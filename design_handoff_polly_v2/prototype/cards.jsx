// cards.jsx — WordCard (tap-word lookup) + AICard (long-press AI explanation)
// Both are bottom-sheet style with spring entrance.

// =============================================================================
// WordCard
// =============================================================================

function WordCard({ word, sentence, tweaks, onClose }) {
  const [added, setAdded] = React.useState(false);
  const [mounted, setMounted] = React.useState(false);
  const entry = window.WORDS[word.w.toLowerCase().replace(/[^\w]/g, '')];

  React.useEffect(() => {
    const id = setTimeout(() => setMounted(true), 16);
    return () => clearTimeout(id);
  }, []);

  const close = () => {
    setMounted(false);
    setTimeout(onClose, 220);
  };

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      pointerEvents: 'auto',
    }}>
      {/* backdrop */}
      <div onClick={close} style={{
        position: 'absolute', inset: 0,
        background: 'rgba(0,0,0,0.45)',
        backdropFilter: 'blur(2px)',
        opacity: mounted ? 1 : 0,
        transition: 'opacity 220ms',
      }} />

      {/* sheet */}
      <div style={{
        position: 'absolute', left: 12, right: 12, bottom: 18,
        transform: `translateY(${mounted ? 0 : 30}px) scale(${mounted ? 1 : 0.96})`,
        opacity: mounted ? 1 : 0,
        transition: 'transform 350ms cubic-bezier(.22,1.3,.36,1), opacity 220ms',
      }}>
        <div style={{
          background: 'var(--surface-elev)',
          backdropFilter: 'blur(24px) saturate(180%)',
          borderRadius: 22, padding: '22px 22px 18px',
          boxShadow: 'var(--shadow-card)',
        }}>
          {/* Drag handle */}
          <div style={{
            position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
            width: 36, height: 4, borderRadius: 2, background: 'var(--divider-strong)',
          }} />

          {/* Header */}
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginTop: 6 }}>
            <div style={{
              fontFamily: 'Fraunces, serif', fontSize: 34, fontWeight: 500,
              color: 'var(--text)', lineHeight: 1, letterSpacing: -0.3,
            }}>{word.w}</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <button onClick={() => setAdded(!added)} style={{
                width: 32, height: 32, borderRadius: 16, border: 'none',
                background: added ? `${tweaks.brandColor}1f` : 'var(--chip-bg)',
                cursor: 'pointer', padding: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                transition: 'background 150ms',
              }}>
                <Icon name={added ? "star-filled" : "star"} size={16}
                  color={added ? tweaks.brandText : 'var(--text-sec)'} />
              </button>
              <button onClick={close} style={{
                width: 32, height: 32, borderRadius: 16, border: 'none',
                background: 'var(--chip-bg)', cursor: 'pointer', padding: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="close" size={14} color="var(--text-sec)" />
              </button>
            </div>
          </div>

          {entry ? (
            <>
              {/* Phonetic */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 12 }}>
                <button style={{
                  display: 'flex', alignItems: 'center', gap: 5,
                  padding: '5px 9px', borderRadius: 14, border: 'none',
                  background: 'var(--chip-bg)', cursor: 'pointer',
                }}>
                  <Icon name="volume" size={12} color={tweaks.aiColor} />
                  <span style={{
                    fontFamily: 'JetBrains Mono, monospace', fontSize: 12,
                    color: 'var(--text)',
                  }}>{entry.phonetic}</span>
                </button>
                {entry.level && (
                  <span style={{
                    padding: '3px 8px', borderRadius: 10,
                    background: `${tweaks.aiColor}22`,
                    fontFamily: 'JetBrains Mono, monospace', fontSize: 10, fontWeight: 700,
                    color: tweaks.aiText, letterSpacing: 0.3,
                  }}>{entry.level}</span>
                )}
              </div>

              {/* Definitions */}
              <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
                {entry.defs.map((d, i) => (
                  <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                    <span style={{
                      padding: '2px 6px', borderRadius: 5,
                      background: `${tweaks.aiColor}22`,
                      fontFamily: 'JetBrains Mono, monospace', fontSize: 10, fontWeight: 700,
                      color: tweaks.aiText, letterSpacing: 0.2, lineHeight: 1.4,
                      flexShrink: 0,
                    }}>{d.pos}</span>
                    <span style={{
                      fontFamily: '"PingFang SC", sans-serif', fontSize: 14.5,
                      color: 'var(--text)', lineHeight: 1.45,
                    }}>{d.meaning}</span>
                  </div>
                ))}
              </div>

              {/* Example */}
              {sentence && (
                <div style={{ marginTop: 16 }}>
                  <div style={{
                    fontFamily: 'Inter, sans-serif', fontSize: 10, fontWeight: 600,
                    color: 'var(--text-ter)', letterSpacing: 0.5,
                  }}>EXAMPLE</div>
                  <div style={{
                    marginTop: 4,
                    fontFamily: 'Inter, sans-serif', fontStyle: 'italic', fontSize: 13,
                    color: 'var(--text-sec)', lineHeight: 1.45,
                  }}>
                    {sentence.text.split(/\s+/).map((w, i) => {
                      const isTarget = w.toLowerCase().replace(/[^\w]/g, '') === word.w.toLowerCase().replace(/[^\w]/g, '');
                      return <span key={i} style={{
                        color: isTarget ? tweaks.brandText : undefined,
                        fontWeight: isTarget ? 600 : undefined,
                        marginRight: 4,
                      }}>{w}</span>;
                    })}
                  </div>
                  <div style={{
                    marginTop: 2,
                    fontFamily: '"PingFang SC", sans-serif', fontSize: 11.5,
                    color: 'var(--text-ter)',
                  }}>{sentence.tr}</div>
                </div>
              )}

              {/* Collocations */}
              {entry.collocations && entry.collocations.length > 0 && (
                <div style={{ marginTop: 16 }}>
                  <div style={{
                    fontFamily: '"PingFang SC", sans-serif', fontSize: 11, fontWeight: 600,
                    color: 'var(--text-ter)', letterSpacing: 0.3,
                  }}>常见搭配</div>
                  <div style={{ marginTop: 7, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                    {entry.collocations.map((c, i) => (
                      <span key={i} style={{
                        padding: '4px 9px', borderRadius: 6,
                        background: 'var(--surface)',
                        fontFamily: 'Inter, sans-serif', fontSize: 11.5,
                        color: 'var(--text-sec)',
                      }}>{c}</span>
                    ))}
                  </div>
                </div>
              )}

              {/* CTAs */}
              <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
                <button style={{
                  flex: 1, padding: '12px 0', borderRadius: 12, border: 'none',
                  background: 'var(--chip-bg-active)', color: 'var(--text)', cursor: 'pointer',
                  fontFamily: '"PingFang SC", sans-serif', fontSize: 13.5, fontWeight: 500,
                }}>完整释义</button>
                <button style={{
                  flex: 1, padding: '12px 0', borderRadius: 12, border: 'none',
                  background: tweaks.aiColor, color: '#0a0a0c', cursor: 'pointer',
                  fontFamily: '"PingFang SC", sans-serif', fontSize: 13.5, fontWeight: 600,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
                }}>
                  <Icon name="sparkles" size={13} color="#0a0a0c" />
                  AI 详解
                </button>
              </div>
            </>
          ) : (
            <div style={{ padding: '32px 0', textAlign: 'center' }}>
              <div style={{
                fontFamily: '"PingFang SC", sans-serif', fontSize: 14,
                color: 'var(--text-sec)',
              }}>该词暂无本地释义</div>
              <div style={{
                marginTop: 6,
                fontFamily: '"PingFang SC", sans-serif', fontSize: 11,
                color: 'var(--text-ter)',
              }}>点击 AI 详解由 gpt-4o 实时生成</div>
              <button style={{
                marginTop: 18, padding: '10px 20px', borderRadius: 12, border: 'none',
                background: tweaks.aiColor, color: '#0a0a0c', cursor: 'pointer',
                fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 600,
                display: 'inline-flex', alignItems: 'center', gap: 6,
              }}>
                <Icon name="sparkles" size={13} color="#0a0a0c" />
                AI 详解
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// AI Explanation Card
// =============================================================================

function AICard({ segment, tweaks, onClose }) {
  const [mounted, setMounted] = React.useState(false);
  const [loaded, setLoaded] = React.useState(false);
  const ai = window.AI_EXPLANATIONS[segment.id] || window.AI_DEFAULT;

  React.useEffect(() => {
    const id = setTimeout(() => setMounted(true), 16);
    // Simulate AI loading
    const t = setTimeout(() => setLoaded(true), 900);
    return () => { clearTimeout(id); clearTimeout(t); };
  }, []);

  const close = () => {
    setMounted(false);
    setTimeout(onClose, 220);
  };

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
    }}>
      {/* backdrop */}
      <div onClick={close} style={{
        position: 'absolute', inset: 0,
        background: 'rgba(0,0,0,0.55)',
        backdropFilter: 'blur(2px)',
        opacity: mounted ? 1 : 0,
        transition: 'opacity 220ms',
      }} />

      {/* sheet */}
      <div style={{
        position: 'absolute', left: 12, right: 12, bottom: 18,
        maxHeight: '78%',
        transform: `translateY(${mounted ? 0 : 30}px) scale(${mounted ? 1 : 0.96})`,
        opacity: mounted ? 1 : 0,
        transition: 'transform 350ms cubic-bezier(.22,1.3,.36,1), opacity 220ms',
      }}>
        <div style={{
          background: 'var(--surface-elev)',
          backdropFilter: 'blur(24px) saturate(180%)',
          borderRadius: 22,
          maxHeight: '100%', display: 'flex', flexDirection: 'column',
          boxShadow: 'var(--shadow-card)',
        }}>
          {/* Drag handle */}
          <div style={{
            position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
            width: 36, height: 4, borderRadius: 2, background: 'var(--divider-strong)',
          }} />

          {/* Header */}
          <div style={{
            padding: '20px 22px 14px', display: 'flex',
            alignItems: 'center', justifyContent: 'space-between',
            borderBottom: '0.5px solid var(--divider)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{
                width: 26, height: 26, borderRadius: 8,
                background: `${tweaks.aiColor}22`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="sparkles" size={14} color={tweaks.aiColor} />
              </div>
              <span style={{
                fontFamily: '"PingFang SC", sans-serif', fontSize: 15, fontWeight: 600,
                color: 'var(--text)',
              }}>AI 讲解</span>
              {!loaded && (
                <div style={{
                  marginLeft: 4, padding: '2px 8px', borderRadius: 10,
                  background: 'rgba(184,196,255,0.12)',
                  fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
                  color: tweaks.aiText,
                  display: 'flex', alignItems: 'center', gap: 4,
                }}>
                  <span style={{
                    width: 5, height: 5, borderRadius: '50%',
                    background: tweaks.aiColor,
                    animation: 'pulse 1.2s ease-in-out infinite',
                  }}/>
                  GENERATING
                </div>
              )}
            </div>
            <button onClick={close} style={{
              width: 30, height: 30, borderRadius: 15, border: 'none',
              background: 'var(--chip-bg)', cursor: 'pointer', padding: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="close" size={13} color="var(--text-sec)" />
            </button>
          </div>

          {/* Scrollable content */}
          <div style={{
            overflowY: 'auto', WebkitOverflowScrolling: 'touch',
            padding: '14px 22px 18px',
          }}>
            {/* Original sentence */}
            <div style={{
              padding: '12px 14px', borderRadius: 12,
              background: 'var(--surface)',
              fontFamily: 'Inter, sans-serif', fontSize: 14, lineHeight: 1.45,
              color: 'var(--text)',
            }}>{segment.text}.</div>

            {/* Skeleton while loading */}
            {!loaded ? <AISkeleton aiColor={tweaks.aiColor} /> : (
              <>
                <Section label="地道翻译" body={ai.natural} />
                <Section label="核心讲解" body={ai.core} />
                <VocabList vocab={ai.vocab} aiColor={tweaks.aiColor} />
                {ai.culture && <Section label="文化背景" body={ai.culture} />}
              </>
            )}

            {/* Disclaimer */}
            <div style={{
              marginTop: 18, paddingTop: 12,
              borderTop: '0.5px solid var(--divider)',
              fontFamily: '"PingFang SC", sans-serif', fontSize: 10.5,
              color: 'var(--text-ter)', lineHeight: 1.5,
            }}>
              ⓘ 本讲解由 AI 生成，可能存在错误。请结合上下文判断。
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Section({ label, body }) {
  return (
    <div style={{ marginTop: 16 }}>
      <div style={{
        fontFamily: '"PingFang SC", sans-serif', fontSize: 11.5,
        color: 'var(--text-ter)', letterSpacing: 0.3, marginBottom: 5,
      }}>{label}</div>
      <div style={{
        fontFamily: '"PingFang SC", sans-serif', fontSize: 13.5,
        color: 'var(--text)', lineHeight: 1.65,
      }}>{body}</div>
    </div>
  );
}

function VocabList({ vocab, aiColor }) {
  if (!vocab || vocab.length === 0) return null;
  return (
    <div style={{ marginTop: 16 }}>
      <div style={{
        fontFamily: '"PingFang SC", sans-serif', fontSize: 11.5,
        color: 'var(--text-ter)', letterSpacing: 0.3, marginBottom: 8,
      }}>关键词汇</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {vocab.map((v, i) => (
          <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
            <div style={{
              width: 5, height: 5, borderRadius: '50%',
              background: aiColor, marginTop: 8, flexShrink: 0,
              boxShadow: `0 0 4px ${aiColor}80`,
            }}/>
            <div style={{ flex: 1 }}>
              <span style={{
                fontFamily: 'Inter, sans-serif', fontSize: 14, fontWeight: 600,
                color: 'var(--text)', marginRight: 6,
              }}>{v.w}</span>
              <div style={{
                marginTop: 3,
                fontFamily: '"PingFang SC", sans-serif', fontSize: 12.5,
                color: 'var(--text-sec)', lineHeight: 1.55,
              }}>{v.note}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function AISkeleton({ aiColor }) {
  return (
    <div style={{ paddingTop: 14, display: 'flex', flexDirection: 'column', gap: 12 }}>
      {[80, 92, 68, 88, 75].map((w, i) => (
        <div key={i} style={{
          height: 12, width: `${w}%`, borderRadius: 6,
          background: `linear-gradient(90deg, ${aiColor}10, ${aiColor}25, ${aiColor}10)`,
          backgroundSize: '200% 100%',
          animation: 'shimmer 1.4s linear infinite',
        }} />
      ))}
    </div>
  );
}

window.WordCard = WordCard;
window.AICard = AICard;
