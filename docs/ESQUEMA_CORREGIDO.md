# Esquema de Base de Datos — Evaluación Verificada y Diseño Corregido
Sistema Cierre de Ventas — UNI FIIS · para implementación en Android Studio

> **Método:** se escanearon los 13 archivos de `docs/` con graphify (grafo en `graphify-out/`), pero como `TABLAS.docx` y el `.docx` del Módulo Batch guardan su contenido en **imágenes incrustadas** que el conversor no lee, se extrajeron y revisaron manualmente las 21 imágenes de `TABLAS.docx` y las 28 del Módulo Batch. Cada hallazgo de abajo está verificado contra la fuente, y los más importantes están **comprobados aritméticamente** con la Longitud de Registro declarada en el diseño físico.

---

## 1. Fuente autoritativa

Hay cuatro versiones del diseño de tablas repartidas entre documentos, y no coinciden entre sí. Para decidir cuál manda se comparó, en cada tabla, la **Longitud de Registro (RL) declarada** contra la **suma real de los tamaños de sus atributos**:

| Tabla | Fuente | RL declarada | Suma real | ¿Cuadra? | Diagnóstico |
|---|---|---:|---:|:--:|---|
| MAESTRA-CLIENTES | **Módulo Online** | 68 | **68** | ✅ | correcta |
| MAESTRA-CLIENTES | xlsx | 68 | 58 | ❌ −10 | le falta `monto_total dec(10)` |
| MAESTRA-ESTRATEGIAS | **Módulo Online** | 37 | **37** | ✅ | correcta |
| MAESTRA-ESTRATEGIAS | xlsx | 37 | 43 | ❌ +6 | le agregaron `tipo_cliente char(6)` sin recalcular |
| MAESTRA-PRODUCTOS | Módulo Online | 53 | 49 | ❌ −4 | le falta un `int(4)` |
| MAESTRA-PRODUCTOS | **xlsx** | 53 | **53** | ✅ | incluye `cierres_venta int(4)` |
| BITÁCORA-INTERACCIONES | **Módulo Online** | 67 | **67** | ✅ | correcta |
| BITÁCORA-INTERACCIONES | xlsx | 67 | 69 | ❌ +2 | cambió `id_interaccion char(8)` por `id_proceso_venta date(6)` + `tipo_cliente char(4)` |
| BITÁCORA-VENTAS | **Módulo Online** | 41 | **41** | ✅ | correcta |
| BITÁCORA-VENTAS | xlsx | 41 | 52 | ❌ +11 | le agregaron `cod_producto char(8)` + `cantidad int(3)` por error |
| BITÁCORA-DETALLE-VENTA | ambas | 17 | **17** | ✅ | correcta |

**Conclusión:** el **`Cierre de Ventas - Módulo Online.docx` es la versión autoritativa** (5 de 6 tablas cuadran exactas). El `.xlsx` contiene ediciones posteriores no validadas — incluidos los `#REF!` de Excel en 7 de los 9 atributos de BITÁCORA-VENTAS. La única corrección que el xlsx aporta correctamente es el atributo faltante de MAESTRA-PRODUCTOS.

---

## 2. Esquema verificado (línea base)

