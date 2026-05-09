import React, { useEffect, useMemo, useState } from "react";
import { api, Settings, Inventory } from "./api";
import { Icon } from "./components/Icon";
import { PreviewIsland, PaletteCard, ShortcutsCard } from "./components/Preview";
import { ThemeSection } from "./sections/ThemeSection";
import { MinibubblesSection } from "./sections/MinibubblesSection";
import { PagesSection } from "./sections/PagesSection";
import { MonitorsSection } from "./sections/MonitorsSection";
import { PinnedAppsSection } from "./sections/PinnedAppsSection";
import { KeyboardSection } from "./sections/KeyboardSection";
import { BindingsSection } from "./sections/BindingsSection";
import { RawSection } from "./sections/RawSection";

type Tab = "theme" | "bubbles" | "pages" | "monitors" | "pinned" | "keyboard" | "bindings" | "raw";

const NAV: { id: Tab; label: string; sub: string; icon: string }[] = [
  { id: "theme",    label: "Theme",    sub: "Catppuccin · palette",   icon: "palette" },
  { id: "bubbles",  label: "Bubbles",  sub: "Active · timing",        icon: "bubble" },
  { id: "pages",    label: "Pages",    sub: "Expanded view",          icon: "pages" },
  { id: "monitors", label: "Monitors", sub: "Resolution · scale",     icon: "monitor" },
  { id: "pinned",   label: "Apps",     sub: "Dock pins",              icon: "pin" },
  { id: "keyboard", label: "Keyboard", sub: "Layouts · XKB",          icon: "keyboard" },
  { id: "bindings", label: "Bindings", sub: "hyprland.conf",          icon: "key" },
  { id: "raw",      label: "Raw JSON", sub: "settings.json",          icon: "code" },
];

const pad = (n: number) => String(n).padStart(2, "0");

