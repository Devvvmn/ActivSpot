<script lang="ts">
  import { onMount } from "svelte";
  import { api, type Keybind } from "../api";
  import Sub from "../components/Sub.svelte";
  import Icon from "../components/Icon.svelte";

  const KINDS = ["bind", "bindl", "bindle", "binde", "bindm", "bindr"];

  let binds: Keybind[] | null = null;
  let filter = "";
  let err: string | null = null;
  let busy = false;
  let saveOk = false;

  let modified = new Map<number, { mods: string; key: string }>();
  // null = not recording, number = editing existing, "new" = recording for new bind
  let recording: number | "new" | null = null;

  const ALL_MODS = ["SUPER", "CTRL", "SHIFT", "ALT"];

  type NewBind = { kind: string; mods: string[]; key: string; action: string; args: string };
  let adding = false;
  let newBind: NewBind = { kind: "bind", mods: [], key: "", action: "", args: "" };
  let recordingKey = false; // true = capturing only the key for newBind

  const KEY_MAP: Record<string, string> = {
    "Enter":"Return"," ":"space","Escape":"escape","Tab":"Tab",
    "Backspace":"BackSpace","Delete":"Delete",
    "ArrowUp":"Up","ArrowDown":"Down","ArrowLeft":"Left","ArrowRight":"Right",
    "Home":"Home","End":"End","PageUp":"Prior","PageDown":"Next",
    ...Object.fromEntries(Array.from({length:12},(_,i)=>[`F${i+1}`,`F${i+1}`])),
  };

  onMount(() => {
    api.keybinds().then(b => (binds = b)).catch(e => (err = String(e)));
  });

  $: dirty = modified.size > 0;

  $: filtered = (() => {
    if (!binds) return [] as (Keybind & { _i: number })[];
    const q = filter.toLowerCase().trim();
    return binds
      .map((b, i) => ({ ...b, _i: i }))
      .filter(b => !q || (b.mods + " " + b.key + " " + b.action + " " + b.args).toLowerCase().includes(q));
  })();

  function comboOf(b: Keybind, i: number) {
    return modified.get(i) ?? { mods: b.mods, key: b.key };
  }

  function captureCombo(e: KeyboardEvent): { mods: string; key: string } {
    const mods: string[] = [];
    if (e.ctrlKey)  mods.push("CTRL");
    if (e.shiftKey) mods.push("SHIFT");
    if (e.altKey)   mods.push("ALT");
    if (e.metaKey)  mods.push("SUPER");
    return { mods: mods.join(" "), key: KEY_MAP[e.key] ?? e.key.toLowerCase() };
  }

  function toggleNewMod(mod: string) {
    newBind = {
      ...newBind,
      mods: newBind.mods.includes(mod)
        ? newBind.mods.filter(m => m !== mod)
        : [...newBind.mods, mod],
    };
  }

  function onKeydown(e: KeyboardEvent) {
    // Capture key for new bind form
    if (recordingKey) {
      if (["Control","Shift","Alt","Meta"].includes(e.key)) return;
      e.preventDefault();
      e.stopPropagation();
      newBind = { ...newBind, key: KEY_MAP[e.key] ?? e.key.toLowerCase() };
      recordingKey = false;
      return;
    }

    // Capture full combo for editing existing bind
    if (recording === null) return;
    if (["Control","Shift","Alt","Meta"].includes(e.key)) return;
    e.preventDefault();
    e.stopPropagation();
    modified.set(recording as number, captureCombo(e));
    modified = modified;
    recording = null;
  }

  async function save() {
    if (!binds || !dirty) return;
    busy = true;
    try {
      const text = await api.getHyprconf();
      const lines = text.split("\n");
      for (const [i, change] of modified) {
        const b = binds[i];
        const parts = [change.mods, change.key, b.action, ...(b.args ? [b.args] : [])];
        lines[b.line - 1] = `${b.kind} = ${parts.join(", ")}`;
      }
      await api.putHyprconf(lines.join("\n"));
      for (const [i, change] of modified) {
        binds[i] = { ...binds[i], ...change };
      }
      binds = [...binds];
      modified.clear();
      modified = modified;
      showSaveOk();
    } catch (e) {
      err = String(e);
    } finally {
      busy = false;
    }
  }

  async function addBind() {
    if (!newBind.key || !newBind.action) return;
    busy = true;
    try {
      const text = await api.getHyprconf();
      const parts = [newBind.mods.join(" "), newBind.key, newBind.action, ...(newBind.args ? [newBind.args] : [])];
      const line = `${newBind.kind} = ${parts.join(", ")}`;
      await api.putHyprconf(text.trimEnd() + "\n" + line + "\n");
      binds = await api.keybinds();
      newBind = { kind: "bind", mods: [], key: "", action: "", args: "" };
      adding = false;
      showSaveOk();
    } catch (e) {
      err = String(e);
    } finally {
      busy = false;
    }
  }

  async function removeBind(i: number) {
    if (!binds) return;
    const b = binds[i];
    busy = true;
    try {
      const text = await api.getHyprconf();
      const lines = text.split("\n");
      lines.splice(b.line - 1, 1);
      await api.putHyprconf(lines.join("\n"));
      binds = await api.keybinds();
      modified.delete(i);
      modified = modified;
    } catch (e) {
      err = String(e);
    } finally {
      busy = false;
    }
  }

  function showSaveOk() {
    saveOk = true;
    setTimeout(() => (saveOk = false), 2000);
  }
