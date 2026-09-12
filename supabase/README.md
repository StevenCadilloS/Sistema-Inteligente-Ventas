# Backend — base compartida y panel de administracion

El catalogo, las ofertas y las ventas viven en **una sola base PostgreSQL**
que todos los dispositivos leen. La app no escribe tablas: pide, y el servidor
aprueba.

## Como se reparte el trabajo

| Vive en el APK (celular) | Vive en el servidor |
|---|---|
| Las pantallas | El catalogo, precios y stock |
| **La deteccion de emociones** (ML Kit + TensorFlow Lite, sin subir imagenes) | Las ofertas y **su orden** |
| Decidir *cuando* pedir el siguiente escalon | El registro de ventas |
| | Las reglas: limite diario, stock, que el total cuadre |

La camara nunca sale del telefono. Lo que viaja por la red es "dame las
ofertas del producto 3", con el token que dice quien pregunta, nunca una
imagen.

> **La emocion no calcula el descuento.** Solo decide si el sistema se queda
> donde esta o avanza al siguiente escalon de una escalera que un
> administrador configuro antes. Los descuentos no se inventan en el codigo.

---

## 1. Puesta en marcha (proyecto en la nube)

1. Crear un proyecto en <https://supabase.com> (el plan gratuito alcanza de
   sobra: el catalogo son 20 filas).
2. Abrir **SQL Editor** y ejecutar, en orden, el contenido de:
   - `migrations/0001_esquema.sql`
   - `migrations/0002_funciones.sql`
   - `migrations/0003_semilla.sql`
   - `migrations/0004_autenticacion.sql`
   - `migrations/0005_almacenamiento.sql`
   - `migrations/0006a_productos.sql`
   - `migrations/0006b_escaleras.sql`
   - `migrations/0006c_combos.sql`
   - `migrations/0007_indices.sql`
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
politicas de PostgreSQL.

```bash
podman compose -f supabase/docker-compose.yml up -d   # o docker compose
bash supabase/tests/ejecutar.sh
```

---

## 3. Lo que hace el administrador

El **Table Editor** de Supabase es la vista de administracion.

### Agregar un producto

**Table Editor → productos → Insert row**:

| Campo | Valor |
|---|---|
| `id_categoria` | el id de la categoria (ver tabla `categorias`) |
| `id_marca` | el id de la marca |
| `nombre` | Teclado Mecanico |
| `precio_centavos` | `21900` — **centavos**, no soles: S/219.00 |
| `stock` | `7` |

`id_producto` se deja vacio: la base asigna el siguiente. La imagen es
opcional: sin ella, la tarjeta muestra el icono de su categoria.

### Poner la foto de un producto

Las fotos no viven en la base —guardar binarios en PostgreSQL es caro y
lento— sino en el bucket `productos` de **Storage**. La columna `imagen`
guarda solo la referencia.

1. **Storage → productos → Upload file**
2. Asignarla al producto:

```sql
update productos set imagen = fn_url_imagen('laptop_lenovo.jpg')
 where nombre = 'Laptop Lenovo IdeaPad';
```

`fn_url_imagen` arma la URL publica a partir del nombre del archivo, sin
tener que recordar el formato ni el id del proyecto. Si se le pasa una URL
completa la devuelve tal cual, asi que tambien se pueden usar fotos alojadas
fuera.

El bucket es de **lectura publica** porque el catalogo se ve sin iniciar
sesion: sus fotos no son un secreto, y un bucket privado obligaria a firmar
cada URL y renovarla al caducar para proteger algo que cualquiera ve abriendo
la tienda. **Subir, reemplazar y borrar exigen ser administrador**: la clave
publica va dentro del APK, y quien la extraiga no debe poder poner cualquier
imagen en las tarjetas que ven los clientes.

### Publicar una oferta

Una oferta es **de descuento** (un porcentaje) o **de combo** (un precio final
fijo), nunca las dos cosas. La base lo exige con `chk_oferta_coherente`.

```sql
-- 1. La oferta
insert into ofertas (id_admin, nombre, id_tipo, porcentaje_descuento, fecha_fin)
values (1, 'Semana tecnologica', 1, 20, now() + interval '7 days');

-- 2. En que escalon entra, y de que producto
insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
values (currval('ofertas_id_oferta_seq'), 5, 1, 1);
```

El porcentaje es **entero**: `20` es 20%, no `0.20`. El tope es 90 — un 100%
regalaria el producto y dejaria el total en cero.

### La escalera de ofertas

`orden` define por donde sube el sistema cuando el cliente responde
desfavorablemente:

```
Laptop Lenovo
  orden 1 → 10%   (primer intento)
  orden 2 → 20%   (si sigue sin convencer)
  orden 3 → 30%   (ultimo escalon)
```

Dos reglas que impone la base:

- **Un escalon, una oferta.** `uq_orden_por_producto` impide que dos ofertas
  peleen por el mismo `orden` del mismo producto: el desempate seria
  arbitrario y la secuencia dejaria de ser reproducible.
- **Cada escalon deberia rebajar mas que el anterior.** Esto no lo puede
  garantizar una restriccion (el administrador podria poner 30% antes que
  10%), pero el sistema lo espera: avanzar tiene que mejorar la oferta, o el
  cliente ve como le suben el precio al poner mala cara.

