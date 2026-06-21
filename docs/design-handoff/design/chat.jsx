// chat.jsx — Chat with Gemma (on-device assistant) + voice recording

const SUGGESTED = [
  'Why was my sleep low this week?',
  'How do I hit my step goal today?',
  'Is my resting heart rate healthy?',
];

// canned, data-grounded on-device replies (keyword routed)
function gemmaReply(text) {
  const q = text.toLowerCase();
  if (/sleep|rest|tired|bed/.test(q))
    return "Your sleep averaged 6h 48m this week — about 42 min under your 7h 30m target. The biggest dip was Tuesday (6h 18m) after a 9:40 PM coffee. Caffeine after 2 PM tends to cost you ~38 min of deep sleep. Try a consistent 10:45 PM wind-down.";
  if (/step|walk|move|active|goal/.test(q))
    return "You're at 7,420 of 10,000 steps with about 5 active hours left. A brisk 22-minute walk (~2,600 steps) closes the gap. Your best window is usually 6–7 PM — that's when you move most.";
  if (/heart|hr|bpm|cardio|pulse/.test(q))
    return "Your resting heart rate is 57 bpm — a 6-month low and down 3 bpm in two weeks. That's a healthy range and a sign your aerobic base is improving. HRV is also trending up, so recovery looks strong.";
  if (/diet|eat|food|meal|nutrition|calorie/.test(q))
    return "Diet recommendations aren't enabled yet — they're coming soon. Once on, I'll suggest meals from your activity and sleep, generated right here on device. For now: with 412 active kcal burned, a protein-forward dinner supports recovery.";
  return "Based on your last 7 days: activity is up 9%, resting heart rate is down 3 bpm, and sleep is your one weak spot at 6h 48m. Want me to break down any of these — steps, heart, or sleep?";
}

function TypingDots() {
  return (
    <div style={{ display: 'flex', gap: 4, padding: '4px 2px' }}>
      {[0, 1, 2].map(i => (
        <span key={i} className="type-dot" style={{ width: 7, height: 7, borderRadius: 99,
          background: 'var(--text-3)', animationDelay: `${i * 0.16}s` }} />
      ))}
    </div>
  );
}

function VoiceOverlay({ onCancel, onSend }) {
  const [secs, setSecs] = React.useState(0);
  React.useEffect(() => {
    const iv = setInterval(() => setSecs(s => s + 1), 1000);
    return () => clearInterval(iv);
  }, []);
  const mm = String(Math.floor(secs / 60)).padStart(2, '0');
  const ss = String(secs % 60).padStart(2, '0');
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 45, background: 'rgba(8,7,6,0.82)',
                  backdropFilter: 'blur(14px)', display: 'flex', flexDirection: 'column',
                  alignItems: 'center', justifyContent: 'center', padding: 32 }}>
      <div style={{ fontSize: 12.5, fontFamily: 'var(--mono)', color: 'var(--accent)',
                    letterSpacing: '.06em', marginBottom: 6 }}>● RECORDING</div>
      <div style={{ fontSize: 44, fontWeight: 760, letterSpacing: '-.03em', fontVariantNumeric: 'tabular-nums' }}>
        {mm}:{ss}
      </div>
      {/* live waveform */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 4, height: 64, margin: '26px 0 8px' }}>
        {Array.from({ length: 27 }).map((_, i) => (
          <span key={i} className="wave-bar" style={{
            width: 4, borderRadius: 99, background: 'var(--accent)',
            animationDelay: `${(i % 9) * 0.09}s`,
            height: 10,
          }} />
        ))}
      </div>
      <div style={{ fontSize: 13, color: 'var(--text-2)', textAlign: 'center', maxWidth: 260, lineHeight: 1.5 }}>
        Speak your question — Gemma transcribes and understands it <b style={{ color: 'var(--text)' }}>entirely on device</b>.
      </div>
      <div style={{ display: 'flex', gap: 16, marginTop: 34, alignItems: 'center' }}>
        <button onClick={onCancel} style={{ width: 56, height: 56, borderRadius: 99, border: '1px solid var(--hair-strong)',
                      background: 'var(--surface)', display: 'grid', placeItems: 'center', cursor: 'pointer' }}>
          <Icon name="plus" size={24} color="var(--text-2)" stroke={2.2} style={{ transform: 'rotate(45deg)' }} />
        </button>
        <button onClick={() => onSend("How's my recovery looking after this week?")}
                style={{ width: 72, height: 72, borderRadius: 99, border: 'none',
                      background: 'var(--accent)', display: 'grid', placeItems: 'center', cursor: 'pointer',
                      boxShadow: '0 0 0 6px var(--accent-soft)' }}>
          <Icon name="check" size={30} color="#1a1410" stroke={2.6} />
        </button>
        <div style={{ width: 56 }} />
      </div>
    </div>
  );
}

