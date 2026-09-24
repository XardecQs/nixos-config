# Organización de archivos

Esquema **híbrido**: PARA para documentos, estructura por origen para código, y por tipo
para media/juegos. Se aplica de forma gradual (fase posterior al refactor del repo).

## Árbol objetivo

```
~/
├── Descargas/            # bandeja de entrada (vaciar semanal)
├── Documentos/           # SOLO documentos (PDFs, apuntes, informes)
│   ├── Proyectos/        # PARA: cosas con fecha de fin
│   ├── Areas/            # responsabilidades continuas (universidad, finanzas)
│   ├── Recursos/         # referencia (plantillas, apuntes, libros técnicos)
│   └── Archivo/          # PARA: frío
├── Media/
│   ├── Imágenes/{Fondos,Capturas,Fotos}
│   ├── Vídeos/  Música/
│   └── Libros/{Libros,Mangas}
├── Proyectos/
│   ├── GitHub/<repo>     # solo repos con remoto
│   ├── Local/<proyecto>  # sin remoto
│   └── Recursos/         # snippets, plantillas, scripts sueltos
├── Juegos/{Linux,Windows,ROMs,Minecraft,Programas}
├── Virtualizacion/{isos,images}
└── Archivo/<año>/<tema>  # archivo frío (ex Trastero)
```

## Reglas

- **1 proyecto = 1 repo git**; nada de `.bk` (el historial está en git).
- **Sin espacios ni acentos** en rutas de código; `kebab-case`/`snake_case`; fechas `YYYY-MM-DD`.
- **Regla de 3 cajas**: `Descargas` (hoy) → carpeta temática (activo) → `Archivo` (frío) → HDD externo.
- `README.md` en carpetas importantes; en Obsidian usar tags en vez de anidar profundo.
- `~/.config` solo contiene configs gestionadas por home-manager; el resto va al repo
  (`modules/home/.../dotfiles`).

## Ajustes en el repo al migrar

- `modules/nixos/core/persistencia.nix`: `Trastero` → `Archivo` (y nuevas rutas).
- `modules/home/apps/syncthing.nix`: rutas de `Media/Libros/Mangas`, etc.
- `hosts/<host>/settings.nix`: `gwal.directorio` (ruta canónica de fondos).
- `modules/home/apps/gta-mo.nix`: `game_root` si cambia de ubicación.
