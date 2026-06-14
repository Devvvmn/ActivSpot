<script lang="ts">
  export let num: number | undefined = undefined;
  export let title: string;
  export let desc: string = "";
</script>

<section class="subsec">
  <div class="subsec-head">
    <div>
      <div class="subsec-title">
        {#if num !== undefined}<span class="num">{String(num).padStart(2, "0")}</span>{/if}
        {title}
      </div>
      {#if desc}<p class="subsec-desc">{desc}</p>{/if}
    </div>
    <slot name="right" />
  </div>
  <slot />
</section>
