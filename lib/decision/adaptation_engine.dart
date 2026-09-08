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
    required this.descuentoPorcentaje,
  });

  final String idProcesoPersuasion;
  final Producto producto;
  final Estrategia? estrategia; // C11: nullable de verdad, sin centinela
  final String texto;

  /// Descuento que la regla de la emocion concede sobre este producto.
  /// 0 cuando la regla no contempla rebaja (premium y oferta estandar).
  final int descuentoPorcentaje;

  /// Precio realmente ofrecido, que es el que se congela en `detalleVenta`
  /// al cerrar la venta. Aritmetica entera en centavos: el dinero nunca pasa
  /// por double (docs/PLAN_ELVIS.md, trampa #3).
  int get precioFinalCentavos =>
      producto.precioUnitarioCentavos -
      (producto.precioUnitarioCentavos * descuentoPorcentaje ~/ 100);

  bool get tieneDescuento => descuentoPorcentaje > 0;
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

  /// [excluir] son productos que el cliente ya rechazo en esta sesion: la
  /// oferta salta al siguiente del ranking en vez de insistir con el mismo.
  /// Sin esto, rechazar y volver a ofertar con la misma emocion devolvia
  /// siempre el mismo producto, porque la regla es determinista.
  ///
  /// [productoObjetivo] fuerza la oferta sobre un producto concreto: es el
  /// caso de retencion, cuando el cliente miro un producto y lo dejo ir. La
  /// emocion sigue decidiendo el descuento y el mensaje, pero el producto es
  /// el que el cliente ya mostro querer.
  Future<Oferta> decidirOferta({
    required String codCliente,
    required String emocion, // ej. "triste" - ProcessedEmotion.emotion en Kotlin
    required int nivelDeInteres,
    Set<String> excluir = const {},
    Producto? productoObjetivo,
    bool conDescuento = true,
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
    // Si ya rechazo todo el catalogo, se vuelve a empezar por el primero:
    // mejor repetir que quedarse sin oferta que mostrar.
    final producto = productoObjetivo ??
        catalogo.firstWhere(
          (p) => !excluir.contains(p.codLoteProducto),
          orElse: () => catalogo.first,
        );
    final estrategia = await _bandit.seleccionarEstrategia();

    final idProcesoPersuasion = await _registrarInteraccion(
      codCliente: codCliente,
      producto: producto,
      codEstrategia: estrategia?.codEstrategia,
      codGesto: codGesto,
      nivelDeInteres: nivelDeInteres,
    );

    // El descuento es la carta que se juega cuando el cliente dice que no:
    // la primera oferta va a precio de lista. Sobre esa base, la estrategia
    // que eligio el UCB1 decide como se persuade.
    final descuento = conDescuento
        ? _descuentoConEstrategia(_descuentoPara(regla), estrategia)
        : 0;

    return Oferta(
      idProcesoPersuasion: idProcesoPersuasion,
      producto: producto,
      estrategia: estrategia,
      texto: _textoPara(regla, producto, descuento) +
          (conDescuento ? _beneficioDe(estrategia) : ''),
      descuentoPorcentaje: descuento,
    );
  }

  /// Bien sustituto de [producto]: la alternativa mas economica que cubre la
  /// misma necesidad, es decir, de su misma categoria. Se usa cuando el
  /// cliente rechazo el producto dos veces (a precio de lista y rebajado):
  /// insistir con el mismo ya no tiene sentido, pero si ofrecerle otra cosa
  /// del mismo rubro.
  ///
  /// Se prefiere uno mas barato que el rechazado — si rechazo dos veces por
  /// precio, subirselo no ayuda. Si no hay ninguno mas barato, cae al mas
  /// economico de la categoria. Devuelve null si no queda alternativa.
  Future<Producto?> sustitutoPara(
    Producto producto, {
    Set<String> excluir = const {},
  }) async {
    final activos = await (_db.select(_db.productos)
          ..where((p) => p.activo.equals(true) & p.totalDisponible.isBiggerThanValue(0))
          ..orderBy([(p) => OrderingTerm.asc(p.precioUnitarioCentavos)]))
        .get();

    final descartados = {...excluir, producto.codLoteProducto};
    final candidatos = activos
        .where((p) => !descartados.contains(p.codLoteProducto))
        .where((p) => p.tipoProducto == producto.tipoProducto)
        .toList();

    if (candidatos.isEmpty) return null;

    final masBaratos = candidatos.where(
      (p) => p.precioUnitarioCentavos < producto.precioUnitarioCentavos,
    );
    // `activos` viene por precio ascendente, asi que el primero de cada
    // filtro ya es el mas economico.
    return masBaratos.isNotEmpty ? masBaratos.first : candidatos.first;
  }

  /// Descuento por regla, siguiendo la intencion ya documentada de cada una
  /// (ver los comentarios de la clase): enojo lleva "descuento agresivo",
  /// sorpresa es "oferta especial", y feliz es premium **sin** descuento.
  ///
  /// Vive aqui y no en la UI a proposito: es una decision de negocio, y es el
  /// mismo numero que termina congelado en `detalleVenta.precioUnitarioCentavos`
  /// cuando la venta se cierra. Un descuento que solo existiera en el texto
  /// del popup no cuadraria con lo que registra la base.
  /// Cada estrategia es un *mecanismo de persuasion distinto*, no una
  /// etiqueta: por eso modifica la oferta. Sin esto el UCB1 estaria
  /// optimizando sobre nombres sin efecto, y no habria nada que aprender.
  ///
  /// Los codigos son los sembrados en `catalogo_demo.dart`; una estrategia
  /// desconocida cae al descuento de la emocion, sin modificarlo.
  int _descuentoConEstrategia(int base, Estrategia? estrategia) {
    switch (estrategia?.codEstrategia) {
      case 'E0000002': // Envio gratis: da valor sin tocar el precio
      case 'E0000003': // Recomendacion premium: apela al producto, no al precio
        return 0;
      case 'E0000004': // Oferta relampago: mas agresiva que el descuento base
        return base == 0 ? 10 : base + 5;
      default: // Descuento directo (E0000001) y cualquier otra
        return base;
    }
  }

  /// Beneficio que la estrategia agrega al mensaje, cuando no pasa por el
  /// precio.
  String _beneficioDe(Estrategia? estrategia) {
    switch (estrategia?.codEstrategia) {
      case 'E0000002':
        return ' Ademas te lo llevamos con envio gratis.';
      case 'E0000003':
        return ' Es de lo mejor que tenemos en su categoria.';
      case 'E0000004':
        return ' Precio relampago: solo por hoy.';
      default:
        return '';
    }
  }

  int _descuentoPara(_TipoRegla regla) {
    switch (regla) {
      case _TipoRegla.enojo:
        return 25;
      case _TipoRegla.sorpresa:
        return 15;
      case _TipoRegla.triste:
        return 10;
      case _TipoRegla.feliz:
      case _TipoRegla.neutral:
        return 0;
    }
  }

  /// El calculo del siguiente correlativo/idProcesoPersuasion (leer el
  /// maximo actual) y el insert que los consume van en UNA transaccion:
  /// sueltos, dos llamadas concurrentes podrian leer el mismo maximo y
  /// chocar contra el UNIQUE(canal, correlativo) al insertar.
  Future<String> _registrarInteraccion({
    required String codCliente,
    required Producto producto,
    required String? codEstrategia,
    required String? codGesto,
    required int nivelDeInteres,
  }) async {
    late final String idProcesoPersuasion;
    await _db.transaction(() async {
      idProcesoPersuasion = await _siguienteIdProcesoPersuasion();
      final correlativo = await _siguienteCorrelativo();

      await _db.into(_db.interacciones).insert(InteraccionesCompanion.insert(
            canal: _canal,
            correlativo: correlativo,
            idProcesoPersuasion: idProcesoPersuasion,
            codCliente: codCliente,
            codEstrategia: Value(codEstrategia),
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

    return idProcesoPersuasion;
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
              ..where((p) => p.activo.equals(true) & p.totalDisponible.isBiggerThanValue(0))
              ..orderBy([(p) => OrderingTerm.asc(p.precioUnitarioCentavos)]))
            .get();
      case _TipoRegla.feliz: // premium, sin descuento
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true) & p.totalDisponible.isBiggerThanValue(0))
              ..orderBy([(p) => OrderingTerm.desc(p.precioUnitarioCentavos)]))
            .get();
      case _TipoRegla.sorpresa: // novedad: lo menos mostrado
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true) & p.totalDisponible.isBiggerThanValue(0))
              ..orderBy([(p) => OrderingTerm.asc(p.totalVecesMostrado)]))
            .get();
      case _TipoRegla.neutral: // estandar: lo mas mostrado
        return (_db.select(_db.productos)
              ..where((p) => p.activo.equals(true) & p.totalDisponible.isBiggerThanValue(0))
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
          ..where((p) => p.activo.equals(true) & p.totalDisponible.isBiggerThanValue(0))
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

  String _textoPara(_TipoRegla regla, Producto producto, int descuento) {
    final centavosFinales = producto.precioUnitarioCentavos -
        (producto.precioUnitarioCentavos * descuento ~/ 100);
    final precio = (centavosFinales / 100).toStringAsFixed(2);

    // Sin rebaja no se puede usar el texto de la regla, que anuncia el
    // porcentaje ("con 0% de descuento" quedaria absurdo).
    if (descuento == 0) {
      return regla == _TipoRegla.feliz
          ? 'Para ti: ${producto.nombreProducto}, nuestra opcion premium '
              'a S/$precio.'
          : 'Te recomendamos: ${producto.nombreProducto} a S/$precio.';
    }

    switch (regla) {
      case _TipoRegla.triste:
        return 'Tal vez esto te anime: ${producto.nombreProducto} con '
            '$descuento% menos, a S/$precio.';
      case _TipoRegla.feliz:
        return 'Para ti: ${producto.nombreProducto}, nuestra opcion premium.';
      case _TipoRegla.sorpresa:
        return 'Oferta especial solo por hoy: ${producto.nombreProducto} con '
            '$descuento% de descuento, a S/$precio.';
      case _TipoRegla.neutral:
        return 'Te recomendamos: ${producto.nombreProducto} a S/$precio.';
      case _TipoRegla.enojo:
        return 'Llevate ${producto.nombreProducto} con $descuento% de '
            'descuento: S/$precio.';
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
