// ActivSpot — Dynamic Island component

// ── Cat sprite ────────────────────────────────────────────────────────────
function IslandCat({ state = 'idle', size = 24 }) {
  const ref = React.useRef();
  const B='#cdd6f4', E='#1e1e2e', N='#cba6f7';
  const SPRITES = {
    sit:   ["#      #","##    ##","########","#E####E#","###NN###"," ###### ","  ####  ","  #  #  "],
    blink: ["#      #","##    ##","########","#-####-#","###NN###"," ###### ","  ####  ","  #  #  "],
    alert: ["#      #","##    ##","########","#EE##EE#","###NN###"," ###### ","  ####  ","  #  #  "],
    walkA: ["#      #","##    ##","########","#E######","###NN###"," ###### "," ## ##  ","  #  #  "],
    walkB: ["#      #","##    ##","########","#E######","###NN###"," ###### ","  ## ## ","  #   # "],
  };
  const SEQS = { idle:['sit','sit','sit','blink'], bop:['sit','blink','sit'], alert:['alert','sit','alert','sit'], walk:['walkA','walkB'] };
  const frameRef = React.useRef(0);

  function draw(frameName) {
    const c = ref.current; if (!c) return;
    const ctx = c.getContext('2d');
    const ps = c.width / 8;
    ctx.clearRect(0,0,c.width,c.height);
    const sprite = SPRITES[frameName]; if (!sprite) return;
    sprite.forEach((row,r) => [...row].forEach((ch,col) => {
      if (ch===' '||ch==='-') return;
      ctx.fillStyle = ch==='E'?E:ch==='N'?N:B;
      ctx.fillRect(col*ps, r*ps, ps, ps);
    }));
  }

  React.useEffect(() => {
    const seq = SEQS[state] || SEQS.idle;
    frameRef.current = 0;
    draw(seq[0]);
    const ms = state==='bop'?300:state==='alert'?220:state==='walk'?200:500;
    const iv = setInterval(() => {
      frameRef.current = (frameRef.current+1) % seq.length;
      draw(seq[frameRef.current]);
    }, ms);
    return () => clearInterval(iv);
  }, [state]);

  return React.createElement('canvas', { ref, width: size, height: size,
    style: { display:'block', imageRendering:'pixelated', width:size, height:size, flexShrink:0 } });
}

// ── Cava bars ─────────────────────────────────────────────────────────────
function CavaBars({ playing }) {
  const refs = Array.from({length:6}, () => React.useRef());
  const COLORS = ['#89b4fa','#cba6f7','#f5c2e7','#fab387','#f5c2e7','#89b4fa'];
  const ph = React.useRef(0);
  const raf = React.useRef();

  React.useEffect(() => {
    function tick() {
      refs.forEach((r,i) => {
        const c = r.current; if (!c) return;
        const ctx = c.getContext('2d');
        const w=c.width, h=c.height;
        const v = playing ? 0.18+0.78*Math.abs(Math.sin(ph.current*0.09+i*1.1)) : 0.08;
        const half = Math.max(1, Math.round(h/2*v));
        const cy = h/2;
        ctx.clearRect(0,0,w,h);
        ctx.fillStyle = COLORS[i];
        ctx.beginPath(); ctx.roundRect(0,cy-half,w,half,1); ctx.fill();
        ctx.beginPath(); ctx.roundRect(0,cy,w,half,1); ctx.fill();
      });
      ph.current++;
      raf.current = requestAnimationFrame(tick);
    }
    tick();
    return () => cancelAnimationFrame(raf.current);
  }, [playing]);

  return React.createElement('div', { style:{display:'flex',alignItems:'center',gap:2,height:16} },
    refs.map((r,i) => React.createElement('canvas', { key:i, ref:r, width:3, height:16,
      style:{width:3,height:16,display:'block',imageRendering:'pixelated'} }))
  );
}

// ── Collapsed states ──────────────────────────────────────────────────────
function ClockCollapsed({ time }) {
  return React.createElement('div', { style:{display:'flex',alignItems:'center',gap:8,padding:'0 18px',height:'100%'} },
    React.createElement('span', { style:{fontSize:13,fontWeight:900,color:'#cdd6f4',letterSpacing:'-0.02em'} }, time),
    React.createElement('span', { style:{fontSize:10,color:'#a6adc8'} }, 'Tue, Apr 07'),
    React.createElement('div', { style:{width:1,height:14,background:'rgba(205,214,244,0.1)'} }),
    React.createElement('span', { style:{fontSize:18,color:'#cba6f7',lineHeight:1} }, '☁'),
    React.createElement('span', { style:{fontSize:12,fontWeight:900,color:'#fab387'} }, '4.9°C'),
  );
}

