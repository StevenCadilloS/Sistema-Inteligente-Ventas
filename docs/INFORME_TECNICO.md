# Tienda Adaptativa — Informe técnico

**Taller 1 · Desarrollo de una Aplicación Adaptativa · UNI FIIS · 2026-1**
Equipo: Elvis Arboleda (base de datos, motor de reglas, autenticación) · Juan Medina
(modelo de emociones) · Steven Cadillo (frontend e integración con la cámara)

---

## 1. Descripción de la aplicación

Tienda móvil que **ajusta su oferta comercial en tiempo real según la expresión facial
del cliente**.

En una tienda física el vendedor nota si el cliente duda o se entusiasma, y reacciona:
cambia el producto, baja el precio o propone una alternativa. En una tienda digital esa
señal se pierde. La aplicación recupera ese canal: lee la expresión con la cámara frontal
y adapta qué productos ve y a qué precio, sin que el cliente pida nada ni pulse un botón.

## 2. Contexto utilizado

La variable de entorno es la **interacción del usuario**, capturada como expresión facial
a través de la cámara frontal. De cada lectura se obtienen dos datos:

| Dato | Valores |
|---|---|
| Emoción | `triste`, `feliz`, `sorpresa`, `neutral`, `enojo` |
| Nivel de interés | 0–100 (confianza del clasificador) |

La cámara trabaja **en segundo plano y sin previsualización**: el cliente navega, no posa
para una foto.

## 3. Comportamiento adaptativo

**Condición que dispara la adaptación:** que la emoción estable del cliente cambie.

Ante ese cambio la aplicación reordena el catálogo **sola, sin intervención manual** —el
requisito eliminatorio del taller—. Si además el cliente toca un producto, se abre una
negociación de tres pasos:

| Paso | Qué hace la aplicación |
|---|---|
| Cambia la emoción | Reordena el catálogo según la regla de esa emoción (automático) |
| El cliente toca un producto | Lo ofrece **a precio de lista** |
| Rechaza | Contraoferta del mismo producto **con el descuento que decide su expresión** |
| Rechaza de nuevo | Ofrece un **bien sustituto**: misma categoría, más económico |
| Rechaza el sustituto | Deja de insistir |

Reglas por emoción (viven en `AdaptationEngine`):

| Emoción | Orden del catálogo | Descuento |
|---|---|---|
| `triste` | Precio ascendente (sustituto económico) | 10% |
| `feliz` | Precio descendente (premium) | 0% |
| `sorpresa` | Menos mostrado (novedad) | 15% |
| `neutral` | Más mostrado (estándar) | 0% |
| `enojo` | Otra categoría, la más económica | 25% |

El descuento **no es decorativo**: el precio rebajado se congela en
`detalleVenta.precioUnitarioCentavos` al cerrar la venta, con aritmética entera en
centavos.

## 4. Pipeline adaptativo

```
ENTRADA (contexto)          PROCESAMIENTO           DECISIÓN               ADAPTACIÓN
─────────────────────  →  ─────────────────  →  ─────────────────  →  ──────────────────
CameraX captura frames    Ventana de 26          Regla de la emoción    Reordena el feed
ML Kit ubica el rostro    frames, voto por       elige y ordena el      del catálogo
TFLite clasifica la       mayoría (45%) con      catálogo; UCB1 elige   Propone la oferta
expresión (48x48 px)      histéresis             la estrategia          con su descuento
```

El **procesamiento** existe porque el clasificador es ruidoso frame a frame: exigir
unanimidad no daba estabilidad, daba saltos. Con voto por mayoría e histéresis los
cambios de emoción bajaron de 16 a 7 en 20 segundos.

## 5. Evidencia de adaptación

La aplicación **registra cada oferta con la emoción que la disparó**, así que la
evidencia es la propia base de datos (`python tools/ver_base.py`). Medición sobre 163
interacciones reales en dispositivo:

| Estrategia | Intentos | Conversión |
|---|---|---|
| Oferta relámpago | 51 | 15.7% |
| Descuento directo | 28 | 0% |

El sistema **dejó de gastar intentos** en la estrategia que no cerraba: eso es el UCB1
aprendiendo, no una regla escrita a mano.

