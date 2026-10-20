#!/usr/bin/env python3
"""Puente JSONL entre DING y cava."""

import json
import os
import signal
import subprocess
import sys
import threading
import time

CAVA_BIN = os.environ.get("CAVA_BIN", "cava")
HERE = os.path.dirname(os.path.abspath(__file__))
CAVA_CONF = os.path.join(HERE, "cava.conf")

write_lock = threading.Lock()
state_lock = threading.Lock()
cava_process = None
reading = True
paused = False


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


def read_stdout(process):
    global paused
    for line in process.stdout:
        if not reading:
            break
        raw = line.strip()
        if not raw:
            continue
        parts = [part for part in raw.split(";") if part]
        bars = []
        for part in parts:
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
    if reading and not paused:
        status("cava terminó")


def read_stderr(process):
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

    threading.Thread(target=read_stdout, args=(process,), daemon=True).start()
    threading.Thread(target=read_stderr, args=(process,), daemon=True).start()
    status("cava conectado")


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
            start_cava()
        elif kind == "request":
            handle_request(message)
        elif kind == "shutdown":
            shutdown()

    shutdown()


if __name__ == "__main__":
    main()
