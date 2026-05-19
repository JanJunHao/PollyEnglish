// library.jsx — 精选课程完整列表页（"查看更多"目标页）
// Top nav + filter chips + vertical list of all videos (using BannerCard style)

function LibraryScreen({ tweaks, onBack, onOpenVideo }) {
  const [filter, setFilter] = React.useState('all');
  const videos = window.HOME_VIDEOS;
  const filtered = videos.filter(v => {
    if (filter === 'all') return true;
    if (filter === 'ted') return v.source === 'TED' || v.source === 'TED-Ed';
    if (filter === 'b1') return v.level === 'B1';
    if (filter === 'b2') return v.level === 'B2';
    return true;
  });

  const filters = [
    { id: 'all', label: '全部', count: videos.length },
    { id: 'ted', label: 'TED', count: videos.filter(v => v.source.startsWith('TED')).length },
    { id: 'b1', label: 'B1 中级', count: videos.filter(v => v.level === 'B1').length },
    { id: 'b2', label: 'B2 中高', count: videos.filter(v => v.level === 'B2').length },
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--bg)', color: 'var(--text)',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Top nav */}
      <div style={{
        flexShrink: 0, padding: '56px 16px 8px 12px',
        display: 'flex', alignItems: 'center', gap: 4,
      }}>
        <button onClick={onBack} style={{
          width: 36, height: 36, borderRadius: 18, background: 'var(--chip-bg)',
          border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', flexShrink: 0, padding: 0,
        }}>
          <Icon name="chevron-left" size={20} color="#fff" />
        </button>
        <div style={{
          flex: 1,
          fontFamily: '"PingFang SC", sans-serif', fontSize: 17, fontWeight: 600,
          color: 'var(--text)', textAlign: 'center', paddingRight: 36,
          letterSpacing: -0.1,
        }}>精选课程</div>
      </div>

      {/* Large title + meta */}
      <div style={{ padding: '14px 22px 16px', flexShrink: 0 }}>
        <div style={{
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 32,
          color: 'var(--text)', letterSpacing: -1, lineHeight: 1.05,
        }}>Course Library</div>
        <div style={{
          marginTop: 4,
          fontFamily: '"PingFang SC", sans-serif', fontSize: 13,
          color: 'var(--text-sec)',
        }}>{filtered.length} 个视频 · 持续更新</div>
      </div>

      {/* Filter chips */}
      <div style={{
        padding: '0 14px 14px', flexShrink: 0,
        display: 'flex', gap: 8, overflowX: 'auto', overflowY: 'hidden',
        scrollbarWidth: 'none',
      }}>
        {filters.map((f) => (
          <button key={f.id} onClick={() => setFilter(f.id)} style={{
            flexShrink: 0, display: 'flex', alignItems: 'center', gap: 6,
            padding: '8px 14px', borderRadius: 18, cursor: 'pointer',
            background: filter === f.id ? `${tweaks.brandColor}1f` : 'var(--surface)',
            border: filter === f.id ? `1px solid ${tweaks.brandColor}44` : '1px solid transparent',
            color: filter === f.id ? tweaks.brandText : 'var(--text)',
            fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 500,
            transition: 'all 180ms',
          }}>
            {f.label}
            <span style={{
              fontFamily: 'JetBrains Mono, monospace', fontSize: 10, fontWeight: 600,
              color: filter === f.id ? tweaks.brandText : 'var(--text-ter)',
            }}>{f.count}</span>
          </button>
        ))}
      </div>

      {/* Video list — vertical stack */}
      <div style={{
        flex: 1, overflow: 'auto', WebkitOverflowScrolling: 'touch',
        padding: '4px 14px 96px',
        display: 'flex', flexDirection: 'column', gap: 14,
      }}>
        {filtered.map((v) => (
          <LibraryItem key={v.id} video={v} tweaks={tweaks}
            onOpen={() => onOpenVideo(v)} />
        ))}
        {filtered.length === 0 && (
          <div style={{
            padding: '50px 20px', textAlign: 'center',
            fontFamily: '"PingFang SC", sans-serif', fontSize: 13,
            color: 'var(--text-ter)',
          }}>暂无符合条件的视频</div>
        )}
      </div>
    </div>
  );
}

function LibraryItem({ video, tweaks, onOpen }) {
  return (
    <div onClick={onOpen} style={{
      position: 'relative', height: 200, borderRadius: 16, overflow: 'hidden',
      background: 'var(--bg)', cursor: 'pointer',
      border: 'var(--card-border)',
    }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        <Thumbnail videoId={video.id} brand={tweaks.brandColor} ai={tweaks.aiColor}
          style={tweaks.thumbStyle} src={video.thumb}/>
      </div>
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, height: '60%',
        background: 'linear-gradient(to bottom, transparent 0%, rgba(0,0,0,0.55) 55%, rgba(0,0,0,0.92) 100%)',
      }}/>
      <div style={{ position: 'absolute', left: 14, right: 70, bottom: 12 }}>
        <div style={{
          fontFamily: 'Inter, sans-serif', fontWeight: 600, fontSize: 15,
          color: '#fff', lineHeight: 1.28, letterSpacing: -0.2,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{video.title}</div>
        <div style={{
          marginTop: 5,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
          color: 'var(--text-sec)', letterSpacing: 0.5,
        }}>
          {video.speaker.toUpperCase()} · {video.duration} · {video.level}
        </div>
      </div>
      <div style={{
        position: 'absolute', right: 12, bottom: 12,
        width: 46, height: 46, borderRadius: '50%',
        background: tweaks.brandColor,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 4px 16px ${tweaks.brandColor}55`,
      }}>
        <div style={{ marginLeft: 3 }}><Icon name="play" size={18} color="#0a0a0c" /></div>
      </div>
    </div>
  );
}

window.LibraryScreen = LibraryScreen;
