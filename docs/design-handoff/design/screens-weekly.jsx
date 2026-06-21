// screens-weekly.jsx — the hero: Weekly Status Report

function MetricRow({ m, onOpen }) {
  const color = m.color || (m.accent2 ? 'var(--accent2)' : 'var(--accent)');
  return (
    <div onClick={() => onOpen && onOpen(m.key)} style={{
      display: 'flex', alignItems: 'center', gap: 14, padding: '13px 0',
      cursor: onOpen ? 'pointer' : 'default',
    }}>
      <div style={{ width: 38, height: 38, borderRadius: 11, flexShrink: 0,
                    display: 'grid', placeItems: 'center',
                    background: 'rgba(255,255,255,0.05)' }}>
        <Icon name={m.icon} size={19} color={color} stroke={2} fill={m.icon === 'heart' ? color : 'none'} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 12.5, color: 'var(--text-2)', marginBottom: 2 }}>{m.label}</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 5 }}>
          <span style={{ fontSize: 21, fontWeight: 680, letterSpacing: '-.02em' }}>{m.value}</span>
          <span style={{ fontSize: 11.5, color: 'var(--text-3)', fontFamily: 'var(--mono)' }}>{m.unit}</span>
        </div>
      </div>
      <Sparkline data={m.series} color={color} width={76} height={32} />
      <div style={{ width: 52, textAlign: 'right' }}>
        <Delta value={m.delta} good={m.good} />
      </div>
    </div>
  );
}

