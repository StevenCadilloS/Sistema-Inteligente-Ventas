# Guía de estudio — Sistema Cierre de Ventas (Taller 1)

Documento para repasar antes de la presentación. Solo texto y cuadros (sin diagramas)
para que se pueda imprimir. Basado en `Taller 01.pdf`, `docs/PLAN_ELVIS.md`,
`docs/ESQUEMA_CORREGIDO.md`, `docs/GUIA_STEVEN.md` y el código fuente actual.

---

## 0. Qué se evalúa (20 puntos)

| Rubro | Puntos | Qué mira el docente |
|---|---:|---|
| Funcionalidad adaptativa | 8 | ¿Se adapta sola al contexto? ¿En tiempo real? ¿La lógica es clara y consistente? |
| Diseño e implementación técnica | 6 | Pipeline correcto · uso de asincronía · manejo del ciclo de vida y recursos |
| Presentación del proyecto | 6 | Buena explicación en clase |

**Regla eliminatoria (textual del PDF):** *"No se considerará adaptativo si el
comportamiento requiere intervención manual del usuario."*

**Dato clave para no perder tiempo estudiando lo que no puntúa:** la base de datos y
el batch/KPIs **no aparecen en la rúbrica**. Solo cuentan como soporte de arquitectura
("separación de capas") y como material de presentación. Los 8 puntos grandes están en
la etapa de **Decisión** (`AdaptationEngine` + `BanditOptimizer`) y en que el puente
cámara→UI funcione de punta a punta sin tocar nada manualmente.

---

## 1. El pipeline obligatorio, mapeado a archivos reales

El PDF exige el flujo: **Entrada (contexto) → Procesamiento → Decisión → Adaptación**.

| # | Fase | Qué hace | Archivo(s) | Clase / método clave | Estado |
|---|---|---|---|---|---|
| 1 | Entrada (contexto) | Captura frames de la cámara frontal | `android/.../context/CameraManager.kt` | `CameraManager.startCamera()` | Implementado |
| 1 | Entrada (contexto) | Detecta rostro (ML Kit) y clasifica la emoción (TFLite, modelo FER-2013) | `android/.../context/EmotionDetector.kt` | `EmotionDetector.detectEmotion()` | Implementado |
| 2 | Procesamiento | Filtra ruido: solo confirma una emoción si se repite 10 frames seguidos | `android/.../processing/EmotionProcessor.kt` | `EmotionProcessor.process()` | Implementado |
| — | Puente nativo → Flutter | Envía la emoción estable a Dart como stream continuo | `channel/EmotionChannelHandler.kt` (nuevo) + registro en `MainActivity.kt` + `lib/services/emotion_channel.dart` (nuevo) | `EventChannel` | **Pendiente** |
| 3 | Decisión | Elige producto según la regla de la emoción + elige estrategia (bandit) + registra el intento | `lib/decision/adaptation_engine.dart` | `AdaptationEngine.decidirOferta()` | Implementado y probado |
| 3 | Decisión | Aprendizaje: cuál estrategia está funcionando mejor (UCB1) | `lib/decision/learning/bandit_optimizer.dart` | `BanditOptimizer.seleccionarEstrategia()` | Implementado y probado |
| 4 | Adaptación | Pinta la oferta nueva en pantalla sin que el usuario haga nada | Pantallas Flutter (login, principal, historial) | — | **Pendiente** |

**Importante para la charla con el docente:** el flujo entero ya existe *como código
probado* excepto el tramo "puente + pantallas", que es trabajo de Steven descrito en
`docs/GUIA_STEVEN.md`. Si te preguntan "muéstrame que se adapta", hoy eso solo se puede
demostrar corriendo los tests (`flutter test`), no la app en pantalla, hasta que ese
tramo se conecte.

---

## 2. Las 5 reglas de adaptación (el corazón de los 8 puntos)

Viven en `AdaptationEngine._productoPara()` (`lib/decision/adaptation_engine.dart`).

| Emoción (string que llega de Kotlin) | Regla de negocio | Qué producto elige | Texto mostrado (`_textoPara`) |
|---|---|---|---|
| `triste` | Sustituto más económico | El producto activo con menor precio | "Tal vez esto te anime: [producto] a S/[precio]" |
| `feliz` | Premium, sin descuento | El producto activo con mayor precio | "Para ti: [producto], nuestra opción premium" |
| `sorpresa` | Novedad | El producto activo menos mostrado (`totalVecesMostrado` más bajo) | "Oferta especial solo por hoy: [producto]" |
| `neutral` | Estándar / default | El producto activo más mostrado | "Te recomendamos: [producto] a S/[precio]" |
| `enojo` | Cambio de categoría + descuento agresivo | Producto de otra categoría distinta a la última mostrada a ese cliente, el más barato de ella | "Precio especial en [producto]: S/[precio]" |

