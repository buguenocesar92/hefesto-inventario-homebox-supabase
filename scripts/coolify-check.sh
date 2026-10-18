#!/usr/bin/env bash
# Test de aceptacion del contrato Coolify para los compose de este repo.
# Sale 0 si cumplen; cualquier otra salida imprime "FALLO: servicio: motivo".
# Por cada compose del contrato:
#   1. Genera un .env temporal con un valor ficticio no secreto por cada ${VAR}
#      que aparezca en el compose (URLs y hosts usan https://ejemplo.invalid).
#      Para supabase-pg fuerza DB_SSLMODE=disable y DB_NAME=mvp_prueba.
#   2. Renderiza con `docker compose --project-directory <base_dir> -f <compose>
#      --env-file <tmp> config --format json`.
#   3. Con jq verifica los puntos 1 y 2 del contrato (seguridad + nombres) y,
#      para supabase-pg, que mvp_prueba y disable aparezcan renderizados.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Compose del contrato de este repo. La base es la raiz del repo.
COMPOSE_FILES=("compose.yaml")
# Tipo de base de datos del compose: supabase-pg (parametrizable).
COMPOSE_BD="supabase-pg"

fail() { echo "FALLO: $1" >&2; exit 1; }

gen_env() {
  local compose="$1"
  local envfile="$2"
  : > "$envfile"

  local vars
  vars=$(grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*(:[-+?][^}]*)?\}' "$compose" \
    | sed -E 's/^\$\{([A-Za-z_][A-Za-z0-9_]*).*/\1/' \
    | sort -u)

  for v in $vars; do
    local val="x1234567890abcdef"
    case "$v" in
      APP_URL|DB_HOST) val="https://ejemplo.invalid" ;;
      DB_SSLMODE) val="disable" ;;
      DB_NAME) val="mvp_prueba" ;;
    esac
    printf '%s=%s\n' "$v" "$val" >> "$envfile"
  done
}

render_compose() {
  local compose="$1" envfile="$2" out="$3"
  docker compose --project-directory "$ROOT" -f "$compose" --env-file "$envfile" \
    config --format json > "$out" 2>"$out.stderr" \
    || { echo "--- stderr ---" >&2; cat "$out.stderr" >&2; fail "$compose: docker compose config fallo"; }
}

