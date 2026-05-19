// thumbs.jsx — Original Polly-branded video covers
// Replaces the YouTube TED thumbnails with editorial SVG art that establishes Polly's own visual identity.
// Each cover is built as 1280x720 viewBox (16:9) and scales to its container.

function Thumbnail({ videoId, brand, ai, style = 'polly', src }) {
  if (style === 'photo' && src) {
    return <img src={src} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />;
  }
  if (videoId === 'julian')        return <CoverVoice brand={brand} />;
  if (videoId === 'ted-ed-dream')  return <CoverDream ai={ai} />;
  if (videoId === 'tim-urban')     return <CoverWait />;
  return null;
}

// 01 — Julian Treasure · How to speak so that people want to listen
// "VOICE" — Fraunces oversized, warm yellow, with thin vertical waveform bars on the right
function CoverVoice({ brand = '#FFE066' }) {
  return (
    <svg viewBox="0 0 1280 720" preserveAspectRatio="xMidYMid slice"
      style={{ width: '100%', height: '100%', display: 'block' }}>
      <defs>
        <radialGradient id="vg" cx="78%" cy="62%" r="60%">
          <stop offset="0%" stopColor={brand} stopOpacity="0.34"/>
          <stop offset="40%" stopColor={brand} stopOpacity="0.10"/>
          <stop offset="100%" stopColor="#0a0a0c" stopOpacity="0"/>
        </radialGradient>
        <linearGradient id="vg2" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#15140f"/>
          <stop offset="100%" stopColor="#0a0a0c"/>
        </linearGradient>
      </defs>
      <rect width="1280" height="720" fill="url(#vg2)"/>
      <rect width="1280" height="720" fill="url(#vg)"/>

      {/* Top-left index */}
      <g transform="translate(56,64)" fill="rgba(255,255,255,0.62)" fontFamily="JetBrains Mono, monospace" fontSize="22" letterSpacing="2">
        <text>01 · TED</text>
      </g>
      <line x1="56" y1="92" x2="200" y2="92" stroke={brand} strokeWidth="2"/>

      {/* Bottom-left credit */}
      <g transform="translate(56,648)" fontFamily="JetBrains Mono, monospace">
        <text fill="rgba(255,255,255,0.42)" fontSize="18" letterSpacing="2">JULIAN TREASURE</text>
        <text y="26" fill="rgba(255,255,255,0.32)" fontSize="14" letterSpacing="1.5">9:58 · CEFR B2 · 2014</text>
      </g>

      {/* Hero word: VOICE */}
      <text x="44" y="450" fill={brand} fontFamily="Fraunces, serif" fontWeight="500"
        fontSize="288" letterSpacing="-12">VOICE</text>

      {/* Subtitle hint */}
      <text x="48" y="500" fill="rgba(255,255,255,0.55)" fontFamily="Fraunces, serif" fontStyle="italic" fontSize="32">
        — the instrument we all play
      </text>

      {/* Right-side waveform */}
      <g transform="translate(1100,360)" opacity="0.95">
        {[40, 90, 35, 130, 75, 160, 95, 110, 50, 145, 80, 120, 60, 100, 30].map((h, i) => (
          <rect key={i} x={i * 10} y={-h / 2} width="4" height={h}
            fill={brand} opacity={0.4 + (i % 4) * 0.15} rx="2"/>
        ))}
      </g>

      {/* Corner ticks */}
      <Tick brand={brand} x={36} y={36} corner="tl"/>
      <Tick brand={brand} x={1244} y={36} corner="tr"/>
      <Tick brand={brand} x={36} y={684} corner="bl"/>
      <Tick brand={brand} x={1244} y={684} corner="br"/>
    </svg>
  );
}

