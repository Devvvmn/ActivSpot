import React from "react";
import { Settings } from "../api";
import { Sub, Row, Toggle, Slider } from "../components/UI";
import { Icon } from "../components/Icon";

const VARIANTS = [
  { id: "mocha",     name: "Mocha",     desc: "Warm night",  colors: ["#1e1e2e", "#cba6f7", "#89b4fa", "#fab387"] },
  { id: "macchiato", name: "Macchiato", desc: "Deep steam",  colors: ["#24273a", "#c6a0f6", "#8aadf4", "#f5a97f"] },
  { id: "frappe",    name: "Frappé",    desc: "Milk coffee", colors: ["#303446", "#ca9ee6", "#8caaee", "#ef9f76"] },
  { id: "latte",     name: "Latte",     desc: "Bright day",  colors: ["#eff1f5", "#8839ef", "#1e66f5", "#fe640b"] },
];

export function ThemeSection({
  s,
  set,
  palette,
}: {
  s: Settings;
  set: (p: Partial<Settings>) => void;
  palette: Record<string, string>;
}) {
  const theme = s.theme ?? { mode: s.topbarTheme || "mocha", overrides: {} };
  const setTheme = (p: Partial<typeof theme>) => set({ theme: { ...theme, ...p } });
  const overrides = theme.overrides || {};
  const setOverride = (k: string, v: string) => {
    const next = { ...overrides };
    if (v) next[k] = v;
    else delete next[k];
    setTheme({ overrides: next });
  };

  const tokens = Object.entries(palette).filter(
    ([, v]) => typeof v === "string" && /^#[0-9a-fA-F]{3,8}$/.test(v),
  );

  return (
    <div className="section">
      <Sub
        num={1}
        title="Catppuccin flavour"
        desc="Base flavour for the top bar and panels. Matugen layers extracted colors on top in real time."
      >
        <div className="variant-grid">
          {VARIANTS.map((v) => (
            <div
              key={v.id}
              className={"variant" + (s.topbarTheme === v.id ? " active" : "")}
              onClick={() => set({ topbarTheme: v.id, theme: { ...theme, mode: v.id } })}
            >
              <div className="stripe">
                {v.colors.map((c, i) => (
                  <span key={i} style={{ background: c }} />
                ))}
              </div>
              <div className="name">{v.name}</div>
              <div className="desc">{v.desc}</div>
            </div>
          ))}
        </div>
      </Sub>

      <Sub
        num={2}
        title="Interface scale"
        desc="Global multiplier from 0.5× to 2.0×. Applies without restarting the shell."
      >
        <Row label="UI scale" code="qs.uiScale">
          <Slider
            value={+(s.uiScale ?? 1).toFixed(2)}
            min={0.5}
            max={2}
            step={0.05}
            unit="×"
            onChange={(v) => set({ uiScale: v })}
          />
        </Row>
      </Sub>

      <Sub
        num={3}
        title="Palette overrides"
        desc="Pin individual qs_colors.json tokens. Empty values fall back to matugen output."
        right={
          Object.keys(overrides).length > 0 && (
            <button className="btn ghost" onClick={() => setTheme({ overrides: {} })}>
              <Icon name="discard" size={12} /> Reset {Object.keys(overrides).length}
            </button>
          )
        }
      >
        {tokens.length === 0 ? (
          <div className="empty">qs_colors.json not detected.</div>
        ) : (
          <div className="swatch-grid">
            {tokens.map(([k, v]) => {
              const cur = overrides[k] || v;
              return (
                <label key={k} className={"swatch" + (overrides[k] ? " overridden" : "")}>
                  <input
                    type="color"
                    value={normalizeHex(cur)}
                    onChange={(e) => setOverride(k, e.target.value)}
                  />
                  <div className="swatch-meta">
                    <span className="name">{k}</span>
                    <span className="hex">{cur.toUpperCase()}</span>
                  </div>
                </label>
              );
            })}
          </div>
        )}
      </Sub>

      <Sub num={4} title="Wallpaper & startup">
        <Row label="Wallpaper directory" hint="Scanned by the wallpaper picker">
          <input
            type="text"
            value={s.wallpaperDir || ""}
            onChange={(e) => set({ wallpaperDir: e.target.value })}
            style={{ width: 320 }}
          />
        </Row>
        <Row label="Top bar help icon">
          <Toggle on={!!s.topbarHelpIcon} onChange={(v) => set({ topbarHelpIcon: v })} />
        </Row>
        <Row label="Open guide on first run">
          <Toggle on={!!s.openGuideAtStartup} onChange={(v) => set({ openGuideAtStartup: v })} />
        </Row>
      </Sub>
    </div>
  );
}

function normalizeHex(s: string): string {
  if (!s) return "#000000";
  if (s.length === 9) return s.slice(0, 7);
  if (s.length === 4) return "#" + [...s.slice(1)].map((c) => c + c).join("");
  return s;
}
