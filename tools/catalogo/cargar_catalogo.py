#!/usr/bin/env python3
"""Carga productos al catalogo desde un CSV.

Genera el SQL que hay que pegar en el SQL Editor de Supabase y, opcionalmente,
sube las imagenes al bucket `productos`.

    python tools/catalogo/cargar_catalogo.py                    # solo el SQL
    python tools/catalogo/cargar_catalogo.py --subir-imagenes   # tambien las fotos

El SQL sale partido en archivos de menos de 10 KB. No es un capricho: el SQL
Editor del panel trunca los scripts largos y devuelve "syntax error at end of
input" en LINE 0, que no dice nada de la causa. Costo cinco intentos
descubrirlo con la migracion 0006.

Por la misma razon el SQL generado evita `from (values ...) join`: es valido y
psql lo acepta, pero el parser del panel lo parte antes del join.

--------------------------------------------------------------------------
LAS CLAVES

Para subir imagenes hace falta la service_role key, que ignora todas las
politicas RLS. NO se guarda en el repositorio ni se pasa por argumento (queda
en el historial del shell). Se lee del entorno:

    PowerShell:  $env:SUPABASE_SERVICE_KEY = "eyJ..."
    Bash:        export SUPABASE_SERVICE_KEY="eyJ..."

La URL sale de env.json, que ya existe y esta en .gitignore.
--------------------------------------------------------------------------
"""

import argparse
import csv
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
CSV_POR_DEFECTO = Path(__file__).parent / 'productos.csv'
SALIDA = Path(__file__).parent / 'sql'
IMAGENES = RAIZ / 'assets' / 'products'

# El panel trunca por encima de ~15 KB; 10 KB deja margen de sobra.
LIMITE_BYTES = 10_000

TIPOS = {
    '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
    '.png': 'image/png', '.webp': 'image/webp',
}


def error(mensaje):
    print(f'ERROR: {mensaje}', file=sys.stderr)
    sys.exit(1)


def leer_credenciales():
    """URL del proyecto desde env.json; la clave de servicio desde el entorno."""
    env = RAIZ / 'env.json'
    if not env.exists():
        error('falta env.json en la raiz. Copialo de env.example.json.')

    datos = json.loads(env.read_text(encoding='utf-8'))
    url = datos.get('SUPABASE_URL', '').rstrip('/')
    if not url:
        error('env.json no tiene SUPABASE_URL.')
    return url


def escapar(texto):
    """Comilla simple para SQL. Las de dentro se doblan."""
    return "'" + str(texto).replace("'", "''") + "'"


def a_centavos(soles):
    """'219.00' -> 21900.

    Se hace con enteros a proposito: float('219.00') * 100 puede dar
    21899.999999999996, y un producto mal cargado por un centavo es el tipo de
    error que nadie mira hasta que cuadra la caja.
    """
    texto = str(soles).strip().replace(',', '.')
    if '.' not in texto:
        return int(texto) * 100
    entero, decimal = texto.split('.', 1)
    decimal = (decimal + '00')[:2]
    return int(entero) * 100 + int(decimal)


