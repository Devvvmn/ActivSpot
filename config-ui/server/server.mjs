#!/usr/bin/env node
// Tiny zero-dep HTTP server for ActivSpot config UI.
// - Serves dist/ (built React app) when present
// - REST: /api/settings, /api/inventory, /api/reload, /api/keybinds, /api/colors
import { createServer } from "node:http";
import { readFile, writeFile, readdir, stat } from "node:fs/promises";
import { existsSync } from "node:fs";
import { extname, join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { exec } from "node:child_process";
import os from "node:os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "..");
const HYPR_DIR = resolve(ROOT, "..");
const SETTINGS = join(HYPR_DIR, "settings.json");
const QS_DIR = join(HYPR_DIR, "scripts/quickshell");
const COLORS_JSON = join(QS_DIR, "qs_colors.json");
const HYPR_CONF = join(HYPR_DIR, "hyprland.conf");
const DIST = join(ROOT, "dist");

const PORT = Number(process.env.CONFIG_UI_PORT || 7331);
const HOST = "127.0.0.1";

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".mjs": "application/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".woff2": "font/woff2",
  ".ico": "image/x-icon",
};

function send(res, status, body, headers = {}) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8", ...headers });
  res.end(typeof body === "string" ? body : JSON.stringify(body));
}

async function readJson(path, fallback = null) {
  try {
    const raw = await readFile(path, "utf8");
    return JSON.parse(raw);
  } catch {
    return fallback;
  }
}

async function listQml(dir) {
  try {
    const entries = await readdir(dir);
    return entries
      .filter((f) => f.endsWith(".qml") && f !== "qmldir")
      .map((f) => f.replace(/\.qml$/, ""));
  } catch {
    return [];
  }
}

async function inventory() {
  const [bubbles, pages, applets, plugins] = await Promise.all([
    listQml(join(QS_DIR, "minibubbles")),
    listQml(join(QS_DIR, "pages")),
    listQml(join(QS_DIR, "topbar/applets")),
    readdir(join(HYPR_DIR, "plugins")).catch(() => []),
  ]);
  // Filter out base/abstract files
  const excluded = new Set(["BaseBubble", "AppletPickerPage", "Spacer", "Separator"]);
  const stripSuffix = (s, suf) => (s.endsWith(suf) ? s.slice(0, -suf.length) : s);
  return {
    bubbles: bubbles
      .filter((b) => !excluded.has(b))
      .map((file) => ({ id: stripSuffix(file, "MiniBubble"), label: humanize(file, "MiniBubble") })),
    pages: pages
      .filter((p) => !excluded.has(p))
      .map((file) => ({ id: stripSuffix(file, "Page"), label: humanize(file, "Page") })),
    applets: applets.map((file) => ({ id: stripSuffix(file, "Applet"), label: humanize(file, "Applet") })),
    plugins: plugins.filter((p) => !p.startsWith(".")).map((id) => ({ id })),
  };
}

function humanize(name, suffix) {
  return name
    .replace(new RegExp(suffix + "$"), "")
    .replace(/([A-Z])/g, " $1")
    .trim();
}

async function parseKeybinds() {
  try {
    const raw = await readFile(HYPR_CONF, "utf8");
    const lines = raw.split("\n");
    const out = [];
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const m = line.match(/^\s*(bind[lme]?)\s*=\s*(.+)$/);
      if (!m) continue;
      const parts = m[2].split(",").map((s) => s.trim());
      if (parts.length < 3) continue;
      const [mods, key, action, ...rest] = parts;
      out.push({
        line: i + 1,
        kind: m[1],
        mods,
        key,
        action,
        args: rest.join(", "),
        raw: line,
      });
    }
    return out;
  } catch {
    return [];
  }
}

async function colorsPalette() {
  const j = await readJson(COLORS_JSON, null);
  if (!j) return null;
  return j;
}

const RELOAD_SCRIPT = join(HYPR_DIR, "scripts/qs_reload.sh");

function reloadShell() {
  return new Promise((resolve) => {
    exec(`bash ${JSON.stringify(RELOAD_SCRIPT)}`, (err, stdout) => {
      resolve({ ok: !err, output: (stdout || "").trim() });
    });
  });
}

async function readBody(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const buf = Buffer.concat(chunks);
  if (!buf.length) return null;
  try {
    return JSON.parse(buf.toString("utf8"));
  } catch {
    return null;
  }
}

async function serveStatic(req, res, urlPath) {
  if (!existsSync(DIST)) return false;
  let p = urlPath === "/" ? "/index.html" : urlPath;
  let full = join(DIST, p);
  if (!full.startsWith(DIST)) return false;
  try {
    const s = await stat(full);
    if (s.isDirectory()) full = join(full, "index.html");
  } catch {
    full = join(DIST, "index.html");
  }
  try {
    const data = await readFile(full);
    res.writeHead(200, { "content-type": MIME[extname(full)] || "application/octet-stream" });
    res.end(data);
    return true;
  } catch {
    return false;
  }
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://${HOST}`);
  const pathname = url.pathname;

  // CORS for vite dev
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  try {
    if (pathname === "/api/settings" && req.method === "GET") {
      const s = await readJson(SETTINGS, {});
      return send(res, 200, s);
    }
    if (pathname === "/api/settings" && req.method === "PUT") {
      const body = await readBody(req);
      if (!body || typeof body !== "object") return send(res, 400, { error: "invalid json" });
      const pretty = JSON.stringify(body, null, 2) + "\n";
      await writeFile(SETTINGS, pretty, "utf8");
      // Trigger Quickshell reload so changes take effect immediately
      const reload = url.searchParams.get("reload") !== "0";
      const r = reload ? await reloadShell() : null;
      return send(res, 200, { ok: true, reload: r });
    }
    if (pathname === "/api/inventory" && req.method === "GET") {
      return send(res, 200, await inventory());
    }
    if (pathname === "/api/keybinds" && req.method === "GET") {
      return send(res, 200, await parseKeybinds());
    }
    if (pathname === "/api/colors" && req.method === "GET") {
      const c = await colorsPalette();
      return send(res, 200, c || {});
    }
    if (pathname === "/api/reload" && req.method === "POST") {
      const r = await reloadShell();
      return send(res, 200, r);
    }
    if (pathname === "/api/health") {
      return send(res, 200, { ok: true, host: os.hostname(), pid: process.pid });
    }

    if (req.method === "GET") {
      const ok = await serveStatic(req, res, pathname);
      if (ok) return;
      // Fallback: tell user dev hint
      if (!existsSync(DIST)) {
        res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
        res.end(
          `<!doctype html><meta charset="utf-8"><title>ActivSpot Config</title>
           <style>body{background:#0b0d12;color:#e2e8f0;font:14px ui-sans-serif,system-ui;padding:48px;max-width:680px;margin:auto}code{background:#1e293b;padding:2px 6px;border-radius:4px}a{color:#60a5fa}</style>
           <h1>ActivSpot Config UI</h1>
           <p>The static build (<code>dist/</code>) is missing. Open the dev frontend at
           <a href="http://127.0.0.1:7332">http://127.0.0.1:7332</a>, or run:</p>
           <pre><code>cd ~/.config/hypr/config-ui &amp;&amp; npm install &amp;&amp; npm run build</code></pre>
           <p>API is up — try <a href="/api/settings">/api/settings</a>.</p>`,
        );
        return;
      }
    }
    send(res, 404, { error: "not found" });
  } catch (e) {
    send(res, 500, { error: String(e?.message || e) });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`[config-ui] listening on http://${HOST}:${PORT}`);
});
