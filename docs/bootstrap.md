# Bootstrap de una máquina nueva

## 1. Clonar el repo

```sh
git clone git@github.com:XardecQs/nixos-config.git ~/Proyectos/GitHub/nixos-config
cd ~/Proyectos/GitHub/nixos-config
```

## 2. Inputs locales (font-collection / gta-mo)

Por defecto el flake usa dos inputs locales:

- `font-collection` → `~/Proyectos/GitHub/font-collection` (repo pesado; se usa en local por velocidad).
- `gta-mo` → `~/Proyectos/GitHub/samt-nix` (en desarrollo; commits locales).

En una máquina sin esos repos, se sustituyen por GitHub con `--override-input`:

```sh
nh os switch ~/Proyectos/GitHub/nixos-config -- \
  --override-input font-collection github:XardecQs/font-collection \
  --override-input gta-mo github:XardecQs/samt-nix
```

La función `rebuild` del zsh hace esta detección automáticamente: si los directorios locales
no existen, añade los overrides; si existen, los usa.

Alternativa: clonar también esos repos en las mismas rutas locales.

## 3. Generar el hardware del host

```sh
sudo nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
```

Crear `hosts/<nuevo>/` copiando una plantilla:

```
hosts/<nuevo>/
  default.nix                # imports hardware + aplica host.modulos
  settings.nix               # hostname, users, admin, modulos.nixos.*, rutas de host
  hardware-configuration.nix # generado
  hardware-extra.nix         # añadidos manuales (discos, zram, etc.)
```

Editar `settings.nix` (hostname, usuario administrador, módulos) y `default.nix` si hace falta.

## 4. Registrar el host en el flake

En `flake.nix`:

```nix
nixosConfigurations = {
  NeoReaper = mkHost { hostname = "NeoReaper"; };
  <nuevo>   = mkHost { hostname = "<nuevo>"; };
};
```

## 5. Secretos (agenix)

Cada host necesita su clave SSH añadida a `secrets.nix` como receptor, y la identidad age
en `~/.ssh/agenix` (la ruta que usa `age.identityPaths`). Restaurar esa identidad desde
un backup seguro antes del primer `switch`.

## 6. Primer switch

```sh
sudo nixos-rebuild switch --flake ~/Proyectos/GitHub/nixos-config#<nuevo>
```

## 7. Añadir un usuario

1. Crear `users/<usuario>/default.nix` (importando perfiles y `modulos.home.*`).
2. Añadirlo a `hosts/<host>/settings.nix` en la lista `users`.
3. Declararlo en `modules/nixos/core/users.nix` (`admin` o `extraUsers` del host).
4. Añadir su clave a `secrets.nix` y crear sus secretos.
