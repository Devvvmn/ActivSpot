<script lang="ts">
  import type { Settings, ParallaxCfg } from "../api";
  import { PARALLAX_EASINGS, defaults } from "../api";
  import Sub from "../components/Sub.svelte";
  import Row from "../components/Row.svelte";
  import Slider from "../components/Slider.svelte";
  import Chip from "../components/Chip.svelte";
  import Icon from "../components/Icon.svelte";

  export let s: Settings;
  export let set: (p: Partial<Settings>) => void;

  const INPUT_PRESETS = [
    { id: "ws",     label: "Workspace only", value: "workspace",               desc: "Shifts on workspace switch" },
    { id: "blend",  label: "Cursor + WS",    value: "cursor:0.0001,workspace", desc: "Subtle cursor drift, workspace dominant" },
    { id: "cursor", label: "Cursor heavy",   value: "cursor:0.5,workspace",    desc: "Strong cursor follow, workspace mixed" },
    { id: "window", label: "Window focus",   value: "window:0.3,workspace",    desc: "Reacts to focused window position" },
    { id: "static", label: "Static",         value: "workspace:0",             desc: "No parallax — wallpaper stays put" },
  ];

  $: p = s.parallax ?? defaults.parallax;

  function setP(patch: Partial<ParallaxCfg>) { set({ parallax: { ...p, ...patch } }); }
  function reset() { set({ parallax: defaults.parallax }); }
</script>

<div class="section">
  <Sub num={1} title="Parallax engine" desc="hyprlax parallax wallpaper daemon. Changes apply on next wallpaper switch or shell restart.">
    <svelte:fragment slot="right">
      <button class="btn ghost" on:click={reset}><Icon name="discard" size={12} /> Reset defaults</button>
    </svelte:fragment>
    <Row label="Shift amount" hint="Per-workspace shift as fraction of screen" code="hyprlax --shift">
      <Slider value={+(p.shift ?? 0.3).toFixed(2)} min={0} max={1} step={0.05} onChange={(v) => setP({ shift: v })} />
    </Row>
    <Row label="Animation duration" hint="Seconds between workspaces" code="hyprlax --duration">
      <Slider value={+(p.duration ?? 1).toFixed(2)} min={0.1} max={5} step={0.1} unit="s" onChange={(v) => setP({ duration: v })} />
    </Row>
    <Row label="Target FPS" code="hyprlax --fps">
      <Slider value={p.fps ?? 60} min={30} max={240} step={1} onChange={(v) => setP({ fps: Math.round(v) })} />
    </Row>
  </Sub>

  <Sub num={2} title="Easing curve" desc="How the wallpaper interpolates between positions.">
    <div class="row">
      <div class="row-label"><span class="l">Easing</span><code>hyprlax --easing</code></div>
      <div class="row-value" style="display:flex;flex-wrap:wrap;gap:6px">
        {#each PARALLAX_EASINGS as e}
          <Chip active={p.easing === e} onClick={() => setP({ easing: e })}>{e}</Chip>
        {/each}
      </div>
    </div>
  </Sub>

  <Sub num={3} title="Parallax inputs" desc="Which signals drive the parallax shift.">
    <div class="row">
      <div class="row-label"><span class="l">Preset</span><span class="h">Quick-pick common combinations</span></div>
      <div class="row-value" style="display:flex;flex-wrap:wrap;gap:6px">
        {#each INPUT_PRESETS as preset}
          <Chip active={p.input === preset.value} onClick={() => setP({ input: preset.value })}>{preset.label}</Chip>
        {/each}
      </div>
    </div>
    <Row label="Custom input string" code="hyprlax --input">
      <input type="text" value={p.input || ""} placeholder="cursor:0.0001,workspace"
             on:input={(e) => setP({ input: e.currentTarget.value })} style="width:320px" />
    </Row>
  </Sub>
</div>
