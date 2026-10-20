#!/usr/bin/env bash
# TDD: ops/start.sh y ops/preflight.sh deben aceptar DB_SSLMODE=disable
# sin abortar. Solo con DB_SSLMODE=verify-full se exige CA legible.
# Sale 0 si acepta modos no verify-full (sin abortar por sslmode) y mantiene
# la exigencia de CA con verify-full.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail=0

run_with_env() {
  local script="$1"
  shift
  env -i HOME="$HOME" PATH="$PATH" "$@" sh "$ROOT/$script" 2>&1
}

check_no_sslmode_abort() {
  local label="$1" script="$2" mode="$3"
  shift 3
  local out rc
  out=$(run_with_env "$script" "$@") && rc=0 || rc=$?
  if echo "$out" | grep -qE '(no es seguro; usa verify-full|Fail-closed en TLS BD)'; then
    echo "FAIL: $label con sslmode=$mode aborta por sslmode"
    echo "--- salida ---"
    echo "$out"
    echo "---"
    fail=1
  else
    echo "PASS: $label con sslmode=$mode no aborta por sslmode"
  fi
}

check_ca_required() {
  local label="$1" script="$2" mode="$3"
  shift 3
  local out rc
  out=$(run_with_env "$script" "$@") && rc=0 || rc=$?
  if echo "$out" | grep -qE 'CA no legible'; then
    echo "PASS: $label con sslmode=$mode exige CA legible"
  else
    echo "FAIL: $label con sslmode=$mode NO exige CA legible"
    echo "--- salida ---"
    echo "$out"
    echo "---"
    fail=1
  fi
}

check_ca_not_required() {
  local label="$1" script="$2" mode="$3"
  shift 3
  local out rc
  out=$(run_with_env "$script" "$@") && rc=0 || rc=$?
  if echo "$out" | grep -qE 'CA no legible'; then
    echo "FAIL: $label con sslmode=$mode exige CA (no deberia)"
    echo "--- salida ---"
    echo "$out"
    echo "---"
    fail=1
  else
    echo "PASS: $label con sslmode=$mode no exige CA"
  fi
}

START_BASE=(
  "HBOX_DATABASE_HOST=db.example.invalid"
  "HBOX_DATABASE_PASSWORD=x1234567890abcdef"
  "HBOX_OPTIONS_HOSTNAME=https://ejemplo.invalid"
)
PRE_BASE=(
  "PGHOST=db.example.invalid"
  "PGPASSWORD=x1234567890abcdef"
)

# Caso 1: disable debe pasar el chequeo de sslmode
check_no_sslmode_abort "ops/start.sh" "ops/start.sh" "disable" \
  "${START_BASE[@]}" HBOX_DATABASE_SSL_MODE=disable HBOX_DATABASE_SSL_ROOT_CERT=/nonexistent
check_no_sslmode_abort "ops/preflight.sh" "ops/preflight.sh" "disable" \
  "${PRE_BASE[@]}" PGSSLMODE=disable PGSSLROOTCERT=/nonexistent

# Caso 2: require debe pasar el chequeo de sslmode
check_no_sslmode_abort "ops/start.sh" "ops/start.sh" "require" \
  "${START_BASE[@]}" HBOX_DATABASE_SSL_MODE=require HBOX_DATABASE_SSL_ROOT_CERT=/nonexistent
check_no_sslmode_abort "ops/preflight.sh" "ops/preflight.sh" "require" \
  "${PRE_BASE[@]}" PGSSLMODE=require PGSSLROOTCERT=/nonexistent

# Caso 3: verify-full debe exigir CA legible
check_ca_required "ops/start.sh" "ops/start.sh" "verify-full" \
  "${START_BASE[@]}" HBOX_DATABASE_SSL_MODE=verify-full HBOX_DATABASE_SSL_ROOT_CERT=/nonexistent
check_ca_required "ops/preflight.sh" "ops/preflight.sh" "verify-full" \
  "${PRE_BASE[@]}" PGSSLMODE=verify-full PGSSLROOTCERT=/nonexistent

# Caso 4: disable no debe exigir CA legible
check_ca_not_required "ops/start.sh" "ops/start.sh" "disable" \
  "${START_BASE[@]}" HBOX_DATABASE_SSL_MODE=disable HBOX_DATABASE_SSL_ROOT_CERT=/nonexistent
check_ca_not_required "ops/preflight.sh" "ops/preflight.sh" "disable" \
  "${PRE_BASE[@]}" PGSSLMODE=disable PGSSLROOTCERT=/nonexistent

exit "$fail"
