#!/usr/bin/env python3
"""Pillow 기반 픽셀아트 스프라이트 후보 생성 도구.

assets/ART_STYLE.md의 규칙(8의 배수 캔버스, 3톤 색상 공식, 외곽선 없음,
좌상단 45도 광원, 하드 엣지·그라디언트 금지)을 그대로 구현한다. 하나의
대상(target)에 대해 비례/디테일을 조금씩 바꾼 후보 이미지를 여러 장
생성해 tools/sprite_candidates/ 아래에 저장한다 — 이 산출물은 최종
채택본이 아니므로 저장소에 커밋하지 않는다(ART_STYLE.md "파일 구성 규칙").

이 스크립트는 생성 + 비교 그리드 합성까지 담당한다(inbox.md #8 3번).
후보 10장을 만든 뒤 --grid로 번호가 붙은 확대 비교 이미지 한 장을 만들면,
그 이미지를 Read 도구로 직접 열어 눈으로 비교해서 고르는 절차를 따른다
(프로그램적 점수만으로 자동 선택하지 않는다 — inbox #8 3번 요구사항).
애니메이션 프레임 확인 루프는 inbox.md #8 4번에서 별도로 만든다.

사용 예:
    python3 tools/sprite_gen.py --list
    python3 tools/sprite_gen.py --target player_body_base --count 10 --grid
"""

import argparse
import colorsys
import json
import random
from pathlib import Path

from PIL import Image, ImageDraw

CANDIDATES_DIR = Path(__file__).resolve().parent / "sprite_candidates"

# ART_STYLE.md 색상 팔레트 앵커 (RGB 0~1) — 임의로 바꾸지 않는다.
SKIN_BASE = (0.2, 0.6, 1.0)


def _clamp01(v):
    return max(0.0, min(1.0, v))


def three_tone(base_rgb):
    """ART_STYLE.md 3톤 공식: 그림자 = V-20%/S+5%, 밝은색 = V+15% (HSV 기준)."""
    h, s, v = colorsys.rgb_to_hsv(*base_rgb)
    shadow = colorsys.hsv_to_rgb(h, _clamp01(s + 0.05), _clamp01(v - 0.20))
    highlight = colorsys.hsv_to_rgb(h, s, _clamp01(v + 0.15))
    return {"shadow": shadow, "base": base_rgb, "highlight": highlight}


def _to_255(rgb):
    return tuple(round(_clamp01(c) * 255) for c in rgb)


def _shade_for_position(dx, dy):
    """좌상단 45도 광원 기준 하드엣지 3톤 분류(dx/dy: bbox 내부 0~1 상대 좌표).

    그라디언트 대신 계단식 경계로만 명암을 나눠 ART_STYLE.md의
    "안티앨리어싱 금지, 하드 엣지" 규칙을 지킨다.
    """
    metric = ((1.0 - dx) + dy) / 2.0
    if metric > 0.62:
        return "highlight"
    if metric < 0.38:
        return "shadow"
    return "base"


def _draw_shaded_ellipse(img, bbox, tones):
    x0, y0, x1, y1 = bbox
    w = max(1, x1 - x0)
    h = max(1, y1 - y0)
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    rx, ry = w / 2.0, h / 2.0
    px = img.load()
    for y in range(y0, y1):
        for x in range(x0, x1):
            nx = (x + 0.5 - cx) / rx
            ny = (y + 0.5 - cy) / ry
            if nx * nx + ny * ny > 1.0:
                continue
            dx = (x - x0) / w
            dy = (y - y0) / h
            tone_key = _shade_for_position(dx, dy)
            px[x, y] = _to_255(tones[tone_key]) + (255,)


def _target_player_body_base(size, rng):
    """플레이어 몸체 베이스(assets/sprites/player/body_base.png 후보).

    비례(머리 크기, 몸통 너비, 몸통 시작 높이)를 후보마다 조금씩
    변주한다. 색상은 ART_STYLE.md의 피부 앵커색을 그대로 쓴다.
    """
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    tones = three_tone(SKIN_BASE)

    head_ratio = 0.34 + rng.uniform(-0.04, 0.04)
    body_width_ratio = 0.62 + rng.uniform(-0.08, 0.08)
    body_top_ratio = 0.30 + rng.uniform(-0.03, 0.03)

    head_r = h * head_ratio / 2.0
    head_cx, head_cy = w / 2.0, h * 0.24
    _draw_shaded_ellipse(
        img,
        (
            round(head_cx - head_r), round(head_cy - head_r),
            round(head_cx + head_r), round(head_cy + head_r),
        ),
        tones,
    )

    body_w = w * body_width_ratio
    body_x0 = round((w - body_w) / 2.0)
    body_x1 = round((w + body_w) / 2.0)
    body_y0 = round(h * body_top_ratio)
    body_y1 = h
    _draw_shaded_ellipse(img, (body_x0, body_y0, body_x1, body_y1), tones)

    return img


