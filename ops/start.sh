#!/bin/sh
set -eu
case "$HBOX_DATABASE_HOST:$HBOX_DATABASE_PASSWORD:$HBOX_OPTIONS_HOSTNAME" in *REEMPLAZAR*|*tudominio.cl*) echo 'Configurar variables reales' >&2; exit 1;; esac
[ "$HBOX_DATABASE_SSL_MODE" = verify-full ]
[ -s /certs/ca.crt ]
exec /app/api /data/config.yml
