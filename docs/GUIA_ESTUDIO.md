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
| 2 | Procesamiento | Filtra ruido: confirma una emoción por voto de mayoría sobre 26 frames | `android/.../processing/EmotionProcessor.kt` | `EmotionProcessor.process()` | Implementado |
| — | Puente nativo → Flutter | Envía la emoción estable a Dart como stream continuo | `channel/EmotionChannelHandler.kt` + registro en `MainActivity.kt` + `lib/services/emotion_channel.dart` | `EventChannel` | Implementado |
| 3 | Decisión | Elige producto según la regla de la emoción + elige estrategia (bandit) + registra el intento | `lib/decision/adaptation_engine.dart` | `AdaptationEngine.decidirOferta()` | Implementado y probado |
| 3 | Decisión | Aprendizaje: cuál estrategia está funcionando mejor (UCB1) | `lib/decision/learning/bandit_optimizer.dart` | `BanditOptimizer.seleccionarEstrategia()` | Implementado y probado |
| 4 | Adaptación | Reordena el feed de productos solo, y ofrece con descuento en el momento de duda | `lib/ui/tienda_screen.dart` | `_adaptarA()`, `_ofertarRetencion()` | Implementado |

**Cómo se ve la adaptación en la app (lo que vas a demostrar):**

Es una **negociación en dos pasos**: el descuento no se regala de entrada, es la carta
que se juega cuando el cliente dice que no.

| Momento | Qué hace el sistema |
|---|---|
| El cliente navega el feed | El catálogo se **reordena solo** según su expresión — sin tocar nada, que es lo que exige la regla eliminatoria |
| Toca un producto | Sale el popup **a precio de lista**: "¿Te lo llevas?" |
| Dice "No, gracias" | Contraoferta: **mismo producto, con el descuento que decide su expresión** ("Espera, te mejoro el precio") |
| Vuelve a rechazar | Se le ofrece un **bien sustituto**: otro de la misma categoría y más económico |
| Rechaza también el sustituto | Se deja de insistir |
| Su cara cambia con la oferta abierta | Al cerrarse, se le reofrece mejorando el precio según la emoción nueva |
| Ya compró ese producto | Queda marcado **"Comprado"** y sale del circuito de ofertas |

Los dos pasos se registran como procesos de persuasión distintos, que es justo la señal
que el UCB1 necesita: ese producto a precio de lista no convierte, con descuento sí.

**Por qué lo ya comprado se excluye:** sin ese bloqueo el sistema le vendía el mismo
producto el mismo día dos veces, y la segunda más barata que la primera.

---

## 2. Las 5 reglas de adaptación (el corazón de los 8 puntos)

Viven en `AdaptationEngine` (`lib/decision/adaptation_engine.dart`): `_catalogoPara()`
ordena el catálogo y `_descuentoPara()` fija la rebaja.

| Emoción (string que llega de Kotlin) | Regla de negocio | Orden del catálogo | Descuento |
|---|---|---|---|
| `triste` | Sustituto más económico | Precio ascendente | 10% |
| `feliz` | Premium, sin descuento | Precio descendente | 0% |
| `sorpresa` | Novedad | `totalVecesMostrado` ascendente | 15% |
| `neutral` | Estándar del catálogo | `totalVecesMostrado` descendente | 0% |
| `enojo` | Cambio de categoría + descuento agresivo | Otra categoría primero, cada bloque por precio ascendente | 25% |

El descuento de la tabla es el de la **contraoferta**; la primera propuesta siempre va a
precio de lista (`decidirOferta(conDescuento: false)`).

**El descuento es real, no decorativo:** el mismo número que ve el cliente en el popup
es el que se congela en `detalleVenta.precioUnitarioCentavos` al cerrar la venta
(aritmética entera en centavos, nunca `double`). Está cubierto por el test *"el descuento
de la oferta es real: la venta congela el precio rebajado"*. Si te preguntan "¿dónde
queda ese descuento en tus datos?", esa es la respuesta.

**Stock:** el catálogo solo ofrece productos con `totalDisponible > 0`, y la venta lo
descuenta **dentro de la misma transacción** que `venta` + `detalleVenta` — si algo
falla, no queda una venta sin su descuento de inventario. El `UPDATE` es relativo en SQL
(`total_disponible - 1`, no leer y restar en Dart) para que dos compras a la vez no se
pisen, con guarda para no dejarlo negativo.

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
- **Qué hace cada estrategia** (`_descuentoConEstrategia` y `_beneficioDe`): no son
  etiquetas, cada una persuade distinto, y por eso hay algo que aprender.

