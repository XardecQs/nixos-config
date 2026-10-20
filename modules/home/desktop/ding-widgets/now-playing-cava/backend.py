#!/usr/bin/env python3
"""Now Playing + Cava: MPRIS vía playerctl y espectro vía cava."""

import base64
import json
import mimetypes
import os
import signal
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request

CAVA_BIN = os.environ.get("CAVA_BIN", "cava")
PLAYERCTL_BIN = os.environ.get("PLAYERCTL_BIN", "playerctl")
HERE = os.path.dirname(os.path.abspath(__file__))
CAVA_CONF = os.path.join(HERE, "cava.conf")

write_lock = threading.Lock()
state_lock = threading.Lock()
cava_process = None
reading = True
paused = False
last_art_url = None
last_art_data = None
player_started = False


def emit(message):
    with write_lock:
        try:
            sys.stdout.write(json.dumps(message, ensure_ascii=False) + "\n")
            sys.stdout.flush()
        except (BrokenPipeError, OSError):
            os._exit(0)


def status(message):
    emit({"type": "event", "name": "status", "payload": {"message": message}})


def log(level, message):
    emit({"type": "log", "level": level, "message": str(message)})


def run_playerctl(*args, timeout=2):
    try:
        result = subprocess.run(
            [PLAYERCTL_BIN, *args],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError:
        raise RuntimeError("playerctl no está instalado")
    except subprocess.TimeoutExpired:
        raise RuntimeError("playerctl no respondió")
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def read_art(url):
    global last_art_data
    if not url:
        return None
    if url == last_art_url and last_art_data:
        return None
    if url.startswith("data:image/"):
        last_art_url = url
        return url

    try:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme == "file":
            path = urllib.request.url2pathname(parsed.path)
            with open(path, "rb") as handle:
                data = handle.read(3 * 1024 * 1024)
            mime = mimetypes.guess_type(path)[0] or "image/png"
        elif parsed.scheme in ("http", "https"):
            request = urllib.request.Request(
                url,
                headers={"User-Agent": "ding-now-playing/1.0"},
            )
            with urllib.request.urlopen(request, timeout=4) as response:
                data = response.read(3 * 1024 * 1024)
                mime = response.headers.get_content_type() or "image/png"
        else:
            return None
    except Exception as error:
        log("warn", f"no se pudo cargar la portada: {error}")
        return None

    if not data:
        return None
    last_art_url = url
    last_art_data = f"data:{mime};base64,{base64.b64encode(data).decode('ascii')}"
    return last_art_data


def read_player():
    global last_art_url, last_art_data
    if not os.path.exists(PLAYERCTL_BIN) and "/" in PLAYERCTL_BIN:
        return {"available": False, "reason": "playerctl no instalado"}

    try:
        status_text = run_playerctl("status")
    except RuntimeError as error:
        return {"available": False, "reason": str(error)}

    if status_text is None:
        return {"available": False}

    metadata = run_playerctl(
        "metadata",
        "--format",
        "{{title}}\t{{artist}}\t{{album}}\t{{mpris:length}}\t{{mpris:artUrl}}",
    )
    if metadata is None:
        return {"available": False}

    fields = metadata.split("\t")
    while len(fields) < 5:
        fields.append("")

    title, artist, album, length_us, art_url = fields[:5]
    try:
        length = float(length_us) / 1_000_000 if length_us else 0.0
    except ValueError:
        length = 0.0

    try:
        position = float(run_playerctl("position") or 0)
    except (ValueError, RuntimeError):
        position = 0.0

    try:
        volume = float(run_playerctl("volume") or 0)
    except (ValueError, RuntimeError):
        volume = 0.0

    player = {
        "available": True,
        "status": status_text.strip(),
        "title": title,
        "artist": artist,
        "album": album,
        "length": length,
        "position": position,
        "volume": volume,
    }
    if art_url:
        art_data = read_art(art_url)
        if art_data:
            player["artData"] = art_data
    else:
        last_art_url = None
        last_art_data = None
        player["artData"] = ""
    return player


def stop_cava():
    global cava_process
    with state_lock:
        process = cava_process
        cava_process = None
    if process is None:
        return
    try:
        if paused:
            process.send_signal(signal.SIGCONT)
    except OSError:
        pass
    try:
        process.terminate()
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        process.kill()
    except OSError:
        pass


def read_cava_stdout(process):
    for line in process.stdout:
        if not reading:
            break
        raw = line.strip()
        if not raw:
            continue
        bars = []
        for part in raw.split(";"):
            if not part:
                continue
            try:
                value = float(part) / 1000.0
            except ValueError:
                value = 0.0
            bars.append(min(1.0, max(0.0, value)))
        if bars:
            emit(
                {
                    "type": "event",
                    "name": "spectrum",
                    "payload": {"bars": bars},
                }
            )


def read_cava_stderr(process):
    for line in process.stderr:
        if not reading:
            break
        text = line.strip()
        if text:
            log("warn", f"cava: {text}")


def start_cava():
    global cava_process
    if cava_process is not None:
        return
    if not os.path.exists(CAVA_CONF):
        status(f"falta {CAVA_CONF}")
        return
    try:
        process = subprocess.Popen(
            [CAVA_BIN, "-p", CAVA_CONF],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            start_new_session=True,
        )
    except FileNotFoundError:
        status("cava no está instalado")
        return
    except OSError as error:
        status(f"no se pudo iniciar cava: {error}")
        return

    with state_lock:
        cava_process = process

    threading.Thread(target=read_cava_stdout, args=(process,), daemon=True).start()
    threading.Thread(target=read_cava_stderr, args=(process,), daemon=True).start()


def set_paused(next_paused):
    global paused
    with state_lock:
        process = cava_process
        if process is None or process.poll() is not None:
            return False
        try:
            process.send_signal(signal.SIGSTOP if next_paused else signal.SIGCONT)
        except OSError:
            return False
        paused = bool(next_paused)
        return True


def player_loop():
    while reading:
        try:
            player = read_player()
        except Exception as error:
            log("warn", f"playerctl: {error}")
            player = {"available": False}
            time.sleep(2)
            continue

        # La posición cambia cada segundo; se envía siempre el snapshot.
        emit({"type": "event", "name": "player", "payload": player})
        time.sleep(1.0)


def handle_request(message):
    request_id = message.get("id")
    method = message.get("method")
    result = {}
    ok = True
    error = None

    if method == "pause":
        set_paused(True)
    elif method == "resume":
        set_paused(False)
    elif method == "play-pause":
        run_playerctl("play-pause")
    elif method == "next":
        run_playerctl("next")
    elif method == "previous":
        run_playerctl("previous")
    elif method == "status":
        result = {"running": cava_process is not None and cava_process.poll() is None}
    else:
        ok = False
        error = {"message": f"método desconocido: {method}"}

    response = {"type": "response", "id": request_id, "ok": ok}
    if ok:
        response["result"] = result
    else:
        response["error"] = error
    emit(response)


def shutdown(*_args):
    global reading
    reading = False
    stop_cava()
    raise SystemExit(0)


def main():
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)
    status("esperando a DING")

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue

        kind = message.get("type")
        if kind == "hello":
            global player_started
            start_cava()
            if not player_started:
                player_started = True
                threading.Thread(target=player_loop, daemon=True).start()
        elif kind == "request":
            handle_request(message)
        elif kind == "shutdown":
            shutdown()

    shutdown()


if __name__ == "__main__":
    main()