def validar(filas):
    """Comprueba el CSV entero antes de generar nada.

    Mejor 20 errores juntos que descubrirlos de uno en uno al pegar el SQL.
    """
    problemas = []
    vistos = set()

    for n, f in enumerate(filas, start=2):  # la 1 es la cabecera
        nombre = f['nombre'].strip()
        if not nombre:
            problemas.append(f'fila {n}: falta el nombre')
            continue
        if nombre in vistos:
            problemas.append(f'fila {n}: "{nombre}" esta repetido en el CSV')
        vistos.add(nombre)

        if not f['categoria'].strip():
            problemas.append(f'fila {n} ({nombre}): falta la categoria')
        if not f['marca'].strip():
            problemas.append(f'fila {n} ({nombre}): falta la marca')

        try:
            centavos = a_centavos(f['precio_soles'])
            if centavos <= 0:
                problemas.append(f'fila {n} ({nombre}): el precio debe ser mayor que cero')
        except (ValueError, AttributeError):
            problemas.append(f'fila {n} ({nombre}): precio invalido "{f["precio_soles"]}"')

        try:
            if int(f['stock']) < 0:
                problemas.append(f'fila {n} ({nombre}): el stock no puede ser negativo')
        except ValueError:
            problemas.append(f'fila {n} ({nombre}): stock invalido "{f["stock"]}"')

        escalera = [e for e in f.get('escalera', '').split('|') if e.strip()]
        anterior = 0
        for pct in escalera:
            try:
                v = int(pct)
            except ValueError:
                problemas.append(f'fila {n} ({nombre}): descuento invalido "{pct}"')
                continue
            if not 1 <= v <= 90:
                # El tope de 90 lo impone la base: un 100% regala el producto.
                problemas.append(f'fila {n} ({nombre}): el descuento {v} esta fuera de 1..90')
            if v <= anterior:
                # Avanzar de escalon tiene que mejorar la oferta, o el cliente
                # ve como le suben el precio al poner mala cara.
                problemas.append(
                    f'fila {n} ({nombre}): la escalera no crece ({anterior} -> {v})')
            anterior = v

        imagen = f.get('imagen', '').strip()
        if imagen and not (IMAGENES / imagen).exists():
            problemas.append(f'fila {n} ({nombre}): no existe assets/products/{imagen}')

    return problemas


def sql_comprobar_referencias(filas):
    """Sentencia que falla si el CSV nombra una categoria o marca inexistente.

    Sin esto, la subconsulta que busca la categoria devuelve null cuando no
    existe, y el insert se salta la fila en silencio: el producto no aparece y
    nadie sabe por que. Mejor que la primera sentencia del script reviente con
    un mensaje que diga cual falta.
    """
    cats = sorted({f['categoria'].strip() for f in filas})
    marcas = sorted({f['marca'].strip() for f in filas})
    lista_cats = ', '.join(escapar(c) for c in cats)
    lista_marcas = ', '.join(escapar(m) for m in marcas)

    lineas = [
        'do $comprobar$',
        'declare',
        '  v_falta text;',
        'begin',
        "  select string_agg(x, ', ') into v_falta",
        f'    from unnest(array[{lista_cats}]) x',
        '   where x not in (select nombre from categorias);',
        '  if v_falta is not null then',
        "    raise exception 'Faltan estas categorias: %', v_falta",
        "      using hint = 'crealas antes de cargar los productos';",
        '  end if;',
        '',
        "  select string_agg(x, ', ') into v_falta",
        f'    from unnest(array[{lista_marcas}]) x',
        '   where x not in (select nombre from marcas);',
        '  if v_falta is not null then',
        "    raise exception 'Faltan estas marcas: %', v_falta",
        "      using hint = 'crealas antes de cargar los productos';",
        '  end if;',
        'end',
        '$comprobar$;',
    ]
    return '\n'.join(lineas) + '\n'


def sql_producto(f):
    nombre = escapar(f['nombre'].strip())
    return (
        'insert into productos (id_categoria, id_marca, nombre, descripcion,\n'
        '                       precio_centavos, stock)\n'
        f'select (select id_categoria from categorias where nombre={escapar(f["categoria"].strip())}),\n'
        f'       (select id_marca from marcas where nombre={escapar(f["marca"].strip())}),\n'
        f'       {nombre}, {escapar(f.get("descripcion", "").strip())},\n'
        f'       {a_centavos(f["precio_soles"])}, {int(f["stock"])}\n'
        f' where not exists (select 1 from productos where nombre={nombre});\n'
    )


def sql_escalon(nombre_producto, pct, orden):
    nombre = escapar(nombre_producto)
    return (
        'insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)\n'
        f"select (select id_oferta from ofertas where nombre='Descuento {pct}%'),\n"
        f'       (select id_producto from productos where nombre={nombre}), {orden}, 1\n'
        f' where not exists (select 1 from ofertas_productos where orden={orden}\n'
        f'   and id_producto=(select id_producto from productos where nombre={nombre}));\n'
    )


