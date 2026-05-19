// theme.jsx — Derive theme-aware tweaks (text-readable brand variants for light mode)
// Components consume CSS vars for surfaces/text; brand colors flow through tweaks.

function mkTheme(t) {
  const isLight = t.theme === 'light';

  // Brand & AI colors used for FILLS (button bg, glow bg) stay the same in both modes —
  // a yellow play button works on both bg's, and translucent chips already adapt.
  // For TEXT on light bg, the pale yellow becomes invisible, so derive a deeper variant.
  const brand = t.brandColor;
  const ai = t.aiColor;
  const brandText = isLight ? '#A57400' : brand;
  const aiText    = isLight ? '#4054C2' : ai;

  return {
    ...t,
    isLight,
    brand,
    ai,
    brandText,
    aiText,
  };
}

window.mkTheme = mkTheme;