Notas para defender esto en vivo:
- Si no hay rostro (`no_face`) o la emoción no está en el catálogo `Gestos`, cae a la
  regla `neutral` en vez de romper el flujo (`getSingleOrNull`, no `getSingle`).
- La emoción llega como **texto** (`"triste"`), no como código interno (`codGesto`) —
  el motor de decisión no conoce nada de la capa de persistencia de Kotlin.
- Cada llamada a `decidirOferta` corre en **una sola transacción**: inserta la
  interacción y actualiza el contador `totalVecesMostrado` del producto juntos, para
  que dos clientes en paralelo no pisen el contador.

---

## 3. Aprendizaje (bandit UCB1)

Vive en `BanditOptimizer` (`lib/decision/learning/bandit_optimizer.dart`).

- **Qué decide:** qué *estrategia* de venta usar (no qué producto — eso ya lo decide la
  regla de emoción). Se ejecuta dentro de `decidirOferta`.
- **Cómo:** cada estrategia acumula un score = `exitos/intentos + sqrt(2*ln(N)/intentos)`
  (fórmula UCB1 clásica: explota lo que funciona, pero sigue probando lo que se conoce
  poco). Una estrategia nunca probada se prioriza automáticamente (evita dividir entre
  cero y fuerza la exploración inicial).
- **De dónde saca los datos:** cuenta en vivo, con `COUNT(DISTINCT id_proceso_persuasion)`,
  sobre las tablas `interacciones` (intentos) y `ventas` (éxitos) — **no** usa las
  columnas `totalVecesAplicada`/`ventasGeneradas` de la tabla `estrategias`; esas
  quedan exclusivas para el batch/KPIs de presentación, deliberadamente, para que las
  dos fuentes no se pisen entre sí.
- **Cómo se cierra el ciclo:** `registrarRespuesta(idProcesoPersuasion, aceptada)`.
  Si acepta, crea una fila en `ventas` + `detalleVenta`. Si rechaza, no crea nada — la
  ausencia de venta con ese mismo `idProcesoPersuasion` **es** el rechazo.

---

## 4. Persistencia (para hablar de "acceso a datos" en la arquitectura)

Motor: `drift` (SQLite tipado) — análogo de Room en Kotlin. Archivo de esquema:
`lib/data/database/tables.dart`. Base de datos: `AppDatabase`
(`lib/data/database/app_database.dart`).

| Tabla | Para qué sirve |
|---|---|
| `TiposCliente`, `TiposProducto`, `Gestos`, `TiposTransaccion` | Catálogos (deben existir antes que cualquier bitácora, o fallan las llaves foráneas) |
| `Clientes` | Datos del cliente + contadores derivados (`cantLecturas`, `totalCompras`, `montoTotalCentavos`) |
| `Productos` | Catálogo de productos + contadores (`totalVendidos`, `cierresVenta`, `totalVecesMostrado`) |
| `Estrategias` | Catálogo de estrategias de venta + contadores derivados (solo para el batch) |
| `Interacciones` | Bitácora de cada intento de persuasión (una fila por oferta mostrada) |
| `Ventas` | Bitácora de cierres (una fila cuando el cliente acepta) |
| `DetalleVenta` | Línea de detalle de cada venta (producto, cantidad, precio congelado) |

`idProcesoPersuasion` es el campo que conecta un intento (`Interacciones`) con su cierre
(`Ventas`) — sin él no se podría medir conversión. Es la corrección más importante que
se le hizo al diseño original del curso de Base de Datos (ver hallazgo G1 más abajo).

---

## 5. Autenticación / sesión

`ClienteRepository` (`lib/data/repositories/cliente_repository.dart`).

- `registrar(nombre, apellido, tipoCliente?)` — crea el cliente y lo deja como sesión activa.
- `iniciarSesion(codCliente)` / `clienteActivo()` / `cerrarSesion()`.
- La sesión se guarda en `SharedPreferences`, no en la base de datos: es estado del
  dispositivo, no un dato de negocio.