function WeeklyScreen({ onOpenMetric }) {
  const w = DATA.week;
  const [regen, setRegen] = React.useState(false);
  const doRegen = () => { setRegen(true); setTimeout(() => setRegen(false), 1400); };

  return (
    <div className="screen">
      {/* header */}
      <div style={{ padding: '0 20px 6px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <div style={{ fontSize: 12.5, fontFamily: 'var(--mono)', color: 'var(--text-3)',
                          letterSpacing: '.06em', textTransform: 'uppercase' }}>Weekly Report</div>
            <h1 style={{ fontSize: 28, fontWeight: 740, letterSpacing: '-.025em', margin: '4px 0 0' }}>{w.range}</h1>
          </div>
        </div>
      </div>

      <div style={{ padding: '14px 16px 0', display: 'flex', flexDirection: 'column', gap: 16 }}>

        {/* status hero card */}
        <Card pad={20} glow style={{ position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -50, right: -50, width: 180, height: 180,
                        borderRadius: '50%', background: 'var(--accent-soft)', filter: 'blur(8px)' }} />
          <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 20 }}>
            <Ring size={108} stroke={11} value={w.statusScore} max={100}
                  gradient={['var(--accent2)', 'var(--accent)']}>
              <span style={{ fontSize: 30, fontWeight: 760, letterSpacing: '-.03em', lineHeight: 1 }}>{w.statusScore}</span>
              <span style={{ fontSize: 10.5, fontFamily: 'var(--mono)', color: 'var(--text-3)',
                             marginTop: 2, letterSpacing: '.04em' }}>/ 100</span>
            </Ring>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '4px 10px',
                            borderRadius: 999, background: 'var(--good-soft)', marginBottom: 8 }}>
                <span style={{ width: 6, height: 6, borderRadius: 99, background: 'var(--good)' }} />
                <span style={{ fontSize: 12.5, fontWeight: 650, color: 'var(--good)' }}>{w.status}</span>
              </div>
              <div style={{ fontSize: 14.5, color: 'var(--text-2)', lineHeight: 1.45 }}>
                Your health score rose <b style={{ color: 'var(--text)' }}>+6 points</b> this week, driven by activity and recovery gains.
              </div>
            </div>
          </div>
        </Card>

        {/* AI summary */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                        margin: '0 2px 10px' }}>
            <GemmaChip label="Summary · on-device" />
            <button onClick={doRegen} style={{
              display: 'inline-flex', alignItems: 'center', gap: 5, background: 'none',
              border: 'none', color: 'var(--text-3)', fontSize: 12.5, cursor: 'pointer',
              fontFamily: 'var(--mono)', padding: 4 }}>
              <span style={{ display: 'inline-flex', animation: regen ? 'spin 1s linear infinite' : 'none' }}>
                <Icon name="refresh" size={14} color="var(--text-3)" stroke={2} />
              </span>
              {regen ? 'Analyzing…' : 'Regenerate'}
            </button>
          </div>
          <Card pad={18}>
            <p style={{ margin: 0, fontSize: 15.5, lineHeight: 1.62, color: 'var(--text)',
                        opacity: regen ? 0.35 : 1, transition: 'opacity .3s',
                        textWrap: 'pretty' }}>
              {w.summary}
            </p>
          </Card>
        </div>

        {/* metrics */}
        <div>
          <SectionLabel>This week vs last</SectionLabel>
          <Card pad={'2px 18px'}>
            {w.metrics.map((m, i) => (
              <div key={m.key} style={{ borderTop: i ? '1px solid var(--hair)' : 'none' }}>
                <MetricRow m={m} onOpen={onOpenMetric} />
              </div>
            ))}
          </Card>
        </div>

        {/* steps bar chart */}
        <div>
          <SectionLabel>Daily steps</SectionLabel>
          <Card pad={18}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 4 }}>
              <span style={{ fontSize: 24, fontWeight: 720, letterSpacing: '-.02em' }}>8,240</span>
              <span style={{ fontSize: 12.5, color: 'var(--text-3)', fontFamily: 'var(--mono)' }}>avg/day</span>
              <span style={{ marginLeft: 'auto' }}><Delta value={9} good /></span>
            </div>
            <BarChart data={w.stepsByDay} labels={w.dayLabels} goal={10000}
                      color="var(--accent)" height={120} />
          </Card>
        </div>

        {/* highlights + watch-outs */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <Card pad={16}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
              <Icon name="check" size={16} color="var(--good)" stroke={2.4} />
              <span style={{ fontSize: 13, fontWeight: 650, color: 'var(--good)',
                             fontFamily: 'var(--mono)', letterSpacing: '.04em', textTransform: 'uppercase' }}>Highlights</span>
            </div>
            {w.highlights.map((h, i) => (
              <div key={i} style={{ display: 'flex', gap: 10, padding: '6px 0',
                                    borderTop: i ? '1px solid var(--hair)' : 'none', marginTop: i ? 6 : 0,
                                    paddingTop: i ? 12 : 6 }}>
                <span style={{ width: 5, height: 5, borderRadius: 99, background: 'var(--good)',
                               marginTop: 7, flexShrink: 0 }} />
                <span style={{ fontSize: 14, lineHeight: 1.5, color: 'var(--text-2)' }}>{h}</span>
              </div>
            ))}
          </Card>
          <Card pad={16}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
              <Icon name="target" size={16} color="var(--accent)" stroke={2} />
              <span style={{ fontSize: 13, fontWeight: 650, color: 'var(--accent)',
                             fontFamily: 'var(--mono)', letterSpacing: '.04em', textTransform: 'uppercase' }}>Watch-outs</span>
            </div>
            {w.watch.map((h, i) => (
              <div key={i} style={{ display: 'flex', gap: 10, padding: '6px 0',
                                    borderTop: i ? '1px solid var(--hair)' : 'none', marginTop: i ? 6 : 0,
                                    paddingTop: i ? 12 : 6 }}>
                <span style={{ width: 5, height: 5, borderRadius: 99, background: 'var(--accent)',
                               marginTop: 7, flexShrink: 0 }} />
                <span style={{ fontSize: 14, lineHeight: 1.5, color: 'var(--text-2)' }}>{h}</span>
              </div>
            ))}
          </Card>
        </div>

        {/* focus next week */}
        <div>
          <SectionLabel>Focus next week</SectionLabel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {w.focus.map((f, i) => (
              <Card key={i} pad={16}>
                <div style={{ display: 'flex', gap: 13 }}>
                  <div style={{ width: 34, height: 34, borderRadius: 10, flexShrink: 0,
                                display: 'grid', placeItems: 'center', background: 'var(--accent-soft)' }}>
                    <Icon name={f.icon} size={17} color="var(--accent)" stroke={2}
                          fill={f.icon === 'heart' ? 'var(--accent)' : 'none'} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 14.5, fontWeight: 650, marginBottom: 3 }}>{f.title}</div>
                    <div style={{ fontSize: 13.5, color: 'var(--text-2)', lineHeight: 1.5 }}>{f.body}</div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* diet teaser — future feature */}
        <Card pad={18} style={{ borderStyle: 'dashed', borderColor: 'var(--hair-strong)',
                                 background: 'transparent' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 13 }}>
            <div style={{ width: 38, height: 38, borderRadius: 11, flexShrink: 0,
                          display: 'grid', placeItems: 'center', background: 'rgba(255,255,255,0.04)' }}>
              <Icon name="leaf" size={19} color="var(--text-3)" stroke={1.9} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontSize: 14.5, fontWeight: 650, color: 'var(--text-2)' }}>Diet recommendations</span>
                <span style={{ fontSize: 10, fontFamily: 'var(--mono)', color: 'var(--text-3)',
                               border: '1px solid var(--hair-strong)', borderRadius: 5, padding: '2px 6px',
                               letterSpacing: '.06em' }}>SOON</span>
              </div>
              <div style={{ fontSize: 13, color: 'var(--text-3)', marginTop: 3, lineHeight: 1.45 }}>
                Personalized meals from your activity & sleep, generated on-device.
              </div>
            </div>
            <Icon name="lock" size={16} color="var(--text-3)" stroke={1.8} />
          </div>
        </Card>

        <div style={{ textAlign: 'center', padding: '4px 0 8px' }}>
          <span style={{ fontSize: 11, fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>
            Analyzed locally · Gemma 3n · {w.range}
          </span>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { WeeklyScreen });