```
MAESTRA-PRODUCTOS                        RL 53 · IC 1024 · indexada
  cod_lote_producto     char     8   PK
  nombre_producto       varchar  20  SK
  fecha_creacion_stock  date     8
  total_disponible      int      4
  total_vendidos        int      4
  cierres_venta         int      4        <- solo en el xlsx; la RL 53 lo exige
  total_veces_mostrado  int      4
  estado_producto       char     1

MAESTRA-CLIENTES                         RL 68 · IC 512 · indexada
  cod_cliente           char     8   PK
  nombre_cliente        varchar  20  SK
  fecha_ingreso         date     8
  cant_lecturas         int      7
  total_compras         int      6
  monto_total           dec      10
  ultima_visita         date     8
  estado_cliente        char     1

MAESTRA-ESTRATEGIAS                      RL 37 · IC 1536 · indexada
  cod_estrategia        char     8   PK
  nombre_estrategia     varchar  20  SK
  total_veces_aplicada  int      4
  ventas_generadas      int      4
  estado                char     1

BITÁCORA-INTERACCIONES                   RL 67 · IC 512 · indexada
  canal                 char     1   PK
  correlativo           int      4   PK
  id_interaccion        char     8
  cod_cliente           char     8   FK
  cod_estrategia        char     8   FK
  cod_gesto             char     8   FK   <- sin tabla maestra (hallazgo G2)
  cod_producto          char     8   FK   <- nombre distinto a la PK que referencia (N3)
  tipo_transaccion      char     4        <- sin tabla catálogo (hallazgo G4)
  fecha                 date     8
  hora                  date     8
  nivel_de_interes      float    2

BITÁCORA-VENTAS                          RL 41 · IC 1024 · indexada
  canal                 char     1   PK
  correlativo           int      4   PK
  cod_cliente           char     8   FK
  cod_estrategia        char     8   FK
  tipo_transaccion      char     4
  fecha                 date     8
  hora                  date     8

BITÁCORA-DETALLE-VENTA                   RL 17 · IC 512 · indexada
  canal_venta           char     1   PK   <- se llama distinto que en BITÁCORA-VENTAS (N2)
  correlativo           int      4   PK
  cod_lote_producto     char     8   PK
  cantidad              int      4
```

---

## 3. Hallazgos

### 3.1 Vacíos estructurales (bloquean funcionalidad)

**G1 — `id_proceso_persuasion` no existe en ninguna tabla. Es el hallazgo más grave.**
Tres de los cuatro KPIs del Módulo Batch ordenan y agrupan por `id_proceso_persuasion`:
- *% de cierre de ventas x mes*: ordena **bitácora ventas** Y **bitácora interacciones** por `id_proceso_persuasion`.
- *% de ventas sin producto alternativo*: filtra interacciones cuyo `id_proceso_persuasion` aparece en ventas.
- *Actualización de `cant_lecturas`*: cuenta `id_proceso_persuasion` distintos por cliente.

Pero **BITÁCORA-VENTAS no tiene ese campo** (sus 7 atributos suman 41 y ahí no cabe). Lo único que comparte con BITÁCORA-INTERACCIONES es `(canal, correlativo)`, que son secuencias **independientes** en cada tabla — el correlativo 0001 de ventas no es el mismo evento que el 0001 de interacciones. Sin un identificador común, **no hay forma de saber qué intento de persuasión terminó en venta**, que es exactamente lo que mide el sistema.

Además, el mismo concepto aparece con tres nombres distintos:

| Documento | Nombre | Tipo |
|---|---|---|
| Módulo Online (autoritativo) | `id_interaccion` | char(8) |
| xlsx | `id_proceso_venta` | date(6) ← tipo incorrecto: los valores son `I00001` |
| Diagramas del Módulo Batch | `id_proceso_persuasion` | — |

**G2 — `cod_gesto char(8) FK` sin tabla maestra.** No existe `MAESTRA-GESTOS` en ningún documento (el Diseño Externo solo menciona un "Catálogo de Gestos" como pantalla). FK colgando.

**G3 — `tipo_cliente` no existe donde debe.** El modelo conceptual (hoja *Modelo* del xlsx) lo define correctamente como atributo de **Cliente**, pero MAESTRA-CLIENTES no lo tiene. El xlsx intentó parcharlo poniéndolo en **MAESTRA-ESTRATEGIAS** (donde no pertenece, y donde rompe la RL). Consecuencia: el KPI *"% efectividad de estrategias x tipo_cliente"* no se puede calcular.

**G4 — `tipo_transaccion char(4)` sin catálogo.** Valores `TRX0003`, `TRX0004`, `TRX0005`… El modelo conceptual define una entidad `Transaccion(codTRX, Tipo_TRX, cod_protocolo, estado)` que nunca llegó al diseño físico.

