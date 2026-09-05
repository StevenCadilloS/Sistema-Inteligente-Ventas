# Modelo para Android Studio — Room / SQLite
Sistema Cierre de Ventas · implementación del esquema corregido

> Requiere leer antes **[ESQUEMA_CORREGIDO.md](ESQUEMA_CORREGIDO.md)** (hallazgos G1–G9, correcciones C1–C11).

---

## 1. Qué se traduce del diseño original y qué no

El diseño del curso es un **diseño físico de mainframe** (registros de longitud fija, bloques, archivos secuenciales, UNLOAD/LOAD, matching con/sin quiebre de control). Buena parte de eso no tiene equivalente en SQLite y **no debe copiarse literalmente**:

| Concepto del diseño original | En Android/Room | Por qué |
|---|---|---|
| `char(8)`, `varchar(20)` con tamaño fijo | `TEXT` sin longitud | SQLite usa tipado dinámico; declarar longitudes no las hace cumplir |
| Longitud de Registro (RL 53, 67…) | *no aplica* | Sirvió para dimensionar bloques en disco; SQLite maneja páginas solo |
| IC (longitud de bloque 512/1024/1536) | *no aplica* | Lo decide el `page_size` de SQLite (4096 por defecto) |
| Capacidad `N=1000000, AC=19*12*18` | *no aplica* | Cálculo de extents de mainframe |
| "Organización indexada" | `@Index` de Room | Es el equivalente real y sí importa |
| UNLOAD → ordenar → matching → LOAD | `GROUP BY` + `UPDATE` dentro de una transacción, lanzados por WorkManager | El motor SQL ya hace el sort-merge internamente |
| Grupo repetitivo `ventas(1-99)` | tabla normalizada + `@DatabaseView` | Viola 1NF; SQLite no puede almacenar grupos repetitivos |
| `date(8)` + `hora date(8)` separados | un solo `timestamp INTEGER` (epoch millis) | Simplifica rangos y ordenamiento; elimina el bug de tipo D2 |
| `dec(10)` para dinero | `INTEGER` en céntimos | **Nunca `REAL` para dinero** — el redondeo binario acumula error |
| `float(2)` para nivel_de_interes | `INTEGER` 0–100 con `CHECK` | Es un porcentaje entero en todos los datos de muestra |
| centinela `00000000` | `NULL` | Room valida FKs; el centinela las rompería (G9) |

**Lo que sí se conserva:** los nombres de tabla y de atributo, la semántica de cada campo, las relaciones, los 4 KPIs y la consulta crítica. El batch se conserva como proceso, solo cambia su implementación.

---

## 2. Decisiones de optimización

### 2.1 Claves primarias: `INTEGER` interno + clave de negocio única

El diseño original usa PKs compuestas de texto (`canal` + `correlativo`). En SQLite conviene un `INTEGER PRIMARY KEY`, porque es **alias del `rowid`** y por lo tanto la clave de clustering real de la tabla: los joins y los índices secundarios apuntan a él directamente. Una PK de texto compuesta obliga a SQLite a mantener un índice extra y encarece cada join.

```kotlin
@PrimaryKey(autoGenerate = true) val id: Long = 0,
// y la clave de negocio como índice único:
@Index(value = ["canal", "correlativo"], unique = true)
```

Así conservas la restricción del diseño original (no puede haber dos ventas con el mismo canal+correlativo) sin pagar su costo en cada join.

### 2.2 El problema del `correlativo` en móvil

`correlativo` es una secuencia por canal. En una app móvil **dos dispositivos sin conexión generarían el mismo correlativo** y colisionarían al sincronizar. Opciones:

- **Recomendada:** `id` local autoincrement + `uuid TEXT` generado en el dispositivo como identidad global. El `correlativo` "oficial" lo asigna el servidor al sincronizar.
- Alternativa sin servidor: incluir `device_id` en la clave única → `(canal, device_id, correlativo)`.

### 2.3 Atributos derivados: batch vs vistas

`total_vendidos`, `total_veces_mostrado`, `cierres_venta`, `cant_lecturas`, `total_compras`, `monto_total`, `total_veces_aplicada` y `ventas_generadas` son **datos derivados** de las bitácoras. Tres estrategias:

