<script lang="ts">
  import type { Settings } from "../api";
  import Sub from "../components/Sub.svelte";
  import Icon from "../components/Icon.svelte";

  export let s: Settings;
  export let setAll: (next: Settings) => void;

  let text = JSON.stringify(s, null, 2);
  let err: string | null = null;

  $: { text = JSON.stringify(s, null, 2); }

  $: lines = text.split("\n").length;

  function apply() {
    try {
      const parsed = JSON.parse(text);
      err = null;
      setAll(parsed);
    } catch (e) {
      err = String(e);
    }
  }
</script>

<div class="section">
  <Sub num={1} title="settings.json" desc='"Apply" pushes into the draft; "Save" writes to disk.'>
    <svelte:fragment slot="right">
      <span style="font-size:10px;color:var(--ink-soft);letter-spacing:0.18em;text-transform:uppercase">
        {lines} lines · {text.length} chars
      </span>
    </svelte:fragment>
    <div class="raw-editor">
      <textarea bind:value={text} spellcheck="false" />
      <div class="raw-foot">
        <span>
          {#if err}<span style="color:var(--bad)">ERR {err}</span>{:else}Valid JSON{/if}
        </span>
        <span style="display:flex;gap:6px">
          <button class="btn ghost" on:click={() => (text = JSON.stringify(s, null, 2))}><Icon name="discard" size={12} /> Reset</button>
          <button class="btn primary" on:click={apply}><Icon name="check" size={12} /> Apply to draft</button>
        </span>
      </div>
    </div>
  </Sub>
</div>