// 02 — TED-Ed · Why do we dream?
// "DREAM" stacked, AI-purple glow, with the 'A' rotated 180° as a dream-logic flip
function CoverDream({ ai = '#B8C4FF' }) {
  return (
    <svg viewBox="0 0 1280 720" preserveAspectRatio="xMidYMid slice"
      style={{ width: '100%', height: '100%', display: 'block' }}>
      <defs>
        <radialGradient id="dg" cx="50%" cy="50%" r="65%">
          <stop offset="0%" stopColor={ai} stopOpacity="0.32"/>
          <stop offset="50%" stopColor={ai} stopOpacity="0.08"/>
          <stop offset="100%" stopColor="#0a0820" stopOpacity="0"/>
        </radialGradient>
        <linearGradient id="dg2" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#0e0c1c"/>
          <stop offset="100%" stopColor="#080614"/>
        </linearGradient>
      </defs>
      <rect width="1280" height="720" fill="url(#dg2)"/>
      <rect width="1280" height="720" fill="url(#dg)"/>

      {/* Stars sprinkled */}
      {[[180,120],[1080,90],[920,180],[150,560],[1180,520],[280,210],[1130,300],[400,640],[1020,650]].map(([cx,cy],i)=>(
        <circle key={i} cx={cx} cy={cy} r={i%3===0?2.4:1.5} fill={ai} opacity={0.45 + (i%4)*0.12}/>
      ))}

      {/* Top-left index */}
      <g transform="translate(56,64)" fill="rgba(255,255,255,0.62)" fontFamily="JetBrains Mono, monospace" fontSize="22" letterSpacing="2">
        <text>02 · TED-Ed</text>
      </g>
      <line x1="56" y1="92" x2="220" y2="92" stroke={ai} strokeWidth="2"/>

      {/* Bottom-left credit */}
      <g transform="translate(56,648)" fontFamily="JetBrains Mono, monospace">
        <text fill="rgba(255,255,255,0.42)" fontSize="18" letterSpacing="2">AMY ADKINS</text>
        <text y="26" fill="rgba(255,255,255,0.32)" fontSize="14" letterSpacing="1.5">4:58 · CEFR B1 · 2015</text>
      </g>

      {/* Stacked title: WHY / DO WE / DREAM? */}
      <g fontFamily="Fraunces, serif" fontWeight="400" fill="#fff">
        <text x="76" y="270" fontSize="80" letterSpacing="-2" fill="rgba(255,255,255,0.55)" fontStyle="italic">why</text>
        <text x="76" y="380" fontSize="80" letterSpacing="-2" fill="rgba(255,255,255,0.55)" fontStyle="italic">do we</text>
        <text x="76" y="540" fontSize="200" fontWeight="500" letterSpacing="-6" fill={ai}>dream?</text>
      </g>

      {/* Right side: a constellation-like brain doodle */}
      <g transform="translate(900,360)" stroke={ai} strokeWidth="1.6" fill="none" opacity="0.7">
        <circle cx="0" cy="0" r="80"/>
        <circle cx="60" cy="-30" r="40" opacity="0.55"/>
        <circle cx="-50" cy="40" r="55" opacity="0.65"/>
        <circle cx="80" cy="60" r="22" opacity="0.45"/>
        <line x1="0" y1="0" x2="60" y2="-30"/>
        <line x1="0" y1="0" x2="-50" y2="40"/>
        <line x1="60" y1="-30" x2="80" y2="60"/>
        <line x1="-50" y1="40" x2="80" y2="60"/>
        {[[0,0],[60,-30],[-50,40],[80,60]].map(([x,y],i)=>(
          <circle key={i} cx={x} cy={y} r="6" fill={ai} stroke="none"/>
        ))}
      </g>

      {/* Corner ticks */}
      <Tick brand={ai} x={36} y={36} corner="tl"/>
      <Tick brand={ai} x={1244} y={36} corner="tr"/>
      <Tick brand={ai} x={36} y={684} corner="bl"/>
      <Tick brand={ai} x={1244} y={684} corner="br"/>
    </svg>
  );
}

