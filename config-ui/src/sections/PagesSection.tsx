import React from "react";
import { Settings, Inventory, defaults } from "../api";
import { Sub, Row, Chip, Slider } from "../components/UI";

const EASINGS = ["linear", "easeInQuad", "easeOutQuad", "easeInOutQuad", "easeOutCubic", "easeInOutCubic", "easeOutBack"];

export function PagesSection({
  s,
  set,
  inv,
}: {
  s: Settings;
  set: (p: Partial<Settings>) => void;
  inv: Inventory | null;
}) {
  const cfg = s.pages ?? defaults.pages;
  const setCfg = (p: Partial<typeof cfg>) => set({ pages: { ...cfg, ...p } });
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
        title="Enabled pages"
        desc="Expanded view: pages available when the pill morphs into a panel."
      >
        {!inv ? (
          <div className="empty"><span className="spinner" /> Loading…</div>
        ) : (
          <div className="chip-list">
            {inv.pages.map((p) => (
              <Chip key={p.id} active={enabled.has(p.id)} onClick={() => toggle(p.id)}>
                {p.label}
              </Chip>
            ))}
          </div>
        )}
      </Sub>

      <Sub
        num={2}
        title="Page transitions"
        desc="Animation used when expanding the island and switching pages."
      >
        <Row label="Duration">
          <Slider
            value={cfg.animations.duration}
            min={0}
            max={800}
            step={10}
            unit="ms"
            onChange={(v) => setCfg({ animations: { ...cfg.animations, duration: v } })}
          />
        </Row>
        <Row label="Easing">
          <select
            value={cfg.animations.easing}
            onChange={(e) => setCfg({ animations: { ...cfg.animations, easing: e.target.value } })}
          >
            {EASINGS.map((x) => <option key={x}>{x}</option>)}
          </select>
        </Row>
      </Sub>
    </div>
  );
}
