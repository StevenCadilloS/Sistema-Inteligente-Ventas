import 'package:drift/drift.dart';

import '../data/database/app_database.dart';
import 'learning/bandit_optimizer.dart';

/// Oferta concreta resultante de una decision de adaptacion: que producto,
/// a que precio, con que estrategia y con que texto persuasivo.
class Oferta {
  const Oferta({
    required this.idProcesoPersuasion,
    required this.producto,
    required this.estrategia,
    required this.texto,
  });

  final String idProcesoPersuasion;
  final Producto producto;
  final Estrategia? estrategia; // C11: nullable de verdad, sin centinela
  final String texto;
}

/// Fase 3 del pipeline (DECISION). Entra un gesto ya estabilizado
/// (context/EmotionProcessor.kt, via el puente Flutter<->Kotlin) y sale una
/// [Oferta] concreta. Cada llamada registra el intento de persuasion en
/// `interacciones` (docs/PLAN_ELVIS.md fase 05 - el rubro de 8 puntos del
/// taller: la oferta cambia sola al cambiar la emocion, sin boton).
///
/// Reglas base (comentarios originales de AdaptationEngine.kt):
///   triste   -> producto sustituto mas economico
///   feliz    -> producto premium (el mas caro, sin descuento)
///   sorpresa -> producto poco mostrado (novedad / oferta especial)
///   neutral  -> producto mas mostrado (oferta estandar del catalogo)
///   enojo    -> cambia de categoria + el mas economico de esa categoria
///
/// La seleccion de estrategia la hace [BanditOptimizer] (fase 06, UCB1).
class AdaptationEngine {
  AdaptationEngine(this._db, this._bandit);

  final AppDatabase _db;
  final BanditOptimizer _bandit;

  static const _canal = 'A'; // app movil (vs 'W' web)
  static const _tipoTransaccion = 'TRX0001';

  Future<Oferta> decidirOferta({
    required String codCliente,
    required String codGesto,
    required int nivelDeInteres,
  }) async {
    final gesto = await (_db.select(_db.gestos)
          ..where((g) => g.codGesto.equals(codGesto)))
        .getSingle();
    final regla = _reglaPara(gesto.nombreGesto);

    final producto = await _productoPara(regla, codCliente);
    final estrategia = await _bandit.seleccionarEstrategia();
    final idProcesoPersuasion = await _siguienteIdProcesoPersuasion();

    await _db.into(_db.interacciones).insert(InteraccionesCompanion.insert(
          canal: _canal,
          correlativo: await _siguienteCorrelativo(),
          idProcesoPersuasion: idProcesoPersuasion,
          codCliente: codCliente,
          codEstrategia: Value(estrategia?.codEstrategia),
          codGesto: Value(codGesto),
          codLoteProducto: Value(producto.codLoteProducto),
          tipoTransaccion: _tipoTransaccion,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          nivelDeInteres: nivelDeInteres,
        ));

    return Oferta(
      idProcesoPersuasion: idProcesoPersuasion,
      producto: producto,
      estrategia: estrategia,
      texto: _textoPara(regla, producto),
    );
  }

  _TipoRegla _reglaPara(String nombreGesto) {
    switch (nombreGesto) {
      case 'triste':
        return _TipoRegla.triste;
      case 'feliz':
        return _TipoRegla.feliz;
      case 'sorpresa':
        return _TipoRegla.sorpresa;
      case 'enojo':
        return _TipoRegla.enojo;
      default:
        return _TipoRegla.neutral;
    }
  }

