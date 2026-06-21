// components.jsx — shared primitives, icons, charts, and mock data for Vesta
// Dark, premium, data-rich health app. All exported to window at the bottom.

// ─────────────────────────────────────────────────────────────
// Icons — simple line/solid glyphs (24x24 unless noted)
// ─────────────────────────────────────────────────────────────
function Icon({ name, size = 24, color = 'currentColor', stroke = 2, fill = 'none' }) {
  const p = {
    home: <path d="M3 10.5 12 3l9 7.5M5 9.5V20a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1V9.5" />,
    weekly: <path d="M4 7h16M4 7a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h16a1 1 0 0 1 1 1v1a1 1 0 0 1-1 1M5 7v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V7M8 11h3M8 15h3M15 11h1M15 15h1" />,
    spark: <path d="M12 3v4M12 17v4M3 12h4M17 12h4M6.5 6.5l2.5 2.5M15 15l2.5 2.5M17.5 6.5 15 9M9 15l-2.5 2.5" />,
    gear: <g><circle cx="12" cy="12" r="3.2" /><path d="M12 2.5v2.2M12 19.3v2.2M21.5 12h-2.2M4.7 12H2.5M18.7 5.3l-1.6 1.6M6.9 17.1l-1.6 1.6M18.7 18.7l-1.6-1.6M6.9 6.9 5.3 5.3" /></g>,
    sliders: <g><path d="M4 7h16M4 12h16M4 17h16" /><circle cx="9" cy="7" r="2.4" /><circle cx="16" cy="12" r="2.4" /><circle cx="7" cy="17" r="2.4" /></g>,
    chevron: <path d="m9 5 7 7-7 7" />,
    chevronL: <path d="m15 5-7 7 7 7" />,
    steps: <path d="M7 13c-1.5 0-2.5-1.4-2.3-3.2.2-1.6.6-3.4 1.2-4.5C6.5 4.3 7.2 4 7.9 4.2c.9.3 1.3 1.4 1.3 2.8 0 1.6-.3 3.4-.8 4.6C8 12.5 7.6 13 7 13ZM16.5 20c-1.4 0-2.4-1.3-2.2-3 .2-1.5.6-3.2 1.1-4.2.4-.9 1-1.2 1.7-1 .8.3 1.2 1.3 1.2 2.6 0 1.5-.3 3.2-.8 4.3-.3.8-.6 1.3-1 1.3Z" />,
    heart: <path d="M12 20s-7-4.3-9.2-8.4C1.3 8.9 2.4 5.5 5.5 5c2-.3 3.6.9 4.5 2.3l2 .1c.9-1.5 2.5-2.7 4.5-2.4 3.1.5 4.2 3.9 2.7 6.6C19 15.7 12 20 12 20Z" />,
    moon: <path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5Z" />,
    flame: <path d="M12 3c.5 3-2 4-2 7a2 2 0 0 0 4 0c0-.8-.3-1.4-.3-1.4 1.8 1 3.3 3 3.3 5.4a5 5 0 0 1-10 0C7 9 12 8 12 3Z" />,
    shield: <path d="M12 3 5 6v5c0 4 3 7.5 7 9 4-1.5 7-5 7-9V6l-7-3Z" />,
    chip: <g><rect x="6" y="6" width="12" height="12" rx="2.5" /><path d="M9.5 9.5h5v5h-5zM9 3v3M12 3v3M15 3v3M9 18v3M12 18v3M15 18v3M3 9h3M3 12h3M3 15h3M18 9h3M18 12h3M18 15h3" /></g>,
    check: <path d="m4.5 12.5 5 5 10-11" />,
    apple: <path d="M16 13c0-2 1.5-2.8 1.6-2.9-0.9-1.3-2.3-1.5-2.8-1.5-1.2-.1-2.3.7-2.9.7s-1.5-.7-2.5-.7c-1.3 0-2.5.8-3.1 2-1.3 2.3-.3 5.7 1 7.6.6.9 1.4 1.9 2.4 1.9s1.3-.6 2.5-.6 1.5.6 2.5.6 1.7-.9 2.3-1.8c.7-1 1-2 1-2.1-.1 0-2-.8-2-3.2ZM14 6.5c.5-.7.9-1.6.8-2.5-.8 0-1.7.5-2.3 1.2-.5.6-.9 1.5-.8 2.4.9.1 1.8-.4 2.3-1.1Z" />,
    bell: <path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6M10 19a2 2 0 0 0 4 0" />,
    arrowUp: <path d="M12 19V5M6 11l6-6 6 6" />,
    lock: <g><rect x="5" y="10" width="14" height="10" rx="2.2" /><path d="M8 10V7a4 4 0 0 1 8 0v3" /></g>,
    refresh: <path d="M3.5 12a8.5 8.5 0 0 1 14.5-6M20.5 12A8.5 8.5 0 0 1 6 18M17 5.5h2.5V3M7 18.5H4.5V21" />,
    plus: <path d="M12 5v14M5 12h14" />,
    target: <g><circle cx="12" cy="12" r="8.5" /><circle cx="12" cy="12" r="4.5" /><circle cx="12" cy="12" r="0.6" fill="currentColor" /></g>,
    info: <g><circle cx="12" cy="12" r="9" /><path d="M12 11v5M12 7.6v.1" /></g>,
    arrowRight: <path d="M5 12h14M13 6l6 6-6 6" />,
    leaf: <path d="M5 19c0-8 6-13 14-13 0 8-5 14-13 14-1 0-1-1-1-1ZM8 16c2.5-2.5 5-4 8-5" />,
    chat: <path d="M4 5.5h16a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H10l-4.5 4v-4H4a1 1 0 0 1-1-1v-8a1 1 0 0 1 1-1Z" />,
    mic: <g><rect x="9" y="3" width="6" height="11" rx="3" /><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21M8.5 21h7" /></g>,
  }[name];
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={color}
         strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round"
         style={{ display: 'block', flexShrink: 0 }}>
      {p}
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Progress ring
// ─────────────────────────────────────────────────────────────
function Ring({ size = 120, stroke = 12, value = 0, max = 100, color = 'var(--accent)',
                track = 'rgba(255,255,255,0.08)', children, gradient }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const pct = Math.max(0, Math.min(1, value / max));
  const gid = React.useMemo(() => 'g' + Math.random().toString(36).slice(2, 8), []);
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        {gradient && (
          <defs>
            <linearGradient id={gid} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor={gradient[0]} />
              <stop offset="100%" stopColor={gradient[1]} />
            </linearGradient>
          </defs>
        )}
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={track} strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none"
                stroke={gradient ? `url(#${gid})` : color} strokeWidth={stroke}
                strokeDasharray={c} strokeDashoffset={c * (1 - pct)} strokeLinecap="round"
                style={{ transition: 'stroke-dashoffset 1s cubic-bezier(.4,0,.2,1)' }} />
      </svg>
      {children && (
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
                      alignItems: 'center', justifyContent: 'center', textAlign: 'center' }}>
          {children}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Sparkline
// ─────────────────────────────────────────────────────────────
function Sparkline({ data, color = 'var(--accent)', width = 96, height = 34, fillFade = true }) {
  const min = Math.min(...data), max = Math.max(...data);
  const span = max - min || 1;
  const pts = data.map((d, i) => {
    const x = (i / (data.length - 1)) * width;
    const y = height - 3 - ((d - min) / span) * (height - 6);
    return [x, y];
  });
  const line = pts.map(p => p.join(',')).join(' ');
  const gid = React.useMemo(() => 'sf' + Math.random().toString(36).slice(2, 8), []);
  const area = `0,${height} ${line} ${width},${height}`;
  return (
    <svg width={width} height={height} style={{ display: 'block', overflow: 'visible' }}>
      {fillFade && (
        <defs>
          <linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.22" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>
      )}
      {fillFade && <polygon points={area} fill={`url(#${gid})`} />}
      <polyline points={line} fill="none" stroke={color} strokeWidth="2.2"
                strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={pts[pts.length - 1][0]} cy={pts[pts.length - 1][1]} r="2.6" fill={color} />
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Bar chart with optional goal line
// ─────────────────────────────────────────────────────────────
function BarChart({ data, labels, max, goal, color = 'var(--accent)', height = 132, highlightLast }) {
  const top = max || Math.max(...data, goal || 0) * 1.08;
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height,
                    position: 'relative', padding: '4px 0' }}>
        {goal != null && (
          <div style={{ position: 'absolute', left: 0, right: 0, bottom: `${(goal / top) * 100}%`,
                        borderTop: '1.5px dashed rgba(255,255,255,0.22)', zIndex: 2 }}>
            <span style={{ position: 'absolute', right: 0, top: -16, fontSize: 10,
                           fontFamily: 'var(--mono)', color: 'var(--text-3)', letterSpacing: '.02em' }}>
              GOAL {goal >= 1000 ? (goal / 1000) + 'k' : goal}
            </span>
          </div>
        )}
        {data.map((d, i) => {
          const h = Math.max(3, (d / top) * 100);
          const isLast = highlightLast && i === data.length - 1;
          const met = goal != null ? d >= goal : true;
          const barBg = met
            ? (goal != null ? color : `color-mix(in oklab, ${color} 75%, transparent)`)
            : 'rgba(255,255,255,0.13)';
          return (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column',
                                  justifyContent: 'flex-end', height: '100%' }}>
              <div style={{
                height: `${h}%`, borderRadius: 5,
                background: isLast && goal == null ? color : barBg,
                outline: isLast ? `1.5px solid ${color}` : 'none',
                outlineOffset: 1,
                transition: 'height .7s cubic-bezier(.4,0,.2,1)',
              }} />
            </div>
          );
        })}
      </div>
      {labels && (
        <div style={{ display: 'flex', gap: 8, marginTop: 7 }}>
          {labels.map((l, i) => (
            <div key={i} style={{ flex: 1, textAlign: 'center', fontSize: 10.5,
                                  fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>{l}</div>
          ))}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────
function Card({ children, style = {}, pad = 16, onClick, glow }) {
  return (
    <div onClick={onClick} style={{
      background: 'var(--surface)',
      border: 'var(--card-border)',
      boxShadow: glow ? '0 0 0 1px var(--accent-soft), 0 8px 30px -12px var(--accent-soft)' : 'var(--card-shadow)',
      borderRadius: 'var(--radius)', padding: pad,
      cursor: onClick ? 'pointer' : 'default',
      transition: 'transform .15s ease',
      ...style,
    }}>{children}</div>
  );
}

function SectionLabel({ children, action, onAction }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
                  margin: '4px 2px 10px' }}>
      <span style={{ fontSize: 12.5, fontFamily: 'var(--mono)', letterSpacing: '.08em',
                     textTransform: 'uppercase', color: 'var(--text-3)' }}>{children}</span>
      {action && <span onClick={onAction} style={{ fontSize: 13, color: 'var(--accent)',
                     fontWeight: 600, cursor: 'pointer' }}>{action}</span>}
    </div>
  );
}

// delta pill: trend indicator
function Delta({ value, good, suffix = '%' }) {
  const up = value >= 0;
  const positive = good === undefined ? up : good;
  const col = positive ? 'var(--good)' : 'var(--accent)';
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 2,
                   fontSize: 12, fontWeight: 650, color: col,
                   fontFamily: 'var(--mono)' }}>
      <svg width="10" height="10" viewBox="0 0 10 10" style={{ transform: up ? 'none' : 'scaleY(-1)' }}>
        <path d="M5 2 L9 8 H1 Z" fill={col} />
      </svg>
      {Math.abs(value)}{suffix}
    </span>
  );
}

