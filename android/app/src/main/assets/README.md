# Modelo de expresiones faciales EmotiScan

`emotion_model.tflite` es la variante float16 de **EmotiScan
FaceExpressionNet for Android**, convertida desde los pesos de
`@vladmandic/face-api` 1.7.15.

- Archivo original: `emotiscan_expression_float16.tflite`
- Licencia de la red original: MIT (ver `LICENSE-emotiscan-face-api.txt`)
- SHA-256: `df4ed33f86a398fe28466c1969388b5fc048cc5132e9f94a9c9b05ef8230bd6e`
- Entrada: `float32 [1, 112, 112, 3]`, RGB en rango `0..255`
- Salida: `float32 [1, 7]`, probabilidades Softmax
- Clases: `neutral`, `happy`, `sad`, `angry`, `fearful`, `disgusted`,
  `surprised`

El preprocesamiento se reproduce en `EmotionDetector.kt`: recorte facial con
un margen del 12 %, escalado a 112 x 112 y escritura RGB `float32` sin
normalización externa. La resta de la media RGB `[122.782, 117.001, 104.298]`
y la división entre 255 están incluidas dentro del modelo.

El proyecto mantiene cinco emociones de negocio. `fearful` y `disgusted` se
traducen a `unknown` y el estabilizador las ignora hasta recibir una predicción
compatible.

El modelo estima expresiones visibles en una imagen. No determina el estado
emocional interno de una persona ni debe usarse como diagnóstico.
