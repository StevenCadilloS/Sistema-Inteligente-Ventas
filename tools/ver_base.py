"""Extrae la base de datos del celular y muestra su contenido.

La base vive en el almacenamiento privado de la app, asi que no se puede
copiar con el explorador de archivos: se saca con `adb run-as`, que solo
funciona porque la build es debug.

Uso (con el celular conectado y depuracion USB activa):
    python tools/ver_base.py            # resumen de todas las tablas
    python tools/ver_base.py ventas     # vuelca una tabla completa
    python tools/ver_base.py esquema    # los CREATE TABLE tal cual estan

Sin celular, sobre la evidencia guardada en el repo (ver EVIDENCIA):
    python tools/ver_base.py --evidencia
    python tools/ver_base.py --evidencia ventas

Ojo: `run-as` solo funciona con la build de depuracion. El APK que publica
GitHub Actions es `--release` y no deja leer la base; para eso esta --evidencia.
"""
import os
import sqlite3
import subprocess
import sys

PAQUETE = "com.tuapp.tienda_adaptativa"
REMOTO = "app_flutter/tienda_adaptativa.sqlite"
LOCAL = os.path.join(os.path.dirname(__file__), "base_extraida.sqlite")

# Instantanea real tomada de un celular tras una sesion de uso. Es la evidencia
# de adaptacion del informe (seccion 5): sobrevive a desinstalar la app.
EVIDENCIA = os.path.join(os.path.dirname(__file__), "base_evidencia_2026-09-08.sqlite")

TABLAS = [
    "clientes",
    "productos",
    "estrategias",
    "gestos",
    "interacciones",
    "ventas",
    "detalle_venta",
]


def extraer():
    """Copia la base del celular al disco local."""
    with open(LOCAL, "wb") as destino:
        proceso = subprocess.run(
            ["adb", "exec-out", "run-as", PAQUETE, "cat", REMOTO],
            stdout=destino,
            stderr=subprocess.PIPE,
        )
    if proceso.returncode != 0 or os.path.getsize(LOCAL) == 0:
        error = proceso.stderr.decode(errors="ignore").strip()
        sys.exit(f"No se pudo extraer la base. ¿Celular conectado?\n{error}")
    print(f"Base extraida: {os.path.getsize(LOCAL) / 1024:.0f} KB\n")


def resumen(con):
    print(f"{'TABLA':<16} FILAS")
    print("-" * 24)
    for tabla in TABLAS:
        try:
            filas = con.execute(f"SELECT COUNT(*) FROM {tabla}").fetchone()[0]
            print(f"{tabla:<16} {filas}")
        except sqlite3.Error:
            print(f"{tabla:<16} (no existe)")

    print("\nULTIMAS INTERACCIONES (emocion -> producto -> estrategia)")
    print("-" * 70)
    consulta = """
        SELECT i.id_proceso_persuasion, g.nombre_gesto, p.nombre_producto,
               e.nombre_estrategia, i.nivel_de_interes,
               (SELECT COUNT(*) FROM ventas v
                 WHERE v.id_proceso_persuasion = i.id_proceso_persuasion)
        FROM interacciones i
        LEFT JOIN gestos g ON g.cod_gesto = i.cod_gesto
        LEFT JOIN productos p ON p.cod_lote_producto = i.cod_lote_producto
        LEFT JOIN estrategias e ON e.cod_estrategia = i.cod_estrategia
        ORDER BY i.timestamp DESC LIMIT 12
    """
    for proc, gesto, prod, estr, interes, vendido in con.execute(consulta):
        cierre = "VENDIDO" if vendido else "rechazado"
        print(f"{proc}  {gesto or '-':<9} {(prod or '-')[:24]:<24} "
              f"{(estr or 'sin estrategia')[:20]:<20} {interes:>3}%  {cierre}")

    print("\nVENTAS (lo cobrado vs el precio de lista)")
    print("-" * 70)
    consulta = """
        SELECT p.nombre_producto, d.precio_unitario_centavos,
               p.precio_unitario_centavos
        FROM ventas v
        JOIN detalle_venta d ON d.venta_id = v.id
        JOIN productos p ON p.cod_lote_producto = d.cod_lote_producto
        ORDER BY v.timestamp DESC LIMIT 12
    """
    for nombre, cobrado, lista in con.execute(consulta):
        descuento = round(100 * (1 - cobrado / lista)) if lista else 0
        marca = f"  (-{descuento}%)" if descuento else ""
        print(f"{nombre[:28]:<28} S/{cobrado / 100:>8.2f}"
              f"   lista S/{lista / 100:>8.2f}{marca}")


def esquema(con):
    """Muestra el DDL real: como quedaron creadas las tablas en el celular.

    Es la fuente de verdad, no la declaracion de Dart: drift genera este SQL a
    partir de `lib/data/database/tables.dart` y es lo que SQLite ejecuto.
    """
    consulta = """
        SELECT type, name, sql FROM sqlite_master
        WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%'
        ORDER BY CASE type WHEN 'table' THEN 0 ELSE 1 END, name
    """
    for tipo, nombre, sql in con.execute(consulta):
        print(f"-- {tipo}: {nombre}")
        print(sql.strip() + ";")
        print()

    # Ojo: no se consulta `PRAGMA foreign_keys` aqui porque es por conexion,
    # y esta es la de lectura, no la de la app. Las FK se ven declaradas
    # arriba (REFERENCES) y AppDatabase las activa al abrir cada conexion.


def volcar(con, tabla):
    columnas = [c[1] for c in con.execute(f"PRAGMA table_info({tabla})")]
    if not columnas:
        sys.exit(f"La tabla '{tabla}' no existe.")
    print(" | ".join(columnas))
    print("-" * 70)
    for fila in con.execute(f"SELECT * FROM {tabla}"):
        print(" | ".join(str(v) for v in fila))


def main():
    argumentos = sys.argv[1:]

    if "--evidencia" in argumentos:
        argumentos.remove("--evidencia")
        if not os.path.exists(EVIDENCIA):
            sys.exit(f"No existe {EVIDENCIA}")
        base = EVIDENCIA
        tam = os.path.getsize(base) / 1024
        print(f"Leyendo la evidencia guardada ({tam:.0f} KB)")
        print()
    else:
        extraer()
        base = LOCAL

    con = sqlite3.connect(base)
    try:
        if argumentos and argumentos[0] == "esquema":
            esquema(con)
        elif argumentos:
            volcar(con, argumentos[0])
        else:
            resumen(con)
    finally:
        con.close()


if __name__ == "__main__":
    main()
