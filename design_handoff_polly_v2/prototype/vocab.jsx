// vocab.jsx — 词汇本：保存的单词卡片列表

window.VOCAB_LIST = [
  { word: 'powerful', src: 'Julian Treasure', time: '0:19', addedAt: '今天', mastery: 0.2 },
  { word: 'voice', src: 'Julian Treasure', time: '0:14', addedAt: '今天', mastery: 0.6 },
  { word: 'instrument', src: 'Julian Treasure', time: '0:16', addedAt: '今天', mastery: 0.0 },
  { word: 'exhaustive', src: 'Julian Treasure', time: '0:42', addedAt: '昨天', mastery: 0.3 },
  { word: 'deadly', src: 'Julian Treasure', time: '0:39', addedAt: '昨天', mastery: 0.4 },
  { word: 'powerfully', src: 'Julian Treasure', time: '0:30', addedAt: '昨天', mastery: 0.5 },
  { word: 'habits', src: 'Julian Treasure', time: '0:35', addedAt: '2 天前', mastery: 0.8 },
  { word: 'experience', src: 'Julian Treasure', time: '0:25', addedAt: '2 天前', mastery: 1.0 },
  { word: 'sound', src: 'Julian Treasure', time: '0:19', addedAt: '3 天前', mastery: 0.9 },
  { word: 'speak', src: 'Julian Treasure', time: '0:25', addedAt: '3 天前', mastery: 1.0 },
];

function VocabScreen({ tweaks, onBack, onWordTap }) {
  const [filter, setFilter] = React.useState('all');
  const [query, setQuery] = React.useState('');

  const filters = [
    { id: 'all', label: '全部' },
    { id: 'new', label: '新学' },
    { id: 'review', label: '待复习' },
    { id: 'mastered', label: '已掌握' },
  ];

  const filtered = window.VOCAB_LIST.filter((v) => {
    if (query && !v.word.toLowerCase().includes(query.toLowerCase())) return false;
    if (filter === 'new') return v.mastery < 0.3;
    if (filter === 'review') return v.mastery >= 0.3 && v.mastery < 0.8;
    if (filter === 'mastered') return v.mastery >= 0.8;
    return true;
  });

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
        }}>词汇本</div>
      </div>

      {/* Heading + meta */}
      <div style={{ padding: '12px 22px 14px', flexShrink: 0 }}>
        <div style={{
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 30,
          color: 'var(--text)', letterSpacing: -1, lineHeight: 1.05,
        }}>Your vocabulary</div>
        <div style={{
          marginTop: 4, display: 'flex', alignItems: 'center', gap: 14,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10.5,
          color: 'var(--text-sec)', letterSpacing: 0.4,
        }}>
          <span><span style={{color: tweaks.brandText, fontWeight: 700}}>{window.VOCAB_LIST.length}</span> WORDS</span>
          <span>·</span>
          <span>{window.VOCAB_LIST.filter(v => v.mastery >= 0.8).length} MASTERED</span>
          <span>·</span>
          <span>{window.VOCAB_LIST.filter(v => v.mastery < 0.3).length} NEW</span>
        </div>
      </div>

      {/* Search */}
      <div style={{ padding: '0 16px 12px', flexShrink: 0 }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          padding: '9px 12px', borderRadius: 11,
          background: 'var(--chip-bg)',
        }}>
          <Icon name="search" size={14} color="var(--text-ter)"/>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="搜索单词..."
            style={{
              flex: 1, background: 'transparent', border: 'none', outline: 'none',
              color: 'var(--text)', fontFamily: 'Inter, sans-serif', fontSize: 13,
            }}
          />
        </div>
      </div>

      {/* Filter chips */}
      <div style={{
        padding: '0 14px 10px', flexShrink: 0,
        display: 'flex', gap: 6, overflowX: 'auto', scrollbarWidth: 'none',
      }}>
        {filters.map((f) => (
          <button key={f.id} onClick={() => setFilter(f.id)} style={{
            flexShrink: 0, padding: '6px 12px', borderRadius: 14, cursor: 'pointer',
            background: filter === f.id ? `${tweaks.brandColor}1f` : 'var(--surface)',
            border: filter === f.id ? `1px solid ${tweaks.brandColor}55` : '1px solid transparent',
            color: filter === f.id ? tweaks.brandText : 'var(--text-sec)',
            fontFamily: '"PingFang SC", sans-serif', fontSize: 12, fontWeight: 500,
          }}>{f.label}</button>
        ))}
      </div>

      {/* Vocab grid */}
      <div style={{
        flex: 1, overflow: 'auto', WebkitOverflowScrolling: 'touch',
        padding: '4px 14px 100px',
      }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
        }}>
          {filtered.map((v) => (
            <VocabTile key={v.word + v.time} item={v} tweaks={tweaks}
              onClick={() => onWordTap(v)}/>
          ))}
        </div>
        {filtered.length === 0 && (
          <div style={{
            padding: '50px 20px', textAlign: 'center',
            fontFamily: '"PingFang SC", sans-serif', fontSize: 13,
            color: 'var(--text-ter)',
          }}>没有符合条件的单词</div>
        )}
      </div>
    </div>
  );
}

function VocabTile({ item, tweaks, onClick }) {
  const entry = window.WORDS[item.word] || {};
  return (
    <div onClick={onClick} style={{
      padding: '14px 14px 12px', borderRadius: 14,
      background: 'var(--surface)',
      border: 'var(--card-border)',
      cursor: 'pointer',
      display: 'flex', flexDirection: 'column', gap: 0,
      position: 'relative', minHeight: 122,
    }}>
      <div style={{
        fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 22,
        color: 'var(--text)', letterSpacing: -0.4, lineHeight: 1.1,
      }}>{item.word}</div>
      {entry.phonetic && (
        <div style={{
          marginTop: 3,
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
          color: 'var(--text-ter)',
        }}>{entry.phonetic}</div>
      )}
      {entry.defs && entry.defs[0] && (
        <div style={{
          marginTop: 7,
          fontFamily: '"PingFang SC", sans-serif', fontSize: 11.5,
          color: 'var(--text-sec)', lineHeight: 1.4,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{entry.defs[0].meaning}</div>
      )}

      <div style={{ flex: 1 }}/>

      {/* Mastery bar */}
      <div style={{
        marginTop: 10, height: 2.5, borderRadius: 2,
        background: 'var(--chip-bg)', overflow: 'hidden',
      }}>
        <div style={{
          width: `${item.mastery * 100}%`, height: '100%',
          background: item.mastery >= 0.8 ? tweaks.brandColor : item.mastery >= 0.3 ? tweaks.aiColor : '#FF9F6E',
          transition: 'width 400ms',
        }}/>
      </div>
      <div style={{
        marginTop: 6, display: 'flex', justifyContent: 'space-between',
        fontFamily: 'JetBrains Mono, monospace', fontSize: 8.5,
        color: 'var(--text-ter)', letterSpacing: 0.3,
      }}>
        <span>{item.time}</span>
        <span>{item.addedAt}</span>
      </div>
    </div>
  );
}

window.VocabScreen = VocabScreen;
