import React, { useEffect, useState, useMemo } from "react";
import { api, Keybind } from "../api";
import { Sub } from "../components/UI";
import { Icon } from "../components/Icon";

export function BindingsSection() {
  const [binds, setBinds] = useState<Keybind[] | null>(null);
  const [filter, setFilter] = useState("");
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    api.keybinds().then(setBinds).catch((e) => setErr(String(e)));
  }, []);

  const filtered = useMemo(() => {
    if (!binds) return [];
    const q = filter.toLowerCase().trim();
    if (!q) return binds;
    return binds.filter((b) =>
      (b.mods + " " + b.key + " " + b.action + " " + b.args).toLowerCase().includes(q),
    );
  }, [binds, filter]);

  return (
    <div className="section">
      <Sub
        num={1}
        title="Hyprland keybindings"
        desc="Read from ~/.config/hypr/hyprland.conf. Edit the file directly — the list refreshes after save."
        right={
          <span style={{ fontSize: 10, color: "var(--ink-soft)", letterSpacing: "0.18em", textTransform: "uppercase" }}>
            <Icon name="lock" size={11} /> read-only
          </span>
        }
      >
        <div className="kb-search">
          <span className="ico"><Icon name="search" size={14} /></span>
          <input
            type="text"
            placeholder="Filter by modifier, key, or action…"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          />
        </div>

        {err && <div className="empty" style={{ color: "var(--bad)" }}>{err}</div>}
        {!binds && !err && (
          <div className="empty"><span className="spinner" /> Loading…</div>
        )}

        {binds && (
          <>
            <div className="kb-row head">
              <span>#</span>
              <span>type</span>
              <span>modifiers</span>
              <span>key</span>
              <span>action</span>
            </div>
            {filtered.map((b, i) => (
              <div key={i} className="kb-row" title={b.raw}>
                <span className="n">{String(i + 1).padStart(2, "0")}</span>
                <span className="kind">{b.kind}</span>
                <span className="mods">{b.mods || "—"}</span>
                <span><span className="key">{b.key}</span></span>
                <span className="action">
                  {b.action}
                  {b.args && <span className="args"> · {b.args}</span>}
                </span>
              </div>
            ))}
            {filtered.length === 0 && <div className="empty">Nothing matches.</div>}
          </>
        )}
      </Sub>
    </div>
  );
}
