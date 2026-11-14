# Bootstrap de una máquina nueva

## 1. Clonar el repo

```sh
git clone git@github.com:XardecQs/nixos-config.git ~/Proyectos/GitHub/nixos-config
cd ~/Proyectos/GitHub/nixos-config
```

## 2. Inputs locales (font-collection / gta-mo / iconos / artcraft-nix / unmined-nix / horizon-nix)

Por defecto el flake usa seis inputs locales:

- `font-collection` → `~/Proyectos/GitHub/font-collection` (repo pesado; se usa en local por velocidad).
- `gta-mo` → `~/Proyectos/GitHub/samt-nix` (en desarrollo; commits locales).
- `iconos` → `~/Proyectos/GitHub/iconos` (pack de iconos en desarrollo; commits locales).
- `artcraft-nix` → `~/Proyectos/GitHub/artcraft-nix` (input `git+file:`; repo local commiteado, aún sin remoto).
- `unmined-nix` → `~/Proyectos/GitHub/unmined-nix` (input `git+file:`; paquete y módulo HM de uNmINeD).
- `horizon-nix` → `~/Proyectos/GitHub/horizon-nix` (input `git+file:`; launcher y módulo HM de Horizon).

En una máquina sin los tres primeros repos, se sustituyen por GitHub con `--override-input`:

```sh
nh os switch ~/Proyectos/GitHub/nixos-config -- \
  --override-input font-collection github:XardecQs/font-collection \
  --override-input gta-mo github:XardecQs/samt-nix \
  --override-input iconos github:XardecQs/iconos
```

`artcraft-nix`, `unmined-nix` y `horizon-nix` todavía no tienen remoto: mantén sus
repos locales en `~/Proyectos/GitHub/`. Cuando se publiquen, sustituye cada input por
su URL de GitHub y ejecuta `nix flake update <input>`.

La función `rebuild` del zsh (y `just switch`) hace la detección automática de los tres
inputs con remoto: si los directorios locales no existen, añade los overrides; si existen,
los usa. También avisa si falta `artcraft-nix` o `horizon-nix`.

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

En una máquina recién instalada todavía no hay `nh` ni `just`, así que usa
`nixos-rebuild` directamente:

```sh
sudo nixos-rebuild switch --flake ~/Proyectos/GitHub/nixos-config#<nuevo>
```

A partir de ahí ya puedes usar `just switch <host>` o la función `rebuild`.

## 7. Añadir un usuario

1. Crear `users/<usuario>/default.nix` (importando perfiles y `modulos.home.*`).
2. Añadirlo a `hosts/<host>/settings.nix` en la lista `users`.
3. Declararlo en `hosts/<host>/settings.nix` (`modulos.nixos.core.users.admin` o `extraUsers`).
4. Añadir su clave pública a `adminAuthorizedKeys` (administrador) o a su configuración SSH.
5. Añadir su clave a `secrets.nix` y crear sus secretos.
