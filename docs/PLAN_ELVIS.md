# Plan de trabajo — Elvis
Sistema Cierre de Ventas · Taller 1 de Desarrollo Adaptativo · UNI FIIS

**Mi tramo:** base de datos completa (dueño único) + dentro del backend compartido, motor de reglas de oferta y autenticación.

**Equipo:** Steven (frontend + integración con la cámara) · Juan (modelo de emociones) · Elvis (BD + reglas + autenticación). El backend es trabajo de los tres.

---

## 0. Lo que califica el taller (y lo que no)

Leído de `Taller 01.pdf`. Es sobre **20 puntos**:

| Rubro | Puntos | Qué evalúa |
|---|---:|---|
| Funcionalidad adaptativa | **8** | ¿Se adapta automáticamente al contexto? ¿Responde en tiempo real? ¿La lógica es clara y consistente? |
| Diseño e implementación técnica | **6** | Pipeline adaptativo correcto · uso de asincronía · manejo del ciclo de vida y recursos |
| Presentación del proyecto | **6** | Buena explicación en clase |

> **Regla eliminatoria:** *"No se considerará adaptativo si el comportamiento requiere intervención manual del usuario."*

### El hallazgo incómodo

**La base de datos no aparece en la rúbrica.** Ni un punto directo. Aparece solo como parte del requisito de arquitectura ("separación de responsabilidades: UI / lógica de negocio / acceso a datos") y como soporte de la demo.

Los 8 puntos de funcionalidad adaptativa y buena parte de los 6 técnicos viven en el **pipeline adaptativo obligatorio**:

```
Entrada (contexto) → Procesamiento → Decisión → Adaptación
```

Y la etapa **Decisión es mía**. Es decir: mi trabajo más valioso para la nota no es el esquema —que ya está diseñado y auditado— sino el **motor de reglas de oferta**. El esquema es infraestructura; las reglas son el rubro de 8 puntos.

**Consecuencia práctica:** el batch y los 4 KPIs valen **cero puntos** en este taller. Solo suman como material de presentación y como entregable del curso de Base de Datos.

### Requisitos técnicos que me tocan directamente

| Requisito del taller | Cómo lo cubro |
|---|---|
| Separación de capas | Mi capa de datos y mi motor de reglas no tocan widgets; expongo funciones, no UI. |
| Abstracción del acceso al contexto | El motor recibe el gesto ya procesado, no el frame ni el tensor. |
| Pipeline adaptativo | Soy la etapa **Decisión**; entrego a **Adaptación** (Steven). |
| Procesamiento en tiempo real | La oferta cambia sola al cambiar la emoción, sin que nadie toque un botón. |
| Programación asíncrona | Todo acceso a BD con `async/await`, sin bloquear el hilo de UI. |
| Ciclo de vida y recursos | Cerrar la conexión a la base y cancelar suscripciones al salir de pantalla. |
| Métodos < 40 líneas | Aplica a `AdaptationEngine` y a los repositorios. |
| README.md | Ya actualizado con descripción, instrucciones de ejecución y tecnologías. |
| Informe de 1 página | Sus secciones 3 (lógica de adaptación) y 4 (pipeline) salen de mi trabajo. |

---

## 1. Dónde estoy parado

El diseño ya está hecho y es sólido: auditadas las 4 versiones del esquema, comprobado cuál manda con la aritmética de Longitud de Registro, 9 hallazgos documentados (G1–G9) y 11 correcciones aplicadas (C1–C11). El modelo físico, los 4 KPIs y el batch están escritos en `MODELO_ANDROID_ROOM.md`.

Lo que falta no es diseño: es **traducción y ejecución**.

### El desajuste que bloquea todo

`MODELO_ANDROID_ROOM.md` está escrito para **Room/Kotlin**: entidades `@Entity`, DAOs `@Query`, una `@DatabaseView`, batch con `WorkManager`. La decisión vigente del equipo es **Flutter (Dart)**, con Kotlin solo para cámara y emociones.

No se pierde el trabajo: el SQL de los 4 KPIs y de los 4 procesos batch es SQLite puro y se porta casi tal cual. Lo que se rehace son las declaraciones de tabla y el cableado.

