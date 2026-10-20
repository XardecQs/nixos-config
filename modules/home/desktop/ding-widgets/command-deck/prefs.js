"use strict";

(() => {
  const list = document.getElementById("list");
  const status = document.getElementById("status");

  const state = {
    actions: [],
    config: {},
    enabled: [],
    hasEnabledConfig: false,
  };

  function setStatus(text) {
    status.textContent = text;
  }

  function save() {
    const next = { ...state.config, enabledActions: state.enabled };
    state.config = next;
    state.hasEnabledConfig = true;
    window.ding?.saveConfig?.(next);
    setStatus("guardado");
  }

  function render() {
    list.replaceChildren();
    if (state.actions.length === 0) {
      setStatus("no hay acciones en el catálogo");
      return;
    }

    for (const action of state.actions) {
      const item = document.createElement("label");
      item.className = "item";

      const input = document.createElement("input");
      input.type = "checkbox";
      input.checked = state.enabled.includes(action.id);
      input.addEventListener("change", () => {
        if (input.checked) {
          if (!state.enabled.includes(action.id)) state.enabled.push(action.id);
        } else {
          state.enabled = state.enabled.filter((id) => id !== action.id);
        }
        save();
      });

      const text = document.createElement("span");
      text.className = "text";

      const label = document.createElement("span");
      label.className = "label";
      label.textContent = `${action.glyph || "•"} ${action.label}`;

      const description = document.createElement("span");
      description.className = "description";
      description.textContent = action.description || action.command?.join(" ") || "";

      text.append(label, description);
      item.append(input, text);
      list.append(item);
    }
    setStatus(`${state.enabled.length} activa(s)`);
  }

  async function load() {
    try {
      const response = await fetch("./actions.json");
      if (!response.ok) throw new Error(`actions.json: ${response.status}`);
      const actions = await response.json();
      if (Array.isArray(actions)) state.actions = actions;
    } catch (error) {
      setStatus("no se pudo cargar actions.json");
      window.ding?.log?.(String(error));
      return;
    }

    try {
      const config = await window.ding?.getConfig?.();
      if (config && typeof config === "object") {
        state.config = config;
        if (Array.isArray(config.enabledActions)) {
          state.enabled = config.enabledActions.map(String);
          state.hasEnabledConfig = true;
        }
      }
    } catch (error) {
      window.ding?.log?.(String(error));
    }

    if (!state.hasEnabledConfig) {
      try {
        const response = await fetch("./widget.json");
        if (response.ok) {
          const manifest = await response.json();
          const defaults = manifest?.defaultConfig?.enabledActions;
          if (Array.isArray(defaults)) {
            state.enabled = defaults.map(String);
            state.hasEnabledConfig = true;
          }
        }
      } catch (error) {
        window.ding?.log?.(String(error));
      }
    }

    if (!state.hasEnabledConfig) {
      state.enabled = state.actions.map((action) => action.id);
    }
    render();
  }

  window.ding?.onConfigChanged?.((config) => {
    if (!config || typeof config !== "object") return;
    state.config = config;
    if (Array.isArray(config.enabledActions)) {
      state.enabled = config.enabledActions.map(String);
      state.hasEnabledConfig = true;
      render();
    }
  });

  load();
})();
