#!/usr/bin/env python3
"""Backend del Command Deck: ejecuta solo acciones del catálogo."""

import json
import os
import subprocess
import sys
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
ACTIONS_FILE = os.path.join(HERE, "actions.json")
NOTIFY_SEND = os.environ.get("NOTIFY_SEND", "")
MAX_OUTPUT = 8192
write_lock = threading.Lock()
actions = {}


def emit(message):
    with write_lock:
        try:
            sys.stdout.write(json.dumps(message, ensure_ascii=False) + "\n")
            sys.stdout.flush()
        except (BrokenPipeError, OSError):
            os._exit(0)


def status(message):
    emit({"type": "event", "name": "status", "payload": {"message": str(message)}})


def log(level, message):
    emit({"type": "log", "level": level, "message": str(message)})


def load_actions():
    try:
        with open(ACTIONS_FILE, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except Exception as error:
        status(f"no se pudo leer actions.json: {error}")
        return

    if not isinstance(data, list):
        status("actions.json no es una lista")
        return

    for action in data:
        if not isinstance(action, dict):
            continue
        action_id = action.get("id")
        command = action.get("command")
        if not isinstance(action_id, str) or not isinstance(command, list):
            continue
        if not command or not all(isinstance(part, str) for part in command):
            continue
        actions[action_id] = action

    status(f"{len(actions)} acción(es) disponible(s)")


def notify(action, ok, code, output):
    if not NOTIFY_SEND or not os.path.exists(NOTIFY_SEND):
        return
    label = action.get("label", action.get("id", "acción"))
    summary = f"Command Deck: {label}"
    if ok:
        body = "Completado"
    else:
        body = f"Falló (código {code})"
    if output and not ok:
        body = f"{body}\n{output[:300]}"
    try:
        subprocess.run(
            [NOTIFY_SEND, "-a", "Command Deck", summary, body],
            timeout=2,
            check=False,
        )
    except Exception:
        pass


def execute(action):
    action_id = action.get("id", "")
    command = action.get("command")
    label = action.get("label", action_id)
    mode = action.get("mode", "background")

    if not isinstance(command, list) or not command:
        emit(
            {
                "type": "event",
                "name": "actionResult",
                "payload": {
                    "id": action_id,
                    "ok": False,
                    "code": 2,
                    "output": "Comando inválido",
                },
            }
        )
        return

    try:
        if mode == "terminal":
            subprocess.Popen(
                command,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            emit(
                {
                    "type": "event",
                    "name": "actionStarted",
                    "payload": {"id": action_id, "label": label},
                }
            )
            emit(
                {
                    "type": "event",
                    "name": "actionResult",
                    "payload": {
                        "id": action_id,
                        "ok": True,
                        "code": 0,
                        "output": "Terminal abierta",
                    },
                }
            )
            return

        process = subprocess.Popen(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            start_new_session=True,
        )
        emit(
            {
                "type": "event",
                "name": "actionStarted",
                "payload": {"id": action_id, "label": label},
            }
        )
        output, _ = process.communicate()
    except FileNotFoundError:
        result = {
            "id": action_id,
            "ok": False,
            "code": 127,
            "output": f"No se encontró el comando: {command[0]}",
        }
        emit({"type": "event", "name": "actionResult", "payload": result})
        notify(action, False, 127, result["output"])
        return
    except OSError as error:
        result = {
            "id": action_id,
            "ok": False,
            "code": 126,
            "output": str(error),
        }
        emit({"type": "event", "name": "actionResult", "payload": result})
        notify(action, False, 126, result["output"])
        return

    output = output or ""
    if len(output) > MAX_OUTPUT:
        output = output[:MAX_OUTPUT] + "\n[… salida truncada …]"

    ok = process.returncode == 0
    emit(
        {
            "type": "event",
            "name": "actionResult",
            "payload": {
                "id": action_id,
                "ok": ok,
                "code": process.returncode,
                "output": output,
            },
        }
    )
    if action.get("notify", True):
        notify(action, ok, process.returncode, output)


def handle_request(message):
    request_id = message.get("id")
    method = message.get("method")
    params = message.get("params") or {}
    result = {}
    ok = True
    error = None

    if method == "run":
        action_id = params.get("id")
        action = actions.get(action_id)
        if action is None:
            ok = False
            error = {"message": f"acción no permitida: {action_id}"}
        else:
            threading.Thread(target=execute, args=(action,), daemon=True).start()
            result = {"started": True}
    elif method == "status":
        result = {"actions": sorted(actions)}
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
    raise SystemExit(0)


def main():
    load_actions()
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
            status("listo")
        elif kind == "request":
            handle_request(message)
        elif kind == "shutdown":
            shutdown()


if __name__ == "__main__":
    main()
