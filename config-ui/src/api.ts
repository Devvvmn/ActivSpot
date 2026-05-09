const BASE = "/api";

async function j<T>(url: string, opts?: RequestInit): Promise<T> {
  const r = await fetch(BASE + url, {
    headers: { "content-type": "application/json" },
    ...opts,
  });
  if (!r.ok) throw new Error(`${r.status} ${r.statusText}`);
  return (await r.json()) as T;
}

export const api = {
  getSettings: () => j<Settings>("/settings"),
  putSettings: (s: Settings) => j<{ ok: true }>("/settings", { method: "PUT", body: JSON.stringify(s) }),
  inventory: () => j<Inventory>("/inventory"),
  keybinds: () => j<Keybind[]>("/keybinds"),
  colors: () => j<Record<string, string>>("/colors"),
  reload: () => j<{ ok: true }>("/reload", { method: "POST" }),
};

export interface Monitor {
  name: string;
  resW: number;
  resH: number;
  rate: number;
  x: number;
  y: number;
  scale: number;
  transform: number;
}

export interface ThemeCfg {
  mode: string;
  overrides: Record<string, string>;
}

export interface BubbleCfg {
  enabled: string[];
  timing: { showMs: number; hideMs: number; easing: string };
}

export interface PagesCfg {
  enabled: string[];
  animations: { duration: number; easing: string };
}

export interface Settings {
  uiScale: number;
  openGuideAtStartup: boolean;
  topbarHelpIcon: boolean;
  wallpaperDir: string;
  language: string;
  kbOptions: string;
  topbarTheme: string;
  pinnedApps: string[];
  monitors: Monitor[];
  theme?: ThemeCfg;
  minibubbles?: BubbleCfg;
  pages?: PagesCfg;
  [k: string]: unknown;
}

export interface Inventory {
  bubbles: { id: string; label: string }[];
  pages: { id: string; label: string }[];
  applets: { id: string; label: string }[];
  plugins: { id: string }[];
}

export interface Keybind {
  line: number;
  kind: string;
  mods: string;
  key: string;
  action: string;
  args: string;
  raw: string;
}

export const defaults: Required<Pick<Settings, "theme" | "minibubbles" | "pages">> = {
  theme: { mode: "mocha", overrides: {} },
  minibubbles: { enabled: [], timing: { showMs: 220, hideMs: 180, easing: "easeOutCubic" } },
  pages: { enabled: [], animations: { duration: 250, easing: "easeOutCubic" } },
};
