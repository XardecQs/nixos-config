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

## Tareas

Las tareas viven en `justfile` (requiere `just`, incluido en el perfil de usuario):

```sh
just                    # lista las tareas
just switch             # aplica la configuración (nh + overrides de inputs locales)
just boot               # registra la próxima generación de arranque
just build              # construye sin activar
just check              # nix flake check con overrides
just ci                 # fmt-check + lint + check
just fmt                # formatea todos los .nix versionados
just update             # actualiza todos los inputs
just update nixpkgs-stable
just gc                 # limpia generaciones antiguas
just audit              # home-audit
```

`just switch` acepta otro host: `just switch <host>`. La función `rebuild` del zsh
sigue disponible y llama al mismo script (`scripts/flake.sh`).

Hosts disponibles: `NeoReaper`.

## Documentación

- [Bootstrap de una máquina nueva](docs/bootstrap.md)
- [Arquitectura](docs/arquitectura.md)
- [Organización de archivos](docs/archivos.md)
- [Persistencia del home](docs/persistencia.md)
