import React from "react";
import { Settings, ParallaxCfg, PARALLAX_EASINGS, defaults } from "../api";
import { Sub, Row, Slider, Chip } from "../components/UI";
import { Icon } from "../components/Icon";

const INPUT_PRESETS: { id: string; label: string; value: string; desc: string }[] = [
  { id: "ws",      label: "Workspace only", value: "workspace",                 desc: "Shifts on workspace switch" },
  { id: "blend",   label: "Cursor + WS",    value: "cursor:0.0001,workspace",   desc: "Subtle cursor drift, workspace dominant" },
  { id: "cursor",  label: "Cursor heavy",   value: "cursor:0.5,workspace",      desc: "Strong cursor follow, workspace mixed" },
  { id: "window",  label: "Window focus",   value: "window:0.3,workspace",      desc: "Reacts to focused window position" },
  { id: "static",  label: "Static",         value: "workspace:0",               desc: "No parallax — wallpaper stays put" },
];

export function ParallaxSection({
  s,
  set,
}: {
  s: Settings;
  set: (p: Partial<Settings>) => void;
}) {
  const p: ParallaxCfg = s.parallax ?? defaults.parallax;
  const setP = (patch: Partial<ParallaxCfg>) => set({ parallax: { ...p, ...patch } });
  const reset = () => set({ parallax: defaults.parallax });

  return (
    <div className="section">
      <Sub
        num={1}
        title="Parallax engine"
        desc="hyprlax parallax wallpaper daemon. Changes apply on next wallpaper switch or shell restart."
        right={
          <button className="btn ghost" onClick={reset}>
            <Icon name="discard" size={12} /> Reset defaults
          </button>
        }
      >
        <Row label="Shift amount" hint="Per-workspace shift as fraction of screen" code="hyprlax --shift">
          <Slider
            value={+(p.shift ?? 0.3).toFixed(2)}
            min={0}
            max={1}
            step={0.05}
            onChange={(v) => setP({ shift: v })}
          />
        </Row>

        <Row label="Animation duration" hint="Seconds between workspaces" code="hyprlax --duration">
          <Slider
            value={+(p.duration ?? 1).toFixed(2)}
            min={0.1}
            max={5}
            step={0.1}
            unit="s"
            onChange={(v) => setP({ duration: v })}
          />
        </Row>

        <Row label="Target FPS" code="hyprlax --fps">
          <Slider
            value={p.fps ?? 60}
            min={30}
            max={240}
            step={1}
            onChange={(v) => setP({ fps: Math.round(v) })}
          />
        </Row>
      </Sub>

      <Sub
        num={2}
        title="Easing curve"
        desc="How the wallpaper interpolates between positions."
      >
        <div className="row">
          <div className="row-label">
            <span className="l">Easing</span>
            <code>hyprlax --easing</code>
          </div>
          <div className="row-value" style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
            {PARALLAX_EASINGS.map((e) => (
              <Chip key={e} active={p.easing === e} onClick={() => setP({ easing: e })}>
                {e}
              </Chip>
            ))}
          </div>
        </div>
      </Sub>

      <Sub
        num={3}
        title="Parallax inputs"
        desc="Which signals drive the parallax shift. Custom syntax: comma-separated, optional weights (e.g. cursor:0.3,workspace)."
      >
        <div className="row">
          <div className="row-label">
            <span className="l">Preset</span>
            <span className="h">Quick-pick common combinations</span>
          </div>
          <div className="row-value" style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
            {INPUT_PRESETS.map((preset) => (
              <Chip
                key={preset.id}
                active={p.input === preset.value}
                onClick={() => setP({ input: preset.value })}
              >
                {preset.label}
              </Chip>
            ))}
          </div>
        </div>

        <Row label="Custom input string" code="hyprlax --input">
          <input
            type="text"
            value={p.input || ""}
            placeholder="cursor:0.0001,workspace"
            onChange={(e) => setP({ input: e.target.value })}
            style={{ width: 320 }}
          />
        </Row>
      </Sub>
    </div>
  );
}