check_root_names() {
  # docker compose siempre inyecta `name:` automatico para el proyecto,
  # las networks y los volumes basandose en el directorio; eso aparece
  # en el JSON rendered aunque no este declarado. El contrato prohibe
  # declararlo en el archivo, asi que el chequeo va sobre el YAML fuente.
  local compose="$1"
  if grep -qE '^name:[[:space:]]*[^[:space:]#]+' "$compose"; then
    fail "compose: name raiz fijo declarado en el archivo (Coolify pone el nombre de proyecto)"
  fi
  # Buscar un `name:` declarado bajo el bloque `networks:` de nivel raiz.
  if awk '
    BEGIN{net=0;depth=0}
    /^networks:[[:space:]]*$/ {net=1; depth=1; next}
    net && /^services:[[:space:]]*$/ {net=0}
    net && /^volumes:[[:space:]]*$/ {net=0}
    net && /^[[:space:]]+name:[[:space:]]*[^[:space:]#]+/ {print; exit 1}
  ' "$compose" | grep -q .; then
    fail "compose: network con 'name:' fijo declarado en el archivo"
  fi
  # Buscar un `name:` declarado bajo el bloque `volumes:` de nivel raiz.
  if awk '
    BEGIN{vol=0}
    /^volumes:[[:space:]]*$/ {vol=1; next}
    vol && /^services:[[:space:]]*$/ {vol=0}
    vol && /^networks:[[:space:]]*$/ {vol=0}
    vol && /^[[:space:]]+name:[[:space:]]*[^[:space:]#]+/ {print; exit 1}
  ' "$compose" | grep -q .; then
    fail "compose: volume con 'name:' fijo declarado en el archivo"
  fi
}

check_services_safety() {
  local rendered="$1"
  local rows count i svc body
  rows=$(jq -c '
    [ .services
      | to_entries[]
      | select((.value.profiles // []) | length == 0)
      | {name: .key, body: .value}
    ]' "$rendered")
  count=$(echo "$rows" | jq 'length')
  for i in $(seq 0 $((count - 1))); do
    svc=$(echo "$rows" | jq -r ".[$i].name")
    body=$(echo "$rows" | jq -c ".[$i].body")

    if echo "$body" | jq -e '(.ports // []) | length > 0' >/dev/null; then
      fail "$svc: tiene 'ports:' (debe ser eliminado; Coolify enruta el dominio)"
    fi
    if echo "$body" | jq -e '.container_name != null' >/dev/null; then
      fail "$svc: container_name fijo (Coolify pone el nombre de proyecto)"
    fi
    if echo "$body" | jq -e '.privileged == true' >/dev/null; then
      fail "$svc: privileged=true (prohibido)"
    fi
    if echo "$body" | jq -e '(.cap_add // []) | length > 0' >/dev/null; then
      fail "$svc: cap_add no vacio"
    fi
    if echo "$body" | jq -e '(.devices // []) | length > 0' >/dev/null; then
      fail "$svc: devices no vacio"
    fi
    if echo "$body" | jq -e '.network_mode == "host"' >/dev/null; then
      fail "$svc: network_mode host"
    fi
    if echo "$body" | jq -e '.pid == "host" or .ipc == "host"' >/dev/null; then
      fail "$svc: pid/ipc host"
    fi
    if echo "$body" | jq -e '(.security_opt // []) | any(test("(^|[=:\\[:space:]])unconfined($|[=:\\[:space:])"))' >/dev/null; then
      fail "$svc: security_opt unconfined"
    fi
    if echo "$body" | jq -e '(.volumes // []) | map(select(type == "object" and .source == "/var/run/docker.sock")) | length > 0' >/dev/null; then
      fail "$svc: monta docker.sock"
    fi
    if echo "$body" | jq -e --arg root "$ROOT" '(.volumes // []) | map(select(type == "object" and .type == "bind" and (.source | type == "string") and (.source | startswith("/")) and (.source != $root) and (.source | startswith($root + "/") | not))) | length > 0' >/dev/null; then
      local bad
      bad=$(echo "$body" | jq -r --arg root "$ROOT" '(.volumes // []) | map(select(type == "object" and .type == "bind" and (.source | type == "string") and (.source | startswith("/")) and (.source != $root) and (.source | startswith($root + "/") | not))) | map(.source) | join(",")')
      fail "$svc: bind fuera del repo: $bad"
    fi
  done
}

check_supabase_pg_params() {
  local rendered="$1"
  local raw
  raw=$(jq -r '
    [ .. | objects
      | to_entries[]
      | select((.key | test("^(HBOX_DATABASE_(DATABASE|USERNAME|SSL_MODE)|PGDATABASE|PGUSER|PGSSLMODE)$")))
    ]
    | map("\(.key)=\(.value|tostring)")
    | join(" ")' "$rendered")

  if ! grep -qE '(^| )(PGSSLMODE|HBOX_DATABASE_SSL_MODE)=disable($| )' <<<"$raw"; then
    fail "compose supabase-pg: no se encontro sslmode=disable (no esta parametrizado)"
  fi
  if ! grep -qE '(^| )(PGDATABASE|HBOX_DATABASE_DATABASE)=mvp_prueba($| )' <<<"$raw"; then
    fail "compose supabase-pg: no se encontro DB=mvp_prueba (no esta parametrizado)"
  fi
}

main() {
  local tmpdir
  tmpdir="$(mktemp -d)"

  for compose in "${COMPOSE_FILES[@]}"; do
    local path="$ROOT/$compose"
    [ -f "$path" ] || { rm -rf "$tmpdir"; fail "no existe $compose"; }
    local envfile="$tmpdir/.env.$(basename "$compose")"
    local rendered="$tmpdir/rendered.$(basename "$compose").json"
    gen_env "$path" "$envfile"
    render_compose "$path" "$envfile" "$rendered"
    check_root_names "$path"
    check_services_safety "$rendered"
    if [ "$COMPOSE_BD" = "supabase-pg" ]; then
      check_supabase_pg_params "$rendered"
    fi
  done

  rm -rf "$tmpdir"
  echo "OK: contratos Coolify cumplidos"
}

main "$@"