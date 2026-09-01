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


# --- 걷기 애니메이션 프레임 (inbox.md #8 4번) ---------------------------------
# 채택된 실제 캐릭터 비례(status.md #64가 고른 player_body_base #08, player.gd의
# HEAD_RATIO/BODY_WIDTH_RATIO/BODY_TOP_RATIO와 동일값) — 걷기 프레임은 후보
# 변주용이 아니라 실제로 게임에 적용될 형태를 그대로 미리 봐야 하므로 랜덤
# 대신 이 고정값을 쓴다.
WALK_HEAD_RATIO = 0.372
WALK_BODY_WIDTH_RATIO = 0.637
WALK_BODY_TOP_RATIO = 0.302
WALK_HEAD_CENTER_Y_RATIO = 0.24
WALK_OUTFIT_START_Y = 20
OUTFIT_BASE = (0.35, 0.25, 0.15)

FOOT_Y = (29, 32)
FOOT_HALF_WIDTH = 1.5
FOOT_CENTER_OFFSET = 3

# 몸이 눈사람형(머리+몸통 타원, 팔다리 없음)이라 실제 다리를 그릴 수 없다.
# 대신 (1) 몸 전체를 dy만큼 위아래로 살짝 튕기고(통통 튀는 느낌), (2) 캔버스
# 하단에 신발 역할을 하는 작은 타원 두 개를 좌우로 벌렸다 좁혔다 하는 방식으로
# "왼발-모임-오른발-모임"의 4프레임 컨택트/패싱 걷기 사이클을 흉내낸다.
# foot_dx가 음수면 발이 좁아지고(contact A), 양수면 벌어진다(contact B) —
# 실제 보행에서 발이 앞뒤로 교차하는 것과 완전히 같지는 않지만, 32x32 픽셀
# 스케일에서 좌우 스탠스 변화 + 바운스만으로도 "걷고 있다"는 인상은 충분히
# 만들어진다(아래 make_frame_strip으로 실제로 눈으로 확인해서 검증한다).
WALK_FRAMES = [
    {"dy": 0, "foot_dx": -2},  # contact A (좁은 스탠스)
    {"dy": -1, "foot_dx": 0},  # passing (바운스 정점, 발 모임)
    {"dy": 0, "foot_dx": 2},  # contact B (넓은 스탠스)
    {"dy": -1, "foot_dx": 0},  # passing
]


