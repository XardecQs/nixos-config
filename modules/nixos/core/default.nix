{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
    builtins.attrNames
    (builtins.filter (
      name:
      name != "default.nix"
      && (lib.hasSuffix ".nix" name || builtins.pathExists (./. + "/${name}/default.nix"))
    ))
    (builtins.map (name: ./. + "/${name}"))
  ];
}
