// ActivSpot — Cat Sprite Component
// 8×8 pixel cat rendered on canvas, 3× scaled = 24×24px

const CAT_SPRITES = {
  sit: [
    " ##  ## ",
    "########",
    "#E####E#",
    "########",
    "########",
    " ###### ",
    "  ####  ",
    "  ####  "
  ],
  blink: [
    " ##  ## ",
    "########",
    "########",
    "########",
    "########",
    " ###### ",
    "  ####  ",
    "  ####  "
  ],
  walkA: [
    " #     #",
    "########",
    "#E######",
    "########",
    "########",
    " ###### ",
    " # ## # ",
    "  #  #  "
  ],
  walkB: [
    " #     #",
    "########",
    "#E######",
    "########",
    "########",
    " ###### ",
    "  ## #  ",
    "  #   # "
  ],
  alert: [
    " ##  ## ",
    "########",
    "#EE##EE#",
    "########",
    "########",
    " ###### ",
    "  ####  ",
    "  ####  "
  ],
  sleep: [
    "        ",
    " #      ",
    "########",
    "########",
    "########",
    "########",
    " ###### ",
    "       #"
  ]
};

const CAT_SEQUENCES = {
  idle:  ['sit','sit','sit','blink'],
  bop:   ['sit','sit'],
  alert: ['alert','sit','alert','sit'],
  walk:  ['walkA','walkB'],
  sleep: ['sleep']
};

function CatSprite({ state = 'idle', catColor = '#cdd6f4', eyeColor = '#1e1e2e', size = 24 }) {
  const canvasRef = React.useRef(null);
  const frameRef  = React.useRef(0);
  const stateRef  = React.useRef(state);
  stateRef.current = state;

  React.useEffect(() => {
    const ps = size / 8;
    function draw() {
      const c = canvasRef.current;
      if (!c) return;
      const ctx = c.getContext('2d');
      ctx.clearRect(0, 0, c.width, c.height);
      const seq  = CAT_SEQUENCES[stateRef.current] || CAT_SEQUENCES.idle;
      const name = seq[frameRef.current % seq.length];
      const sprite = CAT_SPRITES[name];
      if (!sprite) return;
      for (let r = 0; r < sprite.length; r++) {
        for (let col = 0; col < sprite[r].length; col++) {
          const ch = sprite[r][col];
          if (ch === ' ') continue;
          ctx.fillStyle = ch === 'E' ? eyeColor : catColor;
          ctx.fillRect(col * ps, r * ps, ps, ps);
        }
      }
    }
    draw();
    const intervals = { idle: 500, bop: 260, alert: 220, walk: 200, sleep: 9999 };
    const iv = setInterval(() => {
      const seq = CAT_SEQUENCES[stateRef.current] || CAT_SEQUENCES.idle;
      frameRef.current = (frameRef.current + 1) % seq.length;
      draw();
    }, intervals[stateRef.current] || 500);
    return () => clearInterval(iv);
  }, [state, catColor, eyeColor, size]);

  return React.createElement('canvas', {
    ref: canvasRef,
    width: size,
    height: size,
    style: { display: 'block', imageRendering: 'pixelated', width: size, height: size, flexShrink: 0 }
  });
}

// Export to window for other scripts
Object.assign(window, { CatSprite, CAT_SPRITES, CAT_SEQUENCES });
