#!/usr/bin/env python3
"""批量翻译 SubtitleDocument JSON 的所有 segment translation 字段。
分批调 gpt-4o-mini（aaai.vip 网关），合并结果写回原文件。

用法：
  source Polly/Polly/Config/Secrets.xcconfig
  python3 scripts/translate_subtitles.py Polly/Resources/Subtitles/demo-julian-treasure.json "How to speak so that people want to listen by Julian Treasure"
"""
import json
import os
import sys
import time
from pathlib import Path

import urllib.request
import urllib.error


BATCH_SIZE = 30  # 每批 30 句
MODEL = "gpt-4o-mini"


def translate_batch(token: str, base_url: str, video_title: str, batch: list[dict]) -> list[str]:
    prompt = f"""把下面这些英文句子翻译成地道、口语化的中文。
背景：来自 TED 演讲《{video_title}》。每句保持简短，符合学习者快速阅读。

英文：
"""
    for idx, seg in enumerate(batch, 1):
        prompt += f"{idx}. {seg['text']}\n"

    prompt += f"""
严格输出 JSON 数组（不要 markdown 包裹），每项格式 {{"id": 序号, "zh": "中文"}}，共 {len(batch)} 项：
"""

    body = {
        "model": MODEL,
        "max_tokens": 2400,
        "temperature": 0.3,
        "messages": [
            {"role": "system", "content": "你是专业英中翻译，输出严格 JSON。"},
            {"role": "user", "content": prompt},
        ],
    }

    req = urllib.request.Request(
        f"{base_url}/chat/completions",
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.loads(resp.read().decode("utf-8"))

    raw = result["choices"][0]["message"]["content"].strip()
    # 去 markdown 包裹
    if raw.startswith("```"):
        raw = "\n".join(raw.split("\n")[1:-1])
    # 截取第一个 [ 到最后一个 ]
    if "[" in raw and "]" in raw:
        raw = raw[raw.index("["): raw.rindex("]") + 1]

    parsed = json.loads(raw)
    # 按 id 排序，返回 zh 列表
    by_id = {p["id"]: p["zh"] for p in parsed}
    return [by_id.get(i + 1, "") for i in range(len(batch))]


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <json-path> <video-title>", file=sys.stderr)
        sys.exit(1)

    path = Path(sys.argv[1])
    video_title = sys.argv[2]

    token = os.environ.get("ANTHROPIC_AUTH_TOKEN", "")
    base_url = os.environ.get("ANTHROPIC_BASE_URL", "https://api.aaai.vip/v1")
    if not token:
        print("ERROR: ANTHROPIC_AUTH_TOKEN env var not set. Run: source Polly/Polly/Config/Secrets.xcconfig", file=sys.stderr)
        sys.exit(1)

    doc = json.loads(path.read_text(encoding="utf-8"))
    segments = doc["segments"]

    total_batches = (len(segments) + BATCH_SIZE - 1) // BATCH_SIZE
    for batch_idx, start in enumerate(range(0, len(segments), BATCH_SIZE), 1):
        batch = segments[start: start + BATCH_SIZE]
        print(f"[{batch_idx}/{total_batches}] translating {len(batch)} segments...", flush=True)
        try:
            translations = translate_batch(token, base_url, video_title, batch)
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8")
            print(f"  HTTP {e.code}: {err_body[:200]}", file=sys.stderr)
            sys.exit(2)
        except Exception as e:
            print(f"  Failed: {e}", file=sys.stderr)
            time.sleep(2)
            continue

        for seg, zh in zip(batch, translations):
            seg["translation"] = zh

        # 每批写一次，万一中断仍有部分进度
        path.write_text(json.dumps(doc, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"✓ Done. Translations saved to {path}")


if __name__ == "__main__":
    main()
