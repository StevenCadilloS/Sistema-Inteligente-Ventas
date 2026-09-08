# Tienda Adaptativa — Informe técnico

**Taller 1 · Desarrollo de una Aplicación Adaptativa · UNI FIIS · 2026-1**
Equipo: Elvis Arboleda (base de datos, motor de reglas, autenticación) · Juan Medina
(modelo de emociones) · Steven Cadillo (frontend e integración con la cámara)

---

## 1. Descripción de la aplicación

Tienda móvil que **ajusta su oferta comercial en tiempo real según la expresión facial
del cliente**.

En una tienda física un vendedor nota si el cliente duda, se entusiasma o se fastidia, y
reacciona: le cambia el producto, le baja el precio o le propone una alternativa. En una
tienda digital esa señal se pierde por completo. La aplicación recupera ese canal: lee la
expresión del cliente con la cámara frontal y adapta qué productos ve y a qué precio, sin
que él tenga que pedir nada ni pulsar ningún botón.

## 2. Contexto utilizado

La variable de entorno es la **interacción del usuario**, capturada como expresión facial
a través de la cámara frontal. De cada lectura se obtienen dos datos:

| Dato | Valores |
|---|---|
| Emoción | `triste`, `feliz`, `sorpresa`, `neutral`, `enojo` |
| Nivel de interés | 0–100 (confianza del clasificador) |

La cámara trabaja **en segundo plano y sin previsualización**: el cliente navega la tienda
normalmente, no posa para una foto.

## 3. Comportamiento adaptativo

**Condición que dispara la adaptación:** que la emoción estable del cliente cambie.

Ante ese cambio la aplicación reordena el catálogo **sola, sin intervención manual**, que
es el requisito eliminatorio del taller. Cuando además el cliente muestra interés en un
producto, se abre una negociación de tres pasos:

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

## 5. Arquitectura / componentes principales

```
┌──────────────── ANDROID NATIVO (Kotlin) ─────────────────┐
│                                                          │
│  CameraManager ──►  EmotionDetector  ──►  EmotionProcessor
│   (CameraX)        (ML Kit + TFLite)      (estabilización)
│                                                          │
└──────────────────────────┬───────────────────────────────┘
                           │  EventChannel
                           │  { emoción, confianza }
┌──────────────────────────▼───────────────────────────────┐
│                      FLUTTER (Dart)                      │
│                                                          │
│   TiendaScreen ──►  AdaptationEngine  ──►  BanditOptimizer
│  (feed + oferta)   (reglas y descuento)     (UCB1)       │
│                            │                     │       │
│                            ▼                     ▼       │
│                   AppDatabase (drift / SQLite, 10 tablas)│
│                            │                             │
│                            ▼                             │
│                    BatchRunner (cierre diario, KPIs)     │
└──────────────────────────────────────────────────────────┘
```

Separación de capas: el módulo nativo solo produce la emoción; el motor de decisión no
conoce widgets ni cámara; la interfaz decide *cuándo* preguntar, nunca *qué* ofrecer.
Todo corre en el dispositivo, sin servidor.

## 6. Tecnologías utilizadas

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

## 7. Ubicación del código relevante

| Elemento | Archivo / clase |
|---|---|
| Captura del contexto | `android/.../context/CameraManager.kt` |
| Clasificación de la emoción | `android/.../context/EmotionDetector.kt` |
| Procesamiento (estabilización) | `android/.../processing/EmotionProcessor.kt` |
| Puente nativo ↔ Flutter | `android/.../channel/EmotionChannelHandler.kt` · `lib/services/emotion_channel.dart` |
| Decisión (reglas y descuentos) | `lib/decision/adaptation_engine.dart` |
| Aprendizaje (UCB1) | `lib/decision/learning/bandit_optimizer.dart` |
| Adaptación (interfaz) | `lib/ui/tienda_screen.dart` |
| Persistencia | `lib/data/database/app_database.dart` · `tables.dart` |
| Punto de entrada | `lib/main.dart` · `android/.../MainActivity.kt` |

---

**Verificación:** probado en dispositivo real (Xiaomi Redmi, Android 12). 45 pruebas Dart
y 9 Kotlin en verde, `flutter analyze` sin observaciones.

**Limitación conocida:** el modelo clasifica sobre 48×48 píxeles y confunde *triste* con
*enojo*, ya que ambas expresiones bajan las cejas. Es el techo del modelo, no del
pipeline: las correcciones de preprocesamiento (escala de grises, ecualización de
histograma y recorte cuadrado) redujeron el error de "enojo" con rostro neutral del 49%
al 5%.
