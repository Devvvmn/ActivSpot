<script lang="ts">
  import { onMount } from "svelte";
  import type { Settings, Inventory, WeatherData } from "../api";
  import Icon from "./Icon.svelte";

  export let s: Settings;
  export let inv: Inventory | null = null;
  export let palette: Record<string, string> = {};
  export let weather: WeatherData | null = null;

  const BUBBLE_META: Record<string, { label: string; icon: string }> = {
    music:         { label: "Music",         icon: "music"   },
    notifications: { label: "Notifications", icon: "bell"    },
    weather:       { label: "Weather",       icon: "weather" },
    battery:       { label: "Battery",       icon: "battery" },
    recording:     { label: "Recording",     icon: "rec"     },
    discord:       { label: "Discord",       icon: "discord" },
    stash:         { label: "Stash",         icon: "stash"   },
    pet:           { label: "Stewart",       icon: "pet"     },
    lock:          { label: "Lock",          icon: "lock"    },
    focus:         { label: "Focus",         icon: "focus"   },
  };

  type Palette = {
    base: string; mantle: string;
    text: string; subtext0: string;
    surface0: string; surface1: string;
    mauve: string; blue: string; peach: string; green: string;
    red: string; teal: string; pink: string; yellow: string;
  };

  const THEMES: Record<string, Palette> = {
    mocha:    { base:"#1e1e2e", mantle:"#181825", text:"#cdd6f4", subtext0:"#a6adc8", surface0:"#313244", surface1:"#45475a", mauve:"#cba6f7", blue:"#89b4fa", peach:"#fab387", green:"#a6e3a1", red:"#f38ba8", teal:"#94e2d5", pink:"#f5c2e7", yellow:"#f9e2af" },
    apple:    { base:"#f5f5f7", mantle:"#ffffff",  text:"#1d1d1f", subtext0:"#6e6e73", surface0:"#ebebf0", surface1:"#d1d1d6", mauve:"#007aff", blue:"#007aff", peach:"#ff9500", green:"#34c759", red:"#ff3b30", teal:"#5ac8fa", pink:"#ff2d55", yellow:"#ffcc00" },
    nord:     { base:"#2e3440", mantle:"#272c36", text:"#eceff4", subtext0:"#d8dee9", surface0:"#3b4252", surface1:"#434c5e", mauve:"#88c0d0", blue:"#81a1c1", peach:"#d08770", green:"#a3be8c", red:"#bf616a", teal:"#8fbcbb", pink:"#b48ead", yellow:"#ebcb8b" },
    carbon:   { base:"#111111", mantle:"#1a1a1a", text:"#f5f5f5", subtext0:"#a1a1aa", surface0:"#242424", surface1:"#2e2e2e", mauve:"#d4d4d8", blue:"#60a5fa", peach:"#fdba74", green:"#86efac", red:"#fca5a5", teal:"#5eead4", pink:"#f0abfc", yellow:"#fde68a" },
    midnight: { base:"#08080f", mantle:"#0f0f1a", text:"#e2e2ff", subtext0:"#9898c8", surface0:"#16162a", surface1:"#1e1e38", mauve:"#7c7cf5", blue:"#4fc3f7", peach:"#fdba74", green:"#4ade80", red:"#f87171", teal:"#2dd4bf", pink:"#e879f9", yellow:"#fde68a" },
  };

  function resolveTheme(id: string, pal: Record<string, string>): Palette {
    if (id === "matugen" && Object.keys(pal).length > 0) {
      const fb = THEMES.mocha;
      return { base: pal.base||fb.base, mantle: pal.mantle||fb.mantle, text: pal.text||fb.text, subtext0: pal.subtext0||fb.subtext0, surface0: pal.surface0||fb.surface0, surface1: pal.surface1||fb.surface1, mauve: pal.mauve||fb.mauve, blue: pal.blue||fb.blue, peach: pal.peach||fb.peach, green: pal.green||fb.green, red: pal.red||fb.red, teal: pal.teal||fb.teal, pink: pal.pink||fb.pink, yellow: pal.yellow||fb.yellow };
    }
    return THEMES[id] ?? THEMES.mocha;
  }

  function hexToRgb(hex: string): string {
    const h = hex.replace("#", "");
    return `${parseInt(h.slice(0,2),16)},${parseInt(h.slice(2,4),16)},${parseInt(h.slice(4,6),16)}`;
  }

  let now = new Date();
  onMount(() => {
    const id = setInterval(() => (now = new Date()), 1000);
    return () => clearInterval(id);
  });

  $: time    = now.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
  $: dateStr = now.toLocaleDateString("en-GB", { weekday: "short", month: "short", day: "numeric" });
  $: themeId = s.topbarTheme || "mocha";
  $: p       = resolveTheme(themeId, palette);
  $: enabled = s.minibubbles?.enabled ?? [];
  $: stageBg = themeId === "apple" ? p.surface1 : p.base;
  $: wtemp   = weather?.current ? `${Math.round(parseFloat(weather.current.temp))}°` : null;
  $: wicon   = weather?.current?.icon ?? null;
