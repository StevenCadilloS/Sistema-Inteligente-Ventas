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
    required String emocion, // ej. "triste" - ProcessedEmotion.emotion en Kotlin
    required int nivelDeInteres,
  }) async {
    // EmotionProcessor.kt (Juan) no conoce codigos de catalogo: solo
    // produce el nombre de la emocion (ver ProcessedEmotion.emotion en
    // processing/EmotionProcessor.kt). Por eso se busca por nombreGesto,
    // no por codGesto - codGesto es un detalle interno de persistencia.
    //
    // getSingleOrNull, no getSingle: los datos historicos reales tienen
    // gestos fuera de las 5 emociones basicas sembradas (ver
    // test/data/database/casos_reales_test.dart, gesto G0000008), y en
    // produccion el clasificador puede devolver "no_face" u otro valor no
    // sembrado. Una emocion sin catalogar cae a la regla neutral en vez de
    // tumbar el pipeline de decision.
    final gesto = await (_db.select(_db.gestos)
          ..where((g) => g.nombreGesto.equals(emocion)))
        .getSingleOrNull();
    final regla = gesto == null ? _TipoRegla.neutral : _reglaPara(gesto.nombreGesto);
    // Sin fila en Gestos no hay codGesto que guardar (rompe la FK); se
    // registra la interaccion igual, solo sin ese dato.
    final codGesto = gesto?.codGesto;

    final catalogo = await _catalogoPara(regla, codCliente);
    if (catalogo.isEmpty) {
      throw StateError('No hay productos activos en el catalogo.');
    }
    final producto = catalogo.first;
    final estrategia = await _bandit.seleccionarEstrategia();

    // El calculo del siguiente correlativo/idProcesoPersuasion (leer el
    // maximo actual) y el insert que los consume van en UNA transaccion:
    // sueltos, dos llamadas concurrentes podrian leer el mismo maximo y
    // chocar contra el UNIQUE(canal, correlativo) al insertar.
    late final String idProcesoPersuasion;
    await _db.transaction(() async {
      idProcesoPersuasion = await _siguienteIdProcesoPersuasion();
      final correlativo = await _siguienteCorrelativo();

      await _db.into(_db.interacciones).insert(InteraccionesCompanion.insert(
            canal: _canal,
            correlativo: correlativo,
            idProcesoPersuasion: idProcesoPersuasion,
            codCliente: codCliente,
            codEstrategia: Value(estrategia?.codEstrategia),
            codGesto: Value(codGesto),
            codLoteProducto: Value(producto.codLoteProducto),
            tipoTransaccion: _tipoTransaccion,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            nivelDeInteres: nivelDeInteres,
          ));

      // Sin esto, "neutral" (el mas mostrado) y "sorpresa" (el menos
      // mostrado) nunca cambiarian de resultado: nada mas escribia esta
      // columna. Update relativo en SQL (no leer+sumar en Dart) para que
      // sea seguro con llamadas concurrentes.
      await _db.customUpdate(
        'UPDATE productos SET total_veces_mostrado = total_veces_mostrado + 1 '
        'WHERE cod_lote_producto = ?',
        variables: [Variable<String>(producto.codLoteProducto)],
        updates: {_db.productos},
      );
    });

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

  /// Catalogo completo ordenado por la regla de la emocion: el primero es el
  /// producto que se destaca como oferta, y el resto queda ordenado por el
  /// mismo criterio para el feed de la tienda.
  ///
  /// No registra interaccion — eso lo hace [decidirOferta] con el destacado.
  Future<List<Producto>> catalogoPara({
    required String codCliente,
    required String emocion,
  }) async {
    final gesto = await (_db.select(_db.gestos)
          ..where((g) => g.nombreGesto.equals(emocion)))
        .getSingleOrNull();
    final regla =
        gesto == null ? _TipoRegla.neutral : _reglaPara(gesto.nombreGesto);
    return _catalogoPara(regla, codCliente);
  }

  Future<List<Producto>> _catalogoPara(
      _TipoRegla regla, String codCliente) async {
    switch (regla) {
      case _TipoRegla.triste: // sustituto mas economico
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true))
              ..orderBy([(p) => OrderingTerm.asc(p.precioUnitarioCentavos)]))
            .get();
      case _TipoRegla.feliz: // premium, sin descuento
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true))
              ..orderBy([(p) => OrderingTerm.desc(p.precioUnitarioCentavos)]))
            .get();
      case _TipoRegla.sorpresa: // novedad: lo menos mostrado
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true))
              ..orderBy([(p) => OrderingTerm.asc(p.totalVecesMostrado)]))
            .get();
      case _TipoRegla.neutral: // estandar: lo mas mostrado
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true))
              ..orderBy([(p) => OrderingTerm.desc(p.totalVecesMostrado)]))
            .get();
      case _TipoRegla.enojo: // cambia de categoria + descuento agresivo
        return _catalogoOtraCategoria(codCliente);
    }
  }

  /// Pone primero los productos de una categoria distinta a la del ultimo
  /// producto mostrado a este cliente, cada bloque ordenado del mas economico
  /// al mas caro (descuento agresivo). Sin historial o sin otra categoria
  /// disponible, queda el catalogo entero por precio ascendente.
  Future<List<Producto>> _catalogoOtraCategoria(String codCliente) async {
    final activos = await (_db.select(_db.productos)
          ..where((p) => p.activo.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.precioUnitarioCentavos)]))
        .get();
    if (activos.isEmpty) return const [];

    final ultima = await (_db.select(_db.interacciones)
          ..where((i) => i.codCliente.equals(codCliente))
          ..orderBy([(i) => OrderingTerm.desc(i.timestamp)])
          ..limit(1))
        .getSingleOrNull();

    final ultimoCod = ultima?.codLoteProducto;
    if (ultimoCod == null) {
      // Sin historial: queda el orden por precio ascendente, sin pasar por
      // el filtro de categoria.
      return activos;
    }

    final coincidencias =
        activos.where((p) => p.codLoteProducto == ultimoCod);
    final ultimaCategoria =
        coincidencias.isEmpty ? null : coincidencias.first.tipoProducto;

    return [
      ...activos.where((p) => p.tipoProducto != ultimaCategoria),
      ...activos.where((p) => p.tipoProducto == ultimaCategoria),
    ];
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
