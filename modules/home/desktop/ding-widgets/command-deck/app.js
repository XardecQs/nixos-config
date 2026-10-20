"use strict";

(() => {
  const elements = {
    grid: document.getElementById("grid"),
    status: document.getElementById("status"),
    output: document.getElementById("output"),
    confirm: document.getElementById("confirm"),
    confirmTitle: document.getElementById("confirm-title"),
    confirmDescription: document.getElementById("confirm-description"),
    confirmRun: document.getElementById("confirm-run"),
    confirmCancel: document.getElementById("confirm-cancel"),
  };

  const state = {
    actions: [],
    enabled: [],
    pendingAction: null,
    busy: new Set(),
  };

  function setStatus(text) {
    elements.status.textContent = text;
  }

  function showOutput(text) {
    if (!text) {
      elements.output.classList.add("hidden");
      elements.output.textContent = "";
      return;
    }
    elements.output.textContent = text;
    elements.output.classList.remove("hidden");
  }

  function applyConfig(config) {
    if (!config || typeof config !== "object") return;
    if (Array.isArray(config.enabledActions)) {
      state.enabled = config.enabledActions.map(String);
      render();
    }
  }

  function actionById(id) {
    return state.actions.find((action) => action.id === id) || null;
  }

  function runAction(action) {
    if (!action || state.busy.has(action.id)) return;
    state.busy.add(action.id);
    state.pendingAction = null;
    elements.confirm.classList.add("hidden");
    setStatus(`ejecutando ${action.label}…`);
    if (action.showOutput) showOutput("");
    render();

    window.ding?.backendRequest?.("run", { id: action.id }).catch((error) => {
      state.busy.delete(action.id);
      setStatus(error?.message || "error al ejecutar");
      render();
    });
  }

  function requestAction(action) {
    if (!action) return;
    if (!action.confirm) {
      runAction(action);
      return;
    }
    state.pendingAction = action;
    elements.confirmTitle.textContent = action.label;
    elements.confirmDescription.textContent =
      action.description || "Esta acción modificará el sistema o tus archivos.";
    elements.confirm.classList.remove("hidden");
    elements.confirmRun.focus();
  }

  function render() {
    elements.grid.replaceChildren();
    const actions = state.actions.filter((action) => state.enabled.includes(action.id));
    if (actions.length === 0) {
      const empty = document.createElement("div");
      empty.className = "status";
      empty.textContent = "Sin acciones activas";
      elements.grid.append(empty);
      return;
    }

    for (const action of actions) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "action";
      button.title = action.description || action.label;
      button.disabled = state.busy.has(action.id);

      const glyph = document.createElement("span");
      glyph.className = "glyph";
      glyph.textContent = action.glyph || "•";

      const label = document.createElement("span");
      label.className = "label";
      label.textContent = action.label;

      button.append(glyph, label);
      button.addEventListener("click", () => requestAction(action));
      elements.grid.append(button);
    }
  }

  async function loadActions() {
    try {
      const response = await fetch("./actions.json");
      if (!response.ok) throw new Error(`actions.json: ${response.status}`);
      const actions = await response.json();
      if (Array.isArray(actions)) {
        state.actions = actions;
        render();
      }
    } catch (error) {
      setStatus("no se pudo cargar actions.json");
      window.ding?.log?.(String(error));
    }
  }

  elements.confirmCancel.addEventListener("click", () => {
    state.pendingAction = null;
    elements.confirm.classList.add("hidden");
  });

  elements.confirmRun.addEventListener("click", () => {
    if (state.pendingAction) runAction(state.pendingAction);
  });

  window.ding?.onBackendEvent?.((name, payload) => {
    if (name === "actionStarted") {
      const action = actionById(payload?.id);
      if (action) setStatus(`ejecutando ${action.label}…`);
      return;
    }
    if (name === "actionResult") {
      const action = actionById(payload?.id);
      if (action) state.busy.delete(action.id);
      const ok = payload?.ok === true;
      const code = payload?.code;
      if (action?.showOutput) {
        showOutput(payload?.output || (ok ? "Sin salida." : `Error (código ${code}).`));
      }
      setStatus(ok ? `${action?.label || "acción"} completada` : `${action?.label || "acción"} falló`);
      render();
      return;
    }
    if (name === "status") {
      setStatus(payload?.message || "listo");
    }
  });

  window.ding?.onConfigChanged?.((config) => applyConfig(config));

  window.ding
    ?.getConfig?.()
    .then((config) => applyConfig(config))
    .catch(() => {});

  loadActions();
  render();
})();
