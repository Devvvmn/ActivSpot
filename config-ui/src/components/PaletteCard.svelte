<script lang="ts">
  import type { Settings } from "../api";

  export let s: Settings;
  export let palette: Record<string, string> = {};

  const THEMES: Record<string, Record<string, string>> = {
    mocha:    { mauve:"#cba6f7", blue:"#89b4fa", peach:"#fab387", green:"#a6e3a1", red:"#f38ba8", teal:"#94e2d5", pink:"#f5c2e7", yellow:"#f9e2af" },
    apple:    { mauve:"#007aff", blue:"#007aff", peach:"#ff9500", green:"#34c759", red:"#ff3b30", teal:"#5ac8fa", pink:"#ff2d55", yellow:"#ffcc00" },
    nord:     { mauve:"#88c0d0", blue:"#81a1c1", peach:"#d08770", green:"#a3be8c", red:"#bf616a", teal:"#8fbcbb", pink:"#b48ead", yellow:"#ebcb8b" },
    carbon:   { mauve:"#d4d4d8", blue:"#60a5fa", peach:"#fdba74", green:"#86efac", red:"#fca5a5", teal:"#5eead4", pink:"#f0abfc", yellow:"#fde68a" },
    midnight: { mauve:"#7c7cf5", blue:"#4fc3f7", peach:"#fdba74", green:"#4ade80", red:"#f87171", teal:"#2dd4bf", pink:"#e879f9", yellow:"#fde68a" },
  };
  const TOKENS = ["mauve","blue","peach","green","red","teal","pink","yellow"];

  $: themeId = s.topbarTheme || "mocha";
  $: overrides = s.theme?.overrides ?? {};
  // matugen uses palette from qs_colors.json; all other themes use hardcoded values
  $: flavour = themeId === "matugen"
    ? { ...THEMES.mocha, ...Object.fromEntries(Object.entries(palette).filter(([k]) => TOKENS.includes(k))) }
    : (THEMES[themeId] ?? THEMES.mocha);
</script>

<div class="preview-block">
  <div class="preview-head">
    <span class="label">Palette</span>
    <span class="live">{Object.keys(overrides).length > 0 ? `${Object.keys(overrides).length} pinned` : (s.topbarTheme || "mocha")}</span>
  </div>
  <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:1px;background:var(--hair);border:1px solid var(--hair)">
    {#each TOKENS as t}
      {@const color = overrides[t] || flavour[t]}
      <div style="height:44px;background:{color};display:flex;align-items:flex-end;padding:5px 7px;font-size:9px;color:#000;font-weight:800;letter-spacing:0.08em;text-transform:uppercase;position:relative">
        {t}
        {#if overrides[t]}
          <span style="position:absolute;top:5px;right:5px;width:5px;height:5px;border-radius:0;background:#000" />
        {/if}
      </div>
    {/each}
  </div>
</div>
