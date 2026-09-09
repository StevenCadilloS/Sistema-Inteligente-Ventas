# Backend — base compartida y panel de administracion

La tienda dejo de guardar los datos en cada celular. Catalogo, stock, ofertas,
interacciones y ventas viven en **una sola base PostgreSQL** que todos los
dispositivos leen. Eso es lo que permite las tres cosas que antes eran
imposibles:

| Antes (SQLite por celular) | Ahora |
|---|---|
| El catalogo estaba escrito en el codigo (`catalogo_demo.dart`) | El administrador crea productos desde un panel |
| No existian las ofertas como dato: el descuento nacia y moria dentro de una decision | Las ofertas son filas con vigencia, y las publica una persona |
| Cada celular tenia su propio stock | El stock es uno solo, y baja en la pantalla de todos cuando alguien compra |
| El UCB1 aprendia de un solo telefono | Aprende de las interacciones de todos los usuarios |

---

## 1. Puesta en marcha (proyecto en la nube)

1. Crear un proyecto en <https://supabase.com> (el plan gratuito alcanza de
   sobra: el catalogo son 16 filas).
2. Abrir **SQL Editor** y ejecutar, en orden, el contenido de:
   - `migrations/0001_esquema.sql`
   - `migrations/0002_funciones.sql`
   - `migrations/0003_semilla.sql`
3. En **Settings → API**, copiar la *Project URL* y la *publishable key*
   (en proyectos antiguos se llama *anon key*).
4. En la raiz del repositorio, copiar `env.example.json` a `env.json` y pegar
   esos dos valores.
5. Compilar y ejecutar:

   ```bash
   flutter run --dart-define-from-file=env.json
   flutter build apk --release --dart-define-from-file=env.json
   ```

> **Nunca** pongas la `service_role key` en `env.json`. Esa clave ignora todas
> las politicas de seguridad y viajaria dentro del APK, al alcance de
> cualquiera que lo descomprima. La publica solo concede lectura.

## 2. Puesta en marcha sin cuenta en la nube

El esquema no usa nada exclusivo de Supabase: son tablas, funciones y
politicas de PostgreSQL. Se puede levantar en tu propia maquina.

**Solo la base** (suficiente para desarrollar el SQL y correr las pruebas):

```bash
podman compose -f supabase/docker-compose.yml up -d   # o docker compose
bash supabase/tests/ejecutar.sh
```

**Supabase completo** (panel, PostgREST y Realtime, todo Apache-2.0): clonar
<https://github.com/supabase/supabase>, levantar su `docker/docker-compose.yml`
y aplicar encima las migraciones de `migrations/`. La app apunta ahi cambiando
`SUPABASE_URL` en `env.json`.

---

## 3. Lo que hace el administrador

El panel de Supabase (**Table Editor**) es la vista de administracion: muestra
las tablas, deja filtrar, ordenar y editar. No hace falta construir una
pantalla aparte para operar la tienda.

### Agregar un producto

En **Table Editor → productos → Insert row**. Solo hacen falta cuatro campos:

| Campo | Valor |
|---|---|
| `nombre_producto` | Teclado Mecanico |
| `tipo_producto` | `T00001` (ver la tabla `tipos_producto`) |
| `precio_unitario_centavos` | `21900` — **centavos**, no soles: S/219.00 |
| `total_disponible` | `7` |

`cod_lote_producto` se deja vacio: la base asigna el siguiente (`P0000017`). La
imagen es opcional — `imagen` acepta el nombre de un archivo de
`assets/products/` o una URL completa; sin ella la tarjeta muestra el icono de
su categoria.

Al guardar, **el producto aparece en el feed de todos los usuarios conectados
sin que nadie refresque nada.**

### Publicar una oferta

En **Table Editor → ofertas → Insert row**, o desde el SQL Editor:

```sql
insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje, vigente_hasta)
values ('P0000005', 'Semana tecnologica', 20, now() + interval '7 days');
```

El precio rebajado llega a las pantallas de inmediato, con su etiqueta `-20%`.
Cuando pasa `vigente_hasta`, la oferta deja de aplicarse sola: no hay que ir a
apagarla.

Dos reglas que conviene conocer:

- Si hay dos ofertas vigentes sobre el mismo producto, **gana la de mayor
  descuento**.
