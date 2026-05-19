# Polly v2 设计交付 · 给 iOS / SwiftUI 工程的 handoff

> 本目录里的 HTML / JSX 文件是 **设计参考稿**（hi-fi 可交互原型），不是用来直接复制粘贴的生产代码。本文档说明如何把这些设计在你现有的 SwiftUI 工程里**重新实现**，沿用 `Polly/Polly/Features/...` 的既有架构、命名规范、token 体系。

## Overview

第二轮设计在第一轮（深色精读 demo）基础上做了以下扩展：

1. **新增浅色模式** — 整套 dark / light 主题切换，对标 YouTube 等成熟产品的 UX
2. **首页信息架构升级** — 加入顶部分类 tab、6 个内容区块、外刊图文 / 最近更新混合流
3. **新增第二个底部 tab「文件」** — 把视频导入流程从 sheet 升级成独立 tab
4. **新增"我的"tab** — profile 头 + 学习数据 + 历史 + 偏好
5. **完善列表页** — 词汇本、收藏的句子、精选课程库
6. **统一新交付** — 字幕设置、跟读练习两张 sheet 设计统一化

**Fidelity**：高保真。颜色、字号、间距、动画曲线、交互行为都是 production-ready 的。

---

## 主题系统（最先实现）

### Token 表（新增/更新 `AppTheme.swift`）

| Token | Dark | Light | 用途 |
|---|---|---|---|
| `bg` | `#0a0a0c` | `#f4f1ec` | 页面主背景 |
| `surface` | `rgba(255,255,255,0.04)` | `#ffffff` | 卡片表面（含 list row） |
| `surfaceSubtle` | `rgba(255,255,255,0.025)` | `rgba(10,10,12,0.025)` | 浅微妙背景 |
| `surfaceElev` | `rgba(20,20,24,0.97)` | `#ffffff` | 浮层（WordCard / AICard / sheet） |
| `text` | `#ffffff` | `#0a0a0c` | 主要文字 |
| `textSec` | `rgba(255,255,255,0.62)` | `rgba(10,10,12,0.62)` | 次要文字 |
| `textTer` | `rgba(255,255,255,0.42)` | `rgba(10,10,12,0.42)` | 辅助文字 |
| `textMuted` | `rgba(255,255,255,0.28)` | `rgba(10,10,12,0.25)` | 最弱文字 |
| `divider` | `rgba(255,255,255,0.06)` | `rgba(10,10,12,0.08)` | 分隔线 |
| `dividerStrong` | `rgba(255,255,255,0.12)` | `rgba(10,10,12,0.16)` | 较深分隔 |
| `chipBg` | `rgba(255,255,255,0.06)` | `rgba(10,10,12,0.045)` | chip 默认底 |
| `chipBgActive` | `rgba(255,255,255,0.10)` | `rgba(10,10,12,0.10)` | chip 按下/激活底 |
| `overlay` | `rgba(0,0,0,0.5)` | `rgba(0,0,0,0.35)` | 模态遮罩 |
| `tabBarBg` | `rgba(10,10,12,0.82)` | `rgba(244,241,236,0.85)` | tab bar 底 |
| `shadowCard` | `0 8px 32px rgba(0,0,0,0.55)` | `0 6px 22px rgba(0,0,0,0.10)` | 卡片阴影 |

### 品牌色派生（**关键**）

主品牌色 `#FFE066`（亮黄）在浅色模式的白底上**几乎不可见**。需要派生一对 text 变体：

| 用途 | Dark | Light |
|---|---|---|
| `brand`（填充色 — 黄色播放按钮 bg 等，两模式相同） | `#FFE066` | `#FFE066` |
| `brandText`（文字色 — 序号 / "继续学习" 标签 / 字幕 active 词等） | `#FFE066` | `#A57400` |
| `ai`（填充） | `#B8C4FF` | `#B8C4FF` |
| `aiText`（文字） | `#B8C4FF` | `#4054C2` |

