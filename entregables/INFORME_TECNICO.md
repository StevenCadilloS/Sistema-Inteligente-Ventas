# Tienda Adaptativa — Informe técnico

**Taller 1 · Desarrollo de una Aplicación Adaptativa · UNI FIIS · 2026-2**
Elvis Arboleda (base de datos, motor de reglas, autenticación) · Juan Medina (modelo de
emociones) · Steven Cadillo (frontend e integración con la cámara)

## 1. Descripción de la aplicación

**El problema:** mostrar la oferta correcta, en el momento correcto, sin regalar margen ni
depender de que el cliente pulse "ver ofertas".

En una tienda física el vendedor nota que el cliente duda frente al precio y reacciona. En
una tienda digital esa señal se pierde: o el descuento se publica para todos, o no existe.
La aplicación la recupera con la cámara frontal y la usa para decidir **cuándo** pasar al
siguiente escalón de una escalera de ofertas que un administrador configuró en la base de
datos.

> **La emoción no calcula el descuento.** Solo decide si el sistema se queda donde está o
> avanza un escalón. Los porcentajes, su orden y su vigencia viven en PostgreSQL y los
> publica una persona; la app no inventa precios. El contexto gobierna el *ritmo* de la
> negociación, nunca su contenido.

## 2. Contexto utilizado

La variable de entorno es la **interacción del usuario**, capturada como expresión facial
por la cámara frontal. Cada lectura estable entrega una emoción (`feliz`, `sorpresa`,
`neutral`, `triste`, `enojo`, o `no_face`) y la confianza del clasificador (0–1).

La cámara trabaja **sin previsualización** y solo durante una negociación: se enciende al
seleccionar un producto y se apaga al terminar. Ningún fotograma sale del teléfono; la
clasificación ocurre en el dispositivo y la etiqueta se consume ahí mismo.

## 3. Comportamiento adaptativo

**Condición que dispara la adaptación:** que en una ventana de observación de 8 s la
respuesta mayoritaria del cliente sea **desfavorable**.

**Qué hace automáticamente:** avanza un escalón de la escalera del producto —baja el
precio y cambia el mensaje— sin que el cliente pulse nada. La ventana se reabre y el ciclo
se repite hasta que compra, abandona o la escalera se agota.

| Grupo | Emociones | Efecto |
|---|---|---|
| **Favorable** | `feliz`, `sorpresa` | Mantiene el precio actual |
| **Desfavorable** | `neutral`, `triste`, `enojo` | **Avanza un escalón** (p. ej. S/2500 → 10% → 20% → 30%) |
| **Sin señal** | `no_face`, o menos de 2 lecturas | No hace nada |

Se cuentan votos en la ventana, no una sola lectura; un empate se resuelve como favorable,
porque ante la duda no se regala margen. `neutral` cuenta como desfavorable por decisión de
producto, y conviene saber lo que implica: la cara en reposo frente a una pantalla suele
clasificarse así, de modo que la mayoría de clientes verá avanzar la escalera.

La escalada **siempre termina**: el puntero solo avanza y la escalera es finita. Un
producto sin escalera no mueve su precio pase lo que pase, y un cliente que ya usó su
oferta del día recibe la escalera vacía.

## 4. Pipeline adaptativo

```
ENTRADA (contexto)        PROCESAMIENTO           DECISIÓN              ADAPTACIÓN
─────────────────────  →  ───────────────────  →  ─────────────────  →  ────────────────
CameraX entrega frames    Ventana de 26 frames    Cuenta los votos      Avanza el puntero
ML Kit ubica el rostro    Mayoría 45% +           de la ventana y       de la escalera
TFLite clasifica la       histéresis (margen 6)   devuelve mantener/    Repinta el precio;
expresión (48x48 px)      → emoción estable       avanzar/terminar      reabre la ventana
      Kotlin                    Kotlin              Dart (sin UI)           Dart (UI)
```

El **procesamiento** no es un adorno: el clasificador alterna entre dos clases 48% / 42%
sobre la misma cara quieta. Exigir unanimidad no daba estabilidad, daba saltos; con voto
por mayoría e histéresis los cambios de emoción bajaron de **16 a 7 en 20 segundos**. La
**decisión** es Dart puro, sin cámara ni widgets: recibe etiquetas y devuelve un paso, y
por eso se prueba entera sin dispositivo.