def sql_imagen(nombre_producto, archivo):
    nombre = escapar(nombre_producto)
    return (
        f'update productos set imagen = fn_url_imagen({escapar(archivo)})\n'
        f' where nombre={nombre};\n'
    )


def sql_ofertas_que_faltan(filas):
    """Crea las ofertas de descuento que el CSV usa y aun no existen.

    La semilla trae 10%, 20% y 30%. Si alguien pone 15 en el CSV, la oferta no
    existe y el insert del escalon no encontraria nada que insertar --sin
    fallar, que es peor: el producto se quedaria sin ese escalon y nadie se
    enteraria.
    """
    usados = set()
    for f in filas:
        for pct in f.get('escalera', '').split('|'):
            if pct.strip():
                usados.add(int(pct))

    lineas = []
    for pct in sorted(usados):
        lineas.append(
            'insert into ofertas (id_admin, nombre, id_tipo, porcentaje_descuento,\n'
            '                     fecha_inicio, fecha_fin)\n'
            'select (select min(id_admin) from administradores),\n'
            f"       'Descuento {pct}%',\n"
            "       (select id_tipo from tipos_oferta where nombre='Descuento'),\n"
            f'       {pct}, now(), now() + interval \'1 year\'\n'
            f" where not exists (select 1 from ofertas where nombre='Descuento {pct}%');\n"
        )
    return lineas


def escribir_por_partes(nombre_base, cabecera, sentencias):
    """Parte las sentencias en archivos por debajo del limite del panel."""
    SALIDA.mkdir(exist_ok=True)
    archivos, actual, tam, parte = [], [cabecera], len(cabecera), 1

    for s in sentencias:
        bloque = s + '\n'
        if tam + len(bloque) > LIMITE_BYTES and len(actual) > 1:
            ruta = SALIDA / f'{nombre_base}_{parte}.sql'
            ruta.write_text(''.join(actual), encoding='utf-8')
            archivos.append(ruta)
            parte += 1
            actual, tam = [cabecera], len(cabecera)
        actual.append(bloque)
        tam += len(bloque)

    if len(actual) > 1:
        ruta = SALIDA / f'{nombre_base}_{parte}.sql'
        ruta.write_text(''.join(actual), encoding='utf-8')
        archivos.append(ruta)
    return archivos