  Future<Producto> _productoPara(_TipoRegla regla, String codCliente) async {
    switch (regla) {
      case _TipoRegla.triste: // sustituto mas economico
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true))
              ..orderBy([(p) => OrderingTerm.asc(p.precioUnitarioCentavos)])
              ..limit(1))
            .getSingle();
      case _TipoRegla.feliz: // premium, sin descuento
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true))
              ..orderBy([(p) => OrderingTerm.desc(p.precioUnitarioCentavos)])
              ..limit(1))
            .getSingle();
      case _TipoRegla.sorpresa: // novedad: lo menos mostrado
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true))
              ..orderBy([(p) => OrderingTerm.asc(p.totalVecesMostrado)])
              ..limit(1))
            .getSingle();
      case _TipoRegla.neutral: // estandar: lo mas mostrado
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true))
              ..orderBy([(p) => OrderingTerm.desc(p.totalVecesMostrado)])
              ..limit(1))
            .getSingle();
      case _TipoRegla.enojo: // cambia de categoria + descuento agresivo
        return _productoOtraCategoria(codCliente);
    }
  }

  /// Cambia de categoria respecto al ultimo producto mostrado a este
  /// cliente, y dentro de esa categoria elige el mas economico (descuento
  /// agresivo). Si no hay historial o no hay otra categoria disponible,
  /// cae al mas economico del catalogo.
  Future<Producto> _productoOtraCategoria(String codCliente) async {
    final activos = await (_db.select(_db.productos)
          ..where((p) => p.activo.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.precioUnitarioCentavos)]))
        .get();
    if (activos.isEmpty) {
      throw StateError('No hay productos activos en el catalogo.');
    }

    final ultima = await (_db.select(_db.interacciones)
          ..where((i) => i.codCliente.equals(codCliente))
          ..orderBy([(i) => OrderingTerm.desc(i.timestamp)])
          ..limit(1))
        .getSingleOrNull();

    final ultimoCod = ultima?.codLoteProducto;
    final coincidencias =
        activos.where((p) => p.codLoteProducto == ultimoCod);
    final ultimaCategoria =
        ultimoCod == null || coincidencias.isEmpty
            ? null
            : coincidencias.first.tipoProducto;

    final otraCategoria =
        activos.where((p) => p.tipoProducto != ultimaCategoria);
    return otraCategoria.isNotEmpty ? otraCategoria.first : activos.first;
  }

  String _textoPara(_TipoRegla regla, Producto producto) {
    final precio = (producto.precioUnitarioCentavos / 100).toStringAsFixed(2);
    switch (regla) {
      case _TipoRegla.triste:
        return 'Tal vez esto te anime: ${producto.nombreProducto} a S/$precio.';
      case _TipoRegla.feliz:
        return 'Para ti: ${producto.nombreProducto}, nuestra opcion premium.';
      case _TipoRegla.sorpresa:
        return 'Oferta especial solo por hoy: ${producto.nombreProducto}.';
      case _TipoRegla.neutral:
        return 'Te recomendamos: ${producto.nombreProducto} a S/$precio.';
      case _TipoRegla.enojo:
        return 'Precio especial en ${producto.nombreProducto}: S/$precio.';
    }
  }

  Future<int> _siguienteCorrelativo() async {
    final ultima = await (_db.select(_db.interacciones)
          ..where((i) => i.canal.equals(_canal))
          ..orderBy([(i) => OrderingTerm.desc(i.correlativo)])
          ..limit(1))
        .getSingleOrNull();
    return (ultima?.correlativo ?? 0) + 1;
  }

  /// idProcesoPersuasion (C1): la clave que une el intento (interaccion) con
  /// el cierre (venta), si lo hay. Se genera aqui porque el intento siempre
  /// nace en una interaccion.
  Future<String> _siguienteIdProcesoPersuasion() async {
    final ultima = await (_db.select(_db.interacciones)
          ..orderBy([(i) => OrderingTerm.desc(i.idProcesoPersuasion)])
          ..limit(1))
        .getSingleOrNull();

    final siguienteNumero = ultima == null
        ? 1
        : int.parse(ultima.idProcesoPersuasion.substring(2)) + 1;
    return 'PP${siguienteNumero.toString().padLeft(8, '0')}';
  }
}

enum _TipoRegla { triste, feliz, sorpresa, neutral, enojo }
