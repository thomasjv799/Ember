// app.jsx — Vesta shell: theming, navigation, tab bar, tweaks

const ACCENTS = {
  Rouge: { accent: '#fb3b5a', accent2: '#ff8a8f', soft: 'rgba(251,59,90,0.22)', line: 'rgba(251,59,90,0.46)' },
  Amber: { accent: '#ff6a3d', accent2: '#ffb13c', soft: 'rgba(255,106,61,0.22)', line: 'rgba(255,106,61,0.45)' },
  Iris:  { accent: '#a85cff', accent2: '#d98aff', soft: 'rgba(168,92,255,0.22)', line: 'rgba(168,92,255,0.46)' },
  Mint:  { accent: '#10e08a', accent2: '#67f0c4', soft: 'rgba(16,224,138,0.20)', line: 'rgba(16,224,138,0.45)' },
};

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "Rouge",
  "radius": 22,
  "cardStyle": "Elevated",
  "privacyBanner": true
}/*EDITMODE-END*/;

const TABS = [
  { key: 'home', label: 'Today', icon: 'home' },
  { key: 'weekly', label: 'Weekly', icon: 'weekly' },
  { key: 'insights', label: 'Insights', icon: 'spark' },
  { key: 'chat', label: 'Ask', icon: 'chat' },
  { key: 'settings', label: 'Settings', icon: 'sliders' },
];

