#!/usr/bin/env bash
# TDD: el chequeo de supabase-pg en scripts/coolify-check.sh debe limitarse
# a .services.app.environment, no a cualquier nodo del render (antes recorra
# dbtools y preflight, que tienen profiles y pueden mentir).
# Sale 0 si la consulta jq solo ve app y exige los valores correctos.
set -uo pipefail

fail=0

# Render fabricado: app tiene postgres/verify-full hardcodeados (no
# parametrizados), dbtools tiene los valores correctos con profiles.
# El chequeo anterior (con ..) pasaria leyendo dbtools; el nuevo (solo app)
# debe fallar.
JSON_APP_BAD='{
  "services": {
    "app": {
      "environment": {
        "HBOX_DATABASE_SSL_MODE": "verify-full",
        "HBOX_DATABASE_DATABASE": "postgres"
      }
    },
    "dbtools": {
      "profiles": ["tools"],
      "environment": {
        "HBOX_DATABASE_SSL_MODE": "disable",
        "HBOX_DATABASE_DATABASE": "mvp_prueba"
      }
    },
    "preflight": {
      "environment": {
        "PGSSLMODE": "disable",
        "PGDATABASE": "mvp_prueba"
      }
    }
  }
}'

# Render correcto: app tiene los valores esperados.
JSON_APP_OK='{
  "services": {
    "app": {
      "environment": {
        "HBOX_DATABASE_SSL_MODE": "disable",
        "HBOX_DATABASE_DATABASE": "mvp_prueba"
      }
    },
    "dbtools": {
      "profiles": ["tools"],
      "environment": {
        "HBOX_DATABASE_SSL_MODE": "verify-full",
        "HBOX_DATABASE_DATABASE": "postgres"
      }
    }
  }
}'

run_query_new() {
  local json="$1"
  jq -r '
    .services.app.environment
    | to_entries
    | map(select(.key | test("^HBOX_DATABASE_(DATABASE|SSL_MODE)$")))
    | map("\(.key)=\(.value)")
    | join(" ")
  ' <<<"$json"
}

run_query_old() {
  local json="$1"
  jq -r '
    [ .. | objects
      | to_entries[]
      | select((.key | test("^(HBOX_DATABASE_(DATABASE|USERNAME|SSL_MODE)|PGDATABASE|PGUSER|PGSSLMODE)$")))
    ]
    | map("\(.key)=\(.value|tostring)")
    | join(" ")
  ' <<<"$json"
}

# Demostracion del bug: con app incorrecto y dbtools correcto, la consulta
# VIEJA (con ..) encuentra disable+mvp_prueba y pasaria; la NUEVA (solo app)
# no los encuentra. Sin esto, el chequeo pasa aun cuando app no este
# parametrizado.
old=$(run_query_old "$JSON_APP_BAD")
new=$(run_query_new "$JSON_APP_BAD")
if echo "$old" | grep -q 'HBOX_DATABASE_SSL_MODE=disable' && \
   echo "$old" | grep -q 'HBOX_DATABASE_DATABASE=mvp_prueba'; then
  echo "OK-old: la consulta vieja (con ..) lee dbtools (bug demostrado)"
else
  echo "FAIL-old: la consulta vieja no encontro los valores en dbtools; el test no demuestra nada"
  fail=1
fi
if echo "$new" | grep -q 'HBOX_DATABASE_SSL_MODE=disable' && \
   echo "$new" | grep -q 'HBOX_DATABASE_DATABASE=mvp_prueba'; then
  echo "FAIL-new: la consulta nueva sigue leyendo dbtools; el fix no limita la busqueda a app"
  fail=1
else
  echo "OK-new: la consulta nueva solo ve app (no encuentra disable+mvp_prueba en app incorrecto)"
fi

# Caso 2 (verde esperado): app con valores correctos.
out=$(run_query_new "$JSON_APP_OK")
if echo "$out" | grep -q 'HBOX_DATABASE_SSL_MODE=disable' && \
   echo "$out" | grep -q 'HBOX_DATABASE_DATABASE=mvp_prueba'; then
  echo "PASS: el chequeo detecta disable+mvp_prueba en app correcto"
else
  echo "FAIL: el chequeo no encuentra los valores esperados en app correcto"
  echo "Salida: $out"
  fail=1
fi

# Adicional: la consulta nunca debe mencionar nodos fuera de app.environment.
if run_query_new "$JSON_APP_BAD" | grep -q 'dbtools\|preflight'; then
  echo "FAIL: la consulta nombra nodos fuera de app"
  fail=1
else
  echo "PASS: la consulta no nombra nodos fuera de app"
fi

exit "$fail"