</script>

<svelte:window on:keydown={onKeydown} />

<div class="section">
  <Sub num={1} title="Hyprland keybindings" desc="Click any combo to re-bind. Changes write to hyprland.conf.">
    <svelte:fragment slot="right">
      <div style="display:flex;gap:6px;align-items:center">
        {#if saveOk}
          <span style="font-size:10px;color:var(--good);letter-spacing:0.1em">✓ SAVED</span>
        {/if}
        {#if dirty}
          <button class="btn ghost" on:click={() => { modified.clear(); modified = modified; }}>
            <Icon name="discard" size={12} /> Discard
          </button>
          <button class="btn primary" disabled={busy} on:click={save}>
            {#if busy}<span class="spinner" />{:else}<Icon name="save" size={12} />{/if}
            Save
          </button>
        {/if}
        <button class="btn" on:click={() => { adding = !adding; recording = null; }}>
          <Icon name={adding ? "x" : "plus"} size={12} />
          {adding ? "Cancel" : "Add binding"}
        </button>
      </div>
    </svelte:fragment>

    <!-- New binding form -->
    {#if adding}
      <div class="kb-new">
        <select bind:value={newBind.kind}>
          {#each KINDS as k}<option>{k}</option>{/each}
        </select>

        <!-- Modifier toggles -->
        <div class="kb-mods-row">
          {#each ALL_MODS as mod}
            <button
              class="kb-mod-chip"
              class:active={newBind.mods.includes(mod)}
              on:click={() => toggleNewMod(mod)}
            >{mod}</button>
          {/each}
        </div>

        <!-- Key capture -->
        <button
          class="kb-combo"
          class:recording={recordingKey}
          on:click={() => { recordingKey = !recordingKey; recording = null; }}
        >
          {#if recordingKey}
            <span class="kb-listening">press key…</span>
          {:else if newBind.key}
            <span class="key">{newBind.key}</span>
          {:else}
            <span class="kb-listening" style="opacity:0.4">key</span>
          {/if}
        </button>

        <input type="text" placeholder="action (e.g. exec)" bind:value={newBind.action} />
        <input type="text" placeholder="args (e.g. kitty)" bind:value={newBind.args} />

        <button
          class="btn primary"
          disabled={!newBind.key || !newBind.action || busy}
          on:click={addBind}
        >
          <Icon name="plus" size={12} /> Add
        </button>
      </div>
    {/if}

    <div class="kb-search">
      <span class="ico"><Icon name="search" size={14} /></span>
      <input type="text" placeholder="Filter by modifier, key, or action…" bind:value={filter} />
    </div>

    {#if err}
      <div class="empty" style="color:var(--bad)">{err}</div>
    {:else if !binds}
      <div class="empty"><span class="spinner" /> Loading…</div>
    {:else}
      <div class="kb-row head">
        <span>#</span><span>type</span><span>combo</span><span>action</span><span></span>
      </div>

      {#each filtered as b}
        {@const combo = comboOf(b, b._i)}
        {@const isRec = recording === b._i}
        {@const isMod = modified.has(b._i)}
        <div class="kb-row" class:modified={isMod} title={b.raw}>
          <span class="n">{String(b._i + 1).padStart(2, "0")}</span>
          <span class="kind">{b.kind}</span>
          <button
            class="kb-combo"
            class:recording={isRec}
            on:click={() => (recording = isRec ? null : b._i)}
          >
            {#if isRec}
              <span class="kb-listening">press keys…</span>
            {:else}
              {#if combo.mods}<span class="kb-mods">{combo.mods}</span>{/if}
              <span class="key">{combo.key}</span>
            {/if}
          </button>
          <span class="action">
            {b.action}{#if b.args}<span class="args"> · {b.args}</span>{/if}
          </span>
          <button class="icon-btn danger" disabled={busy} on:click={() => removeBind(b._i)}>
            <Icon name="x" size={12} />
          </button>
        </div>
      {/each}

      {#if filtered.length === 0}
        <div class="empty">Nothing matches.</div>
      {/if}
    {/if}
  </Sub>
</div>