// "Generated on-device" chip — privacy as a feature
function GemmaChip({ small, label = 'Generated on-device' }) {
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6,
                  padding: small ? '3px 8px' : '5px 10px', borderRadius: 999,
                  background: 'var(--accent-soft)', border: '1px solid var(--accent-line)' }}>
      <Icon name="chip" size={small ? 12 : 13} color="var(--accent)" stroke={1.8} />
      <span style={{ fontSize: small ? 10.5 : 11.5, fontFamily: 'var(--mono)',
                     color: 'var(--accent)', letterSpacing: '.02em', fontWeight: 600 }}>{label}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────
const DATA = {
  user: { name: 'Aman', initials: 'A' },
  today: {
    date: 'Saturday, June 20',
    steps: 7420, stepGoal: 10000,
    restingHR: 58, activeEnergy: 412, energyGoal: 600,
    sleep: '7h 12m', sleepHrs: 7.2, exercise: 28, exerciseGoal: 30, stand: 9,
    hourlySteps: [120, 60, 0, 0, 30, 240, 880, 1100, 640, 420, 510, 980, 700, 540, 320, 260, 380, 410],
  },
  week: {
    range: 'Jun 13 – Jun 19',
    status: 'On track', statusScore: 78,
    summary: "You hit your 10,000-step goal on 4 of 7 days and averaged 8,240 steps daily — up 9% from last week. Resting heart rate fell 3 bpm, a sign recovery is improving. Sleep was the weak spot: you averaged 6h 48m on weeknights, below your 7h 30m target.",
    metrics: [
      { key: 'steps', label: 'Avg Steps', value: '8,240', unit: '/day', delta: 9, good: true,
        series: [9100, 6400, 10240, 7200, 11020, 5400, 8260], icon: 'steps', useAccent: true },
      { key: 'hr', label: 'Resting HR', value: '57', unit: 'bpm', delta: -3, good: true,
        series: [60, 59, 60, 58, 57, 56, 57], icon: 'heart', color: '#e8596a' },
      { key: 'sleep', label: 'Avg Sleep', value: '6h 48m', unit: '/night', delta: -6, good: false,
        series: [7.2, 6.5, 6.3, 7.0, 6.6, 7.8, 6.9], icon: 'moon', color: '#8a8fe6' },
      { key: 'energy', label: 'Active Energy', value: '486', unit: 'kcal/day', delta: 4, good: true,
        series: [520, 410, 610, 440, 590, 350, 480], icon: 'flame', useAccent: true, accent2: true },
    ],
    stepsByDay: [9100, 6400, 10240, 7200, 11020, 5400, 8260],
    dayLabels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    highlights: [
      'Resting heart rate is at a 6-month low of 57 bpm.',
      'Friday was your most active day — 11,020 steps and a 42-min walk.',
    ],
    watch: [
      'Weeknight sleep averaged 6h 48m, 42 min under target.',
      'Two consecutive low-movement days (Sat–Sun) under 8k steps.',
    ],
    focus: [
      { title: 'Protect a 7.5h sleep window', body: 'Set a 10:45 PM wind-down on weeknights to close the 42-min gap.', icon: 'moon' },
      { title: 'Add one weekend walk', body: 'A 25-min walk Sat & Sun keeps your daily average above 8k.', icon: 'steps' },
      { title: 'Hold your HR gains', body: 'Keep 3 zone-2 sessions a week to maintain the lower resting rate.', icon: 'heart' },
    ],
  },
  insights: [
    { id: 1, cat: 'Activity', color: 'var(--accent)', icon: 'steps', time: '2h ago', pinned: true,
      head: '2,580 steps from your goal — a 22-min walk closes it',
      body: "You're at 7,420 of 10,000 steps with 5 active hours left.",
      tag: 'Today · Steps' },
    { id: 2, cat: 'Heart', color: '#e8596a', icon: 'heart', time: '8h ago',
      head: 'Resting heart rate down 3 bpm in two weeks',
      body: 'Your aerobic base is improving — keep zone-2 sessions consistent.',
      tag: '14-day trend' },
    { id: 3, cat: 'Sleep', color: '#8a8fe6', icon: 'moon', time: 'Yesterday',
      head: 'Late coffee cost you ~38 min of deep sleep',
      body: 'Sleep dipped to 6h 20m after a 9:40 PM coffee. Caffeine after 2 PM is a pattern for you.',
      tag: 'Pattern detected' },
    { id: 4, cat: 'Activity', color: 'var(--accent)', icon: 'flame', time: '2 days ago',
      head: '610 active kcal Wednesday — your weekly high',
      body: 'Recovery looked clean the next morning. Nice effort.',
      tag: 'Energy' },
    { id: 5, cat: 'Heart', color: '#e8596a', icon: 'heart', time: '3 days ago',
      head: 'HRV trending up — recovery looks strong',
      body: 'Heart rate variability is rising week-over-week. No action needed.',
      tag: 'HRV · Recovery' },
  ],
};

Object.assign(window, {
  Icon, Ring, Sparkline, BarChart, Card, SectionLabel, Delta, GemmaChip, DATA,
});
