<script lang="ts">
  export let label: string;
  export let hint: string = "";
  export let code: string = "";
</script>

<div class="row">
  <div class="row-label">
    <span class="l">{label}</span>
    {#if hint}<span class="h">{hint}</span>{/if}
    {#if code}<code>{code}</code>{/if}
  </div>
  <div class="row-value"><slot /></div>
</div>
