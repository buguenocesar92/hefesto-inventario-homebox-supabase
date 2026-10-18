#!/bin/sh
set -eu
case "$PGHOST:$PGPASSWORD" in *REEMPLAZAR*) echo 'Configurar base real' >&2; exit 1;; esac
# Fail-closed en TLS BD: cualquier modo que no verifique el certificado
# del servidor expone contrasena y datos a MITM y aborta el preflight.
if [ "$PGSSLMODE" != verify-full ]; then
  echo "ERROR: PGSSLMODE=$PGSSLMODE no es seguro; usa verify-full." >&2; exit 1
fi
[ -s "$PGSSLROOTCERT" ] || { echo "CA no legible: $PGSSLROOTCERT" >&2; exit 1; }
psql --no-psqlrc -v ON_ERROR_STOP=1 -f /ops/preflight.sql
if [ "${BOOTSTRAP_MODE:-false}" != true ]; then
  psql --no-psqlrc -v ON_ERROR_STOP=1 -f /ops/production.sql
fi
