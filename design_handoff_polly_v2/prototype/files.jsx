// files.jsx — 「文件」tab：导入本地视频 / YouTube 链接 + 已导入列表

function FilesScreen({ tweaks, onOpenVideo }) {
  const [importing, setImporting] = React.useState(null); // null | 'photo' | 'youtube'
  const [urlInput, setUrlInput] = React.useState('');

  // Mock imported videos with various processing states
  const imports = [
    {
      id: 'imp-1',
      title: 'TED · The power of vulnerability',
      source: 'YouTube',
      duration: '20:50',
      thumb: null,
      status: 'ready',
      progress: 1,
      size: '184 MB',
      addedAt: '今天 14:32',
    },
    {
      id: 'imp-2',
      title: '60 Minutes interview · 2025',
      source: '相册',
      duration: '8:14',
      thumb: null,
      status: 'processing',
      stage: '生成字幕',
      progress: 0.62,
      size: '92 MB',
      addedAt: '今天 13:18',
    },
    {
      id: 'imp-3',
      title: 'BBC News · Climate Summit',
      source: 'YouTube',
      duration: '12:03',
      thumb: null,
      status: 'queued',
      stage: '排队中 · 等待 ASR',
      progress: 0,
      size: '—',
      addedAt: '昨天 21:05',
    },
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--bg)', color: 'var(--text)',
      overflow: 'auto', WebkitOverflowScrolling: 'touch', paddingTop: 56,
    }}>
      {/* Top nav title */}
      <div style={{
        padding: '10px 22px 8px', display: 'flex',
        justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 17, fontWeight: 600,
          color: 'var(--text)',
        }}>文件</div>
        <button style={{
          width: 36, height: 36, borderRadius: 18, background: 'var(--chip-bg)',
          border: 'none', cursor: 'pointer', padding: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="search" size={15} color="var(--text-sec)"/>
        </button>
      </div>

      {/* Large hero title */}
      <div style={{ padding: '14px 22px 18px' }}>
        <div style={{
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 32,
          color: 'var(--text)', letterSpacing: -1, lineHeight: 1.05,
        }}>Import a video</div>
        <div style={{
          marginTop: 4,
          fontFamily: '"PingFang SC", sans-serif', fontSize: 13,
          color: 'var(--text-sec)',
        }}>任何视频都能被 AI 加工成一节精读课</div>
      </div>

      {/* Import action tiles */}
      <div style={{ padding: '0 14px 18px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <ImportTile
            icon="photo"
            iconColor={tweaks.brandColor}
            iconBg={`${tweaks.brandColor}22`}
            label="相册视频"
            hint="从相册或文件"
            onClick={() => setImporting('photo')}
          />
          <ImportTile
            icon="link"
            iconColor={tweaks.aiColor}
            iconBg={`${tweaks.aiColor}22`}
            label="YouTube 链接"
            hint="粘贴视频网址"
            onClick={() => setImporting('youtube')}
          />
        </div>
      </div>

      {/* AI capability hint */}
      <div style={{ padding: '0 14px 18px' }}>
        <div style={{
          padding: '12px 14px', borderRadius: 12,
          background: `linear-gradient(135deg, ${tweaks.aiColor}14 0%, transparent 100%)`,
          border: `0.5px solid ${tweaks.aiColor}22`,
          display: 'flex', alignItems: 'flex-start', gap: 10,
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: 6,
            background: `${tweaks.aiColor}24`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <Icon name="sparkles" size={11} color={tweaks.aiColor}/>
          </div>
          <div style={{
            flex: 1,
            fontFamily: '"PingFang SC", sans-serif', fontSize: 12,
            color: 'var(--text-sec)', lineHeight: 1.5,
          }}>
            <span style={{ color: tweaks.aiText, fontWeight: 600 }}>AI 加工</span> · 自动识别音轨、生成英文字幕、翻译成中文、标注关键词。整个过程通常 2–5 分钟。
          </div>
        </div>
      </div>

      {/* Imported list */}
      <div style={{
        padding: '8px 22px 10px',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      }}>
        <div style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 500,
          color: 'var(--text-sec)', letterSpacing: 0.3,
          textTransform: 'uppercase',
        }}>已导入 · {imports.length}</div>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
          color: 'var(--text-ter)', letterSpacing: 0.5,
        }}>免费额度 7 / 10</div>
      </div>

      <div style={{ padding: '0 14px 130px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {imports.map((item) => (
          <ImportRow key={item.id} item={item} tweaks={tweaks}
            onClick={() => item.status === 'ready' && onOpenVideo(item)}/>
        ))}
      </div>

      {/* Import sheet (mock) */}
      {importing === 'youtube' && (
        <ImportSheet
          title="粘贴 YouTube 链接"
          subtitle="支持 youtube.com / youtu.be / m.youtube.com"
          input={
            <div style={{
              padding: '12px 14px', borderRadius: 12,
              background: 'var(--chip-bg)',
              border: `1px solid ${tweaks.aiColor}55`,
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <Icon name="link" size={16} color={tweaks.aiColor}/>
              <input
                value={urlInput}
                onChange={(e) => setUrlInput(e.target.value)}
                placeholder="https://www.youtube.com/watch?v=..."
                style={{
                  flex: 1, background: 'transparent', border: 'none', outline: 'none',
                  color: 'var(--text)', fontFamily: 'JetBrains Mono, monospace', fontSize: 12,
                }}
              />
            </div>
          }
          ctaLabel="开始 AI 加工"
          ctaColor={tweaks.aiColor}
          onClose={() => { setImporting(null); setUrlInput(''); }}
        />
      )}

      {importing === 'photo' && (
        <ImportSheet
          title="从相册导入"
          subtitle="支持 mp4 / mov，最长 30 分钟，最大 500 MB"
          input={
            <div style={{
              padding: '24px 14px', borderRadius: 12,
              background: 'var(--surface)',
              border: '1px dashed var(--divider-strong)',
              textAlign: 'center',
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: 22, margin: '0 auto 10px',
                background: `${tweaks.brandColor}22`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="upload" size={20} color={tweaks.brandColor}/>
              </div>
              <div style={{
                fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 500,
                color: 'var(--text)',
              }}>选择视频文件</div>
              <div style={{
                marginTop: 4,
                fontFamily: '"PingFang SC", sans-serif', fontSize: 11,
                color: 'var(--text-ter)',
              }}>从相册、iCloud Drive 或 文件 App 选取</div>
            </div>
          }
          ctaLabel="选择文件"
          ctaColor={tweaks.brandColor}
          onClose={() => setImporting(null)}
        />
      )}
    </div>
  );
}

function ImportTile({ icon, iconColor, iconBg, label, hint, onClick }) {
  return (
    <button onClick={onClick} style={{
      background: 'var(--surface)',
      border: 'var(--card-border)',
      borderRadius: 16,
      padding: '18px 16px',
      cursor: 'pointer',
      textAlign: 'left',
      display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 14,
    }}>
      <div style={{
        width: 38, height: 38, borderRadius: 11,
        background: iconBg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={20} color={iconColor}/>
      </div>
      <div>
        <div style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 14, fontWeight: 600,
          color: 'var(--text)', lineHeight: 1.2,
        }}>{label}</div>
        <div style={{
          marginTop: 4,
          fontFamily: '"PingFang SC", sans-serif', fontSize: 11.5,
          color: 'var(--text-ter)', letterSpacing: 0.2,
        }}>{hint}</div>
      </div>
    </button>
  );
}

function ImportRow({ item, tweaks, onClick }) {
  const isReady = item.status === 'ready';
  const isProcessing = item.status === 'processing';
  const isQueued = item.status === 'queued';

  return (
    <div onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 12px', borderRadius: 12,
      background: 'var(--surface)',
      border: 'var(--card-border)',
      cursor: isReady ? 'pointer' : 'default',
    }}>
      {/* Thumb placeholder */}
      <div style={{
        width: 60, height: 60, borderRadius: 10, flexShrink: 0,
        background: 'linear-gradient(135deg, #1a1820 0%, #0a0a0c 100%)',
        border: 'var(--card-border)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
      }}>
        {isProcessing ? (
          <div style={{
            width: 30, height: 30, borderRadius: 15,
            border: `2.5px solid ${tweaks.aiColor}25`,
            borderTopColor: tweaks.aiColor,
            animation: 'spin 1.2s linear infinite',
          }}/>
        ) : isQueued ? (
          <Icon name="loop" size={18} color="var(--text-ter)"/>
        ) : (
          <Icon name="play" size={16} color={tweaks.brandColor}/>
        )}
      </div>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: 'Inter, "PingFang SC", sans-serif', fontWeight: 500, fontSize: 13.5,
          color: 'var(--text)', lineHeight: 1.3, letterSpacing: -0.1,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{item.title}</div>

        {isReady ? (
          <div style={{
            marginTop: 4,
            fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
            color: 'var(--text-ter)', letterSpacing: 0.3,
          }}>
            {item.duration} · {item.size} · 来自 {item.source}
          </div>
        ) : (
          <div style={{ marginTop: 6 }}>
            <div style={{
              fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
              color: tweaks.aiText, letterSpacing: 0.5, fontWeight: 700,
              display: 'flex', alignItems: 'center', gap: 6,
            }}>
              <span style={{
                width: 5, height: 5, borderRadius: '50%',
                background: tweaks.aiColor,
                animation: isProcessing ? 'pulse 1.2s ease-in-out infinite' : 'none',
                opacity: isQueued ? 0.5 : 1,
              }}/>
              {isProcessing ? `AI 加工中 · ${item.stage}` : item.stage}
            </div>
            <div style={{
              marginTop: 6, height: 2.5, borderRadius: 2,
              background: 'var(--chip-bg-active)', overflow: 'hidden',
              position: 'relative',
            }}>
              <div style={{
                position: 'absolute', left: 0, top: 0, bottom: 0,
                width: `${item.progress * 100}%`,
                background: tweaks.aiColor,
                boxShadow: `0 0 6px ${tweaks.aiColor}80`,
                transition: 'width 400ms',
              }}/>
            </div>
          </div>
        )}
      </div>

      {isReady ? (
        <Icon name="chevron-right" size={14} color="var(--text-ter)"/>
      ) : (
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
          color: 'var(--text-ter)',
        }}>{Math.round(item.progress * 100)}%</div>
      )}
    </div>
  );
}

