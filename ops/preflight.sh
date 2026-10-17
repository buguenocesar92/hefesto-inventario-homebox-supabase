#!/bin/sh
set -eu
case "$PGHOST:$PGPASSWORD" in *REEMPLAZAR*) echo 'Configurar base real' >&2; exit 1;; esac
psql --no-psqlrc -v ON_ERROR_STOP=1 -f /ops/preflight.sql
if [ "${BOOTSTRAP_MODE:-false}" != true ]; then
  psql --no-psqlrc -v ON_ERROR_STOP=1 -f /ops/production.sql
fi
