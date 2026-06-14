<script lang="ts">
  import type { Settings } from "../api";
  import Sub from "../components/Sub.svelte";
  import Row from "../components/Row.svelte";
  import Toggle from "../components/Toggle.svelte";
  import Slider from "../components/Slider.svelte";
  import Icon from "../components/Icon.svelte";

  export let s: Settings;
  export let set: (p: Partial<Settings>) => void;
  export let palette: Record<string, string> = {};

  const VARIANTS = [
    { id: "mocha",    name: "Mocha",    desc: "Warm night",      colors: ["#1e1e2e","#cba6f7","#89b4fa","#fab387"] },
    { id: "matugen", name: "Matugen",  desc: "Wallpaper tones", colors: ["#1e1e2e","#c0a8f0","#88b4f8","#f0b070"] },
    { id: "apple",   name: "Apple",    desc: "macOS light",     colors: ["#f5f5f7","#007aff","#34c759","#ff9500"] },
    { id: "nord",    name: "Nord",     desc: "Arctic blue",     colors: ["#2e3440","#88c0d0","#81a1c1","#d08770"] },
    { id: "carbon",  name: "Carbon",   desc: "Graphite dark",   colors: ["#111111","#d4d4d8","#60a5fa","#fdba74"] },
    { id: "midnight",name: "Midnight", desc: "Deep space",      colors: ["#08080f","#7c7cf5","#4fc3f7","#e879f9"] },
  ];

  $: theme = s.theme ?? { mode: s.topbarTheme || "mocha", overrides: {} };
  $: overrides = theme.overrides ?? {};

  function setOverride(k: string, v: string) {
    const next = { ...overrides };
    if (v) next[k] = v; else delete next[k];
    set({ theme: { ...theme, overrides: next } });
  }

  function normalizeHex(hex: string): string {
    if (!hex) return "#000000";
    if (hex.length === 9) return hex.slice(0, 7);
    if (hex.length === 4) return "#" + [...hex.slice(1)].map(c => c+c).join("");
    return hex;
  }

  $: tokens = Object.entries(palette).filter(([, v]) => typeof v === "string" && /^#[0-9a-fA-F]{3,8}$/.test(v));
</script>

<div class="section">
  <Sub num={1} title="Theme" desc="Active colour theme for the top bar and panels. Matugen adapts the palette to your wallpaper in real time.">
    <div class="variant-grid">
      {#each VARIANTS as v}
        <button type="button" class="variant" class:active={s.topbarTheme === v.id} on:click={() => set({ topbarTheme: v.id })}>
          <div class="stripe">
            {#each v.colors as c}<span style="background:{c}" />{/each}
          </div>
          <div class="name">{v.name}</div>
          <div class="desc">{v.desc}</div>
        </button>
      {/each}
    </div>
  </Sub>

  <Sub num={2} title="Interface scale" desc="Global multiplier from 0.5× to 2.0×. Applies without restarting the shell.">
    <Row label="UI scale" code="qs.uiScale">
      <Slider value={+(s.uiScale ?? 1).toFixed(2)} min={0.5} max={2} step={0.05} unit="×"
              onChange={(v) => set({ uiScale: v })} />
    </Row>
  </Sub>

  <Sub num={3} title="Palette overrides" desc="Pin individual qs_colors.json tokens. Empty values fall back to matugen output.">
    <svelte:fragment slot="right">
      {#if Object.keys(overrides).length > 0}
        <button class="btn ghost" on:click={() => set({ theme: { ...theme, overrides: {} } })}>
          <Icon name="discard" size={12} /> Reset {Object.keys(overrides).length}
        </button>
      {/if}
    </svelte:fragment>

    {#if tokens.length === 0}
      <div class="empty">qs_colors.json not detected.</div>
    {:else}
      <div class="swatch-grid">
        {#each tokens as [k, v]}
          {@const cur = overrides[k] || v}
          <label class="swatch" class:overridden={!!overrides[k]}>
            <input type="color" value={normalizeHex(cur)} on:change={(e) => setOverride(k, e.currentTarget.value)} />
            <div class="swatch-meta">
              <span class="name">{k}</span>
              <span class="hex">{cur.toUpperCase()}</span>
            </div>
          </label>
        {/each}
      </div>
    {/if}
  </Sub>

  <Sub num={4} title="Wallpaper & startup">
    <Row label="Wallpaper directory" hint="Scanned by the wallpaper picker">
      <input type="text" value={s.wallpaperDir || ""} on:input={(e) => set({ wallpaperDir: e.currentTarget.value })} style="width:320px" />
    </Row>
    <Row label="Show hello popup on startup" hint="Opens the onboarding screen on login">
      <Toggle checked={!!s.openGuideAtStartup} on:change={(e) => set({ openGuideAtStartup: e.detail })} />
    </Row>
  </Sub>
</div>
