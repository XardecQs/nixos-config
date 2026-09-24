#!/usr/bin/env bash
# Migración del home a un subvolumen btrfs dedicado (@home).
#
# Ejecutar con root, con el btrfs ya montado en /mnt (subvolid=5):
#   sudo mount /dev/mapper/DecryptedSystem /mnt
#   sudo ./scripts/migrar-home.sh [--no-snapshot]
#
# Hace SOLO la parte de datos (respaldo, crear @home, repoblar). Luego:
#   1) editar hosts/<host>/settings.nix -> modulos.nixos.homeEstado.subvolumen.enable = true
#   2) sudo nixos-rebuild boot && sudo reboot
#   3) revisar `home-audit`, sembrar allowlist y poner dryRun = false
#
# Usa `cp --reflink=auto` (no `rsync --reflink`, que este build no soporta): al ser el
# mismo btrfs, clona por CoW (rápido y sin duplicar espacio).
set -euo pipefail

MNT="${MNT:-/mnt}"
USER_NAME="${USER_NAME:-xardec}"
HOME_SRC="${HOME_SRC:-/home/$USER_NAME}"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"

DO_SNAPSHOT=1
if [[ "${1:-}" == "--no-snapshot" ]]; then
  DO_SNAPSHOT=0
fi

fail() { echo "Error: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || fail "ejecutar como root (sudo)"
[[ -d "$MNT/@persist" ]] || fail "no se ve un layout btrfs en $MNT (¿montaste el subvolid=5?)"
command -v btrfs >/dev/null || fail "falta btrfs-progs"
command -v cp >/dev/null || fail "falta coreutils"

mkdir -p "$MNT/old_roots"

# 1) Asegurar un @home vacío; respaldar el existente si tuviera datos
if [[ ! -e "$MNT/@home" ]]; then
  echo "[1/3] Creando subvolumen @home"
  btrfs subvolume create "$MNT/@home"
elif [[ -n "$(ls -A "$MNT/@home/$USER_NAME" 2>/dev/null || true)" ]]; then
  echo "[1/3] @home ya tiene datos: respaldando y recreando"
  mv "$MNT/@home" "$MNT/old_roots/@home_stale_$STAMP"
  btrfs subvolume create "$MNT/@home"
else
  echo "[1/3] Reutilizando @home existente (vacío)"
fi

# 2) Snapshot de seguridad de @persist (opcional)
if [[ "$DO_SNAPSHOT" == 1 ]]; then
  echo "[2/3] Snapshot de @persist -> old_roots/@persist_$STAMP"
  btrfs subvolume snapshot "$MNT/@persist" "$MNT/old_roots/@persist_$STAMP"
else
  echo "[2/3] Snapshot omitido (--no-snapshot)"
fi

# 3) Repoblar con reflink
echo "[3/3] Copiando $HOME_SRC -> $MNT/@home/$USER_NAME (reflink/CoW)"
mkdir -p "$MNT/@home/$USER_NAME"
cp -a --reflink=auto "$HOME_SRC/." "$MNT/@home/$USER_NAME/" \
  || echo "Aviso: cp terminó con errores (probablemente sockets/archivos especiales); continuar y revisar."

echo
echo "Listo. Pasos siguientes:"
echo "  1) En hosts/<host>/settings.nix: modulos.nixos.homeEstado.subvolumen.enable = true;"
echo "  2) sudo nixos-rebuild boot && sudo reboot"
echo "  3) Tras reiniciar: 'home-audit' (solo lista). Sembrar allowlist y poner dryRun = false."
echo
echo "Respaldos en $MNT/old_roots/; el home viejo sigue en /persist/home/$USER_NAME hasta verificarlo."