- La oferta del administrador y el descuento adaptativo (el que decide la
  emocion del cliente) **no se suman: se toma el mayor de los dos**. Sumarlos
  permitiria que una promocion del 40% mas un enojo del 25% terminara
  regalando el producto.

### Reponer stock

Editar `total_disponible` en `productos`. El numero cambia en las tarjetas de
todos los usuarios en el momento. Un producto en 0 desaparece del catalogo, y
vuelve solo al reponerlo.

### Dar de baja un producto

Poner `activo = false`. No conviene borrarlo: sus ventas historicas lo
referencian y son las que alimentan los KPIs.

### Dar de alta a otro administrador

Crear el usuario en **Authentication → Users** y despues:

```sql
insert into administradores (id, correo)
values ('<el uuid del usuario>', 'persona@ejemplo.com');
```

Quien entra por el panel de Supabase usa el rol `service_role` y ya puede
escribir; la tabla `administradores` es para aplicaciones que se autentiquen
con un usuario normal.

---

## 4. Que ve cada quien

| Rol | Puede |
|---|---|
| `anon` (la app, con la clave que va dentro del APK) | **Solo leer** catalogo, ofertas y bitacoras. Escribe unicamente llamando a `fn_registrar_cliente`, `fn_registrar_interaccion` y `fn_registrar_venta` |
| `authenticated` + fila en `administradores` | Ademas, crear y editar productos, ofertas, categorias y estrategias |
| `service_role` (panel de Supabase) | Todo |

Que la app no pueda escribir tablas directamente no es una precaucion
decorativa: si pudiera hacer `INSERT`, tambien podria hacer `UPDATE` de
precios, y la clave esta al alcance de cualquiera que abra el APK.
`supabase/tests/04_seguridad.sql` comprueba justo eso, y falla si la tienda
queda abierta.

---

## 5. Cierre diario (modulo batch)

Los 6 procesos derivados son `fn_cierre_diario()`. La app lo dispara una vez al
dia con WorkManager, que sirve para la demostracion, pero en produccion
conviene que lo haga el servidor una sola vez y no cada dispositivo instalado.
Con pg_cron, desde el SQL Editor:

```sql
create extension if not exists pg_cron;
select cron.schedule('cierre-diario', '0 5 * * *', $$ select fn_cierre_diario() $$);
```

La funcion es idempotente: recalcula los contadores desde las bitacoras en vez
de acumular, asi que ejecutarla de mas no descuadra nada.

---

## 6. Consultas utiles

```sql
select * from v_catalogo order by precio_vigente_centavos;   -- lo que ve la tienda
select * from v_kpi1_cierre_por_mes;                          -- % de cierre por mes
select * from v_kpi3_efectividad_por_tipo_cliente;            -- que estrategia convierte
select * from v_estrategia_desempeno;                         -- lo que mira el UCB1
select * from v_cierres_por_tipo_producto order by timestamp desc;
```

---

## 7. Pruebas

```bash
bash supabase/tests/ejecutar.sh
```

Aplica las migraciones sobre la base y corre las cuatro suites. Cada una vive
en una transaccion que termina en `ROLLBACK`, asi que no dejan datos.

| Archivo | Que comprueba |
|---|---|
| `01_ciclo_venta.sql` | Registro de cliente, interaccion, venta, correlativos, precio congelado, stock, FK y errores esperados |
| `02_catalogo_y_ofertas.sql` | Vigencia de ofertas, composicion de descuentos, alta de productos nuevos |
| `03_batch_y_kpis.sql` | Cierre diario, idempotencia y los cuatro KPIs |
| `04_seguridad.sql` | Que la clave publica no pueda tocar precios, stock ni ventas |

Corren tambien en cada push, en el workflow `backend-sql.yml`.

---

## 8. Estructura

```
supabase/
├── migrations/
│   ├── 0001_esquema.sql      tablas, secuencias, RLS y permisos
│   ├── 0002_funciones.sql    escrituras atomicas, vistas, KPIs y Realtime
│   └── 0003_semilla.sql      catalogos base y catalogo de demostracion
├── tests/                    pruebas SQL + ejecutar.sh
├── docker-compose.yml        PostgreSQL local
└── README.md
```
