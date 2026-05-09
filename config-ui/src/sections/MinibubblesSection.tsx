import React from "react";
import { Settings, Inventory, defaults } from "../api";
import { Sub, Row, Slider } from "../components/UI";
import { Icon, BUBBLE_META } from "../components/Icon";

const EASINGS = ["linear", "easeInQuad", "easeOutQuad", "easeInOutQuad", "easeOutCubic", "easeInOutCubic", "easeOutBack"];

export function MinibubblesSection({
  s,
  set,
  inv,
}: {
  s: Settings;
  set: (p: Partial<Settings>) => void;
  inv: Inventory | null;
}) {
  const cfg = s.minibubbles ?? defaults.minibubbles;
  const setCfg = (p: Partial<typeof cfg>) => set({ minibubbles: { ...cfg, ...p } });
  const enabled = new Set(cfg.enabled);
  const toggle = (id: string) => {
    if (enabled.has(id)) enabled.delete(id);
    else enabled.add(id);
    setCfg({ enabled: Array.from(enabled) });
  };

  return (
    <div className="section">
      <Sub
        num={1}
        title="Active bubbles"
        desc="Tap to toggle. Order is determined by registration in the shell."
      >
        {!inv ? (
          <div className="empty"><span className="spinner" /> Loading…</div>
        ) : (
          <div className="bubble-list">
            {inv.bubbles.map((b) => {
              const meta = BUBBLE_META[b.id] || { label: b.label, icon: "info" };
              const on = enabled.has(b.id);
              return (
                <div
                  key={b.id}
                  className={"bubble-item" + (on ? " on" : "")}
                  onClick={() => toggle(b.id)}
                >
                  <span className="ico"><Icon name={meta.icon} size={14} /></span>
                  <div className="meta">
                    <span className="l">{meta.label}</span>
                    <span className="id">{b.id}</span>
                  </div>
                  <span className="state">{on ? "on" : "off"}</span>
                </div>
              );
            })}
          </div>
        )}
      </Sub>

      <Sub
        num={2}
        title="Animation timing"
        desc="Show / hide durations and easing curve used by BaseBubble."
      >
        <Row label="Show duration" hint="Bubble entering the stage">
          <Slider
            value={cfg.timing.showMs}
            min={0}
            max={800}
            step={10}
            unit="ms"
            onChange={(v) => setCfg({ timing: { ...cfg.timing, showMs: v } })}
          />
        </Row>
        <Row label="Hide duration" hint="Collapsing back into the pill">
          <Slider
            value={cfg.timing.hideMs}
            min={0}
            max={800}
            step={10}
            unit="ms"
            onChange={(v) => setCfg({ timing: { ...cfg.timing, hideMs: v } })}
          />
        </Row>
        <Row label="Easing" code="qt::Easing">
          <select
            value={cfg.timing.easing}
            onChange={(e) => setCfg({ timing: { ...cfg.timing, easing: e.target.value } })}
          >
            {EASINGS.map((e) => <option key={e}>{e}</option>)}
          </select>
        </Row>
      </Sub>
    </div>
  );
}
