<script lang="ts">
  import { onMount } from "svelte";
  import { api, type Inventory, type Plugin, type PluginSetting } from "../api";
  import Sub from "../components/Sub.svelte";
  import Icon from "../components/Icon.svelte";
  import Toggle from "../components/Toggle.svelte";

  export let inv: Inventory | null = null;
  export let refreshInventory: () => void = () => {};
  export let showToast: (kind: "success" | "error", msg: string) => void = () => {};

  // id currently awaiting confirmation, and id currently being removed.
  let confirmId: string | null = null;
  let busyId: string | null = null;

  // settings UI state
  let openId: string | null = null;             // which plugin's settings are expanded
  let values: Record<string, Record<string, unknown>> = {};   // working copy per instance id
  let dw: Record<string, unknown> = {};          // desktop_widgets.json (instance registry)
  let selInst: Record<string, string> = {};      // selected instance per plugin id
  let savingId: string | null = null;

  $: plugins = inv?.plugins ?? [];

  onMount(loadAll);

  async function loadAll() {
    try {
      const [stored, widgets] = await Promise.all([
        api.getPluginSettings(),
        api.getDesktopWidgets().catch(() => ({})),
      ]);
      dw = widgets || {};
      const next: Record<string, Record<string, unknown>> = {};
      for (const p of plugins) {
        for (const inst of instancesOf(p)) next[inst] = seed(p, stored[inst] || {});
      }
      values = next;
    } catch (e) {
      // non-fatal: settings just start from defaults
    }
  }

  // Re-seed when the plugin list arrives/changes (inventory loads async).
  $: if (plugins.length) ensureSeeded(plugins);
  function ensureSeeded(ps: Plugin[]) {
    let changed = false;
    const next = { ...values };
    for (const p of ps) {
      for (const inst of instancesOf(p)) {
        if (!next[inst]) { next[inst] = seed(p, {}); changed = true; }
      }
    }
    if (changed) values = next;
  }

  // Instance ids for a plugin: base (=plugin id) + extras "<id>#<n>" from the store.
  function instancesOf(p: Plugin): string[] {
    if (!p.multiInstance) return [p.id];
    const extras = Object.keys(dw)
      .filter((k) => k.startsWith(p.id + "#"))
      .sort((a, b) => Number(a.split("#")[1]) - Number(b.split("#")[1]));
    return [p.id, ...extras];
  }

  function selFor(p: Plugin): string {
    const list = instancesOf(p);
    const cur = selInst[p.id];
    return cur && list.includes(cur) ? cur : p.id;
  }
  function selectInst(p: Plugin, inst: string) {
    selInst = { ...selInst, [p.id]: inst };
  }

  function seed(p: Plugin, stored: Record<string, unknown>) {
    const o: Record<string, unknown> = {};
    for (const f of p.settings || []) {
      o[f.key] = stored[f.key] !== undefined ? stored[f.key] : f.default;
    }
    return o;
  }

  function toggleOpen(id: string) {
    openId = openId === id ? null : id;
  }

  function setVal(inst: string, key: string, v: unknown) {
    values = { ...values, [inst]: { ...values[inst], [key]: v } };
  }

  function numFor(f: PluginSetting, raw: string): number {
    let n = Number(raw);
    if (Number.isNaN(n)) n = Number(f.default) || 0;
    if (f.min !== undefined) n = Math.max(f.min, n);
    if (f.max !== undefined) n = Math.min(f.max, n);
    return n;
  }

  async function save(inst: string, name: string) {
    savingId = inst;
    try {
      await api.putPluginSettings(inst, values[inst] || {});
      showToast("success", `Saved ${name}`);
    } catch (e) {
      showToast("error", String(e));
    } finally {
      savingId = null;
    }
  }

  function resetDefaults(p: Plugin, inst: string) {
    values = { ...values, [inst]: seed(p, {}) };
  }

  async function addInstance(p: Plugin) {
    try {
      const r = await api.addInstance(p.id);
      dw = (await api.getDesktopWidgets().catch(() => ({}))) || {};
      values = { ...values, [r.instId]: seed(p, {}) };
      selInst = { ...selInst, [p.id]: r.instId };
      showToast("success", `Added a new frame`);
    } catch (e) {
      showToast("error", String(e));
    }
  }

  async function removeInstance(p: Plugin, inst: string) {
    try {
      await api.removeInstance(inst);
      dw = (await api.getDesktopWidgets().catch(() => ({}))) || {};
      const nv = { ...values }; delete nv[inst]; values = nv;
      selInst = { ...selInst, [p.id]: p.id };
      showToast("success", `Removed frame`);
    } catch (e) {
      showToast("error", String(e));
    }
  }

  async function uninstall(p: Plugin) {
    busyId = p.id;
    confirmId = null;
    try {
      const r = await api.uninstallPlugin(p.id);
      if (r.ok) {
        showToast("success", `Removed “${p.name}”`);
        refreshInventory();
      } else {
        showToast("error", r.output || `Failed to remove ${p.id}`);
      }
    } catch (e) {
      showToast("error", String(e));
    } finally {
      busyId = null;
    }
  }