**规则**：黄色 fill 在两个模式都好看；黄色 text 在浅色模式必须用 `brandText`。同理 AI 紫蓝。

### SwiftUI 实现建议

```swift
// AppTheme.swift
enum ThemeMode: String { case dark, light }

protocol ThemeTokens {
    var bg: Color { get }
    var surface: Color { get }
    var text: Color { get }
    var textSec: Color { get }
    // ... 其余 token
    var brand: Color { get }
    var brandText: Color { get }
    var aiText: Color { get }
}

struct DarkTokens: ThemeTokens { ... }
struct LightTokens: ThemeTokens { ... }

// EnvironmentKey
extension EnvironmentValues {
    var theme: ThemeTokens { ... }
}

// 顶层
.environment(\.theme, mode == .dark ? DarkTokens() : LightTokens())
```

切换有 320ms 过渡。`withAnimation(.easeInOut(duration: 0.32))` 包住 mode 变化。

### 系统跟随建议

提供三档：`System / Dark / Light`，默认 `System`（跟随 iOS 全局深浅）。存到 `@AppStorage("theme")`。

---

## 一、底部 Tab Bar（**新结构**）

原 `RootTabView.swift` 是 2 tab，现升级为 **3 tab**：

```
探索 (compass)  ·  文件 (folder)  ·  我的 (person)
```

- 毛玻璃 + `tabBarBg` 半透明
- 激活 tab：图标 + 标签都变 `brand`（深色模式）或 `brandText`（浅色模式）— 即 active 用 `brandText`
- 高度：50pt + 安全区（30pt 内边距）

**Player / Library / Vocab / Favorites 这些页面不显示 tab bar**（push 路由覆盖）。

→ 参考：`tabbar.jsx`、`app.jsx` 路由逻辑

---

## 二、Discover Tab（首页大改）

替换 `Features/Home/HomeView.swift` 的内容结构。**移除**：
- `GreetingHeader.swift`（删除问候模块；首页直接进入内容）
- `LearningPlaceholder.swift`（"我的学习"搬到 "我的" tab）
- 顶部 newspaper masthead 装饰（中途加过又删了）

**新结构**（从上到下）：

### 2.1 顶部固定分类 tabs

`CategoryTabs`（**新组件**）— 状态栏下方固定不滚动：
```
推荐  ·  外刊  ·  最近更新
```
- 激活：17pt SemiBold White + 下方 18×3pt 黄色短下划线
- 未激活：14pt Medium `textTer`
- 切换平滑 200ms cubic-bezier
- 切换时下方内容区整块替换（**不是滚动联动**）

→ 参考：`home.jsx` 的 `CategoryTabs` 组件

### 2.2 推荐 tab 的内容（默认）

按顺序：

**(A) Banner 轮播**（替换 `TodayBannerCard.swift`）
- 全屏宽，单卡占 **94% 宽度**，左右各 **3% peek** 露相邻卡边
- 卡片间距 10pt
- 卡片高 234pt，圆角 18pt
- 非激活卡 opacity 0.55
- **小 dot 进度指示器** 放在标题块**下方**（紧跟 meta 行），active dot 14×4 胶囊，inactive 4×4 圆点
- 全画面 SVG 封面（视频缩略图，**不再是 YouTube 图**）+ 底部 60% 高度黑色渐变 (`linear-gradient(to bottom, transparent 0%, rgba(0,0,0,0.55) 55%, rgba(0,0,0,0.92) 100%)`)
- 标题（白色 16px / 600 Inter，最多 2 行）+ 元数据（`JULIAN TREASURE · 9:58 · B2` JetBrains Mono 10.5）+ 右下角 52pt 黄色圆形播放按钮
- 自动轮播 5.2s 一次，支持手势拖拽切换
- **封面图永远保持深色**（无论 dark / light 模式）—— 像 YouTube 缩略图

