// recent.jsx — 最近更新 (recently added) — mixed feed of videos + articles, time-sorted

window.HOME_RECENT = [
  { kind: 'video',   ref: 'julian',           addedAt: '今天 09:24',  isNew: true },
  { kind: 'article', ref: 'econ-ai-chips',    addedAt: '今天 08:10',  isNew: true },
  { kind: 'article', ref: 'nyt-loneliness',   addedAt: '昨天 22:05' },
  { kind: 'video',   ref: 'ted-ed-dream',     addedAt: '昨天 18:32' },
  { kind: 'article', ref: 'guardian-climate', addedAt: '昨天 11:20' },
  { kind: 'video',   ref: 'tim-urban',        addedAt: '2 天前 16:08' },
  { kind: 'article', ref: 'atlantic-attention', addedAt: '3 天前 20:14' },
  { kind: 'article', ref: 'bbc-japan',        addedAt: '4 天前 09:50' },
];

function RecentFeed({ tweaks, onOpenVideo }) {
  const videosById = Object.fromEntries(window.HOME_VIDEOS.map(v => [v.id, v]));
  const articlesById = Object.fromEntries(window.HOME_ARTICLES.map(a => [a.id, a]));

  // Group by date label (extract first segment before space)
  const groups = {};
  for (const item of window.HOME_RECENT) {
    const dateLabel = item.addedAt.split(' ')[0];
    if (!groups[dateLabel]) groups[dateLabel] = [];
    groups[dateLabel].push(item);
  }

  return (
    <>
      {/* Header strip — # of new items */}
      <div style={{
        margin: '0 14px 14px', padding: '12px 14px',
        borderRadius: 12,
        background: `linear-gradient(135deg, ${tweaks.brandColor}14 0%, ${tweaks.aiColor}10 100%)`,
        border: `0.5px solid ${tweaks.brandColor}33`,
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: 8, height: 8, borderRadius: 4,
          background: tweaks.brandColor,
          boxShadow: `0 0 8px ${tweaks.brandColor}`,
          animation: 'pulse 1.6s ease-in-out infinite',
          flexShrink: 0,
        }}/>
        <div style={{ flex: 1 }}>
          <div style={{
            fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 600,
            color: 'var(--text)',
          }}>本周新增 <span style={{ color: tweaks.brandText }}>{window.HOME_RECENT.length}</span> 条</div>
          <div style={{
            marginTop: 2,
            fontFamily: '"PingFang SC", sans-serif', fontSize: 11,
            color: 'var(--text-sec)',
          }}>视频与外刊持续更新，AI 已完成加工</div>
        </div>
        <button style={{
          padding: '6px 10px', borderRadius: 8, border: 'none',
          background: 'var(--chip-bg-active)', cursor: 'pointer',
          fontFamily: '"PingFang SC", sans-serif', fontSize: 11.5, fontWeight: 500,
          color: 'var(--text)',
        }}>全部已读</button>
      </div>

      {Object.entries(groups).map(([dateLabel, items]) => (
        <div key={dateLabel}>
          {/* Date divider */}
          <div style={{
            padding: '12px 22px 8px',
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{
              fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 600,
              color: 'var(--text)',
            }}>{dateLabel}</div>
            <div style={{ flex: 1, height: 0.5, background: 'var(--chip-bg-active)' }}/>
            <div style={{
              fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
              color: 'var(--text-ter)', letterSpacing: 0.5,
            }}>{items.length} ITEM{items.length === 1 ? '' : 'S'}</div>
          </div>

          {/* Item rows */}
          <div style={{ padding: '0 14px 4px', display: 'flex', flexDirection: 'column', gap: 0 }}>
            {items.map((item, i) => {
              if (item.kind === 'video') {
                const v = videosById[item.ref];
                if (!v) return null;
                return (
                  <RecentVideoRow key={item.ref + i} video={v} item={item} tweaks={tweaks}
                    onClick={() => onOpenVideo(v)}/>
                );
              } else {
                const a = articlesById[item.ref];
                if (!a) return null;
                return <RecentArticleRow key={item.ref + i} article={a} item={item} tweaks={tweaks}/>;
              }
            })}
          </div>
        </div>
      ))}

      <div style={{ height: 60 }}/>
    </>
  );
}

function TypeBadge({ kind, brand, ai }) {
  const color = kind === 'video' ? brand : ai;
  const label = kind === 'video' ? '视频' : '外刊';
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 3,
      padding: '2px 6px 2px 5px', borderRadius: 4,
      background: `${color}22`,
      fontFamily: 'JetBrains Mono, monospace', fontSize: 9, fontWeight: 700,
      color, letterSpacing: 0.5,
    }}>{label}</span>
  );
}

