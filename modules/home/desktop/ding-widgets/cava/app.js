"use strict";

(() => {
  const canvas = document.getElementById("spectrum");
  const status = document.getElementById("status");
  const context = canvas.getContext("2d");

  const state = {
    target: [],
    values: [],
    peaks: [],
    config: {
      barColor: "#31e6ff",
      barColor2: "#8a5cff",
      bgAlpha: 0.18,
      showPeaks: true,
    },
    dirty: true,
    statusTimer: 0,
  };

  function hexToRgb(hex) {
    const value = String(hex || "").replace("#", "");
    if (value.length !== 6) return null;
    return {
      r: parseInt(value.slice(0, 2), 16),
      g: parseInt(value.slice(2, 4), 16),
      b: parseInt(value.slice(4, 6), 16),
    };
  }

  function applyConfig(config) {
    if (!config || typeof config !== "object") return;
    state.config = { ...state.config, ...config };
    const alpha = Number(state.config.bgAlpha);
    document.documentElement.style.setProperty(
      "--card-alpha",
      Number.isFinite(alpha) ? String(Math.min(1, Math.max(0, alpha))) : "0.18",
    );
    document.documentElement.style.setProperty("--bar", state.config.barColor);
    document.documentElement.style.setProperty("--bar-2", state.config.barColor2);
    state.dirty = true;
  }

  function showStatus(text, timeout = 0) {
    status.textContent = text;
    status.classList.remove("hidden");
    if (state.statusTimer) window.clearTimeout(state.statusTimer);
    if (timeout > 0) {
      state.statusTimer = window.setTimeout(() => {
        status.classList.add("hidden");
      }, timeout);
    }
  }

  function resize() {
    const rect = canvas.getBoundingClientRect();
    const ratio = window.devicePixelRatio || 1;
    const width = Math.max(1, Math.round(rect.width * ratio));
    const height = Math.max(1, Math.round(rect.height * ratio));
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width;
      canvas.height = height;
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
      status.classList.add("hidden");
    }
  }

  function fillRoundedRect(x, y, width, height, radius) {
    if (typeof context.roundRect === "function") {
      context.beginPath();
      context.roundRect(x, y, width, height, radius);
      context.fill();
      return;
    }
    context.fillRect(x, y, width, height);
  }

  function draw() {
    const width = canvas.width;
    const height = canvas.height;
    if (!width || !height) return;

    const ratio = window.devicePixelRatio || 1;
    const count = Math.max(8, state.target.length || 32);
    const gap = Math.max(2, Math.round(3 * ratio));
    const padding = Math.round(14 * ratio);
    const bottom = height - Math.round(16 * ratio);
    const usable = Math.max(1, width - padding * 2 - gap * (count - 1));
    const barWidth = Math.max(1, usable / count);

    const start = hexToRgb(state.config.barColor) || { r: 49, g: 230, b: 255 };
    const end = hexToRgb(state.config.barColor2) || { r: 138, g: 92, b: 255 };

    context.clearRect(0, 0, width, height);

    for (let index = 0; index < count; index += 1) {
      const target = state.target[index] || 0;
      const current = state.values[index] || 0;
      const next = current + (target - current) * 0.38;
      state.values[index] = next;

      const peak = state.peaks[index] || 0;
      const nextPeak = next > peak ? next : Math.max(0, peak - 0.012);
      state.peaks[index] = nextPeak;

      const x = padding + index * (barWidth + gap);
      const barHeight = Math.max(2 * ratio, next * (bottom - Math.round(12 * ratio)));
      const y = bottom - barHeight;
      const mix = count <= 1 ? 0 : index / (count - 1);
      const red = Math.round(start.r + (end.r - start.r) * mix);
      const green = Math.round(start.g + (end.g - start.g) * mix);
      const blue = Math.round(start.b + (end.b - start.b) * mix);

      const gradient = context.createLinearGradient(0, bottom, 0, y);
      gradient.addColorStop(0, `rgba(${red}, ${green}, ${blue}, 0.28)`);
      gradient.addColorStop(1, `rgba(${red}, ${green}, ${blue}, 0.96)`);

      context.fillStyle = gradient;
      fillRoundedRect(x, y, barWidth, barHeight, barWidth / 2);

      if (state.config.showPeaks) {
        const peakY = bottom - Math.max(2 * ratio, nextPeak * (bottom - Math.round(12 * ratio)));
        context.fillStyle = `rgba(${red}, ${green}, ${blue}, 0.95)`;
        context.fillRect(x, Math.max(0, peakY - 1.5 * ratio), barWidth, 1.5 * ratio);
      }
    }
  }

  function tick() {
    if (state.dirty) {
      state.dirty = false;
      draw();
    } else {
      let moving = false;
      for (let index = 0; index < state.values.length; index += 1) {
        const delta = (state.target[index] || 0) - (state.values[index] || 0);
        if (Math.abs(delta) > 0.002) {
          state.values[index] += delta * 0.38;
          moving = true;
        }
        if ((state.peaks[index] || 0) > (state.values[index] || 0)) {
          state.peaks[index] = Math.max(0, state.peaks[index] - 0.012);
          moving = true;
        }
      }
      if (moving) draw();
    }
    window.requestAnimationFrame(tick);
  }

  window.ding?.onBackendEvent?.((name, payload) => {
    if (name === "spectrum") {
      updateSpectrum(payload?.bars);
      return;
    }
    if (name === "status") {
      showStatus(payload?.message || "cava no disponible", 0);
    }
  });

  window.ding?.onConfigChanged?.((config) => applyConfig(config));

  document.addEventListener("visibilitychange", () => {
    const method = document.hidden ? "pause" : "resume";
    window.ding?.backendRequest?.(method).catch(() => {});
  });

  const observer = new ResizeObserver(resize);
  observer.observe(canvas);
  resize();
  applyConfig(null);

  window.ding
    ?.getConfig?.()
    .then((config) => applyConfig(config))
    .catch(() => {});

  window.ding?.backendRequest?.("status").catch(() => {});
  showStatus("cava…", 0);
  tick();
})();