## 5. Arquitectura / componentes principales

```
┌─────────────────── CELULAR ───────────────────┐   ┌─── SERVIDOR (PostgreSQL) ───┐
│ CONTEXTO (Kotlin)                              │   │ v_catalogo                  │
│   CameraManager ──> EmotionDetector            │   │ v_secuencia_ofertas         │
│ PROCESAMIENTO (Kotlin)     │                   │   │ v_ofertas_vigentes          │
│   EmotionProcessor — 26 frames, mayoría        │   │                             │
│                            │ EventChannel      │   │ fn_ofertas_de()             │
│ DECISIÓN (Dart puro)       v {emoción, conf.}  │<->│ fn_confirmar_carrito()      │
│   ClasificadorRespuesta ──> Negociacion        │   │ fn_puede_usar_oferta()      │
│ ADAPTACIÓN (Dart / UI)     │ (puntero)         │   │                             │
│   TiendaScreen ──> TiendaRepository ───────────┼──>│ RLS sobre las 11 tablas     │
└────────────────────────────────────────────────┘   └─────────────────────────────┘
```

El módulo nativo solo produce emociones y no sabe qué es una oferta; el motor de decisión
no conoce widgets ni cámara; la interfaz decide *cuándo* observar, nunca *qué* ofrecer; el
servidor es el único que fija precios. El reparto no es estético: el APK lleva una clave
que cualquiera puede extraer, así que **no tiene permiso de escritura sobre ninguna
tabla** — sus escrituras pasan por funciones `SECURITY DEFINER`, y `fn_confirmar_carrito`
no recibe el total (lo recalcula) ni el id del cliente (lo saca del token).

## 6. Tecnologías utilizadas

| Capa | Tecnología |
|---|---|
| Aplicación | Flutter 3.47.3 / Dart 3.13 (Material 3) · Kotlin, `minSdk` 26 |
| Contexto | CameraX 1.3.4 (`ImageAnalysis`, frontal) · ML Kit Face Detection 16.1.6 |
| Clasificación | TensorFlow Lite 2.16.1 · FER-2013 (48×48, 7 clases → 5 de negocio) |
| Puente nativo ↔ Flutter | `EventChannel` (flujo continuo) |
| Backend | PostgreSQL vía Supabase: 11 tablas, 3 vistas, 13 funciones, RLS, 17 migraciones · Realtime · Auth |
| Pruebas | 181 Dart (`flutter_test`) · 9 JUnit (JVM) · 3 suites SQL sobre PostgreSQL 16 |

## 7. Ubicación del código relevante

| Elemento | Archivo / clase |
|---|---|
| **Captura del contexto** | `android/.../context/CameraManager.kt` · `context/EmotionDetector.kt` |
| **Procesamiento** | `android/.../processing/EmotionProcessor.kt` |
| Puente nativo ↔ Flutter | `android/.../channel/EmotionChannelHandler.kt` · `lib/services/emotion_channel.dart` |
| **Decisión** | `lib/decision/negociacion.dart` (`ClasificadorRespuesta`, `Negociacion`) |
| **Adaptación** | `lib/ui/tienda_screen.dart` (`_evaluarVentana`, `_abrirVentana`) |
| Escalera y reglas de negocio | `supabase/migrations/0002_funciones.sql` · `0013_limite_oferta_unica.sql` |

---

**Verificación.** `flutter test` → **181 pruebas en verde**; `./gradlew testDebugUnitTest`
→ 9; las 3 suites SQL corren en CI contra un PostgreSQL 16 real. Una fija la regla
eliminatoria —*la oferta avanza sola, sin intervención manual*—; otra comprueba que la
clave del APK no pueda cambiar un precio. Probado en dispositivo real (Xiaomi Redmi,
Android 12).

**Limitación conocida.** El modelo clasifica sobre 48×48 px y confunde *triste* con
*enojo*: ambas bajan las cejas. Es el techo del modelo, no del pipeline — ambas caen en el
grupo *desfavorable*, así que la confusión no altera la decisión. El preprocesamiento
(grises, ecualización de histograma, recorte cuadrado) redujo el error de "enojo" con
rostro neutral del 49% al 5%.
