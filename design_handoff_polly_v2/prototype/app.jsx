// app.jsx — Root for PollyEnglish demo prototype
// Holds: screen state, playback clock, overlay state, tweaks. Hosts iOS frame + transitions.

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "brandColor": "#FFE066",
  "aiColor": "#B8C4FF",
  "theme": "dark",
  "subSize": 16,
  "density": "regular",
  "playbackRate": 1,
  "thumbStyle": "polly"
}/*EDITMODE-END*/;

function App() {
  const [raw, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const t = React.useMemo(() => mkTheme(raw), [raw]);
  const [screen, setScreen] = React.useState('discover'); // 'discover' | 'me' | 'library' | 'player'
  const [prevTab, setPrevTab] = React.useState('discover'); // remember last root tab to return to
  const [transition, setTransition] = React.useState(null); // {from, to, rect}
  const [currentVideo, setCurrentVideo] = React.useState(null);

  // Playback clock
  const [currentTime, setCurrentTime] = React.useState(14.08);
  const [isPlaying, setIsPlaying] = React.useState(false);
  const TOTAL = 9 * 60 + 58;

  // Overlays
  const [wordCard, setWordCard] = React.useState(null); // { word, segment }
  const [aiCard, setAiCard] = React.useState(null);     // segment
  const [subSettings, setSubSettings] = React.useState(false);
  const [shadowing, setShadowing] = React.useState(null); // segment

  // Playback ticker
  React.useEffect(() => {
    if (!isPlaying || screen !== 'player') return;
    const start = performance.now();
    const t0 = currentTime;
    let raf;
    const tick = (now) => {
      const elapsed = (now - start) / 1000;
      const next = t0 + elapsed * t.playbackRate;
      if (next >= TOTAL) {
        setCurrentTime(TOTAL);
        setIsPlaying(false);
        return;
      }
      setCurrentTime(next);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [isPlaying, screen, t.playbackRate]);
  const openVideo = (video, sourceEl) => {
    // remember which root tab the user came from
    if (screen === 'discover' || screen === 'me' || screen === 'library' || screen === 'files' || screen === 'vocab' || screen === 'favorites') {
      setPrevTab(screen);
    }
    setCurrentVideo(video);
    // Capture source thumb rect for hero animation
    let rect = null;
    if (sourceEl) {
      const r = sourceEl.getBoundingClientRect();
      const parent = sourceEl.closest('[data-device-screen]');
      if (parent) {
        const pr = parent.getBoundingClientRect();
        rect = {
          left: r.left - pr.left,
          top: r.top - pr.top,
          width: r.width,
          height: r.height,
          thumb: video.thumb,
        };
      }
    }
    setTransition(rect);
    // Reset playback to opening segment
    setCurrentTime(14.08);
    setIsPlaying(false);
    // After morph animates, swap screens
    setTimeout(() => {
      setScreen('player');
      setIsPlaying(true);
      setTimeout(() => setTransition(null), 100);
    }, 380);
  };

  const onBack = () => {
    setIsPlaying(false);
    setScreen(prevTab);
    setWordCard(null);
    setAiCard(null);
  };

  const handleTapWord = (word, segment) => {
    setIsPlaying(false);
    setWordCard({ word, sentence: segment });
  };
  const handleLongPress = (segment) => {
    setIsPlaying(false);
    setAiCard(segment);
  };

  return (
    <div style={{
      width: '100vw', height: '100vh', position: 'relative',
      background: t.isLight
        ? 'radial-gradient(circle at 30% 20%, #ebe7df 0%, #d6d0c4 80%)'
        : 'radial-gradient(circle at 30% 20%, #1a1a22 0%, #0a0a0c 60%)',
      overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter, -apple-system, sans-serif',
      transition: 'background 320ms',
    }}>
      <IOSDevice width={390} height={844} dark={!t.isLight}>
        <div className="theme-host" data-theme={t.theme} data-device-screen style={{
          position: 'absolute', inset: 0, overflow: 'hidden',
          background: 'var(--bg)',
          color: 'var(--text)',
          transition: 'background 320ms, color 320ms',
        }}>
          {/* Discover (home) screen */}
          <div data-screen-label="01 Discover" style={{
            position: 'absolute', inset: 0,
            transform: screen === 'discover' ? 'translateX(0)' : (screen === 'me' ? 'translateX(-15%)' : 'translateX(-15%)'),
            opacity: screen === 'discover' ? 1 : 0,
            transition: 'transform 380ms cubic-bezier(.22,1,.36,1), opacity 280ms',
            pointerEvents: screen === 'discover' ? 'auto' : 'none',
          }}>
            <HomeScreen tweaks={t}
              onOpenVideo={(video) => {
                const el = document.querySelector(`[data-banner-card="${video.id}"]`);
                openVideo(video, el);
              }}
              onOpenLibrary={() => setScreen('library')}
            />
          </div>

          {/* Me screen */}
          <div data-screen-label="03 Me" style={{
            position: 'absolute', inset: 0,
            transform: screen === 'me' ? 'translateX(0)' : (screen === 'files' ? 'translateX(15%)' : 'translateX(15%)'),
            opacity: screen === 'me' ? 1 : 0,
            transition: 'transform 380ms cubic-bezier(.22,1,.36,1), opacity 280ms',
            pointerEvents: screen === 'me' ? 'auto' : 'none',
          }}>
            <MeScreen tweaks={t}
              onOpenVideo={(video) => openVideo(video, null)}
              onOpenVocab={() => setScreen('vocab')}
              onOpenFavorites={() => setScreen('favorites')}
            />
          </div>

          {/* Vocab screen */}
          {(screen === 'vocab' || prevTab === 'vocab') && (
            <div data-screen-label="04 Vocab" style={{
              position: 'absolute', inset: 0,
              transform: screen === 'vocab' ? 'translateX(0)' : 'translateX(100%)',
              transition: 'transform 380ms cubic-bezier(.22,1,.36,1)',
              pointerEvents: screen === 'vocab' ? 'auto' : 'none',
            }}>
              <VocabScreen tweaks={t}
                onBack={() => setScreen('me')}
                onWordTap={(item) => {
                  // Open word card overlay
                  const seg = window.SUBTITLES.find(s => s.s.toFixed(0) === String(parseFloat(item.time.replace(':','.')).toFixed(0))) || window.SUBTITLES[2];
                  setWordCard({ word: { w: item.word }, sentence: seg });
                }}
              />
            </div>
          )}

          {/* Favorites screen */}
          {(screen === 'favorites' || prevTab === 'favorites') && (
            <div data-screen-label="05 Favorites" style={{
              position: 'absolute', inset: 0,
              transform: screen === 'favorites' ? 'translateX(0)' : 'translateX(100%)',
              transition: 'transform 380ms cubic-bezier(.22,1,.36,1)',
              pointerEvents: screen === 'favorites' ? 'auto' : 'none',
            }}>
              <FavoritesScreen tweaks={t}
                onBack={() => setScreen('me')}
                onOpenSentence={(video, seg) => {
                  setPrevTab('favorites');
                  setCurrentVideo(video);
                  setCurrentTime(seg.s);
                  setScreen('player');
                  setIsPlaying(true);
                }}
              />
            </div>
          )}

          {/* Files screen */}
          <div data-screen-label="02 Files" style={{
            position: 'absolute', inset: 0,
            transform: screen === 'files' ? 'translateX(0)' : (screen === 'discover' ? 'translateX(15%)' : 'translateX(-15%)'),
            opacity: screen === 'files' ? 1 : 0,
            transition: 'transform 380ms cubic-bezier(.22,1,.36,1), opacity 280ms',
            pointerEvents: screen === 'files' ? 'auto' : 'none',
          }}>
            <FilesScreen tweaks={t}
              onOpenVideo={(video) => openVideo(window.HOME_VIDEOS[0], null)}
            />
          </div>

          {/* Library screen (push from Discover) */}
          {(screen === 'library' || prevTab === 'library') && (
            <div data-screen-label="03 Library" style={{
              position: 'absolute', inset: 0,
              transform: screen === 'library' ? 'translateX(0)' : 'translateX(100%)',
              transition: 'transform 380ms cubic-bezier(.22,1,.36,1)',
              pointerEvents: screen === 'library' ? 'auto' : 'none',
            }}>
              <LibraryScreen tweaks={t}
                onBack={() => setScreen('discover')}
                onOpenVideo={(video) => openVideo(video, null)}
              />
            </div>
          )}

          {/* Bottom tab bar — only on root tabs (not on library or player) */}
          {(screen === 'discover' || screen === 'me' || screen === 'files') && (
            <BottomTabBar active={screen} onChange={setScreen} brand={t.brandColor}/>
          )}

          {/* Player screen */}
          {currentVideo && (
            <div data-screen-label="02 Player" style={{
              position: 'absolute', inset: 0,
              transform: screen === 'player' ? 'translateX(0)' : 'translateX(100%)',
              transition: 'transform 380ms cubic-bezier(.22,1,.36,1)',
              pointerEvents: screen === 'player' ? 'auto' : 'none',
            }}>
              <PlayerScreen video={currentVideo} tweaks={t}
                currentTime={currentTime}
                isPlaying={isPlaying}
                setIsPlaying={setIsPlaying}
                seek={(t) => setCurrentTime(Math.max(0, Math.min(TOTAL, t)))}
                onBack={onBack}
                onTapWord={handleTapWord}
                onLongPressSentence={handleLongPress}
                onOpenSubSettings={() => { setIsPlaying(false); setSubSettings(true); }}
                onOpenShadowing={(seg) => { setIsPlaying(false); setShadowing(seg); }}
              />
            </div>
          )}

          {/* Hero morph element for banner → player transition */}
          {transition && (
            <div style={{
              position: 'absolute', zIndex: 90,
              left: transition.left, top: transition.top,
              width: transition.width, height: transition.height,
              borderRadius: 18,
              overflow: 'hidden',
              transition: 'all 380ms cubic-bezier(.22,1,.36,1)',
              pointerEvents: 'none',
              animation: 'heroMorph 380ms forwards cubic-bezier(.22,1,.36,1)',
              background: '#0a0a0c',
            }}>
              <Thumbnail videoId={currentVideo.id} brand={t.brandColor} ai={t.aiColor}
                style={t.thumbStyle} src={currentVideo.thumb} />
              <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.2)' }}/>
            </div>
          )}

          {/* Word card overlay */}
          {wordCard && (
            <WordCard {...wordCard} tweaks={t} onClose={() => { setWordCard(null); if (screen === 'player') setIsPlaying(true); }} />
          )}

          {/* AI card overlay */}
          {aiCard && (
            <AICard segment={aiCard} tweaks={t} onClose={() => { setAiCard(null); setIsPlaying(true); }} />
          )}

          {/* Subtitle settings sheet */}
          {subSettings && (
            <SubtitleSettingsSheet tweaks={t} onClose={() => setSubSettings(false)}/>
          )}

          {/* Shadowing sheet */}
          {shadowing && (
            <ShadowingSheet segment={shadowing} tweaks={t} onClose={() => { setShadowing(null); setIsPlaying(true); }}/>
          )}
        </div>
      </IOSDevice>

      {/* Tweaks panel */}
      <TweaksPanel>
        <TweakSection label="主题" />
        <TweakRadio label="深色 / 浅色" value={t.theme}
          options={['dark', 'light']}
          onChange={(v) => setTweak('theme', v)} />
        <TweakSection label="视觉" />
        <TweakRadio label="缩略图" value={t.thumbStyle}
          options={['polly', 'photo']}
          onChange={(v) => setTweak('thumbStyle', v)} />
        <TweakSection label="品牌色彩" />
        <TweakColor label="主色（黄）" value={t.brandColor}
          options={['#FFE066', '#FFC93B', '#F5D547', '#FFD54B']}
          onChange={(v) => setTweak('brandColor', v)} />
        <TweakColor label="AI 色（紫蓝）" value={t.aiColor}
          options={['#B8C4FF', '#A8B8FF', '#C5B8FF', '#9CAEF5']}
          onChange={(v) => setTweak('aiColor', v)} />
        <TweakSection label="字幕" />
        <TweakSlider label="英文字号" value={t.subSize} min={13} max={20} step={1} unit="px"
          onChange={(v) => setTweak('subSize', v)} />
        <TweakRadio label="密度" value={t.density}
          options={['compact', 'regular', 'comfy']}
          onChange={(v) => setTweak('density', v)} />
        <TweakSection label="播放" />
        <TweakSlider label="播放速度" value={t.playbackRate} min={0.5} max={2} step={0.5} unit="×"
          onChange={(v) => setTweak('playbackRate', v)} />
      </TweaksPanel>
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
