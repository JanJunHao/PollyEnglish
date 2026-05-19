// sheets.jsx — Subtitle settings + Shadowing practice sheets (player overlays)

function SheetShell({ title, subtitle, onClose, children, height }) {
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => {
    const id = setTimeout(() => setMounted(true), 16);
    return () => clearTimeout(id);
  }, []);
  const close = () => { setMounted(false); setTimeout(onClose, 220); };

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 110 }}>
      <div onClick={close} style={{
        position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.5)',
        opacity: mounted ? 1 : 0, transition: 'opacity 220ms',
      }}/>
      <div style={{
        position: 'absolute', left: 12, right: 12, bottom: 18,
        transform: `translateY(${mounted ? 0 : 30}px) scale(${mounted ? 1 : 0.96})`,
        opacity: mounted ? 1 : 0,
        transition: 'transform 350ms cubic-bezier(.22,1.3,.36,1), opacity 220ms',
      }}>
        <div style={{
          background: 'var(--surface-elev)',
          borderRadius: 22,
          maxHeight: height || 'auto',
          boxShadow: 'var(--shadow-card)',
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{
            position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
            width: 36, height: 4, borderRadius: 2, background: 'var(--divider-strong)',
          }}/>
          <div style={{
            padding: '22px 22px 8px',
            display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
          }}>
            <div>
              <div style={{
                fontFamily: '"PingFang SC", sans-serif', fontSize: 18, fontWeight: 600, color: 'var(--text)',
              }}>{title}</div>
              {subtitle && (
                <div style={{
                  marginTop: 4,
                  fontFamily: '"PingFang SC", sans-serif', fontSize: 12, color: 'var(--text-sec)',
                }}>{subtitle}</div>
              )}
            </div>
            <button onClick={close} style={{
              width: 30, height: 30, borderRadius: 15, border: 'none',
              background: 'var(--chip-bg)', cursor: 'pointer', padding: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="close" size={12} color="var(--text-sec)"/>
            </button>
          </div>
          <div style={{ padding: '8px 22px 22px' }}>{children}</div>
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// Subtitle settings
// =============================================================================

function SubtitleSettingsSheet({ tweaks, onClose }) {
  const [mode, setMode] = React.useState('both');
  const [enSize, setEnSize] = React.useState(tweaks.subSize);
  const [zhSize, setZhSize] = React.useState(13);
  const [autoScroll, setAutoScroll] = React.useState(true);
  const [floating, setFloating] = React.useState(true);

  const modes = [
    { id: 'en', label: '仅英文' },
    { id: 'both', label: '双语' },
    { id: 'zh', label: '仅中文' },
  ];

  return (
    <SheetShell title="字幕设置" subtitle="演示用，更改不会持久化" onClose={onClose}>
      <Field label="显示模式">
        <div style={{
          display: 'flex', gap: 4, padding: 3, borderRadius: 10,
          background: 'var(--chip-bg)',
        }}>
          {modes.map((m) => (
            <button key={m.id} onClick={() => setMode(m.id)} style={{
              flex: 1, padding: '8px 0', borderRadius: 7, border: 'none', cursor: 'pointer',
              background: mode === m.id ? 'var(--chip-bg-active)' : 'transparent',
              boxShadow: mode === m.id ? '0 1px 2px rgba(0,0,0,0.2)' : 'none',
              fontFamily: '"PingFang SC", sans-serif', fontSize: 12.5, fontWeight: 500,
              color: mode === m.id ? 'var(--text)' : 'var(--text-sec)',
            }}>{m.label}</button>
          ))}
        </div>
      </Field>

      <Field label="英文字号" value={`${enSize}px`}>
        <RangeSlider value={enSize} min={13} max={20} step={1} onChange={setEnSize} brand={tweaks.brandColor}/>
      </Field>

      <Field label="中文字号" value={`${zhSize}px`}>
        <RangeSlider value={zhSize} min={11} max={18} step={1} onChange={setZhSize} brand={tweaks.brandColor}/>
      </Field>

      <Field label="自动滚动">
        <Toggle value={autoScroll} onChange={setAutoScroll} brand={tweaks.brandColor}/>
      </Field>

      <Field label="浮动字幕（视频区上）">
        <Toggle value={floating} onChange={setFloating} brand={tweaks.brandColor}/>
      </Field>

      {/* Preview */}
      <div style={{
        marginTop: 16, padding: '14px 16px', borderRadius: 12,
        background: 'rgba(0,0,0,0.4)',
        border: 'var(--card-border)',
      }}>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.5, marginBottom: 6,
        }}>预览</div>
        {(mode === 'en' || mode === 'both') && (
          <div style={{
            fontFamily: 'Inter, sans-serif', fontSize: enSize, lineHeight: 1.4,
          }}>
            <span style={{ color: 'var(--text-ter)' }}>it's the most </span>
            <span style={{ color: tweaks.brandText, fontWeight: 500 }}>powerful</span>
            <span style={{ color: 'var(--text)' }}> sound in the world</span>
          </div>
        )}
        {(mode === 'zh' || mode === 'both') && (
          <div style={{
            marginTop: mode === 'both' ? 5 : 0,
            fontFamily: '"PingFang SC", sans-serif', fontSize: zhSize,
            color: 'var(--text-sec)', lineHeight: 1.5,
          }}>可能是这世界上最有力的声音。</div>
        )}
      </div>
    </SheetShell>
  );
}

// =============================================================================
// Shadowing practice
// =============================================================================

function ShadowingSheet({ segment, tweaks, onClose }) {
  const [recording, setRecording] = React.useState(false);
  const [result, setResult] = React.useState(null); // { score: 0-100, feedback }
  const [tick, setTick] = React.useState(0);

  // Animate fake waveform while recording
  React.useEffect(() => {
    if (!recording) return;
    const id = setInterval(() => setTick(t => t + 1), 60);
    const stopTimer = setTimeout(() => {
      setRecording(false);
      setResult({
        score: 87,
        feedback: '整体清晰，但 "powerful" 的重音稍弱，建议在第二音节加重。',
      });
    }, 3500);
    return () => { clearInterval(id); clearTimeout(stopTimer); };
  }, [recording]);

  return (
    <SheetShell title="跟读练习" subtitle="录下你的发音，AI 给出反馈" onClose={onClose}>
      {/* Reference sentence */}
      <div style={{
        padding: '14px 16px', borderRadius: 12,
        background: 'var(--surface)',
      }}>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: tweaks.brandText, letterSpacing: 0.5, marginBottom: 6, fontWeight: 700,
        }}>原句</div>
        <div style={{
          fontFamily: 'Inter, sans-serif', fontSize: 15, lineHeight: 1.45, color: 'var(--text)',
        }}>{segment.text}.</div>
        {segment.tr && (
          <div style={{
            marginTop: 4,
            fontFamily: '"PingFang SC", sans-serif', fontSize: 12,
            color: 'var(--text-ter)',
          }}>{segment.tr}</div>
        )}
      </div>

      {/* Audio comparison */}
      <div style={{
        marginTop: 14, padding: '14px 16px', borderRadius: 12,
        background: 'var(--surface-subtle)',
        border: 'var(--card-border)',
      }}>
        {/* Original waveform */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
          <button style={{
            width: 32, height: 32, borderRadius: 16,
            background: tweaks.brandColor, border: 'none', cursor: 'pointer', padding: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <div style={{ marginLeft: 2 }}><Icon name="play" size={13} color="#0a0a0c"/></div>
          </button>
          <Waveform color={tweaks.brandColor} active animated={false}/>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
            color: 'var(--text-sec)', flexShrink: 0,
          }}>0:02</span>
        </div>
        {/* Your recording */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <button style={{
            width: 32, height: 32, borderRadius: 16,
            background: result ? tweaks.aiColor : 'var(--chip-bg-active)',
            border: 'none', cursor: 'pointer', padding: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <div style={{ marginLeft: 2 }}>
              <Icon name="play" size={13} color={result ? '#0a0a0c' : 'var(--text-muted)'}/>
            </div>
          </button>
          <Waveform color={tweaks.aiColor} active={!!result} animated={recording} tick={tick}/>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
            color: 'var(--text-sec)', flexShrink: 0,
          }}>{result ? '0:02' : recording ? '...' : '—'}</span>
        </div>
      </div>

      {/* Score / feedback */}
      {result && (
        <div style={{
          marginTop: 14, padding: '14px 16px', borderRadius: 12,
          background: `${tweaks.aiColor}12`,
          border: `0.5px solid ${tweaks.aiColor}33`,
        }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 6 }}>
            <Icon name="sparkles" size={13} color={tweaks.aiColor}/>
            <span style={{
              fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5, fontWeight: 700,
              color: tweaks.aiText, letterSpacing: 0.5,
            }}>AI 评分</span>
            <span style={{ flex: 1 }}/>
            <span style={{
              fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 28,
              color: tweaks.aiText, letterSpacing: -1, lineHeight: 1,
            }}>{result.score}</span>
            <span style={{
              fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
              color: 'var(--text-sec)',
            }}>/100</span>
          </div>
          <div style={{
            fontFamily: '"PingFang SC", sans-serif', fontSize: 12.5,
            color: 'var(--text-sec)', lineHeight: 1.55,
          }}>{result.feedback}</div>
        </div>
      )}

      {/* Record button */}
      <button onClick={() => {
        if (recording) return;
        setResult(null);
        setRecording(true);
      }} style={{
        width: '100%', marginTop: 16, padding: '14px 0', borderRadius: 12, border: 'none',
        background: recording ? '#FF6E6E' : tweaks.brandColor,
        color: '#0a0a0c', cursor: 'pointer',
        fontFamily: '"PingFang SC", sans-serif', fontSize: 14, fontWeight: 600,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
      }}>
        {recording ? (
          <>
            <span style={{
              width: 10, height: 10, borderRadius: 2, background: 'var(--bg)',
              animation: 'pulse 1s ease-in-out infinite',
            }}/>
            正在录音… 点击停止
          </>
        ) : (
          <>
            <Icon name="mic" size={14} color="#0a0a0c"/>
            {result ? '重新录制' : '开始录音'}
          </>
        )}
      </button>
    </SheetShell>
  );
}

