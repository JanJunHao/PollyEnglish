#!/usr/bin/env python3
"""把 YouTube vtt（英文字级 + 可选中文句级）转成 Polly SubtitleDocument JSON。

策略：
- 英文 vtt 提供字级时间戳（YouTube auto-caption 标准格式 `<HH:MM:SS.ms><c> word</c>`）
- 中文 vtt（可选）提供 TED 官方人工翻译，按完整句子分段
- 用中文 cue 的时间窗口作为 segment 边界，组装出"完整句子 + 字级时间戳 + 中文翻译"

用法：
  python3 scripts/vtt_to_subtitles.py <en-vtt> <out-json> <video-id> [zh-vtt]
"""
import json
import re
import sys
from pathlib import Path


def parse_time(ts: str) -> float:
    h, m, s = ts.split(":")
    return int(h) * 3600 + int(m) * 60 + float(s)


def parse_en_words(path: Path) -> list[tuple[float, float, str]]:
    """从英文 vtt 提取去重排序的字级 words: [(start, end, word)]"""
    content = path.read_text(encoding="utf-8")
    blocks = content.split("\n\n")[1:]
    seen: set[tuple[float, str]] = set()
    timed: list[list] = []  # [start, end=None, word]

    for block in blocks:
        lines = block.strip().split("\n")
        if not lines or "-->" not in lines[0]:
            continue
        m = re.match(r"(\d+:\d+:\d+\.\d+)\s*-->\s*(\d+:\d+:\d+\.\d+)", lines[0])
        if not m:
            continue
        cue_start = parse_time(m.group(1))

        text_line = next((ln for ln in lines[1:] if "<c>" in ln), None)
        if not text_line:
            continue
        text_line = text_line.lstrip()

        first_m = re.match(r"^([A-Za-z0-9'\-\.]+)", text_line)
        if first_m:
            w_str = first_m.group(1)
            key = (round(cue_start, 2), w_str)
            if key not in seen:
                seen.add(key)
                timed.append([cue_start, None, w_str])
            text_line = text_line[first_m.end():]

        for ts_str, w_str in re.findall(
            r"<(\d+:\d+:\d+\.\d+)><c>\s*([A-Za-z0-9'\-\.]+)\s*</c>",
            text_line,
        ):
            ts = parse_time(ts_str)
            key = (round(ts, 2), w_str)
            if key not in seen:
                seen.add(key)
                timed.append([ts, None, w_str])

    timed.sort(key=lambda x: x[0])
    for i in range(len(timed) - 1):
        timed[i][1] = timed[i + 1][0]
    if timed:
        timed[-1][1] = timed[-1][0] + 0.3

    return [(s, e, w) for s, e, w in timed]


def parse_zh_cues(path: Path) -> list[tuple[float, float, str]]:
    """从中文 vtt 提取句级 cues。过滤 metadata（翻译人员/校对人员行）。"""
    content = path.read_text(encoding="utf-8")
    blocks = content.split("\n\n")[1:]
    cues: list[tuple[float, float, str]] = []

    for block in blocks:
        lines = block.strip().split("\n")
        if not lines or "-->" not in lines[0]:
            continue
        m = re.match(r"(\d+:\d+:\d+\.\d+)\s*-->\s*(\d+:\d+:\d+\.\d+)", lines[0])
        if not m:
            continue
        start = parse_time(m.group(1))
        end = parse_time(m.group(2))
        text = "\n".join(lines[1:]).strip()
        if not text or "翻译人员" in text or "校对人员" in text or "译者" in text:
            continue
        cues.append((start, end, text))

    return cues


def build_segments_with_zh(en_words: list[tuple[float, float, str]],
                            zh_cues: list[tuple[float, float, str]]) -> list[dict]:
    segments: list[dict] = []
    for i, (zh_s, zh_e, zh_text) in enumerate(zh_cues):
        # 下一中文 cue 起点作为本句结束（避免相邻 cue 时间重叠）
        next_start = zh_cues[i + 1][0] if i + 1 < len(zh_cues) else float("inf")
        end_bound = min(zh_e, next_start)

        # 取此时间窗内的英文 words
        seg_words = [(s, e, w) for s, e, w in en_words if zh_s <= s < end_bound]
        if not seg_words:
            continue

        en_text = " ".join(w for _, _, w in seg_words)
        segments.append({
            "id": len(segments),
            "start": seg_words[0][0],
            "end": min(seg_words[-1][1], end_bound),
            "text": en_text,
            "translation": zh_text,
            "words": [{"w": w, "s": s, "e": e} for s, e, w in seg_words],
        })

    return segments


def build_segments_no_zh(en_words: list[tuple[float, float, str]]) -> list[dict]:
    """无中文时按 ~6 词一段分组"""
    GROUP = 8
    segments: list[dict] = []
    for i in range(0, len(en_words), GROUP):
        group = en_words[i: i + GROUP]
        text = " ".join(w for _, _, w in group)
        segments.append({
            "id": len(segments),
            "start": group[0][0],
            "end": group[-1][1],
            "text": text,
            "translation": None,
            "words": [{"w": w, "s": s, "e": e} for s, e, w in group],
        })
    return segments


def main():
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <en-vtt> <out-json> <video-id> [zh-vtt]", file=sys.stderr)
        sys.exit(1)

    en_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    video_id = sys.argv[3]
    zh_path = Path(sys.argv[4]) if len(sys.argv) > 4 else None

    en_words = parse_en_words(en_path)
    print(f"  English words: {len(en_words)}")

    if zh_path and zh_path.exists():
        zh_cues = parse_zh_cues(zh_path)
        print(f"  Chinese cues : {len(zh_cues)}")
        segments = build_segments_with_zh(en_words, zh_cues)
    else:
        segments = build_segments_no_zh(en_words)

    doc = {
        "video_id": video_id,
        "language": "en",
        "segments": segments,
    }
    out_path.write_text(json.dumps(doc, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"✓ {len(segments)} segments → {out_path}")


if __name__ == "__main__":
    main()
