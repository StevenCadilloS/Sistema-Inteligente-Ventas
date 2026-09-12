# Cargar productos al catalogo

Un CSV con los productos, un script que genera el SQL, y opcionalmente la
subida de las fotos al bucket de Storage.

```bash
# 1. Editar tools/catalogo/productos.csv
# 2. Generar el SQL
python tools/catalogo/cargar_catalogo.py

# 3. Pegar en el SQL Editor los archivos de tools/catalogo/sql/, en orden
```

---

## El CSV

| Columna | Obligatoria | Ejemplo | Nota |
|---|---|---|---|
| `nombre` | si | `Teclado Mecanico RGB` | Es la clave: dos productos no pueden llamarse igual |
| `categoria` | si | `Accesorios` | Tiene que existir ya en la tabla `categorias` |
| `marca` | si | `TecnoPlus` | Tiene que existir ya en `marcas` |
| `descripcion` | no | `Switches azules` | |
| `precio_soles` | si | `219.00` | **En soles**, no en centavos: el script convierte |
| `stock` | si | `12` | |
| `imagen` | no | `teclado.jpg` | Archivo de `assets/products/` |
| `escalera` | no | `10\|20\|30` | Porcentajes separados por `\|`, de menor a mayor |

Las categorias y marcas existentes se consultan con:

```sql
select nombre from categorias order by nombre;
select nombre from marcas order by nombre;
```

Para anadir una nueva, antes de cargar los productos:

```sql
insert into categorias (nombre) values ('Deportes') on conflict (nombre) do nothing;
insert into marcas (nombre) values ('MarcaNueva') on conflict (nombre) do nothing;
```

### La escalera

`10|20|30` significa que el producto negocia en tres escalones: primero 10%,
luego 20%, luego 30%. La columna vacia deja el producto **sin escalera**: se
queda siempre en su precio normal, pase lo que pase con la emocion del cliente
(regla 8 del README).

El script comprueba que la escalera **crezca**. Si pones `30|10`, falla: avanzar
de escalon tiene que mejorar la oferta, o el cliente ve como le suben el precio
al poner mala cara.

Si usas un porcentaje que no existe todavia como oferta (por ejemplo 15), el
script genera tambien el `insert` que lo crea.

---

## Las imagenes

Las fotos **no se guardan en la base**: en `productos.imagen` va solo una URL.
Los archivos viven en el bucket `productos` de Supabase Storage.

### Opcion A: que las suba el script

```powershell
# PowerShell
$env:SUPABASE_SERVICE_KEY = "eyJ..."
python tools/catalogo/cargar_catalogo.py --subir-imagenes
```

```bash
# Bash
export SUPABASE_SERVICE_KEY="eyJ..."
python tools/catalogo/cargar_catalogo.py --subir-imagenes
```

La clave esta en **Project Settings -> API -> service_role**.

> La `service_role` key **ignora todas las politicas RLS**: puede leer y
> escribir cualquier tabla sin restriccion. Por eso el script la lee del
> entorno y no de un archivo — para que no acabe en un commit por descuido.
> No la pongas en `env.json`, que es para la clave publica.
>
> La variable de entorno dura lo que la ventana de terminal. Si cierras
> PowerShell, hay que volver a definirla.

### Opcion B: subirlas a mano

**Storage -> productos -> Upload file**, y despues asignarlas:

```sql
update productos set imagen = fn_url_imagen('teclado.jpg')
 where nombre = 'Teclado Mecanico RGB';
```

`fn_url_imagen` arma la URL publica completa a partir del nombre del archivo.
Tambien acepta una URL entera, por si la foto esta alojada fuera.

### Formatos

`.jpg`, `.jpeg`, `.png` y `.webp`. Conviene que no pasen de ~200 KB: viajan a
cada dispositivo que abra la tienda.

---

## Por que el SQL sale partido

El SQL Editor del panel **trunca los scripts largos** y devuelve
`syntax error at end of input` en `LINE 0`, que no dice nada de la causa.
Costo cinco intentos descubrirlo con la migracion 0006.

El script parte la salida en archivos de menos de 10 KB y los numera en el
orden en que hay que pegarlos:

```
1_ofertas_N.sql     las ofertas de descuento que falten
2_productos_N.sql   los productos
3_escaleras_N.sql   que oferta corresponde a cada producto y en que orden
4_imagenes_N.sql    asigna las URLs (solo si el CSV trae imagenes)
```

El orden importa: un escalon no se puede crear antes que su producto.

Por la misma razon el SQL generado evita `from (values ...) join`: es valido y
psql lo acepta, pero el parser del panel lo parte antes del join.

---

## Todo es idempotente

Cada `insert` lleva su `where not exists`. Pegar el mismo SQL dos veces no
duplica nada — comprobado aplicandolo tres veces seguidas.

Eso permite corregir el CSV y volver a generar sin limpiar nada antes.

---

## Lo que el script comprueba antes de generar

Informa de **todos** los problemas juntos, no del primero:

- Nombres vacios o repetidos dentro del CSV
- Categoria o marca sin rellenar
- Precios no numericos o menores o iguales a cero
- Stock negativo
- Descuentos fuera de 1..90 (el tope lo impone la base: un 100% regala el producto)
- Escaleras que no crecen
- Imagenes que el CSV nombra y no estan en `assets/products/`

Lo que **no** comprueba, porque hace falta la base para saberlo: que la
categoria y la marca existan de verdad. Si no existen, el `insert` no falla —
simplemente no inserta la fila, porque la subconsulta devuelve null. Por eso
conviene contar los productos despues:

```sql
select count(*) from productos;
```
