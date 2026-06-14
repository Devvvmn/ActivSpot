<script lang="ts">
  import { createEventDispatcher } from "svelte";
  export let checked: boolean = false;
  const dispatch = createEventDispatcher<{ change: boolean }>();
</script>

<div
  class="toggle"
  class:on={checked}
  role="switch"
  tabindex="0"
  aria-checked={checked}
  on:click={() => dispatch("change", !checked)}
  on:keydown={(e) => (e.key === "Enter" || e.key === " ") && dispatch("change", !checked)}
/>
