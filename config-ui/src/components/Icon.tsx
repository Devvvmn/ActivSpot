import React from "react";

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
};

export function Icon({
  name,
  size = 16,
  style,
  ...rest
}: {
  name: string;
  size?: number;
  style?: React.CSSProperties;
} & React.HTMLAttributes<HTMLSpanElement>) {
  return (
    <span
      className="nf"
      style={{ fontSize: size, lineHeight: 1, ...(style || {}) }}
      {...rest}
    >
      {GLYPHS[name] || GLYPHS.info}
    </span>
  );
}

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