function MusicCollapsed({ playing }) {
  return React.createElement('div', { style:{display:'flex',alignItems:'center',gap:10,padding:'0 10px',height:'100%'} },
    React.createElement('div', { style:{width:26,height:26,borderRadius:7,flexShrink:0,background:'linear-gradient(135deg,#cba6f7,#89b4fa)'} }),
    React.createElement('div', { style:{display:'flex',flexDirection:'column',gap:1} },
      React.createElement('span', { style:{fontSize:12,fontWeight:900,color:'#cdd6f4',whiteSpace:'nowrap'} }, "I Don't Care"),
      React.createElement('span', { style:{fontSize:9,color:'#a6adc8',whiteSpace:'nowrap'} }, 'VIOLENT VIRA'),
    ),
    React.createElement('div', { style:{display:'flex',alignItems:'center',gap:2} },
      React.createElement('div', { style:{width:21,height:21,borderRadius:11,display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,color:'#a6adc8'} }, '◀'),
      React.createElement('div', { style:{width:25,height:25,borderRadius:13,background:'rgba(203,166,247,0.15)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,color:'#cdd6f4'} }, playing?'⏸':'▶'),
      React.createElement('div', { style:{width:21,height:21,borderRadius:11,display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,color:'#a6adc8'} }, '▶'),
    ),
    React.createElement(CavaBars, { playing }),
    React.createElement(IslandCat, { state:'bop', size:24 }),
  );
}

function NotifCollapsed() {
  return React.createElement('div', { style:{display:'flex',alignItems:'center',gap:10,padding:'0 10px',height:'100%'} },
    React.createElement('div', { style:{width:26,height:26,borderRadius:7,background:'rgba(250,179,135,0.15)',display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,fontSize:13,color:'#fab387'} }, '✉'),
    React.createElement('div', { style:{display:'flex',flexDirection:'column',gap:1} },
      React.createElement('span', { style:{fontSize:10,fontWeight:500,color:'#fab387',whiteSpace:'nowrap'} }, 'Discord'),
      React.createElement('span', { style:{fontSize:12,fontWeight:900,color:'#cdd6f4',whiteSpace:'nowrap'} }, 'New message in #general'),
    ),
    React.createElement(IslandCat, { state:'alert', size:24 }),
  );
}

// ── Expanded pages ────────────────────────────────────────────────────────
function ClockExpanded({ time }) {
  return React.createElement('div', { style:{padding:'28px 32px 72px',display:'flex',flexDirection:'column',alignItems:'center',gap:14} },
    React.createElement('span', { style:{fontSize:52,fontWeight:900,color:'#cdd6f4',lineHeight:1,letterSpacing:'-0.03em'} }, time+':42'),
    React.createElement('span', { style:{fontSize:14,color:'#a6adc8'} }, 'Tuesday, April 07'),
    React.createElement('div', { style:{width:'100%',height:1,background:'rgba(205,214,244,0.08)',margin:'4px 0'} }),
    React.createElement('div', { style:{display:'flex',alignItems:'center',gap:16} },
      React.createElement('span', { style:{fontSize:32,color:'#cba6f7'} }, '☁'),
      React.createElement('div', { style:{display:'flex',flexDirection:'column',gap:2} },
        React.createElement('span', { style:{fontSize:26,fontWeight:900,color:'#fab387'} }, '4.9°C'),
        React.createElement('span', { style:{fontSize:11,color:'#a6adc8'} }, 'Clear Sky'),
      ),
    ),
  );
}

function MusicExpanded({ playing, setPlaying }) {
  const [progress, setProgress] = React.useState(36);
  const [preset, setPreset] = React.useState('Rock');
  const presets = ['Flat','Bass','Treble','Vocal','Pop','Rock'];
  const eqVals  = [4,-2,6,8,3,-1,2,5,3,1];
  const eqLabels= ['32','64','125','250','500','1K','2K','4K','8K','16K'];
  return React.createElement('div', { style:{padding:'20px 20px 72px',display:'flex',flexDirection:'column',gap:14} },
    // track row
    React.createElement('div', { style:{display:'flex',gap:16,alignItems:'flex-start'} },
      React.createElement('div', { style:{width:88,height:88,borderRadius:14,background:'linear-gradient(135deg,#cba6f7,#89b4fa)',flexShrink:0,boxShadow:'0 4px 16px rgba(0,0,0,0.4)'} }),
      React.createElement('div', { style:{flex:1,minWidth:0,display:'flex',flexDirection:'column',gap:4} },
        React.createElement('span', { style:{fontSize:18,fontWeight:900,color:'#cdd6f4'} }, "I Don't Care"),
        React.createElement('span', { style:{fontSize:12,color:'#a6adc8',marginBottom:8} }, 'VIOLENT VIRA'),
        React.createElement('div', { style:{height:4,background:'#313244',borderRadius:2,cursor:'pointer',position:'relative'},
          onClick: e => { const r=e.currentTarget.getBoundingClientRect(); setProgress(Math.round((e.clientX-r.left)/r.width*100)); }
        },
          React.createElement('div', { style:{height:'100%',width:progress+'%',background:'linear-gradient(90deg,#cba6f7,#89b4fa)',borderRadius:2} }),
          React.createElement('div', { style:{position:'absolute',top:'50%',left:progress+'%',transform:'translate(-50%,-50%)',width:12,height:12,borderRadius:6,background:'#cdd6f4',border:'2px solid #cba6f7'} }),
        ),
        React.createElement('div', { style:{display:'flex',justifyContent:'space-between',fontSize:10,color:'#a6adc8',marginTop:4} },
          React.createElement('span',null,'00:27'), React.createElement('span',null,'03:01'),
        ),
      ),
    ),
    // controls
    React.createElement('div', { style:{display:'flex',justifyContent:'center',alignItems:'center',gap:28} },
      React.createElement('div', { style:{width:40,height:40,borderRadius:20,background:'rgba(49,50,68,0.7)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,color:'#cdd6f4',cursor:'pointer'} }, '◀◀'),
      React.createElement('div', { onClick:()=>setPlaying(p=>!p), style:{width:56,height:56,borderRadius:28,background:'#cba6f7',display:'flex',alignItems:'center',justifyContent:'center',fontSize:22,color:'#1e1e2e',cursor:'pointer',boxShadow:'0 0 16px rgba(203,166,247,0.45)'} }, playing?'⏸':'▶'),
      React.createElement('div', { style:{width:40,height:40,borderRadius:20,background:'rgba(49,50,68,0.7)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,color:'#cdd6f4',cursor:'pointer'} }, '▶▶'),
    ),
    // EQ label
    React.createElement('div', { style:{display:'flex',alignItems:'center'} },
      React.createElement('span', { style:{fontSize:10,fontWeight:900,color:'#cba6f7',letterSpacing:'0.15em',flex:1} }, 'EQUALIZER'),
      React.createElement('span', { style:{fontSize:9,fontWeight:700,color:'#cba6f7',padding:'2px 8px',background:'rgba(203,166,247,0.15)',border:'1px solid rgba(203,166,247,0.4)',borderRadius:9999} }, preset),
    ),
    // EQ bands
    React.createElement('div', { style:{display:'flex',gap:5,height:68,alignItems:'flex-end'} },
      eqVals.map((v,i)=>React.createElement('div',{key:i,style:{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:2,height:'100%'}},
        React.createElement('span',{style:{fontSize:8,color:v!==0?'#cba6f7':'#6c7086'}},v>0?'+'+v:v),
        React.createElement('div',{style:{flex:1,width:5,background:'#313244',borderRadius:2,position:'relative',overflow:'hidden'}},
          React.createElement('div',{style:{position:'absolute',[v>0?'bottom':'top']:'50%',height:(Math.abs(v)/12*50)+'%',width:'100%',background:'linear-gradient(180deg,#cba6f7,#89b4fa)',borderRadius:2}})),
        React.createElement('span',{style:{fontSize:8,color:'#6c7086'}},eqLabels[i]),
      ))
    ),
    // preset chips
    React.createElement('div', { style:{display:'flex',gap:5} },
      presets.map(p=>React.createElement('div',{key:p,onClick:()=>setPreset(p),
        style:{flex:1,height:26,borderRadius:9999,display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:700,cursor:'pointer',
          background:p===preset?'#cba6f7':'rgba(49,50,68,0.6)',
          color:p===preset?'#1e1e2e':'#cdd6f4',
          border:`1px solid ${p===preset?'rgba(203,166,247,0.8)':'rgba(205,214,244,0.08)'}`,
          transition:'all 180ms'}},p))
    ),
  );
}

// ── Island sizes ──────────────────────────────────────────────────────────
const COLLAPSED_W = { clock:220, music:390, notifs:280 };
const EXPANDED_H  = { clock:230, music:460, notifs:200 };

function DynamicIsland({ page, onPageChange, onWidthChange }) {
  const [expanded, setExpanded] = React.useState(false);
  const [playing, setPlaying]   = React.useState(true);
  const [hovered, setHovered]   = React.useState(false);
  const [time, setTime]         = React.useState('11:17');

  const collapsedW = COLLAPSED_W[page] || 220;

  React.useEffect(() => {
    onWidthChange && onWidthChange(expanded ? 0 : collapsedW);
  }, [expanded, page]);

  React.useEffect(() => {
    const iv = setInterval(() => {
      const d = new Date();
      setTime(d.getHours().toString().padStart(2,'0')+':'+d.getMinutes().toString().padStart(2,'0'));
    }, 1000);
    return () => clearInterval(iv);
  }, []);

  const expandedW = Math.min(680, window.innerWidth - 32);
  const pages = ['clock','music','notifs'];

  return React.createElement('div', {
    style: { position:'fixed', top:0, left:0, right:0, display:'flex', justifyContent:'center', paddingTop:8, zIndex:200, pointerEvents:'none' }
  },
    React.createElement('div', {
      onClick: e => { e.stopPropagation(); if (!expanded) setExpanded(true); },
      onMouseEnter: () => setHovered(true),
      onMouseLeave: () => setHovered(false),
      style: {
        background: '#1e1e2e',
        // pill when collapsed, 28px radius when expanded
        borderRadius: expanded ? 28 : 9999,
        // no overflow hidden on outer — let content sit inside naturally
        boxShadow: expanded ? '0 16px 48px rgba(0,0,0,0.55)' : '0 8px 28px rgba(0,0,0,0.4)',
        cursor: expanded ? 'default' : 'pointer',
        pointerEvents: 'auto',
        width: expanded ? expandedW : collapsedW,
        height: expanded ? (EXPANDED_H[page] || 230) : 38,
        transition: 'width 540ms cubic-bezier(0.16,1,0.3,1), height 540ms cubic-bezier(0.16,1,0.3,1), border-radius 540ms cubic-bezier(0.16,1,0.3,1)',
        transform: hovered && !expanded ? 'scale(1.025)' : 'scale(1)',
        display: 'flex', flexDirection: 'column',
        position: 'relative',
        overflow: 'hidden',
      }
    },
      // collapsed content
      !expanded && React.createElement('div', { style:{height:38,display:'flex',alignItems:'center',flexShrink:0} },
        page==='clock'  && React.createElement(ClockCollapsed, { time }),
        page==='music'  && React.createElement(MusicCollapsed, { playing }),
        page==='notifs' && React.createElement(NotifCollapsed),
      ),
      // expanded content (scrollable if needed)
      expanded && React.createElement('div', { style:{flex:1,overflowY:'auto',overflowX:'hidden'} },
        page==='clock'  && React.createElement(ClockExpanded, { time }),
        page==='music'  && React.createElement(MusicExpanded, { playing, setPlaying }),
        page==='notifs' && React.createElement('div', { style:{padding:'20px 20px 72px',color:'#a6adc8',fontSize:12} }, 'No notifications'),
      ),
      // nav + close bar (pinned to bottom)
      expanded && React.createElement('div', {
        style: { position:'absolute', bottom:0, left:0, right:0, height:52,
          display:'flex', alignItems:'center', justifyContent:'center', gap:8,
          background:'linear-gradient(0deg, rgba(30,30,46,1) 60%, transparent)',
          borderRadius:'0 0 28px 28px' }
      },
        pages.map(p => React.createElement('div', {
          key: p,
          onClick: e => { e.stopPropagation(); onPageChange(p); },
          style: { width:p===page?18:7, height:7, borderRadius:9999,
            background:p===page?'#cba6f7':'rgba(205,214,244,0.2)',
            transition:'all 300ms', cursor:'pointer' }
        })),
        React.createElement('div', {
          onClick: e => { e.stopPropagation(); setExpanded(false); },
          style: { position:'absolute', right:14, width:24, height:24, borderRadius:12,
            background:'rgba(49,50,68,0.9)', display:'flex', alignItems:'center',
            justifyContent:'center', fontSize:11, color:'#a6adc8', cursor:'pointer' }
        }, '✕'),
      ),
    )
  );
}

Object.assign(window, { DynamicIsland, COLLAPSED_W });
