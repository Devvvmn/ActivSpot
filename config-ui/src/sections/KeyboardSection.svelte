<script lang="ts">
  import type { Settings } from "../api";
  import Sub from "../components/Sub.svelte";
  import Row from "../components/Row.svelte";
  import Toggle from "../components/Toggle.svelte";
  import Chip from "../components/Chip.svelte";

  export let s: Settings;
  export let set: (p: Partial<Settings>) => void;

  const KB_OPTIONS = [
    { v: "grp:caps_toggle",      l: "CapsLock cycles layout" },
    { v: "grp:alt_shift_toggle", l: "Alt+Shift cycles layout" },
    { v: "grp:win_space_toggle", l: "Super+Space cycles layout" },
    { v: "caps:swapescape",      l: "Swap Caps and Escape" },
    { v: "compose:ralt",         l: "Right Alt as Compose" },
    { v: "ctrl:nocaps",          l: "Caps acts as Control" },
  ];
  const COMMON_LAYOUTS = ["us","ru","de","fr","es","it","ua","pl","gb","cz","sk"];

  $: layouts = (s.language || "").split(",").map(x => x.trim()).filter(Boolean);
  $: opts    = (s.kbOptions || "").split(",").map(x => x.trim()).filter(Boolean);

  function toggleLayout(c: string) {
    const next = layouts.includes(c) ? layouts.filter(x => x !== c) : [...layouts, c];
    set({ language: next.join(",") });
  }
  function toggleOpt(c: string) {
    const next = opts.includes(c) ? opts.filter(x => x !== c) : [...opts, c];
    set({ kbOptions: next.join(",") });
  }
</script>

<div class="section">
  <Sub num={1} title="Layouts" desc="The order defines the cycle order. Tap to enable.">
    <div class="chip-list">
      {#each COMMON_LAYOUTS as c}
        <Chip active={layouts.includes(c)} onClick={() => toggleLayout(c)}>
          <span style="letter-spacing:0.16em;text-transform:uppercase;font-weight:600">{c}</span>
        </Chip>
      {/each}
    </div>
    <Row label="Raw value" code="hyprctl input:kb_layout">
      <input type="text" value={s.language || ""} on:input={(e) => set({ language: e.currentTarget.value })} style="width:320px" />
    </Row>
  </Sub>

  <Sub num={2} title="XKB options" desc="Low-level modifier behaviour.">
    {#each KB_OPTIONS as o}
      <Row label={o.l} code={o.v}>
        <Toggle checked={opts.includes(o.v)} on:change={() => toggleOpt(o.v)} />
      </Row>
    {/each}
    <Row label="Raw value" code="hyprctl input:kb_options">
      <input type="text" value={s.kbOptions || ""} on:input={(e) => set({ kbOptions: e.currentTarget.value })} style="width:320px" />
    </Row>
  </Sub>
</div>
