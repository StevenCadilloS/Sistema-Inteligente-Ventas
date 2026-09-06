# Fase 2 - Procesamiento

Esta carpeta contiene la lógica encargada de estabilizar las emociones detectadas antes de enviarlas a la fase de decisión.

## Archivo principal

### `EmotionProcessor.kt`
Recibe los resultados crudos producidos por `EmotionDetector.kt` y evita que una predicción aislada cambie inmediatamente el comportamiento de la aplicación.

## Qué se implementó en `EmotionProcessor.kt`

- Recepción de objetos `EmotionResult` provenientes del detector.
- Buffer de resultados recientes.
- Umbral de estabilidad de `10` frames consecutivos.
- Confirmación de una emoción solamente cuando se mantiene durante el número requerido de frames.
- Conservación de la última emoción estable mientras las nuevas predicciones todavía son inestables.
- Cálculo de la confianza promedio de los frames utilizados para confirmar la emoción.
- Manejo del caso `no_face` sin convertirlo automáticamente en una emoción válida del usuario.
- Devolución de un `ProcessedEmotion` con:
  - emoción procesada,
  - confianza promedio,
  - indicador `isStable`.
- Método `reset()` para limpiar el estado del procesador cuando sea necesario.

## Flujo

```text
EmotionDetector
      ↓
EmotionResult crudo
      ↓
EmotionProcessor
      ↓
Buffer de N frames
      ↓
¿La emoción se mantiene durante 10 frames?
   ├── No → mantener última emoción estable
   └── Sí → confirmar nueva emoción
      ↓
ProcessedEmotion
      ↓
AdaptationEngine
```

## Objetivo

El filtro reduce cambios bruscos causados por situaciones momentáneas como:

- parpadeos,
- movimientos rápidos de la cabeza,
- variaciones de iluminación,
- predicciones aisladas del modelo.

## Separación de responsabilidades

`EmotionProcessor.kt` no detecta rostros ni ejecuta TensorFlow Lite.

Su única responsabilidad es procesar y estabilizar los resultados entregados por la fase de contexto, manteniendo separado el pipeline:

```text
CONTEXTO → PROCESAMIENTO → DECISIÓN → ADAPTACIÓN
```
