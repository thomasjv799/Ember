// onboarding.jsx — welcome → connect Apple Health → on-device model setup

function Logo({ size = 40 }) {
  return (
    <div style={{ width: size, height: size, borderRadius: size * 0.28, position: 'relative',
                  background: 'var(--accent)', display: 'grid', placeItems: 'center',
                  boxShadow: '0 8px 24px -8px var(--accent-soft)' }}>
      <div style={{ width: size * 0.42, height: size * 0.42, borderRadius: 99,
                    border: `${size * 0.085}px solid #1a1410` }} />
    </div>
  );
}

function Onboarding({ onDone }) {
  const [step, setStep] = React.useState(0);
  const [setup, setSetup] = React.useState(0); // model setup progress

  React.useEffect(() => {
    if (step !== 2) return;
    setSetup(0);
    const iv = setInterval(() => {
      setSetup(s => {
        if (s >= 100) { clearInterval(iv); return 100; }
        return Math.min(100, s + 4);
      });
    }, 45);
    return () => clearInterval(iv);
  }, [step]);

  const dataTypes = [
    ['steps', 'Steps & Distance', 'var(--accent)'],
    ['heart', 'Heart Rate & HRV', '#e8596a'],
    ['moon', 'Sleep Analysis', '#8a8fe6'],
    ['flame', 'Active Energy', 'var(--accent2)'],
  ];

  return (
    <div style={{ position: 'absolute', inset: 0, background: 'var(--bg)', zIndex: 40,
                  display: 'flex', flexDirection: 'column',
                  padding: '92px 24px 36px', boxSizing: 'border-box' }}>
      {/* progress dots */}
      <div style={{ display: 'flex', gap: 6, justifyContent: 'center', marginBottom: 'auto' }}>
        {[0, 1, 2].map(i => (
          <div key={i} style={{ width: i === step ? 22 : 6, height: 6, borderRadius: 99,
                                 background: i === step ? 'var(--accent)' : 'rgba(255,255,255,0.16)',
                                 transition: 'all .3s' }} />
        ))}
      </div>

      {step === 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
          <Logo size={76} />
          <h1 style={{ fontSize: 38, fontWeight: 760, letterSpacing: '-.035em', margin: '28px 0 0' }}>Ember</h1>
          <p style={{ fontSize: 16.5, color: 'var(--text-2)', lineHeight: 1.5, margin: '14px 0 0', maxWidth: 300 }}>
            Private health intelligence. Your Apple Health data, understood by an AI that runs
            entirely on your iPhone.
          </p>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginTop: 22 }}>
            <Icon name="lock" size={14} color="var(--accent)" stroke={1.9} />
            <span style={{ fontSize: 12.5, fontFamily: 'var(--mono)', color: 'var(--accent)' }}>
              100% on-device · nothing leaves your phone
            </span>
          </div>
        </div>
      )}

      {step === 1 && (
        <div style={{ width: '100%' }}>
          <div style={{ display: 'grid', placeItems: 'center', marginBottom: 26 }}>
            <div style={{ width: 64, height: 64, borderRadius: 20, background: '#fff', display: 'grid',
                          placeItems: 'center' }}>
              <Icon name="heart" size={34} color="#e8596a" stroke={2} fill="#e8596a" />
            </div>
          </div>
          <h1 style={{ fontSize: 27, fontWeight: 730, letterSpacing: '-.03em', textAlign: 'center', margin: '0 0 8px' }}>
            Connect Apple Health
          </h1>
          <p style={{ fontSize: 14.5, color: 'var(--text-2)', textAlign: 'center', lineHeight: 1.5,
                      margin: '0 auto 26px', maxWidth: 300 }}>
            Ember reads these to build your daily and weekly insights.
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {dataTypes.map(([icon, label, color]) => (
              <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 13, padding: '13px 16px',
                            background: 'var(--surface)', borderRadius: 14, border: 'var(--card-border)' }}>
                <div style={{ width: 32, height: 32, borderRadius: 9, display: 'grid', placeItems: 'center',
                              background: 'rgba(255,255,255,0.05)' }}>
                  <Icon name={icon} size={17} color={color} stroke={2} fill={icon === 'heart' ? color : 'none'} />
                </div>
                <span style={{ flex: 1, fontSize: 15, fontWeight: 540 }}>{label}</span>
                <Icon name="check" size={17} color="var(--good)" stroke={2.4} />
              </div>
            ))}
          </div>
        </div>
      )}

      {step === 2 && (
        <div style={{ width: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
          <Ring size={140} stroke={10} value={setup} max={100} gradient={['var(--accent2)', 'var(--accent)']}>
            {setup < 100
              ? <><span style={{ fontSize: 30, fontWeight: 750, letterSpacing: '-.03em' }}>{setup}%</span>
                  <span style={{ fontSize: 10.5, fontFamily: 'var(--mono)', color: 'var(--text-3)' }}>preparing</span></>
              : <Icon name="check" size={46} color="var(--accent)" stroke={2.6} />}
          </Ring>
          <h1 style={{ fontSize: 25, fontWeight: 730, letterSpacing: '-.03em', margin: '28px 0 8px' }}>
            {setup < 100 ? 'Setting up Gemma on-device' : 'Ready to go'}
          </h1>
          <p style={{ fontSize: 14.5, color: 'var(--text-2)', lineHeight: 1.5, margin: '0 auto', maxWidth: 300 }}>
            {setup < 100
              ? 'Loading the Gemma 3n model via Edge Gallery. This runs locally — no account, no cloud.'
              : 'Your on-device model is active. Ember will analyze your health data privately, right here.'}
          </p>
          <div style={{ marginTop: 18 }}>
            <GemmaChip label="Gemma 3n · Edge Gallery" />
          </div>
        </div>
      )}

      {/* CTA */}
      <div style={{ marginTop: 'auto', paddingTop: 32 }}>
        <button
          disabled={step === 2 && setup < 100}
          onClick={() => step < 2 ? setStep(step + 1) : onDone()}
          style={{
            width: '100%', height: 54, borderRadius: 16, border: 'none', cursor: 'pointer',
            background: (step === 2 && setup < 100) ? 'rgba(255,255,255,0.1)' : 'var(--accent)',
            color: (step === 2 && setup < 100) ? 'var(--text-3)' : '#1a1410',
            fontSize: 16.5, fontWeight: 680, fontFamily: 'inherit',
            transition: 'background .2s',
          }}>
          {step === 0 ? 'Get started' : step === 1 ? 'Allow access' : (setup < 100 ? 'Setting up…' : 'Enter Ember')}
        </button>
        {step < 2 && (
          <button onClick={onDone} style={{ width: '100%', marginTop: 10, background: 'none', border: 'none',
                        color: 'var(--text-3)', fontSize: 14, cursor: 'pointer', fontFamily: 'inherit',
                        padding: 8 }}>
            Skip for now
          </button>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { Onboarding, Logo });
