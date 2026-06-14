<script lang="ts">
  import { onMount } from "svelte";
  import { api, type Settings, type Inventory, type WeatherData } from "./api";
  import Icon from "./components/Icon.svelte";
  import PreviewIsland from "./components/PreviewIsland.svelte";
  import PaletteCard from "./components/PaletteCard.svelte";
  import ThemeSection from "./sections/ThemeSection.svelte";
  import MinibubblesSection from "./sections/MinibubblesSection.svelte";
  import PagesSection from "./sections/PagesSection.svelte";
  import MonitorsSection from "./sections/MonitorsSection.svelte";
  import KeyboardSection from "./sections/KeyboardSection.svelte";
  import BindingsSection from "./sections/BindingsSection.svelte";
  import ParallaxSection from "./sections/ParallaxSection.svelte";
  import AddonsSection from "./sections/AddonsSection.svelte";
  import RawSection from "./sections/RawSection.svelte";

  type Tab = "theme"|"bubbles"|"pages"|"monitors"|"keyboard"|"bindings"|"parallax"|"addons"|"raw";

  const NAV: { id: Tab; label: string; sub: string; icon: string }[] = [
    { id: "theme",    label: "Theme",    sub: "Catppuccin · palette",   icon: "palette"  },
    { id: "bubbles",  label: "Bubbles",  sub: "Active · timing",        icon: "bubble"   },
    { id: "pages",    label: "Pages",    sub: "Expanded view",          icon: "pages"    },
    { id: "monitors", label: "Monitors", sub: "Resolution · scale",     icon: "monitor"  },
    { id: "keyboard", label: "Keyboard", sub: "Layouts · XKB",          icon: "keyboard" },
    { id: "bindings", label: "Bindings", sub: "hyprland.conf",          icon: "key"      },
    { id: "parallax", label: "Parallax", sub: "Wallpaper motion",       icon: "monitor"  },
    { id: "addons",   label: "Addons",   sub: "Plugins · install",      icon: "puzzle"   },
    { id: "raw",      label: "Raw JSON", sub: "settings.json",          icon: "code"     },
  ];

  const pad = (n: number) => String(n).padStart(2, "0");

  let tab: Tab = "theme";
  let loaded: Settings | null = null;
  let draft: Settings | null = null;
  let inv: Inventory | null = null;
  let palette: Record<string, string> = {};
  let weather: WeatherData | null = null;
  let busy = false;
  let toast: { kind: "success"|"error"; msg: string } | null = null;

  $: dirty = loaded && draft ? JSON.stringify(loaded) !== JSON.stringify(draft) : false;
  $: current = NAV.find(n => n.id === tab)!;
  $: idx = NAV.findIndex(n => n.id === tab);

  function loadInventory() {
    api.inventory().then(i => (inv = i)).catch(() => {});
  }

  onMount(() => {
    api.getSettings().then(s => { loaded = s; draft = s; }).catch(e => showToast("error", String(e)));
    loadInventory();
    api.colors().then(p => (palette = p)).catch(() => {});
    api.weather().then(w => (weather = w)).catch(() => {});
  });

  function set(patch: Partial<Settings>) {
    if (draft) draft = { ...draft, ...patch };
  }
  function setAll(next: Settings) { draft = next; }
  function discard() { if (loaded) draft = loaded; }

  async function save() {
    if (!draft) return;
    busy = true;
    try {
      await api.putSettings(draft);
      loaded = draft;
      showToast("success", "settings.json written");
    } catch (e) {
      showToast("error", String(e));
    } finally {
      busy = false;
    }
  }

  async function reload() {
    busy = true;
    try {
      await api.reload();
      showToast("success", "Reload signal sent to Quickshell");
    } catch (e) {
      showToast("error", String(e));
    } finally {
      busy = false;
    }
  }

  function showToast(kind: "success"|"error", msg: string) {
    toast = { kind, msg };
    setTimeout(() => (toast = null), 2400);
  }

  function onKeydown(e: KeyboardEvent) {
    if (e.ctrlKey && e.key === "s") { e.preventDefault(); save(); }
    if (e.ctrlKey && e.key === "z") { e.preventDefault(); discard(); }
    if (e.ctrlKey && e.key === "r") { e.preventDefault(); reload(); }
  }
</script>

<svelte:window on:keydown={onKeydown} />