function TabBar({ active, onChange }) {
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 30,
      paddingBottom: 26, paddingTop: 10,
      background: 'linear-gradient(to top, var(--bg) 62%, transparent)',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-around', alignItems: 'center',
                    padding: '0 12px' }}>
        {TABS.map(t => {
          const on = active === t.key;
          return (
            <button key={t.key} onClick={() => onChange(t.key)} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              background: 'none', border: 'none', cursor: 'pointer', padding: '4px 14px',
              fontFamily: 'inherit',
            }}>
              <Icon name={t.icon} size={23} stroke={on ? 2.3 : 2}
                    color={on ? 'var(--accent)' : 'var(--text-3)'} />
              <span style={{ fontSize: 10.5, fontWeight: on ? 680 : 540,
                             color: on ? 'var(--accent)' : 'var(--text-3)',
                             letterSpacing: '.01em' }}>{t.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// header bar with optional back button (for detail)
function TopBar({ back, onBack, right }) {
  return (
    <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 25,
                  height: 92, display: 'flex', alignItems: 'flex-end', padding: '0 14px 6px',
                  pointerEvents: 'none' }}>
      {back && (
        <button onClick={onBack} style={{ pointerEvents: 'auto', width: 38, height: 38, borderRadius: 99,
                      background: 'var(--surface)', border: 'var(--card-border)', display: 'grid',
                      placeItems: 'center', cursor: 'pointer' }}>
          <Icon name="chevronL" size={20} color="var(--text)" stroke={2.2} />
        </button>
      )}
    </div>
  );
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [onboarded, setOnboarded] = React.useState(() => localStorage.getItem('vesta_onboarded') === '1');
  const [tab, setTab] = React.useState('home');
  const [detail, setDetail] = React.useState(null); // metric key or null
  const scrollRef = React.useRef(null);

  const a = ACCENTS[t.accent] || ACCENTS.Rouge;
  const elevated = t.cardStyle === 'Elevated';

  const themeVars = {
    '--bg': '#0c0b0a',
    '--bg2': '#141210',
    '--surface': elevated ? '#1a1714' : 'rgba(255,255,255,0.025)',
    '--text': '#f4f0ea',
    '--text-2': 'rgba(244,240,234,0.62)',
    '--text-3': 'rgba(244,240,234,0.38)',
    '--accent': a.accent,
    '--accent2': a.accent2,
    '--accent-soft': a.soft,
    '--accent-line': a.line,
    '--good': '#5ec98a',
    '--good-soft': 'rgba(94,201,138,0.14)',
    '--hair': 'rgba(255,255,255,0.07)',
    '--hair-strong': 'rgba(255,255,255,0.14)',
    '--radius': t.radius + 'px',
    '--card-border': elevated ? '1px solid rgba(255,255,255,0.07)' : '1px solid rgba(255,255,255,0.10)',
    '--card-shadow': elevated ? '0 4px 24px -12px rgba(0,0,0,0.6)' : 'none',
    '--mono': "ui-monospace, 'SF Mono', 'Roboto Mono', Menlo, monospace",
  };

  const openMetric = (m) => { setDetail(m); if (scrollRef.current) scrollRef.current.scrollTop = 0; };
  const goTab = (k) => { setDetail(null); setTab(k); if (scrollRef.current) scrollRef.current.scrollTop = 0; };

  // reset scroll on view change
  React.useEffect(() => { if (scrollRef.current) scrollRef.current.scrollTop = 0; }, [tab, detail]);

  const finishOnboarding = () => { localStorage.setItem('vesta_onboarded', '1'); setOnboarded(true); };

  let screen;
  if (detail) screen = <DetailScreen metric={detail} />;
  else if (tab === 'home') screen = <HomeScreen onOpenMetric={openMetric} goWeekly={() => goTab('weekly')} goInsights={() => goTab('insights')} />;
  else if (tab === 'weekly') screen = <WeeklyScreen onOpenMetric={openMetric} />;
  else if (tab === 'insights') screen = <InsightsScreen onOpenMetric={openMetric} />;
  else if (tab === 'chat') screen = <ChatScreen />;
  else screen = <SettingsScreen />;
  const isChat = tab === 'chat' && !detail;

  return (
    <div style={themeVars}>
      <IOSDevice dark>
        <div style={{ position: 'absolute', inset: 0, background: 'var(--bg)',
                      fontFamily: "-apple-system, 'SF Pro Display', system-ui, sans-serif",
                      color: 'var(--text)', WebkitFontSmoothing: 'antialiased' }}>

          {!onboarded && <Onboarding onDone={finishOnboarding} />}

          {/* privacy banner */}
          {onboarded && t.privacyBanner && !detail && !isChat && (
            <div style={{ position: 'absolute', top: 54, left: 16, right: 16, zIndex: 24,
                          display: 'flex', alignItems: 'center', gap: 7, padding: '7px 12px',
                          borderRadius: 11, background: 'var(--accent-soft)',
                          border: '1px solid var(--accent-line)', backdropFilter: 'blur(8px)' }}>
              <Icon name="shield" size={13} color="var(--accent)" stroke={1.9} />
              <span style={{ fontSize: 11.5, fontFamily: 'var(--mono)', color: 'var(--accent)',
                             letterSpacing: '.01em' }}>On-device · your data stays on this iPhone</span>
            </div>
          )}

          <TopBar back={!!detail} onBack={() => setDetail(null)} />

          {/* scroll area */}
          <div ref={scrollRef} style={{ position: 'absolute', inset: 0,
                        overflowY: isChat ? 'hidden' : 'auto',
                        display: isChat ? 'flex' : 'block', flexDirection: 'column',
                        paddingTop: isChat ? 54 : ((onboarded && t.privacyBanner && !detail) ? 96 : 64),
                        paddingBottom: isChat ? 86 : 104, WebkitOverflowScrolling: 'touch' }}>
            {screen}
          </div>

          {onboarded && !detail && <TabBar active={tab} onChange={goTab} />}
        </div>
      </IOSDevice>

      <TweaksPanel>
        <TweakSection label="Theme" />
        <TweakRadio label="Accent" value={t.accent} options={['Rouge', 'Amber', 'Iris', 'Mint']}
                    onChange={(v) => setTweak('accent', v)} />
        <TweakRadio label="Cards" value={t.cardStyle} options={['Elevated', 'Outlined']}
                    onChange={(v) => setTweak('cardStyle', v)} />
        <TweakSlider label="Corner radius" value={t.radius} min={10} max={30} unit="px"
                     onChange={(v) => setTweak('radius', v)} />
        <TweakSection label="Privacy" />
        <TweakToggle label="On-device banner" value={t.privacyBanner}
                     onChange={(v) => setTweak('privacyBanner', v)} />
        <TweakSection label="Demo" />
        <TweakButton label="Replay onboarding" onClick={() => { localStorage.removeItem('vesta_onboarded'); setOnboarded(false); }} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
