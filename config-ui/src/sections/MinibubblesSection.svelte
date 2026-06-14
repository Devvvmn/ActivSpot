<script lang="ts">
  import type { Settings, Inventory } from "../api";
  import { defaults } from "../api";
  import Sub from "../components/Sub.svelte";
  import Row from "../components/Row.svelte";
  import Slider from "../components/Slider.svelte";
  import Icon from "../components/Icon.svelte";

  export let s: Settings;
  export let set: (p: Partial<Settings>) => void;
  export let inv: Inventory | null = null;

  const EASINGS = ["linear","easeInQuad","easeOutQuad","easeInOutQuad","easeOutCubic","easeInOutCubic","easeOutBack"];

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

  $: cfg = s.minibubbles ?? defaults.minibubbles;
  $: enabled = new Set(cfg.enabled);

  function toggle(id: string) {
    const next = new Set(enabled);
    if (next.has(id)) next.delete(id); else next.add(id);
    set({ minibubbles: { ...cfg, enabled: Array.from(next) } });
  }

  function setCfg(p: Partial<typeof cfg>) {
    set({ minibubbles: { ...cfg, ...p } });
  }
</script>

<div class="section">
  <Sub num={1} title="Active bubbles" desc="Tap to toggle. Order is determined by registration in the shell.">
    {#if !inv}
      <div class="empty"><span class="spinner" /> Loading…</div>
    {:else}
      <div class="bubble-list">
        {#each inv.bubbles as b}
          {@const meta = BUBBLE_META[b.id] ?? { label: b.label, icon: "info" }}
          {@const on = enabled.has(b.id)}
          <button type="button" class="bubble-item" class:on on:click={() => toggle(b.id)}>
            <span class="ico"><Icon name={meta.icon} size={14} /></span>
            <div class="meta">
              <span class="l">{meta.label}</span>
              <span class="id">{b.id}</span>
            </div>
            <span class="state">{on ? "on" : "off"}</span>
          </button>
        {/each}
      </div>
    {/if}
  </Sub>

  <Sub num={2} title="Animation timing" desc="Show / hide durations and easing curve used by BaseBubble.">
    <Row label="Show duration" hint="Bubble entering the stage">
      <Slider value={cfg.timing.showMs} min={0} max={800} step={10} unit="ms"
              onChange={(v) => setCfg({ timing: { ...cfg.timing, showMs: v } })} />
    </Row>
    <Row label="Hide duration" hint="Collapsing back into the pill">
      <Slider value={cfg.timing.hideMs} min={0} max={800} step={10} unit="ms"
              onChange={(v) => setCfg({ timing: { ...cfg.timing, hideMs: v } })} />
    </Row>
    <Row label="Easing" code="qt::Easing">
      <select value={cfg.timing.easing} on:change={(e) => setCfg({ timing: { ...cfg.timing, easing: e.currentTarget.value } })}>
        {#each EASINGS as e}<option>{e}</option>{/each}
      </select>
    </Row>
  </Sub>

  <Sub num={3} title="Focus rotation" desc="How long each bubble stays as the primary (enlarged) one before rotating to the next.">
    <Row label="Focus duration" hint="Per-bubble focus time before auto-rotation">
      <Slider
        value={Math.round((cfg.focusRotateMs ?? 30000) / 1000)}
        min={5} max={120} step={5} unit="s"
        onChange={(v) => setCfg({ focusRotateMs: v * 1000 })}
      />
    </Row>
  </Sub>
</div>