function Waveform({ color, active, animated, tick = 0 }) {
  // Generate 20 bars with pseudo-random heights, animated if `animated`
  const bars = Array.from({ length: 28 }, (_, i) => {
    const base = Math.abs(Math.sin(i * 1.31)) * 0.7 + 0.2;
    const animOffset = animated ? Math.sin((i + tick * 0.6) * 0.7) * 0.3 : 0;
    return Math.max(0.12, Math.min(1, base + animOffset));
  });
  return (
    <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 2.5, height: 28 }}>
      {bars.map((h, i) => (
        <div key={i} style={{
          flex: 1, height: `${h * 100}%`, minHeight: 3,
          borderRadius: 1.5,
          background: active ? color : 'var(--divider-strong)',
          opacity: active ? (0.5 + h * 0.5) : 1,
          transition: animated ? 'none' : 'all 200ms',
        }}/>
      ))}
    </div>
  );
}

function Field({ label, value, children }) {
  return (
    <div style={{ marginTop: 14 }}>
      <div style={{
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
        marginBottom: 8,
      }}>
        <span style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 13,
          color: 'var(--text-sec)',
        }}>{label}</span>
        {value && (
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 11,
            color: 'var(--text-ter)',
          }}>{value}</span>
        )}
      </div>
      {children}
    </div>
  );
}