**(B) 热门推荐** Section
- Section title：`热门推荐` 20pt SemiBold + 右侧 `查看更多 ›` 12.5pt（页面 `查看更多 →` 进入 Course Library）
- 3 行排行榜，每行：
  - 大编号 36pt Fraunces italic（`01` 用 `brandText`，其余用 `textSec`）
  - 72×72 缩略图（圆角 10pt）
  - 标题 Inter 13.5px + meta `12.4K 人在学 · ↑ 32%`（增长率用 `#FF9F6E` 橙色）
- 各行之间 0.5px `divider`

→ 参考：`home.jsx` `TrendingRow` 组件

**(C) 热门精选** Section + 横滑课程卡

- Section title 同上 + `查看更多 ›`
- 横滑容器，卡片间距 12pt
- 单卡 170×220pt，圆角 14pt
- 上半：96pt SVG 缩略图
- 下半：source 标签（如 `TED`，11.5pt Fraunces italic uppercase brand 色） + 标题 13px Inter 500 + 时长等级 meta

→ 参考：`home.jsx` `CourseCard` 组件

**(D) 每日收听** Section（**全新组件**）

`DailyListeningCard`（深色卡片，**两模式都保持深色 — 像海报**）：
```
背景: linear-gradient(135deg, #161620 0%, #0a0a0c 100%)
右侧装饰: SVG 波形条（20 条不同高度的纵向矩形，brand 黄色，opacity 0.18）
左侧: 56pt 黄色圆形大播放按钮
右侧文字: 
  "DAY 7 · 以商业英语为主"   — mono 9.5pt brand
  "Today's pick"             — Fraunces 18pt italic 500 白色
  "How to speak so that..."  — Inter 13pt 500 白色
  "9:58 · B2"                — mono 10pt textTer
```
→ 参考：`home.jsx` `DailyListeningCard`

**(E) 最新上架** Section + 横滑卡

`NewArrivalCard`，结构同 CourseCard 但加：
- 第一张左上角红色 `NEW` 徽章（4×3pt 圆角，`#FF6E6E` 底，9pt 白字 mono）
- 卡片底部加一行：`● 上架于 今天` / `昨天` / `3 天前`（黄圆点 + 9.5pt mono `textTer`）

→ 参考：`home.jsx` `NewArrivalCard`

**(F) 主题探索** Section + 7 个主题 chip

横滑容器，每 chip：
- 大约 130×60pt，圆角 14pt
- 左侧 30pt 圆角方块（主题对应色 33% 不透明）+ emoji glyph（🎤/🧠/⚛/📊/☕/🎨/📰）
- 右侧：主题名 13pt SemiBold + 数量 `24 videos` mono 9.5pt

主题色（7 个，每个 chip 都不同）：
```
表达与演讲 #FFE066 🎤
心理与思维 #B8C4FF 🧠
科技与未来 #7FD4FF ⚛
商业与职场 #FF9F6E 📊
生活与日常 #A6E8C3 ☕
艺术与设计 #F0A0FF 🎨
新闻与评论 #FFB8B8 📰
```
→ 参考：`home.jsx` `TopicPill` + `HOME_TOPICS` 数据

### 2.3 外刊 tab 的内容（**全新功能**）

整页换成图文文章 feed。从 `推荐` 内容区切换到 `ArticleFeed`：

**(A) 编辑精选 Hero 卡** — 单卡占满，圆角 18pt：
- 上半 130pt 高彩色渐变区（每家出版物有自己的 accent gradient，比如 Economist 是 `linear-gradient(135deg, #E3120B → #6B0500)`）
- 上半内嵌点状纹理 + 出版物斜体 logo（Fraunces 22pt italic）+ 底部左 SECTION 标签（黑底胶囊）+ 右日期
- 下半（卡片白底）：Fraunces 22pt 标题 + Inter italic 13.5pt excerpt 摘要 + 等级徽章 + `1,240 words · 5 min read`

