# Retos técnicos en vivo — Taller 1

Guía de defensa oral. Cada reto sale de un requisito literal de `docs/Taller 01.pdf`.
Formato: **qué te pueden pedir → dónde está → cómo lo haces delante del docente**.

Solo texto y tablas, imprimible.

---

## 0. Antes de entrar al aula

| Acción | Comando |
|---|---|
| Dejar la app corriendo con hot reload | `flutter run` (déjalo abierto: la tecla `r` recarga en 1 s) |
| Ver la base del celular | `python tools/ver_base.py` |
| Ver el esquema SQL real | `python tools/ver_base.py esquema` |
| Volcar una tabla | `python tools/ver_base.py ventas` |
| Limpiar datos para demo desde cero | `adb shell pm clear com.tuapp.tienda_adaptativa` |
| Correr pruebas | `flutter test` (45) · `cd android && ./gradlew testDebugUnitTest` (9) |

**La regla de oro del cambio en vivo:**

| Cambias… | Tiempo | Cómo |
|---|---|---|
| Dart (`lib/`) | ~1 segundo | tecla `r` en la consola de `flutter run` |
| Dart con estado nuevo (campos, `initState`) | ~5 segundos | tecla `R` (hot restart) |
| Esquema de BD (`tables.dart`) | ~1 minuto | `dart run build_runner build --delete-conflicting-outputs` + `pm clear` |
| Kotlin (`android/`) | ~2 minutos | `flutter run` completo — **no hay hot reload** |

> Si te dan a elegir qué cambiar, **elige algo en Dart**. Un cambio en Kotlin te deja
> 2 minutos en silencio frente a la clase.

---

## Bloque A — Funcionalidad Adaptativa (8 pts)

> *"No se considerará adaptativo si el comportamiento requiere intervención manual."*
> Es la frase eliminatoria del PDF (pág. 14). Todo este bloque existe para responderla.

### A1. "Demuéstrame que se adapta sin que toques nada"

**El reto más probable de todos.** Es la condición eliminatoria.

| | |
|---|---|
| **Dónde** | `lib/ui/tienda_screen.dart:149` → `_adaptarA()` |
| **Prueba que lo respalda** | `test/decision/adaptation_engine_test.dart` → *"la regla eliminatoria: la oferta cambia sola sin intervención manual"* |

**En vivo:**
1. Abre la app y **suelta el celular sobre la mesa**, manos visibles y quietas.
2. Cambia de expresión (sonríe, luego frunce el ceño).
3. El chip de emoción cambia y **el feed se reordena solo**.

Frase para acompañar: *"no toqué la pantalla; el único disparador fue mi cara."*

Si te piden verlo en el código, muestra que `_adaptarA` se llama desde el `listen` del
stream (`tienda_screen.dart:144`), no desde ningún `onPressed`.

### A2. "Cambia una regla de adaptación"

| | |
|---|---|
| **Dónde** | `lib/decision/adaptation_engine.dart:208` → `_descuentoPara()` |

Reglas actuales:

| Emoción | Orden del catálogo | Descuento |
|---|---|---|
| `triste` | precio ascendente | 10% |
| `feliz` | precio descendente | 0% |
| `sorpresa` | menos mostrado | 15% |
| `neutral` | más mostrado | 0% |
| `enojo` | otra categoría, la más barata | 25% |

**En vivo:** cambia el `10` de `triste` por `20`, guarda, pulsa `r`. Rechaza una oferta
poniendo cara triste y el popup muestra −20%.

### A3. "Cambia qué productos ve una emoción"

| | |
|---|---|
| **Dónde** | `lib/decision/adaptation_engine.dart:286` → `catalogoPara()` |

Cada emoción tiene su consulta con su `orderBy`. Para invertir el criterio de `feliz`
(que hoy muestra lo caro primero), cambias su `OrderingMode` a ascendente. `r` y listo.

### A4. "¿Y si no hay nadie frente a la cámara?"

