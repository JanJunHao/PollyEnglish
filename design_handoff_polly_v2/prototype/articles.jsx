// articles.jsx — 外刊 (foreign publication articles) feed
// Used inside HomeScreen when category === 'foreign'.

window.HOME_ARTICLES = [
  {
    id: 'econ-ai-chips',
    publication: 'The Economist',
    pubAbbr: 'TE',
    pubColor: '#E3120B',
    pubBg: '#1a0a08',
    accent: 'linear-gradient(135deg, #E3120B 0%, #6B0500 100%)',
    title: 'Why the AI race belongs to the chip makers',
    excerpt: 'As Nvidia\u2019s market cap eclipses four trillion dollars, the real winners of the AI gold rush turn out to be the people selling the shovels.',
    words: 1240, minutes: 5, level: 'B2',
    date: '2 days ago', section: 'BUSINESS',
  },
  {
    id: 'nyt-loneliness',
    publication: 'The New York Times',
    pubAbbr: 'NYT',
    pubColor: '#f6f4ef',
    pubBg: '#0d0d0e',
    accent: 'linear-gradient(135deg, #2c2c30 0%, #0a0a0c 100%)',
    title: 'The loneliness epidemic finds its latest victim: middle-aged men',
    excerpt: 'A new study finds that adult friendships are atrophying \u2014 and the consequences extend well beyond mental health.',
    words: 1820, minutes: 8, level: 'C1',
    date: '1 day ago', section: 'HEALTH',
  },
  {
    id: 'guardian-climate',
    publication: 'The Guardian',
    pubAbbr: 'TG',
    pubColor: '#7FB6E8',
    pubBg: '#08101a',
    accent: 'linear-gradient(135deg, #005689 0%, #002a4a 100%)',
    title: 'Greenland ice loss has tripled, satellite data confirms',
    excerpt: 'New analysis of three decades of satellite measurements reveals a sharply accelerating trend with global implications.',
    words: 960, minutes: 4, level: 'B2',
    date: 'Yesterday', section: 'CLIMATE',
  },
  {
    id: 'atlantic-attention',
    publication: 'The Atlantic',
    pubAbbr: 'A',
    pubColor: '#E63946',
    pubBg: '#180806',
    accent: 'linear-gradient(135deg, #E63946 0%, #6A1218 100%)',
    title: 'You are not distracted. You are adapted.',
    excerpt: 'The real question is not why we can\u2019t focus \u2014 it is what we have evolved to focus on instead.',
    words: 2400, minutes: 10, level: 'C1',
    date: '3 days ago', section: 'PSYCHOLOGY',
  },
  {
    id: 'bbc-japan',
    publication: 'BBC News',
    pubAbbr: 'BBC',
    pubColor: '#fff',
    pubBg: '#120808',
    accent: 'linear-gradient(135deg, #BB1919 0%, #4a0a0a 100%)',
    title: 'Japan rethinks its century-long approach to nuclear power',
    excerpt: 'After Fukushima, the country swore off atomic energy. Now energy costs are forcing a reconsideration.',
    words: 1100, minutes: 5, level: 'B2',
    date: '4 days ago', section: 'POLITICS',
  },
  {
    id: 'newyorker-attention',
    publication: 'The New Yorker',
    pubAbbr: 'TNY',
    pubColor: '#fff',
    pubBg: '#0a0e14',
    accent: 'linear-gradient(135deg, #1a1f2e 0%, #050810 100%)',
    title: 'The quiet renaissance of the analog notebook',
    excerpt: 'In an age of infinite digital tools, why are knowledge workers returning to paper?',
    words: 3100, minutes: 13, level: 'C1',
    date: '5 days ago', section: 'CULTURE',
  },
];

function ArticleFeed({ tweaks }) {
  const [hero, ...rest] = window.HOME_ARTICLES;
  return (
    <>
      {/* Hero article */}
      <div style={{
        padding: '8px 14px 14px',
        fontFamily: 'JetBrains Mono, monospace', fontSize: 10, letterSpacing: 1.5,
        color: tweaks.aiText, fontWeight: 700,
      }}>EDITOR'S PICK · {hero.date.toUpperCase()}</div>
      <div style={{ padding: '0 14px 24px' }}>
        <ArticleHero article={hero} tweaks={tweaks}/>
      </div>

      {/* Recent articles */}
      <div style={{
        padding: '0 22px 14px',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      }}>
        <div style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 20, fontWeight: 600,
          color: 'var(--text)', letterSpacing: -0.2,
        }}>最新外刊</div>
        <button style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          fontFamily: '"PingFang SC", sans-serif', fontSize: 12.5,
          color: 'var(--text-sec)',
        }}>查看更多 ›</button>
      </div>

      <div style={{ padding: '0 14px 6px', display: 'flex', flexDirection: 'column', gap: 0 }}>
        {rest.map((a, i) => (
          <ArticleRow key={a.id} article={a} tweaks={tweaks} last={i === rest.length - 1}/>
        ))}
      </div>

      {/* Stats / source list */}
      <div style={{
        margin: '22px 22px 0',
        padding: '14px 16px',
        borderRadius: 12,
        background: 'var(--surface-subtle)',
        border: 'var(--card-border)',
      }}>
        <div style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 11, fontWeight: 600,
          color: 'var(--text-sec)', letterSpacing: 0.3, marginBottom: 8,
        }}>合作刊源 · {window.HOME_ARTICLES.length}+</div>
        <div style={{
          display: 'flex', flexWrap: 'wrap', gap: 6,
        }}>
          {['Economist', 'NYT', 'Guardian', 'Atlantic', 'BBC', 'New Yorker', 'Bloomberg', 'WSJ'].map((p) => (
            <span key={p} style={{
              padding: '4px 9px', borderRadius: 8,
              background: 'var(--surface)',
              fontFamily: 'Fraunces, serif', fontStyle: 'italic', fontSize: 11.5,
              color: 'var(--text-sec)',
            }}>{p}</span>
          ))}
        </div>
      </div>
    </>
  );
}