**(B) 最新外刊** 列表 — 横向 row：
- 左侧 64×78pt 出版物缩略色块（同样的 accent gradient + 出版物缩写 Fraunces italic 20pt 居中 + 底部 12pt 高分类胶囊）
- 右侧：出版物全名 mono 9.5pt uppercase + Fraunces 14.5 标题 + 等级 / 字数 / 时间

**(C) 合作刊源** 底部 — 一个 stat 卡：
- 包含 8 个出版物名字的小 chip（Economist / NYT / Guardian / Atlantic / BBC / New Yorker / Bloomberg / WSJ）

→ 参考：`articles.jsx`、`HOME_ARTICLES` 数据

### 2.4 最近更新 tab 的内容（**全新功能**）

混合 feed：视频 + 外刊文章按时间倒序，分日期分组。

**(A) 顶部状态条** — 黄紫渐变 + 黄色 pulse 点 + 「本周新增 N 条」+ 「全部已读」按钮

**(B) 按日期分组**（"今天" / "昨天" / "2 天前" ...）：
- Section header：日期 13pt SemiBold + 水平细线 + `N ITEMS` mono 角标
- 每个 item 卡：
  - 视频：96×64 SVG 缩略图 + 时长 pill（右下角 + 黑色 backdrop blur）+ 黄色 `视频` 徽章 + 标题 + 等级/时长/添加时间
  - 文章：96×64 出版物色块 + 紫蓝 `外刊` 徽章 + Fraunces 标题
- 新增（今天）的 item 在徽章前加红圆点

→ 参考：`recent.jsx`、`HOME_RECENT` 数据

---

## 三、Files Tab（**全新**）

`FilesScreen` — 视频导入的独立 tab，整合 `ImportLocalVideoSheet.swift` + 移除 sheet 改成全屏 tab。

**结构**：
1. 顶部：`文件` 标题 + 搜索按钮
2. Fraunces 大字 `Import a video` 32pt 500 + 提示文案
3. 两个并排导入卡（grid 1:1）：
   - 「相册视频」黄色图标 - 点击弹半屏 ImportSheet
   - 「YouTube 链接」紫蓝色图标 - 点击弹 URL 输入 sheet
4. AI 加工提示条（紫蓝渐变）：解释整个 AI 流程
5. **已导入列表**（**新功能 — 显示处理状态**）：
   - 顶部 section header：`已导入 · 3` + 右侧 `免费额度 7 / 10` mono 角标
   - 3 种状态：
     - `ready` — 缩略图位置黄色播放按钮 + 视频 meta + 右侧 chevron
     - `processing` — 紫蓝色旋转 spinner + `AI 加工中 · 生成字幕` + 进度条 + 百分比
     - `queued` — 灰色 loop 图标 + `排队中 · 等待 ASR`

→ 参考：`files.jsx`、`ImportSheet` 组件

**注意**：Sheet 入场动画 — 从底部 spring + 缩放 + 淡入，350ms cubic-bezier(.22, 1.3, .36, 1)。

---

## 四、Me Tab（重新设计 ProfileView.swift）

**结构**：
1. 顶部：`我的` 标题 + 右上角设置图标按钮
2. Profile 头：56pt 圆形渐变头像（`brand → ai` 渐变）+ Fraunces 22pt 名字 + `CEFR B1 · 学龄 7 天` mono meta
3. **学习数据** 3 格 stat grid：
   - 学习天数 7 天（黄）
   - 收藏句子 12 句（紫蓝）
   - 掌握词汇 84 词（橙 `#FF9F6E`）
   - 每格 Fraunces 24pt 500 数字 + 小单位 + 标签
4. **我的学习** Section + 「继续学习」卡（横向 row）：
   - 左 116×116 SVG 缩略图
   - 右：`继续学习` mono 9.5pt brandText + 标题 + 进度 `3:12 / 9:58 · 32%` + 黄色进度条