| | |
|---|---|
| **Dónde** | `android/.../processing/EmotionProcessor.kt:168` → `MAX_FRAMES_SIN_ROSTRO = 5` |
| | `lib/ui/tienda_screen.dart:118` → rama `no_face` |

**Respuesta:** tras 5 frames seguidos sin rostro se emite `no_face`, el chip vuelve a
"Leyendo…" y el feed **se queda como está** en vez de congelarse con una emoción falsa.

**En vivo:** tapa la cámara frontal con el dedo. El chip cambia en ~1 segundo.

Las cuatro constantes que gobiernan la estabilización viven juntas en el `companion
object` (`EmotionProcessor.kt:146`), y son las que tocarías si te piden calibrar:

| Constante | Línea | Valor |
|---|---|---|
| `DEFAULT_STABILITY_THRESHOLD` | 152 | 26 frames de ventana |
| `MARGEN_PARA_CAMBIAR` | 158 | 6 votos de histéresis |
| `MAYORIA_MINIMA` | 166 | 0.45 |
| `MAX_FRAMES_SIN_ROSTRO` | 168 | 5 |

Es una señal **por flanco**: se dispara una sola vez al cruzar el umbral, no en cada
frame. Si preguntan por qué, la razón es que antes un solo frame malo borraba la ventana
de estabilización y la emoción nunca se asentaba.

### A5. "¿Esto es tiempo real? ¿Cuánto tarda?"

| Etapa | Tiempo |
|---|---|
| Frame → emoción cruda | ~30 ms (ML Kit `PERFORMANCE_MODE_FAST` + TFLite) |
| Emoción cruda → emoción estable | ventana de 26 frames ≈ 1–2 s |
| Emoción estable → feed reordenado | 1 consulta SQLite, < 50 ms |

**El argumento fuerte:** la latencia no es un defecto, es una **decisión de diseño**.
Sin la ventana, la etiqueta saltaba 16 veces en 20 segundos; con voto por mayoría e
histéresis bajó a 7. Un vendedor tampoco cambia de oferta cada 200 ms.

---

## Bloque B — Diseño e Implementación Técnica (6 pts)

### B1. "Señálame el pipeline: Entrada → Procesamiento → Decisión → Adaptación"

Es **obligatorio** en el PDF (pág. 8). Ténlo memorizado en este orden:

| Etapa | Archivo | Qué hace |
|---|---|---|
| **Entrada** | `android/.../context/CameraManager.kt:71` | CameraX captura frames de la cámara frontal |
| | `android/.../context/EmotionDetector.kt` | ML Kit ubica el rostro, TFLite clasifica (48×48) |
| **Procesamiento** | `android/.../processing/EmotionProcessor.kt:146` | ventana de 26 frames, voto por mayoría (45%), histéresis (6) |
| **Decisión** | `lib/decision/adaptation_engine.dart:68` | la regla de la emoción elige y ordena el catálogo |
| | `lib/decision/learning/bandit_optimizer.dart:124` | UCB1 elige la estrategia de persuasión |
| **Adaptación** | `lib/ui/tienda_screen.dart:149` | reordena el feed y lanza la oferta |

El puente entre las dos mitades es el `EventChannel` (`lib/services/emotion_channel.dart:11`).

### B2. "¿La interfaz decide qué ofrecer?"

**Respuesta: no, y es deliberado.**

| Capa | Responsabilidad | Qué NO conoce |
|---|---|---|
| `lib/ui/` | *cuándo* preguntar | no sabe qué descuento aplica |
| `lib/decision/` | *qué* ofrecer y a qué precio | no conoce widgets ni cámara |
| `lib/data/` | persistencia | no conoce reglas de negocio |
| `android/.../context/` | solo produce la emoción | no sabe que existe una tienda |

**Prueba objetiva:** en `lib/decision/adaptation_engine.dart` no hay ni un `import`
de Flutter Material. Ábrelo y muestra la cabecera. Por eso las 45 pruebas corren sin
emulador.

### B3. "¿Cómo abstraes el acceso al contexto?"

El PDF pide *"abstracción del acceso al contexto (clases/servicios)"* (pág. 7).

