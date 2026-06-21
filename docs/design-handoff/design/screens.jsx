// screens.jsx — Home, Insights, Detail, Settings, Onboarding

// ───────────────────────── HOME ─────────────────────────
function MetricTile({ icon, color, label, value, unit, sub, onClick, fill }) {
  return (
    <Card pad={15} onClick={onClick} style={{ flex: 1 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div style={{ width: 32, height: 32, borderRadius: 9, display: 'grid', placeItems: 'center',
                      background: 'rgba(255,255,255,0.05)' }}>
          <Icon name={icon} size={17} color={color} stroke={2} fill={fill ? color : 'none'} />
        </div>
        {sub}
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
        <span style={{ fontSize: 23, fontWeight: 700, letterSpacing: '-.02em' }}>{value}</span>
        <span style={{ fontSize: 11.5, color: 'var(--text-3)', fontFamily: 'var(--mono)' }}>{unit}</span>
      </div>
      <div style={{ fontSize: 12.5, color: 'var(--text-2)', marginTop: 2 }}>{label}</div>
    </Card>
  );
}

function HomeScreen({ onOpenMetric, goWeekly, goInsights }) {
  const t = DATA.today;
  const stepPct = Math.round((t.steps / t.stepGoal) * 100);
  const top = DATA.insights[0];
  return (
    <div className="screen">
      <div style={{ padding: '0 20px 2px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 13, fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>{t.date}</div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, padding: '4px 10px',
                        borderRadius: 999, background: 'var(--accent-soft)', border: '1px solid var(--accent-line)' }}>
            <span className="flicker" style={{ display: 'inline-flex' }}>
              <Icon name="flame" size={13} color="var(--accent)" stroke={2} fill="var(--accent)" />
            </span>
            <span style={{ fontSize: 11.5, fontWeight: 700, color: 'var(--accent)', fontFamily: 'var(--mono)' }}>5-day streak</span>
          </div>
        </div>
        <h1 style={{ fontSize: 27, fontWeight: 740, letterSpacing: '-.025em', margin: '4px 0 0' }}>
          Good morning, {DATA.user.name} 👋
        </h1>
      </div>

      <div style={{ padding: '16px 16px 0', display: 'flex', flexDirection: 'column', gap: 16 }}>

        {/* weekly report ready banner — entry to hero */}
        <Card pad={16} glow onClick={goWeekly} style={{ position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -40, right: -30, width: 130, height: 130,
                        borderRadius: '50%', background: 'var(--accent-soft)', filter: 'blur(6px)' }} />
          <div className="sheen-bar" />
          <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 14 }}>
            <div className="floaty glow-pulse" style={{ width: 44, height: 44, borderRadius: 13, flexShrink: 0, display: 'grid',
                          placeItems: 'center', background: 'var(--accent)', }}>
              <Icon name="weekly" size={22} color="#1a1410" stroke={2.1} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                <span style={{ fontSize: 15.5, fontWeight: 680 }}>Your weekly report is ready</span>
              </div>
              <div style={{ fontSize: 12.5, color: 'var(--text-2)', marginTop: 2,
                            display: 'flex', alignItems: 'center', gap: 6 }}>
                <span className="live-dot" style={{ width: 5, height: 5, borderRadius: 99, background: 'var(--good)' }} />
                On track · score 78 · {DATA.week.range}
              </div>
            </div>
            <Icon name="chevron" size={18} color="var(--text-3)" stroke={2.2} />
          </div>
        </Card>

        {/* steps ring focus */}
        <Card pad={18}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
            <Ring size={120} stroke={12} value={t.steps} max={t.stepGoal}
                  gradient={['var(--accent2)', 'var(--accent)']}>
              <Icon name="steps" size={20} color="var(--accent)" stroke={2.2} />
              <span style={{ fontSize: 25, fontWeight: 740, letterSpacing: '-.03em', marginTop: 3, lineHeight: 1 }}>
                {(t.steps / 1000).toFixed(1)}k
              </span>
              <span style={{ fontSize: 10, fontFamily: 'var(--mono)', color: 'var(--text-3)', marginTop: 1 }}>
                of {t.stepGoal / 1000}k
              </span>
            </Ring>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12.5, fontFamily: 'var(--mono)', color: 'var(--text-3)',
                            textTransform: 'uppercase', letterSpacing: '.06em', marginBottom: 4 }}>Steps today</div>
              <div style={{ fontSize: 32, fontWeight: 760, letterSpacing: '-.03em', lineHeight: 1 }}>
                {t.steps.toLocaleString()}
              </div>
              <div style={{ fontSize: 13.5, color: 'var(--text-2)', marginTop: 8, lineHeight: 1.4 }}>
                <b style={{ color: 'var(--accent)' }}>{t.stepGoal - t.steps} steps</b> to your goal —
                about a 22-min walk.
              </div>
            </div>
          </div>
        </Card>

        {/* metric grid */}
        <div style={{ display: 'flex', gap: 12 }}>
          <MetricTile icon="heart" color="#e8596a" fill value={t.restingHR} unit="bpm"
                      label="Resting heart rate" onClick={() => onOpenMetric('hr')}
                      sub={<Delta value={-3} good />} />
          <MetricTile icon="moon" color="#8a8fe6" value={t.sleep} unit="" label="Last night's sleep"
                      onClick={() => onOpenMetric('sleep')} sub={<Delta value={-6} good={false} />} />
        </div>
        <div style={{ display: 'flex', gap: 12, marginTop: -4 }}>
          <MetricTile icon="flame" color="var(--accent2)" value={t.activeEnergy} unit="kcal"
                      label="Active energy" sub={<Delta value={4} good />} />
          <MetricTile icon="spark" color="var(--accent)" value={`${t.exercise}`} unit="min"
                      label="Exercise" sub={
                        <span style={{ fontSize: 11, fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>
                          {t.exercise}/{t.exerciseGoal}
                        </span>} />
        </div>

        {/* this week mini graph */}
        <div>
          <SectionLabel action="Report" onAction={goWeekly}>This week</SectionLabel>
          <Card pad={18}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 12 }}>
              <span style={{ fontSize: 22, fontWeight: 720, letterSpacing: '-.02em' }}>57,680</span>
              <span style={{ fontSize: 12.5, color: 'var(--text-3)', fontFamily: 'var(--mono)' }}>steps · 7 days</span>
              <span style={{ marginLeft: 'auto' }}><Delta value={9} good /></span>
            </div>
            <BarChart data={DATA.week.stepsByDay} labels={DATA.week.dayLabels} goal={10000}
                      color="var(--accent)" height={92} />
          </Card>
        </div>

        {/* today's suggestion */}
        <div>
          <SectionLabel action="See all" onAction={goInsights}>Today's suggestion</SectionLabel>
          <Card pad={16} onClick={goInsights}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, flexShrink: 0, display: 'grid',
                            placeItems: 'center', background: 'var(--accent-soft)' }}>
                <Icon name="spark" size={18} color="var(--accent)" stroke={2} />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ margin: '1px 0 10px', fontSize: 14.5, lineHeight: 1.55, color: 'var(--text)' }}>
                  {top.body}
                </p>
                <GemmaChip small label="Gemma · on-device" />
              </div>
            </div>
          </Card>
        </div>

        <div style={{ textAlign: 'center', padding: '2px 0 6px' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 11,
                         fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>
            <Icon name="shield" size={12} color="var(--text-3)" stroke={1.8} />
            Synced from Apple Health · processed on device
          </span>
        </div>
      </div>
    </div>
  );
}

