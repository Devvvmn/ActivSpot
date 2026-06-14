<script lang="ts">
  export let active: boolean = false;
  export let onClick: (() => void) | undefined = undefined;
</script>

<button type="button" class="chip" class:active on:click={onClick}>
  <slot />
</button>
