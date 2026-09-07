# Guía de integración — Steven

Puente Kotlin↔Flutter + pantallas. Todo lo que aquí se llama (`ClienteRepository`, `AdaptationEngine`, `BanditOptimizer`) ya existe, está probado (35 tests) y no necesita cambios — solo hay que invocarlo desde la UI.

> Antes de empezar: `flutter pub get && dart run build_runner build && flutter test` — confirma que partes de una base en verde.

---

## Orden recomendado

1. **El puente**, sin UI — validar con `print`/logs que las emociones llegan a Dart.
2. **Pantalla de login** — no depende del puente, se puede hacer en paralelo.
3. **Pantalla principal** — puente + `AdaptationEngine`.
4. **Botones aceptar/rechazar**.
5. **Historial** — opcional, déjala para el final.

---

## 1. El puente (Platform Channel)

`ProcessedEmotion` (Kotlin) es un **stream continuo** de eventos, no una llamada única — por eso es `EventChannel`, no `MethodChannel`.

### Kotlin: `android/app/src/main/kotlin/com/tuapp/tienda_adaptativa/channel/EmotionChannelHandler.kt` (nuevo)

```kotlin
package com.tuapp.tienda_adaptativa.channel

import androidx.activity.ComponentActivity
import com.tuapp.tienda_adaptativa.context.CameraManager
import com.tuapp.tienda_adaptativa.context.EmotionDetector
import com.tuapp.tienda_adaptativa.processing.EmotionProcessor
import io.flutter.plugin.common.EventChannel

class EmotionChannelHandler(
    private val activity: ComponentActivity
) : EventChannel.StreamHandler {

    private val cameraManager = CameraManager(activity)
    private val emotionDetector = EmotionDetector(activity)
    private val emotionProcessor = EmotionProcessor()

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        cameraManager.startCamera { frame ->
            emotionDetector.detectEmotion(
                frame,
                onResult = { crudo ->
                    val procesado = emotionProcessor.process(crudo)
                    if (procesado.isStable) {
                        events?.success(
                            mapOf(
                                "emotion" to procesado.emotion,
                                "confidence" to procesado.confidence,
                            )
                        )
                    }
                },
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        cameraManager.stopCamera()
    }

    /** Llamar desde MainActivity.onDestroy(). */
    fun dispose() {
        cameraManager.release()
        emotionDetector.close()
    }
}
```

### Kotlin: registrar el canal en `MainActivity.kt`

```kotlin
package com.tuapp.tienda_adaptativa

import com.tuapp.tienda_adaptativa.channel.EmotionChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val emotionChannelName = "com.tuapp.tienda_adaptativa/emotion"
    private var handler: EmotionChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handler = EmotionChannelHandler(this)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, emotionChannelName)
            .setStreamHandler(handler)
    }

    override fun onDestroy() {
        handler?.dispose()
        super.onDestroy()
    }
}
```

### Dart: `lib/services/emotion_channel.dart` (nuevo)

```dart
import 'package:flutter/services.dart';

class EmocionDetectada {
  const EmocionDetectada({required this.emotion, required this.confidence});

  final String emotion; // "triste", "feliz", "sorpresa", "neutral", "enojo"...
  final double confidence; // 0.0 - 1.0
}

class EmotionChannel {
  static const _channel = EventChannel('com.tuapp.tienda_adaptativa/emotion');

  Stream<EmocionDetectada> get emociones =>
      _channel.receiveBroadcastStream().map((evento) {
        final mapa = evento as Map;
        return EmocionDetectada(
          emotion: mapa['emotion'] as String,
          confidence: (mapa['confidence'] as num).toDouble(),
        );
      });
}
```

**⚠️ Gotcha — preview visual de la cámara.** `CameraManager.kt` hoy solo tiene el caso de uso `ImageAnalysis` (analiza frames en background), **no** `Preview`. Si quieres mostrar el video en pantalla (no solo detectar en silencio), hay que agregarle un caso de uso `Preview` + exponerlo como `PlatformView`/`Texture` a Flutter. Si no es indispensable para la demo, se puede omitir — la detección funciona igual sin mostrar el video.