5. **学习资料** Section ListGroup（圆角白卡内嵌 4 行）：
   - 收藏的句子 → /favorites (`12`)
   - 词汇本 → /vocab (`84`)
   - 学习数据 → 数据页 (`详情`)
   - 学习目标 → (`每日 15 分钟`)
6. **偏好** Section ListGroup（3 行）：
   - 字幕偏好 (`英文+中文`)
   - 默认播放速度 (`1.0×`)
   - 语言 (`简体中文`)

→ 参考：`me.jsx`

---

## 五、Course Library 页（重新设计 CategoryListView.swift）

push 路由，从 Discover 的「精选课程 / 热门推荐 - 查看更多」进入。

**结构**：
1. 顶部：← 返回 + `精选课程` 居中标题
2. Fraunces `Course Library` 32pt + 视频数量副标
3. 筛选 chips：`全部 ` / `TED` / `B1 中级` / `B2 中高`，每个 chip 内嵌数字徽章
4. 视频列表（垂直堆叠，gap 14pt）：每张 200pt 高的 banner-style 卡，结构同首页 banner

→ 参考：`library.jsx`

---

## 六、Vocab 页（重新设计 VocabularyListView.swift）

push 路由，从 Me tab「词汇本」进入。

**结构**：
1. 顶部：← 返回 + `词汇本` 标题
2. Fraunces `Your vocabulary` 30pt + 统计副标（`84 WORDS · 21 MASTERED · 8 NEW`，mono 10.5pt）
3. 搜索框（chip 圆角）+ 筛选 chips（全部/新学/待复习/已掌握）
4. **2 列 grid**，每 tile：
   - Fraunces 22pt 单词
   - 音标 mono 10pt textTer
   - 释义 11.5pt 2 行省略
   - 底部：3pt 高的掌握度进度条（颜色按等级：`brand` 已掌握 / `ai` 复习中 / `#FF9F6E` 新学）+ 视频时间码 + 添加时间

→ 参考：`vocab.jsx`、`VOCAB_LIST` 数据

---

## 七、Favorites 页（重新设计 FavoritesListView.swift）

push 路由，从 Me tab「收藏的句子」进入。

**结构**：
1. 顶部：← 返回 + `收藏的句子` 标题
2. Fraunces `Saved sentences` 30pt + 统计副标
3. 卡片列表（垂直，gap 10pt）：
   - 顶行：⭐ 黄色 + `JULIAN TREASURE · 0:18` mono + 右侧添加时间
   - 句子英文（Inter 14.5pt 500）
   - 中文翻译（PingFang SC 12pt textSec）

→ 参考：`favorites.jsx`、`FAVORITES_LIST` 数据

点击进入：跳转 PlayerView 并跳到对应时间码。

---

## 八、Player 改动（增量更新）

`PlayerView.swift` 大结构不变，但有几处增量：

1. **顶部 chips toolbar** — `ChipsToolbar.swift` 加 `AI 字幕` 紫蓝徽章（视频区下、字幕区上）
2. **底部 tab bar 改交互**：
   - `字幕` 按钮 → 弹 `SubtitleSettingsSheet`（不再是 placeholder）
   - `跟读` 按钮 → 弹 `ShadowingSheet` 并传入当前句
3. **字幕列表字级高亮的颜色**改用 `brandText`（而非 `brand`），保证浅色模式可读
4. **进度条 thumb 按下** scale 11→16pt + 周围 6px 黄色光环

---

## 九、WordCard / AICard

### WordCard.swift 更新

- 单词主体 30pt Fraunces 500
- 音标按钮 + B1/B2 等级徽章（mono 10pt + `ai/aiText` 紫蓝底）
- 词性徽章 `n. / v.` 用 ai-color 22% 底 + `aiText` 文字（保持浅色可读）
- 例句**命中词高亮** — 例句中的目标词用 `brandText` 加粗
- 常见搭配 chips（Inter 11.5pt 灰底）
- 双 CTA：`完整释义`（白底深字）+ `AI 详解`（`ai` 紫蓝底 + 深字 + ✨ icon）
- 入场：spring 350ms cubic-bezier(.22, 1.3, .36, 1) 从底部弹出 30pt + scale 0.96→1 + opacity

