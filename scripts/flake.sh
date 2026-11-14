#!/usr/bin/env bash
# Orquestador del flake: reconstrucción y verificación.
# Única fuente de verdad para los overrides de inputs locales.
set -euo pipefail

usage() {
  cat <<'EOF'
Uso: scripts/flake.sh <accion> [host] [args...]

Acciones:
  switch   aplica la configuración (nh os switch)
  boot     registra la próxima generación de arranque
  test     activa la configuración solo para la sesión actual
  build    construye el toplevel sin activarlo
  check    nix flake check --no-build --no-write-lock-file

Variables:
  HOST     host a reconstruir (por defecto: hostname -s)
  HOME     se usa para localizar los repos de inputs locales
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo="$(dirname -- "$script_dir")"

action="${1:-}"
if [[ -z "$action" || "$action" == "-h" || "$action" == "--help" ]]; then
  usage
  [[ -n "$action" ]] && exit 0 || exit 2
fi
shift

host="${1:-${HOST:-$(hostname -s)}}"
if (( $# > 0 )); then
  shift
fi
extra=("$@")

local_repos="${HOME}/Proyectos/GitHub"

overrides=()
[[ -d "${local_repos}/font-collection/.git" ]] ||
  overrides+=(--override-input font-collection github:XardecQs/font-collection)
[[ -d "${local_repos}/iconos/.git" ]] ||
  overrides+=(--override-input iconos github:XardecQs/iconos)
[[ -d "${local_repos}/samt-nix/.git" ]] ||
  overrides+=(--override-input gta-mo github:XardecQs/samt-nix)

case "$action" in
  check)
    exec nix flake check --no-build --no-write-lock-file "${overrides[@]}" "$repo"
    ;;
  switch | boot | test | build)
    for dep in artcraft-nix horizon-nix; do
      if [[ ! -d "${local_repos}/${dep}" ]]; then
        printf 'Falta %s (repo local git+file de %s). Cópialo o clónalo antes de reconstruir.\n' \
          "${local_repos}/${dep}" "$dep" >&2
        exit 1
      fi
    done
    if command -v home-audit >/dev/null 2>&1; then
      audit="$(home-audit || true)"
      if [[ -n "$audit" ]]; then
        printf 'Aviso: home-audit detectó entradas fuera de la allowlist:\n%s\n' "$audit" >&2
      fi
    fi
    cmd=(nh os "$action" "${repo}#${host}")
    cmd+=("${extra[@]}")
    if (( ${#overrides[@]} > 0 )); then
      cmd+=(-- "${overrides[@]}")
    fi
    exec "${cmd[@]}"
    ;;
  *)
    printf 'Acción desconocida: %s\n' "$action" >&2
    usage >&2
    exit 2
    ;;
esac
