import 'dart:math' as math;

import '../data/modelos/modelos.dart';
import '../data/repositories/tienda_repository.dart';
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
    this.descuentoDelAdministrador = false,
  });

  final String idProcesoPersuasion;
  final Producto producto;
  final Estrategia? estrategia; // C11: nullable de verdad, sin centinela
  final String texto;

  /// Descuento efectivamente concedido sobre el precio de lista. Es el mayor
  /// entre el que decide la emocion y el que el administrador publico en
  /// `ofertas` — nunca la suma (ver [AdaptationEngine.decidirOferta]).
  final int descuentoPorcentaje;

  /// Si el descuento vigente lo puso una persona desde el panel y no la
  /// emocion del cliente. Solo cambia como se redacta el mensaje: anunciar
  /// una promocion de tienda no es lo mismo que reaccionar a una cara.
  final bool descuentoDelAdministrador;

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
///
/// El ordenamiento ocurre en memoria y no con un ORDER BY, a diferencia de la
/// version local. Con la base en el servidor, reordenar en SQL costaria un
/// viaje de red por cada cambio de expresion — un segundo largo cada vez que
/// el cliente mueve la cara, cuando la emocion estable ya tarda 1-2 s en
/// llegar (RNF-02). La lista completa se pide una vez y se reordena aqui.
class AdaptationEngine {
  AdaptationEngine(this._repo, this._bandit);

  final TiendaRepository _repo;
  final BanditOptimizer _bandit;

  /// [excluir] son productos que el cliente ya rechazo en esta sesion: la
  /// oferta salta al siguiente del ranking en vez de insistir con el mismo.
  /// Sin esto, rechazar y volver a ofertar con la misma emocion devolvia
  /// siempre el mismo producto, porque la regla es determinista.
  ///
  /// [productoObjetivo] fuerza la oferta sobre un producto concreto: es el
  /// caso de retencion, cuando el cliente miro un producto y lo dejo ir. La
  /// emocion sigue decidiendo el descuento y el mensaje, pero el producto es
  /// el que el cliente ya mostro querer.
  ///
  /// [catalogo] evita releer el catalogo cuando quien llama ya lo tiene fresco
  /// (la tienda lo recibe por Realtime). Si no se pasa, se consulta.
  Future<Oferta> decidirOferta({
    required String codCliente,
    required String emocion, // ej. "triste" - ProcessedEmotion.emotion en Kotlin
    required int nivelDeInteres,
    Set<String> excluir = const {},
    Producto? productoObjetivo,
    bool conDescuento = true,
    List<Producto>? catalogo,
  }) async {
    // EmotionProcessor.kt (Juan) no conoce codigos de catalogo: solo produce
    // el nombre de la emocion. Una emocion que no sea una de las cinco
    // conocidas ("no_face", o cualquier etiqueta nueva del clasificador) cae a
    // la regla neutral en vez de tumbar el pipeline. La traduccion nombre ->
    // cod_gesto la hace el servidor al registrar la interaccion.
    final regla = _reglaPara(emocion);

    final ordenado = await _catalogoPara(regla, codCliente, catalogo);
    if (ordenado.isEmpty) {
      throw StateError('No hay productos activos en el catalogo.');
    }
    // Si ya rechazo todo el catalogo, se vuelve a empezar por el primero:
    // mejor repetir que quedarse sin oferta que mostrar.
    final producto =
        productoObjetivo ??
        ordenado.firstWhere(
          (p) => !excluir.contains(p.codLoteProducto),
          orElse: () => ordenado.first,
        );
    final estrategia = await _bandit.seleccionarEstrategia();

    final idProcesoPersuasion = await _repo.registrarInteraccion(
      codCliente: codCliente,
      emocion: emocion,
      codLoteProducto: producto.codLoteProducto,
      codEstrategia: estrategia?.codEstrategia,
      nivelDeInteres: nivelDeInteres,
    );

    // El descuento es la carta que se juega cuando el cliente dice que no:
    // la primera oferta va a precio de lista. Sobre esa base, la estrategia
    // que eligio el UCB1 decide como se persuade.
    final adaptativo = conDescuento
        ? _descuentoConEstrategia(_descuentoPara(regla), estrategia)
        : 0;

    // El mayor de los dos, nunca la suma. Sumarlos permitiria que una
    // promocion del 40% mas un enojo del 25% terminara regalando el producto;
    // y quedarse solo con el adaptativo seria peor: el feed anuncia la
    // promocion del administrador, y el popup la desmentiria mostrando un
    // precio mas alto.
    final descuento = math.max(adaptativo, producto.descuentoOferta);
    final mandaElAdministrador =
        producto.descuentoOferta > 0 && producto.descuentoOferta >= adaptativo;

    return Oferta(
      idProcesoPersuasion: idProcesoPersuasion,
      producto: producto,
      estrategia: estrategia,
      texto:
          _textoPara(regla, producto, descuento, mandaElAdministrador) +
          (conDescuento ? _beneficioDe(estrategia) : ''),
      descuentoPorcentaje: descuento,
      descuentoDelAdministrador: mandaElAdministrador,
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
    List<Producto>? catalogo,
  }) async {
    final disponibles = _porPrecioAscendente(
      await _disponibles(catalogo),
    );

    final descartados = {...excluir, producto.codLoteProducto};
    final candidatos = disponibles
        .where((p) => !descartados.contains(p.codLoteProducto))
        .where((p) => p.tipoProducto == producto.tipoProducto)
        .toList();

    if (candidatos.isEmpty) return null;

    final masBaratos = candidatos.where(
      (p) => p.precioUnitarioCentavos < producto.precioUnitarioCentavos,
    );
    // La lista viene por precio ascendente, asi que el primero de cada filtro
    // ya es el mas economico.
    return masBaratos.isNotEmpty ? masBaratos.first : candidatos.first;
  }

