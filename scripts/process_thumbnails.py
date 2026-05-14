#!/usr/bin/env python3
"""在 YouTube 原图基础上做品牌化处理：
- 4 个角强遮罩盖 TED/TED-Ed logo
- 底部强渐变让 banner 文字区清晰
- 整体轻微暖色叠加统一风格

所有遮罩用 L 模式 mask + Image.composite(black, img, mask) 直接覆盖（更可靠）。
"""
import urllib.request
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter


VIDEOS = [
    ("julian-treasure-maxresdefault", "eIho2S0ZahI"),
    ("ted-ed-dream-maxresdefault",    "2W85Dwxx218"),
    ("tim-urban-maxresdefault",       "arj7oStGLkU"),
]

THUMBS = Path(__file__).resolve().parent.parent / "Polly" / "Resources" / "Thumbnails"


def process(out: Path, video_id: str):
    url = f"https://i.ytimg.com/vi/{video_id}/maxresdefault.jpg"
    print(f"  Downloading {url}")
    raw = urllib.request.urlopen(url, timeout=30).read()
    tmp_path = out.with_suffix(".raw.jpg")
    tmp_path.write_bytes(raw)

    img = Image.open(tmp_path).convert("RGB")
    W, H = img.size

    # === 1. 4 角矩形遮罩盖 logo（更大覆盖区，避免椭圆漏角）===
    corner_mask = Image.new("L", (W, H), 0)
    cd = ImageDraw.Draw(corner_mask)
    sw = int(W * 0.30)   # 30% 宽
    sh_bot = int(H * 0.38)  # 底部矩形高 38%（覆盖 TED logo + 上一些）
    sh_top = int(H * 0.25)  # 顶部矩形高 25%
    # 左下（TED 标准位置）
    cd.rectangle([0, H - sh_bot, sw, H], fill=255)
    # 右下
    cd.rectangle([W - sw, H - sh_bot, W, H], fill=255)
    # 右上（TED-Ed 标准位置）
    cd.rectangle([W - sw, 0, W, sh_top], fill=255)
    # 左上（稍弱）
    cd.rectangle([0, 0, sw, sh_top], fill=200)
    # 强高斯模糊柔化（覆盖到中央方向有渐变）
    corner_mask = corner_mask.filter(ImageFilter.GaussianBlur(radius=int(W * 0.07)))

    black = Image.new("RGB", (W, H), (0, 0, 0))
    img = Image.composite(black, img, corner_mask)

    # === 2. 底部强渐变 ===
    bottom_mask = Image.new("L", (1, H), 0)
    bd = ImageDraw.Draw(bottom_mask)
    for y in range(int(H * 0.48), H):
        t = max(0.0, (y - H * 0.48) / (H * 0.52))
        alpha = int(245 * (t ** 1.3))
        bd.rectangle([0, y, 1, y + 1], fill=alpha)
    bottom_mask = bottom_mask.resize((W, H))
    img = Image.composite(black, img, bottom_mask)

    # === 3. 顶部弱渐变 ===
    top_mask = Image.new("L", (1, H), 0)
    td = ImageDraw.Draw(top_mask)
    for y in range(int(H * 0.20)):
        t = 1 - y / (H * 0.20)
        alpha = int(170 * t)
        td.rectangle([0, y, 1, y + 1], fill=alpha)
    top_mask = top_mask.resize((W, H))
    img = Image.composite(black, img, top_mask)

    # === 4. 整体轻微暖色叠加（5%）统一风格 ===
    warm = Image.new("RGB", (W, H), (255, 200, 130))
    img = Image.blend(img, warm, 0.04)

    img.save(out, quality=90, optimize=True)
    tmp_path.unlink()
    print(f"  ✓ {out.name}")


def main():
    THUMBS.mkdir(parents=True, exist_ok=True)
    for name, vid in VIDEOS:
        process(THUMBS / f"{name}.jpg", vid)
    print("✓ All thumbnails processed")


if __name__ == "__main__":
    main()