| Estrategia | Ventaja | Costo | Cuándo usarla |
|---|---|---|---|
| **A. Batch periódico** (WorkManager) | Fiel al diseño original; lecturas instantáneas | Los valores quedan desactualizados hasta la próxima corrida | Métricas de reporte; es lo que pide el curso |
| **B. `@DatabaseView`** (cálculo al vuelo) | Imposible que se desincronice | Se recalcula en cada consulta | Pantallas que necesitan el dato exacto ahora |
| **C. Triggers SQLite** | Siempre consistente y barato de leer | Lógica escondida en la BD, difícil de testear | Contadores muy calientes |

**Recomendación:** A para los KPIs e indicadores (§4), B para lo que se muestre en pantalla del cliente/producto. No mezcles A y C sobre el mismo campo: se pisarían.

### 2.4 Precio histórico

`precio_unitario` va **en los dos lados**: en `maestra_productos` (precio vigente) y como *snapshot* en `bitacora_detalle_venta` (precio al momento de la venta). Sin el snapshot, cambiar el precio de un producto reescribiría el historial de ventas y `monto_total` dejaría de cuadrar.

### 2.5 Índices

Room emite warning si una FK no tiene índice. Además de esos, los KPIs necesitan:

```
bitacora_interacciones : (id_proceso_persuasion), (cod_cliente), (cod_estrategia), (timestamp)
bitacora_ventas        : (id_proceso_persuasion), (cod_cliente), (cod_estrategia), (timestamp)
bitacora_detalle_venta : (venta_id), (cod_lote_producto)
maestra_productos      : (tipo_producto)
maestra_clientes       : (tipo_cliente)
```

---

## 3. Entidades Room

