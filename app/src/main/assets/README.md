# Modelo de emociones

El módulo `context/EmotionDetector.kt` utiliza el modelo TensorFlow Lite:

```text
emotion_model.tflite
```

Ubicación:

```text
app/src/main/assets/emotion_model.tflite
```

## Modelo seleccionado

Fuente: `maftuh-main/meme-emotion-detector` en Hugging Face.

Licencia declarada por el autor: **MIT**.

SHA-256 verificado al incorporarlo al repositorio:

```text
2f7681b40c9ac41508aef807edf1a1f77a8ff340c4d39e66ec7f4c8842092162
```

El modelo fue seleccionado porque coincide con el formato usado por `TfliteEmotionClassifier.kt`:

- TensorFlow Lite
- entrada facial `48 x 48`
- un canal (escala de grises)
- valores `Float32` normalizados dividiendo cada píxel entre `255.0`
- salida de 7 clases

Orden de salida del modelo:

```text
0 angry
1 disgust
2 fear
3 happy
4 sad
5 surprise
6 neutral
```

## Adaptación al pipeline del proyecto

El proyecto utiliza cinco emociones de negocio. El clasificador adapta las siete clases del modelo así:

| Modelo | Pipeline del proyecto |
|---|---|
| angry | enojo |
| disgust | enojo |
| fear | neutral |
| happy | feliz |
| sad | triste |
| surprise | sorpresa |
| neutral | neutral |

`no_face` no proviene del modelo. Lo devuelve `EmotionDetector` cuando Google ML Kit no encuentra un rostro en el frame.

## Dependencias Android necesarias

Cuando el proyecto Android tenga sus archivos Gradle, este módulo necesitará las dependencias correspondientes a:

- CameraX (`androidx.camera:camera-core`, versión 1.3.x según el README principal)
- Google ML Kit Face Detection
- TensorFlow Lite 2.14.x según el README principal

## Nota de alcance

El módulo clasifica expresiones faciales visibles. Su resultado no debe interpretarse como una medición fiable del estado emocional interno de una persona.