export function App() {
  const [tab, setTab] = useState<Tab>("theme");
  const [loaded, setLoaded] = useState<Settings | null>(null);
  const [draft, setDraft] = useState<Settings | null>(null);
  const [inv, setInv] = useState<Inventory | null>(null);
  const [palette, setPalette] = useState<Record<string, string>>({});
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<{ kind: "success" | "error"; msg: string } | null>(null);

  useEffect(() => {
    api.getSettings()
      .then((s) => { setLoaded(s); setDraft(s); })
      .catch((e) => setToast({ kind: "error", msg: String(e) }));
    api.inventory().then(setInv).catch(() => {});
    api.colors().then(setPalette).catch(() => {});
  }, []);

  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(null), 2400);
    return () => clearTimeout(t);
  }, [toast]);

  const dirty = useMemo(() => {
    if (!loaded || !draft) return false;
    return JSON.stringify(loaded) !== JSON.stringify(draft);
  }, [loaded, draft]);

  const set = (patch: Partial<Settings>) => setDraft((d) => (d ? { ...d, ...patch } : d));
  const setAll = (next: Settings) => setDraft(next);

  const save = async () => {
    if (!draft) return;
    setBusy(true);
    try {
      await api.putSettings(draft);
      setLoaded(draft);
      setToast({ kind: "success", msg: "settings.json written" });
    } catch (e) {
      setToast({ kind: "error", msg: String(e) });
    } finally {
      setBusy(false);
    }
  };

  const reload = async () => {
    setBusy(true);
    try {
      await api.reload();
      setToast({ kind: "success", msg: "Reload signal sent to Quickshell" });
    } catch (e) {
      setToast({ kind: "error", msg: String(e) });
    } finally {
      setBusy(false);
    }
  };

  const discard = () => loaded && setDraft(loaded);

  if (!draft) {
    return (
      <div style={{ display: "grid", placeItems: "center", height: "100vh" }}>
        <span className="spinner" />&nbsp;&nbsp;Loading settings…
      </div>
    );
  }

  const idx = NAV.findIndex((n) => n.id === tab);
  const current = NAV[idx];

  return (
    <>
      <div className="toprule">
        <div className="left">
          <span className="dot">●</span>
          <span><b>ActivSpot</b> · Configurator</span>
        </div>
        <div className="right">
          <span>~/.config/qs</span>
          <span className="ok">● live</span>
        </div>
      </div>

      <div className="app">
        <aside className="sidebar">
          <div className="brand">
            <div className="brand-mark" />
            <div>
              <div className="brand-name">ActivSpot</div>
              <div className="brand-sub">Configurator</div>
            </div>
          </div>

          <div className="nav-label">
            <span>Sections</span>
            <span className="num">{pad(NAV.length)}</span>
          </div>

          <div className="nav">
            {NAV.map((n, i) => (
              <button
                key={n.id}
                className={"nav-item" + (tab === n.id ? " active" : "")}
                onClick={() => setTab(n.id)}
              >
                <span className="ico"><Icon name={n.icon} size={14} /></span>
                <span className="label-stack">
                  <span className="l">{n.label}</span>
                  <span className="s">{n.sub}</span>
                </span>
                <span />
                <span className="num">{pad(i + 1)}</span>
              </button>
            ))}
          </div>

          <div className="sidebar-foot">
            <div className="shell-line">
              <span className="pulse" />
              <div className="meta">
                <div className="t">Quickshell</div>
                <div className="s">live · cfg ok</div>
              </div>
            </div>
            <div className="shell-foot-meta">
              <span>~/.config/qs</span>
              <span>cfg · ok</span>
            </div>
          </div>
        </aside>

        <main className="main">
          <div className="topbar">
            <div className="left">
              <div className="crumbs">
                <span className="num">{pad(idx + 1)} / {pad(NAV.length)}</span>
                <span>—</span>
                <span>Configurator</span>
                <span>›</span>
                <span className="now">{current?.label}</span>
              </div>
              <h1 className="page-title">{current?.label}</h1>
              <p className="page-sub">{current?.sub}</p>
            </div>
            <div className="actions">
              <span className={"status-pill " + (dirty ? "dirty" : "")}>
                <span className="dot" />
                <span className="label-text">{dirty ? "Unsaved" : "All saved"}</span>
              </span>
              <button className="btn" onClick={reload} disabled={busy}>
                <Icon name="refresh" size={13} /> <span className="label-text">Reload shell</span>
              </button>
              <button className="btn primary" onClick={save} disabled={!dirty || busy}>
                {busy ? <span className="spinner" /> : <Icon name="save" size={13} />}
                <span className="label-text">Save</span>
              </button>
            </div>
          </div>

          <div className="content">
            <div className="content-scroll">
              {tab === "theme"     && <ThemeSection    s={draft} set={set} palette={palette} />}
              {tab === "bubbles"   && <MinibubblesSection s={draft} set={set} inv={inv} />}
              {tab === "pages"     && <PagesSection    s={draft} set={set} inv={inv} />}
              {tab === "monitors"  && <MonitorsSection s={draft} set={set} />}
              {tab === "pinned"    && <PinnedAppsSection s={draft} set={set} />}
              {tab === "keyboard"  && <KeyboardSection s={draft} set={set} />}
              {tab === "bindings"  && <BindingsSection />}
              {tab === "raw"       && <RawSection     s={draft} set={setAll} />}
            </div>

            <div className="preview-rail">
              <PreviewIsland s={draft} inv={inv} />
              <PaletteCard s={draft} palette={palette} />
              <ShortcutsCard />
            </div>
          </div>
        </main>
      </div>

      <div className={"savedock" + (dirty ? " show" : "")}>
        <span className="dot" />
        <span className="label">
          <b>Unsaved changes</b> &nbsp;·&nbsp; draft differs from settings.json
        </span>
        <span className="grow" />
        <button className="btn ghost" onClick={discard} disabled={busy}>
          <Icon name="discard" size={13} /> Discard
        </button>
        <button className="btn primary" onClick={save} disabled={busy}>
          {busy ? <span className="spinner" /> : <Icon name="save" size={13} />}
          Save changes
        </button>
      </div>

      {toast && (
        <div className={"toast " + toast.kind}>
          <Icon
            name={toast.kind === "success" ? "check" : "x"}
            size={13}
            style={{ color: toast.kind === "success" ? "var(--good)" : "var(--bad)" }}
          />
          {toast.msg}
        </div>
      )}
    </>
  );
}