```kotlin
package pe.edu.uni.cierreventas.data.entity

import androidx.room.*

// ─────────────── CATÁLOGOS ───────────────

@Entity(tableName = "maestra_tipo_cliente")
data class TipoCliente(
    @PrimaryKey val codTipoCliente: String,      // T00001
    val nombreTipoCliente: String,
    val activo: Boolean = true
)

@Entity(tableName = "maestra_tipo_producto")
data class TipoProducto(
    @PrimaryKey val tipoProducto: String,        // T00002  (C6)
    val nombreTipoProducto: String,
    val activo: Boolean = true
)

@Entity(tableName = "maestra_gestos")            // C2 — cierra la FK huérfana G2
data class Gesto(
    @PrimaryKey val codGesto: String,            // G0000004
    val nombreGesto: String,
    val descripcion: String? = null,
    val activo: Boolean = true
)

@Entity(tableName = "maestra_tipo_transaccion")  // C4 — G4
data class TipoTransaccion(
    @PrimaryKey val codTransaccion: String,      // TRX0003
    val tipoTrx: String,
    val codProtocolo: String? = null,
    val activo: Boolean = true
)

// ─────────────── MAESTRAS ───────────────

@Entity(
    tableName = "maestra_clientes",
    foreignKeys = [ForeignKey(
        entity = TipoCliente::class,
        parentColumns = ["codTipoCliente"], childColumns = ["tipoCliente"],
        onDelete = ForeignKey.RESTRICT
    )],
    indices = [Index("tipoCliente")]
)
data class Cliente(
    @PrimaryKey val codCliente: String,          // C0000002
    val nombre: String,                          // C6 — separado de apellido
    val apellido: String,
    val tipoCliente: String?,                    // C3 — movido aquí desde estrategias
    val fechaIngreso: Long,                      // epoch millis
    // ── derivados, mantenidos por el batch (§4) ──
    val cantLecturas: Int = 0,
    val totalCompras: Int = 0,
    val montoTotalCentavos: Long = 0,            // dinero en enteros
    val ultimaVisita: Long? = null,
    val activo: Boolean = true
)

@Entity(
    tableName = "maestra_productos",
    foreignKeys = [ForeignKey(
        entity = TipoProducto::class,
        parentColumns = ["tipoProducto"], childColumns = ["tipoProducto"],
        onDelete = ForeignKey.RESTRICT
    )],
    indices = [Index("tipoProducto")]
)
data class Producto(
    @PrimaryKey val codLoteProducto: String,     // P0000005
    val nombreProducto: String,
    val tipoProducto: String?,                   // C6 — lo exige la consulta crítica
    val precioUnitarioCentavos: Long,            // C5 — desbloquea monto_total
    val fechaCreacionStock: Long,
    val totalDisponible: Int = 0,
    // ── derivados ──
    val totalVendidos: Int = 0,
    val cierresVenta: Int = 0,                   // C9 — exigido por la RL 53
    val totalVecesMostrado: Int = 0,
    val activo: Boolean = true
)

@Entity(tableName = "maestra_estrategias")
data class Estrategia(
    @PrimaryKey val codEstrategia: String,       // E0000002
    val nombreEstrategia: String,
    // NO lleva tipo_cliente (G3)
    val totalVecesAplicada: Int = 0,             // derivado
    val ventasGeneradas: Int = 0,                // derivado
    val activo: Boolean = true
)

// ─────────────── BITÁCORAS ───────────────

@Entity(
    tableName = "bitacora_interacciones",
    foreignKeys = [
        ForeignKey(Cliente::class,   ["codCliente"],       ["codCliente"]),
        ForeignKey(Estrategia::class,["codEstrategia"],    ["codEstrategia"]),
        ForeignKey(Gesto::class,     ["codGesto"],         ["codGesto"]),
        ForeignKey(Producto::class,  ["codLoteProducto"],  ["codLoteProducto"]),
        ForeignKey(TipoTransaccion::class, ["tipoTransaccion"], ["codTransaccion"])
    ],
    indices = [
        Index(value = ["canal", "correlativo"], unique = true),
        Index("idProcesoPersuasion"), Index("codCliente"),
        Index("codEstrategia"), Index("codGesto"),
        Index("codLoteProducto"), Index("tipoTransaccion"), Index("timestamp")
    ]
)
data class Interaccion(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val canal: String,                           // 'W' web, 'A' app
    val correlativo: Int,
    val idProcesoPersuasion: String,             // C1 — la clave que une intento ↔ cierre
    val codCliente: String,
    val codEstrategia: String?,                  // C11 — nullable, sin centinela 00000000
    val codGesto: String?,
    val codLoteProducto: String?,                // C7 — nombre unificado
    val tipoTransaccion: String,
    val timestamp: Long,                         // fecha + hora en un solo campo
    val nivelDeInteres: Int                      // 0..100
)

@Entity(
    tableName = "bitacora_ventas",
    foreignKeys = [
        ForeignKey(Cliente::class,    ["codCliente"],    ["codCliente"]),
        ForeignKey(Estrategia::class, ["codEstrategia"], ["codEstrategia"]),
        ForeignKey(TipoTransaccion::class, ["tipoTransaccion"], ["codTransaccion"])
    ],
    indices = [
        Index(value = ["canal", "correlativo"], unique = true),
        Index("idProcesoPersuasion"), Index("codCliente"),
        Index("codEstrategia"), Index("timestamp")
    ]
)
data class Venta(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val canal: String,                           // C7 — antes canal_venta en detalle
    val correlativo: Int,
    val idProcesoPersuasion: String,             // ★ C1 — el campo que faltaba (G1)
    val codCliente: String,
    val codEstrategia: String?,
    val tipoTransaccion: String,
    val timestamp: Long
)

@Entity(
    tableName = "bitacora_detalle_venta",
    foreignKeys = [
        ForeignKey(Venta::class, ["id"], ["ventaId"], onDelete = ForeignKey.CASCADE),
        ForeignKey(Producto::class, ["codLoteProducto"], ["codLoteProducto"])
    ],
    indices = [
        Index(value = ["ventaId", "codLoteProducto"], unique = true),
        Index("codLoteProducto")
    ]
)
data class DetalleVenta(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val ventaId: Long,                           // FK real, no (canal, correlativo) suelto
    val codLoteProducto: String,
    val cantidad: Int,
    val precioUnitarioCentavos: Long             // §2.4 — snapshot del precio
)
```

---

## 4. Los 4 KPIs y la consulta crítica

### KPI 1 — % de cierre de ventas por mes

```kotlin
@Query("""
    WITH intentos AS (
        SELECT strftime('%Y-%m', timestamp/1000, 'unixepoch') AS mes,
               COUNT(DISTINCT idProcesoPersuasion) AS n
        FROM bitacora_interacciones GROUP BY mes
    ),
    cierres AS (
        SELECT strftime('%Y-%m', timestamp/1000, 'unixepoch') AS mes,
               COUNT(DISTINCT idProcesoPersuasion) AS n
        FROM bitacora_ventas GROUP BY mes
    )
    SELECT i.mes AS mes,
           COALESCE(c.n, 0) AS cierres,
           i.n AS intentos,
           ROUND(100.0 * COALESCE(c.n, 0) / i.n, 2) AS porcentaje
    FROM intentos i LEFT JOIN cierres c ON c.mes = i.mes
    ORDER BY i.mes
""")
suspend fun cierreVentasPorMes(): List<CierrePorMes>
```

### KPI 2 — % de ventas sin producto alternativo

De los procesos que terminaron en venta, cuántos mostraron **un solo** producto:

```kotlin
@Query("""
    WITH productos_por_proceso AS (
        SELECT idProcesoPersuasion AS pid,
               COUNT(DISTINCT codLoteProducto) AS n_prod
        FROM bitacora_interacciones
        WHERE codLoteProducto IS NOT NULL
        GROUP BY idProcesoPersuasion
    )
    SELECT ROUND(100.0 * SUM(CASE WHEN p.n_prod = 1 THEN 1 ELSE 0 END) / COUNT(*), 2)
    FROM productos_por_proceso p
    WHERE p.pid IN (SELECT DISTINCT idProcesoPersuasion FROM bitacora_ventas)
""")
suspend fun ventasSinProductoAlternativo(): Double
```

> Nota: esta consulta es la prueba de por qué G1 era bloqueante — sin `idProcesoPersuasion` en ambas tablas, el `IN (...)` no tendría por dónde enlazar.

### KPI 3 — % de efectividad de estrategias por tipo de cliente

```kotlin
@Query("""
    SELECT cl.tipoCliente        AS tipoCliente,
           e.codEstrategia       AS codEstrategia,
           e.nombreEstrategia    AS nombreEstrategia,
           COUNT(DISTINCT v.idProcesoPersuasion) AS ventasGeneradas,
           COUNT(DISTINCT i.idProcesoPersuasion) AS vecesAplicada,
           ROUND(100.0 * COUNT(DISTINCT v.idProcesoPersuasion)
                 / NULLIF(COUNT(DISTINCT i.idProcesoPersuasion), 0), 2) AS efectividad
    FROM bitacora_interacciones i
    JOIN maestra_clientes cl     ON cl.codCliente = i.codCliente
    JOIN maestra_estrategias e   ON e.codEstrategia = i.codEstrategia
    LEFT JOIN bitacora_ventas v  ON v.idProcesoPersuasion = i.idProcesoPersuasion
                                AND v.codEstrategia = i.codEstrategia
    GROUP BY cl.tipoCliente, e.codEstrategia
    ORDER BY cl.tipoCliente, efectividad DESC
""")
suspend fun efectividadEstrategiaPorTipoCliente(): List<EfectividadEstrategia>
```

### KPI 4 — % de ventas por día de la semana

```kotlin
@Query("""
    SELECT CAST(strftime('%w', timestamp/1000, 'unixepoch') AS INTEGER) AS diaSemana,
           COUNT(*) AS ventas,
           ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM bitacora_ventas), 2) AS porcentaje
    FROM bitacora_ventas
    GROUP BY diaSemana ORDER BY diaSemana
""")
suspend fun ventasPorDiaSemana(): List<VentasPorDia>   // 0 = domingo … 6 = sábado
```

### Consulta crítica — cierres de venta por tipo de producto (reemplaza el grupo repetitivo, C10/G8)

```kotlin
@DatabaseView("""
    SELECT p.tipoProducto           AS tipoProducto,
           tp.nombreTipoProducto    AS nombreTipoProducto,
           c.codCliente             AS codCliente,
           c.nombre || ' ' || c.apellido AS cliente,
           p.codLoteProducto        AS codLoteProducto,
           p.nombreProducto         AS nombreProducto,
           d.cantidad               AS cantidad,
           d.precioUnitarioCentavos * d.cantidad AS importeCentavos,
           e.codEstrategia          AS codEstrategia,
           e.nombreEstrategia       AS nombreEstrategia,
           v.timestamp              AS timestamp
    FROM bitacora_detalle_venta d
    JOIN bitacora_ventas v        ON v.id = d.ventaId
    JOIN maestra_productos p      ON p.codLoteProducto = d.codLoteProducto
    LEFT JOIN maestra_tipo_producto tp ON tp.tipoProducto = p.tipoProducto
    JOIN maestra_clientes c       ON c.codCliente = v.codCliente
    LEFT JOIN maestra_estrategias e ON e.codEstrategia = v.codEstrategia
""", viewName = "v_cierres_por_tipo_producto")
data class CierrePorTipoProducto(
    val tipoProducto: String?, val nombreTipoProducto: String?,
    val codCliente: String, val cliente: String,
    val codLoteProducto: String, val nombreProducto: String,
    val cantidad: Int, val importeCentavos: Long,
    val codEstrategia: String?, val nombreEstrategia: String?,
    val timestamp: Long
)
```

Una fila por venta-producto en vez de un registro con 99 ocurrencias: misma información, en 1NF, y filtrable por `tipoProducto` con un índice.

---

