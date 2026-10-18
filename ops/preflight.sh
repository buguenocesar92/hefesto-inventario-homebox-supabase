#!/bin/sh
set -eu
case "$PGHOST:$PGPASSWORD" in *REEMPLAZAR*) echo 'Configurar base real' >&2; exit 1;; esac
# sslmode acepta los modos validos de libpq. Con disable (red interna Docker
# hacia un Postgres compartido) la CA no es obligatoria; libpq la ignora.
case "$PGSSLMODE" in
  disable|allow|prefer|require|verify-ca|verify-full) ;;
  *) echo "ERROR: PGSSLMODE=$PGSSLMODE no es un modo valido (disable|allow|prefer|require|verify-ca|verify-full)." >&2; exit 1 ;;
esac
# CA legible solo con verify-full; con disable/require/etc. libpq la ignora
# y exigirla bloquearia el preflight en red interna hacia Postgres compartido.
if [ "$PGSSLMODE" = verify-full ]; then
  [ -s "$PGSSLROOTCERT" ] || { echo "CA no legible: $PGSSLROOTCERT" >&2; exit 1; }
fi
psql --no-psqlrc -v ON_ERROR_STOP=1 -f /ops/preflight.sql
if [ "${BOOTSTRAP_MODE:-false}" != true ]; then
  psql --no-psqlrc -v ON_ERROR_STOP=1 -f /ops/production.sql
fi
