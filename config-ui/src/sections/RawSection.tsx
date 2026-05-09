import React, { useEffect, useState } from "react";
import { Settings } from "../api";
import { Sub } from "../components/UI";
import { Icon } from "../components/Icon";

export function RawSection({ s, set }: { s: Settings; set: (next: Settings) => void }) {
  const [text, setText] = useState(() => JSON.stringify(s, null, 2));
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    setText(JSON.stringify(s, null, 2));
  }, [s]);

  const apply = () => {
    try {
      const parsed = JSON.parse(text);
      setErr(null);
      set(parsed);
    } catch (e) {
      setErr(String(e));
    }
  };

  const lines = text.split("\n").length;

  return (
    <div className="section">
      <Sub
        num={1}
        title="settings.json"
        desc='Direct edit. "Apply" pushes into the draft; "Save" writes to disk.'
        right={
          <span style={{ fontSize: 10, color: "var(--ink-soft)", letterSpacing: "0.18em", textTransform: "uppercase" }}>
            {lines} lines · {text.length} chars
          </span>
        }
      >
        <div className="raw-editor">
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            spellCheck={false}
          />
          <div className="raw-foot">
            <span>
              {err ? (
                <span style={{ color: "var(--bad)" }}>⚠ {err}</span>
              ) : (
                "Valid JSON"
              )}
            </span>
            <span style={{ display: "flex", gap: 6 }}>
              <button className="btn ghost" onClick={() => setText(JSON.stringify(s, null, 2))}>
                <Icon name="discard" size={12} /> Reset
              </button>
              <button className="btn primary" onClick={apply}>
                <Icon name="check" size={12} /> Apply to draft
              </button>
            </span>
          </div>
        </div>
      </Sub>
    </div>
  );
}
