{ host, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware-extra.nix
    ./../../modules/nixos
  ];

  networking.hostName = host.hostname;

  modulos = host.modulos;
}
