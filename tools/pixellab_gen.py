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

인증: HTTP 헤더 Authorization: Bearer $PIXELLAB_API_KEY (CLAUDE.md "비밀값"
규칙 — 절대 하드코딩 금지, 항상 환경변수로만 읽는다).

사용 예:
    python3 tools/pixellab_gen.py --description "a cute wizard character" \
        --width 32 --height 32 --grid
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
from sprite_gen import make_comparison_grid  # noqa: E402  (inbox #8 3번 도구 재사용)

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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--description", required=True, help="생성할 이미지 설명 프롬프트")
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
        help="생성 직후 번호 라벨이 붙은 비교 그리드(comparison.png)를 out_dir에 함께 만든다",
    )
    parser.add_argument(
        "--grid-limit", type=int, default=25,
        help="비교 그리드에 포함할 최대 후보 수 (기본 25 — 최대 64장이 나올 수 있어 "
        "그리드가 과도하게 커지는 것을 막는다. 원본 파일은 모두 저장된다)",
    )
    parser.add_argument("--poll-interval", type=float, default=3.0, help="폴링 간격(초)")
    parser.add_argument("--timeout", type=float, default=300.0, help="폴링 타임아웃(초)")
    args = parser.parse_args()

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