| | |
|---|---|
| **Dónde** | `lib/services/emotion_channel.dart:10` |

```dart
class EmotionChannel {
  static const _channel = EventChannel('com.tuapp.tienda_adaptativa/emotion');
  Stream<EmocionDetectada> get emociones => ...
}
```

La UI recibe un `Stream<EmocionDetectada>` de Dart puro. **No sabe que detrás hay una
cámara.** Si mañana el contexto viniera de un sensor de batería, cambia esta clase y
nada más.

Remate: por eso las pruebas inyectan un stream falso sin necesitar cámara.

### B4. "¿Dónde está la asincronía?"

| Mecanismo | Dónde | Para qué |
|---|---|---|
| `Stream` + `listen` | `tienda_screen.dart:113` | eventos de emoción, no bloqueantes |
| `async` / `await` | todo `adaptation_engine.dart` | consultas SQLite fuera del hilo de UI |
| Thread pool (Kotlin) | `CameraManager.kt` → `analyzerExecutor` | el análisis de imagen no bloquea la UI |
| `Handler(Looper.getMainLooper())` | `EmotionChannelHandler.kt` | **volver** al hilo principal para emitir |

**El detalle que suma puntos:** el último. `EventSink.success()` está anotado `@UiThread`;
llamarlo desde el hilo de la cámara lanza excepción. Aquí se cruza de vuelta al hilo
principal explícitamente. Es *concurrencia controlada*, la frase exacta del PDF.

### B5. "Sales de la app, ¿qué pasa con la cámara?"

El PDF pide *"registro / liberación de listeners o sensores, evitar fugas"* (pág. 8).
Este bloque está **bien cubierto en ambos lados** — apréndetelo, es punto seguro:

| Lado | Dónde | Qué libera |
|---|---|---|
| Dart | `tienda_screen.dart:83` `dispose()` | cancela el `StreamSubscription` y los 2 `Timer` |
| Kotlin | `EmotionChannelHandler.kt:61` `onCancel()` | libera cámara y detector al cerrar el stream |
| Kotlin | `CameraManager.kt:94` `release()` | `unbindAll()` + `analyzerExecutor.shutdown()` |
| Kotlin | `EmotionDetector.kt:202` `close()` | cierra ML Kit, el intérprete TFLite y su worker |
| Kotlin | `MainActivity.kt:22` `onDestroy()` | cierre en el ciclo de vida de la Activity |
| Kotlin | `EmotionDetector.kt:71` | `frame.close()` en **cada** frame |

Ese último importa: si no cierras cada `ImageProxy`, CameraX deja de entregar frames tras
unos segundos. Es la fuga clásica de CameraX y aquí está resuelta.

### B6. "Métodos menores a 40 líneas"

El PDF lo pide explícito (pág. 9). **Se cumple: cero métodos de lógica sobre 40 líneas.**

Lo único largo son los `build()`, y eso tiene respuesta:

| Qué | Líneas | Por qué no cuenta |
|---|---|---|
| `build()` en 6 pantallas y widgets | 79–220 | Son **árboles de widgets declarativos**: composición, no lógica. No tienen ramas ni estado que seguir |

Si el docente insiste en que un `build()` de 220 líneas es largo, la respuesta honesta es
que se parte extrayendo sub-widgets (`_Encabezado`, `_Precio`, `_Botones`), pero que eso
mueve líneas de sitio sin reducir complejidad ciclomática — que es lo que la regla busca.

**El dato que sí puedes ofrecer:** la lógica de negociación estaba en un método de 67
líneas y se partió en cuatro, cada uno con una responsabilidad:

| Método | Línea | Qué hace |
|---|---|---|
| `_responderOferta` | 277 | registra la respuesta y enruta |
| `_siguientePeldano` | 306 | decide el peldaño de la escalada |
| `_ofrecerSustituto` | 334 | busca la alternativa de la misma categoría |
| `_ofertarTrasPausa` | 351 | espera 500 ms y reofrece |

Cómo verificarlo delante de él, si lo pide:

```bash
grep -n "Future<void> _siguientePeldano" lib/ui/tienda_screen.dart
```

### B7. "¿Es responsivo?"

Está en los conceptos aplicados del PDF (pág. 3).

| | |
|---|---|
| **Dónde** | `lib/ui/tienda_screen.dart:511` |

```dart
final columnas = (constraints.maxWidth / 190).floor().clamp(2, 4);
```
(en el archivo va partido en tres líneas por el formateador)

**En vivo:** rota el celular. Pasa de 2 columnas a 3 o 4 sin recargar.

El `clamp(2, 4)` es lo que explicas: nunca una sola columna (desperdicia pantalla ancha)
ni más de cuatro (las tarjetas quedan ilegibles). Además hay `maxWidth: 900`
(línea 510) para que en tablet no se estire sin límite.

---

## Bloque C — "Cámbiame esto ahora mismo"

Ordenados de más fácil a más riesgoso. **Si puedes elegir, elige de arriba.**

| # | Reto | Archivo | Tiempo | Riesgo |
|---|---|---|---|---|
| C1 | Cambiar un descuento por emoción | `adaptation_engine.dart:208` | 10 s | ninguno |
| C2 | Cambiar los segundos del popup | `tienda_screen.dart:184` | 10 s | ninguno |
| C3 | Cambiar el texto de una oferta | `adaptation_engine.dart:195` | 10 s | ninguno |
| C4 | Cambiar el orden del catálogo de una emoción | `adaptation_engine.dart:286` | 30 s | bajo |
| C5 | Agregar un producto al catálogo | `data/database/catalogo_demo.dart` | 1 min | medio: necesita `pm clear` |
| C6 | Agregar una columna a una tabla | `data/database/tables.dart` | 2 min | medio: `build_runner` + `pm clear` |
| C7 | Cambiar la estabilidad del detector | `EmotionProcessor.kt:146` (companion) | 2 min | alto: recompila Kotlin |
| C8 | Cambiar el mapeo emoción→clase FER | `EmotionDetector.kt:393` `mapFerClass` | 2 min | alto: recompila Kotlin |

### C6 en detalle (el más probable si el docente es de base de datos)

Tus 10 tablas están en `lib/data/database/tables.dart`:

| Tabla | Línea | | Tabla | Línea |
|---|---|---|---|---|
| `TiposCliente` | 22 | | `Productos` | 90 |
| `TiposProducto` | 32 | | `Estrategias` | 109 |
| `Gestos` | 44 | | `Interacciones` | 128 |
| `TiposTransaccion` | 56 | | `Ventas` | 157 |
| `Clientes` | 70 | | `DetalleVenta` | 179 |

Pasos, en orden:

```bash
# 1. agregar el atributo en tables.dart, p.ej. dentro de Productos:
#    TextColumn get marca => text().nullable()();
dart run build_runner build --delete-conflicting-outputs
adb shell pm clear com.tuapp.tienda_adaptativa
flutter run
```

**La trampa:** `schemaVersion` está en **1** (`app_database.dart:36`) y `onCreate` solo
corre con base nueva. Si no haces `pm clear`, la base del celular conserva el esquema
viejo y la app revienta. Dilo tú antes de que pase — demuestra que entiendes migraciones.

Si te piden migración de verdad: subes `schemaVersion` a 2 y agregas `onUpgrade` al
`MigrationStrategy` que ya existe en `app_database.dart:39`.

---

## Bloque D — Preguntas conceptuales (sin tocar código)

### D1. "¿Por qué esto es adaptativo y no simplemente reactivo?"

Un sistema reactivo responde a una **orden**. Este responde a una **condición del
contexto que el usuario no emite a propósito**: nadie sonríe *para* pedir un descuento.
El usuario no sabe que está disparando la adaptación, y además el sistema **aprende**:
UCB1 cambia qué estrategia usa según lo que funcionó antes.

### D2. "¿Por qué un bandit y no elegir al azar?"

| | |
|---|---|
| **Dónde** | `lib/decision/learning/bandit_optimizer.dart:124` |

