#!/usr/bin/env bash
# Aplica las migraciones sobre una base limpia y corre las pruebas SQL.
#
# Uso local (con el compose de supabase/docker-compose.yml levantado):
#
#     bash supabase/tests/ejecutar.sh
#
# Uso contra otra base (por ejemplo la de CI, o un Supabase autohospedado):
#
#     PGURL=postgresql://usuario:clave@host:5432/basedatos bash supabase/tests/ejecutar.sh
#
# Cada archivo de prueba corre dentro de una transaccion que termina en
# ROLLBACK, asi que no deja datos. Las secuencias si avanzan (Postgres no las
# revierte), y por eso la base se recrea al principio: 01_ciclo_venta.sql
# comprueba que el primer cliente reciba C0000001.

set -euo pipefail

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PGURL="${PGURL:-postgresql://postgres:postgres@localhost:55432/tienda}"

# psql local si existe; si no, el que vive dentro del contenedor.
if command -v psql >/dev/null 2>&1; then
  correr() { psql "$PGURL" -v ON_ERROR_STOP=1 -q -f "$1"; }
elif command -v podman >/dev/null 2>&1 || command -v docker >/dev/null 2>&1; then
  motor="$(command -v podman || command -v docker)"
  correr() {
    "$motor" exec -i tienda-pg psql -U postgres -d tienda -v ON_ERROR_STOP=1 -q < "$1"
  }
else
  echo "Hace falta psql, docker o podman." >&2
  exit 1
fi

echo "== Aplicando migraciones =="
for archivo in "$raiz"/supabase/migrations/*.sql; do
  echo "   $(basename "$archivo")"
  correr "$archivo"
done

echo "== Pruebas =="
correr "$raiz/supabase/tests/00_ayudas.sql"

# Cada archivo se ejecuta UNA sola vez: las secuencias de Postgres no vuelven
# atras con el ROLLBACK, y 01_ciclo_venta.sql afirma sobre el primer codigo
# que entregan. Correrlo dos veces en la misma pasada lo haria fallar solo.
fallos=0
for archivo in "$raiz"/supabase/tests/[0-9][0-9]_*.sql; do
  nombre="$(basename "$archivo")"
  [ "$nombre" = "00_ayudas.sql" ] && continue

  if salida="$(correr "$archivo" 2>&1)"; then
    echo "   PASA  $nombre"
  else
    echo "   FALLA $nombre"
    echo "$salida" | grep -E "FALLO|ERROR" | head -5 || true
    fallos=$((fallos + 1))
  fi
done

if [ "$fallos" -gt 0 ]; then
  echo "== $fallos archivo(s) con fallos =="
  exit 1
fi

echo "== Todas las pruebas SQL pasaron =="