  /// Catalogo completo ordenado por la regla de la emocion: el primero es el
  /// producto que se destaca como oferta, y el resto queda ordenado por el
  /// mismo criterio para el feed de la tienda.
  ///
  /// No registra interaccion — eso lo hace [decidirOferta] con el destacado.
  Future<List<Producto>> catalogoPara({
    required String codCliente,
    required String emocion,
    List<Producto>? catalogo,
  }) {
    return _catalogoPara(_reglaPara(emocion), codCliente, catalogo);
  }

  Future<List<Producto>> _catalogoPara(
    _TipoRegla regla,
    String codCliente,
    List<Producto>? catalogo,
  ) async {
    final disponibles = await _disponibles(catalogo);

    switch (regla) {
      case _TipoRegla.triste: // sustituto mas economico
        return _porPrecioAscendente(disponibles);
      case _TipoRegla.feliz: // premium, sin descuento
        return _ordenar(
          disponibles,
          (a, b) => b.precioUnitarioCentavos.compareTo(a.precioUnitarioCentavos),
        );
      case _TipoRegla.sorpresa: // novedad: lo menos mostrado
        return _ordenar(
          disponibles,
          (a, b) => a.totalVecesMostrado.compareTo(b.totalVecesMostrado),
        );
      case _TipoRegla.neutral: // estandar: lo mas mostrado
        return _ordenar(
          disponibles,
          (a, b) => b.totalVecesMostrado.compareTo(a.totalVecesMostrado),
        );
      case _TipoRegla.enojo: // cambia de categoria + descuento agresivo
        return _catalogoOtraCategoria(disponibles, codCliente);
    }
  }

  Future<List<Producto>> _disponibles(List<Producto>? catalogo) async {
    final fuente = catalogo ?? await _repo.catalogo();
    return fuente.where((p) => p.disponible).toList();
  }

