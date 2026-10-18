#!/bin/sh
set -eu
case "$HBOX_DATABASE_HOST:$HBOX_DATABASE_PASSWORD:$HBOX_OPTIONS_HOSTNAME" in *REEMPLAZAR*|*tudominio.cl*) echo 'Configurar variables reales' >&2; exit 1;; esac
# Unico modo aceptado: verify-full. Cualquier otro (verify-ca, require,
# prefer, allow, disable) no verifica el certificado del servidor, expone
# contrasena y datos a MITM, y aborta el arranque (fail-closed).
if [ "$HBOX_DATABASE_SSL_MODE" != verify-full ]; then
  echo "ERROR: DB_SSLMODE=$HBOX_DATABASE_SSL_MODE no es seguro; usa verify-full." >&2; exit 1
fi
# Valida el CA exacto que usara el binario, no asumir la ruta por defecto.
case "$HBOX_DATABASE_SSL_ROOT_CERT" in
  ''|none)
    echo "ERROR: HBOX_DATABASE_SSL_ROOT_CERT vacio: define la ruta del CA." >&2; exit 1
    ;;
  *)
    [ -s "$HBOX_DATABASE_SSL_ROOT_CERT" ] || { echo "CA no legible: $HBOX_DATABASE_SSL_ROOT_CERT" >&2; exit 1; }
    ;;
esac
exec /app/api /data/config.yml
