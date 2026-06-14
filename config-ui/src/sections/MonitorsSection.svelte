<script lang="ts">
  import type { Settings, Monitor } from "../api";
  import Sub from "../components/Sub.svelte";
  import Icon from "../components/Icon.svelte";

  export let s: Settings;
  export let set: (p: Partial<Settings>) => void;

  const TRANSFORMS = [
    { v: 0, l: "Normal" }, { v: 1, l: "90°" }, { v: 2, l: "180°" }, { v: 3, l: "270°" },
    { v: 4, l: "Flipped" }, { v: 5, l: "Flipped 90°" }, { v: 6, l: "Flipped 180°" }, { v: 7, l: "Flipped 270°" },
  ];

  $: monitors = s.monitors || [];

  $: map = monitors.length ? (() => {
    const minX = Math.min(...monitors.map(m => m.x));
    const minY = Math.min(...monitors.map(m => m.y));
    const maxX = Math.max(...monitors.map(m => m.x + m.resW));
    const maxY = Math.max(...monitors.map(m => m.y + m.resH));
    return { minX, minY, w: maxX - minX, h: maxY - minY };
  })() : null;

  function update(i: number, patch: Partial<Monitor>) {
    set({ monitors: monitors.map((m, idx) => idx === i ? { ...m, ...patch } : m) });
  }
  function remove(i: number) { set({ monitors: monitors.filter((_, idx) => idx !== i) }); }
  function add() {
    set({ monitors: [...monitors, { name: `OUTPUT-${monitors.length+1}`, resW: 1920, resH: 1080, rate: 60, x: 0, y: 0, scale: 1, transform: 0 }] });
  }
</script>

<div class="section">
  <Sub num={1} title="Layout" desc="Arrangement of all outputs. Edit positions below to change.">
    <svelte:fragment slot="right">
      <button class="btn" on:click={add}><Icon name="plus" size={12} /> Add output</button>
    </svelte:fragment>

    {#if map}
      <div class="monitor-map">
        {#each monitors as m, i}
          <div
            class="display" class:primary={i===0}
            style="left:{((m.x-map.minX)/map.w)*100}%;top:{((m.y-map.minY)/map.h)*100}%;width:{(m.resW/map.w)*100}%;height:{(m.resH/map.h)*100}%;padding:8px"
          >
            <div style="text-align:center">
              <div class="n">{m.name}</div>
              <div class="res">{m.resW}×{m.resH} · {m.rate}Hz</div>
            </div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="empty">No outputs configured.</div>
    {/if}
  </Sub>

  {#each monitors as m, i}
    <div class="monitor-card">
      <div class="monitor-head">
        <div class="monitor-title">
          <span class="num">{String(i+1).padStart(2,"0")}</span>
          {#if i===0}<span class="pin" />{/if}
          {m.name}
        </div>
        <button class="btn danger" on:click={() => remove(i)}><Icon name="x" size={12} /> Remove</button>
      </div>
      <div class="monitor-grid">
        <label>Name<input type="text" value={m.name} on:input={(e) => update(i, { name: e.currentTarget.value })} /></label>
        <label>Width<input type="number" value={m.resW} on:input={(e) => update(i, { resW: +e.currentTarget.value })} /></label>
        <label>Height<input type="number" value={m.resH} on:input={(e) => update(i, { resH: +e.currentTarget.value })} /></label>
        <label>Refresh<input type="number" value={m.rate} on:input={(e) => update(i, { rate: +e.currentTarget.value })} /></label>
        <label>X<input type="number" value={m.x} on:input={(e) => update(i, { x: +e.currentTarget.value })} /></label>
        <label>Y<input type="number" value={m.y} on:input={(e) => update(i, { y: +e.currentTarget.value })} /></label>
        <label>Scale<input type="number" step="0.05" value={m.scale} on:input={(e) => update(i, { scale: +e.currentTarget.value })} /></label>
        <label>Transform
          <select value={m.transform} on:change={(e) => update(i, { transform: +e.currentTarget.value })}>
            {#each TRANSFORMS as t}<option value={t.v}>{t.l}</option>{/each}
          </select>
        </label>
      </div>
    </div>
  {/each}
</div>