---

## 2. Conectar el puente a la decisión

Cuando llega una emoción por el stream:

```dart
emotionChannel.emociones.listen((e) async {
  final oferta = await adaptationEngine.decidirOferta(
    codCliente: clienteActivo!,      // de ClienteRepository.clienteActivo()
    emocion: e.emotion,               // tal cual llega de Kotlin
    nivelDeInteres: (e.confidence * 100).round(),
  );
  setState(() => ofertaActual = oferta);
});
```

`Oferta` trae: `idProcesoPersuasion`, `producto` (con `nombreProducto`, `precioUnitarioCentavos`, ...), `estrategia` (nullable), `texto` (el mensaje persuasivo ya armado, listo para mostrar).

**Botones "Me interesa" / "No gracias":**

```dart
await banditOptimizer.registrarRespuesta(
  idProcesoPersuasion: ofertaActual.idProcesoPersuasion,
  aceptada: true, // o false
);
```

---

## 3. Las 3 pantallas

### Login / Registro
- Campos: nombre, apellido (`tipoCliente` es opcional, puede omitirse).
- Al enviar: `await clienteRepository.registrar(nombre: ..., apellido: ...)`.
- **Al arrancar la app**, antes de mostrar login: `final activo = clienteRepository.clienteActivo();` — si no es `null`, saltar directo a la pantalla principal (la regla eliminatoria del taller prohíbe intervención manual innecesaria; no repitas el login en cada apertura).

### Principal (producto + oferta adaptativa)
- Se suscribe a `emotionChannel.emociones` (ver arriba).
- Pinta `ofertaActual.texto` y los datos de `ofertaActual.producto`.
- Botones aceptar/rechazar → `registrarRespuesta(...)`.
- **Al salir de la pantalla:** cancelar la suscripción al stream (`StreamSubscription.cancel()`), o el canal sigue en `onListen` y la cámara nunca se libera — esto es exactamente el requisito de "Gestión del Ciclo de Vida" de la rúbrica (evitar fugas de recursos).

### Historial
- No hay una query dedicada todavía para esto — se puede armar con `db.select(db.interacciones)` directo, o pedir que se agregue una query nombrada en `queries.drift` (avísame si la necesitas, es rápido de agregar).

---

## 4. Cómo instanciar todo (`lib/main.dart`)

Una sola `AppDatabase`, compartida por todos los repositorios/servicios:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await programarCierreDiario(); // ya esta

  final db = AppDatabase();
  final prefs = await SharedPreferences.getInstance();

  final clienteRepository = ClienteRepository(db, prefs);
  final bandit = BanditOptimizer(db);
  final adaptationEngine = AdaptationEngine(db, bandit);

  runApp(MyApp(
    clienteRepository: clienteRepository,
    adaptationEngine: adaptationEngine,
    bandit: bandit,
  ));
}
```

Cómo bajar esas 3 instancias hasta cada pantalla (constructor directo, `InheritedWidget`, `provider`, `riverpod`...) queda a tu criterio — no hay una decisión tomada todavía sobre manejo de estado en la capa de UI.

---

## 5. Checklist antes de dar por conectado

- [ ] El stream de emociones llega a Dart (probar con un `print` antes de tocar UI).
- [ ] Cámara y análisis se detienen al salir de la pantalla (no quedan corriendo en background).
- [ ] `decidirOferta` recibe `emocion` como string (`"triste"`), **no** un código (`"G0000001"`).
- [ ] `nivelDeInteres` es un entero 0-100 (no un float 0.0-1.0).
- [ ] La app no repite el login si ya hay `clienteActivo()`.
- [ ] Aceptar/rechazar llama a `registrarRespuesta` con el `idProcesoPersuasion` correcto (el de la oferta que se le mostró, no uno viejo).

Dudas o si necesitas que ajuste alguna firma → avísame.
