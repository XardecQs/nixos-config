{ lib }:
{
  # Importa todos los módulos de un directorio:
  #   - archivos "<nombre>.nix"
  #   - subdirectorios "<nombre>/default.nix"
  # ignorando "default.nix" del propio directorio y los prefijados con "_"
  # (plantillas/parciales que no son módulos).
  importDir =
    dir:
    let
      entradas = builtins.readDir dir;
      esModulo =
        name:
        name != "default.nix"
        && !(lib.hasPrefix "_" name)
        && (lib.hasSuffix ".nix" name || builtins.pathExists (dir + "/${name}/default.nix"));
    in
    builtins.map (name: dir + "/${name}") (builtins.filter esModulo (builtins.attrNames entradas));
}