**G5 — No hay precio en ninguna tabla.** `MAESTRA-CLIENTES.monto_total dec(10)` es incalculable: ni MAESTRA-PRODUCTOS ni BITÁCORA-DETALLE-VENTA guardan un importe.

**G6 / G7 — La consulta crítica pide campos que no existen.** *"Cierres de venta por Tipo de Producto"* necesita `tipo_producto` (MAESTRA-PRODUCTOS no lo tiene) y `apellido` (MAESTRA-CLIENTES solo tiene `nombre_cliente varchar(20)`).

**G8 — La tabla consulta viola 1NF.** Está diseñada con un **grupo repetitivo `ventas(1-99)`** de 123 bytes por ocurrencia (RL 12196 máx / 2479 promedio). Es válido en el diseño físico de mainframe del curso, pero **SQLite/Room no puede representarlo**. Requiere rediseño (ver §4 del documento de Android).

**G9 — Valores centinela `00000000` en columnas FK.** En los datos de muestra de `TABLAS.docx` y del xlsx, las filas donde todavía no hubo estrategia o producto usan `cod_estrategia = 00000000` y `cod_lote_producto = 00000000`. No existe ninguna estrategia ni producto con ese código, así que la FK apunta al vacío. En Android esto **rompe la integridad referencial** (Room sí valida las FK, a diferencia de SQLite por defecto). Debe modelarse como `NULL`.

### 3.2 Inconsistencias de nomenclatura

- **N1 —** La misma tabla se llama `BITACORA INTERACCIONES` en el Primer Caso y `BITACORA CLIENTES` en el Segundo Caso de `TABLAS.docx` (mismas 11 columnas).
- **N2 —** La clave de enlace se llama `canal` en BITÁCORA-VENTAS y `canal_venta` en BITÁCORA-DETALLE-VENTA.
- **N3 —** La FK hacia productos se llama `cod_producto` en BITÁCORA-INTERACCIONES pero `cod_lote_producto` en BITÁCORA-DETALLE-VENTA y en la PK de MAESTRA-PRODUCTOS. En `TABLAS.docx` las capturas alternan entre ambos nombres dentro del mismo caso.
- **N4 —** `cant_lecturas`/`total_compras` (Módulo Online) vs `cant_entradas`/`total_cierres_ventas` (xlsx). **La aritmética favorece al Módulo Online**, y los diagramas batch usan `total_compras`.

### 3.3 Errores en los diagramas del Módulo Batch

- **D1 —** *Actualización de `total_veces_aplicada`*: todo el flujo ordena y agrega por `cod_estrategia`, pero la caja final dice *"Matching sin quiebre x **cod_cliente**"*. Debe ser `x cod_estrategia`. (Los otros tres procesos de actualización sí usan la clave correcta.)
- **D2 —** `hora` está tipada como `date(8)` en ambas bitácoras.
- **D3 —** Existen dos diagramas distintos (`Primer KPI.png` y `Tercer KPI.png`) para **el mismo** indicador *"% de ventas por día de la semana"*, con pipelines diferentes. Son propuestas alternativas; hay que elegir una.

### 3.4 Corrección a mi reporte anterior

En la primera versión de este documento reporté que "faltaban los diagramas de 2 KPIs". **Era incorrecto:** los diagramas de *% cierre de ventas x mes* y *% ventas sin producto alternativo* **sí existen**, dentro del `.docx` del Módulo Batch como imágenes incrustadas — invisibles para el conversor de texto. Los 4 KPIs están diagramados.

---

## 4. Correcciones aplicadas al diseño

