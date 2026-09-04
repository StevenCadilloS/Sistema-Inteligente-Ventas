# Fase 1 - Contexto

Esta carpeta contiene la captura y análisis inicial del contexto del usuario.

## Archivos

### `CameraManager.kt`
Responsable de la cámara y de entregar frames mediante CameraX.

> Este archivo no fue modificado en la rama `feature/emotion-detector`.

### `EmotionDetector.kt`
Responsable de detectar el rostro y clasificar la expresión facial.

## Qué se implementó en `EmotionDetector.kt`

- Recepción de frames de CameraX mediante `ImageProxy`.
- Detección de rostros usando Google ML Kit Face Detection.
- Selección del rostro principal cuando aparecen varias caras.
- Corrección de orientación del frame según `rotationDegrees`.
- Recorte seguro de la región facial con un pequeño margen.
- Preprocesamiento de la cara a `48 x 48` píxeles en escala de grises.
- Normalización de píxeles a valores entre `0` y `1`.
- Carga y ejecución del modelo TensorFlow Lite `emotion_model.tflite`.
- Clasificación basada en FER-2013.
- Conversión de las clases del modelo a las emociones utilizadas por el proyecto:
  - `feliz`
  - `triste`
  - `sorpresa`
  - `neutral`
  - `enojo`
- Manejo del caso `no_face` cuando ML Kit no encuentra un rostro.
- Devolución de un `EmotionResult` con emoción y nivel de confianza.
- Liberación de recursos de ML Kit, TensorFlow Lite y bitmaps cuando corresponde.

## Flujo

```text
CameraManager
     ↓
ImageProxy
     ↓
EmotionDetector
     ↓
ML Kit detecta rostro
     ↓
Recorte facial
     ↓
48x48 grayscale
     ↓
TensorFlow Lite
     ↓
EmotionResult(emotion, confidence)
     ↓
EmotionProcessor
```

## Modelo utilizado

El modelo se encuentra en:

```text
app/src/main/assets/emotion_model.tflite
```

Trabaja con una entrada facial de `48 x 48` en escala de grises y genera 7 clases FER-2013.

El detector adapta esas clases a las emociones definidas por el pipeline del proyecto.

## Alcance

Esta fase entrega una clasificación cruda por frame. La estabilización entre varios frames no se realiza aquí; esa responsabilidad pertenece a `processing/EmotionProcessor.kt`.
