import React from "react";

export function Toggle({ on, onChange }: { on: boolean; onChange: (v: boolean) => void }) {
  return (
    <div
      className={"toggle" + (on ? " on" : "")}
      onClick={() => onChange(!on)}
      role="switch"
      aria-checked={on}
    />
  );
}

export function Row({
  label,
  hint,
  code,
  children,
}: {
  label: React.ReactNode;
  hint?: React.ReactNode;
  code?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <div className="row">
      <div className="row-label">
        <span className="l">{label}</span>
        {hint && <span className="h">{hint}</span>}
        {code && <code>{code}</code>}
      </div>
      <div className="row-value">{children}</div>
    </div>
  );
}

export function Sub({
  num,
  title,
  desc,
  right,
  children,
}: {
  num?: number;
  title: React.ReactNode;
  desc?: React.ReactNode;
  right?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <section className="subsec">
      <div className="subsec-head">
        <div>
          <div className="subsec-title">
            {num !== undefined && <span className="num">{String(num).padStart(2, "0")}</span>}
            {title}
          </div>
          {desc && <p className="subsec-desc">{desc}</p>}
        </div>
        {right && <div>{right}</div>}
      </div>
      {children}
    </section>
  );
}

export function Chip({
  active,
  onClick,
  onRemove,
  children,
}: {
  active?: boolean;
  onClick?: () => void;
  onRemove?: () => void;
  children: React.ReactNode;
}) {
  return (
    <span className={"chip" + (active ? " active" : "")} onClick={onClick}>
      {children}
      {onRemove && (
        <span
          className="x"
          onClick={(e) => {
            e.stopPropagation();
            onRemove();
          }}
        >
          ✕
        </span>
      )}
    </span>
  );
}

export function Slider({
  value,
  min,
  max,
  step,
  unit,
  onChange,
}: {
  value: number;
  min: number;
  max: number;
  step?: number;
  unit?: string;
  onChange: (v: number) => void;
}) {
  return (
    <div className="slider-row">
      <input
        type="range"
        className="slider"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(parseFloat(e.target.value))}
      />
      <div className="val">
        {value}
        {unit && <span className="u">{unit}</span>}
      </div>
    </div>
  );
}
