// home.jsx — PollyEnglish home screen (editorial direction)
// Greeting + Today's primer + Today Banner (custom Polly art) + Featured row + My Learning

function HomeScreen({ tweaks, onOpenVideo, onOpenLibrary }) {
  const [bannerIdx, setBannerIdx] = React.useState(0);
  const [dragX, setDragX] = React.useState(0);
  const [dragStart, setDragStart] = React.useState(null);
  const [category, setCategory] = React.useState('recommend');
  const videos = window.HOME_VIDEOS;

  React.useEffect(() => {
    if (dragStart !== null) return;
    const t = setTimeout(() => setBannerIdx((i) => (i + 1) % videos.length), 5200);
    return () => clearTimeout(t);
  }, [bannerIdx, dragStart, videos.length]);

  const onDragStart = (e) => {
    const x = e.touches ? e.touches[0].clientX : e.clientX;
    setDragStart(x);
  };
  const onDragMove = (e) => {
    if (dragStart === null) return;
    const x = e.touches ? e.touches[0].clientX : e.clientX;
    setDragX(x - dragStart);
  };
  const onDragEnd = () => {
    if (Math.abs(dragX) > 60) {
      setBannerIdx((i) => (i + (dragX < 0 ? 1 : -1) + videos.length) % videos.length);
    }
    setDragStart(null);
    setDragX(0);
  };

  const today = new Date();

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--bg)', color: 'var(--text)',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Fixed top: status bar spacer + category tabs */}
      <div style={{
        flexShrink: 0, paddingTop: 56,
        background: tweaks.bgColor,
        position: 'relative', zIndex: 5,
      }}>
        <CategoryTabs active={category} onChange={setCategory} brand={tweaks.brandColor}/>
      </div>

      {/* Scrollable content area */}
      <div style={{
        flex: 1, overflow: 'auto', WebkitOverflowScrolling: 'touch',
      }}>
        <div style={{ height: 12 }} />

      {/* Content swaps based on category */}
      {category === 'foreign' ? (
        <ArticleFeed tweaks={tweaks}/>
      ) : category === 'recent' ? (
        <RecentFeed tweaks={tweaks} onOpenVideo={onOpenVideo}/>
      ) : (
        <>
      <div style={{
        position: 'relative', height: 234, overflow: 'visible',
      }}
        onMouseDown={onDragStart} onMouseMove={onDragMove} onMouseUp={onDragEnd} onMouseLeave={onDragEnd}
        onTouchStart={onDragStart} onTouchMove={onDragMove} onTouchEnd={onDragEnd}
      >
        <div style={{
          display: 'flex', height: 234, gap: 10, paddingLeft: 0,
          transform: `translateX(calc(3% - ${bannerIdx * 94}% - ${bannerIdx * 10}px + ${dragX}px))`,
          transition: dragStart === null ? 'transform 580ms cubic-bezier(.22,1,.36,1)' : 'none',
        }}>
          {videos.map((v, i) => (
            <div key={v.id} style={{ flex: '0 0 94%', height: 234, opacity: i === bannerIdx ? 1 : 0.55, transition: 'opacity 400ms' }}>
              <BannerCard video={v} brand={tweaks.brandColor} ai={tweaks.aiColor}
                thumbStyle={tweaks.thumbStyle}
                index={i} total={videos.length}
                onOpen={() => onOpenVideo(v)} />
            </div>
          ))}
        </div>
      </div>

      {/* Section: TRENDING */}
      <SectionDivider label="热门推荐" action="查看更多" onAction={onOpenLibrary} brand={tweaks.brandColor}/>

      <div style={{ padding: '0 14px 4px', display: 'flex', flexDirection: 'column', gap: 4 }}>
        {videos.map((v, i) => (
          <TrendingRow key={v.id} video={v} rank={i + 1} stats={window.HOME_TRENDING_STATS[v.id]}
            tweaks={tweaks} onOpen={() => onOpenVideo(v)}/>
        ))}
      </div>

      {/* Section: FEATURED */}
      <SectionDivider label="热门精选" action="查看更多" onAction={onOpenLibrary} brand={tweaks.brandColor}/>

      <div style={{
        display: 'flex', gap: 12, padding: '0 14px 10px',
        overflowX: 'auto', overflowY: 'hidden', scrollbarWidth: 'none',
      }}>
        {videos.map((v) => (
          <CourseCard key={v.id} video={v} brand={tweaks.brandColor} ai={tweaks.aiColor}
            thumbStyle={tweaks.thumbStyle}
            onOpen={() => onOpenVideo(v)} />
        ))}
        <div style={{ minWidth: 6, height: 1 }}/>
      </div>

      {/* Section: DAILY LISTENING */}
      <SectionDivider label="每日收听" brand={tweaks.brandColor}/>

      <div style={{ padding: '0 14px 10px' }}>
        <DailyListeningCard video={videos[0]} tweaks={tweaks} onOpen={() => onOpenVideo(videos[0])}/>
      </div>

      {/* Section: NEW ADDITIONS */}
      <SectionDivider label="最新上架" action="查看更多" onAction={onOpenLibrary} brand={tweaks.brandColor}/>

      <div style={{
        display: 'flex', gap: 12, padding: '0 14px 10px',
        overflowX: 'auto', overflowY: 'hidden', scrollbarWidth: 'none',
      }}>
        {videos.map((v, i) => (
          <NewArrivalCard key={v.id} video={v} brand={tweaks.brandColor} ai={tweaks.aiColor}
            thumbStyle={tweaks.thumbStyle}
            badge={i === 0 ? 'NEW' : null}
            addedAt={['今天', '昨天', '3 天前'][i]}
            onOpen={() => onOpenVideo(v)} />
        ))}
        <div style={{ minWidth: 6, height: 1 }}/>
      </div>

      {/* Section: TOPICS */}
      <SectionDivider label="主题探索" brand={tweaks.brandColor}/>

      <div style={{
        display: 'flex', gap: 8, padding: '0 14px 6px',
        overflowX: 'auto', overflowY: 'hidden', scrollbarWidth: 'none',
      }}>
        {window.HOME_TOPICS.map((topic) => (
          <TopicPill key={topic.id} topic={topic} brand={tweaks.brandColor}/>
        ))}
        <div style={{ minWidth: 6, height: 1 }}/>
      </div>

      <div style={{ height: 100 }}/>
        </>
      )}

      {category === 'foreign' && <div style={{ height: 100 }}/>}
      {category === 'recent' && <div style={{ height: 100 }}/>}
      </div>
    </div>
  );
}

