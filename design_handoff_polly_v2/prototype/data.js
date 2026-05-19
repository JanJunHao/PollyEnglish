// PollyEnglish demo data — first ~20 segments of Julian Treasure's "How to speak so that people want to listen"
// + word entries + AI explanation. Pulled from the iOS app's Resources/Subtitles JSON.

window.SUBTITLES = [
  { id: 0,  s: 14.08, e: 16.07,  text: "the human voice it's", tr: "人类的声音：",
    words: [["the",14.08,14.24],["human",14.24,14.92],["voice",14.92,15.92],["it's",15.92,16.16]] },
  { id: 1,  s: 16.16, e: 17.99,  text: "the instrument we all play", tr: "是我们所有人都弹奏的乐器。",
    words: [["the",16.16,16.24],["instrument",16.24,16.72],["we",16.72,16.88],["all",16.88,17.04],["play",17.04,18.48]] },
  { id: 2,  s: 18.48, e: 20.35,  text: "it's the most powerful sound in the world probably", tr: "可能是这个世界上最有力的声音。",
    words: [["it's",18.48,18.72],["the",18.72,18.8],["most",18.8,19.04],["powerful",19.04,19.36],["sound",19.36,19.6],["in",19.6,19.68],["the",19.68,19.76],["world",19.76,20.0],["probably",20.0,20.4]] },
  { id: 3,  s: 20.4,  e: 22.12,  text: "it's the only one that can start a war or", tr: "它绝无仅有，或能引起战争，",
    words: [["it's",20.4,20.56],["the",20.56,20.64],["only",20.64,20.8],["one",20.8,20.96],["that",20.96,21.04],["can",21.04,21.28],["start",21.28,21.52],["a",21.52,21.68],["war",21.68,22.08],["or",22.08,22.32]] },
  { id: 4,  s: 22.32, e: 23.94,  text: "say i love you and", tr: "或能说「我爱你」。",
    words: [["say",22.32,22.64],["i",22.64,22.8],["love",22.8,23.04],["you",23.04,23.92],["and",23.92,24.08]] },
  { id: 5,  s: 24.08, e: 25.82,  text: "yet many people have the experience that when they", tr: "然而，很多人有这种经历，",
    words: [["yet",24.08,24.32],["many",24.32,24.56],["people",24.56,24.72],["have",24.72,24.88],["the",24.88,25.04],["experience",25.04,25.44],["that",25.44,25.6],["when",25.6,25.76],["they",25.76,25.92]] },
  { id: 6,  s: 25.92, e: 28.21,  text: "speak people don't listen to them", tr: "当他们说的时候，人们并不在听。",
    words: [["speak",25.92,26.48],["people",26.48,26.8],["don't",26.8,27.04],["listen",27.04,27.28],["to",27.28,27.44],["them",27.44,28.4]] },
  { id: 7,  s: 28.4,  e: 29.35,  text: "why is that", tr: "这是为什么呢？",
    words: [["why",28.4,28.64],["is",28.64,28.88],["that",28.88,29.36]] },
  { id: 8,  s: 29.36, e: 31.02,  text: "how can we speak powerfully", tr: "我们怎样有力地说",
    words: [["how",29.36,29.52],["can",29.52,29.68],["we",29.68,29.84],["speak",29.84,30.16],["powerfully",30.16,31.12]] },
  { id: 9,  s: 31.12, e: 33.14,  text: "to make change in the world", tr: "而让世界发生某种改变？",
    words: [["to",31.12,31.44],["make",31.44,31.68],["change",31.68,32.32],["in",32.32,32.48],["the",32.48,32.56],["world",32.56,33.44]] },
  { id: 10, s: 33.44, e: 35.13,  text: "what i'd like to suggest there are a number", tr: "我所提议的是，",
    words: [["what",33.44,33.68],["i'd",33.68,33.76],["like",33.76,33.92],["to",33.92,34.08],["suggest",34.08,34.56],["there",34.56,34.8],["are",34.8,35.04],["a",35.04,35.12],["number",35.12,35.36]] },
  { id: 11, s: 35.36, e: 36.97,  text: "of habits that we need to move away from", tr: "我们需要改变一些习惯。",
    words: [["of",35.36,35.44],["habits",35.44,35.84],["that",35.84,35.92],["we",35.92,36.08],["need",36.08,36.24],["to",36.24,36.32],["move",36.32,36.56],["away",36.56,36.8],["from",36.8,37.76]] },
  { id: 12, s: 37.76, e: 39.31,  text: "assembled for your pleasure here", tr: "在此我为你们收集整理了，",
    words: [["assembled",37.76,38.24],["for",38.24,38.4],["your",38.4,38.8],["pleasure",38.8,39.2],["here",39.2,39.44]] },
  { id: 13, s: 39.44, e: 41.44,  text: "seven deadly sins of speaking", tr: "说话的七宗罪。",
    words: [["seven",39.44,39.84],["deadly",39.84,40.24],["sins",40.24,40.56],["of",40.56,40.72],["speaking",40.72,41.44]] },
  { id: 14, s: 41.6,  e: 43.88,  text: "i'm not pretending this is an exhaustive list", tr: "我没打算假装这是一个详细的列表，",
    words: [["i'm",41.6,41.76],["not",41.76,42.0],["pretending",42.0,42.6],["this",42.6,42.8],["is",42.8,42.96],["an",42.96,43.12],["exhaustive",43.12,43.6],["list",43.6,44.0]] },
  { id: 15, s: 44.48, e: 46.51,  text: "but these seven i think are pretty large", tr: "但这七个，我以为是相当大的",
    words: [["but",44.48,44.6],["these",44.6,44.72],["seven",44.72,44.96],["i",44.96,45.12],["think",45.12,45.36],["are",45.36,45.52],["pretty",45.52,45.84],["large",45.84,46.88]] },
];

