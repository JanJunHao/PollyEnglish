// favorites.jsx — 收藏的句子

window.FAVORITES_LIST = [
  { segId: 2, video: 'julian', addedAt: '今天' },
  { segId: 6, video: 'julian', addedAt: '今天' },
  { segId: 9, video: 'julian', addedAt: '昨天' },
  { segId: 13, video: 'julian', addedAt: '昨天' },
  { segId: 14, video: 'julian', addedAt: '2 天前' },
  { segId: 0, video: 'julian', addedAt: '3 天前' },
];

function FavoritesScreen({ tweaks, onBack, onOpenSentence }) {
  const segById = Object.fromEntries(window.SUBTITLES.map(s => [s.id, s]));
  const videosById = Object.fromEntries(window.HOME_VIDEOS.map(v => [v.id, v]));

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--bg)', color: 'var(--text)',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Top nav */}
      <div style={{
        flexShrink: 0, padding: '56px 16px 4px 12px',
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
        }}>收藏的句子</div>
      </div>

      {/* Heading + meta */}
      <div style={{ padding: '12px 22px 18px', flexShrink: 0 }}>
        <div style={{
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 30,
          color: 'var(--text)', letterSpacing: -1, lineHeight: 1.05,
        }}>Saved sentences</div>
        <div style={{
          marginTop: 4,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10.5,
          color: 'var(--text-sec)', letterSpacing: 0.4,
        }}>
          <span style={{color: tweaks.brandText, fontWeight: 700}}>{window.FAVORITES_LIST.length}</span> SENTENCES · ALL SOURCES
        </div>
      </div>

      {/* List */}
      <div style={{
        flex: 1, overflow: 'auto', WebkitOverflowScrolling: 'touch',
        padding: '0 14px 100px',
        display: 'flex', flexDirection: 'column', gap: 10,
      }}>
        {window.FAVORITES_LIST.map((fav, i) => {
          const seg = segById[fav.segId];
          const video = videosById[fav.video];
          if (!seg || !video) return null;
          return (
            <FavoriteCard key={fav.segId + '-' + i} seg={seg} video={video} addedAt={fav.addedAt}
              tweaks={tweaks} onClick={() => onOpenSentence(video, seg)}/>
          );
        })}
      </div>
    </div>
  );
}

function FavoriteCard({ seg, video, addedAt, tweaks, onClick }) {
  return (
    <div onClick={onClick} style={{
      padding: '14px 16px 14px', borderRadius: 14,
      background: 'var(--surface)',
      border: 'var(--card-border)',
      cursor: 'pointer',
      position: 'relative',
    }}>
      {/* Star + meta */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8, marginBottom: 9,
      }}>
        <Icon name="star-filled" size={12} color={tweaks.brandColor}/>
        <span style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.5, fontWeight: 600,
        }}>
          {video.speaker.toUpperCase()} · {formatTime(seg.s)}
        </span>
        <div style={{ flex: 1 }}/>
        <span style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.3,
        }}>{addedAt}</span>
      </div>

      {/* Sentence — English */}
      <div style={{
        fontFamily: 'Inter, sans-serif', fontWeight: 500, fontSize: 14.5,
        color: 'var(--text)', lineHeight: 1.4, letterSpacing: -0.1,
      }}>{seg.text}.</div>

      {/* Translation */}
      {seg.tr && (
        <div style={{
          marginTop: 4,
          fontFamily: '"PingFang SC", sans-serif', fontSize: 12,
          color: 'var(--text-ter)', lineHeight: 1.45,
        }}>{seg.tr}</div>
      )}
    </div>
  );
}

window.FavoritesScreen = FavoritesScreen;