// Receive new prop
HomeScreen.defaultProps = {};

// =============================================================================
// Category tab strip
// =============================================================================

function CategoryTabs({ active, onChange, brand }) {
  const tabs = [
    { id: 'recommend', label: '推荐' },
    { id: 'foreign',   label: '外刊' },
    { id: 'recent',    label: '最近更新' },
  ];
  return (
    <div style={{
      padding: '8px 16px 0',
      display: 'flex', alignItems: 'flex-end', gap: 22,
      borderBottom: '0.5px solid var(--divider)',
    }}>
      {tabs.map((tab) => {
        const isActive = active === tab.id;
        return (
          <button key={tab.id} onClick={() => onChange(tab.id)} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            padding: '8px 0 10px', position: 'relative',
            fontFamily: '"PingFang SC", sans-serif',
            fontSize: isActive ? 17 : 14,
            fontWeight: isActive ? 700 : 500,
            color: isActive ? 'var(--text)' : 'var(--text-ter)',
            letterSpacing: -0.2,
            transition: 'font-size 200ms cubic-bezier(.22,1,.36,1), color 200ms',
          }}>
            {tab.label}
            {isActive && (
              <div style={{
                position: 'absolute', bottom: 4, left: '50%', transform: 'translateX(-50%)',
                width: 18, height: 3, borderRadius: 2,
                background: brand,
              }}/>
            )}
          </button>
        );
      })}
    </div>
  );
}

// =============================================================================
// Daily Listening hero card
// =============================================================================