// Word dictionary — pulled from Polly's words.json (subset)
window.WORDS = {
  "voice": {
    phonetic: "/vɔɪs/", level: "A2",
    defs: [
      { pos: "n.", meaning: "声音；嗓音；说话声" },
      { pos: "v.", meaning: "表达；说出（意见或情感）" },
    ],
    collocations: ["raise one's voice", "in a low voice", "find one's voice"],
  },
  "powerful": {
    phonetic: "/ˈpaʊə.fəl/", level: "B1",
    defs: [
      { pos: "adj.", meaning: "强大的；有力的；有影响力的" },
      { pos: "adj.", meaning: "（情感、效果）强烈的；震撼人心的" },
    ],
    collocations: ["powerful argument", "powerful speech", "powerful effect"],
  },
  "instrument": {
    phonetic: "/ˈɪn.strə.mənt/", level: "B1",
    defs: [
      { pos: "n.", meaning: "乐器" },
      { pos: "n.", meaning: "工具；仪器；手段" },
    ],
    collocations: ["musical instrument", "an instrument of change"],
  },
  "human": {
    phonetic: "/ˈhjuː.mən/", level: "A2",
    defs: [
      { pos: "adj.", meaning: "人类的；人的" },
      { pos: "n.", meaning: "人；人类" },
    ],
    collocations: ["human being", "human nature", "human voice"],
  },
  "sound": {
    phonetic: "/saʊnd/", level: "A1",
    defs: [
      { pos: "n.", meaning: "声音；声响" },
      { pos: "v.", meaning: "听起来；发出声音" },
      { pos: "adj.", meaning: "可靠的；合理的" },
    ],
    collocations: ["the sound of", "sound asleep", "sound advice"],
  },
  "world": {
    phonetic: "/wɜːld/", level: "A1",
    defs: [
      { pos: "n.", meaning: "世界；地球" },
      { pos: "n.", meaning: "领域；圈子" },
    ],
    collocations: ["around the world", "the natural world"],
  },
  "experience": {
    phonetic: "/ɪkˈspɪə.ri.əns/", level: "B1",
    defs: [
      { pos: "n.", meaning: "经历；经验；体验" },
      { pos: "v.", meaning: "经历；体验；感受到" },
    ],
    collocations: ["have an experience", "from experience", "experience life"],
  },
  "habits": {
    phonetic: "/ˈhæb.ɪts/", level: "A2",
    defs: [
      { pos: "n.", meaning: "习惯；习性（复数）" },
    ],
    collocations: ["good habits", "bad habits", "break a habit"],
  },
  "exhaustive": {
    phonetic: "/ɪɡˈzɔː.stɪv/", level: "C1",
    defs: [
      { pos: "adj.", meaning: "详尽的；彻底的；无遗漏的" },
    ],
    collocations: ["exhaustive list", "exhaustive research", "exhaustive analysis"],
  },
  "deadly": {
    phonetic: "/ˈded.li/", level: "B2",
    defs: [
      { pos: "adj.", meaning: "致命的；致死的" },
      { pos: "adj.", meaning: "极其的；非常的（强调）" },
    ],
    collocations: ["deadly weapon", "deadly serious", "seven deadly sins"],
  },
  "speak": {
    phonetic: "/spiːk/", level: "A1",
    defs: [
      { pos: "v.", meaning: "说；说话；讲（语言）" },
      { pos: "v.", meaning: "演讲；发言" },
    ],
    collocations: ["speak English", "speak up", "speak out"],
  },
  "powerfully": {
    phonetic: "/ˈpaʊə.fəl.i/", level: "B2",
    defs: [
      { pos: "adv.", meaning: "强有力地；有效地" },
    ],
    collocations: ["speak powerfully", "act powerfully"],
  },
};

// AI explanations — keyed by segment id
window.AI_EXPLANATIONS = {
  2: {
    natural: "可能是这世界上最有力量的声音。",
    core: "Treasure 用 \"the most powerful\" 而非 \"a powerful\" — 加上定冠词形成最高级断言，配合句末 \"probably\" 又留一丝克制的余地。这种「先抛重磅、再轻轻一收」的结构，正是 TED 演讲开场常见的修辞节奏。",
    vocab: [
      { w: "powerful", note: "形容声音的影响力，而非物理音量。常与 sound / speech / argument 搭配。" },
      { w: "probably", note: "演讲中故意的「软化词」 — 让最高级断言不显得武断。" },
      { w: "sound", note: "此处不只指物理声音，而是隐喻「信号 / 表达」。" },
    ],
    culture: "Julian Treasure 是英国声学顾问，TED 上拥有过亿播放，主攻「如何让人想听你说话」这一议题。此句是他的 \"The 7 deadly sins of speaking\" 演讲开场。",
  },
  // Default fallback for other segments
};
window.AI_DEFAULT = {
  natural: "（地道翻译生成中…）",
  core: "这个句子在演讲中起到承接作用 —— 把听众的注意力从抽象概念过渡到具体的「七宗罪」列表。注意 Treasure 用了大量短句和停顿，这是 TED 演讲家训练出的节奏感。",
  vocab: [
    { w: "habit", note: "习惯。注意它的复数 habits 在这里指「一系列做法」。" },
    { w: "speak", note: "可作及物或不及物。speak English（讲英语）/ speak up（大声说）。" },
  ],
  culture: "TED 演讲对「开场前 30 秒」有强约定 —— 必须建立 stakes（利害关系）。Treasure 用 \"war / I love you\" 这种极端例子，正是这套训练的体现。",
};
