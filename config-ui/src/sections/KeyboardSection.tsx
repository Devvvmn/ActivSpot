import React from "react";
import { Settings } from "../api";
import { Sub, Row, Chip, Toggle } from "../components/UI";

const KB_OPTIONS = [
  { v: "grp:caps_toggle",      l: "CapsLock cycles layout" },
  { v: "grp:alt_shift_toggle", l: "Alt+Shift cycles layout" },
  { v: "grp:win_space_toggle", l: "Super+Space cycles layout" },
  { v: "caps:swapescape",      l: "Swap Caps and Escape" },
  { v: "compose:ralt",         l: "Right Alt as Compose" },
  { v: "ctrl:nocaps",          l: "Caps acts as Control" },
];
const COMMON_LAYOUTS = ["us", "ru", "de", "fr", "es", "it", "ua", "pl", "gb", "cz", "sk"];

export function KeyboardSection({ s, set }: { s: Settings; set: (p: Partial<Settings>) => void }) {
  const layouts = (s.language || "").split(",").map((x) => x.trim()).filter(Boolean);
  const opts = (s.kbOptions || "").split(",").map((x) => x.trim()).filter(Boolean);

  const toggleLayout = (c: string) => {
    const next = layouts.includes(c) ? layouts.filter((x) => x !== c) : [...layouts, c];
    set({ language: next.join(",") });
  };
  const toggleOpt = (c: string) => {
    const next = opts.includes(c) ? opts.filter((x) => x !== c) : [...opts, c];
    set({ kbOptions: next.join(",") });
  };

  return (
    <div className="section">
      <Sub num={1} title="Layouts" desc="The order defines the cycle order. Tap to enable.">
        <div className="chip-list">
          {COMMON_LAYOUTS.map((c) => (
            <Chip key={c} active={layouts.includes(c)} onClick={() => toggleLayout(c)}>
              <span style={{ letterSpacing: "0.16em", textTransform: "uppercase", fontWeight: 600 }}>{c}</span>
            </Chip>
          ))}
        </div>
        <Row label="Raw value" code="hyprctl input:kb_layout">
          <input
            type="text"
            value={s.language || ""}
            onChange={(e) => set({ language: e.target.value })}
            style={{ width: 320 }}
          />
        </Row>
      </Sub>

      <Sub num={2} title="XKB options" desc="Low-level modifier behaviour.">
        {KB_OPTIONS.map((o) => (
          <Row key={o.v} label={o.l} code={o.v}>
            <Toggle on={opts.includes(o.v)} onChange={() => toggleOpt(o.v)} />
          </Row>
        ))}
        <Row label="Raw value" code="hyprctl input:kb_options">
          <input
            type="text"
            value={s.kbOptions || ""}
            onChange={(e) => set({ kbOptions: e.target.value })}
            style={{ width: 320 }}
          />
        </Row>
      </Sub>
    </div>
  );
}
