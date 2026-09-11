import '../data/modelos/modelos.dart';

/// Como se clasifica la respuesta del cliente a lo que tiene delante.
enum Respuesta {
  /// `happy` o `surprise`: el cliente esta respondiendo bien a este precio.
  favorable,

  /// `neutral`, `sad` o `angry`: no termina de convencerle.
  ///
  /// `neutral` cuenta como desfavorable por decision de producto, siguiendo
  /// las reglas del sistema. Conviene saber lo que implica: la cara en reposo
  /// frente a una pantalla suele clasificarse como neutral, asi que la
  /// mayoria de los clientes vera avanzar la escalera. Si algun dia la tienda
  /// regala mas margen del que quiere, este es el primer sitio donde mirar.
  desfavorable,

  /// No hubo cara suficiente para decidir (`no_face`, o una ventana vacia).
  /// No es favorable ni desfavorable: no se hace nada.
  sinSenal,
}

/// Clasifica una racha de emociones en una sola respuesta.
///
/// Se observan varias predicciones en una ventana corta en vez de tomar una
/// sola como definitiva: el clasificador cambia de opinion entre fotogramas, y
/// una unica lectura haria saltar la oferta por un parpadeo.
///
/// Los nombres son los que produce el modulo Kotlin (EmotionDetector.kt); se
/// aceptan tambien los ingleses por si el clasificador cambia de etiquetas.
class ClasificadorRespuesta {
  const ClasificadorRespuesta({this.minimoVotos = 2});

  /// Cuantas lecturas hacen falta para decidir. Con menos, se considera que no
  /// hubo senal suficiente.
  ///
  /// Son 2 y no 3 porque cada lectura ya viene filtrada: el modulo nativo solo
  /// emite tras 26 frames consecutivos de la misma emocion (~1,3 s), asi que
  /// una lectura aqui no es un fotograma suelto sino un segundo largo de cara
  /// sostenida. Exigir 3 dejaba ventanas enteras sin decidir.
  final int minimoVotos;

  static const _favorables = {'feliz', 'sorpresa', 'happy', 'surprise'};
  static const _desfavorables = {
    'neutral', 'triste', 'enojo', 'sad', 'angry',
  };

  /// Cuenta votos y devuelve el grupo mayoritario. Un empate se resuelve como
  /// favorable: ante la duda no se regala margen.
  Respuesta clasificar(Iterable<String> emociones) {
    var favorable = 0;
    var desfavorable = 0;

    for (final e in emociones) {
      final nombre = e.toLowerCase();
      if (_favorables.contains(nombre)) {
        favorable++;
      } else if (_desfavorables.contains(nombre)) {
        desfavorable++;
      }
      // 'no_face' y cualquier etiqueta desconocida no votan: que el rostro
      // salga de cuadro no es una opinion sobre el precio.
    }

    if (favorable + desfavorable < minimoVotos) return Respuesta.sinSenal;
    return desfavorable > favorable ? Respuesta.desfavorable : Respuesta.favorable;
  }
}

/// Una negociacion en curso sobre un producto concreto.
///
/// Es un puntero sobre la escalera de ofertas que el administrador configuro,
/// no un generador de descuentos. La emocion del cliente solo decide si el
/// puntero se queda donde esta o avanza al siguiente escalon; el descuento de
/// cada escalon ya venia dado por la base.
///
/// Empieza siempre en el precio normal (README, regla 3): la primera oferta se
/// juega cuando el cliente no responde bien a lo que ve, no antes.
class Negociacion {
  Negociacion({required this.producto, required List<EscalonOferta> escalera})
    : _escalera = List.unmodifiable(escalera);

  final Producto producto;
  final List<EscalonOferta> _escalera;

  /// -1 = precio normal; 0..n-1 = escalon de la escalera.
  int _posicion = -1;

  /// El escalon vigente, o null si todavia se muestra el precio normal.
  EscalonOferta? get escalonActual =>
      _posicion < 0 ? null : _escalera[_posicion];

  /// Lo que el cliente pagaria ahora mismo.
  int get precioActualCentavos =>
      escalonActual?.precioFinalCentavos ?? producto.precioCentavos;

  /// La oferta con la que se cerraria la venta, o null si es a precio normal.
  int? get idOfertaActual => escalonActual?.idOferta;

  bool get enPrecioNormal => _posicion < 0;

  /// Cuantos escalones tiene la escalera. Se muestra al cliente ("oferta 2 de
  /// 3") para que vea que la negociacion tiene un final y no una pendiente
  /// infinita.
  int get totalEscalones => _escalera.length;

  /// Si queda algun escalon por mostrar. Cuando se agota, la interaccion
  /// termina: no hay mas que ofrecer (README, regla 11).
  bool get quedanEscalones => _posicion + 1 < _escalera.length;

  /// Cuanto se ha rebajado respecto del precio normal.
  int get descuentoCentavos => producto.precioCentavos - precioActualCentavos;

  /// Avanza al siguiente escalon. Devuelve false si ya no quedaba ninguno,
  /// en cuyo caso la posicion no cambia.
  bool avanzar() {
    if (!quedanEscalones) return false;
    _posicion++;
    return true;
  }

  /// Que hacer ante la respuesta del cliente.
  ///
  /// Favorable o sin senal: quedarse donde se esta. Desfavorable: avanzar, si
  /// queda a donde.
  PasoNegociacion siguientePaso(Respuesta respuesta) {
    if (respuesta != Respuesta.desfavorable) return PasoNegociacion.mantener;
    if (!quedanEscalones) return PasoNegociacion.terminar;
    return PasoNegociacion.avanzar;
  }

  /// Mensaje para el cliente en el estado actual.
  String get mensaje {
    final escalon = escalonActual;
    if (escalon == null) {
      return '${producto.nombre} a ${soles(producto.precioCentavos)}.';
    }
    if (escalon.esCombo) {
      return '${escalon.nombreOferta}: ${producto.nombre} a '
          '${soles(escalon.precioFinalCentavos)}.';
    }
    return '${escalon.nombreOferta}: ${producto.nombre} con '
        '${escalon.porcentajeDescuento}% de descuento, a '
        '${soles(escalon.precioFinalCentavos)}.';
  }
}

/// Lo que corresponde hacer despues de leer la cara del cliente.
enum PasoNegociacion {
  /// Se queda con el precio o la oferta que ya se muestra.
  mantener,

  /// Se pasa al siguiente escalon de la escalera.
  avanzar,

  /// No quedan ofertas: se acaba la interaccion y se apaga la camara.
  terminar,
}