## 5. El batch, como WorkManager

Los 4 procesos de actualización del Módulo Batch, con la **corrección D1** aplicada (`total_veces_aplicada` se agrupa por `cod_estrategia`, no por `cod_cliente`):

```kotlin
@Dao
interface BatchDao {

    // 2.1.1 — matching x cod_estrategia  (D1: el diagrama decía cod_cliente, es un error)
    @Query("""
        UPDATE maestra_estrategias SET totalVecesAplicada = (
            SELECT COUNT(*) FROM bitacora_interacciones i
            WHERE i.codEstrategia = maestra_estrategias.codEstrategia
        )
    """)
    suspend fun actualizarTotalVecesAplicada()

    // 2.1.2 — matching con quiebre x cod_estrategia
    @Query("""
        UPDATE maestra_estrategias SET ventasGeneradas = (
            SELECT COUNT(*) FROM bitacora_ventas v
            WHERE v.codEstrategia = maestra_estrategias.codEstrategia
        )
    """)
    suspend fun actualizarVentasGeneradas()

    // 2.2.1 — procesos de persuasión distintos por cliente
    @Query("""
        UPDATE maestra_clientes SET cantLecturas = (
            SELECT COUNT(DISTINCT i.idProcesoPersuasion) FROM bitacora_interacciones i
            WHERE i.codCliente = maestra_clientes.codCliente
        )
    """)
    suspend fun actualizarCantLecturas()

    // 2.2.2 — matching con quiebre x cod_cliente
    @Query("""
        UPDATE maestra_clientes SET
            totalCompras = (SELECT COUNT(*) FROM bitacora_ventas v
                            WHERE v.codCliente = maestra_clientes.codCliente),
            montoTotalCentavos = (
                SELECT COALESCE(SUM(d.cantidad * d.precioUnitarioCentavos), 0)
                FROM bitacora_ventas v
                JOIN bitacora_detalle_venta d ON d.ventaId = v.id
                WHERE v.codCliente = maestra_clientes.codCliente),
            ultimaVisita = (SELECT MAX(v.timestamp) FROM bitacora_ventas v
                            WHERE v.codCliente = maestra_clientes.codCliente)
    """)
    suspend fun actualizarTotalesCliente()

    @Transaction
    suspend fun ejecutarCierreDiario() {
        actualizarTotalVecesAplicada()
        actualizarVentasGeneradas()
        actualizarCantLecturas()
        actualizarTotalesCliente()
    }
}

class CierreDiarioWorker(ctx: Context, params: WorkerParameters) :
    CoroutineWorker(ctx, params) {
    override suspend fun doWork(): Result = try {
        AppDatabase.get(applicationContext).batchDao().ejecutarCierreDiario()
        Result.success()
    } catch (e: Exception) { Result.retry() }
}

// registro (una vez, en Application.onCreate)
WorkManager.getInstance(context).enqueueUniquePeriodicWork(
    "cierre_diario", ExistingPeriodicWorkPolicy.KEEP,
    PeriodicWorkRequestBuilder<CierreDiarioWorker>(1, TimeUnit.DAYS)
        .setConstraints(Constraints.Builder()
            .setRequiresBatteryNotLow(true).build())
        .build()
)
```

El `@Transaction` cumple la regla del documento *Consideraciones*: **el batch es un proceso único** — o se actualizan las cuatro cosas, o no se actualiza ninguna.

---

## 6. Orden de trabajo sugerido

1. Crear el proyecto con Room (`androidx.room:room-runtime`, `room-ktx`, y `room-compiler` vía KSP).
2. Pegar las entidades de §3 y crear la `@Database` con `exportSchema = true` (el JSON del esquema sirve como entregable y para migraciones).
3. Sembrar los catálogos (`tipo_cliente`, `tipo_producto`, `gestos`, `tipo_transaccion`) con un `RoomDatabase.Callback` — **antes** de cualquier bitácora, o las FKs fallarán.
4. Cargar los datos de muestra de `TABLAS.docx` (Primer y Segundo Caso) como datos de prueba: sirven para validar que los KPIs dan lo mismo que el ejercicio en papel.
5. Implementar los DAOs de §4 y verificar contra esos casos.
6. Recién ahí, el batch de §5.

Antes de empezar, conviene cerrar las 4 preguntas abiertas de [ESQUEMA_CORREGIDO.md §5](ESQUEMA_CORREGIDO.md) — sobre todo la #4 (si la app cubre solo el módulo online o también el batch), porque decide si los pasos 5 y 6 entran en el alcance.
