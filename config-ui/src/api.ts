const BASE = "/api";

async function j<T>(url: string, opts?: RequestInit): Promise<T> {
  const r = await fetch(BASE + url, {
    headers: { "content-type": "application/json" },
    ...opts,
  });
  if (!r.ok) throw new Error(`${r.status} ${r.statusText}`);
  return (await r.json()) as T;
}

export interface WeatherCurrent {
  icon: string;
  hex: string;
  desc: string;
  temp: string;
  feels_like: string;
  humidity: string;
  wind: string;
}

export interface WeatherData {
  current: WeatherCurrent | null;
  today: { max: string; min: string; icon: string; desc: string } | null;
}

export const api = {
  getSettings: () => j<Settings>("/settings"),
  putSettings: (s: Settings) => j<{ ok: true }>("/settings", { method: "PUT", body: JSON.stringify(s) }),
  inventory: () => j<Inventory>("/inventory"),
  keybinds: () => j<Keybind[]>("/keybinds"),
  colors: () => j<Record<string, string>>("/colors"),
  weather: () => j<WeatherData>("/weather"),
  getHyprconf: () => fetch("/api/hyprconf").then(r => r.text()),
  putHyprconf: (text: string) => j<{ ok: true }>("/hyprconf", { method: "PUT", body: JSON.stringify({ text }) }),
  reload: () => j<{ ok: true }>("/reload", { method: "POST" }),
  uninstallPlugin: (id: string) =>
    j<{ ok: boolean; output: string }>(`/plugins/${encodeURIComponent(id)}`, { method: "DELETE" }),
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
  focusRotateMs: number;
}

export interface PagesCfg {
  enabled: string[];
  animations: { duration: number; easing: string };
}

export interface ParallaxCfg {
  shift: number;        // % of screen per workspace (hyprlax --shift, default 0.3)
  duration: number;     // seconds (hyprlax --duration, default 1.0)
  easing: string;       // linear|quad|cubic|quart|quint|sine|expo|circ|back|elastic|bounce|snap
  fps: number;          // hyprlax --fps, default 60
  input: string;        // hyprlax --input, e.g. "workspace" or "cursor:0.3,workspace"
}

export const PARALLAX_EASINGS = [
  "linear","quad","cubic","quart","quint","sine","expo","circ","back","elastic","bounce","snap",
] as const;

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
  parallax?: ParallaxCfg;
  [k: string]: unknown;
}

export interface Plugin {
  id: string;
  name: string;
  version: string;
  author: string;
  description: string;
  hasWindow: boolean;
  hasBarWidget: boolean;
  hasHooks: boolean;
}

export interface Inventory {
  bubbles: { id: string; label: string }[];
  pages: { id: string; label: string }[];
  applets: { id: string; label: string }[];
  plugins: Plugin[];
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

export const defaults: Required<Pick<Settings, "theme" | "minibubbles" | "pages" | "parallax">> = {
  theme: { mode: "mocha", overrides: {} },
  minibubbles: { enabled: [], timing: { showMs: 220, hideMs: 180, easing: "easeOutCubic" }, focusRotateMs: 30000 },
  pages: { enabled: [], animations: { duration: 250, easing: "easeOutCubic" } },
  parallax: { shift: 0.3, duration: 1.0, easing: "cubic", fps: 60, input: "cursor:0.0001,workspace" },
};