function NewDot() {
  return (
    <span style={{
      display: 'inline-block', width: 5, height: 5, borderRadius: '50%',
      background: '#FF6E6E', marginRight: 4, verticalAlign: 'middle',
    }}/>
  );
}

function RecentVideoRow({ video, item, tweaks, onClick }) {
  return (
    <div onClick={onClick} style={{
      display: 'flex', gap: 12, padding: '12px 8px',
      cursor: 'pointer',
      borderBottom: '0.5px solid var(--divider)',
    }}>
      <div style={{
        width: 96, height: 64, borderRadius: 8, flexShrink: 0,
        overflow: 'hidden', background: 'var(--bg)',
        border: 'var(--card-border)',
        position: 'relative',
      }}>
        <Thumbnail videoId={video.id} brand={tweaks.brandColor} ai={tweaks.aiColor}
          style={tweaks.thumbStyle} src={video.thumb}/>
        {/* Duration pill */}
        <div style={{
          position: 'absolute', right: 4, bottom: 4,
          padding: '1px 5px', borderRadius: 4,
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          fontFamily: 'JetBrains Mono, monospace', fontSize: 8.5, fontWeight: 600,
          color: '#fff', letterSpacing: 0.3,
        }}>{video.duration}</div>
      </div>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
          {item.isNew && <NewDot/>}
          <TypeBadge kind="video" brand={tweaks.brandColor} ai={tweaks.aiColor}/>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
            color: 'var(--text-ter)', letterSpacing: 0.3,
          }}>{video.source} · {video.speaker.split(' ')[0].toUpperCase()}</span>
        </div>
        <div style={{
          fontFamily: 'Inter, sans-serif', fontWeight: 500, fontSize: 13.5,
          color: 'var(--text)', lineHeight: 1.3, letterSpacing: -0.1,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{video.title}</div>
        <div style={{
          marginTop: 5,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.4,
        }}>
          <span style={{ color: tweaks.aiText }}>{video.level}</span>
          <span> · </span>
          <span>{item.addedAt}</span>
        </div>
      </div>
    </div>
  );
}

function RecentArticleRow({ article, item, tweaks }) {
  return (
    <div style={{
      display: 'flex', gap: 12, padding: '12px 8px',
      cursor: 'pointer',
      borderBottom: '0.5px solid var(--divider)',
    }}>
      {/* Mini cover */}
      <div style={{
        width: 96, height: 64, borderRadius: 8, flexShrink: 0,
        background: article.accent,
        position: 'relative', overflow: 'hidden',
        border: 'var(--card-border)',
      }}>
        <div style={{
          position: 'absolute', inset: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontStyle: 'italic',
          fontSize: 20, color: article.pubColor,
          textShadow: '0 1px 4px rgba(0,0,0,0.4)',
          letterSpacing: -0.5,
        }}>{article.pubAbbr}</div>
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0, height: 12,
          background: 'rgba(0,0,0,0.5)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'JetBrains Mono, monospace', fontSize: 7.5, letterSpacing: 0.5,
          color: 'var(--text-sec)', fontWeight: 700,
        }}>{article.section}</div>
      </div>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
          {item.isNew && <NewDot/>}
          <TypeBadge kind="article" brand={tweaks.brandColor} ai={tweaks.aiColor}/>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
            color: 'var(--text-ter)', letterSpacing: 0.3,
          }}>{article.publication.toUpperCase()}</span>
        </div>
        <div style={{
          fontFamily: 'Fraunces, serif', fontSize: 14.5, fontWeight: 500,
          color: 'var(--text)', lineHeight: 1.3, letterSpacing: -0.2,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{article.title}</div>
        <div style={{
          marginTop: 5,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.4,
        }}>
          <span style={{ color: tweaks.aiText }}>{article.level}</span>
          <span> · </span>
          <span>{article.minutes} min</span>
          <span> · </span>
          <span>{item.addedAt}</span>
        </div>
      </div>
    </div>
  );
}

window.RecentFeed = RecentFeed;