function ChatScreen() {
  const [msgs, setMsgs] = React.useState([
    { who: 'ai', text: "Hi Aman — I'm running locally on this iPhone. Ask me anything about your health data. Nothing you say leaves the device." },
  ]);
  const [draft, setDraft] = React.useState('');
  const [typing, setTyping] = React.useState(false);
  const [recording, setRecording] = React.useState(false);
  const endRef = React.useRef(null);

  React.useEffect(() => {
    if (endRef.current) endRef.current.parentElement.scrollTop = endRef.current.offsetTop + 999;
  }, [msgs, typing]);

  const send = (text, viaVoice) => {
    const t = (text || '').trim();
    if (!t) return;
    setDraft('');
    setRecording(false);
    setMsgs(m => [...m, { who: 'me', text: t, voice: !!viaVoice }]);
    setTyping(true);
    setTimeout(() => {
      setTyping(false);
      setMsgs(m => [...m, { who: 'ai', text: gemmaReply(t) }]);
    }, 1100);
  };

  return (
    <div className="screen" style={{ height: '100%', display: 'flex', flexDirection: 'column', paddingTop: 0 }}>
      {/* header */}
      <div style={{ padding: '0 20px 12px', display: 'flex', alignItems: 'center', gap: 11 }}>
        <div className="glow-pulse" style={{ width: 40, height: 40, borderRadius: 12, background: 'var(--accent)',
                      display: 'grid', placeItems: 'center', flexShrink: 0 }}>
          <Icon name="chip" size={21} color="#1a1410" stroke={1.9} />
        </div>
        <div>
          <h1 style={{ fontSize: 21, fontWeight: 720, letterSpacing: '-.02em', margin: 0 }}>Ask Gemma</h1>
          <div style={{ fontSize: 11.5, fontFamily: 'var(--mono)', color: 'var(--good)',
                        display: 'flex', alignItems: 'center', gap: 5 }}>
            <span className="live-dot" style={{ width: 6, height: 6, borderRadius: 99, background: 'var(--good)' }} />
            On-device · Gemma 3n
          </div>
        </div>
      </div>

      {/* messages */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '4px 16px 8px',
                    display: 'flex', flexDirection: 'column', gap: 12 }}>
        {msgs.map((m, i) => (
          <div key={i} style={{ display: 'flex', justifyContent: m.who === 'me' ? 'flex-end' : 'flex-start' }}>
            <div style={{
              maxWidth: '82%', padding: '11px 14px', fontSize: 14.5, lineHeight: 1.5,
              borderRadius: 18, textWrap: 'pretty',
              borderBottomRightRadius: m.who === 'me' ? 5 : 18,
              borderBottomLeftRadius: m.who === 'me' ? 18 : 5,
              background: m.who === 'me' ? 'var(--accent)' : 'var(--surface)',
              color: m.who === 'me' ? '#1a1410' : 'var(--text)',
              border: m.who === 'me' ? 'none' : 'var(--card-border)',
              fontWeight: m.who === 'me' ? 540 : 400,
            }}>
              {m.voice && (
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6, opacity: 0.7 }}>
                  <Icon name="mic" size={13} color="#1a1410" stroke={2} />
                  <span style={{ fontSize: 11, fontFamily: 'var(--mono)' }}>Voice · transcribed on device</span>
                </div>
              )}
              {m.text}
            </div>
          </div>
        ))}
        {typing && (
          <div style={{ display: 'flex', justifyContent: 'flex-start' }}>
            <div style={{ padding: '8px 14px', borderRadius: 18, borderBottomLeftRadius: 5,
                          background: 'var(--surface)', border: 'var(--card-border)' }}>
              <TypingDots />
            </div>
          </div>
        )}
        <div ref={endRef} />
      </div>

      {/* suggested prompts */}
      {msgs.length <= 1 && (
        <div style={{ display: 'flex', gap: 8, padding: '0 16px 10px', flexWrap: 'wrap' }}>
          {SUGGESTED.map(s => (
            <button key={s} onClick={() => send(s)} style={{
              padding: '8px 13px', borderRadius: 999, fontSize: 12.5, cursor: 'pointer',
              background: 'var(--accent-soft)', border: '1px solid var(--accent-line)',
              color: 'var(--accent)', fontFamily: 'inherit', fontWeight: 560,
            }}>{s}</button>
          ))}
        </div>
      )}

      {/* composer */}
      <div style={{ padding: '8px 16px 14px', display: 'flex', alignItems: 'center', gap: 9 }}>
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8, padding: '4px 6px 4px 16px',
                      background: 'var(--surface)', border: 'var(--card-border)', borderRadius: 999 }}>
          <input value={draft} onChange={e => setDraft(e.target.value)}
                 onKeyDown={e => e.key === 'Enter' && send(draft)}
                 placeholder="Ask about your health…"
                 style={{ flex: 1, background: 'none', border: 'none', outline: 'none',
                          color: 'var(--text)', fontSize: 15, fontFamily: 'inherit', minWidth: 0 }} />
          {draft.trim()
            ? <button onClick={() => send(draft)} style={{ width: 38, height: 38, borderRadius: 99, border: 'none',
                          background: 'var(--accent)', display: 'grid', placeItems: 'center', cursor: 'pointer', flexShrink: 0 }}>
                <Icon name="arrowUp" size={20} color="#1a1410" stroke={2.4} />
              </button>
            : <button onClick={() => setRecording(true)} style={{ width: 38, height: 38, borderRadius: 99, border: 'none',
                          background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', cursor: 'pointer', flexShrink: 0 }}>
                <Icon name="mic" size={19} color="var(--accent)" stroke={2.1} />
              </button>}
        </div>
      </div>

      {recording && <VoiceOverlay onCancel={() => setRecording(false)} onSend={(txt) => send(txt, true)} />}
    </div>
  );
}

Object.assign(window, { ChatScreen });
