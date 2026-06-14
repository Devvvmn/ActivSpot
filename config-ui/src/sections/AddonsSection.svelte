<script lang="ts">
  import { api, type Inventory, type Plugin } from "../api";
  import Sub from "../components/Sub.svelte";
  import Icon from "../components/Icon.svelte";

  export let inv: Inventory | null = null;
  export let refreshInventory: () => void = () => {};
  export let showToast: (kind: "success" | "error", msg: string) => void = () => {};

  // id currently awaiting confirmation, and id currently being removed.
  let confirmId: string | null = null;
  let busyId: string | null = null;

  $: plugins = inv?.plugins ?? [];

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
       desc="Drop a .qsplugin onto the Dynamic Island to install. Remove an addon below — its dir, hypr snippet and bindings are cleaned up and the shell reloads.">
    {#if !inv}
      <div class="empty"><span class="spinner" /> Loading…</div>
    {:else if plugins.length === 0}
      <div class="empty">
        <Icon name="puzzle" size={15} /> No addons installed.
      </div>
    {:else}
      <div class="addon-list">
        {#each plugins as p (p.id)}
          <div class="addon-item" class:busy={busyId === p.id}>
            <span class="ico"><Icon name="puzzle" size={16} /></span>
            <div class="meta">
              <div class="head">
                <span class="name">{p.name}</span>
                {#if p.version}<span class="ver">v{p.version}</span>{/if}
                {#if p.hasBarWidget}<span class="tag">bar</span>{/if}
                {#if p.hasWindow}<span class="tag">window</span>{/if}
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
                <button type="button" class="mini danger-ghost"
                        on:click={() => (confirmId = p.id)} disabled={!!busyId}>
                  <Icon name="trash" size={12} /> Remove
                </button>
              {/if}
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </Sub>
</div>

<style>
  .addon-list { display: flex; flex-direction: column; gap: 8px; }
  .addon-item {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: start;
    gap: 12px;
    padding: 12px 14px;
    border: 1px solid var(--line, rgba(255,255,255,0.08));
    border-radius: 12px;
    background: var(--card, rgba(255,255,255,0.02));
    transition: opacity .15s, border-color .15s;
  }
  .addon-item.busy { opacity: .55; }
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
  .mini.danger-ghost { background: transparent; border-color: rgba(243,139,168,0.4); color: #f38ba8; }
  .mini.danger-ghost:hover:not(:disabled) { background: rgba(243,139,168,0.12); }
  .mini.danger { background: #f38ba8; color: #1a1620; border-color: #f38ba8; }
  .mini.danger:hover { background: #f17497; }
</style>