### AICard / ExplanationCard.swift 更新

- 头部 `✨ AI 讲解` 标题 + GENERATING 状态徽章（生成中 1.2s 脉冲点 + `aiText` 文字）
- 5 段内容：原句 / 地道翻译 / 核心讲解 / 关键词汇 / 文化背景
- key_vocab 列表用 `ai` 圆点 + 单词 14pt 600 + 注释 12.5pt
- 骨架屏（loading 状态）：5 行不同宽度 shimmer 动画矩形
- 底部合规免责声明 `ⓘ 本讲解由 AI 生成…`（10.5pt textTer）

---

## 十、Sheets 设计统一化

`SubtitleSettingsSheet.swift` 和 `ShadowingSheet.swift` 用同一个 `SheetShell` 容器：

- 居中卡片，左右 12pt margin，bottom 18pt
- 顶部 drag handle（36×4 半透明胶囊）
- 标题 + 副标 + 右上 close 圆按钮
- 入场动画同 WordCard

### SubtitleSettingsSheet 内容
- 显示模式 segmented control：`仅英文` / `双语` / `仅中文`
- 英文字号 slider 13-20px
- 中文字号 slider 11-18px
- 自动滚动 toggle
- 浮动字幕 toggle
- **实时预览块**：显示三态高亮的 active word

### ShadowingSheet 内容
- 原句卡片
- 双 waveform 对比（原音 + 用户录音）
- 大录音按钮（默认黄色，录音中变红 + 脉冲方块）
- 录音结束后 AI 评分卡（Fraunces 大数字 + 紫蓝色 + 反馈文字）

→ 参考：`sheets.jsx`

---

## 视频缩略图（**重做**）

原 YouTube 缩略图（含 TED logo + 绿字 "timbre/prosody"）**全部替换**为 SVG 自制封面，统一编辑系排版：

| 视频 | 主色 | 中央字 |
|---|---|---|
| Julian Treasure | `#FFE066` 暖黄 | `VOICE`（Fraunces 288pt 500，副标 "the instrument we all play"） |
| TED-Ed Dream | `#B8C4FF` 紫蓝 | `why do we dream?`（叠层堆叠，含星点 + 大脑节点） |
| Tim Urban | `#FF9F6E` 暖琥珀 | `Wait.`（Fraunces 320pt 500，副标 "inside the procrastinator's mind"，右侧 11:50 卡住的时钟） |

每张都带 4 角 L 形 registration ticks 装饰 + 角落 `01 · TED` mono 编号 + 左下 `JULIAN TREASURE / 9:58 · CEFR B2 · 2014` mono credits。

→ 参考：`thumbs.jsx` 的 SVG 源（可直接转成 SwiftUI Canvas/Path）

---

## 动画/过渡 一览

| 场景 | duration | easing |
|---|---|---|
| Banner 轮播切换 | 580ms | `cubic-bezier(.22, 1, .36, 1)` |
| 主题切换（dark↔light） | 320ms | `easeInOut` |
| WordCard / AICard / 任何 sheet 入场 | 350ms | `cubic-bezier(.22, 1.3, .36, 1)` |
| Sheet 退场 | 220ms | linear opacity + transform |
| Banner dot 切换 | 300ms | `cubic-bezier(.22, 1, .36, 1)` |
| CategoryTabs 文字大小过渡 | 200ms | `cubic-bezier(.22, 1, .36, 1)` |
| AI generating 脉冲点 | 1200ms | `easeInOut` 无限循环 |
| Shimmer skeleton | 1400ms | linear 无限 |

---

