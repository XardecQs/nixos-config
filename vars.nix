{
  # Valores por defecto globales compartidos por NixOS y home-manager.
  # Los datos específicos de cada máquina viven en hosts/<host>/settings.nix,
  # y los de cada usuario en users/<usuario>/default.nix.

  system = "x86_64-linux";
  defaultUser = "xardec";
  timezone = "America/Lima";
  locale = "es_PE.UTF-8";
  stateVersion = "26.05";

  # Subruta (relativa al hogar del usuario) donde vive este repositorio.
  # Se usa para derivar rutas como la de nixd/nh sin hardcodear el usuario.
  flakeSubpath = "Proyectos/GitHub/nixos-config";
}