- Al arrancar la app, si `clienteActivo()` no es null, se debe saltar el login — la
  regla eliminatoria prohíbe pedirle algo manual al usuario que no haga falta.

---

## 6. Batch (cierre diario) — vale 0 puntos en la rúbrica

`BatchRunner.ejecutarCierreDiario()` (`lib/data/batch/batch_runner.dart`), programado
una vez al día por `CierreDiarioScheduler` con `WorkManager`
(`lib/data/batch/cierre_diario_scheduler.dart`).

Recalcula 6 contadores derivados (para los 4 KPIs del curso de Base de Datos) en una
sola transacción: todo o nada. **No confundir con el aprendizaje UCB1** — son cálculos
independientes que nunca leen ni escriben las mismas columnas.

Solo es útil como material de presentación ("aquí también hay un proceso batch"), no
para la nota de este taller.

---

## 7. Estado actual: qué está armado y qué falta

| Componente | Responsable | Estado |
|---|---|---|
| Cámara + detección + clasificación de emoción (Kotlin) | Juan | Implementado |
| Filtro de estabilidad (Kotlin) | Juan | Implementado |
| Puente `EventChannel` (Kotlin + Dart) | Steven | **Pendiente** |
| Pantallas (login, principal, historial) | Steven | **Pendiente** |
| Motor de reglas de adaptación (`AdaptationEngine`) | Elvis | Implementado, probado |
| Aprendizaje UCB1 (`BanditOptimizer`) | Elvis | Implementado, probado |
| Base de datos (`drift`, 10 tablas) | Elvis | Implementado, probado |
| Autenticación (`ClienteRepository`) | Elvis | Implementado, probado |
| Batch / KPIs | Elvis | Implementado, probado (no puntúa) |
| `main.dart` conectando todo | Steven | **Pendiente** (hoy sigue siendo la plantilla de `flutter create`) |

**Antes de la presentación, esta tabla debería quedar sin "Pendiente" en la fila del
puente y de `main.dart` como mínimo** — sin eso no hay demo en vivo posible y se pierde
la mayor parte de los 8 puntos de funcionalidad adaptativa.

---

## 8. Si el docente pide cambiar algo en vivo — dónde tocar

| Te puede pedir... | Archivo | Qué cambiar |
|---|---|---|
| Cambiar qué producto se ofrece para una emoción | `lib/decision/adaptation_engine.dart` | El `case` correspondiente dentro de `_productoPara()` |
| Cambiar el mensaje mostrado | `lib/decision/adaptation_engine.dart` | El `case` correspondiente dentro de `_textoPara()` |
| Agregar una emoción/regla nueva | `lib/decision/adaptation_engine.dart` | Agregar caso en el `enum _TipoRegla`, en `_reglaPara()`, en `_productoPara()` y en `_textoPara()` |
| Hacer que tarde más/menos en confirmar una emoción | `android/.../processing/EmotionProcessor.kt` | Constante `DEFAULT_STABILITY_THRESHOLD` (hoy 10 frames) |
| Cambiar la fórmula de exploración del aprendizaje | `lib/decision/learning/bandit_optimizer.dart` | Método `_ucb1()` |
| Cambiar la frecuencia del cierre diario | `lib/data/batch/cierre_diario_scheduler.dart` | `Duration(days: 1)` en `programarCierreDiario()` |
| Agregar un campo al registro de cliente | `lib/data/database/tables.dart` (tabla `Clientes`) + `lib/data/repositories/cliente_repository.dart` (`registrar()`) | Nueva columna + parámetro |
| Agregar un nuevo tipo de cliente o producto | `AppDatabase.seedCatalogos()` en `lib/data/database/app_database.dart` | Agregar fila al `insertAll` correspondiente |

---

## 9. Trampas y decisiones ya resueltas (para no titubear en preguntas capciosas)

Si preguntan "¿por qué hiciste X así y no de otra forma?", la respuesta casi siempre
está aquí (`docs/PLAN_ELVIS.md §6` y `docs/ESQUEMA_CORREGIDO.md`):

1. **El dinero es entero (centavos), nunca `REAL`** — evita errores de redondeo binario.
2. **Las llaves foráneas no se validan solas en SQLite** (a diferencia de Room) — hay
   que activar `PRAGMA foreign_keys = ON` en cada conexión (`app_database.dart`,
   `beforeOpen`).
