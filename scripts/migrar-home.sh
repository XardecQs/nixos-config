#!/usr/bin/env bash
# Migración del home a un subvolumen btrfs dedicado (@home).
#
# Ejecutar con root, con el btrfs ya montado en /mnt (subvolid=5):
#   sudo mount /dev/mapper/DecryptedSystem /mnt
#   sudo ./scripts/migrar-home.sh
#
# Hace SOLO la parte de datos (respaldo, crear @home, repoblar). Luego:
#   1) editar hosts/<host>/settings.nix -> modulos.nixos.homeEstado.subvolumen.enable = true
#   2) sudo nixos-rebuild boot && sudo reboot
#   3) revisar `home-audit`, sembrar allowlist y poner dryRun = false
set -euo pipefail

MNT="${MNT:-/mnt}"
USER_NAME="${USER_NAME:-xardec}"
HOME_SRC="${HOME_SRC:-/home/$USER_NAME}"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"

fail() { echo "Error: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || fail "ejecutar como root (sudo)"
[[ -d "$MNT/@persist" ]] || fail "no se ve un layout btrfs en $MNT (¿montaste el subvolid=5?)"
command -v btrfs >/dev/null || fail "falta btrfs-progs"
command -v rsync >/dev/null || fail "falta rsync"

mkdir -p "$MNT/old_roots"

# 1) Respaldar el @home obsoleto
if [[ -e "$MNT/@home" ]]; then
  echo "[1/4] Respadando @home -> old_roots/@home_stale_$STAMP"
  mv "$MNT/@home" "$MNT/old_roots/@home_stale_$STAMP"
fi

# 2) Snapshot de seguridad de @persist (por si acaso)
echo "[2/4] Snapshot de @persist -> old_roots/@persist_$STAMP"
btrfs subvolume snapshot "$MNT/@persist" "$MNT/old_roots/@persist_$STAMP"

# 3) Crear @home nuevo
echo "[3/4] Creando subvolumen @home"
btrfs subvolume create "$MNT/@home"

# 4) Repoblar con reflink (mismo btrfs: rápido y sin duplicar espacio)
echo "[4/4] Copiando $HOME_SRC -> $MNT/@home/$USER_NAME (reflink)"
mkdir -p "$MNT/@home/$USER_NAME"
rsync -aHAX --numeric-ids --reflink=auto --info=progress2 "$HOME_SRC/" "$MNT/@home/$USER_NAME/"

echo
echo "Listo. Pasos siguientes:"
echo "  1) En hosts/<host>/settings.nix: modulos.nixos.homeEstado.subvolumen.enable = true;"
echo "  2) sudo nixos-rebuild boot && sudo reboot"
echo "  3) Tras reiniciar: 'home-audit' (solo lista). Sembrar allowlist y poner dryRun = false."
echo
echo "Respaldos:"
echo "  $MNT/old_roots/@home_stale_$STAMP"
echo "  $MNT/old_roots/@persist_$STAMP"
echo "El home viejo sigue en /persist/home/$USER_NAME hasta que lo borres manualmente."
