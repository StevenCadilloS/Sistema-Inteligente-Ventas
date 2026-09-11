# Estabilización del detector binario

`EmotionProcessor.kt` recibe las respuestas crudas del detector y evita que un
fotograma aislado cambie la negociación.

## Comportamiento

- Mantiene una ventana móvil de 12 fotogramas.
- Exige que una respuesta reúna al menos 65% de los votos.
- Exige tres votos de ventaja para desplazar la respuesta vigente.
- Promedia la confianza de los fotogramas ganadores.
- Conserva `incierto` como resultado válido, pero la capa de decisión no lo
  interpreta como favorable ni desfavorable.
- Tolera pérdidas aisladas del rostro y comunica `no_face` después de cinco
  fotogramas consecutivos sin cara.
- `reset()` limpia el filtro al terminar la interacción.

```text
favorable / desfavorable / incierto / no_face
  -> ventana de 12 fotogramas
  -> mayoría e histéresis
  -> ProcessedEmotion
  -> EventChannel
```

El procesador no detecta rostros ni decide descuentos. Solo estabiliza la
salida producida por el detector.