// 03 — Tim Urban · Inside the mind of a master procrastinator
// "WAIT." in serif over warm amber gradient, with a single tiny clock
function CoverWait() {
  const amber = '#FF9F6E';
  return (
    <svg viewBox="0 0 1280 720" preserveAspectRatio="xMidYMid slice"
      style={{ width: '100%', height: '100%', display: 'block' }}>
      <defs>
        <radialGradient id="wg" cx="20%" cy="40%" r="70%">
          <stop offset="0%" stopColor={amber} stopOpacity="0.38"/>
          <stop offset="45%" stopColor={amber} stopOpacity="0.10"/>
          <stop offset="100%" stopColor="#0a0a0c" stopOpacity="0"/>
        </radialGradient>
        <linearGradient id="wg2" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#1a120c"/>
          <stop offset="100%" stopColor="#0a0807"/>
        </linearGradient>
      </defs>
      <rect width="1280" height="720" fill="url(#wg2)"/>
      <rect width="1280" height="720" fill="url(#wg)"/>

      {/* Top-left index */}
      <g transform="translate(56,64)" fill="rgba(255,255,255,0.62)" fontFamily="JetBrains Mono, monospace" fontSize="22" letterSpacing="2">
        <text>03 · TED</text>
      </g>
      <line x1="56" y1="92" x2="200" y2="92" stroke={amber} strokeWidth="2"/>

      {/* Hero word */}
      <text x="56" y="450" fill={amber} fontFamily="Fraunces, serif" fontWeight="500"
        fontSize="320" letterSpacing="-14">Wait.</text>

      {/* Subtitle hint */}
      <text x="62" y="520" fill="rgba(255,255,255,0.55)" fontFamily="Fraunces, serif" fontStyle="italic" fontSize="32">
        — inside the procrastinator's mind
      </text>

      {/* Bottom-left credit */}
      <g transform="translate(56,648)" fontFamily="JetBrains Mono, monospace">
        <text fill="rgba(255,255,255,0.42)" fontSize="18" letterSpacing="2">TIM URBAN</text>
        <text y="26" fill="rgba(255,255,255,0.32)" fontSize="14" letterSpacing="1.5">14:04 · CEFR B2 · 2016</text>
      </g>

      {/* Right: clock face line drawing */}
      <g transform="translate(1060,360)" stroke={amber} strokeWidth="2.5" fill="none" opacity="0.85" strokeLinecap="round">
        <circle cx="0" cy="0" r="105"/>
        {/* Hour ticks */}
        {Array.from({length: 12}).map((_, i) => {
          const a = (i * 30 - 90) * Math.PI / 180;
          const r1 = 95, r2 = 105;
          return <line key={i}
            x1={Math.cos(a) * r1} y1={Math.sin(a) * r1}
            x2={Math.cos(a) * r2} y2={Math.sin(a) * r2}
            strokeWidth={i % 3 === 0 ? 3 : 1.5}/>;
        })}
        {/* hands stuck at 11:50 — procrastinator's clock */}
        <line x1="0" y1="0" x2="0" y2="-66" strokeWidth="3"/>
        <line x1="0" y1="0" x2="-58" y2="-30" strokeWidth="3"/>
        <circle cx="0" cy="0" r="5" fill={amber} stroke="none"/>
      </g>

      {/* Corner ticks */}
      <Tick brand={amber} x={36} y={36} corner="tl"/>
      <Tick brand={amber} x={1244} y={36} corner="tr"/>
      <Tick brand={amber} x={36} y={684} corner="bl"/>
      <Tick brand={amber} x={1244} y={684} corner="br"/>
    </svg>
  );
}

// Small L-shaped corner registration mark
function Tick({ x, y, corner, brand }) {
  const len = 22, sw = 2.5;
  let p;
  if (corner === 'tl') p = `M${x + len} ${y} L${x} ${y} L${x} ${y + len}`;
  else if (corner === 'tr') p = `M${x - len} ${y} L${x} ${y} L${x} ${y + len}`;
  else if (corner === 'bl') p = `M${x + len} ${y} L${x} ${y} L${x} ${y - len}`;
  else p = `M${x - len} ${y} L${x} ${y} L${x} ${y - len}`;
  return <path d={p} stroke={brand} strokeWidth={sw} fill="none" strokeLinecap="round"/>;
}

window.Thumbnail = Thumbnail;
