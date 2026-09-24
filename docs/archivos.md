# Organización de archivos

Esquema híbrido aplicado: **PARA** para documentos, **por origen** para el archivo
sentimental, y **por tipo** para media/juegos.

## Árbol aplicado

```
~/
├── Descargas/                 # bandeja de entrada (vaciar semanal)
├── Documentos/
│   ├── Académicos/{Informes,...}
│   ├── Areas/                 # responsabilidades continuas
│   ├── Recursos/              # referencia (pdf, jpg, escritos...)
│   ├── Obsidian/              # vault activo
│   └── Archivo/
├── Media/
│   ├── Imágenes/{Fondos,Capturas,Fotos}
│   ├── Vídeos/  Música/
│   └── Libros/{Libros,Mangas}
├── Proyectos/
│   ├── GitHub/<repo>          # repos con remoto
│   ├── Local/<proyecto>       # sin remoto (C, gta3sc, legacy-conversion)
│   └── Scripts/
├── Juegos/
│   ├── GTA/{mods,SA...}
│   ├── Minecraft/{servers,tools}
│   ├── Linux/ Windows/ ROMs/
├── Archivo/
│   ├── Personal/              # irremplazable (SSD + backup pendiente)
│   │   ├── PC-Infancia/{backup-2025-08,backup-2025-08-parte2,backup-2026-03,Renovatio,juegos}
│   │   ├── Abuelo/  Familia/  Ximena/
│   │   ├── Telefono/{2026-02,2026-07}
│   │   ├── Marca/  Notas/
│   └── GTA/                   # (se usa Juegos/GTA/mods para modding activo)
└── Virtualizacion -> /storage/lab-hdd/Virtualizacion   # movido al HDD (regenerable)
```

## Clasificación por disco

- **SSD**: todo lo personal/irremplazable (`Documentos`, `Proyectos`, `Archivo/Personal`,
  `Media`, `Juegos`).
- **HDD (`/storage/lab-hdd`, poco fiable)**: solo datos regenerables (`Virtualizacion`,
  librería Steam secundaria, ROMs, modding). Nunca copia única de algo importante.

## Reglas

- **1 proyecto = 1 repo git**; sin `.bk` (el historial está en git).
- **Sin espacios ni acentos** en rutas de código; `kebab-case`; fechas `YYYY-MM-DD`.
- **Regla de 3 cajas**: `Descargas` (hoy) → carpeta temática (activo) → `Archivo` (frío) → HDD.
- Configs gestionadas viven en el repo (`modules/home/.../dotfiles`); `~/.config` solo lo demás.

## Estado (2026-09)

Hecho: `Trastero` → `Archivo/Personal` (por origen), `Descargas` clasificado y vacío,
`Virtualizacion` movido al HDD, sueltos y duplicados consolidados, y creado
`Proyectos/Local/legacy-conversion` con inventario.

## Pendiente

- **Backups** (restic/borg) para `Archivo/Personal`, `Documentos` y `Proyectos`.
- Terminar la migración de formatos en `Proyectos/Local/legacy-conversion` y deduplicar
  originales vs convertidos (solo tras backup).
- **Archivos en 0 bytes** de la migración antigua (rsync sin verificar): 1401 recuperados
  in-place por hardlink; 858 pendientes de recopiar desde la laptop de mi hermana / USB de
  papá. Informe y `.zero` en `~/Archivo/Personal/_recuperacion/`.

## Acoplamientos al mover/renombrar

- `modules/nixos/core/persistencia.nix` (`usuario.directories`).
- `modules/home/core/dotfiles.nix` (`xdg.userDirs`).
- `modules/home/apps/syncthing.nix` (rutas sincronizadas).
- `hosts/<host>/settings.nix` (`gwal.directorio`) y `hardware-extra.nix` (montajes).
- `modules/home/apps/gta-mo.nix` (`game_root`) y librerías de Steam.
