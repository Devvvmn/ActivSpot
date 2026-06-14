<script lang="ts">
  export let value: number;
  export let min: number;
  export let max: number;
  export let step: number = 1;
  export let unit: string = "";
  export let onChange: (v: number) => void;
</script>

<div class="slider-row">
  <input
    type="range"
    class="slider"
    {min} {max} {step} {value}
    on:input={(e) => onChange(parseFloat(e.currentTarget.value))}
  />
  <div class="val">
    {value}{#if unit}<span class="u">{unit}</span>{/if}
  </div>
</div>