def _player_silhouette(size, dy=0):
    """머리/몸통(+기본 코디) 실루엣을 dy만큼 수직으로 이동해 그린다(발 제외)."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    skin_tones = three_tone(SKIN_BASE)
    outfit_tones = three_tone(OUTFIT_BASE)

    head_r = h * WALK_HEAD_RATIO / 2.0
    head_cx, head_cy = w / 2.0, h * WALK_HEAD_CENTER_Y_RATIO + dy
    _draw_shaded_ellipse(
        img,
        (
            round(head_cx - head_r), round(head_cy - head_r),
            round(head_cx + head_r), round(head_cy + head_r),
        ),
        skin_tones,
    )

    body_w = w * WALK_BODY_WIDTH_RATIO
    body_x0 = round((w - body_w) / 2.0)
    body_x1 = round((w + body_w) / 2.0)
    body_y0 = round(h * WALK_BODY_TOP_RATIO) + dy
    body_y1 = h + dy
    bbox = (body_x0, body_y0, body_x1, body_y1)
    _draw_shaded_ellipse(img, bbox, skin_tones)
    _draw_shaded_ellipse_partial(img, bbox, outfit_tones, WALK_OUTFIT_START_Y + dy)

    return img, skin_tones


def _draw_shaded_ellipse_partial(img, bbox, tones, min_row):
    """_draw_shaded_ellipse와 같지만 min_row 위쪽 행은 건너뛴다(하의를 몸통
    타원의 아래쪽에만 덮어씌우는 용도 — player.gd _draw_shaded_ellipse의
    min_row 인자와 동일한 목적)."""
    x0, y0, x1, y1 = bbox
    w = max(1, x1 - x0)
    h = max(1, y1 - y0)
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    rx, ry = w / 2.0, h / 2.0
    px = img.load()
    for y in range(y0, y1):
        if y < min_row:
            continue
        for x in range(x0, x1):
            nx = (x + 0.5 - cx) / rx
            ny = (y + 0.5 - cy) / ry
            if nx * nx + ny * ny > 1.0:
                continue
            dx = (x - x0) / w
            dy = (y - y0) / h
            tone_key = _shade_for_position(dx, dy)
            px[x, y] = _to_255(tones[tone_key]) + (255,)


def _draw_feet(img, foot_dx, shoe_rgb):
    w, h = img.size
    px = img.load()
    shoe = _to_255(shoe_rgb) + (255,)
    left_cx = w / 2.0 - FOOT_CENTER_OFFSET - foot_dx
    right_cx = w / 2.0 + FOOT_CENTER_OFFSET + foot_dx
    for fx_center in (left_cx, right_cx):
        fx0 = round(fx_center - FOOT_HALF_WIDTH)
        fx1 = round(fx_center + FOOT_HALF_WIDTH)
        for y in range(FOOT_Y[0], FOOT_Y[1]):
            for x in range(fx0, fx1):
                if 0 <= x < w and 0 <= y < h:
                    px[x, y] = shoe


def generate_walk_cycle(size=(32, 32), out_dir=None):
    """플레이어 걷기 4프레임(contact-passing-contact-passing)을 생성한다."""
    out_dir = Path(out_dir) if out_dir else (CANDIDATES_DIR / "player_walk")
    out_dir.mkdir(parents=True, exist_ok=True)
    files = []
    for i, frame in enumerate(WALK_FRAMES):
        img, skin_tones = _player_silhouette(size, dy=frame["dy"])
        _draw_feet(img, frame["foot_dx"], skin_tones["shadow"])
        path = out_dir / f"player_walk_{i:02d}.png"
        img.save(path, "PNG")
        files.append(path)
    return out_dir, files


def make_frame_strip(files, out_path, scale=8, pad=4, label_h=14):
    """애니메이션 프레임들을 순서대로 가로 스트립 한 장으로 합친다.

    make_comparison_grid()가 서로 다른 "후보"를 비교하기 위한 것이라면, 이
    함수는 하나로 채택된 대상의 "프레임 순서"가 자연스럽게 이어지는지
    확인하기 위한 것이다(inbox.md #8 4번). Image.NEAREST만 사용해 확대해
    ART_STYLE.md의 하드 엣지 규칙을 그대로 유지한다.
    """
    files = list(files)
    if not files:
        raise ValueError("스트립을 만들 프레임 파일이 없습니다.")

    thumbs = [Image.open(f).convert("RGBA") for f in files]
    w, h = thumbs[0].size
    cell_w, cell_h = w * scale, h * scale

    strip = Image.new(
        "RGBA",
        (len(thumbs) * (cell_w + pad) + pad, cell_h + label_h + pad * 2),
        (40, 40, 40, 255),
    )
    draw = ImageDraw.Draw(strip)
    for i, thumb in enumerate(thumbs):
        x = pad + i * (cell_w + pad)
        big = thumb.resize((cell_w, cell_h), Image.NEAREST)
        strip.paste(big, (x, pad), big)
        draw.text((x, pad + cell_h + 1), f"frame {i}", fill=(255, 255, 255, 255))

    strip.save(out_path, "PNG")
    return out_path


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
    parser.add_argument(
        "--walk", action="store_true",
        help="플레이어 걷기 4프레임(contact-passing-contact-passing)을 생성하고 "
        "frame_strip.png로 순서를 확인할 수 있게 만든다 (inbox.md #8 4번)",
    )
    args = parser.parse_args()

    if args.walk:
        out_dir, files = generate_walk_cycle(out_dir=args.out)
        print(f"{len(files)}장 생성 완료 -> {out_dir}")
        strip_path = make_frame_strip(files, out_dir / "frame_strip.png")
        print(f"프레임 스트립 생성 완료 -> {strip_path}")
        return

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