function DailyListeningCard({ video, tweaks, onOpen }) {
  return (
    <div onClick={onOpen} style={{
      position: 'relative', borderRadius: 16, overflow: 'hidden',
      background: `linear-gradient(135deg, #161620 0%, #0a0a0c 100%)`,
      border: 'var(--card-border)',
      padding: '16px 16px 14px',
      display: 'flex', alignItems: 'center', gap: 14,
      cursor: 'pointer',
      boxShadow: '0 8px 24px rgba(0,0,0,0.35)',
    }}>
      {/* Decorative waveform bars on the right */}
      <svg viewBox="0 0 120 80" preserveAspectRatio="none"
        style={{
          position: 'absolute', right: 0, top: 0, bottom: 0,
          width: 130, height: '100%', opacity: 0.18,
          pointerEvents: 'none',
        }}>
        {[20,55,35,80,45,70,30,90,50,40,75,25,60,42,85,30,50,38,72,28].map((h, i) => (
          <rect key={i} x={i * 6} y={40 - h / 2} width="3" height={h}
            rx="1.5" fill={tweaks.brandColor}/>
        ))}
      </svg>

      {/* Date/play button on the left */}
      <div style={{
        width: 56, height: 56, borderRadius: '50%',
        background: tweaks.brandColor,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0, position: 'relative',
        boxShadow: `0 4px 16px ${tweaks.brandColor}66`,
      }}>
        <div style={{ marginLeft: 3 }}>
          <Icon name="play" size={22} color="#0a0a0c"/>
        </div>
      </div>

      <div style={{ flex: 1, minWidth: 0, position: 'relative' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4,
        }}>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5, letterSpacing: 1,
            color: tweaks.brandText, fontWeight: 700,
          }}>DAY 7</span>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
            color: 'var(--text-ter)', letterSpacing: 0.4,
          }}>· 以商业英语为主</span>
        </div>
        <div style={{
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 18,
          color: '#fff', letterSpacing: -0.3, lineHeight: 1.2,
          fontStyle: 'italic',
        }}>Today's pick</div>
        <div style={{
          marginTop: 4,
          fontFamily: 'Inter, sans-serif', fontWeight: 500, fontSize: 13,
          color: '#fff', lineHeight: 1.3, letterSpacing: -0.1,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{video.title}</div>
        <div style={{
          marginTop: 6,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
          color: 'var(--text-sec)', letterSpacing: 0.4,
        }}>
          {video.duration} · {video.level}
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// New arrival card
// =============================================================================

function NewArrivalCard({ video, brand, ai, thumbStyle, badge, addedAt, onOpen }) {
  return (
    <div onClick={onOpen} style={{
      minWidth: 170, width: 170, height: 230, borderRadius: 14,
      overflow: 'hidden', background: '#0c0c10', cursor: 'pointer',
      border: 'var(--card-border)',
      flexShrink: 0, position: 'relative',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ position: 'relative', width: 170, height: 96, overflow: 'hidden' }}>
        <Thumbnail videoId={video.id} brand={brand} ai={ai}
          style={thumbStyle} src={video.thumb}/>
        {badge && (
          <div style={{
            position: 'absolute', top: 8, left: 8,
            padding: '3px 7px', borderRadius: 4,
            background: '#FF6E6E',
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9, fontWeight: 700,
            color: '#fff', letterSpacing: 0.5,
          }}>{badge}</div>
        )}
      </div>
      <div style={{ padding: '11px 12px 12px', flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5, letterSpacing: 0.6,
          color: 'var(--text-ter)', fontWeight: 700,
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <span style={{
            width: 5, height: 5, borderRadius: '50%',
            background: brand,
          }}/>
          上架于 {addedAt}
        </div>
        <div style={{
          marginTop: 4,
          fontFamily: 'Inter, sans-serif', fontWeight: 500, fontSize: 13,
          color: 'var(--text)', lineHeight: 1.32,
          display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden',
          flex: 1,
        }}>{video.title}</div>
        <div style={{
          marginTop: 8,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.5,
        }}>
          {video.duration} · {video.level}
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// Topic pill
// =============================================================================

function TopicPill({ topic, brand }) {
  return (
    <button style={{
      flexShrink: 0, display: 'flex', alignItems: 'center', gap: 8,
      padding: '12px 14px 12px 12px', borderRadius: 14,
      background: `${topic.color}14`,
      border: `0.5px solid ${topic.color}33`,
      cursor: 'pointer',
    }}>
      <div style={{
        width: 30, height: 30, borderRadius: 9,
        background: `${topic.color}33`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 16,
      }}>
        {topic.glyph}
      </div>
      <div style={{ textAlign: 'left' }}>
        <div style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 600,
          color: 'var(--text)', lineHeight: 1.1,
        }}>{topic.name}</div>
        <div style={{
          marginTop: 2,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.3,
        }}>{topic.count} videos</div>
      </div>
    </button>
  );
}

// =============================================================================
// Trending row
// =============================================================================

function TrendingRow({ video, rank, stats, tweaks, onOpen }) {
  return (
    <div onClick={onOpen} style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: '10px 6px', cursor: 'pointer',
      borderBottom: rank < 3 ? '0.5px solid var(--divider)' : 'none',
    }}>
      <div style={{
        width: 36, flexShrink: 0, textAlign: 'center',
        fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 30,
        fontStyle: 'italic', letterSpacing: -1,
        color: rank === 1 ? tweaks.brandText : 'var(--text-sec)',
        lineHeight: 1,
      }}>{String(rank).padStart(2, '0')}</div>

      <div style={{
        width: 72, height: 72, borderRadius: 10, overflow: 'hidden', flexShrink: 0,
        background: 'var(--bg)',
        border: 'var(--card-border)',
      }}>
        <Thumbnail videoId={video.id} brand={tweaks.brandColor} ai={tweaks.aiColor}
          style={tweaks.thumbStyle} src={video.thumb}/>
      </div>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: 'Inter, sans-serif', fontWeight: 500, fontSize: 13.5,
          color: 'var(--text)', lineHeight: 1.3, letterSpacing: -0.1,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{video.title}</div>
        <div style={{
          marginTop: 5, display: 'flex', alignItems: 'center', gap: 8,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
          color: 'var(--text-ter)', letterSpacing: 0.4,
        }}>
          <span>{stats.views}</span>
          <span>·</span>
          <span style={{ color: '#FF9F6E' }}>↑ {stats.growth}</span>
        </div>
      </div>
    </div>
  );
}

window.HOME_TOPICS = [
  { id: 'comm',  name: '表达与演讲', count: 24, color: '#FFE066', glyph: '🎤' },
  { id: 'psy',   name: '心理与思维', count: 18, color: '#B8C4FF', glyph: '🧠' },
  { id: 'sci',   name: '科技与未来', count: 31, color: '#7FD4FF', glyph: '⚛︎' },
  { id: 'biz',   name: '商业与职场', count: 22, color: '#FF9F6E', glyph: '📊' },
  { id: 'life',  name: '生活与日常', count: 16, color: '#A6E8C3', glyph: '☕' },
  { id: 'art',   name: '艺术与设计', count: 11, color: '#F0A0FF', glyph: '🎨' },
  { id: 'news',  name: '新闻与评论', count: 28, color: '#FFB8B8', glyph: '📰' },
];

window.HOME_TRENDING_STATS = {
  'julian':       { views: '12.4K 人在学', growth: '32%' },
  'ted-ed-dream': { views: '8.7K 人在学',  growth: '18%' },
  'tim-urban':    { views: '5.2K 人在学',  growth: '12%' },
};

// =============================================================================
// Section divider — editorial "chapter" label
// =============================================================================

function SectionDivider({ label, action, onAction, brand }) {
  return (
    <div style={{
      padding: '22px 22px 12px',
      display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
    }}>
      <div style={{
        fontFamily: '"PingFang SC", sans-serif', fontSize: 20, fontWeight: 600,
        color: 'var(--text)', letterSpacing: -0.2,
      }}>{label}</div>
      {action && (
        <button onClick={onAction} style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          padding: '4px 0', display: 'flex', alignItems: 'center', gap: 2,
          fontFamily: '"PingFang SC", sans-serif', fontSize: 12.5,
          color: 'var(--text-sec)',
        }}>
          {action}
          <Icon name="chevron-right" size={13} color="var(--text-sec)" />
        </button>
      )}
    </div>
  );
}

