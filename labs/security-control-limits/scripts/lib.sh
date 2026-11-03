#!/usr/bin/env bash
set -euo pipefail

SCL_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export SCL_ROOT
INFRA_COMPOSE="$SCL_ROOT/infrastructure/docker-compose.yml"

case_backend() {
  case "$1" in
    CVE-2025-29927) printf '%s\n' 'case-target:3000' ;;
    CVE-2023-46604) printf '%s\n' 'case-target:61616' ;;
    CVE-2024-27198) printf '%s\n' 'case-target:8111' ;;
    *) echo "Unknown case: $1" >&2; return 2 ;;
  esac
}

validate_mode() {
  [[ "$1" == mode-a || "$1" == mode-b ]] || {
    echo "Mode must be mode-a or mode-b" >&2
    return 2
  }
}

compose_files() {
  local case_id="$1" mode="$2"
  printf '%s\n' "$INFRA_COMPOSE" \
    "$SCL_ROOT/cases/$case_id/docker-compose.yml" \
    "$SCL_ROOT/cases/$case_id/$mode/docker-compose.override.yml"
}

compose_cmd() {
  local case_id="$1" mode="$2" file args=(docker compose -p scl-lab)
  while IFS= read -r file; do args+=(-f "$file"); done < <(compose_files "$case_id" "$mode")
  printf '%q ' "${args[@]}"
}

run_in_service() {
  local service="$1"
  shift
  local case_id="${CASE_ID:?CASE_ID is required}" mode="${LAB_MODE:?LAB_MODE is required}" file
  local project="${SCL_COMPOSE_PROJECT_NAME:-scl-lab}"
  local args=(docker compose -p "$project")
  while IFS= read -r file; do args+=(-f "$file"); done < <(compose_files "$case_id" "$mode")
  [[ -z "${SCL_COMPOSE_EXTRA_FILE:-}" ]] || args+=(-f "$SCL_COMPOSE_EXTRA_FILE")
  "${args[@]}" exec -T "$service" "$@"
}

service_container_id() {
  local service="$1"
  local case_id="${CASE_ID:?CASE_ID is required}" mode="${LAB_MODE:?LAB_MODE is required}" file
  local project="${SCL_COMPOSE_PROJECT_NAME:-scl-lab}"
  local args=(docker compose -p "$project")
  while IFS= read -r file; do args+=(-f "$file"); done < <(compose_files "$case_id" "$mode")
  [[ -z "${SCL_COMPOSE_EXTRA_FILE:-}" ]] || args+=(-f "$SCL_COMPOSE_EXTRA_FILE")
  "${args[@]}" ps -q "$service"
}

# Copy a completed command artifact out of an untrusted client container. The
# client gets only tmpfs working storage and never a writable evidence mount.
capture_service_file() {
  local service="$1" source="$2" destination="$3" container_id
  container_id="$(service_container_id "$service")"
  [[ -n "$container_id" ]] || {
    echo "Could not resolve container for service: $service" >&2
    return 1
  }
  # Docker's archive-copy API does not reliably expose files from a container
  # tmpfs mount. Stream the completed file through exec instead; the host shell
  # owns the destination and the client still cannot modify retained evidence.
  docker exec "$container_id" cat "$source" >"$destination"
}

capture_service_file_or_empty() {
  local service="$1" source="$2" destination="$3"
  if ! capture_service_file "$service" "$source" "$destination" 2>/dev/null; then
    : >"$destination"
  fi
}

capture_http() {
  local service="$1" name="$2" destination_dir="$3"
  shift 3
  local tmp_base="/tmp/scl-$name"
  run_in_service "$service" curl -D "$tmp_base.headers" -o "$tmp_base.body" "$@" || true
  capture_service_file_or_empty "$service" "$tmp_base.headers" "$destination_dir/$name.headers"
  capture_service_file_or_empty "$service" "$tmp_base.body" "$destination_dir/$name.body"
}