// ───────────────────────── INSIGHTS ─────────────────────────
function InsightsScreen({ onOpenMetric }) {
  const [filter, setFilter] = React.useState('All');
  const cats = ['All', 'Activity', 'Heart', 'Sleep'];
  const list = DATA.insights.filter(i => filter === 'All' || i.cat === filter);
  return (
    <div className="screen">
      <div style={{ padding: '0 20px 2px' }}>
        <div style={{ fontSize: 13, fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>Updated 2h ago</div>
        <h1 style={{ fontSize: 27, fontWeight: 740, letterSpacing: '-.025em', margin: '4px 0 0' }}>Insights</h1>
      </div>

      {/* weekly insight summary graph */}
      <div style={{ padding: '14px 16px 0' }}>
        <Card pad={16}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 11.5, fontFamily: 'var(--mono)', color: 'var(--text-3)',
                            textTransform: 'uppercase', letterSpacing: '.06em' }}>Insights this week</div>
              <div style={{ fontSize: 23, fontWeight: 730, marginTop: 4, letterSpacing: '-.02em' }}>12 generated</div>
            </div>
            <Sparkline data={[1, 3, 2, 4, 2, 5, 3]} color="var(--accent)" width={94} height={40} />
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {[['Activity', 'var(--accent)', 5], ['Heart', '#e8596a', 4], ['Sleep', '#8a8fe6', 3]].map(([l, c, n]) => (
              <div key={l} style={{ flex: 1, padding: '9px 11px', borderRadius: 11, background: 'rgba(255,255,255,0.04)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                  <span style={{ width: 6, height: 6, borderRadius: 99, background: c }} />
                  <span style={{ fontSize: 11, color: 'var(--text-3)' }}>{l}</span>
                </div>
                <div style={{ fontSize: 18, fontWeight: 720, marginTop: 4 }}>{n}</div>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* filter chips */}
      <div style={{ display: 'flex', gap: 8, padding: '14px 16px 4px', overflowX: 'auto' }}>
        {cats.map(c => (
          <button key={c} onClick={() => setFilter(c)} style={{
            padding: '7px 15px', borderRadius: 999, fontSize: 13, fontWeight: 600, whiteSpace: 'nowrap',
            border: '1px solid ' + (filter === c ? 'transparent' : 'var(--hair-strong)'),
            background: filter === c ? 'var(--accent)' : 'transparent',
            color: filter === c ? '#1a1410' : 'var(--text-2)', cursor: 'pointer',
            fontFamily: 'inherit',
          }}>{c}</button>
        ))}
      </div>

      <div style={{ padding: '12px 16px 0' }}>
        <Card pad={'2px 16px'}>
          {list.map((i, idx) => (
            <div key={i.id} onClick={() => i.cat === 'Heart' ? onOpenMetric('hr') :
                  i.cat === 'Sleep' ? onOpenMetric('sleep') : onOpenMetric('steps')}
                 style={{ display: 'flex', gap: 12, padding: '15px 0', cursor: 'pointer',
                          borderTop: idx ? '1px solid var(--hair)' : 'none' }}>
              <span style={{ width: 9, height: 9, borderRadius: 99, background: i.color, marginTop: 5,
                             flexShrink: 0, boxShadow: `0 0 9px ${i.color}` }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15, fontWeight: 650, lineHeight: 1.32, letterSpacing: '-.01em',
                              textWrap: 'pretty' }}>{i.head}</div>
                <div style={{ fontSize: 13, color: 'var(--text-2)', lineHeight: 1.45, marginTop: 4 }}>{i.body}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 7 }}>
                  <span style={{ fontSize: 10, fontFamily: 'var(--mono)', color: i.color, fontWeight: 700,
                                 letterSpacing: '.05em' }}>{i.cat.toUpperCase()}</span>
                  <span style={{ fontSize: 10.5, fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>{i.tag} · {i.time}</span>
                  {i.pinned && (
                    <span style={{ fontSize: 9.5, fontFamily: 'var(--mono)', color: 'var(--accent)',
                                   background: 'var(--accent-soft)', padding: '2px 6px', borderRadius: 5,
                                   letterSpacing: '.05em', marginLeft: 'auto' }}>NOW</span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </Card>
        <div style={{ textAlign: 'center', padding: '14px 0 8px' }}>
          <GemmaChip small label="All insights generated on-device" />
        </div>
      </div>
    </div>
  );
}

// ───────────────────────── DETAIL ─────────────────────────
const METRIC_DETAIL = {
  steps: { title: 'Steps', icon: 'steps', color: 'var(--accent)', big: '7,420', unit: 'steps today',
    goal: 'Goal 10,000', series: DATA.today.hourlySteps, labels: ['6a', '', '9a', '', '12p', '', '3p', '', '6p', '', '9p', ''],
    stats: [['Goal', '10,000'], ['Distance', '5.4 km'], ['Flights', '8'], ['Avg/day', '8,240']],
    note: "You're 2,580 steps from today's goal. Friday was your best day this week at 11,020." },
  hr: { title: 'Heart Rate', icon: 'heart', color: '#e8596a', fill: true, big: '58', unit: 'bpm resting',
    goal: '6-month low', series: [62, 60, 61, 59, 60, 58, 57, 59, 58, 57, 58, 57],
    labels: ['', 'Mar', '', 'Apr', '', 'May', '', '', 'Jun', '', '', ''],
    stats: [['Resting', '58 bpm'], ['Range today', '52–141'], ['Walking avg', '92 bpm'], ['HRV', '48 ms']],
    note: 'Resting heart rate dropped 3 bpm over two weeks — a sign of improving aerobic fitness.' },
  sleep: { title: 'Sleep', icon: 'moon', color: '#8a8fe6', big: '7h 12m', unit: 'last night',
    goal: 'Target 7h 30m', series: [7.2, 6.5, 6.3, 7.0, 6.6, 7.8, 6.9, 6.4, 7.1, 6.8, 7.2, 6.9],
    labels: ['', '', '', '', '', 'past 12 nights', '', '', '', '', '', ''],
    stats: [['Asleep', '7h 12m'], ['Deep', '1h 04m'], ['REM', '1h 38m'], ['Avg/night', '6h 48m']],
    note: 'Weeknight sleep is averaging 42 min under target. A consistent 10:45 PM wind-down helps.' },
};

function DetailScreen({ metric }) {
  const d = METRIC_DETAIL[metric] || METRIC_DETAIL.steps;
  const maxv = Math.max(...d.series);
  return (
    <div className="screen" style={{ paddingTop: 4 }}>
      <div style={{ padding: '0 20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 11 }}>
          <div style={{ width: 40, height: 40, borderRadius: 12, display: 'grid', placeItems: 'center',
                        background: 'rgba(255,255,255,0.05)' }}>
            <Icon name={d.icon} size={21} color={d.color} stroke={2.1} fill={d.fill ? d.color : 'none'} />
          </div>
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 730, letterSpacing: '-.025em', margin: 0 }}>{d.title}</h1>
            <div style={{ fontSize: 12, fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>{d.goal}</div>
          </div>
        </div>
      </div>

      <div style={{ padding: '18px 16px 0', display: 'flex', flexDirection: 'column', gap: 16 }}>
        <Card pad={18}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 7, marginBottom: 14 }}>
            <span style={{ fontSize: 40, fontWeight: 760, letterSpacing: '-.04em', color: d.color }}>{d.big}</span>
            <span style={{ fontSize: 13, color: 'var(--text-3)', fontFamily: 'var(--mono)' }}>{d.unit}</span>
          </div>
          <BarChart data={d.series} labels={d.labels} color={d.color} max={maxv * 1.1} height={120} highlightLast />
        </Card>

        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
          {d.stats.map(([k, v], i) => (
            <Card key={i} pad={14} style={{ flex: '1 1 40%', minWidth: 0 }}>
              <div style={{ fontSize: 11.5, fontFamily: 'var(--mono)', color: 'var(--text-3)',
                            textTransform: 'uppercase', letterSpacing: '.04em' }}>{k}</div>
              <div style={{ fontSize: 20, fontWeight: 700, marginTop: 5, letterSpacing: '-.02em' }}>{v}</div>
            </Card>
          ))}
        </div>

        <Card pad={16}>
          <div style={{ display: 'flex', gap: 12 }}>
            <Icon name="spark" size={18} color="var(--accent)" stroke={2} />
            <div style={{ flex: 1 }}>
              <p style={{ margin: '0 0 10px', fontSize: 14.5, lineHeight: 1.55, color: 'var(--text)' }}>{d.note}</p>
              <GemmaChip small label="Gemma · on-device" />
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ───────────────────────── SETTINGS ─────────────────────────
function SettingsRow({ icon, iconBg, title, detail, rightEl, last, onClick }) {
  return (
    <div onClick={onClick} style={{ display: 'flex', alignItems: 'center', gap: 13, padding: '13px 16px',
                  borderTop: last === 'first' ? 'none' : '1px solid var(--hair)',
                  cursor: onClick ? 'pointer' : 'default' }}>
      {icon && (
        <div style={{ width: 30, height: 30, borderRadius: 8, flexShrink: 0, display: 'grid',
                      placeItems: 'center', background: iconBg || 'rgba(255,255,255,0.06)' }}>
          <Icon name={icon} size={16} color="#fff" stroke={2} />
        </div>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontWeight: 520 }}>{title}</div>
        {detail && <div style={{ fontSize: 12.5, color: 'var(--text-3)', marginTop: 1 }}>{detail}</div>}
      </div>
      {rightEl}
    </div>
  );
}

function Toggle({ on, onChange }) {
  return (
    <div onClick={() => onChange(!on)} style={{ width: 46, height: 28, borderRadius: 99, padding: 3,
                  background: on ? 'var(--accent)' : 'rgba(255,255,255,0.16)', cursor: 'pointer',
                  transition: 'background .2s', flexShrink: 0 }}>
      <div style={{ width: 22, height: 22, borderRadius: 99, background: '#fff',
                    transform: on ? 'translateX(18px)' : 'none', transition: 'transform .2s',
                    boxShadow: '0 1px 3px rgba(0,0,0,0.3)' }} />
    </div>
  );
}

function SettingsScreen() {
  const [onDevice, setOnDevice] = React.useState(true);
  const [notif, setNotif] = React.useState(true);
  return (
    <div className="screen">
      <div style={{ padding: '0 20px 2px' }}>
        <h1 style={{ fontSize: 27, fontWeight: 740, letterSpacing: '-.025em', margin: 0 }}>Settings</h1>
      </div>

      <div style={{ padding: '16px 16px 0', display: 'flex', flexDirection: 'column', gap: 22 }}>
        {/* profile */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '4px 4px' }}>
          <div style={{ width: 56, height: 56, borderRadius: 99, background: 'var(--accent)', display: 'grid',
                        placeItems: 'center', fontSize: 24, fontWeight: 700, color: '#1a1410' }}>
            {DATA.user.initials}
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 19, fontWeight: 680 }}>{DATA.user.name}</div>
            <div style={{ fontSize: 13, color: 'var(--text-3)' }}>34 · 178 cm · Goal: 10k steps</div>
          </div>
          <Icon name="chevron" size={18} color="var(--text-3)" stroke={2} />
        </div>

        {/* ON-DEVICE INTELLIGENCE — privacy as a feature */}
        <div>
          <SectionLabel>On-device intelligence</SectionLabel>
          <Card pad={0} style={{ overflow: 'hidden' }}>
            <div style={{ padding: 18, background: 'var(--accent-soft)', borderBottom: '1px solid var(--hair)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 13 }}>
                <div style={{ width: 44, height: 44, borderRadius: 13, display: 'grid', placeItems: 'center',
                              background: 'var(--accent)', flexShrink: 0 }}>
                  <Icon name="chip" size={23} color="#1a1410" stroke={1.9} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ fontSize: 16, fontWeight: 700 }}>Gemma 3n</span>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, fontSize: 11.5,
                                   fontFamily: 'var(--mono)', color: 'var(--good)' }}>
                      <span style={{ width: 6, height: 6, borderRadius: 99, background: 'var(--good)' }} />
                      Active
                    </span>
                  </div>
                  <div style={{ fontSize: 12.5, color: 'var(--text-2)', marginTop: 2, fontFamily: 'var(--mono)' }}>
                    via Edge Gallery · 4-bit · 3.1 GB
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 14,
                            padding: '10px 12px', background: 'rgba(0,0,0,0.22)', borderRadius: 12 }}>
                <Icon name="lock" size={15} color="var(--accent)" stroke={1.9} />
                <span style={{ fontSize: 12.5, color: 'var(--text-2)', lineHeight: 1.35 }}>
                  Your health data is analyzed on this iPhone and <b style={{ color: 'var(--text)' }}>never leaves the device</b>.
                </span>
              </div>
              <div style={{ marginTop: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11,
                              fontFamily: 'var(--mono)', color: 'var(--text-3)', marginBottom: 6, letterSpacing: '.04em' }}>
                  <span>STORAGE · 3.1 / 8 GB</span><span style={{ color: 'var(--accent)' }}>39%</span>
                </div>
                <div style={{ height: 8, borderRadius: 99, background: 'rgba(0,0,0,0.28)', overflow: 'hidden' }}>
                  <div className="grow-bar" style={{ width: '39%', height: '100%', borderRadius: 99,
                                background: 'linear-gradient(90deg, var(--accent2), var(--accent))' }} />
                </div>
              </div>
            </div>
            <SettingsRow icon="shield" iconBg="rgba(255,255,255,0.08)" title="Process on device only"
                         detail="No cloud, no network calls" last="first"
                         rightEl={<Toggle on={onDevice} onChange={setOnDevice} />} />
            <SettingsRow icon="refresh" iconBg="rgba(255,255,255,0.08)" title="Re-run weekly analysis"
                         detail="Last run today, 6:02 AM"
                         rightEl={<Icon name="chevron" size={16} color="var(--text-3)" stroke={2} />} onClick={() => {}} />
            <SettingsRow icon="chip" iconBg="rgba(255,255,255,0.08)" title="Model & storage"
                         detail="Gemma 3n · 3.1 GB used"
                         rightEl={<Icon name="chevron" size={16} color="var(--text-3)" stroke={2} />} onClick={() => {}} />
          </Card>
        </div>

        {/* data sources */}
        <div>
          <SectionLabel>Data sources</SectionLabel>
          <Card pad={0} style={{ overflow: 'hidden' }}>
            <SettingsRow icon="apple" iconBg="#fff" title="Apple Health" detail="Connected · 12 data types"
                         last="first"
                         rightEl={<span style={{ display: 'inline-flex', alignItems: 'center', gap: 5,
                           fontSize: 12.5, color: 'var(--good)', fontWeight: 600 }}>
                           <span style={{ width: 6, height: 6, borderRadius: 99, background: 'var(--good)' }} />Linked</span>} />
            <SettingsRow icon="heart" iconBg="#e8596a" title="Steps, Heart, Sleep, Energy"
                         detail="Read access · synced 2m ago"
                         rightEl={<Icon name="chevron" size={16} color="var(--text-3)" stroke={2} />} onClick={() => {}} />
          </Card>
        </div>

        {/* preferences */}
        <div>
          <SectionLabel>Preferences</SectionLabel>
          <Card pad={0} style={{ overflow: 'hidden' }}>
            <SettingsRow icon="bell" iconBg="rgba(255,255,255,0.08)" title="Daily suggestions" last="first"
                         rightEl={<Toggle on={notif} onChange={setNotif} />} />
            <SettingsRow icon="target" iconBg="rgba(255,255,255,0.08)" title="Goals"
                         detail="Steps, sleep, energy"
                         rightEl={<Icon name="chevron" size={16} color="var(--text-3)" stroke={2} />} onClick={() => {}} />
            <SettingsRow icon="info" iconBg="rgba(255,255,255,0.08)" title="About Ember" detail="Version 1.0 (beta)"
                         rightEl={<Icon name="chevron" size={16} color="var(--text-3)" stroke={2} />} onClick={() => {}} />
          </Card>
        </div>

        <div style={{ textAlign: 'center', padding: '0 0 8px' }}>
          <span style={{ fontSize: 11, fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>
            Ember · Private health intelligence
          </span>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { HomeScreen, InsightsScreen, DetailScreen, SettingsScreen });
