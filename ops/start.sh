#!/bin/sh
set -eu
case "$HBOX_DATABASE_HOST:$HBOX_DATABASE_PASSWORD:$HBOX_OPTIONS_HOSTNAME" in *REEMPLAZAR*|*tudominio.cl*) echo 'Configurar variables reales' >&2; exit 1;; esac
# sslmode acepta los modos validos de libpq. Con disable (red interna Docker
# hacia un Postgres compartido) la CA no es obligatoria; libpq la ignora.
case "$HBOX_DATABASE_SSL_MODE" in
  disable|allow|prefer|require|verify-ca|verify-full) ;;
  *) echo "ERROR: DB_SSLMODE=$HBOX_DATABASE_SSL_MODE no es un modo valido (disable|allow|prefer|require|verify-ca|verify-full)." >&2; exit 1 ;;
esac
# Valida el CA exacto que usara el binario solo con verify-full; sin verify-full
# libpq/pgx lo ignoran y exigirlo bloquearia el arranque en red interna.
if [ "$HBOX_DATABASE_SSL_MODE" = verify-full ]; then
  case "$HBOX_DATABASE_SSL_ROOT_CERT" in
    ''|none)
      echo "ERROR: HBOX_DATABASE_SSL_ROOT_CERT vacio: define la ruta del CA." >&2; exit 1
      ;;
    *)
      [ -s "$HBOX_DATABASE_SSL_ROOT_CERT" ] || { echo "CA no legible: $HBOX_DATABASE_SSL_ROOT_CERT" >&2; exit 1; }
      ;;
  esac
fi
exec /app/api /data/config.yml
