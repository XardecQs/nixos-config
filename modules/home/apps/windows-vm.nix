{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.apps.windows-vm;

  setupScript = pkgs.writeShellScriptBin "ventana-qemu-setup" ''
    set -euo pipefail

    IMG_DIR="$HOME/Virtualizacion/images"
    ISO_DIR="$HOME/Virtualizacion/isos"
    DISK="$IMG_DIR/windows-ltsc.qcow2"

    mkdir -p "$IMG_DIR" "$ISO_DIR"

    if [ -f "$DISK" ]; then
      if [ "''${1:-}" != "--force" ]; then
        echo "El disco ya existe: $DISK"
        echo "Usá --force para recrearlo."
        exit 1
      fi
      rm -f "$DISK"
    fi

    echo "Creando disco virtual de ${cfg.diskSize}..."
    ${pkgs.qemu_kvm}/bin/qemu-img create -f qcow2 "$DISK" "${cfg.diskSize}"

    echo ""
    echo "Disco creado: $DISK"
    echo ""
    echo "Para instalar Windows 10 LTSC:"
    echo "  1. Colocá la ISO de Windows 10 LTSC en:"
    echo "     $ISO_DIR/"
    echo "  2. Descargá virtio-win ISO desde:"
    echo "     https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
    echo "     y guardala como: $ISO_DIR/virtio-win.iso"
    echo "  3. Ejecutá: ventana-qemu-instalar"
    echo ""
  '';

  installScript = pkgs.writeShellScriptBin "ventana-qemu-instalar" ''
    set -euo pipefail

    IMG_DIR="$HOME/Virtualizacion/images"
    ISO_DIR="$HOME/Virtualizacion/isos"
    DISK="$IMG_DIR/windows-ltsc.qcow2"

    if [ ! -f "$DISK" ]; then
      echo "Ejecutá ventana-qemu-setup primero."
      exit 1
    fi

    WIN_ISO=""
    for iso in "$ISO_DIR"/Win{10,dows10}*.iso "$ISO_DIR"/*.iso; do
      [ -f "$iso" ] && WIN_ISO="$iso" && break
    done

    if [ -z "$WIN_ISO" ] || [ ! -f "$WIN_ISO" ]; then
      echo "ISO de Windows no encontrada en $ISO_DIR/"
      echo "Renombrala como Win10-LTSC.iso o similar."
      exit 1
    fi

    VIRTIO_ISO="$ISO_DIR/virtio-win.iso"
    if [ ! -f "$VIRTIO_ISO" ]; then
      echo "virtio-win ISO no encontrada: $VIRTIO_ISO"
      echo "Descargala: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
      exit 1
    fi

    echo "ISO detectada: $WIN_ISO"
    echo "Arrancando instalador de Windows..."
    echo ""
    echo "IMPORTANTE: Cuando Windows pregunte por el disco, cargá los drivers"
    echo "            desde el CD-ROM de virtio-win:"
    echo "              virtio-win.iso/amd64/2k25 → NetKVM  (red)"
    echo "              virtio-win.iso/amd64/2k25 → viostor  (disco)"
    echo ""

    ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
      -name windows-ltsc-setup \
      -machine q35,accel=kvm \
      -cpu host \
      -smp cores=${toString cfg.cores} \
      -m ${cfg.ram} \
      -drive file="$DISK",if=virtio \
      -cdrom "$WIN_ISO" \
      -drive file="$VIRTIO_ISO",media=cdrom \
      -boot order=d \
      -device virtio-gpu-gl \
      -display gtk,gl=on \
      -device virtio-serial-pci \
      -chardev spicevmc,id=vdagent,name=vdagent \
      -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
      -nic user,model=virtio-net-pci \
      -audiodev pa,id=pa,server=unix:/run/user/$(id -u)/pulse/native \
      -device ich9-intel-hda \
      -device hda-micro,audiodev=pa \
      -rtc base=localtime
  '';
in
{
  options.modulos.home.apps.windows-vm = {
    enable = lib.mkEnableOption "windows-vm";

    diskSize = lib.mkOption {
      type = lib.types.str;
      default = "64G";
      description = "Tamaño del disco virtual qcow2";
    };

    ram = lib.mkOption {
      type = lib.types.str;
      default = "8G";
      description = "RAM asignada a la VM";
    };

    cores = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Núcleos asignados a la VM";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      qemu_kvm
      OVMF
      setupScript
      installScript
    ];

    home.activation.windowsVmDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/Virtualizacion/images" "$HOME/Virtualizacion/isos"
    '';
  };
}
