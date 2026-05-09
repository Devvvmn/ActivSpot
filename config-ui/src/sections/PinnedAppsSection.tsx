import React, { useState } from "react";
import { Settings } from "../api";
import { Sub } from "../components/UI";
import { Icon } from "../components/Icon";

export function PinnedAppsSection({ s, set }: { s: Settings; set: (p: Partial<Settings>) => void }) {
  const apps = s.pinnedApps || [];
  const [draft, setDraft] = useState("");

  const add = () => {
    const v = draft.trim();
    if (!v || apps.includes(v)) return;
    set({ pinnedApps: [...apps, v] });
    setDraft("");
  };
  const remove = (a: string) => set({ pinnedApps: apps.filter((x) => x !== a) });
  const move = (i: number, dir: -1 | 1) => {
    const j = i + dir;
    if (j < 0 || j >= apps.length) return;
    const next = apps.slice();
    [next[i], next[j]] = [next[j], next[i]];
    set({ pinnedApps: next });
  };

  return (
    <div className="section">
      <Sub
        num={1}
        title="Pinned applications"
        desc="Quick launch entries. Order is mirrored in the dock and launcher."
      >
        {apps.length === 0 ? (
          <div className="empty">No pinned apps. Add an executable name below.</div>
        ) : (
          <div className="app-list">
            {apps.map((a, i) => (
              <div key={a} className="app-row">
                <span className="num">{String(i + 1).padStart(2, "0")}</span>
                <span className="grip"><Icon name="grip" size={14} /></span>
                <span className="name">{a}</span>
                <span className="actions-mini">
                  <button className="icon-btn" disabled={i === 0} onClick={() => move(i, -1)}>
                    <Icon name="up" size={13} />
                  </button>
                  <button className="icon-btn" disabled={i === apps.length - 1} onClick={() => move(i, 1)}>
                    <Icon name="down" size={13} />
                  </button>
                  <button className="icon-btn danger" onClick={() => remove(a)}>
                    <Icon name="x" size={13} />
                  </button>
                </span>
              </div>
            ))}
          </div>
        )}
        <div className="add-app">
          <input
            type="text"
            placeholder="e.g. firefox or org.kde.dolphin"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && add()}
            style={{ minWidth: 0 }}
          />
          <button className="btn primary" onClick={add}>
            <Icon name="plus" size={12} /> Pin
          </button>
        </div>
      </Sub>
    </div>
  );
}
