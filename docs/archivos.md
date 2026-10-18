# Organización de archivos

Sistema híbrido (**Modelo A**): **XDG** para las carpetas de sistema, **PARA** para documentos
activos, **por origen** para el archivo sentimental y **por tipo** para media/juegos.

## Regla de nombres

- **Carpetas de contenido** (visibles, con icono): **español natural** (Mayúscula inicial,
  tildes y espacios): `Imágenes`, `Vídeos`, `Música`, `Áreas`, `Grabaciones de pantalla`…
- **Carpetas técnicas** (código, repos, extensiones, ocultas): **ASCII**/`kebab-case`, minúsculas:
  `Proyectos/GitHub`, `Proyectos/Scripts/py`, `Juegos/ROMs`.
- Fechas `YYYY-MM-DD`; sin `|`, `:` ni duplicados por mayúsculas.

## Principios

- **Un solo inbox:** todo entra por `Descargas` y se triajea pronto (nada vive ahí más de unos días).
- **Temperatura:** lo activo en `Documentos`/`Media`/`Proyectos`; lo frío en `Archivo/`.
- **Un criterio por nivel:** documentos por **tema**, media por **tipo**, sentimental por **origen**.
- **XDG en la raíz** (nunca anidados); `Público` desactivado, `Plantillas` dentro de `Documentos`.
- **Sin duplicados lógicos:** una única ubicación canónica por cosa.

## Árbol

```
~/
├── Descargas/                 # inbox (único sitio donde usar `ordenar`)
├── Escritorio/                # XDG desktop
├── Documentos/                # ACTIVO, por TEMA
│   ├── Académicos/<curso>/
│   ├── Áreas/{Finanzas,Marca}/
│   ├── Recursos/<tema>/       # referencia por tema (no por formato)
│   ├── Plantillas/            # XDG templates
│   └── Obsidian/              # vault de Obsidian
├── Media/                     # por TIPO
│   ├── Imágenes/{Capturas de pantalla,Wallpapers,Fotos,...}
│   ├── Vídeos/{Grabaciones de pantalla,...}
│   ├── Música/{Álbumes,Sencillos}
│   ├── Libros/
│   └── Mangas/
├── Proyectos/{GitHub,Local,Scripts}   # técnicas: ASCII
├── Juegos/
├── Virtualizacion -> /storage/lab-hdd/Virtualizacion
└── Archivo/                   # FRÍO
    ├── Personal/
    │   ├── {Abuelo,Familia,Marca,Notas,PC-Infancia,Telefono,Ximena}/
    │   └── _recuperacion/     # informe y `zero/` (hasta cerrarlo)
    └── Tia/
```

Los wallpapers viven en `Media/Imágenes/Wallpapers` (SSD). `Virtualizacion` apunta al
HDD y es regenerable.

## Clasificación por disco

- **SSD:** personal/irremplazable (`Documentos`, `Proyectos`, `Archivo`, `Media`, `Juegos`).
- **HDD (`/storage/lab-hdd`, poco fiable):** solo regenerable (`Virtualizacion`, librería Steam
  secundaria, ROMs, modding). Nunca copia única.

## Reglas

- **1 proyecto = 1 repo git**; sin `.bk` (el historial está en git).
- `ordenar` solo en `Descargas` (crea carpetas por extensión; **no** usarlo en `Documentos`/`Recursos`).
- Configs gestionadas viven en el repo (`modules/home/.../dotfiles`); `~/.config` solo lo demás.

## Pendiente

- **Backups** (restic/borg) para `Archivo` (126G irremplazable), `Documentos` y `Proyectos`.
- **0 bytes**: informe y `zero/` en `~/Archivo/Personal/_recuperacion/`; 858 pendientes de recopiar.
- Terminar la migración de formatos en `Proyectos/Local/legacy-conversion` (tras backup).
- Triaje manual de `Descargas` (6,2 GB) y de `Documentos/test`.

## Acoplamientos al mover/renombrar

- La allowlist del enforcement: `users/<usuario>/home-allowlist.nix` (raíz, `config`, `share` y `state`).
- `modules/home/core/dotfiles.nix` (`xdg.userDirs`).
- `modules/home/apps/syncthing.nix` (rutas sincronizadas; ahora en `users/<usuario>`).
- `hosts/<host>/settings.nix` (`gwal.directorio`, `gnome.monitorConnector`) y `hardware-extra.nix` (montajes).
- `modules/home/apps/gta-mo.nix` (`gameRoot`) y librerías de Steam.
