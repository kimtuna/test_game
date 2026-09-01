#!/usr/bin/env python3
"""PixelLab API 기반 픽셀아트 스프라이트 생성 도구.

inbox.md #9 — 기존 Pillow 절차적 드로잉(tools/sprite_gen.py, inbox #8)은
결과 품질이 기대에 못 미쳐, 실제 스프라이트는 PixelLab(픽셀아트 전용 AI
이미지 생성 서비스) API로 만드는 것으로 대체됐다. 이 스크립트는
POST /generate-image-v2로 후보 이미지를 요청하고 GET /background-jobs/{id}로
완료될 때까지 폴링해 base64 이미지를 PNG로 저장한다.

비교 그리드 합성은 tools/sprite_gen.py의 make_comparison_grid()를 그대로
재사용한다(inbox #9 1번이 "기존 도구를 재사용할 수 있으면 재사용"하라고
명시함) — 신뢰할 수 있는 결과를 Read 도구로 직접 보고 고르는 절차
(inbox #8 3번에서 확립, #9 2번이 동물에도 그대로 적용)는 대상이 절차적
Pillow 그림이든 PixelLab 결과든 동일하다.

움직이는 대상(동물 등)의 애니메이션은 POST /animate-with-text-v2로 참조 이미지 +
동작 설명(action)을 보내 프레임들을 받는다(inbox #9 3번). 완료된 프레임은
tools/sprite_gen.py의 make_frame_strip()으로 스트립 이미지를 만들어 Read
도구로 자연스러움을 확인하는 절차(inbox #8 4번)를 그대로 따른다.

인증: HTTP 헤더 Authorization: Bearer $PIXELLAB_API_KEY (CLAUDE.md "비밀값"
규칙 — 절대 하드코딩 금지, 항상 환경변수로만 읽는다).

사용 예 (정적 이미지 생성):
    python3 tools/pixellab_gen.py --description "a cute wizard character" \
        --width 32 --height 32 --grid

사용 예 (애니메이션 생성 — 위에서 고른 정적 이미지를 참조로 사용):
    python3 tools/pixellab_gen.py --reference out/deer_00.png --action "walk" \
        --width 32 --height 32 --strip
"""

import argparse
import base64
import json
import os
import sys
import time
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sprite_gen import make_comparison_grid, make_frame_strip  # noqa: E402  (inbox #8 3/4번 도구 재사용)

API_BASE = "https://api.pixellab.ai/v2"
CANDIDATES_DIR = Path(__file__).resolve().parent / "pixellab_candidates"

# width/height 둘 다 이 값 이하면 한 번의 요청으로 64장이 나온다(장당 단가가
# 가장 쌈 — 사람이 직접 확인한 사실, inbox.md #9 참고). 43~85면 16장, 86~170이면
# 4장으로 줄어든다. 새 target을 추가할 때 이 상수 이하로 캔버스를 잡으면
# 후보를 많이 확보할 수 있다.
CHEAP_TIER_MAX_SIDE = 42


def _api_key():
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key:
        raise SystemExit(
            "PIXELLAB_API_KEY 환경변수가 설정되어 있지 않습니다. "
            "CLAUDE.md 비밀값 규칙에 따라 이 스크립트는 키를 하드코딩하지 않으므로, "
            ".harness/secrets.env에 키가 있는지 확인하세요."
        )
    return key


def _headers():
    return {"Authorization": f"Bearer {_api_key()}"}


def submit_job(description, width, height, seed=None, no_background=True):
    body = {
        "description": description,
        "image_size": {"width": width, "height": height},
        "no_background": no_background,
    }
    if seed is not None:
        body["seed"] = seed
    resp = requests.post(f"{API_BASE}/generate-image-v2", headers=_headers(), json=body)
    if resp.status_code != 202:
        raise SystemExit(
            f"generate-image-v2 요청 실패 (status={resp.status_code}): {resp.text}"
        )
    data = resp.json()
    return data["background_job_id"]


def poll_job(job_id, interval=3.0, timeout=300.0):
    deadline = time.monotonic() + timeout
    while True:
        resp = requests.get(f"{API_BASE}/background-jobs/{job_id}", headers=_headers())
        resp.raise_for_status()
        data = resp.json()
        status = data.get("status")
        if status == "completed":
            return data
        if status == "failed":
            raise SystemExit(f"PixelLab job {job_id} 실패: {json.dumps(data)[:500]}")
        if time.monotonic() > deadline:
            raise SystemExit(f"PixelLab job {job_id} 폴링 타임아웃({timeout}초)")
        time.sleep(interval)


