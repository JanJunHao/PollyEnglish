// player.jsx — PollyEnglish video player screen
// Video frame + floating subtitle + chips + subtitle list (word-level highlight) + progress + bottom tab bar.
// Tap a word -> WordCard. Long-press a sentence -> AICard.

function PlayerScreen({ video, tweaks, onBack, onTapWord, onLongPressSentence, currentTime, isPlaying, setIsPlaying, seek, onOpenSubSettings, onOpenShadowing }) {
  const segments = window.SUBTITLES;
  const TOTAL = 9 * 60 + 58; // 9:58
  const listRef = React.useRef(null);
  const [autoScroll, setAutoScroll] = React.useState(true);
  const [userScrolledAt, setUserScrolledAt] = React.useState(null);
  const [aiSubtitleOn, setAiSubtitleOn] = React.useState(true);

  // Determine current segment
  const currentSeg = React.useMemo(() => {
    for (let i = segments.length - 1; i >= 0; i--) {
      if (currentTime >= segments[i].s) return segments[i];
    }
    return segments[0];
  }, [currentTime, segments]);

  // Auto-scroll current segment into view
  React.useEffect(() => {
    if (!autoScroll || !listRef.current) return;
    if (userScrolledAt && Date.now() - userScrolledAt < 4000) return;
    const el = listRef.current.querySelector(`[data-seg-id="${currentSeg.id}"]`);
    if (el) {
      const list = listRef.current;
      const top = el.offsetTop - list.clientHeight / 2 + el.clientHeight / 2;
      list.scrollTo({ top, behavior: 'smooth' });
    }
  }, [currentSeg.id, autoScroll, userScrolledAt]);

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--bg)', color: 'var(--text)',
      display: 'flex', flexDirection: 'column', position: 'relative',
    }}>
      {/* Top nav */}
      <div style={{
        flexShrink: 0, paddingTop: 56, paddingBottom: 10, padding: '56px 12px 10px',
        display: 'flex', alignItems: 'flex-start', gap: 8,
      }}>
        <button onClick={onBack} style={{
          width: 36, height: 36, borderRadius: 18, background: 'var(--chip-bg)',
          border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          flexShrink: 0, padding: 0,
        }}>
          <Icon name="chevron-left" size={20} color="#fff" />
        </button>
        <div style={{ flex: 1, minWidth: 0, paddingTop: 1 }}>
          <div style={{
            fontFamily: 'Inter, sans-serif', fontWeight: 600, fontSize: 14,
            color: 'var(--text)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            letterSpacing: -0.1,
          }}>{video.title}</div>
          <div style={{ marginTop: 3, display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 10.5, color: 'var(--text-sec)' }}>
              {video.speaker} · {video.source}
            </span>
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 3,
              padding: '2px 7px 2px 5px', borderRadius: 10,
              background: 'rgba(184,196,255,0.15)',
              fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5, fontWeight: 700,
              color: '#B8C4FF', letterSpacing: 0.3,
            }}>
              <Icon name="sparkles" size={10} color="#B8C4FF" />
              AI 字幕
            </span>
          </div>
        </div>
        <button style={{
          width: 36, height: 36, borderRadius: 18, background: 'var(--chip-bg)',
          border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          flexShrink: 0, padding: 0,
        }}>
          <Icon name="more" size={18} color="#fff" />
        </button>
      </div>

      {/* Video frame */}
      <div style={{ padding: '4px 12px 10px', flexShrink: 0 }}>
        <VideoFrame video={video} currentSeg={currentSeg} currentTime={currentTime}
          isPlaying={isPlaying} onTapWord={onTapWord} brand={tweaks.brandColor} ai={tweaks.aiColor}
          thumbStyle={tweaks.thumbStyle}
          aiSubtitleOn={aiSubtitleOn} />
      </div>

      {/* Chips toolbar */}
      <div style={{
        padding: '6px 12px 10px', flexShrink: 0,
        display: 'flex', gap: 8, overflowX: 'auto', overflowY: 'hidden',
        scrollbarWidth: 'none',
      }}>
        <ChipBtn icon="sparkles" label="AI 讲解" active={false} iconColor="#B8C4FF" />
        <ChipBtn icon="auto-scroll" label="自动滚动" active={autoScroll}
          onClick={() => setAutoScroll(!autoScroll)} brand={tweaks.brandColor} />
        <ChipBtn icon="star" label="收藏" />
        <ChipBtn icon="list" label="词汇" />
        <ChipBtn icon="search" label="查找" />
        <ChipBtn icon="fav" label="笔记" />
        <div style={{ minWidth: 4 }} />
      </div>

      {/* Subtitle list */}
      <div ref={listRef}
        onScroll={() => setUserScrolledAt(Date.now())}
        style={{
          flex: 1, minHeight: 0, overflow: 'auto', WebkitOverflowScrolling: 'touch',
          padding: '6px 0 16px',
        }}
      >
        {segments.map((seg) => (
          <SubtitleRow key={seg.id} seg={seg}
            isCurrent={seg.id === currentSeg.id}
            currentTime={currentTime}
            tweaks={tweaks}
            onWordTap={(w) => onTapWord(w, seg)}
            onLongPress={() => onLongPressSentence(seg)}
            onTap={() => seek(seg.s)}
          />
        ))}
      </div>

      {/* Progress bar */}
      <div style={{ flexShrink: 0, padding: '6px 16px 8px' }}>
        <Progress current={currentTime} total={TOTAL} brand={tweaks.brandColor} onSeek={seek} />
      </div>

      {/* Main control row */}
      <div style={{
        flexShrink: 0, padding: '8px 24px 6px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <CtrlBtn icon="prev-sentence" size={28}
          onClick={() => {
            const prev = [...segments].reverse().find(s => s.s < currentTime - 0.5);
            seek(prev ? prev.s : 0);
          }}
        />
        <CtrlBtn icon="back10" size={32}
          onClick={() => seek(Math.max(0, currentTime - 10))}
        />
        <button onClick={() => setIsPlaying(!isPlaying)} style={{
          width: 60, height: 60, borderRadius: '50%',
          background: tweaks.brandColor, border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 4px 18px ${tweaks.brandColor}50`,
          padding: 0,
        }}>
          {isPlaying
            ? <Icon name="pause" size={22} color="#0a0a0c" />
            : <div style={{ marginLeft: 3 }}><Icon name="play" size={22} color="#0a0a0c" /></div>}
        </button>
        <CtrlBtn icon="forward10" size={32}
          onClick={() => seek(Math.min(TOTAL, currentTime + 10))}
        />
        <CtrlBtn icon="next-sentence" size={28}
          onClick={() => {
            const next = segments.find(s => s.s > currentTime + 0.1);
            seek(next ? next.s : TOTAL);
          }}
        />
      </div>

      {/* Bottom tab bar */}
      <div style={{
        flexShrink: 0, padding: '4px 4px 30px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-around',
        borderTop: '0.5px solid var(--divider)',
      }}>
        <TabBtn icon="speed" label="1.0×" />
        <TabBtn icon="loop" label="循环" />
        <TabBtn icon="ab" label="AB" />
        <TabBtn icon="subtitle" label="字幕" onClick={onOpenSubSettings} />
        <TabBtn icon="mic" label="跟读" onClick={() => onOpenShadowing(currentSeg)} />
      </div>
    </div>
  );
}

// ----------------------------------------------------------------------------
// Video frame: thumbnail backdrop + animated "playing" overlay + floating subtitle
// ----------------------------------------------------------------------------

function VideoFrame({ video, currentSeg, currentTime, isPlaying, onTapWord, brand, ai, thumbStyle, aiSubtitleOn }) {
  return (
    <div style={{
      position: 'relative', width: '100%', aspectRatio: '16/9', borderRadius: 14,
      overflow: 'hidden', background: '#000',
      boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
    }}>
      <Thumbnail videoId={video.id} brand={brand} ai={ai} style={thumbStyle} src={video.thumb}/>

      {/* Light shimmer to suggest playback */}
      {isPlaying && (
        <div style={{
          position: 'absolute', inset: 0,
          background: 'linear-gradient(120deg, transparent 0%, rgba(255,255,255,0.03) 45%, rgba(255,255,255,0.08) 50%, rgba(255,255,255,0.03) 55%, transparent 100%)',
          backgroundSize: '200% 100%',
          animation: 'shimmer 3.5s linear infinite',
          mixBlendMode: 'screen',
        }} />
      )}

      {/* Dim if paused */}
      {!isPlaying && (
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.35)' }} />
      )}

      {/* expand button top-right */}
      <div style={{
        position: 'absolute', top: 8, right: 8,
        width: 32, height: 32, borderRadius: 8,
        background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(8px)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name="expand" size={14} color="#fff" />
      </div>

      {/* Center play button when paused */}
      {!isPlaying && (
        <div style={{
          position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)',
          width: 56, height: 56, borderRadius: '50%',
          background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          border: '1px solid var(--divider-strong)',
        }}>
          <div style={{ marginLeft: 3 }}>
            <Icon name="play" size={24} color="#fff" />
          </div>
        </div>
      )}

      {/* Floating subtitle */}
      {aiSubtitleOn && currentSeg && (
        <div style={{
          position: 'absolute', bottom: 14, left: 16, right: 16,
          textAlign: 'center', pointerEvents: 'auto',
        }}>
          <div style={{
            fontFamily: 'Inter, sans-serif', fontSize: 14, fontWeight: 500,
            lineHeight: 1.35, letterSpacing: 0.1,
            textShadow: '0 2px 12px rgba(0,0,0,0.95), 0 0 4px rgba(0,0,0,0.7)',
          }}>
            {currentSeg.words.map(([w, s, e], i) => {
              const state = currentTime > e ? 'read' : currentTime >= s ? 'active' : 'unread';
              const color = state === 'active' ? brand
                          : state === 'read' ? 'rgba(255,255,255,0.5)'
                          : '#fff';
              return (
                <span key={i}
                  onClick={(ev) => { ev.stopPropagation(); onTapWord({ w, s, e }, currentSeg); }}
                  style={{ color, marginRight: 4, cursor: 'pointer', transition: 'color 120ms' }}>
                  {w}
                </span>
              );
            })}
          </div>
          {currentSeg.tr && (
            <div style={{
              marginTop: 2, fontFamily: '"PingFang SC", sans-serif', fontSize: 11.5,
              color: '#fff', opacity: 0.85,
              textShadow: '0 2px 8px rgba(0,0,0,0.95)',
            }}>{currentSeg.tr}</div>
          )}
        </div>
      )}
    </div>
  );
}

// ----------------------------------------------------------------------------
// Subtitle list row
// ----------------------------------------------------------------------------

function SubtitleRow({ seg, isCurrent, currentTime, tweaks, onWordTap, onLongPress, onTap }) {
  const longPressTimer = React.useRef(null);
  const pressed = React.useRef(false);

  const handlePressStart = () => {
    pressed.current = true;
    longPressTimer.current = setTimeout(() => {
      if (pressed.current) onLongPress();
    }, 500);
  };
  const handlePressEnd = () => {
    pressed.current = false;
    if (longPressTimer.current) clearTimeout(longPressTimer.current);
  };

  const colorFor = (word) => {
    if (!isCurrent) return 'var(--text)';
    if (currentTime > word[2]) return 'var(--text-ter)';
    if (currentTime >= word[1]) return tweaks.brandText;
    return 'var(--text)';
  };

  const padding = tweaks.density === 'compact' ? '10px 0' : tweaks.density === 'comfy' ? '18px 0' : '14px 0';

  return (
    <div data-seg-id={seg.id}
      onMouseDown={handlePressStart} onMouseUp={handlePressEnd} onMouseLeave={handlePressEnd}
      onTouchStart={handlePressStart} onTouchEnd={handlePressEnd}
      style={{
        display: 'flex', gap: 12, padding: '0 16px',
        background: isCurrent
          ? `linear-gradient(90deg, ${tweaks.brandColor}10 0%, transparent 70%)`
          : 'transparent',
        position: 'relative',
        cursor: 'pointer',
      }}
    >
      {/* Left glow bar */}
      <div style={{
        width: 3, flexShrink: 0, alignSelf: 'stretch',
        margin: '6px 0', borderRadius: 2,
        background: isCurrent ? tweaks.brandColor : 'transparent',
        boxShadow: isCurrent ? `0 0 8px ${tweaks.brandColor}66` : 'none',
        transition: 'background 200ms',
      }} />
      <div style={{ flex: 1, padding }}>
        {/* meta line */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 5 }}>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 10, fontWeight: 600,
            color: isCurrent ? tweaks.brandText : 'var(--text-ter)',
          }}>{String(seg.id + 1).padStart(2, '0')}</span>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
            color: 'var(--text-ter)',
          }}>{formatTime(seg.s)}</span>
        </div>
        {/* english */}
        <div onClick={(e) => { e.stopPropagation(); onTap(); }}
          style={{ fontFamily: 'Inter, sans-serif', fontSize: tweaks.subSize, lineHeight: 1.4 }}>
          {seg.words.map(([w, s, e], i) => (
            <span key={i}
              onClick={(ev) => { ev.stopPropagation(); pressed.current = false; clearTimeout(longPressTimer.current); onWordTap({ w, s, e }); }}
              style={{
                color: colorFor([w, s, e]),
                fontWeight: isCurrent ? 500 : 400,
                marginRight: 4, cursor: 'pointer',
                transition: 'color 120ms',
              }}>{w}</span>
          ))}
        </div>
        {/* chinese */}
        {seg.tr && (
          <div style={{
            marginTop: 4,
            fontFamily: '"PingFang SC", sans-serif', fontSize: tweaks.subSize - 3,
            color: 'var(--text-sec)', lineHeight: 1.5,
          }}>{seg.tr}</div>
        )}
      </div>
    </div>
  );
}

// ----------------------------------------------------------------------------
// Progress, chips, buttons
// ----------------------------------------------------------------------------

function Progress({ current, total, brand, onSeek }) {
  const barRef = React.useRef(null);
  const pct = Math.min(100, (current / total) * 100);
  const [dragging, setDragging] = React.useState(false);

  const handleDown = (e) => {
    setDragging(true);
    handleMove(e);
  };
  const handleMove = (e) => {
    const rect = barRef.current.getBoundingClientRect();
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
    const p = Math.max(0, Math.min(1, x / rect.width));
    onSeek(p * total);
  };
  const handleUp = () => setDragging(false);

  React.useEffect(() => {
    if (!dragging) return;
    const move = (e) => handleMove(e);
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', handleUp);
    window.addEventListener('touchmove', move);
    window.addEventListener('touchend', handleUp);
    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', handleUp);
      window.removeEventListener('touchmove', move);
      window.removeEventListener('touchend', handleUp);
    };
  }, [dragging]);

  return (
    <div style={{ padding: '6px 0' }}>
      <div ref={barRef}
        onMouseDown={handleDown} onTouchStart={handleDown}
        style={{
          position: 'relative', height: 4, borderRadius: 2,
          background: 'var(--chip-bg-active)', cursor: 'pointer',
        }}
      >
        <div style={{
          position: 'absolute', top: 0, left: 0, height: '100%',
          width: `${pct}%`, borderRadius: 2,
          background: `linear-gradient(90deg, ${brand}, ${brand}cc)`,
          boxShadow: `0 0 8px ${brand}60`,
        }} />
        <div style={{
          position: 'absolute', top: '50%', left: `${pct}%`,
          width: dragging ? 16 : 11, height: dragging ? 16 : 11, borderRadius: '50%',
          background: '#fff', transform: 'translate(-50%, -50%)',
          boxShadow: dragging ? `0 0 0 6px ${brand}33, 0 2px 6px rgba(0,0,0,0.4)` : '0 2px 4px rgba(0,0,0,0.3)',
          transition: 'width 120ms, height 120ms, box-shadow 120ms',
        }} />
      </div>
      <div style={{
        marginTop: 6, display: 'flex', justifyContent: 'space-between',
        fontFamily: 'JetBrains Mono, monospace', fontSize: 11,
        color: 'var(--text-sec)',
      }}>
        <span>{formatTime(current)}</span>
        <span>{formatTime(total)}</span>
      </div>
    </div>
  );
}

function ChipBtn({ icon, label, active, iconColor, onClick, brand }) {
  return (
    <button onClick={onClick} style={{
      flexShrink: 0, display: 'flex', alignItems: 'center', gap: 6,
      padding: '8px 14px', borderRadius: 18,
      background: active ? `${brand}1f` : 'var(--chip-bg)',
      border: active ? `1px solid ${brand}44` : '1px solid var(--divider)',
      color: active ? brand : '#fff', cursor: 'pointer',
      fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 500,
    }}>
      <Icon name={icon} size={14} color={iconColor || (active ? brand : '#fff')} />
      {label}
    </button>
  );
}

function CtrlBtn({ icon, size = 32, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: size + 16, height: size + 16, borderRadius: '50%', border: 'none',
      background: 'transparent', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 0,
    }}>
      <Icon name={icon} size={size - 4} color="var(--text-sec)" />
    </button>
  );
}

function TabBtn({ icon, label, active, brand, onClick }) {
  return (
    <button onClick={onClick} style={{
      flex: 1, padding: '8px 4px 2px', background: 'transparent', border: 'none',
      cursor: 'pointer',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
    }}>
      <Icon name={icon} size={18} color={active ? brand : 'var(--text-sec)'} />
      <span style={{
        fontFamily: '"PingFang SC", sans-serif', fontSize: 10,
        color: active ? brand : 'var(--text-sec)',
      }}>{label}</span>
    </button>
  );
}

function formatTime(t) {
  const m = Math.floor(t / 60);
  const s = Math.floor(t % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

window.PlayerScreen = PlayerScreen;
window.formatTime = formatTime;
