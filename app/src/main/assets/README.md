# Modelo de emociones

El módulo `context/EmotionDetector.kt` espera un modelo TensorFlow Lite llamado:

```text
emotion_model.tflite
```

La ubicación final debe ser:

```text
app/src/main/assets/emotion_model.tflite
```

## Formato esperado

El adaptador `TfliteEmotionClassifier.kt` está preparado para un modelo FER-2013 con:

- entrada: imagen facial `48 x 48`
- un canal (escala de grises)
- valores `Float32` normalizados a `[0, 1]`
- salida: 7 clases FER-2013

Orden esperado de salida:

```text
0 angry
1 disgust
2 fear
3 happy
4 sad
5 surprise
6 neutral
```

El proyecto utiliza solo cinco emociones de negocio. El clasificador las adapta así:

| FER-2013 | Pipeline del proyecto |
|---|---|
| angry | enojo |
| disgust | enojo |
| fear | neutral |
| happy | feliz |
| sad | triste |
| surprise | sorpresa |
| neutral | neutral |

`no_face` no proviene del modelo: lo devuelve `EmotionDetector` cuando ML Kit no encuentra un rostro.

## Dependencias Android necesarias

Cuando se agreguen los archivos Gradle del proyecto Android, el módulo necesita las dependencias correspondientes a:

- CameraX (`androidx.camera:camera-core`, versión 1.3.x según el README principal)
- Google ML Kit Face Detection
- TensorFlow Lite 2.14.x según el README principal

El modelo binario `.tflite` no se incluye todavía en este repositorio.
