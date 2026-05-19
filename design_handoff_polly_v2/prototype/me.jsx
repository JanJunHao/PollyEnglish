// me.jsx — 「我的」tab：我的学习 + 学习数据 + 设置入口

function MeScreen({ tweaks, onOpenVideo, onOpenVocab, onOpenFavorites }) {
  const julian = window.HOME_VIDEOS[0];

  return (
    <div style={{
      width: '100%', height: '100%', background: 'var(--bg)', color: 'var(--text)',
      overflow: 'auto', WebkitOverflowScrolling: 'touch', paddingTop: 56,
    }}>
      {/* Top nav title */}
      <div style={{ padding: '10px 22px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 17, fontWeight: 600,
          color: 'var(--text)',
        }}>我的</div>
        <button style={{
          width: 36, height: 36, borderRadius: 18, background: 'var(--chip-bg)',
          border: 'none', cursor: 'pointer', padding: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="settings" size={16} color="var(--text-sec)"/>
        </button>
      </div>

      {/* Profile header */}
      <div style={{
        padding: '14px 22px 24px', display: 'flex', alignItems: 'center', gap: 14,
      }}>
        <div style={{
          width: 56, height: 56, borderRadius: 28,
          background: `linear-gradient(135deg, ${tweaks.brandColor}, ${tweaks.aiColor})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Fraunces, serif', fontSize: 26, fontWeight: 500,
          color: '#0a0a0c',
          boxShadow: `0 6px 20px ${tweaks.brandColor}33`,
        }}>P</div>
        <div style={{ flex: 1 }}>
          <div style={{
            fontFamily: 'Fraunces, serif', fontSize: 22, fontWeight: 500,
            color: 'var(--text)', letterSpacing: -0.4,
          }}>Polly Learner</div>
          <div style={{
            marginTop: 2,
            fontFamily: 'JetBrains Mono, monospace', fontSize: 10.5,
            color: 'var(--text-sec)', letterSpacing: 0.6,
          }}>CEFR B1 · 学龄 7 天</div>
        </div>
      </div>

      {/* Stats row */}
      <div style={{ padding: '0 14px 14px' }}>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10,
        }}>
          <StatTile label="学习天数" value="7" unit="天" tone={tweaks.brandColor}/>
          <StatTile label="收藏句子" value="12" unit="句" tone={tweaks.aiColor}/>
          <StatTile label="掌握词汇" value="84" unit="词" tone="#FF9F6E"/>
        </div>
      </div>

      {/* My Learning */}
      <SectionTitle label="我的学习" right="查看全部"/>
      <div style={{ padding: '0 14px 8px' }}>
        <LearningCard video={julian} progress={0.32} currentTime="3:12"
          tweaks={tweaks} onOpen={() => onOpenVideo(julian)}/>
      </div>

      {/* List rows */}
      <SectionTitle label="学习资料"/>
      <div style={{ padding: '0 14px 14px' }}>
        <ListGroup>
          <ListRow icon="bookmark" iconBg={`${tweaks.brandColor}22`} iconColor={tweaks.brandColor}
            label="收藏的句子" trailing="12" onClick={onOpenFavorites}/>
          <ListRow icon="book" iconBg={`${tweaks.aiColor}22`} iconColor={tweaks.aiColor}
            label="词汇本" trailing="84" onClick={onOpenVocab}/>
          <ListRow icon="chart" iconBg="#FF9F6E22" iconColor="#FF9F6E"
            label="学习数据" trailing="详情"/>
          <ListRow icon="target" iconBg="var(--chip-bg-active)" iconColor="var(--text)"
            label="学习目标" trailing="每日 15 分钟" last/>
        </ListGroup>
      </div>

      <SectionTitle label="偏好"/>
      <div style={{ padding: '0 14px 130px' }}>
        <ListGroup>
          <ListRow icon="subtitle" iconBg="var(--chip-bg-active)" iconColor="var(--text)"
            label="字幕偏好" trailing="英文+中文"/>
          <ListRow icon="speed" iconBg="var(--chip-bg-active)" iconColor="var(--text)"
            label="默认播放速度" trailing="1.0×"/>
          <ListRow icon="globe" iconBg="var(--chip-bg-active)" iconColor="var(--text)"
            label="语言" trailing="简体中文" last/>
        </ListGroup>
      </div>
    </div>
  );
}

function StatTile({ label, value, unit, tone }) {
  return (
    <div style={{
      padding: '14px 12px', borderRadius: 14,
      background: 'var(--surface)',
      border: 'var(--card-border)',
    }}>
      <div style={{
        fontFamily: '"PingFang SC", sans-serif', fontSize: 10.5,
        color: 'var(--text-sec)', letterSpacing: 0.2,
      }}>{label}</div>
      <div style={{
        marginTop: 5, display: 'flex', alignItems: 'baseline', gap: 3,
      }}>
        <span style={{
          fontFamily: 'Fraunces, serif', fontWeight: 500, fontSize: 24,
          color: tone, letterSpacing: -0.5, lineHeight: 1,
        }}>{value}</span>
        <span style={{
          fontFamily: '"PingFang SC", sans-serif', fontSize: 10,
          color: 'var(--text-ter)',
        }}>{unit}</span>
      </div>
    </div>
  );
}

function SectionTitle({ label, right, onAction }) {
  return (
    <div style={{
      padding: '18px 22px 10px',
      display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
    }}>
      <div style={{
        fontFamily: '"PingFang SC", sans-serif', fontSize: 13, fontWeight: 500,
        color: 'var(--text-sec)', letterSpacing: 0.3,
        textTransform: 'uppercase',
      }}>{label}</div>
      {right && (
        <button onClick={onAction} style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          padding: 0,
          fontFamily: '"PingFang SC", sans-serif', fontSize: 12,
          color: 'var(--text-ter)',
        }}>{right} ›</button>
      )}
    </div>
  );
}

function LearningCard({ video, progress, currentTime, tweaks, onOpen }) {
  return (
    <div onClick={onOpen} style={{
      position: 'relative', borderRadius: 16, overflow: 'hidden',
      background: '#0c0c10', cursor: 'pointer',
      border: 'var(--card-border)',
      display: 'flex',
    }}>
      <div style={{ width: 116, height: 116, position: 'relative', flexShrink: 0 }}>
        <Thumbnail videoId={video.id} brand={tweaks.brandColor} ai={tweaks.aiColor}
          style={tweaks.thumbStyle} src={video.thumb}/>
      </div>
      <div style={{ flex: 1, padding: '12px 14px', minWidth: 0, display: 'flex', flexDirection: 'column' }}>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 9.5,
          color: tweaks.brandText, letterSpacing: 0.7, fontWeight: 700,
        }}>继续学习</div>
        <div style={{
          marginTop: 4,
          fontFamily: 'Inter, sans-serif', fontWeight: 600, fontSize: 13.5,
          color: 'var(--text)', lineHeight: 1.3,
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        }}>{video.title}</div>

        <div style={{ flex: 1 }}/>

        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
          color: 'var(--text-sec)', letterSpacing: 0.5,
          marginBottom: 5,
        }}>
          {currentTime} / {video.duration} · {Math.round(progress * 100)}%
        </div>
        <div style={{
          height: 3, borderRadius: 2, background: 'var(--chip-bg-active)',
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{
            position: 'absolute', left: 0, top: 0, bottom: 0,
            width: `${progress * 100}%`,
            background: `linear-gradient(90deg, ${tweaks.brandColor}, ${tweaks.brandColor}cc)`,
            boxShadow: `0 0 6px ${tweaks.brandColor}80`,
          }}/>
        </div>
      </div>
    </div>
  );
}

function ListGroup({ children }) {
  return (
    <div style={{
      background: 'var(--surface)', borderRadius: 14,
      border: 'var(--card-border)',
      overflow: 'hidden',
    }}>{children}</div>
  );
}

function ListRow({ icon, iconBg, iconColor, label, trailing, last, onClick }) {
  return (
    <div onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '13px 14px', cursor: onClick ? 'pointer' : 'default',
      borderBottom: last ? 'none' : '0.5px solid var(--divider)',
    }}>
      <div style={{
        width: 30, height: 30, borderRadius: 8,
        background: iconBg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <Icon name={icon} size={15} color={iconColor}/>
      </div>
      <div style={{
        flex: 1,
        fontFamily: '"PingFang SC", sans-serif', fontSize: 14.5,
        color: 'var(--text)', letterSpacing: -0.1,
      }}>{label}</div>
      {trailing && (
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 11,
          color: 'var(--text-ter)',
        }}>{trailing}</div>
      )}
      <Icon name="chevron-right" size={13} color="var(--text-muted)"/>
    </div>
  );
}

window.MeScreen = MeScreen;