**Recomendación: `drift`, no `sqflite` pelado.** `drift` es el análogo directo de Room en Dart —tablas en código, DAOs tipados por codegen, vistas, migraciones versionadas, transacciones— y las consultas se pegan como SQL crudo devolviendo objetos tipados. Con `sqflite` las 11 tablas quedan como `CREATE TABLE` en strings y cada fila vuelve como `Map<String, dynamic>` con el mapeo a mano. Ambos corren sobre el mismo SQLite: la decisión es cuánto tipado se quiere, no qué motor.

---

## 2. Decisiones — todas cerradas (2026-09-06)

| # | Pregunta | Decisión |
|---|---|---|
| **D1** | ¿`cant_lecturas`, `cant_entradas` o `cant_sesiones`? | **`cant_lecturas`** — cuadra con la RL 68 del Módulo Online (autoritativo) y con los diagramas batch. |
| **D2** | ¿Qué pipeline usa el KPI de ventas por día? | **`Tercer KPI.png`** — su fórmula coincide con el título del indicador y con `MODELO_ANDROID_ROOM.md §4` KPI4. `Primer KPI.png` medía otra cosa (tasa de cierre por día). |
| **D3** | ¿`cierres_venta` se queda en MAESTRA-PRODUCTOS? | **Se mantiene** — la RL 53 solo cuadra con este campo incluido; se agrega al batch existente como un `COUNT` más. |
| **D4** | ¿Solo módulo online, o también batch + KPIs? | **Ambos** — módulo online primero (fases 1–6, lo que puntúa), batch como fase 7 no bloqueante. |
| **D5** | ¿`drift` o `sqflite`? | **`drift`** — traduce 1 a 1 el diseño de `MODELO_ANDROID_ROOM.md` sin mapeo manual. |

Respuestas también escritas en `ESQUEMA_CORREGIDO.md §5`. La Fase 01 del plan queda completa.

---

## 3. Las fases

### 01 · Cerrar las cinco decisiones — ✅ hecho (2026-09-06)
**Entregable:** §5 del documento con las 5 respuestas fechadas. Ver sección 2 arriba.

