{ lib, ... }:
{
  imports = [
    ./sistema.nix
  ];

  options.modulos.compartidos.gnome = {
    enable = lib.mkEnableOption "GNOME (sistema)";
  };
}
