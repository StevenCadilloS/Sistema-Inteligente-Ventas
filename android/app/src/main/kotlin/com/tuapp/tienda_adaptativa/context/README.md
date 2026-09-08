# Fase 1 - Contexto

Esta carpeta contiene la captura y análisis inicial del contexto del usuario.

## Archivos

### `CameraManager.kt`
Responsable de controlar la cámara frontal y entregar frames en tiempo real mediante CameraX.

**Qué se implementó:**
- Verificación de permisos de cámara en runtime
- Solicitud de permisos con `ActivityResultContracts`
- Inicialización de CameraX con cámara frontal (`DEFAULT_FRONT_CAMERA`)
- Configuración de `ImageAnalysis` con estrategia `KEEP_ONLY_LATEST`
- Resolución objetivo: 640x480
- Callback `onFrameCaptured` que entrega cada `ImageProxy` al caller
- Liberación de recursos con `stopCamera()` y `release()`
- Executor de un solo hilo para análisis de frames

**Flujo:**
```text
CameraManager.startCamera()
        ↓
CameraX ImageAnalysis
        ↓
ImageProxy (frame)
        ↓
EmotionDetector.detectEmotion()
```

### `EmotionDetector.kt`
Responsable de detectar el rostro y clasificar la expresión facial.

**Qué se implementó:**
- Recepción de frames de CameraX mediante `ImageProxy`
- Detección de rostros usando Google ML Kit Face Detection
- Selección del rostro principal cuando aparecen varias caras
- Corrección de orientación del frame según `rotationDegrees`
- Recorte seguro de la región facial con un pequeño margen
- Preprocesamiento del recorte facial como RGB `float32` de `112 x 112`
- Entrada en rango `0..255`; la normalización está incluida dentro del modelo
- Carga y ejecución del modelo TensorFlow Lite `emotion_model.tflite`
- Clasificación mediante EmotiScan FaceExpressionNet
- Conversión de las clases del modelo a las emociones del proyecto:
  - `feliz`
  - `triste`
  - `sorpresa`
  - `neutral`
  - `enojo`
- Manejo del caso `no_face` cuando ML Kit no encuentra un rostro
- Devolución de un `EmotionResult` con emoción y nivel de confianza
- Liberación de recursos de ML Kit, TensorFlow Lite y bitmaps

**Flujo:**
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
112x112 RGB float32 (0..255)
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

Usa EmotiScan FaceExpressionNet (variante float16), con entrada RGB `112 x 112`
y siete probabilidades Softmax en el orden `neutral`, `happy`, `sad`, `angry`,
`fearful`, `disgusted`, `surprised`.

La procedencia, licencia, hash y contrato del modelo están documentados en
`app/src/main/assets/README.md`.

El detector adapta esas clases a las emociones definidas por el pipeline del proyecto.

## Alcance

Esta fase entrega una clasificación cruda por frame. La estabilización entre varios frames no se realiza aquí; esa responsabilidad pertenece a `processing/EmotionProcessor.kt`.
