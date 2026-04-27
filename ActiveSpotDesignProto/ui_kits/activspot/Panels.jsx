// ActivSpot — Popup Panels (Music, Clock/Calendar, Battery, Notifications)

// ── Music Panel ────────────────────────────────────────────────────────────
function MusicPanel({ onClose }) {
  const [playing, setPlaying] = React.useState(true);
  const [preset, setPreset] = React.useState('Rock');
  const [progress, setProgress] = React.useState(36);
  const presets = ['Flat','Bass','Treble','Vocal','Pop','Rock'];
  const eqBands = [4,-2,6,8,3,-1,2,5,3,1];
  const labels  = ['32','64','125','250','500','1K','2K','4K','8K','16K'];

  return React.createElement('div', { style: panelStyle },
    // header
    React.createElement('div', { style: { display:'flex', alignItems:'center', gap:16, marginBottom:20 } },
      React.createElement('div', { style: { width:88, height:88, borderRadius:14, background:'linear-gradient(135deg,#cba6f7,#89b4fa)', flexShrink:0, boxShadow:'0 4px 16px rgba(0,0,0,0.4)' } }),
      React.createElement('div', { style:{ flex:1, minWidth:0 } },
        React.createElement('div', { style:{ fontSize:18, fontWeight:900, color:'#cdd6f4', marginBottom:4, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' } }, 'I Don\'t Care'),
        React.createElement('div', { style:{ fontSize:12, color:'#a6adc8', marginBottom:12 } }, 'VIOLENT VIRA'),
        // progress
        React.createElement('div', { style:{ position:'relative', height:4, background:'#313244', borderRadius:2, cursor:'pointer' },
          onClick: e => { const r = e.currentTarget.getBoundingClientRect(); setProgress(Math.round((e.clientX - r.left) / r.width * 100)); }
        },
          React.createElement('div', { style:{ height:'100%', width:progress+'%', background:'linear-gradient(90deg,#cba6f7,#89b4fa)', borderRadius:2 } }),
          React.createElement('div', { style:{ position:'absolute', top:'50%', left:progress+'%', transform:'translate(-50%,-50%)', width:12, height:12, borderRadius:6, background:'#cdd6f4', border:'2px solid #cba6f7' } }),
        ),
        React.createElement('div', { style:{ display:'flex', justifyContent:'space-between', marginTop:4, fontSize:10, color:'#a6adc8' } },
          React.createElement('span', null, '00:27'),
          React.createElement('span', null, '03:01'),
        ),
      ),
      React.createElement('button', { onClick: onClose, style:{ background:'none', border:'none', color:'#a6adc8', fontSize:16, cursor:'pointer', padding:4 } }, '✕'),
    ),
    // controls
    React.createElement('div', { style:{ display:'flex', justifyContent:'center', alignItems:'center', gap:24, marginBottom:20 } },
      React.createElement('div', { onClick:()=>{}, style: ctrlBtn(44) }, '◀◀'),
      React.createElement('div', { onClick:()=>setPlaying(p=>!p), style:{ ...ctrlBtn(56), background:'#cba6f7', color:'#1e1e2e', boxShadow:'0 0 16px rgba(203,166,247,0.45)', fontSize:22 } }, playing ? '⏸' : '▶'),
      React.createElement('div', { onClick:()=>{}, style: ctrlBtn(44) }, '▶▶'),
    ),
    // EQ label + preset badge
    React.createElement('div', { style:{ display:'flex', alignItems:'center', marginBottom:8 } },
      React.createElement('span', { style:{ fontSize:10, fontWeight:900, color:'#cba6f7', letterSpacing:'0.15em', flex:1 } }, 'EQUALIZER'),
      React.createElement('span', { style:{ fontSize:10, fontWeight:700, color:'#cba6f7', padding:'2px 8px', background:'rgba(203,166,247,0.15)', border:'1px solid rgba(203,166,247,0.4)', borderRadius:9999 } }, preset),
    ),
    // EQ bands
    React.createElement('div', { style:{ display:'flex', gap:6, height:80, alignItems:'flex-end', marginBottom:12 } },
      ...eqBands.map((v,i) => React.createElement('div', { key:i, style:{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', gap:3, height:'100%' } },
        React.createElement('span', { style:{ fontSize:8, color: v!==0 ? '#cba6f7' : '#6c7086' } }, v > 0 ? '+'+v : v),
        React.createElement('div', { style:{ flex:1, width:5, background:'#313244', borderRadius:2, position:'relative', overflow:'hidden' } },
          v > 0
            ? React.createElement('div', { style:{ position:'absolute', bottom:'50%', height:(Math.abs(v)/12*50)+'%', width:'100%', background:'linear-gradient(180deg,#cba6f7,#89b4fa)', borderRadius:2 } })
            : React.createElement('div', { style:{ position:'absolute', top:'50%', height:(Math.abs(v)/12*50)+'%', width:'100%', background:'linear-gradient(180deg,#cba6f7,#89b4fa)', borderRadius:2, opacity:0.7 } }),
        ),
        React.createElement('span', { style:{ fontSize:8, color:'#6c7086' } }, labels[i]),
      ))
    ),
    // preset chips
    React.createElement('div', { style:{ display:'flex', gap:6, flexWrap:'wrap' } },
      ...presets.map(p => React.createElement('div', {
        key: p, onClick: () => setPreset(p),
        style: {
          flex:1, height:26, borderRadius:9999, display:'flex', alignItems:'center', justifyContent:'center',
          fontSize:10, fontWeight:700, cursor:'pointer',
          background: p === preset ? '#cba6f7' : 'rgba(49,50,68,0.6)',
          color: p === preset ? '#1e1e2e' : '#cdd6f4',
          border: `1px solid ${p === preset ? 'rgba(203,166,247,0.8)' : 'rgba(205,214,244,0.08)'}`,
          transition: 'all 180ms',
        }
      }, p))
    ),
  );
}

// ── Battery Panel ──────────────────────────────────────────────────────────
function BatteryPanel({ onClose }) {
  const [mode, setMode] = React.useState('Performa');
  const modes = ['Performa','Balance','Saver'];
  return React.createElement('div', { style: { ...panelStyle, width: 280 } },
    React.createElement('div', { style:{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:16 } },
      React.createElement('span', { style:{ fontSize:11, fontWeight:900, color:'#cba6f7', letterSpacing:'0.12em' } }, 'BATTERY'),
      React.createElement('button', { onClick: onClose, style:{ background:'none', border:'none', color:'#a6adc8', fontSize:16, cursor:'pointer' } }, '✕'),
    ),
    React.createElement('div', { style:{ display:'flex', justifyContent:'center', marginBottom:20 } },
      React.createElement('div', { style:{ position:'relative', width:120, height:120 } },
        React.createElement('svg', { width:120, height:120, viewBox:'0 0 120 120' },
          React.createElement('circle', { cx:60, cy:60, r:50, fill:'none', stroke:'#313244', strokeWidth:10 }),
          React.createElement('circle', { cx:60, cy:60, r:50, fill:'none', stroke:'url(#batGrad)', strokeWidth:10,
            strokeDasharray: `${Math.PI*100*0.54} ${Math.PI*100}`, strokeDashoffset: Math.PI*100*0.25,
            strokeLinecap:'round', transform:'rotate(-90 60 60)' }),
          React.createElement('defs', null,
            React.createElement('linearGradient', { id:'batGrad', x1:'0%', y1:'0%', x2:'100%', y2:'0%' },
              React.createElement('stop', { offset:'0%', stopColor:'#a6e3a1' }),
              React.createElement('stop', { offset:'100%', stopColor:'#b9f0b5' }),
            )
          ),
        ),
        React.createElement('div', { style:{ position:'absolute', inset:0, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center' } },
          React.createElement('span', { style:{ fontSize:24, fontWeight:900, color:'#cdd6f4' } }, '54%'),
          React.createElement('span', { style:{ fontSize:9, color:'#a6adc8', letterSpacing:'0.08em' } }, 'DISCHARGING'),
        ),
      ),
    ),
    React.createElement('div', { style:{ display:'flex', gap:6 } },
      ...modes.map(m => React.createElement('div', {
        key:m, onClick:()=>setMode(m),
        style:{ flex:1, height:28, borderRadius:9999, display:'flex', alignItems:'center', justifyContent:'center', fontSize:10, fontWeight:700, cursor:'pointer',
          background: m===mode ? 'rgba(203,166,247,0.2)' : 'rgba(49,50,68,0.5)',
          color: m===mode ? '#cba6f7' : '#a6adc8',
          border:`1px solid ${m===mode ? 'rgba(203,166,247,0.4)' : 'rgba(205,214,244,0.07)'}`,
          transition:'all 180ms' }
      }, m))
    ),
  );
}

// ── Notifications Panel ────────────────────────────────────────────────────
const NOTIFS = [
  { app:'Discord', title:'New message in #general', body:'dxvmxn: hey are you free?', accent:'#cba6f7' },
  { app:'System',  title:'Package update available', body:'hyprland 0.45.0', accent:'#89b4fa' },
  { app:'Build',   title:'Compilation succeeded',   body:'quickshell · 4.2s', accent:'#a6e3a1' },
];

function NotifsPanel({ onClose }) {
  const [items, setItems] = React.useState(NOTIFS);
  const [dnd, setDnd] = React.useState(false);
  return React.createElement('div', { style: panelStyle },
    React.createElement('div', { style:{ display:'flex', alignItems:'center', gap:8, marginBottom:14 } },
      React.createElement('span', { style:{ fontSize:10, fontWeight:900, color:'#cba6f7', letterSpacing:'0.15em', flex:1 } }, 'NOTIFICATIONS'),
      React.createElement('div', { onClick:()=>setDnd(d=>!d), style:{ padding:'3px 10px', borderRadius:9999, fontSize:10, fontWeight:700, cursor:'pointer',
        background: dnd ? 'rgba(203,166,247,0.22)' : 'rgba(49,50,68,0.5)',
        color: dnd ? '#cba6f7' : '#a6adc8',
        border:`1px solid ${dnd ? 'rgba(203,166,247,0.5)' : 'rgba(205,214,244,0.08)'}` } }, dnd ? '◉ DND' : '◎ DND'),
      React.createElement('div', { onClick:()=>setItems([]), style:{ padding:'3px 10px', borderRadius:9999, fontSize:10, color:'#a6adc8', background:'rgba(49,50,68,0.5)', border:'1px solid rgba(205,214,244,0.08)', cursor:'pointer' } }, 'Clear'),
      React.createElement('button', { onClick:onClose, style:{ background:'none',border:'none',color:'#a6adc8',fontSize:14,cursor:'pointer',padding:2 } }, '✕'),
    ),
    items.length === 0
      ? React.createElement('div', { style:{ textAlign:'center', padding:'24px 0', color:'#585b70', fontSize:12 } }, 'No notifications')
      : React.createElement('div', { style:{ display:'flex', flexDirection:'column', gap:5 } },
          ...items.map((n,i) => React.createElement('div', { key:i, style:{ background:'rgba(49,50,68,0.55)', border:'1px solid rgba(205,214,244,0.07)', borderRadius:12, height:52, display:'flex', alignItems:'center', padding:'0 8px', gap:8 } },
            React.createElement('div', { style:{ width:3, alignSelf:'stretch', margin:'10px 0', borderRadius:2, background:n.accent, opacity:0.75, flexShrink:0 } }),
            React.createElement('div', { style:{ width:32, height:32, borderRadius:9, background:`rgba(${hexToRgb(n.accent)},0.12)`, flexShrink:0, display:'flex', alignItems:'center', justifyContent:'center', fontSize:14, color:n.accent } }, n.app[0]),
            React.createElement('div', { style:{ flex:1, minWidth:0 } },
              React.createElement('div', { style:{ fontSize:11, fontWeight:700, color:'#cdd6f4', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' } }, n.app + '  ·  ' + n.title),
              React.createElement('div', { style:{ fontSize:10, color:'#a6adc8', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' } }, n.body),
            ),
            React.createElement('div', { onClick:()=>setItems(prev=>prev.filter((_,j)=>j!==i)), style:{ width:20, height:20, borderRadius:10, display:'flex', alignItems:'center', justifyContent:'center', fontSize:10, color:'#a6adc8', cursor:'pointer', background:'rgba(69,71,90,0.4)' } }, '✕'),
          ))
        ),
  );
}

// ── Shared helpers ─────────────────────────────────────────────────────────
const panelStyle = {
  background: 'rgba(30,30,46,0.96)',
  backdropFilter: 'blur(24px)',
  border: '1px solid rgba(205,214,244,0.07)',
  borderRadius: 20,
  padding: 20,
  boxShadow: '0 16px 48px rgba(0,0,0,0.5)',
  fontFamily: "'JetBrains Mono', monospace",
  minWidth: 340,
  maxWidth: 420,
};

function ctrlBtn(size) {
  return { width:size, height:size, borderRadius:size/2, background:'rgba(49,50,68,0.7)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:size===56?22:16, color:'#cdd6f4', cursor:'pointer', border:'none', transition:'transform 200ms', userSelect:'none' };
}

function hexToRgb(hex) {
  const r = parseInt(hex.slice(1,3),16);
  const g = parseInt(hex.slice(3,5),16);
  const b = parseInt(hex.slice(5,7),16);
  return `${r},${g},${b}`;
}

Object.assign(window, { MusicPanel, BatteryPanel, NotifsPanel, panelStyle, ctrlBtn, hexToRgb });