def subir_imagenes(filas, url):
    """Sube al bucket `productos` las imagenes que el CSV nombra."""
    clave = os.environ.get('SUPABASE_SERVICE_KEY', '').strip()
    if not clave:
        error(
            'falta SUPABASE_SERVICE_KEY en el entorno.\n'
            '  PowerShell:  $env:SUPABASE_SERVICE_KEY = "eyJ..."\n'
            '  Bash:        export SUPABASE_SERVICE_KEY="eyJ..."\n'
            '\n'
            '  Esta en Project Settings -> API -> service_role. Es la clave que\n'
            '  ignora las politicas RLS: no la pongas en env.json ni en el codigo.'
        )

    subidas, fallos = 0, 0
    for f in filas:
        archivo = f.get('imagen', '').strip()
        if not archivo:
            continue

        origen = IMAGENES / archivo
        tipo = TIPOS.get(origen.suffix.lower())
        if tipo is None:
            print(f'  OMITIDA  {archivo} (extension no soportada)')
            fallos += 1
            continue

        destino = f'{url}/storage/v1/object/productos/{archivo}'
        peticion = urllib.request.Request(
            destino,
            data=origen.read_bytes(),
            method='POST',
            headers={
                'Authorization': f'Bearer {clave}',
                'Content-Type': tipo,
                # Reemplaza si ya existe, para poder corregir una foto sin
                # borrarla antes a mano.
                'x-upsert': 'true',
            },
        )
        try:
            with urllib.request.urlopen(peticion, timeout=60):
                print(f'  subida   {archivo}  ({origen.stat().st_size // 1024} KB)')
                subidas += 1
        except urllib.error.HTTPError as e:
            detalle = e.read().decode('utf-8', 'replace')[:200]
            print(f'  FALLO    {archivo}: {e.code} {detalle}')
            fallos += 1
        except urllib.error.URLError as e:
            print(f'  FALLO    {archivo}: {e.reason}')
            fallos += 1

    return subidas, fallos


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--csv', type=Path, default=CSV_POR_DEFECTO,
                   help='CSV de entrada (por defecto tools/catalogo/productos.csv)')
    p.add_argument('--subir-imagenes', action='store_true',
                   help='sube al bucket las imagenes que nombra el CSV')
    args = p.parse_args()

    if not args.csv.exists():
        error(f'no existe {args.csv}')

    with args.csv.open(encoding='utf-8-sig', newline='') as fh:
        filas = [f for f in csv.DictReader(fh) if f.get('nombre', '').strip()]

    if not filas:
        error('el CSV no tiene filas con nombre')

    print(f'Leidas {len(filas)} filas de {args.csv.name}\n')

    problemas = validar(filas)
    if problemas:
        print(f'El CSV tiene {len(problemas)} problemas:\n')
        for x in problemas:
            print(f'  - {x}')
        sys.exit(1)
    print('CSV valido.\n')

    url = leer_credenciales()

    if args.subir_imagenes:
        con_imagen = [f for f in filas if f.get('imagen', '').strip()]
        if con_imagen:
            print(f'Subiendo {len(con_imagen)} imagenes al bucket productos:')
            subidas, fallos = subir_imagenes(filas, url)
            print(f'\n  {subidas} subidas, {fallos} con fallo\n')
            if fallos:
                print('  Las que fallaron no tendran foto: revisa el error y\n'
                      '  vuelve a lanzar el script.\n')
        else:
            print('Ninguna fila tiene imagen: no hay nada que subir.\n')

    # --- SQL ---------------------------------------------------------------
    cab = ('-- Generado por tools/catalogo/cargar_catalogo.py\n'
           '-- Pegar en el SQL Editor de Supabase, en orden.\n'
           '-- Todo es idempotente: aplicarlo dos veces no duplica nada.\n\n')

    ofertas = sql_ofertas_que_faltan(filas)
    # La comprobacion va al principio del primer archivo: si falta una
    # categoria, el script entero se detiene ahi en vez de insertar a medias.
    productos = [sql_comprobar_referencias(filas)] + [sql_producto(f) for f in filas]

    escalones = []
    for f in filas:
        pcts = [int(x) for x in f.get('escalera', '').split('|') if x.strip()]
        for orden, pct in enumerate(pcts, start=1):
            escalones.append(sql_escalon(f['nombre'].strip(), pct, orden))

    imagenes = [sql_imagen(f['nombre'].strip(), f['imagen'].strip())
                for f in filas if f.get('imagen', '').strip()]

    generados = []
    if ofertas:
        generados += escribir_por_partes('1_ofertas', cab, ofertas)
    generados += escribir_por_partes('2_productos', cab, productos)
    if escalones:
        generados += escribir_por_partes('3_escaleras', cab, escalones)
    if imagenes:
        generados += escribir_por_partes('4_imagenes', cab, imagenes)

    print('SQL generado en tools/catalogo/sql/ -- pegar en este orden:\n')
    for r in generados:
        print(f'  {r.name:24} {r.stat().st_size:6} bytes')

    # len(filas), no len(productos): esa lista lleva ademas la sentencia de
    # comprobacion de categorias y marcas.
    print(f'\n{len(filas)} productos, {len(escalones)} escalones, '
          f'{len(imagenes)} imagenes.')
    print('\nDespues de pegarlo, comprobar en el SQL Editor:')
    print('  select count(*) from productos;')


if __name__ == '__main__':
    main()
