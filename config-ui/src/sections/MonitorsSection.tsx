import React, { useMemo } from "react";
import { Monitor, Settings } from "../api";
import { Sub } from "../components/UI";
import { Icon } from "../components/Icon";

const TRANSFORMS = [
  { v: 0, l: "Normal" },
  { v: 1, l: "90°" },
  { v: 2, l: "180°" },
  { v: 3, l: "270°" },
  { v: 4, l: "Flipped" },
  { v: 5, l: "Flipped 90°" },
  { v: 6, l: "Flipped 180°" },
  { v: 7, l: "Flipped 270°" },
];

export function MonitorsSection({ s, set }: { s: Settings; set: (p: Partial<Settings>) => void }) {
  const monitors = s.monitors || [];
  const update = (i: number, patch: Partial<Monitor>) =>
    set({ monitors: monitors.map((m, idx) => (idx === i ? { ...m, ...patch } : m)) });
  const remove = (i: number) =>
    set({ monitors: monitors.filter((_, idx) => idx !== i) });
  const add = () =>
    set({
      monitors: [
        ...monitors,
        { name: `OUTPUT-${monitors.length + 1}`, resW: 1920, resH: 1080, rate: 60, x: 0, y: 0, scale: 1, transform: 0 },
      ],
    });

  const map = useMemo(() => {
    if (!monitors.length) return null;
    const bx = monitors.reduce(
      (acc, m) => ({
        minX: Math.min(acc.minX, m.x),
        minY: Math.min(acc.minY, m.y),
        maxX: Math.max(acc.maxX, m.x + m.resW),
        maxY: Math.max(acc.maxY, m.y + m.resH),
      }),
      { minX: Infinity, minY: Infinity, maxX: -Infinity, maxY: -Infinity },
    );
    const w = bx.maxX - bx.minX;
    const h = bx.maxY - bx.minY;
    return { ...bx, w, h };
  }, [monitors]);

  return (
    <div className="section">
      <Sub
        num={1}
        title="Layout"
        desc="Arrangement of all outputs. Edit positions below to change."
        right={
          <button className="btn" onClick={add}>
            <Icon name="plus" size={12} /> Add output
          </button>
        }
      >
        {map ? (
          <div className="monitor-map">
            {monitors.map((m, i) => {
              const sX = (x: number) => `${((x - map.minX) / map.w) * 100}%`;
              const sY = (y: number) => `${((y - map.minY) / map.h) * 100}%`;
              const sW = `${(m.resW / map.w) * 100}%`;
              const sH = `${(m.resH / map.h) * 100}%`;
              return (
                <div
                  key={i}
                  className={"display" + (i === 0 ? " primary" : "")}
                  style={{ left: sX(m.x), top: sY(m.y), width: sW, height: sH, padding: 8 }}
                >
                  <div style={{ textAlign: "center" }}>
                    <div className="n">{m.name}</div>
                    <div className="res">{m.resW}×{m.resH} · {m.rate}Hz</div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="empty">No outputs configured.</div>
        )}
      </Sub>

      {monitors.map((m, i) => (
        <div key={i} className="monitor-card">
          <div className="monitor-head">
            <div className="monitor-title">
              <span className="num">{String(i + 1).padStart(2, "0")}</span>
              {i === 0 && <span className="pin" />}
              {m.name}
            </div>
            <button className="btn danger" onClick={() => remove(i)}>
              <Icon name="x" size={12} /> Remove
            </button>
          </div>
          <div className="monitor-grid">
            <label>Name<input type="text" value={m.name} onChange={(e) => update(i, { name: e.target.value })} /></label>
            <label>Width<input type="number" value={m.resW} onChange={(e) => update(i, { resW: +e.target.value })} /></label>
            <label>Height<input type="number" value={m.resH} onChange={(e) => update(i, { resH: +e.target.value })} /></label>
            <label>Refresh<input type="number" value={m.rate} onChange={(e) => update(i, { rate: +e.target.value })} /></label>
            <label>X<input type="number" value={m.x} onChange={(e) => update(i, { x: +e.target.value })} /></label>
            <label>Y<input type="number" value={m.y} onChange={(e) => update(i, { y: +e.target.value })} /></label>
            <label>Scale<input type="number" step="0.05" value={m.scale} onChange={(e) => update(i, { scale: +e.target.value })} /></label>
            <label>
              Transform
              <select value={m.transform} onChange={(e) => update(i, { transform: +e.target.value })}>
                {TRANSFORMS.map((t) => <option key={t.v} value={t.v}>{t.l}</option>)}
              </select>
            </label>
          </div>
        </div>
      ))}
    </div>
  );
}
