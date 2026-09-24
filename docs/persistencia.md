# Persistencia del home (modelo C)

Objetivo: evitar que el home acumule basura con el tiempo **sin** los problemas que
introduce bind-mountear paths sueltos (papelera rota, `mimeapps` con `EBUSY`,
distrobox/waydroid con mounts anidados, etc.).

## Idea

- `/home` se monta desde un **subvolumen btrfs dedicado `@home`** → es un **único
  filesystem normal**. Root sigue impermanente (`@root` se recrea desde `@blank`), pero
  el home no se toca. El montaje vive en el host (`hosts/<host>/hardware-configuration.nix`,
  `fileSystems."/home"`), no en el módulo.
- La limpieza ya no es "persistir solo lo listado", sino **"persistir todo y cuarentenar
  lo no permitido"** al arrancar (allowlist declarativa).
- Lo cuarentenado va a `~/.quarantine/<fecha>/…` (nunca se borra en el enforcement) y se
  poda con retención configurable.
- `~/.cache` y `~/.local/state` persistidos, con **janitor** por antigüedad.

## Módulo `modulos.nixos.homeEstado`

Opciones principales (en `hosts/<host>/settings.nix`):

| Opción | Descripción |
|---|---|
| `enable` | Activa el enforcement |
| `user` / `home` | Usuario y ruta del home |
| `allow.top` | Entradas permitidas en el nivel superior |
| `allow.config` | Permitidas en `~/.config` |
| `allow.share` | Permitidas en `~/.local/share` |
| `allow.state` | Permitidas en `~/.local/state` |
| `quarantine` | Directorio de cuarentena (por defecto `.quarantine`) |
| `retentionDays` | Retención de la cuarentena (30) |
| `dryRun` | Si `true`, solo reporta (no mueve nada) |
| `janitor.*` | Limpieza de `~/.cache`/`~/.local/state` por antigüedad |

El janitor se implementa aparte, en `modules/nixos/core/home-janitor.nix` (mismas opciones
bajo `homeEstado.janitor`), para que `home-estado.nix` se ocupe solo del enforcement.

Comportamiento del enforcement:
- Se ejecuta antes del display manager (`systemd.services.home-estado`).
- **Salta symlinks** (los gestiona home-manager) y **puntos de montaje**.
- Mueve a cuarentena lo no permitido; registra en el log del servicio.
- El janitor corre como el usuario (`systemd.services.home-cache-janitor`).

Comandos:
- `home-audit`: como el enforcement pero siempre en dry-run (lista lo que cuarentenaría).
- `home-promote <ruta-en-cuarentena> [destino]`: restaura algo de la cuarentena.

## Migración (una vez)

```sh
sudo mount /dev/mapper/DecryptedSystem /mnt   # subvolid=5
sudo ./scripts/migrar-home.sh
```
Luego:
1. En `hosts/<host>/hardware-configuration.nix`: añadir `fileSystems."/home"` con
   `subvol=@home` y `neededForBoot = true` (ver el host de referencia `NeoReaper`).
2. `sudo nixos-rebuild boot --flake ~/Proyectos/GitHub/nixos-config#NeoReaper && sudo reboot`.
3. Tras reiniciar: `home-audit` (revisar), sembrar la allowlist con lo legítimo, y
   `dryRun = false`.
4. Cuando esté validado: borrar `/persist/home/<user>` y los `old_roots/@home_stale_*`.

## Riesgos y salvaguardas

- **Nunca borra**: todo va a cuarentena (reversible). `home-promote` restaura.
- `dryRun = true` por defecto; nada se mueve hasta activar.
- `/home` usa `neededForBoot = true` por agenix (`~/.ssh/agenix`).
- El janitor usa **mtime** (los mounts son `noatime`) y excluye estado sensible
  (`zsh`, `wireplumber`, `syncthing`, `nix`, `home-manager`).

## Relación con backup

Este modelo **no** sustituye backups. `Archivo/Personal`, `Documentos` y `Proyectos`
siguen necesitando copia externa (ver `~/Documentos/pendientes.md`).