Respaldo automatizado: 45 pruebas Dart y 9 JUnit, una de ellas fija la regla
eliminatoria — *la oferta cambia sola sin intervención manual*.

## 6. Justificación técnica

Un sistema **reactivo** responde a una orden. Este responde a una **condición del
contexto que el usuario no emite a propósito**: nadie sonríe *para* pedir un descuento.
No hay botón que dispare la adaptación. Cumple los cinco conceptos del curso:

| Concepto | Cómo se cumple |
|---|---|
| Software adaptativo | La oferta y el orden del catálogo cambian sin intervención manual |
| Adaptación al contexto | La variable es la expresión facial, capturada de la cámara frontal |
| Procesamiento en tiempo real | ~30 ms por frame; la emoción estable llega en 1–2 s |
| Uso de capacidades del dispositivo | CameraX, ML Kit y TensorFlow Lite, todo en el dispositivo |
| Diseño responsivo | La grilla recalcula columnas con `LayoutBuilder` (2 a 4 según ancho) |

## 7. Arquitectura / componentes principales

```
ANDROID NATIVO (Kotlin)
  CameraManager ──► EmotionDetector ──────► EmotionProcessor
   (CameraX)       (ML Kit + TFLite)        (estabilización)
                                                   │ EventChannel
FLUTTER (Dart)                                     ▼ {emoción, confianza}
  TiendaScreen ──► AdaptationEngine ──────► BanditOptimizer (UCB1)
  (feed+oferta)   (reglas y descuento)             │
                            └──────► AppDatabase (drift/SQLite, 10 tablas)
                                             └──► BatchRunner (cierre, KPIs)
```

Separación de capas: el módulo nativo solo produce la emoción; el motor de decisión no
conoce widgets ni cámara; la interfaz decide *cuándo* preguntar, nunca *qué* ofrecer.
Todo corre en el dispositivo, sin servidor.

## 8. Tecnologías utilizadas

| Capa | Tecnología |
|---|---|
| Aplicación | Flutter 3.47 / Dart 3.13 (Material 3) |
| Módulo nativo | Kotlin, `minSdk` 26 |
| Cámara | AndroidX CameraX 1.3.4 (`ImageAnalysis`, cámara frontal) |
| Detección de rostro | Google ML Kit Face Detection 16.1.6 |
| Clasificación de emoción | TensorFlow Lite 2.16.1, modelo FER (48×48, 7 clases) |
| Puente nativo ↔ Flutter | `EventChannel` (stream continuo) |
| Persistencia | `drift` 2.34 sobre SQLite (10 tablas, FK activas) |
| Sesión y tareas | `shared_preferences`, `workmanager` (cierre diario) |
| Pruebas | `flutter_test` (45 casos) y JUnit 4.13 (9 casos, JVM) |

## 9. Ubicación del código relevante

| Elemento | Archivo / clase |
|---|---|
| Captura y clasificación del contexto | `android/.../context/CameraManager.kt` · `EmotionDetector.kt` |
| Procesamiento (estabilización) | `android/.../processing/EmotionProcessor.kt` |
| Puente nativo ↔ Flutter | `android/.../channel/EmotionChannelHandler.kt` · `lib/services/emotion_channel.dart` |
| Decisión (reglas y descuentos) | `lib/decision/adaptation_engine.dart` |
| Aprendizaje (UCB1) | `lib/decision/learning/bandit_optimizer.dart` |
| Adaptación (interfaz) | `lib/ui/tienda_screen.dart` |
| Persistencia | `lib/data/database/app_database.dart` · `tables.dart` |

---

**Verificación:** probado en dispositivo real (Xiaomi Redmi, Android 12),
`flutter analyze` sin observaciones.

**Limitación conocida:** el modelo clasifica sobre 48×48 píxeles y confunde *triste* con
*enojo*, ya que ambas expresiones bajan las cejas. Es el techo del modelo, no del
pipeline: las correcciones de preprocesamiento (escala de grises, ecualización de
histograma y recorte cuadrado) redujeron el error de "enojo" con rostro neutral del 49%
al 5%.
