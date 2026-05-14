#!/usr/bin/env python3
"""生成 Polly App 占位资源：AppIcon、LaunchLogo、3 张视频缩略图。
全部用 PIL 程序生成（不依赖设计师），统一深色 + 品牌黄风格。
设计师重做时直接替换 png 文件即可。
"""
import json
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "Polly" / "Resources" / "Assets.xcassets"
THUMBS = ROOT / "Polly" / "Resources" / "Thumbnails"

BG = (10, 10, 12)              # bg-primary #0A0A0C
BRAND = (255, 224, 102)        # brand-primary #FFE066
AI = (184, 196, 255)           # ai-primary #B8C4FF
WHITE = (255, 255, 255)
SUBTLE = (170, 170, 175)


def load_font(size: int, weight: str = "regular"):
    candidates = [
        "/System/Library/Fonts/Supplemental/Optima.ttc",
        "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    if weight == "bold":
        candidates = [
            "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf",
            "/System/Library/Fonts/HelveticaNeue.ttc",
        ] + candidates
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()


# ---------- App Icon (1024) ----------

def gen_app_icon(out: Path):
    size = 1024
    img = Image.new("RGB", (size, size), BG)
    d = ImageDraw.Draw(img)

    # 圆角矩形被 iOS 自动应用，icon 本身画方形

    # 中央偏左 "P" 字母 (Fraunces 风格用衬线字体)
    p_size = 700
    p_font = load_font(p_size, "bold")
    d.text((280, 130), "P", fill=BRAND, font=p_font)

    # 右下角 字幕高亮条占位（暗示"字幕字级高亮"）
    bar_y = 820
    bar_h = 14
    # 灰色字幕条
    d.rectangle([180, bar_y, 720, bar_y + bar_h], fill=(70, 70, 78))
    # 黄色 active 段
    d.rectangle([180, bar_y, 360, bar_y + bar_h], fill=BRAND)

    img.save(out, "PNG", optimize=True)
    print(f"✓ AppIcon → {out}")


# ---------- Launch Logo ----------

def gen_launch_logo(out: Path):
    """1024 宽透明 PNG，居中 Polly 字标"""
    w, h = 1024, 400
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Polly 字标
    main_size = 220
    main_font = load_font(main_size, "bold")
    text = "Polly"
    bbox = d.textbbox((0, 0), text, font=main_font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (w - tw) // 2 - bbox[0]
    y = 40
    d.text((x, y), text, fill=BRAND, font=main_font)

    # slogan
    slogan_size = 36
    slogan_font = load_font(slogan_size)
    slogan = "视频精读 · 字字精进"
    sbbox = d.textbbox((0, 0), slogan, font=slogan_font)
    sw = sbbox[2] - sbbox[0]
    sx = (w - sw) // 2 - sbbox[0]
    sy = y + th + 60
    d.text((sx, sy), slogan, fill=SUBTLE, font=slogan_font)

    img.save(out, "PNG", optimize=True)
    print(f"✓ LaunchLogo → {out}")


# ---------- 视频缩略图 ----------

def gen_thumbnail(out: Path, *, accent: tuple, illustration: str):
    """1280×720 装饰图：渐变光 + 同心圆 + 字母图徽。
    标题/副标交给 App 内 Text 渲染（避免缩放下文字模糊 + 颜色冲突）。
    """
    w, h = 1280, 720
    img = Image.new("RGB", (w, h), BG)

    # 自上而下的 accent 色渐变光（约 30% 屏高）
    grad = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for i in range(0, h):
        if i < int(h * 0.7):
            alpha = int(55 * (1 - i / (h * 0.7)))
        else:
            alpha = 0
        gd.rectangle([0, i, w, i + 1], fill=(*accent, alpha))
    img = Image.alpha_composite(img.convert("RGBA"), grad).convert("RGB")
    d = ImageDraw.Draw(img)

    # 中央同心圆 + 字母
    cx, cy = w // 2, h // 2
    R = 160
    d.ellipse([cx - R, cy - R, cx + R, cy + R], outline=accent, width=10)
    d.ellipse([cx - R // 2, cy - R // 2, cx + R // 2, cy + R // 2], fill=accent)

    sym_font = load_font(150, "bold")
    sbbox = d.textbbox((0, 0), illustration, font=sym_font)
    sw = sbbox[2] - sbbox[0]
    sh = sbbox[3] - sbbox[1]
    d.text((cx - sw // 2 - sbbox[0], cy - sh // 2 - sbbox[1]), illustration,
           fill=BG, font=sym_font)

    # 四角微小品牌点缀
    d.rectangle([60, 60, 100, 64], fill=accent)
    d.rectangle([60, 60, 64, 100], fill=accent)
    d.rectangle([w - 100, h - 64, w - 60, h - 60], fill=accent)
    d.rectangle([w - 64, h - 100, w - 60, h - 60], fill=accent)

    img.save(out, "JPEG", quality=88, optimize=True)
    print(f"✓ Thumbnail → {out}")


# ---------- Asset Catalog 元数据 ----------

def write_app_icon_contents(iconset_dir: Path):
    contents = {
        "images": [
            {"idiom": "universal", "filename": "AppIcon-1024.png", "platform": "ios", "size": "1024x1024"}
        ],
        "info": {"version": 1, "author": "polly-script"}
    }
    (iconset_dir / "Contents.json").write_text(json.dumps(contents, indent=2))


def write_image_set_contents(imageset_dir: Path, filename: str):
    contents = {
        "images": [
            {"idiom": "universal", "filename": filename, "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"}
        ],
        "info": {"version": 1, "author": "polly-script"}
    }
    (imageset_dir / "Contents.json").write_text(json.dumps(contents, indent=2))


def write_catalog_root(catalog_dir: Path):
    contents = {"info": {"version": 1, "author": "polly-script"}}
    (catalog_dir / "Contents.json").write_text(json.dumps(contents, indent=2))


def main():
    # AppIcon.appiconset
    iconset = ASSETS / "AppIcon.appiconset"
    iconset.mkdir(parents=True, exist_ok=True)
    gen_app_icon(iconset / "AppIcon-1024.png")
    write_app_icon_contents(iconset)

    # LaunchLogo.imageset
    launchset = ASSETS / "LaunchLogo.imageset"
    launchset.mkdir(parents=True, exist_ok=True)
    gen_launch_logo(launchset / "LaunchLogo.png")
    write_image_set_contents(launchset, "LaunchLogo.png")

    write_catalog_root(ASSETS)

    # 视频缩略图（覆盖原 jpg）
    THUMBS.mkdir(parents=True, exist_ok=True)
    gen_thumbnail(THUMBS / "julian-treasure-maxresdefault.jpg", accent=BRAND, illustration="V")
    gen_thumbnail(THUMBS / "ted-ed-dream-maxresdefault.jpg",   accent=AI,    illustration="Z")
    gen_thumbnail(THUMBS / "tim-urban-maxresdefault.jpg",       accent=(255, 172, 117), illustration="P")

    print("\n✓ All assets generated")


if __name__ == "__main__":
    main()
