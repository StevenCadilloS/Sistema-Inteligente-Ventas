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

### 03 · Datos de prueba y verificación contra el papel
*Requiere 02 (listo).* Cargar el Primer y Segundo Caso de `TABLAS.docx` (los reales, no los sintéticos de la prueba de humo) y comparar contra lo que el ejercicio ya calculó a mano.
**Entregable:** criterio de aceptación real — si los números coinciden, la traducción quedó bien.

### 04 · Autenticación
*Requiere 02.*
- Registro y login contra `maestra_clientes`; definir cómo se generan los `codCliente` (formato `C0000002`) en el dispositivo.
- C6 ya separó `nombre` y `apellido`: el formulario pide los dos.
- `tipoCliente` es nullable pero el KPI 3 agrupa por él — decidir si se pide al registrarse o se asigna después.
- Sesión local persistida.

**Entregable:** `registrar(nombre, apellido, tipoCliente?) → codCliente` e `iniciarSesion(codCliente)`.

### 05 · Motor de reglas de oferta ← *el rubro de 8 puntos*
*Requiere 02 + contrato con Juan.*
- Entra un gesto (emoción estable de Juan), sale una oferta concreta: estrategia, producto, precio, texto.
- Reglas base, ya escritas en los comentarios de `AdaptationEngine.kt`: triste → sustituto más económico; sorpresa → descuento o combo; feliz → premium sin descuento; neutral → estándar; enojo → cambio de categoría con descuento agresivo.
- Cada decisión escribe una fila en `bitacora_interacciones` con `idProcesoPersuasion`, `codGesto`, `codEstrategia`, `codLoteProducto`, `nivelDeInteres`.
- C11: `codEstrategia` y `codLoteProducto` son nullables de verdad. Nada de centinelas `00000000`.
- **Regla eliminatoria del taller:** la oferta debe cambiar sola al cambiar la emoción. Los botones "Me interesa / No gracias" son *retroalimentación*, no el disparador de la adaptación.

**Entregable:** `decidirOferta(codCliente, codGesto, nivelDeInteres) → Oferta`.

### 06 · Aprendizaje UCB1
*Requiere 05.*
- No necesita tablas nuevas: `maestra_estrategias.ventasGeneradas` y `totalVecesAplicada` **ya son** los éxitos e intentos de la fórmula.
- `score = ventasGeneradas / totalVecesAplicada + √(2·ln N / totalVecesAplicada)`.
- Definir de dónde salen los contadores: recalculados al vuelo (exactos) o mantenidos por el batch (rápidos de leer, desactualizados entre corridas). **No mezclar con triggers** sobre el mismo campo: se pisan.

**Entregable:** `registrarRespuesta(idProcesoPersuasion, aceptada)` y selección que mejora con el uso.

### 07 · Batch y KPIs
*Solo si D4 lo incluye. Cero puntos de rúbrica; valor de presentación.*
- Los 4 procesos de actualización en **una sola transacción** — la regla que exige `Consideraciones.docx`.
- Aplicar la corrección D1: `totalVecesAplicada` agrupa por `codEstrategia`, no por `codCliente` como decía el diagrama.
- Los 4 KPIs ya están en SQL en §4; en Flutter el programador periódico es `workmanager`.

**Entregable:** cierre diario ejecutable a demanda para la presentación.

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
