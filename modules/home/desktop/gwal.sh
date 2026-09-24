#!/usr/bin/env bash
set -euo pipefail

# ─── Configuración (inyectada por Nix o variables de entorno) ────────────────

DIRECTORIO="${GWAL_DIRECTORIO:-$HOME/Media/Imágenes/Wallpapers}"
MODO="${GWAL_MODO:-auto}"
read -r -a EXTENSIONES <<< "${GWAL_EXTENSIONES:-jpeg jpg png gif pnm tga tiff webp bmp farbfeld}"
ESTADO_DIR="${GWAL_ESTADO_DIRECTORIO:-$HOME/.local/state/gwal}"
NOTIFICACIONES="${GWAL_NOTIFICACIONES:-true}"

# Estado de la última selección (lo fijan las funciones de elección).
SELECCIONADA=""
SEL_TOTAL=0
SEL_RESTANTES=0
CICLO_REINICIADO="false"

# ─── Utilidades ──────────────────────────────────────────────────────────────

error() {
    echo "Error: $*" >&2
    exit 1
}

comprobar_deps() {
    for cmd in gsettings zenity shuf find realpath mkdir; do
        command -v "$cmd" >/dev/null 2>&1 || error "dependencia faltante: '$cmd'"
    done
}

notificar() {
    local titulo="$1" mensaje="$2" icono="${3:-}"
    [[ "${NOTIFICACIONES,,}" == "true" ]] || return 0
    command -v notify-send >/dev/null 2>&1 || return 0
    if [[ -n "$icono" ]]; then
        notify-send -i "$icono" "$titulo" "$mensaje" 2>/dev/null || true
    else
        notify-send "$titulo" "$mensaje" 2>/dev/null || true
    fi
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

# ─── Historial (carrusel) ────────────────────────────────────────────────────

# Ruta del fichero de wallpapers ya usados para un modo concreto.
ruta_historial() {
    printf '%s/usados-%s\n' "$ESTADO_DIR" "$1"
}

# Vacía el historial del modo indicado, reiniciando el ciclo.
limpiar_historial() {
    local modo="$1" archivo
    archivo="$(ruta_historial "$modo")"
    [[ -f "$archivo" ]] && : > "$archivo"
    echo "Historial de '$modo' reiniciado."
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

# Elige una imagen sin repetir hasta agotar el ciclo; al agotarse lo reinicia.
# Deja el resultado y el progreso en las variables globales SEL_*.
elegir_aleatoria() {
    local modo="$1" archivo
    archivo="$(ruta_historial "$modo")"
    mkdir -p "$ESTADO_DIR"

    local todas=()
    mapfile -t todas < <(obtener_imagenes "$modo")
    SEL_TOTAL="${#todas[@]}"
    (( SEL_TOTAL > 0 )) || error "no se encontraron imágenes en '$DIRECTORIO'"

    local -A usadas=()
    if [[ -f "$archivo" ]]; then
        local usada
        while IFS= read -r usada || [[ -n "$usada" ]]; do
            [[ -n "$usada" ]] && usadas["$usada"]=1
        done < "$archivo"
    fi

    local candidatas=() img canon
    for img in "${todas[@]}"; do
        canon="$(realpath "$img")"
        [[ -n "${usadas[$canon]:-}" ]] || candidatas+=("$canon")
    done

    CICLO_REINICIADO="false"
    if (( ${#candidatas[@]} == 0 )); then
        : > "$archivo"
        for img in "${todas[@]}"; do
            candidatas+=("$(realpath "$img")")
        done
        CICLO_REINICIADO="true"
    fi

    SEL_RESTANTES=$(( ${#candidatas[@]} - 1 ))
    SELECCIONADA="$(printf '%s\n' "${candidatas[@]}" | shuf -n 1)"
    printf '%s\n' "$SELECCIONADA" >> "$archivo"
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
    SELECCIONADA="$out"
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

mostrar_progreso() {
    local modo="$1"
    if [[ "$CICLO_REINICIADO" == "true" ]]; then
        notificar "gwal" "Ciclo completo en '$modo': historial reiniciado. Quedan $SEL_RESTANTES de $SEL_TOTAL."
    else
        notificar "gwal" "Fondo aplicado ($modo). Quedan $SEL_RESTANTES de $SEL_TOTAL."
    fi
}

mostrar_ayuda() {
    cat <<EOF
Uso: gwal [OPCIÓN]

Opciones:
  -r, --random   Aplica una imagen aleatoria sin repetir hasta agotar el ciclo
  -p, --pick     Abre un selector de archivos
  -c, --clear    Reinicia el historial del modo actual
  -h, --help     Muestra esta ayuda

Sin argumentos, muestra un diálogo de selección.
EOF
}

# ─── main ────────────────────────────────────────────────────────────────────

main() {
    comprobar_deps

    local accion modo
    case "${1:-}" in
        --random | -r) accion="random" ;;
        --pick | -p) accion="manual" ;;
        --clear | -c) accion="clear" ;;
        --help | -h) mostrar_ayuda; exit 0 ;;
        "") accion="$(menu_zenity)" || exit 0 ;;
        *) mostrar_ayuda >&2; exit 1 ;;
    esac

    modo="$(resolver_modo)"

    case "$accion" in
        random)
            elegir_aleatoria "$modo"
            aplicar_fondo "$SELECCIONADA"
            mostrar_progreso "$modo"
            ;;
        manual)
            elegir_manual || exit 0
            aplicar_fondo "$SELECCIONADA"
            ;;
        clear)
            limpiar_historial "$modo"
            ;;
    esac
}

main "$@"