| Estrategia | Efecto sobre la oferta |
|---|---|
| Descuento directo | Aplica la rebaja que corresponde a la emoción |
| Oferta relámpago | Sube esa rebaja 5 puntos, con mensaje de urgencia |
| Envío gratis | No toca el precio: agrega valor por otro lado |
| Recomendación premium | No toca el precio: apela a la calidad del producto |

  Si te preguntan **qué aprende el algoritmo**, la respuesta es esta: compara mecanismos
  de persuasión reales y descubre cuál convierte más en tu base de clientes. Las dos que
  no bajan el precio suelen convertir menos, y el UCB1 termina prefiriendo las otras.
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

## 7. Estado actual

| Componente | Responsable | Estado |
|---|---|---|
| Cámara + detección + clasificación de emoción (Kotlin) | Juan | Implementado |
| Filtro de estabilidad (Kotlin) | Juan | Implementado |
| Puente `EventChannel` (Kotlin + Dart) | Steven | Implementado |
| Pantallas (login, tienda, historial) | Steven | Implementado |
| Motor de reglas de adaptación (`AdaptationEngine`) | Elvis | Implementado, probado |
| Aprendizaje UCB1 (`BanditOptimizer`) | Elvis | Implementado, probado |
| Base de datos (`drift`, 10 tablas) | Elvis | Implementado, probado |
| Autenticación (`ClienteRepository`) | Elvis | Implementado, probado |
| Batch / KPIs | Elvis | Implementado, probado (no puntúa) |
| `main.dart` conectando todo | Steven | Implementado |

Verificado en dispositivo real (Redmi, Android 12): **45 tests Dart + 9 Kotlin**,
`flutter analyze` sin issues, y la base con interacciones y ventas escribiéndose
durante el uso.

**Semántica del carrito, por si preguntan:** la pantalla "Tus compras" no es un carrito
pendiente — aceptar la oferta *es* lo que cierra el proceso de persuasión, así que en
ese momento ya se escribió `venta` + `detalleVenta`. Por eso no se pueden eliminar
líneas: la bitácora de ventas no se borra, y el KPI 2 mide justamente la existencia de
esa venta.

---

## 8. Si el docente pide cambiar algo en vivo — dónde tocar

| Te puede pedir... | Archivo | Qué cambiar |
|---|---|---|
| Cambiar el orden del catálogo para una emoción | `lib/decision/adaptation_engine.dart` | El `case` correspondiente en `_catalogoPara()` |
| Cambiar el porcentaje de descuento de una emoción | `lib/decision/adaptation_engine.dart` | El `case` correspondiente en `_descuentoPara()` |
| Cambiar qué hace una estrategia | `lib/decision/adaptation_engine.dart` | `_descuentoConEstrategia()` y `_beneficioDe()` |
| Cambiar cómo se elige el bien sustituto | `lib/decision/adaptation_engine.dart` | `sustitutoPara()` |
| Cambiar el mensaje mostrado | `lib/decision/adaptation_engine.dart` | El `case` correspondiente en `_textoPara()` |
| Agregar una emoción/regla nueva | `lib/decision/adaptation_engine.dart` | Caso en `enum _TipoRegla`, `_reglaPara()`, `_catalogoPara()`, `_descuentoPara()` y `_textoPara()` |
| Hacer que tarde más/menos en confirmar una emoción | `android/.../processing/EmotionProcessor.kt` | `DEFAULT_STABILITY_THRESHOLD` (26 frames ≈ 1.3 s) |
| Que la emoción cambie más/menos fácil (parpadeo) | `android/.../processing/EmotionProcessor.kt` | `MAYORIA_MINIMA` (0.45) y `MARGEN_PARA_CAMBIAR` (6 votos) |
| Que detecte el rostro desde más lejos | `android/.../context/EmotionDetector.kt` | `setMinFaceSize(0.10f)` |
| Que la contraoferta salga con o sin descuento | `lib/ui/tienda_screen.dart` | El parámetro `conDescuento` en `_ofertarRetencion()` |
| Que vuelva a ofrecer algo ya comprado | `lib/ui/tienda_screen.dart` | `_yaComprado()` |
| Cuánto dura el popup de oferta | `lib/ui/tienda_screen.dart` | `_segundosRestantes = 10` en `_mostrarPopupOferta()` |
| Cambiar la fórmula de exploración del aprendizaje | `lib/decision/learning/bandit_optimizer.dart` | Método `_ucb1()` |
| Cambiar la frecuencia del cierre diario | `lib/data/batch/cierre_diario_scheduler.dart` | `Duration(days: 1)` en `programarCierreDiario()` |
| Agregar un campo al registro de cliente | `lib/data/database/tables.dart` (tabla `Clientes`) + `cliente_repository.dart` (`registrar()`) | Nueva columna + parámetro |
| Agregar productos o categorías al catálogo | `lib/data/database/catalogo_demo.dart` | Agregar filas al `insertAll` correspondiente |