## 字体（保持 brief 已确定的）

- `font-display`：**Fraunces** — 单词主体、品牌字、首页 Hero 标题、Section 大标题
- `font-body`：**Inter / PingFang SC** — 英文正文 Inter，中文 PingFang
- `font-mono`：**JetBrains Mono** — 时间码、徽章、技术标签、音标 IPA

---

## 工程实现建议

1. **先做主题系统** — `ThemeTokens` protocol + `EnvironmentKey`，所有 view 不再硬编码颜色
2. **然后做新 tab 结构** — 调整 `RootTabView.swift` 加 Files tab
3. **再迭代 HomeView** — 替换内容布局
4. **新建文件**：
   - `Features/Home/CategoryTabs.swift`
   - `Features/Home/TrendingRow.swift`
   - `Features/Home/DailyListeningCard.swift`
   - `Features/Home/NewArrivalCard.swift`
   - `Features/Home/TopicPill.swift`
   - `Features/Articles/` 文件夹（含 `ArticleFeed.swift`、`ArticleHero.swift`、`ArticleRow.swift`、`Article.swift` model）
   - `Features/Recent/RecentFeed.swift`
   - `Features/Files/FilesView.swift`
   - `Features/Me/MeView.swift`（替换或并行 `ProfileView.swift`）
   - `Features/Me/StatTile.swift`
   - `Features/Me/LearningCard.swift`
   - `Features/Me/ListGroup.swift` / `ListRow.swift`
5. **更新现有文件**：
   - `App/AppTheme.swift` — 加 ThemeTokens
   - `App/RootTabView.swift` — 3 tab
   - `Features/Home/HomeView.swift` — 重写
   - `Features/Home/TodayBannerCard.swift` — 改 peek 布局 + 进度 dots
   - `Features/Player/PlayerView.swift` — chip 行为
   - `Features/Player/PlayerBottomTabBar.swift` — 字幕 / 跟读按钮 wire 到 sheet
   - `Features/Player/SubtitleListView.swift` — 颜色用 brandText
   - `Features/WordCard/WordCard.swift` — 浅色模式适配
   - `Features/Explanation/ExplanationCard.swift` — 同上
   - `Features/Vocabulary/VocabularyListView.swift` — 重写
   - `Features/Favorites/FavoritesListView.swift` — 重写
   - `Features/Home/CategoryListView.swift` → 改名 `LibraryView`，重写

---

## 原型文件清单

`prototype/` 目录里是这次的可交互原型源码（HTML + React JSX）：

```
PollyEnglish.html         — 入口
app.jsx                   — 路由 + 状态
theme.jsx                 — 主题派生函数 mkTheme
home.jsx                  — 首页 + 分类 tabs + 多个 section
player.jsx                — 播放器
cards.jsx                 — WordCard + AICard
me.jsx                    — 我的 tab
library.jsx               — 课程库
vocab.jsx                 — 词汇本
favorites.jsx             — 收藏的句子
files.jsx                 — 文件 tab + 导入流程
articles.jsx              — 外刊 feed
recent.jsx                — 最近更新混合 feed
sheets.jsx                — 字幕设置 + 跟读 sheet
thumbs.jsx                — 3 张原创视频缩略图 SVG
icons.jsx                 — 全部 SVG icon
tabbar.jsx                — 底部 tab bar
data.js                   — 字幕 + 词典 + AI 讲解的演示数据
ios-frame.jsx             — iOS 设备外壳（仅用于展示，不需要移植）
tweaks-panel.jsx          — Tweaks 浮窗（仅用于展示）
```

打开 `PollyEnglish.html` 直接看效果。所有交互（点击单词、长按句子、切换主题、切 tab）都是真的能跑的。

---

## 联系

设计如有不清楚的地方，提交 issue 或直接看对应 .jsx 源码 — 排版、间距、颜色都是 inline style，对照 SwiftUI 写成 modifier 即可。
