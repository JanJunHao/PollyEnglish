// tabbar.jsx — Bottom tab bar shared by 探索 / 我的

function BottomTabBar({ active, onChange, brand }) {
  const tabs = [
    { id: 'discover', icon: 'compass', label: '探索' },
    { id: 'files', icon: 'folder', label: '文件' },
    { id: 'me', icon: 'person', label: '我的' },
  ];

  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      paddingBottom: 30, paddingTop: 6,
      background: 'var(--tab-bar-bg)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      borderTop: '0.5px solid var(--divider)',
      display: 'flex', justifyContent: 'space-around',
      zIndex: 50,
    }}>
      {tabs.map((tab) => (
        <button key={tab.id} onClick={() => onChange(tab.id)} style={{
          flex: 1, background: 'transparent', border: 'none', cursor: 'pointer',
          padding: '6px 4px',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
        }}>
          <Icon name={tab.icon} size={22}
            color={active === tab.id ? brand : 'var(--text-ter)'}/>
          <span style={{
            fontFamily: '"PingFang SC", sans-serif', fontSize: 10.5, fontWeight: 500,
            color: active === tab.id ? brand : 'var(--text-sec)',
            letterSpacing: 0.3,
          }}>{tab.label}</span>
        </button>
      ))}
    </div>
  );
}

window.BottomTabBar = BottomTabBar;