  /// Pone primero los productos de una categoria distinta a la del ultimo
  /// producto mostrado a este cliente, cada bloque ordenado del mas economico
  /// al mas caro (descuento agresivo). Sin historial o sin otra categoria
  /// disponible, queda el catalogo entero por precio ascendente.
  Future<List<Producto>> _catalogoOtraCategoria(
    List<Producto> disponibles,
    String codCliente,
  ) async {
    final porPrecio = _porPrecioAscendente(disponibles);
    if (porPrecio.isEmpty) return const [];

    final ultimoCod = await _repo.ultimoProductoMostrado(codCliente);
    if (ultimoCod == null) {
      // Sin historial: queda el orden por precio ascendente, sin pasar por
      // el filtro de categoria.
      return porPrecio;
    }

    final coincidencias = porPrecio.where((p) => p.codLoteProducto == ultimoCod);
    final ultimaCategoria = coincidencias.isEmpty
        ? null
        : coincidencias.first.tipoProducto;

    return [
      ...porPrecio.where((p) => p.tipoProducto != ultimaCategoria),
      ...porPrecio.where((p) => p.tipoProducto == ultimaCategoria),
    ];
  }

  List<Producto> _porPrecioAscendente(List<Producto> productos) => _ordenar(
    productos,
    (a, b) => a.precioUnitarioCentavos.compareTo(b.precioUnitarioCentavos),
  );

  /// Ordena sin modificar la lista de entrada y desempata siempre por codigo.
  ///
  /// El desempate no es cosmetico: `List.sort` no es estable, asi que dos
  /// productos con el mismo precio (o el mismo numero de exhibiciones, que es
  /// frecuente en un catalogo recien sembrado) podrian salir en un orden
  /// distinto en cada llamada, y el feed parpadearia sin que cambie nada.
  List<Producto> _ordenar(
    List<Producto> productos,
    int Function(Producto, Producto) comparar,
  ) {
    final copia = [...productos];
    copia.sort((a, b) {
      final orden = comparar(a, b);
      return orden != 0 ? orden : a.codLoteProducto.compareTo(b.codLoteProducto);
    });
    return copia;
  }

  /// Cada estrategia es un *mecanismo de persuasion distinto*, no una
  /// etiqueta: por eso modifica la oferta. Sin esto el UCB1 estaria
  /// optimizando sobre nombres sin efecto, y no habria nada que aprender.
  ///
  /// Los codigos son los sembrados en supabase/migrations/0003_semilla.sql;
  /// una estrategia desconocida cae al descuento de la emocion, sin
  /// modificarlo.
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

  /// Descuento por regla, siguiendo la intencion ya documentada de cada una:
  /// enojo lleva "descuento agresivo", sorpresa es "oferta especial", y feliz
  /// es premium **sin** descuento.
  ///
  /// Vive aqui y no en la UI a proposito: es una decision de negocio, y es el
  /// mismo numero que termina congelado en `detalle_venta.precio_unitario_centavos`
  /// cuando la venta se cierra. Un descuento que solo existiera en el texto
  /// del popup no cuadraria con lo que registra la base.
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

  _TipoRegla _reglaPara(String emocion) {
    switch (emocion) {
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

  String _textoPara(
    _TipoRegla regla,
    Producto producto,
    int descuento,
    bool mandaElAdministrador,
  ) {
    final centavosFinales =
        producto.precioUnitarioCentavos -
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

    // Cuando el descuento es la promocion de la tienda y no una reaccion a la
    // cara del cliente, se anuncia como tal: decirle "tal vez esto te anime"
    // por un precio que ve cualquiera suena a invento.
    if (mandaElAdministrador) {
      final nombre = producto.nombreOferta;
      return nombre == null
          ? '${producto.nombreProducto} esta en oferta: $descuento% menos, '
                'a S/$precio.'
          : '$nombre: ${producto.nombreProducto} con $descuento% de descuento, '
                'a S/$precio.';
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
}

enum _TipoRegla { triste, feliz, sorpresa, neutral, enojo }
