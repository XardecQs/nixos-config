"""Convierte videos a AVIF animado para usarlos como wallpapers.

Pensado para el flujo de `wallpaper-live`: los AVIF se guardan como originales
y el helper genera WebM bajo demanda para Gnome Live Wallpaper Engine.
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

FFMPEG = os.environ.get("WALLPAPER_CONVERT_FFMPEG", "ffmpeg")
FFPROBE = os.environ.get("WALLPAPER_CONVERT_FFPROBE", "ffprobe")
VIDEO_EXTENSIONS = {".mp4", ".mkv", ".mov", ".webm", ".avi"}


def run(command):
    return subprocess.run(command, capture_output=True, text=True)


def video_files(paths, recursive):
    files = []
    for raw in paths:
        path = Path(raw).expanduser()
        if path.is_file() and path.suffix.lower() in VIDEO_EXTENSIONS:
            files.append(path)
            continue
        if not path.is_dir():
            print(f"wallpaper-convert: ignorando {raw}", file=sys.stderr)
            continue
        pattern = "**/*" if recursive else "*"
        for candidate in sorted(path.glob(pattern)):
            if candidate.is_file() and candidate.suffix.lower() in VIDEO_EXTENSIONS:
                files.append(candidate)
    return files


def frame_rate(path):
    result = run(
        [
            FFPROBE,
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=avg_frame_rate",
            "-of",
            "csv=p=0",
            str(path),
        ]
    )
    if result.returncode != 0:
        return 0.0
    value = result.stdout.strip()
    if not value:
        return 0.0
    try:
        if "/" in value:
            numerator, denominator = value.split("/", 1)
            return float(numerator) / float(denominator)
        return float(value)
    except (ValueError, ZeroDivisionError):
        return 0.0


def animated_frames(path):
    result = run(
        [
            FFPROBE,
            "-v",
            "error",
            "-select_streams",
            "v",
            "-show_entries",
            "stream=nb_frames",
            "-of",
            "csv=p=0",
            str(path),
        ]
    )
    frames = 0
    for line in result.stdout.splitlines():
        line = line.strip()
        if line.isdigit():
            frames = max(frames, int(line))
    if frames > 1:
        return frames

    # Algunos muxers no rellenan nb_frames; contar como fallback.
    result = run(
        [
            FFPROBE,
            "-v",
            "error",
            "-count_frames",
            "-select_streams",
            "v",
            "-show_entries",
            "stream=nb_read_frames",
            "-of",
            "csv=p=0",
            str(path),
        ]
    )
    for line in result.stdout.splitlines():
        line = line.strip()
        if line.isdigit():
            frames = max(frames, int(line))
    return frames


def scale_filter(max_width, max_height):
    return (
        f"scale=w='min({max_width},iw)':h='min({max_height},ih)'"
        ":force_original_aspect_ratio=decrease"
    )


def encode(source, output, crf, preset, max_width, max_height, fps_cap):
    filters = [scale_filter(max_width, max_height)]
    source_fps = frame_rate(source)
    if source_fps > fps_cap + 0.5:
        filters.insert(0, f"fps={fps_cap}")

    temporary = output.with_name(f".{output.name}.tmp")
    temporary.unlink(missing_ok=True)
    command = [
        FFMPEG,
        "-y",
        "-v",
        "error",
        "-i",
        str(source),
        "-an",
        "-vf",
        ",".join(filters),
        "-c:v",
        "libsvtav1",
        "-crf",
        str(crf),
        "-preset",
        str(preset),
        "-f",
        "avif",
        str(temporary),
    ]
    result = run(command)
    if result.returncode != 0:
        temporary.unlink(missing_ok=True)
        raise RuntimeError(result.stderr.strip() or "ffmpeg falló")

    frames = animated_frames(temporary)
    if frames <= 1:
        temporary.unlink(missing_ok=True)
        raise RuntimeError(f"el AVIF resultante no es animado (frames={frames})")

    os.replace(temporary, output)
    return frames


def unique_path(directory, name):
    candidate = directory / name
    if not candidate.exists():
        return candidate
    stem = candidate.stem
    suffix = candidate.suffix
    index = 1
    while True:
        candidate = directory / f"{stem}.{index}{suffix}"
        if not candidate.exists():
            return candidate
        index += 1


def move_original(source, backup_dir):
    backup_dir.mkdir(parents=True, exist_ok=True)
    target = unique_path(backup_dir, source.name)
    shutil.move(str(source), str(target))
    return target


def convert_one(source, args):
    output = (
        Path(args.output_dir).expanduser() / f"{source.stem}.avif"
        if args.output_dir
        else source.with_suffix(".avif")
    )

    if output.exists() and not args.force:
        print(f"OMITIDO (existe): {output.name}")
        return "skipped"

    print(f"CONV {source.name} -> {output.name}")
    if args.dry_run:
        print("  [dry-run] ffmpeg no se ejecuta")
        return "dry-run"

    output.parent.mkdir(parents=True, exist_ok=True)
    try:
        frames = encode(
            source,
            output,
            args.crf,
            args.preset,
            args.max_width,
            args.max_height,
            args.fps,
        )

        if (
            not args.no_fallback
            and output.stat().st_size >= source.stat().st_size
            and (
                args.fallback_width < args.max_width
                or args.fallback_height < args.max_height
            )
        ):
            print("  el AVIF no reduce tamaño; probando resolución de fallback")
            frames = encode(
                source,
                output,
                args.crf,
                args.preset,
                args.fallback_width,
                args.fallback_height,
                args.fps,
            )

        original_size = source.stat().st_size
        output_size = output.stat().st_size
        status = "OK" if output_size < original_size else "OK (aviso: no reduce)"
        print(
            f"  {status}: {format_size(output_size)} "
            f"de {format_size(original_size)}, {frames} frames"
        )

        if args.backup:
            destination = move_original(
                source,
                Path(args.backup_dir).expanduser()
                if args.backup_dir
                else source.parent / ".mp4-originales",
            )
            print(f"  original movido a {destination}")
        elif args.delete:
            source.unlink()
            print("  original eliminado")

        return "converted"
    except Exception as error:
        print(f"  ERROR: {error}", file=sys.stderr)
        return "failed"


def format_size(size):
    if size < 1024 * 1024:
        return f"{size / 1024:.0f} KB"
    return f"{size / 1048576:.1f} MB"


def positive_int(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("debe ser mayor que 0")
    return number


def main():
    parser = argparse.ArgumentParser(
        prog="wallpaper-convert",
        description="Convierte MP4/vídeo a AVIF animado para wallpapers.",
    )
    parser.add_argument("paths", nargs="+", help="archivos o directorios")
    parser.add_argument("-r", "--recursive", action="store_true")
    parser.add_argument("-o", "--output-dir")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--max-width", type=positive_int, default=1600)
    parser.add_argument("--max-height", type=positive_int, default=900)
    parser.add_argument("--fps", type=positive_int, default=30)
    parser.add_argument("--crf", type=int, default=35)
    parser.add_argument("--preset", type=int, default=6)
    parser.add_argument("--fallback-width", type=positive_int, default=1280)
    parser.add_argument("--fallback-height", type=positive_int, default=720)
    parser.add_argument("--no-fallback", action="store_true")
    originals = parser.add_mutually_exclusive_group()
    originals.add_argument(
        "-b",
        "--backup",
        action="store_true",
        help="mueve el original a .mp4-originales tras convertir",
    )
    originals.add_argument(
        "-d",
        "--delete",
        action="store_true",
        help="elimina el original tras convertir",
    )
    parser.add_argument("--backup-dir")
    args = parser.parse_args()

    files = video_files(args.paths, args.recursive)
    if not files:
        print("wallpaper-convert: no se encontraron vídeos", file=sys.stderr)
        return 1

    summary = {"converted": 0, "skipped": 0, "failed": 0, "dry-run": 0}
    for source in files:
        summary[convert_one(source, args)] += 1

    print(
        "Resumen: "
        f"convertidos={summary['converted']} "
        f"omitidos={summary['skipped']} "
        f"fallidos={summary['failed']} "
        f"dry-run={summary['dry-run']}"
    )
    return 0 if summary["failed"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