# target 이름 -> {캔버스 크기, 그리기 함수(size, rng) -> Image}.
# 새 대상(동물/나무/아이템 등)을 추가할 때는 여기에 항목만 추가하면
# generate()/CLI가 그대로 동작한다.
TARGETS = {
    "player_body_base": {
        "size": (32, 32),
        "draw": _target_player_body_base,
    },
}


def generate(target_name, count, out_dir=None, seed=None):
    if target_name not in TARGETS:
        raise SystemExit(
            f"알 수 없는 target '{target_name}'. --list로 사용 가능한 target을 확인하세요."
        )
    spec = TARGETS[target_name]
    out_dir = Path(out_dir) if out_dir else (CANDIDATES_DIR / target_name)
    out_dir.mkdir(parents=True, exist_ok=True)

    manifest = []
    for i in range(count):
        rng = random.Random(f"{seed}:{i}" if seed is not None else i)
        img = spec["draw"](spec["size"], rng)
        filename = f"{target_name}_{i:02d}.png"
        img.save(out_dir / filename, "PNG")
        manifest.append({"index": i, "file": filename})

    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2)
    )
    return out_dir, [out_dir / m["file"] for m in manifest]


def make_comparison_grid(files, out_path, scale=6, columns=5, label_h=14):
    """후보 PNG들을 확대 + 번호 라벨을 붙여 한 장의 비교 그리드로 합친다.

    ART_STYLE.md의 하드 엣지 규칙을 유지하기 위해 확대는 Image.NEAREST만
    쓴다(보간 금지). 번호 라벨은 스프라이트 본체가 아니라 비교용 UI이므로
    이 규칙 대상이 아니다 — 그리드 셀 아래 여백에만 그린다.
    """
    files = list(files)
    if not files:
        raise ValueError("비교 그리드를 만들 후보 파일이 없습니다.")

    thumbs = [Image.open(f).convert("RGBA") for f in files]
    w, h = thumbs[0].size
    cell_w, cell_h = w * scale, h * scale
    rows = (len(thumbs) + columns - 1) // columns
    pad = 4

    grid = Image.new(
        "RGBA",
        (columns * (cell_w + pad) + pad, rows * (cell_h + label_h + pad) + pad),
        (40, 40, 40, 255),
    )
    draw = ImageDraw.Draw(grid)

    for i, thumb in enumerate(thumbs):
        col, row = i % columns, i // columns
        x = pad + col * (cell_w + pad)
        y = pad + row * (cell_h + label_h + pad)
        big = thumb.resize((cell_w, cell_h), Image.NEAREST)
        grid.paste(big, (x, y), big)
        draw.text((x, y + cell_h + 1), f"#{i:02d}", fill=(255, 255, 255, 255))

    grid.save(out_path, "PNG")
    return out_path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", help="생성할 대상 이름")
    parser.add_argument("--count", type=int, default=10, help="후보 개수 (기본 10)")
    parser.add_argument(
        "--out", default=None,
        help="출력 디렉터리 (기본 tools/sprite_candidates/<target>)",
    )
    parser.add_argument("--seed", default=None, help="재현 가능한 결과를 위한 시드")
    parser.add_argument("--list", action="store_true", help="사용 가능한 target 목록 출력")
    parser.add_argument(
        "--grid", action="store_true",
        help="생성 직후 번호 라벨이 붙은 비교 그리드(comparison.png)를 out_dir에 함께 만든다",
    )
    args = parser.parse_args()

    if args.list or not args.target:
        print("사용 가능한 target:")
        for name, spec in TARGETS.items():
            print(f"  {name}  (캔버스 {spec['size'][0]}x{spec['size'][1]})")
        return

    out_dir, files = generate(args.target, args.count, args.out, args.seed)
    print(f"{len(files)}장 생성 완료 -> {out_dir}")

    if args.grid:
        grid_path = make_comparison_grid(files, out_dir / "comparison.png")
        print(f"비교 그리드 생성 완료 -> {grid_path}")


if __name__ == "__main__":
    main()
