# Arquitectura

El repo separa tres ejes que antes vivían mezclados en `configuration.nix`:

| Capa | Responde a | Cambia entre… | Ejemplo |
|------|------------|---------------|---------|
| `modules/nixos/*` | qué puede hacer el sistema | nunca | pipewire, keyd, virtualisation |
| `modules/home/*` | qué puede hacer el usuario | nunca | nvim, gwal, apps |
| `modules/compartidos/*` | sistema + usuario | nunca | gnome, flatpak |
| `users/<u>/` | quién es y qué quiere | usuarios | dotfiles, apps, juegos |
| `hosts/<h>/` | sobre qué máquina corre | máquinas | discos, kernel, GPU, rutas |
| `vars.nix` | defaults globales | casi nunca | system, timezone, stateVersion |

## Flujo de evaluación

1. `mkHost` (en `flake.nix`) carga `hosts/<host>/settings.nix` y resuelve la lista de usuarios.
2. `hosts/<host>/default.nix` importa el hardware y aplica `host.modulos` (módulos del sistema).
3. Para cada usuario se construye `home-manager.users.<u>` mezclando `users/<u>` con
   `host.homeOverrides.<u>` (ajustes puntuales por máquina).
4. `specialArgs` inyecta `inputs`, `helpers`, `vars` y `host` en todos los módulos.
5. `modules/home` entra como `sharedModules` para todos los usuarios.

## Qué va en cada eje

- **Host**: `fileSystems`, `boot.*`, `networking.hostName`, GPU/kernel, LUKS, rollback,
  rutas a discos externos, `gwal.directorio`.
- **Usuario**: `modulos.home.*`, `home.packages`, rutas dentro del hogar, atajos `dconf`,
  dotfiles, y la allowlist del home (`users/<u>/home-allowlist.nix`).
- **Compartido/global**: `modulos.nixos.*`, `modulos.compartidos.*`, `vars.nix`.

## Añadir capacidades

Los módulos se auto-importan con `helpers.importDir`. Basta con crear
`modules/{nixos,home,compartidos}/<categoria>/<nombre>.nix` con su opción
`modulos.<...>.<nombre>.enable` y activarla desde `hosts/<host>/settings.nix` o
`users/<usuario>/default.nix` según corresponda.
