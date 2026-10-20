"""Puente entre formatos animados y Gnome Live Wallpaper Engine.

GWE solo reproduce vídeo y GIF. Este helper convierte WebP/AVIF animados a
WebM (con caché), genera el thumbnail que espera GWE y activa el wallpaper.
"""

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

FFMPEG = os.environ.get("WALLPAPER_LIVE_FFMPEG", "ffmpeg")
FFPROBE = os.environ.get("WALLPAPER_LIVE_FFPROBE", "ffprobe")
DCONF = os.environ.get("WALLPAPER_LIVE_DCONF", "dconf")
GNOME_EXTENSIONS = os.environ.get("WALLPAPER_LIVE_GNOME_EXTENSIONS", "gnome-extensions")
GWE_UUID = "gnome-wallpaper-engine@gjs.com"
GWE_PATH = "/org/gnome/shell/extensions/gnome-wallpaper-engine/"
VIDEO_EXTS = {".gif", ".mp4", ".webm", ".mkv", ".mov", ".avi"}
CONVERT_EXTS = {".webp", ".avif"}
SUPPORTED_EXTS = VIDEO_EXTS | CONVERT_EXTS


def run(command, **kwargs):
    return subprocess.run(command, capture_output=True, text=True, **kwargs)


def data_home():
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))


def backgrounds_dir():
    path = data_home() / "gnome-wallpaper-engine" / "backgrounds"
    path.mkdir(parents=True, exist_ok=True)
    return path


def safe_int(value, fallback=0):
    try:
        return int(value)
    except (TypeError, ValueError):
        return fallback


def safe_float(value, fallback=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def probe_streams(path):
    result = run(
        [
            FFPROBE,
            "-v",
            "error",
            "-show_streams",
            "-show_format",
            "-of",
            "json",
            str(path),
        ]
    )
    if result.returncode != 0:
        return [], 0.0
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return [], 0.0

    format_duration = safe_float(data.get("format", {}).get("duration"))
    streams = []
    for stream in data.get("streams", []):
        if stream.get("codec_type") != "video":
            continue
        streams.append(
            {
                "index": safe_int(stream.get("index")),
                "frames": safe_int(stream.get("nb_frames")),
                "duration": safe_float(stream.get("duration"), format_duration),
            }
        )
    return streams, format_duration


def webp_frames(path):
    try:
        from PIL import Image
    except ImportError as error:
        raise RuntimeError("Pillow no está disponible") from error

    with Image.open(path) as image:
        return int(getattr(image, "n_frames", 1))


def best_stream(streams):
    if not streams:
        return {"index": 0, "frames": 0, "duration": 0.0}
    return max(streams, key=lambda item: (item["frames"], item["duration"]))


def is_animated(path):
    suffix = Path(path).suffix.lower()
    if suffix == ".webp":
        try:
            return webp_frames(path) > 1
        except Exception:
            return False
    if suffix not in SUPPORTED_EXTS:
        return False

    streams, format_duration = probe_streams(path)
    if not streams:
        return True
    best = best_stream(streams)
    return best["frames"] > 1 or max(best["duration"], format_duration) > 0.02


def managed_name(path, suffix):
    source = Path(path)
    try:
        stat = source.stat()
    except OSError:
        stat = None
    digest_source = f"{source.resolve()}:{stat.st_mtime_ns if stat else 0}:{stat.st_size if stat else 0}"
    digest = hashlib.sha256(digest_source.encode("utf-8")).hexdigest()[:12]
    stem = re.sub(r"[^A-Za-z0-9._-]+", "-", source.stem).strip("-") or "wallpaper"
    return f"live-{stem[:60]}-{digest}{suffix}"


def convert_avif(path, output):
    streams, _ = probe_streams(path)
    best = best_stream(streams)
    frames = best["frames"]
    duration = best["duration"]
    fps = 30.0
    if frames > 1 and duration > 0:
        fps = max(1.0, min(60.0, frames / duration))

    command = [
        FFMPEG,
        "-y",
        "-v",
        "error",
        "-i",
        str(path),
        "-map",
        f"0:{best['index']}",
        "-an",
        "-r",
        f"{fps:.6f}",
        "-vf",
        "scale=trunc(iw/2)*2:trunc(ih/2)*2",
        "-c:v",
        "libvpx-vp9",
        "-pix_fmt",
        "yuva420p",
        "-b:v",
        "0",
        "-crf",
        "35",
        "-row-mt",
        "1",
        "-cpu-used",
        "4",
        str(output),
    ]
    result = run(command)
    if result.returncode != 0 or not output.exists() or output.stat().st_size == 0:
        output.unlink(missing_ok=True)
        raise RuntimeError(result.stderr.strip() or "ffmpeg no pudo convertir el AVIF")


def convert_webp(path, output):
    try:
        from PIL import Image
    except ImportError as error:
        raise RuntimeError("Pillow no está disponible") from error

    with Image.open(path) as image:
        width, height = image.size
        frames = int(getattr(image, "n_frames", 1))
        command = [
            FFMPEG,
            "-y",
            "-v",
            "error",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgba",
            "-s",
            f"{width}x{height}",
            "-r",
            "30",
            "-i",
            "-",
            "-an",
            "-vf",
            "scale=trunc(iw/2)*2:trunc(ih/2)*2",
            "-c:v",
            "libvpx-vp9",
            "-pix_fmt",
            "yuva420p",
            "-b:v",
            "0",
            "-crf",
            "35",
            "-row-mt",
            "1",
            "-cpu-used",
            "4",
            str(output),
        ]
        process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )
        try:
            for index in range(frames):
                image.seek(index)
                frame = image.convert("RGBA")
                if frame.size != (width, height):
                    frame = frame.resize((width, height))
                process.stdin.write(frame.tobytes())
        finally:
            process.stdin.close()
            stderr = process.stderr.read().decode("utf-8", "replace")
            code = process.wait()

    if code != 0 or not output.exists() or output.stat().st_size == 0:
        output.unlink(missing_ok=True)
        raise RuntimeError(stderr.strip() or "ffmpeg no pudo convertir el WebP")


