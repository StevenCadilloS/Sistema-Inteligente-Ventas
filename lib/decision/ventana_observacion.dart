import 'package:clock/clock.dart';

/// Una ventana de observacion que se puede congelar y descongelar sin perder
/// lo ya observado.
///
/// Existe porque el cliente puede dejar de mirar a media negociacion. Cuando
/// eso pasa, la ventana no puede seguir corriendo: si lo hiciera, ocho
/// segundos de nadie delante de la camara se leerian como "sin senal" y la
/// ronda se gastaria sin que el cliente viera nada. Congelarla deja la
/// negociacion exactamente donde estaba hasta que el rostro vuelva.
///
/// No sabe de widgets ni de temporizadores, a proposito: aqui vive la
/// aritmetica y el invariante de "en pausa no se cuenta", y se puede probar
/// sin emulador. Quien arma y cancela los Timer es la pantalla, que es la
/// unica que tiene dispose() y puede garantizar que no quede ninguno vivo.
///
/// El reloj es inyectable porque `Stopwatch` y `DateTime.now()` NO estan
/// falseados en las pruebas de widget: `tester.pump(Duration)` avanza el reloj
/// de fake_async, no el de pared. `clock.now()` si lo esta -- fake_async
/// ejecuta el cuerpo dentro de `withClock`, cosa comprobada antes de escribir
/// esta clase. Sin eso, el tiempo consumido daria cero en toda la suite.
class VentanaObservacion {
  VentanaObservacion({required this.total, DateTime Function()? ahora})
      : _ahora = ahora ?? _relojAmbiente {
    _desde = _ahora();
  }

  static DateTime _relojAmbiente() => clock.now();

  /// Cuanto dura la ventana completa.
  final Duration total;

  final DateTime Function() _ahora;

  final List<String> _lecturas = [];

  /// Tiempo ya consumido en tramos anteriores (lo acumulado antes de cada
  /// pausa). El tramo en curso se suma aparte en [transcurrido].
  Duration _consumido = Duration.zero;

  /// Cuando empezo el tramo en curso, o null si esta congelada.
  DateTime? _desde;

  bool get pausada => _desde == null;

  /// Las emociones observadas en esta ventana, en orden de llegada.
  List<String> get lecturas => List.unmodifiable(_lecturas);

  /// Lo consumido de la ventana. En pausa deja de crecer: es la definicion
  /// operativa de "la ventana no avanza".
  Duration get transcurrido =>
      _consumido + (pausada ? Duration.zero : _ahora().difference(_desde!));

  /// Lo que falta para que la ventana cierre. Es con esto, y no con [total],
  /// con lo que hay que rearmar el temporizador al reanudar: ahi esta el
  /// "desde donde quedo".
  Duration get restante {
    final falta = total - transcurrido;
    return falta.isNegative ? Duration.zero : falta;
  }

  /// De 0 a 1, para pintar la barra. Congelado mientras [pausada]: el numero
  /// que deja de moverse es la prueba visible de que la ventana no corre.
  double get progreso {
    if (total.inMicroseconds <= 0) return 1;
    return (transcurrido.inMicroseconds / total.inMicroseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// Anota una emocion observada.
  ///
  /// Devuelve false si se descarto por estar en pausa. Que el descarte viva
  /// aqui y no en la pantalla es lo que convierte "mientras este pausada no
  /// deberan contabilizarse emociones" en algo que se puede probar sin montar
  /// una interfaz.
  bool registrar(String emocion) {
    if (pausada) return false;
    _lecturas.add(emocion);
    return true;
  }

  /// Congela la ventana. Idempotente: llamarla dos veces no pierde tiempo ni
  /// lo cuenta dos veces.
  void pausar() {
    if (pausada) return;
    _consumido = transcurrido;
    _desde = null;
  }

  /// Descongela desde donde quedo. No toca [_consumido], que es justamente lo
  /// que hace que la ventana no se reinicie.
  void reanudar() {
    if (!pausada) return;
    _desde = _ahora();
  }
}
