# Detector binario de respuesta facial

Esta carpeta contiene la captura de cámara y la clasificación facial que usa
la negociación.

## Qué detecta

El detector ya no intenta asignar cinco emociones. Produce únicamente:

- `favorable`: sonrisa con probabilidad igual o mayor a `0.65`.
- `desfavorable`: sonrisa con probabilidad igual o menor a `0.35`.
- `incierto`: zona intermedia, rostro pequeño, mala pose o clasificación no
  disponible.
- `no_face`: no se encontró un rostro.

La zona incierta es intencional: una lectura ambigua nunca debe convertirse
automáticamente en un descuento.

## Flujo

```text
CameraX (640x480, cámara frontal)
  -> ML Kit encuentra el rostro principal
  -> valida tamaño y pose
  -> ML Kit calcula smilingProbability
  -> favorable / desfavorable / incierto
  -> EmotionProcessor estabiliza 12 frames
  -> EventChannel envía la respuesta a Flutter
```

## Controles de calidad

- El rostro debe medir al menos 96 x 96 píxeles.
- La cabeza debe estar aproximadamente frontal: yaw y roll dentro de 18
  grados, pitch dentro de 20 grados.
- Se usan landmarks y modo de clasificación de ML Kit.
- Se conserva una franja de incertidumbre entre 0.35 y 0.65.
- Todo corre en el teléfono; ninguna imagen se guarda ni se envía.

## Calibración

Los umbrales están centralizados en `EmotionDetector.kt`. Antes de cambiarlos,
registrar pruebas con varias personas, iluminación y distancias, y medir falsos
favorables y falsos desfavorables. No se deben ajustar mirando únicamente a una
persona.

El archivo `android/app/src/main/assets/emotion_model.tflite` pertenece al
detector multiclase anterior y ya no se carga. Se conserva temporalmente para
facilitar la comparación o una reversión.