### 02 · El esquema, en Dart — ✅ hecho y probado (2026-09-06)
*Requeria D1 · D3 · D5.*
- Proyecto Flutter inicializado (`flutter create`), Kotlin real de `app/` movido a `android/app/src/main/kotlin/...` (paquete `com.tuapp.tienda_adaptativa`); los stubs vacios de `data/`, `decision/`, `di/`, `ui/` se descartaron — ahora se escriben en Dart.
- **10 tablas** + 1 vista en `lib/data/database/tables.dart`: 4 catálogos, 3 maestras, 3 bitácoras, `v_cierres_por_tipo_producto` (reemplaza el grupo repetitivo C10/G8) en `queries.drift`.
- Índices de §2.5 (FK + `idProcesoPersuasion`, `codCliente`, `codEstrategia`, `timestamp`).
- `AppDatabase.seedCatalogos()` corre dentro de `MigrationStrategy.onCreate`, antes de cualquier bitácora.
- `PRAGMA foreign_keys = ON` en cada conexión (trampa #1 — SQLite no lo activa solo).
- Fechas/horas como `INTEGER` epoch millis explícito (no `DateTimeColumn` de drift), para que coincida exacto con el SQL de los KPIs.
- **Probado de punta a punta** en `test/data/database/app_database_test.dart` (3 tests, todos pasan): siembra de catálogos, ciclo interacción→venta→detalle con FK activas, la vista de la consulta crítica, los 4 KPIs, y el batch (`cierresVenta`, `totalVendidos`, `montoTotalCentavos`).

**Entregable:** ✅ `flutter test test/data/database/` en verde.

### 03 · Datos de prueba y verificación contra el papel — ✅ hecho y probado (2026-09-06)
- El contenido de `TABLAS.docx` está en 21 imágenes incrustadas, no en texto (confirma el método ya usado en `ESQUEMA_CORREGIDO.md`). Se extrajeron del `.docx` y se leyeron directamente.
- Primer Caso (cliente C0000002, 3 interacciones → 1 venta, junio 2025) y Segundo Caso (cliente C0000023, 4 interacciones → 1 venta, mayo 2025) cargados tal cual en el esquema real.
- La vista de la consulta crítica y los 4 KPIs corren sobre los datos reales y dan resultados correctos (KPI1: 100% en ambos meses; KPI2: 50% — un caso mostró un solo producto, el otro dos).
- **Dos hallazgos nuevos en los datos fuente** (documentados en el test, no en `ESQUEMA_CORREGIDO.md` porque son erratas puntuales de estas filas, no del diseño): el Segundo Caso repite `correlativo 0003` dos veces con distinto `tipo_transaccion` (viola UNIQUE) — se renumeró; y aparece `cod_gesto G0000008`, fuera de las 5 emociones básicas del clasificador — **señal para Juan**: los datos históricos usan más gestos que las 5 clases FER-2013 actuales.
- Los contadores derivados (`cant_lecturas`, `monto_total`, etc.) no se verificaron: su valor "antes" depende de cientos de filas históricas que el documento omite con "...".

**Entregable:** ✅ `flutter test test/data/database/casos_reales_test.dart` en verde (5/5).

### 04 · Autenticación — ✅ hecho y probado (2026-09-06)
- `lib/data/repositories/cliente_repository.dart`: `registrar(nombre, apellido, tipoCliente?) → codCliente` (secuencial local `C0000001`, `C0000002`...) e `iniciarSesion(codCliente)`.
- Sesión persistida con `shared_preferences` (estado del dispositivo, no dato de negocio — no va en la BD).
- `tipoCliente` nullable (C3): se puede registrar sin él.
- 5/5 tests en verde (`test/data/repositories/cliente_repository_test.dart`).

### 05 · Motor de reglas de oferta ← *el rubro de 8 puntos* — ✅ hecho y probado (2026-09-06)
- `lib/decision/adaptation_engine.dart`: `decidirOferta(codCliente, codGesto, nivelDeInteres) → Oferta`.
- Reglas por gesto (consultando `gestos.nombreGesto`, no hardcodeando códigos): triste → producto más económico (sustituto); feliz → el más caro (premium); sorpresa → el menos mostrado (novedad); neutral → el más mostrado (estándar); enojo → cambia de categoría respecto al último producto mostrado a ese cliente + el más económico de esa categoría (descuento agresivo).
- Cada decisión inserta una fila en `interacciones` con `idProcesoPersuasion` (generado aquí, C1), `codGesto`, `codEstrategia`, `codLoteProducto`, `nivelDeInteres`. C11: `codEstrategia`/`codLoteProducto` nullable, sin centinela `00000000`.
- Selección de estrategia: la activa con menos `totalVecesAplicada` (exploración) — **placeholder explícito para la fase 06**, que lo reemplaza por el score UCB1.
- Un `tipoTransaccion` único sembrado (`TRX0001`); el aceptar/rechazar NO vive ahí — se infiere de si existe una `venta` con el mismo `idProcesoPersuasion` (fase 06).
- 6/6 tests en verde, incluida la regla eliminatoria del taller: mismo cliente + mismo nivel de interés, único input distinto es el gesto → la oferta cambia sola (`test/decision/adaptation_engine_test.dart`).

**Entregable:** `decidirOferta(codCliente, codGesto, nivelDeInteres) → Oferta`.

### 06 · Aprendizaje UCB1 — ✅ hecho y probado (2026-09-06)
- `lib/decision/learning/bandit_optimizer.dart`: `seleccionarEstrategia()` y `registrarRespuesta(idProcesoPersuasion, aceptada)`.
- **Decidido: recalculado al vuelo**, no via batch — `COUNT` en vivo sobre `interacciones`/`ventas` por estrategia en cada selección. Deliberadamente no toca `estrategias.ventasGeneradas`/`totalVecesAplicada`: esas columnas quedan exclusivas del batch (fase 07, para KPIs/presentación) y así nunca se pisan entre sí.
- Una estrategia nunca aplicada se prioriza sobre el score (evita dividir por cero y fuerza exploración inicial).
- `registrarRespuesta(aceptada: true)` crea la `venta` + `detalleVenta` (con snapshot del precio) que cierra el proceso; `aceptada: false` no crea nada — el rechazo se infiere de la ausencia de venta, igual que lo lee el KPI 2.
- `AdaptationEngine` ahora recibe `BanditOptimizer` inyectado; ya no tiene su propio placeholder de estrategia.
- 5/5 tests en verde (`test/decision/learning/bandit_optimizer_test.dart`); 20/20 en toda la suite.

### 07 · Batch y KPIs — ✅ hecho y probado (2026-09-06)
*Cero puntos de rúbrica; valor de presentación.*
- `lib/data/batch/batch_runner.dart`: `BatchRunner.ejecutarCierreDiario()` envuelve los 6 procesos (4 originales + `cierresVenta`/`totalVendidos` de D3) en **una sola transacción** (`db.transaction()`) — la regla de `Consideraciones.docx`.
- D1 aplicado: `totalVecesAplicada` agrupa por `codEstrategia`, no por `codCliente`.
- `lib/data/batch/cierre_diario_scheduler.dart`: programador periódico con `workmanager` (una vez al día). El entregable real sigue siendo `ejecutarCierreDiario()` a demanda — el scheduler solo automatiza dispararlo.
- Independiente de la fase 06: el bandit recalcula éxitos/intentos en vivo y nunca toca estas mismas columnas.
- 2/2 tests en verde (incluye idempotencia: correrlo dos veces da el mismo resultado); build de Android verificado con `workmanager` incluido.

**Entregable:** ✅ cierre diario ejecutable a demanda, probado.

---

## 4. El puente que el esquema ya tenía

El diseño del curso de Base de Datos ya trae los enganches que la app adaptativa necesita:

- **`maestra_gestos`** (corrección C2, para cerrar la FK huérfana G2) es donde entran las clases FER-2013 de Juan. La semilla la defino yo.
- **`nivelDeInteres`** como entero 0–100 (en vez del `float(2)` original) encaja con la confianza del clasificador.
- **`maestra_estrategias`** con sus dos contadores derivados es lo que UCB1 necesita, sin agregar una columna.
- **`idProcesoPersuasion`** (C1, el que desbloqueó G1) es la sesión de persuasión completa: desde que se detecta al cliente hasta que compra o se va. Lo genero yo y viaja en cada evento.

---

## 5. Las tres firmas a acordar con el equipo

| Dirección | Qué se pasa | Quién lo define |
|---|---|---|
| Juan → Elvis | Por emoción estable: `codGesto` + `nivelDeInteres` (0–100). Juan no escribe en la BD. | El mapeo FER-2013 → `maestra_gestos` lo defino yo al sembrar el catálogo. |
| Elvis → Steven | `decidirOferta(...)` devuelve la oferta a pintar; `registrarRespuesta(...)` cierra el ciclo. | Yo. Steven solo consume. |
| Elvis → Steven | `registrar(...)`, `iniciarSesion(...)`, cliente activo de la sesión. | Yo, incluido el formato de `codCliente`. |

---

## 6. Seis trampas de esta migración

1. **Las FK no se validan solas.** Room las valida por defecto; SQLite en Dart no. Hay que ejecutar `PRAGMA foreign_keys = ON` **en cada conexión**. Sin eso la corrección C11 queda sin efecto.
2. **Orden de siembra:** los 4 catálogos antes que cualquier fila de bitácora.
3. **Dinero en enteros:** `precioUnitarioCentavos`, `montoTotalCentavos` como `INTEGER`. Nunca `REAL`.
4. **El precio va en los dos lados:** vigente en `maestra_productos`, congelado en `bitacora_detalle_venta`. Sin la copia, cambiar un precio reescribe el historial.
5. **El `correlativo` colisiona en móvil:** dos dispositivos offline generan el mismo número. Solución ya documentada: `id` local + `uuid` de dispositivo.
6. **Un solo `timestamp`** en epoch millis, no dos campos `date(8)`. Elimina el error D2 y simplifica los `GROUP BY`.

---

## 7. Lo que no es mío

- **Cámara y captura de frames** — Steven. Recibo el resultado, no el video.
- **Modelo de emociones y estabilización** — Juan. Consumo `codGesto`, no lo produzco.
- **Pantallas y navegación** — Steven. Expongo funciones, no widgets.

Si algo de esto bloquea, el arreglo es acordar la firma correspondiente, no implementarlo yo.

---

*Fuentes: `Taller 01.pdf` (rúbrica), `ESQUEMA_CORREGIDO.md` (G1–G9, C1–C11), `MODELO_ANDROID_ROOM.md` (entidades, KPIs, batch) y el esqueleto Kotlin en `app/src/main/`.*
*`PLAN_TALLER01.md` quedó fuera: describe una carpeta `android/` que no existe en el repo y una ruta nativa que el equipo descartó.*
