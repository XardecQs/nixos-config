#!/usr/bin/env bash
set -euo pipefail

# ─── Configuración (inyectada por Nix o variables de entorno) ────────────────

DIRECTORIO="${GWAL_DIRECTORIO:-$HOME/Media/Imágenes/Wallpapers}"
MODO="${GWAL_MODO:-auto}"
read -r -a EXTENSIONES <<< "${GWAL_EXTENSIONES:-jpeg jpg png gif pnm tga tiff webp bmp farbfeld}"

# ─── Utilidades ──────────────────────────────────────────────────────────────

error() {
    echo "Error: $*" >&2
    exit 1
}

comprobar_deps() {
    for cmd in gsettings zenity shuf find realpath; do
        command -v "$cmd" >/dev/null 2>&1 || error "dependencia faltante: '$cmd'"
    done
}

# Devuelve 0 si el fichero tiene una extensión soportada.
es_imagen() {
    local f="$1" ext
    ext="${f##*.}"
    [[ "$ext" == "$f" ]] && return 1 # sin extensión
    ext="${ext,,}"
    local e
    for e in "${EXTENSIONES[@]}"; do
        [[ "$ext" == "$e" ]] && return 0
    done
    return 1
}

# Lista imágenes (una por línea) bajo `dir`, aplicando las opciones extra de find.
recoger() {
    local dir="$1"
    shift
    [[ -d "$dir" ]] || return 0
    local f
    while IFS= read -r -d '' f; do
        es_imagen "$f" && printf '%s\n' "$f"
    done < <(find "$dir" "$@" -type f -print0 2>/dev/null)
}

# ─── Modo de selección ───────────────────────────────────────────────────────

# Resuelve el modo final: "auto" detecta el tema de GNOME (oscuro/claro).
resolver_modo() {
    local m="$MODO"
    if [[ "$m" == "auto" ]]; then
        local scheme
        scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)"
        case "$scheme" in
            *prefer-dark*) m="oscuro" ;;
            *) m="claro" ;;
        esac
    fi
    printf '%s\n' "$m"
}

# Lista todas las imágenes candidatas según el modo.
# Las imágenes sueltas en la raíz del directorio siempre se incluyen.
obtener_imagenes() {
    local modo="$1"
    case "$modo" in
        todo)
            recoger "$DIRECTORIO"
            ;;
        claro | oscuro)
            recoger "$DIRECTORIO" -maxdepth 1 # sueltas en la raíz
            recoger "$DIRECTORIO/$modo" # clasificadas
            ;;
        *)
            error "modo desconocido: '$modo'"
            ;;
    esac
}

elegir_aleatoria() {
    local img
    img="$(obtener_imagenes "$1" | shuf -n 1)"
    [[ -n "$img" ]] || error "no se encontraron imágenes en '$DIRECTORIO'"
    printf '%s\n' "$img"
}

# ─── Selección manual (zenity) ───────────────────────────────────────────────

construir_filtro() {
    local exts=() e
    for e in "${EXTENSIONES[@]}"; do
        exts+=("*.$e")
    done
    printf 'Imágenes | %s\n' "${exts[*]}"
}

elegir_manual() {
    local filtro out
    filtro="$(construir_filtro)"
    out="$(zenity --file-selection \
        --title="Selecciona una imagen de fondo" \
        --file-filter="$filtro" \
        --filename="$DIRECTORIO/" \
        --width=900 --height=700 2>/dev/null)" || return 1
    [[ -n "$out" ]] || return 1
    printf '%s\n' "$out"
}

menu_zenity() {
    local out
    out="$(zenity --list \
        --title="Seleccionar fondo" \
        --text="Elige una opción:" \
        --column=Opción \
        "Imagen aleatoria" "Imagen manual" \
        --height=300 --width=300 2>/dev/null)" || return 1
    case "$out" in
        "Imagen aleatoria") printf 'random\n' ;;
        "Imagen manual") printf 'manual\n' ;;
        *) return 1 ;;
    esac
}

# ─── Aplicar fondo ───────────────────────────────────────────────────────────

aplicar_fondo() {
    local img uri
    img="$(realpath "$1")" || error "ruta de imagen inválida: '$1'"
    uri="file://$img"
    gsettings set org.gnome.desktop.background picture-uri "$uri" \
        || error "gsettings falló al establecer picture-uri"
    gsettings set org.gnome.desktop.background picture-uri-dark "$uri" \
        || error "gsettings falló al establecer picture-uri-dark"
    echo "Fondo aplicado: $img"
}

mostrar_ayuda() {
    cat <<EOF
Uso: gwal [OPCIÓN]

Opciones:
  -r, --random   Aplica una imagen aleatoria de $DIRECTORIO
  -p, --pick     Abre un selector de archivos
  -h, --help     Muestra esta ayuda

Sin argumentos, muestra un diálogo de selección.
EOF
}

# ─── main ────────────────────────────────────────────────────────────────────

main() {
    comprobar_deps

    local accion img
    case "${1:-}" in
        --random | -r) accion="random" ;;
        --pick | -p) accion="manual" ;;
        --help | -h) mostrar_ayuda; exit 0 ;;
        "") accion="$(menu_zenity)" || exit 0 ;;
        *) mostrar_ayuda >&2; exit 1 ;;
    esac

    case "$accion" in
        random) img="$(elegir_aleatoria "$(resolver_modo)")" ;;
        manual) img="$(elegir_manual)" || exit 0 ;;
    esac

    aplicar_fondo "$img"
}

main "$@"
