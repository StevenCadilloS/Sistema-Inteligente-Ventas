# Fase 2 — Procesamiento

Esta carpeta estabiliza las emociones detectadas antes de que lleguen a la fase de
decisión. Sin ella, una predicción aislada movería el precio.

## Archivo principal

### `EmotionProcessor.kt`

Recibe los `EmotionResult` crudos de `EmotionDetector.kt` y decide cuándo una emoción es
lo bastante firme como para declararla estable.

## Cómo decide

El clasificador es ruidoso fotograma a fotograma: medido en dispositivo, alterna entre dos
clases 48% / 42% sobre la misma cara quieta. Por eso el filtro no exige que la ventana
entera sea idéntica —eso no daba estabilidad, daba saltos— sino que combina tres reglas:

| Regla | Valor | Por qué |
|---|---|---|
| Tamaño de la ventana | `26` frames (~1,3 s a ~20 fps) | Filtra el ruido sin que la app se sienta lenta |
| Mayoría mínima | `0.45` de la ventana | La clase correcta gana con ~54% de los frames; con 0.6 no se confirmaba ninguna emoción nunca |
| Margen para desplazar a la vigente | `6` votos | Sin histéresis, dos clases empatadas se turnaban el primer puesto y la emoción cambiaba ~1 vez por segundo |

Resultado medido: los cambios de emoción bajaron de **16 a 7 en 20 segundos** con el
usuario quieto.

## El caso `no_face`

`no_face` nunca se confirma como emoción. La ventana **no** se limpia en el primer frame
sin rostro: con la cámara real, ML Kit pierde el rostro un frame suelto cada ~1 s por
movimiento o desenfoque, y limpiar en cada uno reiniciaba la ventana antes de completar
los 26 frames — la emoción no llegaba a estabilizarse nunca.

Solo tras `MAX_FRAMES_SIN_ROSTRO = 5` lecturas seguidas sin rostro se descarta la ventana
y se avisa una única vez a la interfaz con `rostroPerdido`. La emoción vigente se conserva
a propósito: reiniciarla a neutral fabricaba transiciones falsas cada vez que el rostro
salía un instante de cuadro (medido: 143 de ~430 frames sin rostro en 20 s de uso normal).

## Qué devuelve

Un `ProcessedEmotion` con la emoción, la confianza promedio de los frames que la
confirmaron, el indicador `isStable` y el flanco `rostroPerdido`. `reset()` limpia el
estado al cambiar de producto o de pantalla.

## Flujo

```text
EmotionDetector
      ↓  EmotionResult crudo
EmotionProcessor
      ↓  ventana de 26 frames
¿Alguna clase gana el 45% de la ventana?
   ├── No → mantener la última emoción estable (isStable = false)
   └── Sí → ¿le gana a la vigente por 6 votos o más?
             ├── No → mantener la vigente
             └── Sí → confirmar la nueva (isStable = true)
      ↓  ProcessedEmotion
EmotionChannelHandler → EventChannel → Dart
```

## Separación de responsabilidades

`EmotionProcessor.kt` no detecta rostros ni ejecuta TensorFlow Lite, y tampoco sabe qué es
una oferta: su única responsabilidad es estabilizar lo que entrega la fase de contexto.
Quien decide qué hacer con la emoción es `lib/decision/negociacion.dart`, en Dart.

```text
CONTEXTO → PROCESAMIENTO → DECISIÓN → ADAPTACIÓN
            (esta carpeta)
```