def make_thumbnail(video, thumbnail):
    result = run(
        [
            FFMPEG,
            "-y",
            "-v",
            "error",
            "-ss",
            "0",
            "-i",
            str(video),
            "-frames:v",
            "1",
            "-vf",
            "scale=640:-2",
            str(thumbnail),
        ]
    )
    if result.returncode != 0 or not thumbnail.exists():
        thumbnail.unlink(missing_ok=True)
        raise RuntimeError(result.stderr.strip() or "no se pudo generar el thumbnail")


def link_file(target, link):
    if link.is_symlink() or link.exists():
        if link.is_dir():
            raise RuntimeError(f"no se puede reemplazar el directorio {link}")
        link.unlink()
    os.symlink(target, link)


def set_gwe(name):
    if shutil.which(GNOME_EXTENSIONS) or Path(GNOME_EXTENSIONS).exists():
        run([GNOME_EXTENSIONS, "enable", GWE_UUID])
    run([DCONF, "write", GWE_PATH + "autostart", "true"])
    # Forzar un cambio real aunque se reaplique el mismo wallpaper. GWE
    # reinicia mpv al recibir changed::current-wallpaper.
    run([DCONF, "write", GWE_PATH + "current-wallpaper", "''"])
    time.sleep(0.2)
    result = run([DCONF, "write", GWE_PATH + "current-wallpaper", json.dumps(name)])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "dconf no pudo activar GWE")


def stop_gwe():
    if shutil.which(DCONF) or Path(DCONF).exists():
        run([DCONF, "write", GWE_PATH + "current-wallpaper", "''"])


def apply(path):
    source = Path(path).expanduser()
    if not source.is_file():
        raise RuntimeError(f"no existe el archivo: {source}")
    suffix = source.suffix.lower()
    if suffix not in SUPPORTED_EXTS:
        raise RuntimeError(f"formato no soportado: {suffix or '(sin extensión)'}")

    backgrounds = backgrounds_dir()
    if suffix in CONVERT_EXTS:
        link_suffix = ".webm"
        name = managed_name(source, link_suffix)
        target = backgrounds / name
        if not target.exists() or target.stat().st_size == 0:
            if suffix == ".avif":
                convert_avif(source, target)
            else:
                convert_webp(source, target)
    else:
        link_suffix = suffix
        name = managed_name(source, link_suffix)
        target = source.resolve()
        link = backgrounds / name
        if link != target:
            link_file(target, link)

    make_thumbnail(target, backgrounds / f"{Path(name).stem}-thumb.jpg")
    set_gwe(name)
    print(f"Wallpaper animado aplicado: {source} -> {name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--is-animated", action="store_true")
    parser.add_argument("--stop", action="store_true")
    parser.add_argument("file", nargs="?")
    args = parser.parse_args()

    if args.is_animated:
        if not args.file:
            print("falta el archivo", file=sys.stderr)
            return 2
        return 0 if is_animated(args.file) else 1

    if args.stop:
        stop_gwe()
        return 0

    if not args.file:
        parser.print_help()
        return 2

    try:
        apply(args.file)
    except Exception as error:
        print(f"wallpaper-live: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