</script>

<div class="preview-block">
  <div class="preview-head">
    <span class="label">Live preview</span>
    <span class="live"><span class="dot" />on air</span>
  </div>

  <div class="preview-stage" style="background:{stageBg}">
    <div class="stage-island" style="background:{p.mantle};color:{p.text};border:1px solid {p.surface0}">
      <div style="display:flex;flex-direction:column;align-items:flex-start;gap:0">
        <span class="clock" style="color:{p.text};font-size:15px;line-height:1.1">{time}</span>
        <span style="font-size:10px;font-weight:500;color:{p.subtext0};line-height:1.1">{dateStr}</span>
      </div>

      <span class="sep" style="height:16px;background:rgba({hexToRgb(p.text)},0.10)" />

      {#if wicon && wtemp}
        <div style="display:flex;align-items:center;gap:6px">
          <span class="nf" style="font-size:22px;color:{p.mauve};line-height:1">{wicon}</span>
          <span style="font-size:16px;font-weight:900;color:{p.peach};font-variant-numeric:tabular-nums">{wtemp}</span>
        </div>
      {:else}
        <div style="display:flex;align-items:center;gap:6px;opacity:0.3">
          <Icon name="weather" size={16} color={p.subtext0} />
          <span style="font-size:14px;font-weight:900;color:{p.subtext0}">—°</span>
        </div>
      {/if}
    </div>

    <div style="display:flex;gap:5px;margin-top:10px">
      {#each [0,1,2,3,4] as i}
        <span style="width:{i===1?16:6}px;height:3px;border-radius:99px;background:{i===1?p.mauve:p.surface0};opacity:{i===1?1:0.5}" />
      {/each}
    </div>

    <div class="preview-bubbles">
      {#each (inv?.bubbles ?? []).slice(0, 6) as b}
        {@const meta = BUBBLE_META[b.id] ?? { label: b.label, icon: "info" }}
        {@const on = enabled.includes(b.id)}
        <span
          class="preview-bubble"
          class:muted={!on}
          title={meta.label}
          style={on ? `background:${p.surface0};color:${p.subtext0};border-color:${p.surface1}` : ""}
        >
          <Icon name={meta.icon} size={11} color={on ? p.mauve : ""} />
          <span>{meta.label}</span>
        </span>
      {/each}
    </div>
  </div>

  <div class="preview-meta">
    <div class="preview-line">
      <span class="l">Theme</span>
      <span class="v" style="color:{p.mauve}">{themeId}</span>
    </div>
    <div class="preview-line">
      <span class="l">UI scale</span>
      <span class="v">×{(s.uiScale || 1).toFixed(2)}</span>
    </div>
    <div class="preview-line">
      <span class="l">Active bubbles</span>
      <span class="v">{enabled.length} / {inv?.bubbles.length ?? 0}</span>
    </div>
    <div class="preview-line">
      <span class="l">Show / hide</span>
      <span class="v">{s.minibubbles?.timing.showMs ?? 220}ms · {s.minibubbles?.timing.hideMs ?? 180}ms</span>
    </div>
    <div class="preview-line">
      <span class="l">Page transition</span>
      <span class="v">{s.pages?.animations.duration ?? 250}ms</span>
    </div>
  </div>
</div>