### Reponer stock

Editar `stock` en `productos`. El numero cambia en las tarjetas de todos los
usuarios en el momento. Un producto en 0 desaparece del catalogo.

### Dar de baja un producto

Poner `activo = false`. No conviene borrarlo: sus ventas historicas lo
referencian.

### Dar de alta a otro administrador

Crear el usuario en **Authentication → Users** y despues enlazarlo:

```sql
update administradores set uid = '<el uuid del usuario>'
 where correo = 'persona@ejemplo.com';
```

Quien entra por el panel usa `service_role` y ya puede escribir; el `uid` es
para aplicaciones que se autentiquen con un usuario normal.

---

## 4. Que ve cada quien

| Rol | Puede |
|---|---|
| `anon` (la app sin sesion) | **Solo leer** el catalogo y las ofertas. Nada mas: no puede comprar, ni ver ofertas personalizadas, ni leer ningun historial |
| `authenticated` (cliente con cuenta) | Ademas, comprar, pedir su escalera de ofertas y leer **sus** compras |
| `authenticated` + fila en `administradores` | Ademas, crear y editar productos, ofertas y categorias |
| `service_role` (panel de Supabase) | Todo |

Que la app no pueda escribir tablas no es una precaucion decorativa: si
pudiera hacer `INSERT`, tambien podria hacer `UPDATE` de precios, y la clave
esta al alcance de cualquiera que abra el APK. `supabase/tests/04_seguridad.sql`
comprueba justo eso, y falla si la tienda queda abierta.

Ni el precio ni la identidad se los cree el servidor a la app:
`fn_registrar_venta` no recibe ningun total — lo **recalcula** desde el
catalogo — y tampoco recibe el id del cliente: lo saca del token. Mientras lo
recibia como parametro, cualquiera con la clave publica podia registrar
compras a nombre de otra persona.

### Las contrasenas

No estan en nuestras tablas. `clientes` guarda `uid`, que apunta a
`auth.users`; el hash (bcrypt), el salt, el refresco de tokens y la
recuperacion por correo los maneja Supabase Auth en un esquema al que la app
no tiene acceso. Escribir uno mismo el hashing de contrasenas es facil de hacer
mal, y delegarlo elimina esa categoria entera de errores.

El correo tampoco lo manda el formulario: `fn_registrar_cliente` lo lee de
`auth.users`, que es el que Supabase ya verifico.

---

## 5. La regla de las dos ofertas por dia

Un cliente puede usar ofertas solo en sus **dos primeras compras del dia**.
Se cuentan las compras, no las que llevaron oferta: a la tercera ya no hay
oferta aunque las dos primeras fueran a precio normal.

```sql
select fn_compras_del_dia();    -- cuantas lleva hoy quien llama
select fn_puede_usar_oferta();  -- le queda derecho a oferta?
```

Ninguna de las dos recibe a quien consultar: sale del token. Es lo que hace
que el limite signifique algo — antes de que los clientes tuvieran cuenta,
bastaba con reinstalar la app para volver a cero.

"Hoy" es el dia en `America/Lima`, no en UTC: con UTC, una compra a las 8 de
la noche ya contaria como del dia siguiente y el cliente estrenaria su limite
a mitad de la tarde. Si el negocio opera en otro huso, se cambia en
`fn_zona_negocio()`.

---

## 6. Consultas utiles

```sql
select * from v_catalogo order by precio_centavos;      -- lo que ve la tienda
select * from v_ofertas_vigentes;                        -- ofertas activas hoy
select * from v_secuencia_ofertas where id_producto = 1; -- la escalera de un producto
select * from fn_ofertas_de(1);                          -- escalera para quien llama
select * from fn_historial(20);                          -- sus ultimas compras
```

---

## 7. Pruebas

```bash
bash supabase/tests/ejecutar.sh
```

Cada suite vive en una transaccion que termina en `ROLLBACK`, asi que no dejan
datos.

| Archivo | Que comprueba |
|---|---|
| `01_ciclo_venta.sql` | Registro de cliente, compra con y sin oferta, precio congelado, stock, errores esperados |
| `02_catalogo_y_ofertas.sql` | Orden de la escalera, vigencia, el limite de dos ofertas por dia, coherencia de las ofertas |
| `04_seguridad.sql` | Que la clave publica no pueda tocar precios, stock, ofertas ni ventas, y que un cliente no vea lo de otro |

---

## 8. Estructura

```
supabase/
├── migrations/
│   ├── 0001_esquema.sql      tablas, RLS y permisos
│   ├── 0002_funciones.sql    vistas, escrituras validadas y Realtime
│   ├── 0003_semilla.sql      catalogo de demostracion
│   ├── 0004_autenticacion.sql   identidad del cliente y RLS personal
│   ├── 0005_almacenamiento.sql  bucket de imagenes y sus politicas
│   ├── 0006a_productos.sql      3 categorias, 4 marcas y 14 productos
│   ├── 0006b_escaleras.sql      las escaleras de ofertas
│   ├── 0006c_combos.sql         saca los combos de las escaleras sueltas
│   └── 0007_indices.sql         indices de las consultas mas frecuentes
├── tests/                    pruebas SQL + ejecutar.sh
├── docker-compose.yml        PostgreSQL local
└── README.md
```
