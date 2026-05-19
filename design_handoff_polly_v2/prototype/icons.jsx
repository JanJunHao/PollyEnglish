// Shared icons for PollyEnglish — small SVGs, fill="currentColor" for easy theming.

function Icon({ name, size = 20, color, style = {}, strokeWidth = 1.8 }) {
  const sw = strokeWidth;
  const c = color || 'currentColor';
  const common = { width: size, height: size, viewBox: '0 0 24 24', fill: 'none', style };

  const paths = {
    'chevron-left': <path d="M15 18l-6-6 6-6" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/>,
    'chevron-right': <path d="M9 6l6 6-6 6" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/>,
    'play': <path d="M6 4l14 8-14 8V4z" fill={c}/>,
    'pause': <g fill={c}><rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/></g>,
    'more': <g fill={c}><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></g>,
    'sparkles': <g fill={c}><path d="M12 2l1.7 4.3L18 8l-4.3 1.7L12 14l-1.7-4.3L6 8l4.3-1.7L12 2z"/><path d="M19 14l.8 2.2L22 17l-2.2.8L19 20l-.8-2.2L16 17l2.2-.8L19 14z"/></g>,
    'star': <path d="M12 2l3 7h7l-5.5 4.5L18 21l-6-4-6 4 1.5-7.5L2 9h7l3-7z" stroke={c} strokeWidth={sw} strokeLinejoin="round" fill="none"/>,
    'star-filled': <path d="M12 2l3 7h7l-5.5 4.5L18 21l-6-4-6 4 1.5-7.5L2 9h7l3-7z" fill={c}/>,
    'volume': <g stroke={c} strokeWidth={sw} fill="none" strokeLinecap="round" strokeLinejoin="round"><path d="M11 5L6 9H2v6h4l5 4V5z"/><path d="M15.5 8.5a5 5 0 010 7"/><path d="M18.5 5.5a9 9 0 010 13"/></g>,
    'close': <path d="M6 6l12 12M18 6L6 18" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round"/>,
    'back10': <g stroke={c} strokeWidth={sw} fill="none" strokeLinecap="round" strokeLinejoin="round"><path d="M3 12a9 9 0 109-9"/><path d="M12 3L8 6l4 3"/><text x="12" y="16" fill={c} stroke="none" fontSize="9" fontWeight="700" fontFamily="-apple-system" textAnchor="middle">10</text></g>,
    'forward10': <g stroke={c} strokeWidth={sw} fill="none" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12a9 9 0 11-9-9"/><path d="M12 3l4 3-4 3"/><text x="12" y="16" fill={c} stroke="none" fontSize="9" fontWeight="700" fontFamily="-apple-system" textAnchor="middle">10</text></g>,
    'prev-sentence': <g fill={c}><path d="M11 5L4 12l7 7V5z"/><path d="M20 5l-7 7 7 7V5z"/></g>,
    'next-sentence': <g fill={c}><path d="M13 5l7 7-7 7V5z"/><path d="M4 5l7 7-7 7V5z"/></g>,
    'auto-scroll': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><path d="M12 4v14M5 11l7 7 7-7"/></g>,
    'list': <g stroke={c} strokeWidth={sw} strokeLinecap="round"><line x1="4" y1="6" x2="20" y2="6"/><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="18" x2="20" y2="18"/></g>,
    'fav': <path d="M12 3v18M3 12h18" stroke={c} strokeWidth={sw} strokeLinecap="round"/>,
    'search': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"><circle cx="11" cy="11" r="6"/><path d="M20 20l-4-4"/></g>,
    'expand': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><path d="M4 14v6h6M20 10V4h-6M4 20l7-7M20 4l-7 7"/></g>,
    'mic': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0014 0M12 18v3"/></g>,
    'loop': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><path d="M17 2l4 4-4 4M3 12V8a4 4 0 014-4h14M7 22l-4-4 4-4M21 12v4a4 4 0 01-4 4H3"/></g>,
    'speed': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="13" r="8"/><path d="M12 13l4-3M12 3v2"/></g>,
    'ab': <g fill={c} fontFamily="-apple-system" fontSize="9" fontWeight="700"><text x="6" y="14">A</text><text x="13" y="14">B</text></g>,
    'subtitle': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"><rect x="3" y="6" width="18" height="12" rx="2"/><path d="M7 11h4M13 11h4M7 15h2M11 15h6"/></g>,
    'compass': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5.5-5.5 2 2-5.5 5.5-2z" fill={c} stroke="none"/></g>,
    'person': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-8 8-8s8 3.6 8 8"/></g>,
    'settings': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 11-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 11-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 11-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 110-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 112.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 114 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 112.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 110 4h-.09a1.65 1.65 0 00-1.51 1z"/></g>,
    'book': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><path d="M4 19.5A2.5 2.5 0 016.5 17H20V3H6.5A2.5 2.5 0 004 5.5v14z"/><path d="M4 19.5A2.5 2.5 0 016.5 22H20"/></g>,
    'bookmark': <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2v16z" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/>,
    'chart': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><line x1="4" y1="20" x2="4" y2="10"/><line x1="10" y1="20" x2="10" y2="4"/><line x1="16" y1="20" x2="16" y2="14"/><line x1="3" y1="20" x2="21" y2="20"/></g>,
    'target': <g fill="none" stroke={c} strokeWidth={sw}><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.5" fill={c}/></g>,
    'filter': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><line x1="4" y1="7" x2="20" y2="7"/><line x1="7" y1="12" x2="17" y2="12"/><line x1="10" y1="17" x2="14" y2="17"/></g>,
    'folder': <path d="M3 7a2 2 0 012-2h4l2 3h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V7z" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/>,
    'photo': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8.5" cy="10" r="1.5"/><path d="M21 16l-5-5-9 9"/></g>,
    'youtube': <g fill="none"><rect x="2" y="6" width="20" height="12" rx="3" fill={c}/><path d="M10 9.5l5 2.5-5 2.5v-5z" fill="#0a0a0c"/></g>,
    'link': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><path d="M10 14a4 4 0 005.66 0l3-3a4 4 0 00-5.66-5.66l-1 1"/><path d="M14 10a4 4 0 00-5.66 0l-3 3a4 4 0 005.66 5.66l1-1"/></g>,
    'plus': <g stroke={c} strokeWidth={sw + 0.4} strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></g>,
    'upload': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v3a3 3 0 01-3 3H6a3 3 0 01-3-3v-3"/><path d="M12 3v13M7 8l5-5 5 5"/></g>,
    'spinner': <g fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"><path d="M21 12a9 9 0 11-6.219-8.56" opacity="1"/></g>,
    'globe': <g fill="none" stroke={c} strokeWidth={sw}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 010 18M12 3a14 14 0 000 18"/></g>,
  };

  return <svg {...common}>{paths[name] || null}</svg>;
}

window.Icon = Icon;
