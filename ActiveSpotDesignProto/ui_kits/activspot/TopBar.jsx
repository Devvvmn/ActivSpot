// ActivSpot TopBar — React component
// Draggable applets, edit mode wiggle, battery gradient

function TopBarApplet({ children, style = {}, onClick, glow }) {
  const [hov, setHov] = React.useState(false);
  return React.createElement('div', {
    onClick,
    onMouseEnter: () => setHov(true),
    onMouseLeave: () => setHov(false),
    style: {
      height: 32,
      borderRadius: 9999,
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 6,
      padding: '0 12px',
      border: '1px solid rgba(205,214,244,0.05)',
      fontSize: 12,
      fontWeight: 700,
      whiteSpace: 'nowrap',
      cursor: 'pointer',
      transform: hov ? 'scale(1.05)' : 'scale(1)',
      transition: 'transform 250ms cubic-bezier(0.16,1,0.3,1), background 180ms ease',
      userSelect: 'none',
      boxShadow: glow || 'none',
      ...style,
    }
  }, children);
}

function WorkspacesApplet({ active = 5 }) {
  const nums = [1,2,3,4,5,6,7,8];
  return React.createElement('div', {
    style: { height: 32, borderRadius: 9999, display: 'inline-flex', alignItems: 'center', gap: 3, padding: '0 8px', background: 'rgba(49,50,68,0.5)', border: '1px solid rgba(205,214,244,0.05)' }
  }, nums.map(n => React.createElement('div', {
    key: n,
    style: {
      width: 24, height: 24, borderRadius: 12,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 11, fontWeight: 700,
      background: n === active ? 'rgba(203,166,247,0.2)' : 'rgba(205,214,244,0.07)',
      color: n === active ? '#cba6f7' : '#a6adc8',
      transition: 'background 200ms, color 200ms',
    }
  }, n)));
}

function TopBar({ onAppletClick }) {
  return React.createElement('div', {
    style: {
      position: 'fixed', top: 0, left: 0, right: 0,
      height: 48,
      display: 'flex', alignItems: 'center',
      padding: '0 12px',
      gap: 5,
      zIndex: 100,
      fontFamily: "'JetBrains Mono', monospace",
    }
  },
    React.createElement(WorkspacesApplet, { active: 5 }),
    React.createElement(TopBarApplet, { style: { background: 'rgba(49,50,68,0.5)', color: '#cdd6f4' } }, 'EN'),
    React.createElement('div', { style: { flex: 1 } }),
    React.createElement(TopBarApplet, {
      style: { background: 'rgba(49,50,68,0.5)', color: '#cdd6f4' },
      onClick: () => onAppletClick && onAppletClick('network')
    }, '▪ Fibernet-IA...'),
    React.createElement(TopBarApplet, {
      style: { background: 'rgba(49,50,68,0.5)', color: '#a6adc8' },
      onClick: () => onAppletClick && onAppletClick('network')
    }, '⊹ Disconnected'),
    React.createElement(TopBarApplet, {
      style: { background: 'linear-gradient(90deg,#a6e3a1,#b9f0b5)', color: '#1e1e2e', border: 'none' },
      onClick: () => onAppletClick && onAppletClick('battery'),
      glow: '0 0 10px rgba(166,227,161,0.3)'
    }, '▮ 54%'),
  );
}

Object.assign(window, { TopBar, TopBarApplet, WorkspacesApplet });