</script>

<div class="section">
  <Sub num={1} title="Installed addons"
       desc="Drop a .qsplugin onto the Dynamic Island to install. Configure an addon's options below (multi-instance widgets can have several copies), or remove it — its dir, hypr snippet and bindings are cleaned up and the shell reloads.">
    {#if !inv}
      <div class="empty"><span class="spinner" /> Loading…</div>
    {:else if plugins.length === 0}
      <div class="empty">
        <Icon name="puzzle" size={15} /> No addons installed.
      </div>
    {:else}
      <div class="addon-list">
        {#each plugins as p (p.id)}
          <div class="addon-item" class:busy={busyId === p.id} class:open={openId === p.id}>
            <div class="addon-head">
              <span class="ico"><Icon name="puzzle" size={16} /></span>
              <div class="meta">
                <div class="head">
                  <span class="name">{p.name}</span>
                  {#if p.version}<span class="ver">v{p.version}</span>{/if}
                  {#if p.hasBarWidget}<span class="tag">bar</span>{/if}
                  {#if p.multiInstance}<span class="tag">multi</span>{:else if p.hasWindow}<span class="tag">window</span>{/if}
                  {#if p.hasHooks}<span class="tag warn">hooks</span>{/if}
                </div>
                {#if p.description}<p class="desc">{p.description}</p>{/if}
                <span class="id">{p.id}{p.author ? ` · ${p.author}` : ""}</span>
              </div>

              <div class="act">
                {#if busyId === p.id}
                  <span class="spinner" />
                {:else if confirmId === p.id}
                  <button type="button" class="mini ghost" on:click={() => (confirmId = null)}>Cancel</button>
                  <button type="button" class="mini danger" on:click={() => uninstall(p)}>
                    <Icon name="trash" size={12} /> Confirm
                  </button>
                {:else}
                  {#if p.settings?.length}
                    <button type="button" class="mini" on:click={() => toggleOpen(p.id)}>
                      <Icon name="settings" size={12} /> {openId === p.id ? "Close" : "Configure"}
                    </button>
                  {/if}
                  <button type="button" class="mini danger-ghost"
                          on:click={() => (confirmId = p.id)} disabled={!!busyId}>
                    <Icon name="trash" size={12} /> Remove
                  </button>
                {/if}
              </div>
            </div>

            {#if openId === p.id && p.settings?.length}
              <div class="settings">
                {#if p.multiInstance}
                  <div class="instbar">
                    {#each instancesOf(p) as inst, i}
                      <button type="button" class="chip" class:sel={selFor(p) === inst}
                              on:click={() => selectInst(p, inst)}>Frame {i + 1}</button>
                    {/each}
                    <button type="button" class="chip add" on:click={() => addInstance(p)}>
                      <Icon name="plus" size={11} /> Add
                    </button>
                  </div>
                {/if}

                {#if values[selFor(p)]}
                  {#each p.settings as f (f.key)}
                    <div class="field">
                      <div class="flabel">
                        <span class="ftitle">{f.label}</span>
                        {#if f.help}<span class="fhelp">{f.help}</span>{/if}
                      </div>
                      <div class="finput">
                        {#if f.type === "bool"}
                          <Toggle checked={!!values[selFor(p)][f.key]}
                                  on:change={(e) => setVal(selFor(p), f.key, e.detail)} />
                        {:else if f.type === "number"}
                          <input class="inp num" type="number"
                                 min={f.min} max={f.max}
                                 value={values[selFor(p)][f.key]}
                                 on:input={(e) => setVal(selFor(p), f.key, numFor(f, e.currentTarget.value))} />
                          {#if f.suffix}<span class="suffix">{f.suffix}</span>{/if}
                        {:else}
                          <input class="inp" type="text"
                                 placeholder={f.placeholder || ""}
                                 value={String(values[selFor(p)][f.key] ?? "")}
                                 on:input={(e) => setVal(selFor(p), f.key, e.currentTarget.value)} />
                        {/if}
                      </div>
                    </div>
                  {/each}

                  <div class="settings-act">
                    {#if p.multiInstance && selFor(p) !== p.id}
                      <button type="button" class="mini danger-ghost" on:click={() => removeInstance(p, selFor(p))}>
                        <Icon name="trash" size={12} /> Remove frame
                      </button>
                    {/if}
                    <span class="spacer" />
                    <button type="button" class="mini ghost" on:click={() => resetDefaults(p, selFor(p))}>Reset</button>
                    <button type="button" class="mini primary" on:click={() => save(selFor(p), p.name)}
                            disabled={savingId === selFor(p)}>
                      {#if savingId === selFor(p)}<span class="spinner sm" />{/if} Save
                    </button>
                  </div>
                {/if}
              </div>
            {/if}
          </div>
        {/each}
      </div>
    {/if}
  </Sub>
</div>

<style>
  .addon-list { display: flex; flex-direction: column; gap: 8px; }
  .addon-item {
    border: 1px solid var(--line, rgba(255,255,255,0.08));
    border-radius: 12px;
    background: var(--card, rgba(255,255,255,0.02));
    transition: opacity .15s, border-color .15s;
  }
  .addon-item.busy { opacity: .55; }
  .addon-item.open { border-color: var(--accent, #cba6f7); }
  .addon-head {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: start;
    gap: 12px;
    padding: 12px 14px;
  }
  .ico {
    display: grid; place-items: center;
    width: 30px; height: 30px;
    border-radius: 8px;
    background: rgba(255,255,255,0.05);
    color: var(--accent, #cba6f7);
  }
  .meta { min-width: 0; display: flex; flex-direction: column; gap: 3px; }
  .head { display: flex; align-items: baseline; gap: 8px; flex-wrap: wrap; }
  .name { font-weight: 600; font-size: 13px; }
  .ver { font-size: 11px; color: var(--muted, #9aa); opacity: .8; }
  .tag {
    font-size: 9.5px; letter-spacing: .04em; text-transform: uppercase;
    padding: 1px 6px; border-radius: 999px;
    background: rgba(255,255,255,0.06); color: var(--muted, #9aa);
  }
  .tag.warn { background: rgba(249,191,86,0.14); color: #f9bf56; }
  .desc {
    margin: 0; font-size: 11.5px; line-height: 1.45;
    color: var(--muted, #9aa);
  }
  .id { font-size: 10.5px; color: var(--muted, #9aa); opacity: .6; font-family: ui-monospace, monospace; }
  .act { display: flex; align-items: center; gap: 6px; padding-top: 2px; }
  .mini {
    display: inline-flex; align-items: center; gap: 5px;
    font-size: 11.5px; font-weight: 500;
    padding: 5px 10px; border-radius: 8px;
    border: 1px solid transparent; cursor: pointer;
    background: rgba(255,255,255,0.05); color: var(--text, #e2e8f0);
    transition: background .15s, border-color .15s, color .15s;
  }
  .mini:disabled { opacity: .4; cursor: default; }
  .mini.ghost { background: transparent; border-color: var(--line, rgba(255,255,255,0.12)); }
  .mini.primary { background: var(--accent, #cba6f7); color: #1a1620; border-color: var(--accent, #cba6f7); }
  .mini.primary:hover:not(:disabled) { filter: brightness(1.08); }
  .mini.danger-ghost { background: transparent; border-color: rgba(243,139,168,0.4); color: #f38ba8; }
  .mini.danger-ghost:hover:not(:disabled) { background: rgba(243,139,168,0.12); }
  .mini.danger { background: #f38ba8; color: #1a1620; border-color: #f38ba8; }
  .mini.danger:hover { background: #f17497; }

  /* settings form */
  .settings {
    display: flex; flex-direction: column; gap: 12px;
    padding: 6px 14px 14px 14px;
    border-top: 1px solid var(--line, rgba(255,255,255,0.08));
  }
  .instbar { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
  .chip {
    font-size: 11.5px; font-weight: 500;
    padding: 4px 11px; border-radius: 999px; cursor: pointer;
    border: 1px solid var(--line, rgba(255,255,255,0.14));
    background: transparent; color: var(--muted, #9aa);
    transition: background .15s, color .15s, border-color .15s;
  }
  .chip.sel { background: var(--accent, #cba6f7); color: #1a1620; border-color: var(--accent, #cba6f7); }
  .chip.add {
    display: inline-flex; align-items: center; gap: 4px;
    border-style: dashed; color: var(--text, #e2e8f0);
  }
  .chip.add:hover { border-color: var(--accent, #cba6f7); color: var(--accent, #cba6f7); }
  .field {
    display: grid;
    grid-template-columns: 1fr auto;
    align-items: center;
    gap: 14px;
  }
  .flabel { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
  .ftitle { font-size: 12.5px; font-weight: 500; }
  .fhelp { font-size: 11px; color: var(--muted, #9aa); line-height: 1.4; }
  .finput { display: flex; align-items: center; gap: 6px; }
  .inp {
    background: rgba(0,0,0,0.25);
    border: 1px solid var(--line, rgba(255,255,255,0.12));
    border-radius: 8px;
    color: var(--text, #e2e8f0);
    font-size: 12px;
    padding: 6px 10px;
    width: 240px;
    outline: none;
    transition: border-color .15s;
  }
  .inp:focus { border-color: var(--accent, #cba6f7); }
  .inp.num { width: 90px; text-align: right; }
  .suffix { font-size: 11px; color: var(--muted, #9aa); }
  .settings-act { display: flex; align-items: center; gap: 8px; padding-top: 2px; }
  .settings-act .spacer { flex: 1; }
  .spinner.sm { width: 12px; height: 12px; }
</style>