```
score = éxitos/intentos + sqrt(2 * ln(N) / intentos)
```

El primer término **explota** lo que ya funciona; la raíz **explora** lo poco probado.
Al azar nunca converge; solo con el promedio, una estrategia con mala suerte inicial no
se prueba nunca más.

**Evidencia real medida en el celular:** "Oferta relámpago" 51 intentos con 15.7% de
conversión frente a "Descuento directo" 28 intentos con 0%. El algoritmo dejó de gastar
intentos en la que no cierra. Esto vale oro: no es teoría, son datos de tu app.

### D3. "¿Por qué el dinero es entero?"

Centavos en `INTEGER`, nunca `REAL`. Con punto flotante binario, 0.1 + 0.2 no da 0.3 y
el error se acumula en `montoTotalCentavos`. El descuento usa división entera:
`precio * porcentaje ~/ 100`.

### D4. "¿Por qué 26 frames y no 5?"

Porque se **midió**. Con umbrales bajos la etiqueta saltaba 16 veces en 20 segundos —
inservible para decidir una oferta. Con ventana de 26, mayoría del 45% e histéresis de
6 votos, bajó a 7. Los 9 tests JUnit de `EmotionProcessorTest.kt` fijan ese
comportamiento para que no se rompa.

### D5. "¿Dónde queda registrado que el cliente rechazó?"

En la **ausencia** de venta para ese `idProcesoPersuasion`. Cada oferta escribe una
`interaccion`; solo las aceptadas escriben en `ventas`. El KPI 2 mide exactamente esa
diferencia. Es el enlace entre intento y cierre.

---

## Bloque E — Puntos débiles conocidos

Ténlos listos: si el docente los encuentra y tú ya los tenías identificados, el golpe se
convierte en punto a favor.

| Debilidad | Cómo responder |
|---|---|
| El modelo confunde `triste` con `enojo` | Es el techo del modelo FER a 48×48: ambas bajan las cejas. El preprocesamiento (grises, ecualización, recorte cuadrado) ya bajó el error de "enojo con cara neutra" del 49% al 5% |
| `tipo_cliente` nunca se asigna | La tabla y la FK existen; falta la regla que clasifica Nuevo/Frecuente/VIP. Es trabajo pendiente, no un error de diseño |
| `total_vendidos` está en 0 | Es un derivado que actualiza el módulo batch en el cierre diario, no la transacción en línea |
| El informe ocupa ~2 páginas | Ya cubre las **6 secciones que exige el PDF** más 3 propias (arquitectura, tecnologías, ubicación). El PDF dice *1 página máx.*: si el docente lo exige, borras las secciones **7, 8 y 9** y queda exacto |

**Lo que el PDF pide y quizá no tengas a la vista:** la sección *"Evidencia de adaptación
— capturas o descripción de cambios dinámicos"* (pág. 12). Si la piden, tu evidencia es
la propia base de datos: `python tools/ver_base.py` muestra las interacciones con la
emoción que las disparó y qué estrategia se usó. Eso es evidencia medida, mejor que una
captura.

---

## Resumen de una hoja (lo mínimo que debes recordar)

| Pregunta | Respuesta de una línea |
|---|---|
| ¿Dónde se adapta solo? | `tienda_screen.dart:149` `_adaptarA`, llamado desde el `listen` del stream |
| ¿Dónde están las reglas? | `adaptation_engine.dart:208` (descuentos) y `:286` (orden del catálogo) |
| ¿Dónde está el pipeline? | Kotlin `context/` → `processing/` → Dart `decision/` → `ui/` |
| ¿Dónde se abstrae el contexto? | `services/emotion_channel.dart:10` |
| ¿Dónde se liberan recursos? | `tienda_screen.dart:83` (sin cambio) y `EmotionChannelHandler.kt:61` |
| ¿Dónde está el esquema? | `data/database/tables.dart`, 10 clases |
| ¿Dónde está el aprendizaje? | `learning/bandit_optimizer.dart:124` |
| ¿Cómo cambio algo rápido? | Editar Dart + tecla `r` |
