# nixos-config

Configuración NixOS + home-manager, **multi-host** y **multi-usuario**, gestionada como flake.

## Estructura

| Ruta | Responsabilidad |
|------|-----------------|
| `flake.nix` | Define `nixosConfigurations` (hosts) y compone usuarios/módulos. |
| `vars.nix` | Defaults globales (`system`, usuario, timezone, locale, `stateVersion`). |
| `hosts/<host>/` | Hardware y ajustes de cada máquina (`settings.nix`, `default.nix`, `hardware-*.nix`). |
| `users/<user>/` | Preferencias de cada usuario (`modulos.home.*`). |
| `modules/nixos/` | Módulos de sistema agnósticos. |
| `modules/home/` | Módulos de usuario agnósticos. |
| `modules/compartidos/` | Módulos que afectan sistema y usuario. |
| `lib/` | Helpers (`importDir`, etc.). |
| `secrets/` | Secretos cifrados con agenix. |
| `docs/` | Guías. |

## Reconstruir

```sh
# con la función `rebuild` del zsh (usa nh y detecta inputs locales):
rebuild

# equivalente manual:
nh os switch ~/Proyectos/GitHub/nixos-config
```

Hosts disponibles: `NeoReaper`.

## Documentación

- [Bootstrap de una máquina nueva](docs/bootstrap.md)
- [Arquitectura](docs/arquitectura.md)
- [Organización de archivos](docs/archivos.md)
