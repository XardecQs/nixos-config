{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.nixos.services.windows-vm;

  sessionScript = pkgs.writeShellScriptBin "ventana-qemu-session" ''
    LOG_FILE="/home/xardec/Virtualizacion/ventana-qemu-session.log"
    exec >"$LOG_FILE" 2>&1 || exec >"/tmp/ventana-qemu-session.log" 2>&1

    set -euo pipefail

    VM_DISK="/home/xardec/Virtualizacion/images/windows-ltsc.qcow2"
    SPICE_SOCK="/tmp/ventana-qemu-spice-''${UID}.sock"
    PID_FILE="/tmp/ventana-qemu-''${UID}.pid"

    echo "[$(date)] Iniciando ventana-qemu-session"

    cleanup() {
      echo "[$(date)] cleanup disparado ($$)"
      if [ -f "$PID_FILE" ]; then
        QEMU_PID=$(cat "$PID_FILE")
        echo "[$(date)] Matando QEMU PID=$QEMU_PID"
        kill -TERM "$QEMU_PID" 2>/dev/null || true
        for i in $(seq 1 60); do
          kill -0 "$QEMU_PID" 2>/dev/null || break
          sleep 1
        done
        kill -KILL "$QEMU_PID" 2>/dev/null || true
        rm -f "$PID_FILE"
      fi
      rm -f "$SPICE_SOCK"
      echo "[$(date)] cleanup terminado"
    }

    trap cleanup EXIT INT TERM HUP

    if [ ! -f "$VM_DISK" ]; then
      echo "[$(date)] ERROR: disco no encontrado: $VM_DISK"
      exit 1
    fi

    echo "[$(date)] Arrancando QEMU..."
    ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
      -name windows-ltsc \
      -machine q35,accel=kvm \
      -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
      -smp cores=4 \
      -m 8G \
      -drive file="$VM_DISK",if=virtio,cache=none,aio=native \
      -device virtio-vga \
      -spice unix=on,addr="$SPICE_SOCK",disable-ticketing=on \
      -device virtio-serial-pci \
      -chardev spicevmc,id=vdagent,name=vdagent \
      -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
      -nic user,model=virtio-net-pci \
      -audiodev spice,id=spice \
      -device ich9-intel-hda \
      -device hda-micro,audiodev=spice \
      -rtc base=localtime \
      &
    QEMU_PID=$!
    echo "$QEMU_PID" > "$PID_FILE"
    echo "[$(date)] QEMU PID=$QEMU_PID"

    echo "[$(date)] Esperando socket SPICE..."
    for i in $(seq 1 30); do
      [ -S "$SPICE_SOCK" ] && break
      sleep 0.5
    done

    if [ ! -S "$SPICE_SOCK" ]; then
      echo "[$(date)] ERROR: socket SPICE no apareció en 15s"
      wait "$QEMU_PID" || echo "[$(date)] QEMU ya murió, exit=$?"
      exit 1
    fi

    echo "[$(date)] Socket listo, lanzando cage..."

    export GDK_BACKEND=wayland

    set +e
    ${pkgs.cage}/bin/cage -- ${pkgs.virt-viewer}/bin/remote-viewer \
      --full-screen "spice+unix://$SPICE_SOCK"
    CAGE_EXIT=$?
    set -e
    echo "[$(date)] cage terminó con exit=$CAGE_EXIT"

    if ! kill -0 "$QEMU_PID" 2>/dev/null; then
      echo "[$(date)] QEMU ($QEMU_PID) ya no está corriendo"
      wait "$QEMU_PID" || echo "[$(date)] QEMU exit code=$?"
    fi

    cleanup
  '';

  sessionDesktop = pkgs.writeTextFile {
    name = "ventana-qemu-session-desktop";
    destination = "/share/wayland-sessions/windows-qemu.desktop";
    text = ''
      [Desktop Entry]
      Encoding=UTF-8
      Name=Windows (QEMU)
      Comment=Arrancar máquina virtual Windows 10 LTSC
      Exec=${sessionScript}/bin/ventana-qemu-session
      Type=Application
    '';
    passthru.providedSessions = [ "windows-qemu" ];
  };
in
{
  options.modulos.nixos.services.windows-vm = {
    enable = lib.mkEnableOption "windows-vm";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qemu_kvm
      OVMF
      cage
      virt-viewer
    ];

    services.displayManager.sessionPackages = [ sessionDesktop ];
  };
}