def generate(description, width, height, out_dir=None, seed=None, no_background=True,
             poll_interval=3.0, timeout=300.0):
    """후보 이미지를 생성해 PNG로 저장한다. (out_dir, 저장된 파일 목록) 반환."""
    job_id = submit_job(description, width, height, seed=seed, no_background=no_background)
    job = poll_job(job_id, interval=poll_interval, timeout=timeout)

    images = (job.get("last_response") or {}).get("images")
    if not images:
        raise SystemExit(
            f"PixelLab job {job_id}가 completed 상태지만 images가 비어있습니다: "
            f"{json.dumps(job)[:500]}"
        )

    slug = "".join(c if c.isalnum() else "_" for c in description.lower())[:40].strip("_")
    out_dir = Path(out_dir) if out_dir else (CANDIDATES_DIR / slug)
    out_dir.mkdir(parents=True, exist_ok=True)

    files = []
    manifest = []
    for i, img_obj in enumerate(images):
        raw = base64.b64decode(img_obj["base64"])
        filename = f"{slug}_{i:02d}.png"
        path = out_dir / filename
        path.write_bytes(raw)
        files.append(path)
        manifest.append({"index": i, "file": filename})

    (out_dir / "manifest.json").write_text(
        json.dumps(
            {
                "description": description,
                "image_size": {"width": width, "height": height},
                "seed": seed,
                "job_id": job_id,
                "candidates": manifest,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return out_dir, files


def submit_animate_job(reference_image_path, action, width, height,
                        ref_width=None, ref_height=None, seed=None,
                        no_background=True, view="low top-down", direction="south"):
    """POST /animate-with-text-v2 — 참조 이미지 + 동작 설명으로 애니메이션 job을 제출한다.

    reference_image_size/image_size는 32~256px 범위(PixelLab 스펙, openapi.json
    확인). 32x32/64x64는 16프레임, 128px 이상은 4프레임이 나온다(엔드포인트
    설명에 명시됨). view/direction 기본값은 이 게임의 탑다운 시점(design.md)과
    ART_STYLE.md 관례에 맞춰 "low top-down"/"south"로 잡았다.
    """
    ref_width = ref_width or width
    ref_height = ref_height or height
    ref_b64 = base64.b64encode(Path(reference_image_path).read_bytes()).decode("ascii")
    body = {
        "reference_image": {"base64": ref_b64},
        "reference_image_size": {"width": ref_width, "height": ref_height},
        "action": action,
        "image_size": {"width": width, "height": height},
        "no_background": no_background,
        "view": view,
        "direction": direction,
    }
    if seed is not None:
        body["seed"] = seed
    resp = requests.post(f"{API_BASE}/animate-with-text-v2", headers=_headers(), json=body)
    if resp.status_code != 202:
        raise SystemExit(
            f"animate-with-text-v2 요청 실패 (status={resp.status_code}): {resp.text}"
        )
    return resp.json()["background_job_id"]


def animate(reference_image_path, action, width, height, out_dir=None,
            poll_interval=3.0, timeout=300.0, **submit_kwargs):
    """참조 이미지 + 동작 설명으로 애니메이션 프레임들을 생성해 PNG로 저장한다.

    (out_dir, 저장된 프레임 파일 목록) 반환 — generate()와 대칭되는 구조라
    manifest.json 기록, base64 디코딩 방식을 그대로 따른다.
    """
    job_id = submit_animate_job(reference_image_path, action, width, height, **submit_kwargs)
    job = poll_job(job_id, interval=poll_interval, timeout=timeout)

    images = (job.get("last_response") or {}).get("images")
    if not images:
        raise SystemExit(
            f"PixelLab animate job {job_id}가 completed 상태지만 images가 비어있습니다: "
            f"{json.dumps(job)[:500]}"
        )

    slug = "".join(c if c.isalnum() else "_" for c in action.lower())[:40].strip("_")
    out_dir = Path(out_dir) if out_dir else (CANDIDATES_DIR / f"anim_{slug}")
    out_dir.mkdir(parents=True, exist_ok=True)

    files = []
    for i, img_obj in enumerate(images):
        raw = base64.b64decode(img_obj["base64"])
        path = out_dir / f"frame_{i:02d}.png"
        path.write_bytes(raw)
        files.append(path)

    (out_dir / "manifest.json").write_text(
        json.dumps(
            {
                "reference_image": str(reference_image_path),
                "action": action,
                "image_size": {"width": width, "height": height},
                "job_id": job_id,
                "frames": [f.name for f in files],
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return out_dir, files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--description", default=None, help="[생성 모드] 생성할 이미지 설명 프롬프트")
    parser.add_argument(
        "--reference", default=None,
        help="[애니메이션 모드] 애니메이션의 기준이 될 참조 이미지 PNG 경로 (--action과 함께 지정하면 애니메이션 모드로 전환)",
    )
    parser.add_argument("--action", default=None, help="[애니메이션 모드] 동작 설명 (예: walk, attack)")
    parser.add_argument("--view", default="low top-down",
                         choices=["none", "low top-down", "high top-down", "side"],
                         help="[애니메이션 모드] 카메라 시점 (기본 low top-down — 이 게임의 탑다운 시점)")
    parser.add_argument("--direction", default="south",
                         help="[애니메이션 모드] 캐릭터가 바라보는 방향 (기본 south)")
    parser.add_argument("--width", type=int, default=32, help="이미지 폭 (기본 32)")
    parser.add_argument("--height", type=int, default=32, help="이미지 높이 (기본 32)")
    parser.add_argument("--seed", type=int, default=None, help="재현 가능한 결과를 위한 시드")
    parser.add_argument("--out", default=None, help="출력 디렉터리 (기본 tools/pixellab_candidates/<slug>)")
    parser.add_argument(
        "--with-background", action="store_true",
        help="배경 제거 없이 생성 (기본은 no_background=true, 투명 배경)",
    )
    parser.add_argument(
        "--grid", action="store_true",
        help="[생성 모드] 생성 직후 번호 라벨이 붙은 비교 그리드(comparison.png)를 out_dir에 함께 만든다",
    )
    parser.add_argument(
        "--grid-limit", type=int, default=25,
        help="비교 그리드에 포함할 최대 후보 수 (기본 25 — 최대 64장이 나올 수 있어 "
        "그리드가 과도하게 커지는 것을 막는다. 원본 파일은 모두 저장된다)",
    )
    parser.add_argument(
        "--strip", action="store_true",
        help="[애니메이션 모드] 생성 직후 프레임 순서를 확인할 가로 스트립(strip.png)을 out_dir에 함께 만든다",
    )
    parser.add_argument("--poll-interval", type=float, default=3.0, help="폴링 간격(초)")
    parser.add_argument("--timeout", type=float, default=300.0, help="폴링 타임아웃(초)")
    args = parser.parse_args()

    animate_mode = args.reference is not None or args.action is not None
    if animate_mode:
        if args.reference is None or args.action is None:
            parser.error("애니메이션 모드는 --reference와 --action을 함께 지정해야 합니다.")
        if args.description is not None:
            parser.error("--description(생성 모드)과 --reference/--action(애니메이션 모드)은 함께 쓸 수 없습니다.")

        out_dir, files = animate(
            args.reference,
            args.action,
            args.width,
            args.height,
            out_dir=args.out,
            seed=args.seed,
            no_background=not args.with_background,
            view=args.view,
            direction=args.direction,
            poll_interval=args.poll_interval,
            timeout=args.timeout,
        )
        print(f"{len(files)}프레임 생성 완료 -> {out_dir}")

        if args.strip:
            strip_path = make_frame_strip(files, out_dir / "strip.png")
            print(f"프레임 스트립 생성 완료 -> {strip_path}")
        return

    if args.description is None:
        parser.error("생성 모드는 --description이 필요합니다 (또는 --reference/--action으로 애니메이션 모드를 쓰세요).")

    if max(args.width, args.height) <= CHEAP_TIER_MAX_SIDE:
        print(f"[정보] width/height <= {CHEAP_TIER_MAX_SIDE} -> 64장 예상 (최저 단가 구간)")

    out_dir, files = generate(
        args.description,
        args.width,
        args.height,
        out_dir=args.out,
        seed=args.seed,
        no_background=not args.with_background,
        poll_interval=args.poll_interval,
        timeout=args.timeout,
    )
    print(f"{len(files)}장 생성 완료 -> {out_dir}")

    if args.grid:
        grid_files = files[: args.grid_limit]
        grid_path = make_comparison_grid(grid_files, out_dir / "comparison.png")
        print(f"비교 그리드 생성 완료 ({len(grid_files)}장) -> {grid_path}")


if __name__ == "__main__":
    main()
