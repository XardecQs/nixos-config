"use strict";

(() => {
  const elements = {
    art: document.getElementById("art"),
    fallback: document.getElementById("art-fallback"),
    title: document.getElementById("title"),
    artist: document.getElementById("artist"),
    toggle: document.getElementById("toggle"),
    prev: document.getElementById("prev"),
    next: document.getElementById("next"),
    time: document.getElementById("time"),
    progress: document.getElementById("progress-fill"),
    status: document.getElementById("status"),
    canvas: document.getElementById("spectrum"),
  };
  const context = elements.canvas.getContext("2d");

  const state = {
    accent: "#31e6ff",
    target: [],
    values: [],
    peaks: [],
    dirty: true,
    available: false,
    statusTimer: 0,
  };

  function hexToRgb(hex) {
    const value = String(hex || "").replace("#", "");
    if (value.length !== 6) return { r: 49, g: 230, b: 255 };
    return {
      r: parseInt(value.slice(0, 2), 16),
      g: parseInt(value.slice(2, 4), 16),
      b: parseInt(value.slice(4, 6), 16),
    };
  }

  function applyConfig(config) {
    if (!config || typeof config !== "object") return;
    if (typeof config.accent === "string") {
      state.accent = config.accent;
      document.documentElement.style.setProperty("--accent", config.accent);
    }
    state.dirty = true;
  }

  function showStatus(text, timeout = 0) {
    elements.status.textContent = text;
    elements.status.classList.remove("hidden");
    if (state.statusTimer) window.clearTimeout(state.statusTimer);
    if (timeout > 0) {
      state.statusTimer = window.setTimeout(() => {
        elements.status.classList.add("hidden");
      }, timeout);
    }
  }

  function formatTime(seconds) {
    const value = Number(seconds);
    if (!Number.isFinite(value) || value < 0) return "0:00";
    const minutes = Math.floor(value / 60);
    const rest = Math.floor(value % 60).toString().padStart(2, "0");
    return `${minutes}:${rest}`;
  }

  function updatePlayer(player) {
    if (!player || typeof player !== "object") return;
    const available = player.available === true;
    state.available = available;

    if (!available) {
      elements.title.textContent = "Sin reproducción";
      elements.artist.textContent = "—";
      elements.toggle.textContent = "▶";
      elements.time.textContent = "0:00 / 0:00";
      elements.progress.style.transform = "scaleX(0)";
      elements.art.classList.add("hidden");
      elements.fallback.classList.remove("hidden");
      for (const button of [elements.toggle, elements.prev, elements.next]) {
        button.disabled = true;
      }
      return;
    }

    const title = String(player.title || "").trim() || "Sin título";
    const artist = String(player.artist || "").trim() || "—";
    const album = String(player.album || "").trim();
    const label = album ? `${artist} · ${album}` : artist;
    elements.title.textContent = title;
    elements.artist.textContent = label;
    elements.toggle.textContent = player.status === "Playing" ? "⏸" : "▶";

    const length = Number(player.length) || 0;
    const position = Number(player.position) || 0;
    elements.time.textContent = `${formatTime(position)} / ${formatTime(length)}`;
    const ratio = length > 0 ? Math.min(1, Math.max(0, position / length)) : 0;
    elements.progress.style.transform = `scaleX(${ratio})`;

    if (player.artData === "") {
      elements.art.removeAttribute("src");
      elements.art.classList.add("hidden");
      elements.fallback.classList.remove("hidden");
    } else if (
      typeof player.artData === "string" &&
      player.artData.startsWith("data:image/")
    ) {
      elements.art.src = player.artData;
      elements.art.classList.remove("hidden");
      elements.fallback.classList.add("hidden");
    }

    for (const button of [elements.toggle, elements.prev, elements.next]) {
      button.disabled = false;
    }
  }

  function resize() {
    const rect = elements.canvas.getBoundingClientRect();
    const ratio = window.devicePixelRatio || 1;
    const width = Math.max(1, Math.round(rect.width * ratio));
    const height = Math.max(1, Math.round(rect.height * ratio));
    if (elements.canvas.width !== width || elements.canvas.height !== height) {
      elements.canvas.width = width;
      elements.canvas.height = height;
    }
    state.dirty = true;
  }

  function updateSpectrum(bars) {
    if (!Array.isArray(bars)) return;
    state.target = bars.map((value) => {
      const numeric = Number(value);
      return Number.isFinite(numeric) ? Math.min(1, Math.max(0, numeric)) : 0;
    });
    if (state.values.length !== state.target.length) {
      state.values = state.target.slice();
      state.peaks = state.target.slice();
    }
    state.dirty = true;
    if (state.target.some((value) => value > 0.001)) {
      elements.status.classList.add("hidden");
    }
  }

  function draw() {
    const width = elements.canvas.width;
    const height = elements.canvas.height;
    if (!width || !height) return;

    const ratio = window.devicePixelRatio || 1;
    const count = Math.max(8, state.target.length || 32);
    const gap = Math.max(1, Math.round(2 * ratio));
    const padding = Math.round(2 * ratio);
    const bottom = height - Math.round(3 * ratio);
    const usable = Math.max(1, width - padding * 2 - gap * (count - 1));
    const barWidth = Math.max(1, usable / count);

    const accent = hexToRgb(state.accent);

    context.clearRect(0, 0, width, height);
    for (let index = 0; index < count; index += 1) {
      const target = state.target[index] || 0;
      const current = state.values[index] || 0;
      const next = current + (target - current) * 0.4;
      state.values[index] = next;

      const peak = state.peaks[index] || 0;
      const nextPeak = next > peak ? next : Math.max(0, peak - 0.012);
      state.peaks[index] = nextPeak;

      const x = padding + index * (barWidth + gap);
      const barHeight = Math.max(1.5 * ratio, next * (height - 4 * ratio));
      const y = bottom - barHeight;
      const alpha = 0.22 + (index / count) * 0.7;
      context.fillStyle = `rgba(${accent.r}, ${accent.g}, ${accent.b}, ${alpha.toFixed(3)})`;
      context.fillRect(x, y, barWidth, barHeight);

      if (nextPeak > next + 0.01) {
        const peakY = bottom - Math.max(1.5 * ratio, nextPeak * (height - 4 * ratio));
        context.fillStyle = state.accent;
        context.fillRect(x, Math.max(0, peakY - 1), barWidth, 1);
      }
    }
  }

  function tick() {
    let moving = false;
    for (let index = 0; index < state.values.length; index += 1) {
      const delta = (state.target[index] || 0) - (state.values[index] || 0);
      if (Math.abs(delta) > 0.002) {
        state.values[index] += delta * 0.4;
        moving = true;
      }
      if ((state.peaks[index] || 0) > (state.values[index] || 0)) {
        state.peaks[index] = Math.max(0, state.peaks[index] - 0.012);
        moving = true;
      }
    }
    if (state.dirty || moving) {
      state.dirty = false;
      draw();
    }
    window.requestAnimationFrame(tick);
  }

  function run(method) {
    if (!state.available) return;
    window.ding?.backendRequest?.(method).catch((error) => {
      showStatus(error?.message || "Error al controlar el reproductor", 4000);
    });
  }

  elements.toggle.addEventListener("click", () => run("play-pause"));
  elements.prev.addEventListener("click", () => run("previous"));
  elements.next.addEventListener("click", () => run("next"));

  window.ding?.onBackendEvent?.((name, payload) => {
    if (name === "player") {
      updatePlayer(payload);
      return;
    }
    if (name === "spectrum") {
      updateSpectrum(payload?.bars);
      return;
    }
    if (name === "status") {
      showStatus(payload?.message || "playerctl no disponible", 0);
    }
  });

  window.ding?.onConfigChanged?.((config) => applyConfig(config));

  document.addEventListener("visibilitychange", () => {
    const method = document.hidden ? "pause" : "resume";
    window.ding?.backendRequest?.(method).catch(() => {});
  });

  const observer = new ResizeObserver(resize);
  observer.observe(elements.canvas);
  resize();
  applyConfig(null);

  window.ding
    ?.getConfig?.()
    .then((config) => applyConfig(config))
    .catch(() => {});

  window.ding?.backendRequest?.("status").catch(() => {});
  showStatus("playerctl…", 0);
  tick();
})();