// Bottom sheet for import flows
function ImportSheet({ title, subtitle, input, ctaLabel, ctaColor, onClose }) {
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => {
    const id = setTimeout(() => setMounted(true), 16);
    return () => clearTimeout(id);
  }, []);
  const close = () => { setMounted(false); setTimeout(onClose, 220); };

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 110 }}>
      <div onClick={close} style={{
        position: 'absolute', inset: 0,
        background: 'rgba(0,0,0,0.5)',
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
          borderRadius: 22, padding: '22px 22px 22px',
          boxShadow: 'var(--shadow-card)',
          position: 'relative',
        }}>
          <div style={{
            position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
            width: 36, height: 4, borderRadius: 2, background: 'var(--divider-strong)',
          }}/>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginTop: 4 }}>
            <div>
              <div style={{
                fontFamily: '"PingFang SC", sans-serif', fontSize: 18, fontWeight: 600, color: 'var(--text)',
              }}>{title}</div>
              <div style={{
                marginTop: 4,
                fontFamily: '"PingFang SC", sans-serif', fontSize: 12, color: 'var(--text-sec)',
              }}>{subtitle}</div>
            </div>
            <button onClick={close} style={{
              width: 30, height: 30, borderRadius: 15, border: 'none',
              background: 'var(--chip-bg)', cursor: 'pointer', padding: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="close" size={12} color="var(--text-sec)"/>
            </button>
          </div>

          <div style={{ marginTop: 16 }}>{input}</div>

          <button onClick={close} style={{
            width: '100%', marginTop: 14, padding: '13px 0', borderRadius: 12, border: 'none',
            background: ctaColor, color: '#0a0a0c', cursor: 'pointer',
            fontFamily: '"PingFang SC", sans-serif', fontSize: 14, fontWeight: 600,
          }}>{ctaLabel}</button>
        </div>
      </div>
    </div>
  );
}

window.FilesScreen = FilesScreen;
