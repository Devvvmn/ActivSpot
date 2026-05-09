import React, { useEffect, useState } from "react";
import { Settings, Inventory } from "../api";
import { Icon, BUBBLE_META } from "./Icon";

function useNow() {
  const [t, setT] = useState(new Date());
  useEffect(() => {
    const id = setInterval(() => setT(new Date()), 1000);
    return () => clearInterval(id);
  }, []);
  return t;
}

const FLAVOURS: Record<string, Record<string, string>> = {
  mocha:     { mauve: "#cba6f7", blue: "#89b4fa", peach: "#fab387", green: "#a6e3a1", red: "#f38ba8", teal: "#94e2d5", pink: "#f5c2e7", yellow: "#f9e2af" },
  macchiato: { mauve: "#c6a0f6", blue: "#8aadf4", peach: "#f5a97f", green: "#a6da95", red: "#ed8796", teal: "#8bd5ca", pink: "#f5bde6", yellow: "#eed49f" },
  frappe:    { mauve: "#ca9ee6", blue: "#8caaee", peach: "#ef9f76", green: "#a6d189", red: "#e78284", teal: "#81c8be", pink: "#f4b8e4", yellow: "#e5c890" },
  latte:     { mauve: "#8839ef", blue: "#1e66f5", peach: "#fe640b", green: "#40a02b", red: "#d20f39", teal: "#179299", pink: "#ea76cb", yellow: "#df8e1d" },
};

export function PreviewIsland({ s, inv }: { s: Settings; inv: Inventory | null }) {
  const now = useNow();
  const time = now.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
  const enabled = s.minibubbles?.enabled ?? [];
  const variant = s.topbarTheme || "mocha";
  const variantBg: Record<string, string> = {
    mocha: "#1e1e2e", macchiato: "#24273a", frappe: "#303446", latte: "#eff1f5",
  };
  const bg = variantBg[variant] || "#1e1e2e";
  const ink = variant === "latte" ? "#4c4f69" : "#cdd6f4";

  return (
    <div className="preview-block">
      <div className="preview-head">
        <span className="label">Live preview</span>
        <span className="live"><span className="dot" />on air</span>
      </div>

      <div className="preview-stage">
        <div className="stage-island" style={{ background: bg, color: ink }}>
          <span className="clock">{time}</span>
          <span className="sep" />
          <Icon name="weather" size={13} />
          <span style={{ fontSize: 10, opacity: 0.75 }}>+18°</span>
        </div>

        <div className="preview-bubbles">
          {(inv?.bubbles ?? []).slice(0, 6).map((b) => {
            const meta = BUBBLE_META[b.id] || { label: b.label, icon: "info" };
            const on = enabled.includes(b.id);
            return (
              <span
                key={b.id}
                className={"preview-bubble" + (on ? "" : " muted")}
                title={meta.label}
              >
                <Icon name={meta.icon} size={11} />
                <span>{meta.label}</span>
              </span>
            );
          })}
        </div>
      </div>

      <div className="preview-meta">
        <div className="preview-line">
          <span className="l">Flavour</span>
          <span className="v">{variant}</span>
        </div>
        <div className="preview-line">
          <span className="l">UI scale</span>
          <span className="v">×{(s.uiScale || 1).toFixed(2)}</span>
        </div>
        <div className="preview-line">
          <span className="l">Active bubbles</span>
          <span className="v">
            {enabled.length} / {inv?.bubbles.length ?? 0}
          </span>
        </div>
        <div className="preview-line">
          <span className="l">Show / hide</span>
          <span className="v">
            {s.minibubbles?.timing.showMs ?? 220}ms · {s.minibubbles?.timing.hideMs ?? 180}ms
          </span>
        </div>
        <div className="preview-line">
          <span className="l">Page transition</span>
          <span className="v">{s.pages?.animations.duration ?? 250}ms</span>
        </div>
      </div>
    </div>
  );
}

export function PaletteCard({
  s,
  palette,
}: {
  s: Settings;
  palette: Record<string, string>;
}) {
  const overrides = s.theme?.overrides || {};
  const flavour = FLAVOURS[s.topbarTheme || "mocha"] || FLAVOURS.mocha;
  const tokens = ["mauve", "blue", "peach", "green", "red", "teal", "pink", "yellow"];
  return (
    <div className="preview-block">
      <div className="preview-head">
        <span className="label">Palette</span>
        <span className="live">
          {Object.keys(overrides).length > 0
            ? `${Object.keys(overrides).length} pinned`
            : "matugen"}
        </span>
      </div>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: 1,
          background: "var(--hair)",
          border: "1px solid var(--hair)",
        }}
      >
        {tokens.map((t) => (
          <div
            key={t}
            style={{
              height: 44,
              background: overrides[t] || palette[t] || flavour[t],
              display: "flex",
              alignItems: "flex-end",
              padding: "5px 7px",
              fontSize: 9,
              color: "rgba(0,0,0,0.65)",
              fontWeight: 600,
              letterSpacing: "0.08em",
              textTransform: "uppercase",
              position: "relative",
            }}
          >
            {t}
            {overrides[t] && (
              <span
                style={{
                  position: "absolute",
                  top: 5,
                  right: 5,
                  width: 5,
                  height: 5,
                  borderRadius: "50%",
                  background: "rgba(0,0,0,0.85)",
                }}
              />
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export function ShortcutsCard() {
  const items: [string, string][] = [
    ["Save", "⌘ S"],
    ["Discard", "⌘ Z"],
    ["Reload shell", "⌘ R"],
    ["Search bindings", "/"],
  ];
  return (
    <div className="preview-block">
      <div className="preview-head">
        <span className="label">Shortcuts</span>
      </div>
      <div style={{ display: "flex", flexDirection: "column" }}>
        {items.map(([l, k]) => (
          <div key={l} className="preview-line">
            <span className="l">{l}</span>
            <span className="kbd">{k}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