// =============================================================================
// Article hero — large editorial card
// =============================================================================

function ArticleHero({ article, tweaks }) {
  return (
    <div style={{
      borderRadius: 18, overflow: 'hidden',
      background: article.pubBg,
      border: 'var(--card-border)',
      boxShadow: 'var(--shadow-card)',
      cursor: 'pointer',
    }}>
      {/* Cover */}
      <div style={{
        height: 130, position: 'relative',
        background: article.accent,
        overflow: 'hidden',
      }}>
        {/* Texture overlay */}
        <svg viewBox="0 0 400 130" preserveAspectRatio="none"
          style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.18 }}>
          <defs>
            <pattern id={`p-${article.id}`} width="3" height="3" patternUnits="userSpaceOnUse">
              <rect width="3" height="3" fill="#fff" opacity="0"/>
              <circle cx="1" cy="1" r="0.5" fill="#fff" opacity="0.5"/>
            </pattern>
          </defs>
          <rect width="400" height="130" fill={`url(#p-${article.id})`}/>
        </svg>
        {/* Publication mark — large, italic */}
        <div style={{
          position: 'absolute', left: 18, top: 16,
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontStyle: 'italic',
          fontSize: 22, letterSpacing: -0.5,
          color: article.pubColor,
          textShadow: '0 2px 8px rgba(0,0,0,0.25)',
        }}>{article.publication}</div>
        {/* Section + date */}
        <div style={{
          position: 'absolute', left: 18, bottom: 14, right: 18,
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <span style={{
            padding: '3px 8px', borderRadius: 8,
            background: 'rgba(0,0,0,0.35)',
            backdropFilter: 'blur(6px)',
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5, fontWeight: 700,
            color: '#fff', letterSpacing: 1,
          }}>{article.section}</span>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
            color: 'var(--text-sec)', letterSpacing: 0.5,
          }}>{article.date.toUpperCase()}</span>
        </div>
      </div>

      {/* Text body */}
      <div style={{ padding: '18px 18px 18px' }}>
        <div style={{
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 22,
          color: '#fff', letterSpacing: -0.5, lineHeight: 1.2,
        }}>{article.title}</div>
        <div style={{
          marginTop: 10,
          fontFamily: 'Inter, sans-serif', fontSize: 13.5, fontWeight: 400,
          color: 'var(--text-sec)', lineHeight: 1.55, fontStyle: 'italic',
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{article.excerpt}</div>
        <div style={{
          marginTop: 14, display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <span style={{
            padding: '3px 8px', borderRadius: 8,
            background: `${tweaks.aiColor}22`,
            fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5, fontWeight: 700,
            color: tweaks.aiText, letterSpacing: 0.5,
          }}>{article.level}</span>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 10.5,
            color: 'var(--text-ter)', letterSpacing: 0.4,
          }}>{article.words.toLocaleString()} words · {article.minutes} min read</span>
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// Article row — list style (text-first, small accent rect on left)
// =============================================================================

function ArticleRow({ article, tweaks, last }) {
  return (
    <div style={{
      display: 'flex', gap: 12, padding: '14px 8px',
      cursor: 'pointer',
      borderBottom: last ? 'none' : '0.5px solid var(--divider)',
    }}>
      {/* Mini cover */}
      <div style={{
        width: 64, height: 78, borderRadius: 8, flexShrink: 0,
        background: article.accent,
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', inset: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontStyle: 'italic',
          fontSize: 18, color: article.pubColor,
          textShadow: '0 1px 4px rgba(0,0,0,0.4)',
          letterSpacing: -0.5,
        }}>{article.pubAbbr}</div>
        {/* Bottom strip */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0, height: 14,
          background: 'rgba(0,0,0,0.5)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'JetBrains Mono, monospace', fontSize: 8, letterSpacing: 0.5,
          color: 'var(--text-sec)', fontWeight: 700,
        }}>{article.section}</div>
      </div>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5, letterSpacing: 0.7,
          color: 'var(--text-ter)', fontWeight: 700, marginBottom: 4,
        }}>{article.publication.toUpperCase()}</div>
        <div style={{
          fontFamily: 'Fraunces, serif', fontSize: 15, fontWeight: 500,
          color: 'var(--text)', lineHeight: 1.3, letterSpacing: -0.2,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{article.title}</div>
        <div style={{
          marginTop: 6, display: 'flex', alignItems: 'center', gap: 8,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: 'var(--text-ter)', letterSpacing: 0.4,
        }}>
          <span style={{ color: tweaks.aiText }}>{article.level}</span>
          <span>·</span>
          <span>{article.minutes} min</span>
          <span>·</span>
          <span>{article.date}</span>
        </div>
      </div>
    </div>
  );
}

window.ArticleFeed = ArticleFeed;
