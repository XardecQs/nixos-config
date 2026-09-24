# Organización de archivos

Sistema híbrido (**Modelo A**): **XDG** para las carpetas de sistema, **PARA** para documentos
activos, **por origen** para el archivo sentimental y **por tipo** para media/juegos.

## Regla de nombres

- **Carpetas de contenido** (visibles, con icono): **español natural** (Mayúscula inicial,
  tildes y espacios): `Imágenes`, `Vídeos`, `Música`, `Áreas`, `Notas`, `Grabaciones de pantalla`…
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
│   ├── Universidad/<curso>/
│   ├── Áreas/{Finanzas,Marca}/
│   ├── Recursos/<tema>/       # referencia por tema (no por formato)
│   ├── Plantillas/            # XDG templates
│   ├── Notas/                 # vault de Obsidian
│   └── Personal/
├── Media/                     # por TIPO
│   ├── Imágenes/{Capturas de pantalla,Fondos de pantalla,Fotos,...}
│   ├── Vídeos/{Grabaciones de pantalla,...}
│   ├── Música/{Álbumes,Sencillos}
│   └── Libros/  Mangas/
├── Proyectos/{GitHub,Local,Scripts}   # técnicas: ASCII
├── Juegos/
└── Archivo/                   # FRÍO
    ├── Personal/{Abuelo,Familia,Ximena,Tia}/   # sentimental por origen
    ├── Dispositivos/{PC-Infancia,Telefono}/<YYYY-MM>/
    ├── _recuperacion/         # informe 0 bytes (hasta cerrarlo)
    ├── Universidad/<año>/     # académicos terminados
    └── Propios/               # proyectos personales fríos
```

`Virtualizacion -> /storage/lab-hdd/Virtualizacion` (regenerable, en el HDD).

## Clasificación por disco

- **SSD:** personal/irremplazable (`Documentos`, `Proyectos`, `Archivo`, `Media`, `Juegos`).
- **HDD (`/storage/lab-hdd`, poco fiable):** solo regenerable (`Virtualizacion`, librería Steam
  secundaria, ROMs, modding). Nunca copia única.

## Reglas

- **1 proyecto = 1 repo git**; sin `.bk` (el historial está en git).
- `ordenar` solo en `Descargas` (crea carpetas por extensión; **no** usarlo en `Documentos`/`Recursos`).
- Configs gestionadas viven en el repo (`modules/home/.../dotfiles`); `~/.config` solo lo demás.

## Estado (2026-09)

- Reorganización a Modelo A: `Escritorio` a la raíz, `Público` desactivado, vault en
  `Documentos/Notas`, `Académicos` → `Universidad`, `Areas` → `Áreas`, `libros` → `Libros`.
- `Archivo`: `Personal` (por persona) y `Dispositivos` (backups técnicos) separados; `Tia` dentro de
  `Personal`; duplicado `papá`/`Papá` y `Grabaciones de pantalla` unificados.

## Pendiente

- **Backups** (restic/borg) para `Archivo` (126G irremplazable), `Documentos` y `Proyectos`.
- **0 bytes**: informe y `.zero` en `~/Archivo/_recuperacion/`; 858 pendientes de recopiar.
- Terminar la migración de formatos en `Proyectos/Local/legacy-conversion` (tras backup).

## Acoplamientos al mover/renombrar

- La allowlist del enforcement: `users/<usuario>/home-allowlist.nix` (**cualquier carpeta nueva en la raíz**).
- `modules/home/core/dotfiles.nix` (`xdg.userDirs`).
- `modules/home/apps/syncthing.nix` (rutas sincronizadas).
- `hosts/<host>/settings.nix` (`gwal.directorio`) y `hardware-extra.nix` (montajes).
- `modules/home/apps/gta-mo.nix` (`gameRoot`) y librerías de Steam.
