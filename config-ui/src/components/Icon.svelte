<script lang="ts">
  export let name: string;
  export let size: number = 16;
  export let color: string = "";

  const GLYPHS: Record<string, string> = {
    palette:  "\u{F03D8}",
    bubble:   "\u{F0366}",
    pages:    "\u{F0219}",
    monitor:  "\u{F0379}",
    pin:      "\u{F0403}",
    keyboard: "\u{F030C}",
    key:      "\u{F030B}",
    code:     "\u{F0626}",
    save:     "\u{F0193}",
    refresh:  "\u{F0450}",
    discard:  "\u{F01B4}",
    plus:     "\u{F0415}",
    minus:    "\u{F0374}",
    grip:     "\u{F0708}",
    up:       "\u{F0143}",
    down:     "\u{F0140}",
    search:   "\u{F0349}",
    check:    "\u{F012C}",
    x:        "\u{F0156}",
    music:    "\u{F075A}",
    bell:     "\u{F009B}",
    weather:  "\u{F05D4}",
    battery:  "\u{F0079}",
    rec:      "\u{F044A}",
    lock:     "\u{F033E}",
    chevron:  "\u{F0142}",
    settings: "\u{F0493}",
    play:     "\u{F040A}",
    pause:    "\u{F03E4}",
    stash:    "\u{F0494}",
    info:     "\u{F02FD}",
    eye:      "\u{F0208}",
    discord:  "\u{F066F}",
    pet:      "\u{F011B}",
    focus:    "\u{F051B}",
    warning:  "\u{F0026}",
    puzzle:   "\u{F00EA}",
    trash:    "\u{F0A7A}",
  };

  export const BUBBLE_META: Record<string, { label: string; icon: string }> = {
    music:         { label: "Music",         icon: "music"   },
    notifications: { label: "Notifications", icon: "bell"    },
    weather:       { label: "Weather",       icon: "weather" },
    battery:       { label: "Battery",       icon: "battery" },
    recording:     { label: "Recording",     icon: "rec"     },
    discord:       { label: "Discord",       icon: "discord" },
    stash:         { label: "Stash",         icon: "stash"   },
    pet:           { label: "Stewart",       icon: "pet"     },
    lock:          { label: "Lock",          icon: "lock"    },
    focus:         { label: "Focus",         icon: "focus"   },
  };

  $: glyph = GLYPHS[name] ?? GLYPHS.info;
  $: style = `font-size:${size}px;line-height:1${color ? `;color:${color}` : ""}`;
</script>

<span class="nf" {style}>{glyph}</span>