| # | Corrección | Justificación |
|---|---|---|
| C1 | Agregar `id_proceso_persuasion char(8)` a **BITÁCORA-VENTAS** y renombrar `id_interaccion` → `id_proceso_persuasion` en BITÁCORA-INTERACCIONES | Desbloquea G1: es la clave que une intento ↔ cierre. Un solo nombre para el concepto |
| C2 | Nueva tabla `MAESTRA-GESTOS(cod_gesto PK, nombre_gesto, descripcion)` | Cierra la FK huérfana G2 |
| C3 | Mover `tipo_cliente` a **MAESTRA-CLIENTES** + nueva `MAESTRA-TIPO-CLIENTE` | G3; coincide con el modelo conceptual |
| C4 | Nueva tabla `MAESTRA-TIPO-TRANSACCION(cod_transaccion PK, tipo_trx, cod_protocolo, estado)` | G4; la entidad ya existía en el modelo conceptual |
| C5 | Agregar `precio_unitario` a MAESTRA-PRODUCTOS **y** snapshot `precio_unitario` en BITÁCORA-DETALLE-VENTA | G5. El snapshot evita que cambiar un precio altere ventas históricas |
| C6 | Agregar `tipo_producto` (FK a nueva `MAESTRA-TIPO-PRODUCTO`) y separar `nombre_cliente` en `nombre` + `apellido` | G6/G7: la consulta crítica los exige |
| C7 | Unificar `canal_venta` → `canal`, y `cod_producto` → `cod_lote_producto` | N2, N3 |
| C8 | Nombre único `BITACORA_INTERACCIONES` | N1 |
| C9 | Conservar `cant_lecturas`, `total_compras`, `monto_total`, y agregar `cierres_venta` a productos | N4 + fila de RL 53 |
| C10 | Reemplazar el grupo repetitivo de la tabla consulta por una vista normalizada | G8 |
| C11 | `cod_estrategia`/`cod_lote_producto` nullables; eliminar el centinela `00000000` | G9 |

---

## 5. Preguntas que necesitan tu decisión

1. ~~**`cant_lecturas` vs `cant_entradas`**~~ → **Decidido: `cant_lecturas`.** Cuadra con la RL 68 del Módulo Online (autoritativo) y con el nombre ya usado en los diagramas batch. (2026-09-05)
2. ~~**KPI de ventas por día**~~ → **Decidido: `Tercer KPI.png`.** Su fórmula (ventas/total_ventas × día) coincide con el título del indicador y con `MODELO_ANDROID_ROOM.md §4` KPI4; `Primer KPI.png` en realidad mide tasa de cierre por día (otra métrica), no distribución. (2026-09-05)
3. ~~**`cierres_venta` en MAESTRA-PRODUCTOS**~~ → **Decidido: se mantiene.** La RL 53 solo cuadra con este campo incluido (el Módulo Online lo omitió por error en su lista de campos, pese a declarar RL 53). Se mantiene el proceso batch, añadiendo `cierres_venta` como un `COUNT` más sobre `bitacora_detalle_venta`, junto a `total_vendidos`. (2026-09-05)
4. ~~**Alcance en Android**~~ → **Decidido: ambos.** Módulo online primero (fases 1-6, es lo que puntúa en el taller); batch + 4 KPIs como fase 7, no bloqueante, reaprovechando el SQL ya escrito en `MODELO_ANDROID_ROOM.md`. (2026-09-06)
5. ~~**`drift` vs `sqflite`**~~ → **Decidido: `drift`.** Traduce 1 a 1 lo ya diseñado en `MODELO_ANDROID_ROOM.md` (entidades tipadas, DAOs por codegen, vistas, migraciones), sin el mapeo manual `Map<String, dynamic>` de `sqflite`. (2026-09-06)

---

## 6. Siguiente paso

El modelo listo para Android Studio — DDL, entidades Room en Kotlin, DAOs para los 4 KPIs y las decisiones de optimización — está en **[MODELO_ANDROID_ROOM.md](MODELO_ANDROID_ROOM.md)**.

El grafo de conocimiento sigue disponible en `graphify-out/` (`graph.html` interactivo, `GRAPH_REPORT.md`, `graph.json`). Consultas: `graphify query "<pregunta>"`.
