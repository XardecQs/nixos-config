set shell := ["bash", "-euo", "pipefail", "-c"]

host := env("HOST", `hostname -s`)
flake := justfile_directory()
flake_sh := flake / "scripts" / "flake.sh"

# Lista las tareas disponibles
default:
    @just --list

# Aplica la configuración (nh os switch + overrides de inputs locales)
switch h=host *args:
    "{{flake_sh}}" switch "{{h}}" {{args}}

# Registra la próxima generación de arranque sin activarla
boot h=host *args:
    "{{flake_sh}}" boot "{{h}}" {{args}}

# Activa la configuración solo para la sesión actual
test h=host *args:
    "{{flake_sh}}" test "{{h}}" {{args}}

# Construye el toplevel sin activarlo
build h=host *args:
    "{{flake_sh}}" build "{{h}}" {{args}}

# nix flake check con overrides de inputs locales
check:
    "{{flake_sh}}" check

# Formatea todos los .nix versionados
fmt:
    nixfmt $(git -C "{{flake}}" ls-files '*.nix')

# Verifica el formato sin escribir
fmt-check:
    nixfmt --check $(git -C "{{flake}}" ls-files '*.nix')

# Ejecuta statix y deadnix
lint:
    statix check .
    deadnix --fail .

# Verificación completa (equivalente a CI local)
ci: fmt-check lint check

# Actualiza todos los inputs, o solo el indicado: just update nixpkgs-stable
update input="":
    if [[ -n "{{input}}" ]]; then nix flake update "{{input}}"; else nix flake update; fi

# Limpia generaciones antiguas con nh
gc:
    nh clean all --keep-since 4d --keep 3

# Lista entradas del home fuera de la allowlist
audit:
    home-audit

# Edita un secreto agenix: just secrets-edit primaryUser-password
secrets-edit name:
    agenix -e "secrets/{{name}}.age"

# Re-cifra los secretos tras cambiar receptores en secrets.nix
secrets-rekey:
    agenix -r
