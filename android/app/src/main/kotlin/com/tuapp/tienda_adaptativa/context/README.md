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
- Preprocesamiento de la cara a `48 x 48` píxeles en escala de grises
- Ecualización de histograma sobre el recorte (`ecualizar()`): reparte los niveles de gris para que el contraste no dependa de la luz de la sala
- Normalización de píxeles a valores entre `0` y `1`
- Carga y ejecución del modelo TensorFlow Lite `emotion_model.tflite`
- Clasificación basada en FER-2013
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

### El orden de las clases importa (y no es el canónico)

Keras arma las etiquetas con `flow_from_directory`, es decir en **orden alfabético** —
`angry, disgust, fear, happy, neutral, sad, surprise`— y **no** el orden canónico de
FER-2013, que pone `sad, surprise, neutral` al final. El código original asumía el
canónico, y por eso una cara en reposo se mostraba como "triste 97%".

Comprobado en dispositivo con el vector de probabilidades: una cara relajada da el índice
4 en el 56% de los frames, y poner cara triste lo hunde al 18% en vez de subirlo. Si el 4
fuera `sad` pasaría lo contrario.

El pipeline del proyecto usa cinco emociones de negocio, así que dos clases se pliegan:

| Índice | Clase del modelo | Emoción del proyecto |
|---|---|---|
| 0 | angry | `enojo` |
| 1 | disgust | `enojo` (sin regla propia) |
| 2 | fear | `neutral` (sin regla propia) |
| 3 | happy | `feliz` |
| 4 | neutral | `neutral` |
| 5 | sad | `triste` |
| 6 | surprise | `sorpresa` |

### Dos decisiones de detección

- **`PERFORMANCE_MODE_FAST`, no `ACCURATE`:** con un solo rostro cercano la precisión es
  equivalente y `ACCURATE` bajaba los fps.
- **`setMinFaceSize(0.10f)`:** es la fracción mínima del ancho del frame que debe ocupar
  la cara. Con `0.35` hubo 376 frames sin una sola detección, y con `0.15`, 0 de 257 a un
  brazo de distancia: la app solo servía pegada a la cara. `0.10` es el valor por defecto
  de ML Kit y cubre la distancia normal de uso de un celular.

## Alcance

Esta fase entrega una clasificación cruda por frame. La estabilización entre varios frames no se realiza aquí; esa responsabilidad pertenece a `processing/EmotionProcessor.kt`.