{#if !draft}
  <div style="display:grid;place-items:center;height:100vh">
    <span class="spinner" />&nbsp;&nbsp;Loading settings…
  </div>
{:else}
  <div class="toprule">
    <div class="left">
      <span class="dot">●</span>
      <span><b>Dyne</b> · Configurator</span>
    </div>
    <div class="right">
      <span>~/.config/qs</span>
      <span class="ok">● live</span>
    </div>
  </div>

  <div class="app">
    <aside class="sidebar">
      <div class="brand">
        <div class="brand-mark" />
        <div>
          <div class="brand-name">ActivSpot</div>
          <div class="brand-sub">Configurator</div>
        </div>
      </div>

      <div class="nav-label">
        <span>Sections</span>
        <span class="num">{pad(NAV.length)}</span>
      </div>

      <div class="nav">
        {#each NAV as n, i}
          <button class="nav-item" class:active={tab === n.id} on:click={() => (tab = n.id)}>
            <span class="ico"><Icon name={n.icon} size={14} /></span>
            <span class="label-stack">
              <span class="l">{n.label}</span>
              <span class="s">{n.sub}</span>
            </span>
            <span />
            <span class="num">{pad(i+1)}</span>
          </button>
        {/each}
      </div>

      <div class="sidebar-foot">
        <div class="shell-line">
          <span class="pulse" />
          <div class="meta">
            <div class="t">Quickshell</div>
            <div class="s">live · cfg ok</div>
          </div>
        </div>
        <div class="shell-foot-meta">
          <span>~/.config/qs</span>
          <span>cfg · ok</span>
        </div>
      </div>
    </aside>

    <main class="main">
      <div class="topbar">
        <div class="left">
          <div class="crumbs">
            <span class="num">{pad(idx+1)} / {pad(NAV.length)}</span>
            <span>—</span>
            <span>Configurator</span>
            <span>›</span>
            <span class="now">{current?.label}</span>
          </div>
          <h1 class="page-title">{current?.label}</h1>
          <p class="page-sub">{current?.sub}</p>
        </div>
        <div class="actions">
          <span class="status-pill" class:dirty>
            <span class="dot" />
            <span class="label-text">{dirty ? "Unsaved" : "All saved"}</span>
          </span>
          <button class="btn" on:click={reload} disabled={busy}>
            <Icon name="refresh" size={13} /> <span class="label-text">Reload shell</span>
          </button>
          <button class="btn primary" on:click={save} disabled={!dirty || busy}>
            {#if busy}<span class="spinner" />{:else}<Icon name="save" size={13} />{/if}
            <span class="label-text">Save</span>
          </button>
        </div>
      </div>

      <div class="content">
        <div class="content-scroll">
          {#if tab === "theme"}    <ThemeSection    s={draft} {set} {palette} />
          {:else if tab === "bubbles"}  <MinibubblesSection s={draft} {set} {inv} />
          {:else if tab === "pages"}    <PagesSection    s={draft} {set} {inv} />
          {:else if tab === "monitors"} <MonitorsSection s={draft} {set} />
          {:else if tab === "keyboard"} <KeyboardSection s={draft} {set} />
          {:else if tab === "bindings"} <BindingsSection />
          {:else if tab === "parallax"} <ParallaxSection s={draft} {set} />
          {:else if tab === "addons"}   <AddonsSection {inv} refreshInventory={loadInventory} {showToast} />
          {:else if tab === "raw"}      <RawSection s={draft} {setAll} />
          {/if}
        </div>

        <div class="preview-rail">
          <PreviewIsland s={draft} {inv} {palette} {weather} />
          <PaletteCard s={draft} {palette} />
        </div>
      </div>
    </main>
  </div>

  <div class="savedock" class:show={dirty}>
    <span class="dot" />
    <span class="label"><b>Unsaved changes</b> &nbsp;·&nbsp; draft differs from settings.json</span>
    <span class="grow" />
    <button class="btn ghost" on:click={discard} disabled={busy}>
      <Icon name="discard" size={13} /> Discard
    </button>
    <button class="btn primary" on:click={save} disabled={busy}>
      {#if busy}<span class="spinner" />{:else}<Icon name="save" size={13} />{/if}
      Save changes
    </button>
  </div>

  {#if toast}
    <div class="toast {toast.kind}">
      <Icon name={toast.kind === "success" ? "check" : "x"} size={13}
            color={toast.kind === "success" ? "var(--good)" : "var(--bad)"} />
      {toast.msg}
    </div>
  {/if}
{/if}
