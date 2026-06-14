<script lang="ts">
  import type { Settings, Inventory } from "../api";
  import { defaults } from "../api";
  import Sub from "../components/Sub.svelte";
  import Row from "../components/Row.svelte";
  import Slider from "../components/Slider.svelte";
  import Chip from "../components/Chip.svelte";

  export let s: Settings;
  export let set: (p: Partial<Settings>) => void;
  export let inv: Inventory | null = null;

  const EASINGS = ["linear","easeInQuad","easeOutQuad","easeInOutQuad","easeOutCubic","easeInOutCubic","easeOutBack"];

  $: cfg = s.pages ?? defaults.pages;
  $: enabled = new Set(cfg.enabled);

  function toggle(id: string) {
    const next = new Set(enabled);
    if (next.has(id)) next.delete(id); else next.add(id);
    set({ pages: { ...cfg, enabled: Array.from(next) } });
  }

  function setCfg(p: Partial<typeof cfg>) {
    set({ pages: { ...cfg, ...p } });
  }
</script>

<div class="section">
  <Sub num={1} title="Enabled pages" desc="Expanded view: pages available when the pill morphs into a panel.">
    {#if !inv}
      <div class="empty"><span class="spinner" /> Loading…</div>
    {:else}
      <div class="chip-list">
        {#each inv.pages as p}
          <Chip active={enabled.has(p.id)} onClick={() => toggle(p.id)}>{p.label}</Chip>
        {/each}
      </div>
    {/if}
  </Sub>

  <Sub num={2} title="Page transitions" desc="Animation used when expanding the island and switching pages.">
    <Row label="Duration">
      <Slider value={cfg.animations.duration} min={0} max={800} step={10} unit="ms"
              onChange={(v) => setCfg({ animations: { ...cfg.animations, duration: v } })} />
    </Row>
    <Row label="Easing">
      <select value={cfg.animations.easing} on:change={(e) => setCfg({ animations: { ...cfg.animations, easing: e.currentTarget.value } })}>
        {#each EASINGS as e}<option>{e}</option>{/each}
      </select>
    </Row>
  </Sub>
</div>