function RangeSlider({ value, min, max, step, onChange, brand }) {
  const pct = ((value - min) / (max - min)) * 100;
  return (
    <div style={{ position: 'relative', height: 24, display: 'flex', alignItems: 'center' }}>
      <div style={{
        position: 'absolute', left: 0, right: 0, height: 3, borderRadius: 2,
        background: 'var(--chip-bg-active)',
      }}/>
      <div style={{
        position: 'absolute', left: 0, height: 3, borderRadius: 2,
        width: `${pct}%`,
        background: `linear-gradient(90deg, ${brand}, ${brand}cc)`,
      }}/>
      <input
        type="range" min={min} max={max} step={step} value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        style={{
          position: 'absolute', inset: 0, width: '100%', height: '100%',
          opacity: 0, cursor: 'pointer',
        }}
      />
      <div style={{
        position: 'absolute', left: `${pct}%`, transform: 'translateX(-50%)',
        width: 14, height: 14, borderRadius: '50%',
        background: '#fff',
        boxShadow: '0 2px 6px rgba(0,0,0,0.4)',
        pointerEvents: 'none',
      }}/>
    </div>
  );
}

function Toggle({ value, onChange, brand }) {
  return (
    <button onClick={() => onChange(!value)} style={{
      width: 46, height: 28, borderRadius: 14, border: 'none', cursor: 'pointer',
      background: value ? brand : 'var(--divider-strong)',
      position: 'relative', padding: 0, transition: 'background 200ms',
    }}>
      <div style={{
        position: 'absolute', top: 2, left: value ? 20 : 2,
        width: 24, height: 24, borderRadius: 12,
        background: '#fff',
        boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
        transition: 'left 200ms',
      }}/>
    </button>
  );
}

window.SubtitleSettingsSheet = SubtitleSettingsSheet;
window.ShadowingSheet = ShadowingSheet;
