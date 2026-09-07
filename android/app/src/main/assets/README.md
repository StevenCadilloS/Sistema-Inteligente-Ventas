# Modelo de expresiones faciales

`emotion_model.tflite` es la variante float16 de **MaternaLink FER —
MobileNetV2, 7-class calibrated**.

- Fuente: https://huggingface.co/mykkularathne/maternalink-fer-mobilenetv2
- Archivo original: `fer_mobilenetv2_96_float16.tflite`
- Licencia declarada por el autor: MIT
- SHA-256: `a83946afed5043953d03a00eb239c8cc3584fe9f28eed74ba7ac9456a79ca78d`
- Entrada: `float32 [1, 96, 96, 3]`, rango `[-1, 1]`
- Salida: `float32 [1, 7]`, Softmax calibrado
- Clases: `angry`, `disgust`, `fear`, `happy`, `neutral`, `sad`, `surprise`

El preprocesamiento del autor se reproduce en `EmotionDetector.kt`: conversión
a gris, escalado bilineal a 48 x 48 con redondeo a `uint8`, réplica a tres
canales, escalado bilineal a 96 x 96 en `float32` y normalización a `[-1, 1]`.

El modelo estima expresiones visibles en una imagen. No determina el estado
emocional interno de una persona ni debe usarse como diagnóstico.
