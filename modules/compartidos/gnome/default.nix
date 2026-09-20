{ lib, ... }:
{
  imports = [
    ./sistema.nix
    ./usuario.nix
  ];

  options.modulos.compartidos.gnome = {
    enable = lib.mkEnableOption "GNOME (sistema + usuario)";
  };
}