3. **Los catálogos se siembran antes que cualquier bitácora** — si no, las FK fallan.
4. **El precio va en dos lados**: vigente en `Productos`, congelado (snapshot) en
   `DetalleVenta` — así cambiar un precio no reescribe ventas históricas.
5. **`idProcesoPersuasion` no existía en el diseño original del curso** (hallazgo G1) —
   sin él no se puede saber qué intento de persuasión terminó en venta, que es
   exactamente lo que mide el sistema. Se agregó como corrección C1.
6. **No hay tabla de gestos en el diseño original** (hallazgo G2) — se creó
   `Gestos` (corrección C2) para mapear las 5 emociones de Juan a algo con FK válida.
7. **Sin centinelas `00000000` en llaves foráneas** — se modelan como `NULL` de verdad
   (corrección C11), porque Room/drift sí valida integridad referencial y un código
   inventado rompería la FK.
8. **El aprendizaje UCB1 y el batch nunca comparten columnas** aunque midan cosas
   parecidas — decisión deliberada para que no se pisen entre sí (uno es en vivo, el
   otro es un recálculo periódico para KPIs).

---

## 10. Asincronía y ciclo de vida (rubro técnico, 6 puntos)

Para justificar este punto de la rúbrica con ejemplos concretos:

- **Todo acceso a base de datos es `async/await`** (`Future<...>`), nunca bloquea el
  hilo de UI: ver cualquier método público de `AdaptationEngine`, `BanditOptimizer`,
  `ClienteRepository`.
- **Operaciones que deben ser atómicas van en `_db.transaction(...)`**: registrar una
  oferta (interacción + contador), registrar una venta (venta + detalle), registrar un
  cliente nuevo (evita choques si dos llamadas concurrentes generan el mismo código).
- **El stream de emociones es un `EventChannel`**, no un `MethodChannel` — porque es un
  flujo continuo de eventos, no una llamada única (pendiente de conectar, ver §7).
- **Ciclo de vida / liberación de recursos** (evita fugas, parte de la regla
  eliminatoria):
  - `CameraManager.stopCamera()` / `.release()` — libera la cámara y el executor.
  - `EmotionDetector.close()` — libera el detector de ML Kit y el intérprete TFLite.
  - En Dart: cancelar la suscripción al `EventChannel` (`StreamSubscription.cancel()`)
    al salir de la pantalla principal — **esto todavía no existe** porque la pantalla
    no existe; es parte de lo pendiente.

---

## 11. Glosario rápido

| Término | Significado |
|---|---|
| FER-2013 | Dataset/clasificador de emociones faciales que usa el modelo TFLite (7 clases originales, mapeadas a 5 emociones de negocio) |
| ML Kit | Librería de Google para detectar el rostro dentro del frame (no clasifica emoción, solo ubica la cara) |
| TFLite | TensorFlow Lite — motor que corre el modelo de clasificación de emociones en el celular |
| UCB1 | Upper Confidence Bound — algoritmo de multi-armed bandit que balancea explorar estrategias nuevas vs. explotar la que mejor funciona |
| `codGesto` | Código interno (ej. `G0000001`) de una emoción en la base de datos — detalle de persistencia, no lo que produce Kotlin |
| `idProcesoPersuasion` | Identificador que une un intento de oferta con su posible cierre en venta |
| `drift` | ORM tipado sobre SQLite para Dart (equivalente a Room en Android nativo) |
| `EventChannel` | Canal de Flutter para recibir un flujo continuo de eventos desde código nativo (Kotlin) |
| WorkManager | Librería para programar tareas periódicas en background en Android |

---

## 12. Checklist final antes de la presentación

- [ ] El puente Kotlin→Flutter está conectado y las 3 pantallas existen.
- [ ] Corriste la app y viste la oferta cambiar sola al cambiar de expresión, sin tocar nada.
- [ ] Corriste `flutter test` y todos los tests pasan.
- [ ] Puedes explicar de memoria las 5 reglas de emoción sin mirar el código.
- [ ] Sabes en qué archivo y método tocar para cada fila de la tabla de la sección 8.
- [ ] Puedes justificar al menos 3 de las decisiones/trampas de la sección 9 sin leerlas.
- [ ] Sabes señalar, en el código, un ejemplo de `async/await` y uno de liberación de recursos.
- [ ] Sabes explicar por qué el sistema NO requiere intervención manual (regla eliminatoria).