// =============================================================================
// BannerCard — full-art with bottom meta strip (editorial direction)
// =============================================================================

function BannerCard({ video, brand, ai, thumbStyle, index, total, onOpen }) {
  return (
    <div
      data-banner-card={video.id}
      onClick={onOpen}
      style={{
        position: 'relative', height: 234, borderRadius: 18, overflow: 'hidden',
        background: 'var(--bg)', cursor: 'pointer',
        boxShadow: 'var(--shadow-card)',
        border: 'var(--card-border)',
      }}
    >
      {/* Cover art fills the whole card */}
      <div style={{ position: 'absolute', inset: 0 }}>
        <Thumbnail videoId={video.id} brand={brand} ai={ai}
          style={thumbStyle} src={video.thumb}/>
      </div>

      {/* Bottom gradient mask for legibility */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, height: '60%',
        background: 'linear-gradient(to bottom, transparent 0%, rgba(0,0,0,0.55) 55%, rgba(0,0,0,0.92) 100%)',
        pointerEvents: 'none',
      }}/>

      {/* Title + meta overlay (bottom-left), play button (bottom-right) */}
      <div style={{
        position: 'absolute', left: 16, right: 76, bottom: 14,
      }}>
        <div style={{
          fontFamily: 'Inter, sans-serif', fontWeight: 600, fontSize: 16,
          color: '#fff', lineHeight: 1.28, letterSpacing: -0.2,
          textShadow: '0 2px 8px rgba(0,0,0,0.5)',
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{video.title}</div>
        <div style={{
          marginTop: 6,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10.5,
          color: 'var(--text-sec)', letterSpacing: 0.6,
        }}>
          {video.speaker.toUpperCase()} · {video.duration} · {video.level}
        </div>
        {/* Page indicator: small dots BELOW the meta line */}
        {typeof index === 'number' && typeof total === 'number' && (
          <div style={{
            marginTop: 8,
            display: 'flex', gap: 4,
          }}>
            {Array.from({ length: total }).map((_, i) => (
              <div key={i} style={{
                width: i === index ? 14 : 4, height: 4, borderRadius: 2,
                background: i === index ? 'var(--text)' : 'var(--text-ter)',
                transition: 'all 300ms cubic-bezier(.22,1,.36,1)',
              }}/>
            ))}
          </div>
        )}
      </div>

      {/* Floating play button */}
      <div style={{
        position: 'absolute', right: 14, bottom: 14,
        width: 52, height: 52, borderRadius: '50%',
        background: brand,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 6px 22px ${brand}66, 0 2px 8px rgba(0,0,0,0.35)`,
      }}>
        <div style={{ marginLeft: 3 }}>
          <Icon name="play" size={20} color="#0a0a0c" />
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// CourseCard — small editorial card with custom art
// =============================================================================

function CourseCard({ video, brand, ai, thumbStyle, onOpen }) {
  return (
    <div onClick={onOpen} style={{
      minWidth: 170, width: 170, height: 230, borderRadius: 14,
      overflow: 'hidden', background: '#0c0c10', cursor: 'pointer',
      border: 'var(--card-border)',
      flexShrink: 0,
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ position: 'relative', width: 170, height: 96, overflow: 'hidden' }}>
        <Thumbnail videoId={video.id} brand={brand} ai={ai}
          style={thumbStyle} src={video.thumb}/>
      </div>
      <div style={{ padding: '11px 12px 12px', flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{
          fontFamily: 'Fraunces, serif', fontWeight: 400, fontStyle: 'italic',
          fontSize: 9.5, letterSpacing: 1.5,
          color: video.dotColor || brand,
          textTransform: 'uppercase',
        }}>{video.source}</div>
        <div style={{
          marginTop: 4,
          fontFamily: 'Inter, sans-serif', fontWeight: 500, fontSize: 13,
          color: 'var(--text)', lineHeight: 1.32,
          display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden',
          flex: 1,
        }}>{video.title}</div>
        <div style={{
          marginTop: 8,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.5,
        }}>
          {video.duration} · {video.level}
        </div>
      </div>
    </div>
  );
}

window.HOME_VIDEOS = [
  {
    id: 'julian',
    title: 'How to speak so that people want to listen',
    speaker: 'Julian Treasure',
    duration: '9:58',
    level: 'B2',
    source: 'TED',
    thumb: 'assets/julian-thumbnail.jpg',
    dotColor: '#FFE066',
  },
  {
    id: 'ted-ed-dream',
    title: 'Why do we dream?',
    speaker: 'TED-Ed · Amy Adkins',
    duration: '4:58',
    level: 'B1',
    source: 'TED-Ed',
    thumb: 'assets/ted-ed-dream-thumbnail.jpg',
    dotColor: '#B8C4FF',
  },
  {
    id: 'tim-urban',
    title: 'Inside the mind of a master procrastinator',
    speaker: 'Tim Urban',
    duration: '14:04',
    level: 'B2',
    source: 'TED',
    thumb: 'assets/tim-urban-thumbnail.jpg',
    dotColor: '#FF9F6E',
  },
];

window.HomeScreen = HomeScreen;