---

## 8-bis. Calibración del clasificador (medido en dispositivo, no a ojo)

Si preguntan "¿cómo sabes que el modelo funciona bien?", esta es la parte más fuerte de
la defensa: cada ajuste salió de una medición, no de intuición.

| Hallazgo | Cómo se detectó | Corrección |
|---|---|---|
| El modelo esperaba RGB, no escala de grises | La app crasheaba al arrancar; se inspeccionó el tensor del `.tflite` (`[1,48,48,3]`) | `preprocess()` escribe 3 canales |
| Orden de clases alfabético, no FER-2013 | Cara relajada daba índice 4 en 56% de los frames, y hacer cara triste lo *bajaba* a 18%. Si el 4 fuera "triste" pasaría lo contrario | `mapFerClass()`: 4=neutral, 5=sad, 6=surprise |
| Entrada fuera de distribución | Con RGB real, cara neutral daba 49% "enojo"; con gris replicado bajó a 5% | Gris replicado en los 3 canales |
| Contraluz aplanaba el rostro | A brazo extendido el falso "enojo" subía a 48% | Ecualización de histograma → bajó a 13% |
| Recorte deformado | El rectángulo de ML Kit se aplastaba a 48×48; misma cara daba 5% vs 63% de "enojo" según distancia | Recorte **cuadrado** centrado |
| No detectaba a distancia normal | 0 detecciones en 257 frames a un brazo | `setMinFaceSize` 0.35 → 0.10 |
| La emoción parpadeaba | 16 cambios en 20 s con el usuario quieto | Voto por mayoría + histéresis (bajó a 7, luego se endureció el margen) |

**Limitación honesta que conviene admitir tú mismo antes de que la encuentren:** el
modelo trabaja con 48×48 píxeles (2304 valores) y confunde triste con enojo — ambas
expresiones bajan las cejas. Es el techo del modelo, no del pipeline.

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

## 12. Pruebas automatizadas

Dos suites, ninguna necesita celular ni emulador:

| Suite | Cuántas | Cómo correrla |
|---|---|---|
| Dart (BD, repositorio, motor, bandit, batch, arranque) | 45 | `flutter test` |
| Kotlin (`EmotionProcessor`) | 9 | `cd android && ./gradlew :app:testDebugUnitTest` |

Las de Kotlin cubren la lógica más delicada del pipeline, y cada caso fija un bug que ya
ocurrió en dispositivo: que un frame `no_face` suelto no descarte la ventana, que la
pérdida real de rostro avise una sola vez, y que la histéresis impida el parpadeo entre
dos clases empatadas.

**Detalle que vale contar si preguntan por el proceso:** la primera vez que se corrieron
las pruebas de Kotlin, Gradle reportó `BUILD SUCCESSFUL`… sin haber ejecutado ninguna. El
directorio `src/test/kotlin` no estaba registrado y la tarea pasó en vacío. Se detectó
recién al abrir `build/app/test-results/`, donde el XML dice cuántos casos corrieron de
verdad. Un build verde no equivale a pruebas ejecutadas.

---

## 12-bis. Cómo mostrar los datos reales en la presentación

La base vive en el almacenamiento privado de la app, así que no se puede abrir desde el
explorador de archivos del celular. Con el celular conectado:

```
python tools/ver_base.py            # resumen de todas las tablas
python tools/ver_base.py ventas     # vuelca una tabla completa
```

Imprime cuántas filas tiene cada tabla, las últimas interacciones con su emoción,
estrategia y si convirtieron, y las ventas comparando lo cobrado contra el precio de
lista — que es la prueba visible de que el descuento es real.

Para verlo como tablas navegables, el script deja el archivo en
`tools/base_extraida.sqlite`: ábrelo con **DB Browser for SQLite** (gratuito) y usa la
pestaña *Browse Data*.

---

## 13. Checklist final antes de la presentación

- [ ] El puente Kotlin→Flutter está conectado y las 3 pantallas existen.
- [ ] Corriste la app y viste la oferta cambiar sola al cambiar de expresión, sin tocar nada.
- [ ] Corriste `flutter test` (45) y `cd android && ./gradlew :app:testDebugUnitTest` (9).
- [ ] Puedes explicar de memoria las 5 reglas de emoción sin mirar el código.
- [ ] Sabes en qué archivo y método tocar para cada fila de la tabla de la sección 8.
- [ ] Puedes justificar al menos 3 de las decisiones/trampas de la sección 9 sin leerlas.
- [ ] Sabes señalar, en el código, un ejemplo de `async/await` y uno de liberación de recursos.
- [ ] Sabes explicar por qué el sistema NO requiere intervención manual (regla eliminatoria).
