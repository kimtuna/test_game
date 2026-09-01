# status.md — 인수인계서

새 항목은 번호를 이어서 맨 아래에 추가한다. 기존 항목은 수정/삭제하지 않는다. 가장 마지막 번호가 이번 세션의 출발점이다.

---

### #1 — 2026-09-01 (하네스 초기 설정, 자동 세션 아님)

- 한 일: 하네스 구조(design.md / status.md / inbox.md / CLAUDE.md) 생성. `my-2d-game` 뼈대(Player 이동 스크립트, Main.tscn)를 그대로 이식. Git 원격을 `https://github.com/kimtuna/test_game.git`로 연결.
- 확인: `godot --headless --path /Users/tuna/Desktop/test_game --quit` 에러 없음 확인.
- 다음 할 일: 아이템(수집 대상) 씬을 하나 만들고, 맵에 최소 1개 배치해서 Player가 접촉하면 사라지도록 구현한다 (점수 처리는 다음 단계로 미룬다 — 한 세션에 하나만).

---

### #2 — 2026-09-01 (자동 세션)

- 한 일:
  - (부수) `CLAUDE.md`/`.gitignore`에 남아있던 미커밋 상태 정리: 프로젝트 루트가 `/Users/tuna/Desktop/test_game`에서 `/Users/tuna/projects/test_game`로 이동한 것을 문서 경로에 반영하고, `.harness/` 로그 디렉토리를 저장소에서 제외.
  - (본 작업) `scenes/Item.tscn` + `scripts/item.gd` 생성: `Area2D` 기반 아이템, `CollisionShape2D`(20x20) + `Sprite2D`(텍스처는 Player와 동일하게 아직 없음). `body_entered` 시그널에서 `CharacterBody2D`(Player)가 닿으면 `queue_free()`로 사라짐.
  - `scenes/Main.tscn`에 Item 인스턴스 1개를 Player 시작 위치(576, 324)와 겹치지 않는 (750, 400)에 배치.
  - 점수 처리는 inbox 지시대로 이번 세션 범위에서 제외.
- 확인: `godot --headless --path /Users/tuna/projects/test_game --quit` 에러 없음 확인 (파싱/런타임 에러 없음).
- 다음 할 일: 점수 시스템을 추가한다 — 아이템을 모을 때마다 점수를 올리고 화면(UI, 예: Label/CanvasLayer)에 표시한다. 아이템이 여러 개 필요할 수 있으니(점수가 의미를 가지려면 최소 2개 이상) 이번에 Main.tscn에 아이템을 1~2개 더 배치하는 것도 함께 고려한다. 그 다음 단계는 "정해진 개수를 다 모으면 클리어 화면" 구현이다.

---

### #3 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없어 status.md #2의 다음 할 일을 그대로 이어받음):
  - `scripts/item.gd`: `collected` 시그널 추가, 접촉 시 `queue_free()` 전에 emit. `_ready()`에서 `add_to_group("items")`로 자가 등록해 씬 어디에 배치되든 Main이 그룹으로 찾을 수 있게 함.
  - `scripts/main.gd` 신설: `Main` 루트에 부착. `_ready()`에서 `items` 그룹의 모든 아이템의 `collected` 시그널을 구독, 수집될 때마다 `score` 1 증가시키고 `UI/ScoreLabel` 텍스트를 "Score: N"으로 갱신.
  - `scenes/Main.tscn`: `main.gd`를 Main 노드 스크립트로 연결, `CanvasLayer/Label`(ScoreLabel)을 좌상단에 추가. 점수가 의미를 가지도록 아이템을 기존 1개(750,400)에서 2개 더 추가(Item2 300,200 / Item3 900,150) — Player 시작 위치(576,324)와 겹치지 않게 배치.
- 확인: `godot --headless --path /Users/tuna/projects/test_game --quit` 에러 없음 확인 (파싱/런타임 에러 없음). 실제 화면 실행(에디터)은 확인/커밋 이후로 미룸(규칙 5).
- 다음 할 일: "클리어 화면" 구현 — 정해진 개수(현재 배치된 아이템 3개)를 모두 모으면 클리어 화면(예: CanvasLayer + Label "Clear!" 또는 별도 씬 전환)을 띄운다. `main.gd`에 아이템 총 개수를 추적해 `score`가 총 개수에 도달하면 클리어 UI를 표시하도록 확장하면 된다. design.md의 "완료 정의"에 명시된 1차 목표(스폰→수집→점수 표시→클리어)의 마지막 조각이다.

---

### #4 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없어 status.md #3의 다음 할 일을 그대로 이어받음):
  - `scripts/main.gd`: `total_items` 변수 추가, `_ready()`에서 `items` 그룹 노드 수를 세어 저장. `_on_item_collected()`에서 `score >= total_items`가 되면 `clear_label.visible = true`로 클리어 화면 표시.
  - `scenes/Main.tscn`: `UI/ClearLabel`(Label) 추가 — 기본 `visible = false`, 화면 중앙(412,284)~(812,364)에 배치, 폰트 크기 48, 가운데 정렬, 텍스트 "Clear!". 별도 씬 전환 대신 같은 CanvasLayer 안에서 보이기/숨기기로 구현(가장 단순한 방식, 범위 밖 복잡한 씬 전환은 피함).
  - 이로써 design.md의 완료 정의(스폰→수집→점수 표시→클리어)에 명시된 1차 목표 흐름이 코드상으로는 모두 구현됨.
- 확인: `godot --headless --path /Users/tuna/projects/test_game --quit` 에러 없음 확인 (파싱/런타임 에러 없음). 실제 실행(에디터)으로 아이템 3개를 모두 모았을 때 "Clear!"가 뜨는지 시각적 확인은 규칙 5에 따라 커밋 이후로 미룸 — 아직 미확인.
- 다음 할 일: 에디터를 열어 실제 플레이로 전체 루프(이동 → 아이템 3개 수집 → 점수 갱신 → 클리어 화면 표시)를 처음부터 끝까지 시각적으로 확인한다. 문제없으면 design.md의 1차 완료 정의가 충족된 것이므로, 이후 세션은 inbox.md에 새 지시가 없는 한 확장 기능(적, 타이머, 여러 레벨 등)을 사용자에게 제안하거나 대기한다.

---

### #5 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없어 status.md #4의 다음 할 일을 그대로 이어받음):
  - #4가 남긴 다음 할 일은 "에디터를 열어 실제 플레이로 시각 확인"이었으나, 이번 세션은 비대화형(non-interactive) 자동 세션이라 사람이 눈으로 에디터를 보는 방식은 수행할 수 없었다. 대신 같은 목적(파싱 통과 수준을 넘어 실제 게임플레이 동작 검증)을 비대화형 환경에서도 반복 가능하게 만족시키기 위해 `tests/loop_headless_test.gd`를 신설했다.
  - 이 스크립트는 `godot --headless --path . --script res://tests/loop_headless_test.gd`로 실행되며, `Main.tscn`을 직접 인스턴스화한 뒤 Player를 각 아이템의 `global_position`으로 순간이동시키고 물리 프레임을 여러 번 진행시켜 실제 `Area2D` 충돌(`body_entered`)이 발생하도록 만든다. 이후 `ScoreLabel` 텍스트가 "Score: 3"인지, `ClearLabel.visible`이 true인지, `items` 그룹에 남은 노드가 0개인지 검사해 결과를 PASS/FAIL로 출력하고 종료 코드를 설정한다.
  - 실행 결과: `HEADLESS_LOOP_TEST: PASS (score=Score: 3, clear=true)`. 이동→수집→점수 갱신→클리어 표시까지 전체 루프가 실제로 동작함을 확인했다.
- 확인: `godot --headless --path . --quit` 에러 없음. `godot --headless --path . --script res://tests/loop_headless_test.gd` PASS.
- 남은 제약: 위 테스트는 물리 시뮬레이션 기반으로 로직/충돌을 검증하지만, 실제 사람이 키보드로 조작했을 때의 조작감·UI 배치의 시각적 자연스러움(글자 겹침, 폰트 크기 등)까지는 보증하지 않는다. 사람이 직접 에디터로 플레이해 시각적으로 확인하는 것을 여전히 권장한다.
- 다음 할 일: design.md의 1차 완료 정의(스폰→수집→점수 표시→클리어)는 코드 검증까지 충족되었다고 판단한다. inbox.md에 새 지시가 없다면, 다음 세션은 확장 기능(예: 적, 타이머, 여러 레벨, 아이템 스프라이트 등 현재 텍스처 없는 부분 보강) 중 design.md 범위 안에서 가장 우선순위가 높아 보이는 것 하나를 제안하거나, 사용자의 inbox 지시를 기다린다.

---

### #6 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없어 status.md #5의 다음 할 일을 그대로 이어받음):
  - 확인해보니 `scenes/Player.tscn`, `scenes/Item.tscn`의 `Sprite2D` 노드에 texture가 비어 있어, 헤드리스 테스트(#5)는 통과하지만 실제로 화면을 열어 실행하면 Player와 Item이 전혀 보이지 않는 상태였다. design.md의 완료 정의("실제 실행에서 처음부터 끝까지 끊김 없이 동작")를 실질적으로 만족시키려면 최소한의 시각적 피드백이 필요하다고 판단했다. 이는 design.md가 금지한 "확장 기능(적/타이머/레벨)"이나 "복잡한 아트"가 아니라 기존 핵심 루프를 실제로 눈으로 확인 가능하게 만드는 보강이므로, inbox 지시 없이 이번 세션의 작업으로 진행했다.
  - `scripts/player.gd`: `_ready()`에서 `Image.create(32,32,...)` + `ImageTexture.create_from_image()`로 파란색(0.2, 0.6, 1.0) 단색 텍스처를 절차적으로 생성해 `$Sprite2D.texture`에 할당. 별도 이미지 파일(에셋) 없이 코드로만 처리해 "복잡한 아트" 범위를 침범하지 않음.
  - `scripts/item.gd`: 동일한 방식으로 20x20 노란색(1.0, 0.85, 0.2) 텍스처를 생성해 아이템에 할당.
- 확인: `godot --headless --path . --quit` 에러 없음. `godot --headless --path . --script res://tests/loop_headless_test.gd` 실행 결과 `HEADLESS_LOOP_TEST: PASS (score=Score: 3, clear=true)` — 텍스처 변경 후에도 이동→수집→점수→클리어 전체 루프가 정상 동작함을 재확인.
- 다음 할 일: 이제 Player/Item이 실제 화면에서도 보이므로, 사람이 직접 에디터로 플레이해 조작감·시각적 배치(글자 겹침, 아이템 간격 등)를 확인하는 것을 권장한다. inbox.md에 새 지시가 없다면, 다음 세션은 design.md가 명시한 확장 범위(적, 타이머, 여러 레벨 등) 중 하나를 진행하기보다는— design.md가 "그 이후 확장은 inbox.md 지시가 내려온 뒤에 진행한다"고 명확히 제한하고 있으므로 — 사용자에게 다음 확장 방향(적 추가, 타이머, 레벨 확장, 사운드 등 범위 밖 항목 포함 여부)을 inbox.md를 통해 지시해 줄 것을 제안하는 상태로 대기하는 것이 맞다.

---

### #7 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없음. status.md #6이 남긴 "시각적 배치 확인" 권고에 따라 `scenes/Main.tscn`의 아이템 간격(Player와 Item/Item2/Item3 사이 거리 187~368px, 뷰포트 1152x648 안에 모두 위치)과 `UI/ScoreLabel`·`UI/ClearLabel` 좌표(좌상단 vs 화면 중앙, 겹침 없음)를 직접 점검했으나 실질적인 배치 결함은 없었음. 대신 점검 과정에서 `project.godot`의 `config/name`이 `my-2d-game` 뼈대를 이식했던 #1 세션 이후 "My 2D Game"으로 그대로 남아 있어 design.md의 게임 제목("Test Game")과 불일치하는 것을 발견함 — 창 제목에 그대로 노출되는 부분이라 규칙 1(합격 기준: 리뷰해도 부끄럽지 않은가)에 어긋난다고 판단해 이번 세션의 작업으로 수정함):
  - `project.godot`: `config/name`을 `"My 2D Game"` → `"Test Game"`으로 수정. 게임플레이 로직/씬 구조 변경 없음 (design.md가 금지한 확장 기능이 아니라 기존 결과물의 정합성 결함 수정).
- 확인: `godot --headless --path . --quit` 에러 없음. `godot --headless --path . --script res://tests/loop_headless_test.gd` 실행 결과 `HEADLESS_LOOP_TEST: PASS (score=Score: 3, clear=true)` — 이름 변경이 게임 로직에 영향 없음을 확인.
- 다음 할 일: design.md의 1차 완료 정의(스폰→수집→점수 표시→클리어)는 코드 검증 및 시각적 배치 점검까지 마쳤다고 판단한다. inbox.md에 새 지시가 없는 한, 다음 세션은 design.md가 명시적으로 제한한 확장 범위(적, 타이머, 여러 레벨, 사운드 등)를 임의로 진행하지 말고, 사용자에게 inbox.md를 통한 다음 방향 지시를 요청하는 상태로 대기한다.

---

### #8 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없음. status.md #7이 이미 1차 완료 정의 충족을 확인했고, design.md가 확장 기능은 inbox 지시 없이는 진행하지 말라고 명시하므로 새 게임플레이 기능은 만들지 않았다. 대신 기존 코드를 다시 점검하며 규칙 1(합격 기준)에 걸리는 견고성 결함 하나를 발견해 수정함):
  - `scripts/item.gd`의 `_on_body_entered()`가 `body is CharacterBody2D` 타입 체크로 수집 여부를 판정하고 있었다. 지금은 Player가 유일한 `CharacterBody2D`라 우연히 맞지만, 나중에 적(enemy)을 `CharacterBody2D`로 추가하면 아이템이 적과 닿아도 수집되는 잘못된 동작으로 이어지는 잠재 버그였다. 이는 design.md가 말하는 "확장 기능"이 아니라 기존 핵심 루프 구현의 잠재적 결함 수정이므로 이번 세션 범위로 진행했다.
  - `scripts/player.gd`: `_ready()`에서 `add_to_group("player")` 추가.
  - `scripts/item.gd`: `_on_body_entered()` 판정을 `body.is_in_group("player")`로 변경.
- 확인: `godot --headless --path . --quit` 에러 없음. `godot --headless --path . --script res://tests/loop_headless_test.gd` 실행 결과 `HEADLESS_LOOP_TEST: PASS (score=Score: 3, clear=true)` — 변경 후에도 이동→수집→점수→클리어 전체 루프 정상 동작 확인.
- 다음 할 일: design.md의 1차 완료 정의는 여전히 충족된 상태다. inbox.md에 새 지시가 없는 한, 다음 세션도 확장 범위(적, 타이머, 여러 레벨, 사운드 등)를 임의로 진행하지 말고 사용자의 inbox 지시를 기다리는 것이 맞다. 다만 "대기"가 곧 "할 일 없음"을 뜻하지는 않는다 — 기존 구현을 다시 읽어보며 확장 범위를 벗어나지 않는 선에서의 견고성/버그 점검은 매 세션 유효한 작업이 될 수 있다.

---

### #9 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없음. status.md #8의 권고대로 확장 기능 대신 견고성 점검을 진행하다가, `scenes/Main.tscn`의 `UI/ClearLabel`이 `CanvasLayer` 안에서 anchor(0,0,0,0) + 고정 픽셀 offset(412~812, 284~364)으로만 배치되어 있는 것을 발견함. 이 방식은 뷰포트 크기(1152x648)를 기준으로 좌상단에서 고정 거리만큼 떨어진 위치라, 데스크톱 창은 기본적으로 사용자가 리사이즈할 수 있으므로(별도로 `window/size/resizable`을 껐다는 설정이 project.godot에 없음) 창 크기를 바꾸면 "Clear!" 텍스트가 화면 중앙에서 벗어나게 되는 견고성 결함이었음. `ScoreLabel`은 좌상단 고정이 의도된 배치라 문제가 없지만 `ClearLabel`은 "화면 중앙"이 의도이므로 앵커링이 잘못됨. 이는 design.md가 막은 "확장 기능"이 아니라 이미 구현된 클리어 화면의 배치 정합성 결함 수정이므로 이번 세션 범위로 진행함):
  - `scenes/Main.tscn`: `UI/ClearLabel`의 anchor를 `(0,0,0,0)`에서 `(0.5,0.5,0.5,0.5)`(화면 중앙)로 변경하고, offset을 뷰포트 크기와 무관하게 중앙 기준 `(-200,-40)~(200,40)`으로 재계산(기존 400x80 박스 크기 유지). 이제 창 크기가 바뀌어도 "Clear!"가 항상 화면 중앙에 표시됨.
- 확인: `godot --headless --path . --quit` 에러 없음. `godot --headless --path . --script res://tests/loop_headless_test.gd` 실행 결과 `HEADLESS_LOOP_TEST: PASS (score=Score: 3, clear=true)` — 앵커 변경 후에도 이동→수집→점수→클리어 전체 루프 정상 동작 확인.
- 다음 할 일: design.md의 1차 완료 정의는 여전히 충족된 상태다. inbox.md에 새 지시가 없는 한, 다음 세션도 확장 범위(적, 타이머, 여러 레벨, 사운드 등)를 임의로 진행하지 말고 사용자의 inbox 지시를 기다린다. 이번 세션처럼 UI 앵커/배치, 충돌 판정, 텍스처 등 기존 구현의 견고성 결함을 다시 점검하는 것은 매 세션 유효하지만, 이제 눈에 띄는 결함은 대부분 정리된 상태이므로 다음 자동 세션은 새로운 관점(예: 실제 창 리사이즈 시나리오, 다른 화면 해상도, 반복 실행 시 상태 초기화 등)에서 점검하거나, 더 이상 발견되는 결함이 없다면 사용자에게 다음 확장 방향을 inbox.md로 지시해 줄 것을 요청하는 상태로 대기하는 것이 맞다.

---

### #10 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없음. status.md #9가 다음 할 일로 제안한 "새로운 관점(실제 창 리사이즈 시나리오)" 점검을 진행함. `project.godot`의 `[display]` 섹션에 스트레치 설정이 전혀 없어 기본값(`window/stretch/mode="disabled"`)이 적용되고 있었음을 확인했다. 이 모드에서는 OS 창 크기가 곧 뷰포트 크기가 되므로, 사용자가 창을 키우면 원래 1152x648로 설계된 게임 월드 바깥의 빈 배경이 그대로 드러나고, 창을 줄이면 오른쪽/아래쪽에 배치된 아이템(Item3 등)이 화면 밖으로 잘려 보이지 않는 채로 플레이해야 하는 상태였다. `ScoreLabel`/`ClearLabel`은 #9에서 앵커를 고정해 위치 자체는 안전하지만, 게임 월드 콘텐츠가 창 크기에 따라 잘리거나 빈 공간이 늘어나는 것은 "리뷰해도 부끄럽지 않은가"(규칙 1) 기준에 걸리는 시각적 견고성 결함이라 판단해 이번 세션 작업으로 진행함. 이는 design.md가 제한한 게임플레이 확장(적/타이머/레벨/사운드)이 아니라 렌더링/디스플레이 설정 보정임):
  - `project.godot`: `[display]`에 `window/stretch/mode="canvas_items"`, `window/stretch/aspect="keep"` 추가. 이제 창 크기가 바뀌어도 1152x648 기준으로 설계된 게임 콘텐츠 전체가 종횡비를 유지한 채 스케일되어 보이며(레터박스 방식), 월드가 잘리거나 빈 배경이 늘어나는 문제가 사라짐.
- 확인: `godot --headless --path . --quit` 에러 없음. `godot --headless --path . --script res://tests/loop_headless_test.gd` 실행 결과 `HEADLESS_LOOP_TEST: PASS (score=Score: 3, clear=true)` — 스트레치 설정 변경 후에도 이동→수집→점수→클리어 전체 루프 정상 동작 확인(스트레치 모드는 렌더링 스케일링만 영향을 주고 월드 좌표/충돌 판정에는 영향 없음을 재확인).
- 다음 할 일: design.md의 1차 완료 정의(스폰→수집→점수 표시→클리어)는 여전히 충족된 상태이며, 이번 세션으로 UI 앵커·충돌 판정·텍스처·창 리사이즈까지 견고성 점검이 한 바퀴 돌았다. inbox.md에 새 지시가 없다면, 다음 자동 세션은 더 이상 사소한 견고성 결함을 억지로 찾기보다 — design.md가 명시한 대로 확장 기능(적, 타이머, 여러 레벨, 사운드, 아이템 종류 다양화 등)은 반드시 inbox.md 지시가 있어야 진행할 수 있으므로 — 이 status.md에 다음 확장 방향을 inbox.md로 알려달라는 요청을 남기고, 사용자가 실제로 에디터에서 플레이해 조작감을 확인해 줄 것을 권장하는 상태로 대기하는 것이 맞다.

---

### #11 — 2026-09-01 (자동 세션)

- 한 일 (inbox 미처리 항목 없음. status.md #10까지 UI 앵커·충돌 판정·텍스처·창 리사이즈 견고성 점검이 한 바퀴 돌아 새로운 결함을 억지로 찾기보다, 코드 전체(scripts/, scenes/, project.godot, tests/, assets/)를 다시 읽으며 기능적 결함 유무를 확인함. 명백한 버그는 발견하지 못했으나, `UI/ScoreLabel`이 "Score: N" 형식으로 현재 점수만 보여주고 목표 개수(총 아이템 수)를 알려주지 않아, 플레이어가 몇 개를 더 모아야 클리어되는지 알 수 없는 점을 확인함. design.md 핵심 루프의 "점수가 오르고 화면에 표시된다"는 이미 문자 그대로는 충족되어 있었지만, 수집형 게임에서 진행도(N/총개수)를 보여주는 것은 새로운 게임플레이 기능(적/타이머/레벨/사운드 등 design.md가 막은 확장)이 아니라 기존에 이미 구현된 점수 표시 자체의 완성도를 높이는 것이므로 규칙 1(합격 기준)에 따라 이번 세션 작업으로 진행함):
  - `scripts/main.gd`: `_update_label()`의 텍스트 포맷을 `"Score: %d"` → `"Score: %d / %d"` (score / total_items)로 변경.
  - `tests/loop_headless_test.gd`: 변경된 텍스트 포맷에 맞춰 `expected_score_text`를 `"Score: %d / %d" % [total_items, total_items]`로 갱신.
- 확인: `godot --headless --path . --quit` 에러 없음. `godot --headless --path . --script res://tests/loop_headless_test.gd` 실행 결과 `HEADLESS_LOOP_TEST: PASS (score=Score: 3 / 3, clear=true)` — 포맷 변경 후에도 이동→수집→점수→클리어 전체 루프 정상 동작 확인.
- 다음 할 일: design.md의 1차 완료 정의는 여전히 충족된 상태다. inbox.md에 새 지시가 없는 한, 다음 세션도 design.md가 명시적으로 제한한 확장 범위(적, 타이머, 여러 레벨, 사운드 등)를 임의로 진행하지 말아야 한다. 이번 세션까지 UI 표시·앵커·충돌 판정·텍스처·창 리사이즈에 대한 점검이 여러 차례 반복되었으므로, 다음 자동 세션은 (1) 여전히 남아있을 수 있는 세부 결함을 새로운 관점에서 찾아보되 억지로 만들어내지 말고, (2) 특별한 결함이 없다면 사용자에게 inbox.md를 통한 다음 확장 방향(적, 타이머, 여러 레벨, 사운드, 재시작 기능 등) 지시를 요청하며 대기하는 것이 맞다.

---

### #12 — 2026-09-01 (자동 세션)

- 계기: inbox #1(design.md를 "동물의 숲 스타일 나만의 섬" 기획으로 전면 교체) 처리. inbox #1의 지시 3개 중 이번 세션은 규칙 4(기능 하나만)에 따라 지시 1번(구 프로토타입 정리)만 처리했다. 지시 2·3번(새 기획 로드맵의 첫 조각 구현, 세부 판단 기준)은 다음 세션 이후로 이어간다.
- 한 일:
  - 이전 design.md(탑다운 아이템 수집 프로토타입) 기준으로 만들어졌던 `scenes/Item.tscn`, `scripts/item.gd`, `scripts/main.gd`(점수/클리어 로직), `tests/loop_headless_test.gd`를 삭제. 새 기획(나만의 섬 라이프시뮬레이션)과 무관한 코드이기 때문.
  - `scenes/Main.tscn`을 `Player` 인스턴스 하나만 남긴 최소 상태로 재작성 — Item 인스턴스 3개, `UI` CanvasLayer(ScoreLabel/ClearLabel), `main.gd` 스크립트 연결을 모두 제거.
  - `scripts/player.gd`(캐릭터 이동)와 `scenes/Player.tscn`은 새 기획의 "캐릭터 이동/카메라" 단계에서도 그대로 쓸 수 있어 유지.
- 확인: `godot --headless --path . --quit` 에러 없음 (파싱/런타임 에러 없음). 정리 후 남은 씬 구조가 단순해 헤드리스 통합 테스트는 이번엔 별도로 만들지 않음 — 다음 세션에서 새 기획 기준의 핵심 루프가 생기면 그에 맞는 테스트를 다시 만든다.
- 다음 할 일: design.md의 "진행 방식에 대한 참고"에 명시된 순서의 첫 단계인 **캐릭터 이동/카메라**를 이어간다. 이동은 이미 있으므로, 다음 세션은 `Camera2D`를 `Player.tscn`에 추가해 카메라가 캐릭터를 따라다니게 만드는 작은 단위 하나만 구현하는 것을 권장한다. inbox #1의 지시 2·3번(로드맵 순서 참고, 세부 수치는 상식적 기본값으로 판단 후 근거를 status.md에 기록)은 계속 유효하므로 앞으로도 참고할 것.

---

### #13 — 2026-09-01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #12가 남긴 다음 할 일(캐릭터 이동/카메라 중 카메라 구현)을 그대로 이어받음.
- 한 일:
  - `scenes/Player.tscn`에 `Camera2D` 자식 노드 추가. `position_smoothing_enabled = true`, `position_smoothing_speed = 8.0`으로 설정해 카메라가 캐릭터를 부드럽게 따라가도록 함(딱딱하게 순간 이동하듯 붙는 것보다 자연스러운 느낌을 위한 상식적 기본값 — 수치 자체는 design.md 범위 밖이라 하네스가 임의로 정함, 값이 과하다고 판단되면 다음 세션에서 조정 가능).
  - `Camera2D`가 `Player`(CharacterBody2D)의 자식이라 별도 스크립트 없이 캐릭터 이동에 따라 자동으로 카메라가 따라감. Godot 4의 `Camera2D.enabled` 기본값이 `true`이고 씬 내 유일한 카메라이므로 별도로 활성화 처리할 필요 없음.
  - 현재 `Main.tscn`에는 Player 외 다른 콘텐츠(지형 등)가 없어 카메라 이동 효과가 시각적으로 두드러지진 않지만, 다음 로드맵 단계인 "섬 기본 지형"이 추가되면 바로 의미가 생기는 구조.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 씬 구조가 단순해 별도 헤드리스 통합 테스트는 만들지 않음 — Camera2D는 로직이 아니라 씬 구성이라 코드 테스트로 검증할 대상이 마땅치 않다고 판단.
- 다음 할 일: design.md 로드맵의 다음 단계인 **섬 기본 지형**을 시작한다. 가장 작은 단위로는 `TileMap`(또는 최소한 배경으로 쓸 단색/절차적 텍스처의 바닥 `Sprite2D`/`ColorRect`) 하나를 `Main.tscn`에 추가해 Player가 밟고 다닐 "섬 바닥"의 시각적 기준을 마련하는 것을 권장한다. 아직 아트 리소스가 없으므로(design.md "범위 밖" 항목) 절차적 색상 텍스처 등 상식적 기본값으로 최소 구현하고, 실제 섬 모양(경계, 지형 기복 등)은 이후 세션에서 점진적으로 확장한다.

---

### #14 — 2026-09-01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #13이 남긴 다음 할 일(섬 기본 지형)을 그대로 이어받음.
- 한 일:
  - `scripts/terrain.gd` 신설: `Node2D`에 부착. `_ready()`에서 `Image.create()` + `ImageTexture.create_from_image()`로 두 개의 절차적 단색 텍스처를 생성해 자식 `Sprite2D`(`Ocean`, `Island`)에 각각 할당. 기존 `player.gd`/과거 `item.gd`에서 쓰던 "코드로 절차적 단색 텍스처 생성" 패턴을 그대로 따름 — design.md "범위 밖"(아트 리소스 미정) 항목에 대한 상식적 기본값.
  - `Ocean`: 3000x2000 파란색(0.2, 0.5, 0.8) — 섬을 둘러싼 바다.
  - `Island`: 2000x1300 초록색(0.35, 0.65, 0.25) — 플레이어가 밟고 다닐 육지. 바다보다 작아서 육지 경계 바깥은 바다가 보임 — "섬" 형태를 시각적으로 표현.
  - `scenes/Main.tscn`: `Terrain`(Node2D, `terrain.gd` 연결) 노드를 `Player`보다 먼저(트리 순서상 앞에) 추가해 지형이 배경으로 먼저 그려지고 Player가 그 위에 그려지도록 함. `Ocean`/`Island` 두 `Sprite2D`를 Player 시작 위치(576, 324)와 같은 좌표에 중심을 맞춰 배치해 Player가 섬 중앙에서 시작하도록 함.
  - 섬 경계에 충돌/이동 제한은 아직 없음(범위 밖) — 이번 세션은 시각적 "기본 지형"만 다룸. 경계 충돌은 design.md 로드맵상 별도 단계(채집/사냥/포획 이전 어딘가)로 미룸.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). Terrain은 정적 배경 스프라이트라 별도 헤드리스 로직 테스트는 만들지 않음 — 검증할 게임플레이 로직(충돌/점수 등)이 없고 시각적 배치 확인은 사람이 에디터로 보는 것이 더 적절하다고 판단.
- 다음 할 일: design.md 로드맵의 다음 단계인 **채집/사냥/포획** 준비 작업으로, 섬 경계 밖(바다)으로 Player가 나가지 못하도록 막는 경계 충돌(예: Island 크기에 맞춘 `StaticBody2D` + `CollisionShape2D` 벽, 또는 좌표 클램프)을 추가하는 것을 권장한다. 이는 "섬 기본 지형"의 자연스러운 마무리이자, 이후 채집 대상(나무/식물/동물)을 섬 안에 배치하기 전에 플레이어 이동 범위를 확정해두면 좋기 때문이다. 사람이 직접 에디터로 플레이해 섬/바다 배치가 시각적으로 자연스러운지 확인하는 것도 권장한다.

---

### #15 — 2026-09-01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #14가 남긴 다음 할 일(섬 경계 충돌)을 그대로 이어받음.
- 한 일:
  - `scripts/terrain.gd`: Island 텍스처 크기(`ISLAND_SIZE`)·바다 텍스처 크기(`OCEAN_SIZE`)를 상수로 분리하고, `_create_boundary_walls()`를 추가해 Island 둘레에 `StaticBody2D`("IslandBounds") + `CollisionShape2D` 4개(상/하/좌/우, 두께 40px, 모서리까지 겹치도록 양옆으로 살짝 더 길게)를 절차적으로 생성. 벽 위치/크기를 `ISLAND_SIZE`에서 그대로 계산하므로, 나중에 섬 크기가 바뀌어도 텍스처와 충돌 벽이 어긋나지 않는다(#8에서 배운 "값 중복으로 인한 잠재 버그" 교훈을 반영).
  - Player가 `CharacterBody2D` + `move_and_slide()`로 이동하므로 벽은 `StaticBody2D`의 물리 충돌만으로 자연스럽게 동작 — Player 스크립트나 씬 변경 불필요.
  - `tests/loop_headless_test.gd`(구 프로토타입, #12에서 삭제)와 같은 패턴으로 `tests/boundary_headless_test.gd` 신설: `Main.tscn`을 직접 인스턴스화하고 Player를 섬 중앙에 놓은 뒤 250 물리 프레임 동안 오른쪽으로 이동시켜, 섬 오른쪽 경계(x=1576)를 넘지 못하고 벽 앞(player 반경만큼 안쪽)에서 멈추는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/boundary_headless_test.gd` 실행 결과 `HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)` — Player가 섬 중심에서 오른쪽으로 계속 이동해도 경계(1576) 안쪽 1560에서 멈춰, 벽에 막혀 바다로 못 나감을 확인. (반경 16px인 Player 충돌 박스 절반만큼 안쪽에서 멈추는 것은 물리적으로 정확한 동작.)
- 남은 제약: 이번 테스트는 오른쪽 방향 하나만 검증했다. 상/하/좌 방향 벽도 동일한 코드 경로(`_create_boundary_walls`)로 생성되므로 로직상 대칭적으로 동작할 것으로 예상하지만, 사람이 에디터로 네 방향 모두 실제로 막히는지 시각적으로 확인하는 것을 권장한다.
- 다음 할 일: design.md 로드맵의 "섬 기본 지형" 단계가 경계 충돌까지 포함해 마무리되었다고 판단한다. 다음 단계는 **채집/사냥/포획**이다. 아직 아무 채집/사냥 대상이 없으므로, 가장 작은 단위로는 섬 안에 "나무" 1종(등급 없이 최소 1개체) 오브젝트를 배치하고 상호작용(예: 근접 후 특정 키 입력 시 사라짐/자원 획득 등 최소한의 동작) 중 가장 단순한 조각 하나만 구현하는 것을 권장한다. design.md의 등급 체계·장비는 아직 범위 밖이므로 이번엔 손대지 않는다.

---

### #16 — 2026-09-01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #15가 남긴 다음 할 일(채집/사냥/포획의 첫 조각 — 나무 1종 배치 + 최소 상호작용)을 그대로 이어받음.
- 한 일:
  - `scripts/tree.gd` 신설: `Area2D` 기반. `body_entered`/`body_exited`로 `player` 그룹 멤버가 상호작용 범위(반경 60px 원형 `CollisionShape2D`)에 들어왔는지 추적(`player_nearby`)하고, 범위 안에서 `ui_accept`(기본 키: Space/Enter)를 누르면 `queue_free()`로 나무를 없애고 `print()`로 획득 메시지를 남긴다. 트렁크(갈색 사각형)+캐노피(초록 사각형)를 `Image`로 절차적으로 그려 `Sprite2D` 텍스처에 할당 — 기존 player.gd/terrain.gd가 써온 "코드로 절차적 텍스처 생성" 패턴을 그대로 따름.
  - 커스텀 입력 액션을 새로 만들지 않고 Godot 기본 액션인 `ui_accept`를 상호작용 키로 재사용했다. 근거: `project.godot`의 `[input]` 섹션에 `InputEventKey` 리소스를 수동으로 작성하면 형식 오류를 내기 쉽고, `ui_accept`(Space/Enter)는 이미 기본 입력맵에 있어 "채집 가능 여부를 알리는 최소 UI(예: 안내 문구)가 아직 없는" 현재 단계에서 상식적인 기본값으로 충분하다고 판단. 전용 "상호작용" 키 바인딩이 필요해지면(다른 액션과 겹치기 시작하면) 이후 세션에서 커스텀 액션으로 분리하면 된다.
  - `scenes/Tree.tscn` 신설: `Area2D`("Tree") + `Sprite2D` + 원형 `CollisionShape2D`(반지름 60).
  - `scenes/Main.tscn`: `Tree` 인스턴스 1개를 섬 안쪽, Player 시작 위치(576,324)와 겹치지 않는 (900,500)에 배치.
  - `tests/tree_harvest_headless_test.gd` 신설: `Main.tscn`을 인스턴스화해 (1) 상호작용 범위 밖에서 `ui_accept`를 눌러도 나무가 사라지지 않는지, (2) Player를 나무 위치로 이동시켜 범위 안에 들어간 뒤 `player_nearby`가 채워지는지, (3) 그 상태에서 `ui_accept`를 누르면 실제로 나무가 트리에서 제거되는지를 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/tree_harvest_headless_test.gd` 실행 결과 `HEADLESS_TREE_HARVEST_TEST: PASS`(콘솔에 "나무를 채집했다: 통나무 x1" 출력 확인). 기존 `godot --headless --path . --script res://tests/boundary_headless_test.gd`도 `HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)`로 재확인해 섬 경계 충돌 로직에 회귀가 없음을 검증.
- 남은 제약: 채집 시 자원 획득이 `print()` 콘솔 출력뿐이고, 화면에 보이는 UI(인벤토리, 획득 알림)나 실제 자원 카운트 저장은 아직 없다. 등급 시스템(design.md 명시)도 이 나무에는 아직 없어 항상 한 번에 채집된다. 이런 부분은 design.md 로드맵상 "등급·장비" 단계 및 그 이후에 다룰 범위라 이번 세션에서는 의도적으로 손대지 않았다.
- 다음 할 일: 채집/사냥/포획 단계를 계속 이어가려면, 다음으로 작은 단위 후보는 (1) 나무 채집 결과를 화면에서 확인 가능하게 만드는 최소 UI(예: 획득 시 잠깐 뜨는 텍스트, 또는 좌상단 통나무 개수 표시), 또는 (2) design.md가 언급한 "동물" 쪽 첫 조각(예: 도망 없이 고정된 동물 1종을 배치해 사냥 상호작용의 뼈대만 우선 만들기) 중 하나다. 사람이 에디터로 직접 플레이해 나무에 다가가 Space/Enter로 채집되는 조작감을 확인하는 것도 권장한다. inbox.md에 새 지시가 없다면 다음 세션은 이 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행한다.

---

### #17 — 2026-09-01 11:39 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #16이 남긴 두 후보(채집 결과 최소 UI vs 동물 첫 조각) 중, 규칙 4(기능 하나만)에 따라 "채집 결과를 화면에서 확인 가능하게 만드는 최소 UI"를 선택해 진행함 — 이미 구현된 나무 채집 기능의 완성도를 높이는 쪽이 새로운 상호작용 대상(동물)을 시작하는 것보다 더 작은 단위라고 판단.
- 한 일:
  - `scripts/tree.gd`: `harvested(resource_name: String, amount: int)` 시그널 추가. `_harvest()`에서 `queue_free()` 전에 `harvested.emit("통나무", 1)`을 emit하도록 변경.
  - `scripts/main.gd` 신설: `Main`(Node2D) 루트에 부착. `_ready()`에서 `harvestable` 그룹(현재는 Tree)의 모든 노드에 대해 `harvested` 시그널을 구독하고, `inventory: Dictionary`에 자원명별 개수를 누적한 뒤 `UI/InventoryLabel` 텍스트를 "자원명: 개수" 형식(줄바꿈으로 여러 자원 구분)으로 갱신. 인벤토리가 비어 있으면(아직 아무것도 채집하지 않았으면) 라벨을 빈 문자열로 둬 화면에 불필요한 텍스트가 뜨지 않게 함.
  - `scenes/Main.tscn`: `main.gd`를 Main 노드 스크립트로 연결. `UI`(CanvasLayer) + `UI/InventoryLabel`(Label, 좌상단 offset 16,16~300,100, 폰트 크기 24) 추가.
  - `tests/tree_harvest_headless_test.gd`: 기존 채집 성공/실패 검증에 이어, 채집 후 `UI/InventoryLabel.text`가 "통나무: 1"인지 확인하는 검증을 추가.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/tree_harvest_headless_test.gd` 실행 결과 `HEADLESS_TREE_HARVEST_TEST: PASS`(라벨 텍스트 검증 포함). `godot --headless --path . --script res://tests/boundary_headless_test.gd` 실행 결과 `HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)` — 섬 경계 충돌 로직 회귀 없음 재확인.
- 남은 제약: 인벤토리는 세션 중 메모리에만 존재하며(저장/불러오기 없음), 자원 종류가 늘어나도 대응 가능한 구조이지만 아직 통나무 하나뿐이라 다중 자원 표시(줄바꿈 레이아웃)는 실제 화면에서 시각적으로 확인되지 않았다. design.md의 등급 시스템도 여전히 미적용.
- 다음 할 일: design.md 로드맵상 채집/사냥/포획 단계를 계속 진행한다면, 다음 후보는 design.md가 언급한 "동물" 쪽 첫 조각(예: 도망 트리거 없이 고정된 동물 1종을 배치해 사냥/포획 상호작용의 뼈대만 우선 만들기)이 자연스럽다 — 채집(나무) 쪽은 최소 UI까지 갖춰졌으므로, 이제 사냥/포획이라는 다른 축의 첫 조각을 시작할 차례. 사람이 에디터로 직접 플레이해 인벤토리 라벨이 실제로 잘 보이는지(폰트 크기, 위치, 여러 줄일 때 겹침 여부) 확인하는 것도 권장한다. inbox.md에 새 지시가 없다면 다음 세션은 이 방향으로 진행한다.

---

### #18 — 2026-09-01 11:42 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #17이 남긴 다음 할 일(design.md가 언급한 "동물" 쪽 첫 조각 — 도망 트리거 없이 고정된 동물 1종을 배치해 사냥/포획 상호작용의 뼈대만 우선 만들기)을 그대로 이어받음.
- 한 일:
  - `scripts/animal.gd` 신설: `tree.gd`와 동일한 패턴(Area2D, `player_nearby` 추적, `ui_accept`로 상호작용)을 따르되, 나무처럼 한 번에 사라지는 대신 체력(`health`, 기본 100)을 가지고 `ui_accept`를 누를 때마다 34씩 깎이는 "공격" 방식으로 구현. 체력이 0 이하가 되면 `harvested` 시그널로 자원("고기" x1)을 emit하고 `queue_free()`. 트렁크/캐노피 대신 단색 갈색(0.6, 0.4, 0.2) 사각형을 절차적 텍스처로 사용해 나무와 시각적으로 구분.
  - 동물을 `harvestable` 그룹에 등록해, 이미 있는 `main.gd`의 인벤토리 로직(그룹의 `harvested` 시그널을 구독해 자원별 개수를 누적하고 `UI/InventoryLabel`에 표시)을 그대로 재사용 — `main.gd`는 수정하지 않음. "harvested/harvestable"이라는 이름이 채집뿐 아니라 사냥으로 얻는 자원도 포괄할 만큼 일반적이라고 판단했기 때문.
  - `scenes/Animal.tscn` 신설: `Area2D`("Animal") + `Sprite2D` + 원형 `CollisionShape2D`(반지름 50).
  - `scenes/Main.tscn`: `Animal` 인스턴스 1개를 섬 안쪽, Player 시작 위치(576,324)·Tree(900,500)와 겹치지 않는 (300,450)에 배치.
  - design.md가 명시한 포획(마취총, 체력 8% 미만 조건)과 도주 AI(발소리/시야/피격 감지)는 이번 세션 범위에서 의도적으로 제외했다 — 포획은 별도 무기/아이템 시스템이, 도주 AI는 감지/이동 로직이 각각 필요해 "기능 하나만"(규칙 4)을 넘어서기 때문. status.md #16이 "고정된 동물 1종 배치"를 제안한 것과 같은 이유로, 이번 조각은 사냥(반복 공격 → 처치 → 자원 획득)까지만 다룬다.
  - `tests/animal_hunt_headless_test.gd` 신설: `Main.tscn`을 인스턴스화해 (1) 범위 밖에서 `ui_accept`를 눌러도 체력이 줄지 않는지, (2) Player가 범위 안에 들어가면 `player_nearby`가 설정되는지, (3) 체력이 0 이하가 될 때까지(3회) 반복 공격하면 실제로 동물이 사라지고 인벤토리 라벨이 "고기: 1"이 되는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/animal_hunt_headless_test.gd` 실행 결과 `HEADLESS_ANIMAL_HUNT_TEST: PASS (hits=3)`. 기존 `tests/tree_harvest_headless_test.gd`(`HEADLESS_TREE_HARVEST_TEST: PASS`), `tests/boundary_headless_test.gd`(`HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)`)도 재실행해 회귀 없음을 확인.
- 남은 제약: 동물은 완전히 고정되어 있고(이동/애니메이션 없음), 사냥 판정도 "가까이서 아무 키나 반복 누르면 죽는다"는 매우 단순한 형태다. 포획 분기(체력 8% 미만 + 마취총)가 없어 design.md의 "동물을 죽일 수도, 포획할 수도 있다"는 아직 절반(죽이기)만 구현된 상태. 화면에 동물 체력을 보여주는 UI도 없어(콘솔 출력뿐) 플레이어가 몇 대 더 때려야 하는지 알 수 없다.
- 다음 할 일: 사냥/포획 축을 계속 이어가려면 다음으로 작은 단위 후보는 (1) 체력을 8% 미만으로 낮췄을 때 다른 입력(예: 별도 액션 또는 조건)으로 "포획"과 "사냥(처치)"을 구분하는 최소 분기 추가, 또는 (2) 화면에 동물 체력을 보여주는 간단한 UI(예: 체력바 또는 숫자)다. 도주 AI(발소리/시야/피격 감지)는 별도의 더 큰 작업이므로 서두르지 않는다. inbox.md에 새 지시가 없다면 다음 세션은 규칙 4(기능 하나만)에 따라 이 중 하나를 골라 진행한다.

---

### #19 — 2026-09-01 11:45 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #18이 남긴 두 후보(포획/사냥 분기 vs 동물 체력 UI) 중 "화면에 동물 체력을 보여주는 UI"를 선택했다 — 포획 분기는 design.md가 명시한 마취총(별도 무기/아이템)이 아직 없는 상태에서 입력 조건만으로 흉내 내면 기획과 어긋난 임시방편이 될 위험이 있는 반면, 체력 UI는 이미 존재하는 `health` 값을 화면에 노출하는 것뿐이라 범위가 더 작고 확실하다고 판단했다.
  - `scenes/Animal.tscn`: `Sprite2D` 위(오프셋 y=-50 근처)에 `HealthLabel`(Label, 폭 80 중앙 정렬, 폰트 크기 20) 추가. 처음에는 `Label2D` 타입으로 시도했으나 Godot 4.7에 그런 내장 클래스가 없어("Could not find type Label2D") 파싱 에러가 났다 — Node2D 자식으로 `Label`(Control)을 두면 부모의 2D 트랜스폼을 그대로 따라가며 월드 공간에 떠 있는 텍스트로 동작하는 일반적인 패턴이라는 것을 확인하고 `Label`로 교체함.
  - `scripts/animal.gd`: `@onready var health_label: Label = $HealthLabel` 추가, `_update_health_label()`을 신설해 텍스트를 `"%d/%d" % [health, MAX_HEALTH]` 형식으로 갱신. `_ready()`에서 초기값(100/100) 표시, `_attack()`에서 공격할 때마다(단, 사냥으로 죽어서 `queue_free()`되는 경우는 제외) 갱신하도록 호출.
  - `tests/animal_hunt_headless_test.gd`: 1회 공격 후 `HealthLabel.text`가 "66/100"인지 확인하는 검증을 추가.
- 확인: `godot --headless --path . --quit` 에러 없음(Label2D 시행착오 이후 최종적으로 파싱/런타임 에러 없음 확인). `godot --headless --path . --script res://tests/animal_hunt_headless_test.gd` 실행 결과 `HEADLESS_ANIMAL_HUNT_TEST: PASS (hits=3)` — 체력 라벨 검증 포함. 회귀 확인을 위해 `tests/tree_harvest_headless_test.gd`(`HEADLESS_TREE_HARVEST_TEST: PASS`), `tests/boundary_headless_test.gd`(`HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)`)도 재실행해 이상 없음을 확인.
- 남은 제약: 체력 표시는 플레이어와의 거리와 무관하게 항상 보인다(가까이 가야만 보이게 하는 조건 없음) — design.md에 그런 제약이 명시되지 않아 상식적인 기본값으로 항상 표시함. 체력바(그래픽 바) 대신 숫자(N/100) 텍스트로만 표시해 시각적으로는 소박하다. 포획 분기(체력 8% 미만 + 마취총)는 여전히 구현되지 않았다.
- 다음 할 일: 사냥/포획 축의 다음 단위로는 design.md가 명시한 **포획**(체력 8% 미만 상태에서 마취총으로 포획)을 시작하는 것이 자연스럽다. 마취총이라는 아이템/장비 개념이 아직 전혀 없으므로, 가장 작은 단위로는 (1) 플레이어가 소지한 것으로 가정하는 최소한의 "마취총" 개념(예: 별도 입력 액션 하나, 아이템 슬롯 없이)을 도입해 체력이 8% 미만일 때 그 입력으로 포획(동물이 사라지고 "포획 성공" 로그/자원 대신 포획 상태 기록)되는 분기를 추가하는 것, 또는 (2) 도주 AI(발소리/시야/피격 감지 중 하나)의 첫 조각을 시작하는 것 중 하나다. 두 방향 모두 design.md 로드맵(채집/사냥/포획)의 핵심에 해당하므로, inbox.md에 새 지시가 없다면 다음 세션은 규칙 4(기능 하나만)에 따라 이 중 더 작게 쪼갤 수 있는 쪽을 골라 진행한다.

---

### #20 — 2026-09-01 11:49 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #19가 남긴 두 후보(포획 분기 vs 도주 AI) 중 "포획 분기"를 선택했다 — 도주 AI는 감지(발소리/시야)와 이동(도망 경로)을 함께 설계해야 해 규칙 4(기능 하나만)를 넘어서는 반면, 포획은 이미 있는 `health` 값에 조건 분기 하나만 추가하면 되어 더 작은 단위였다.
- 한 일:
  - `scripts/animal.gd`: design.md의 포획 조건(체력 8% 미만 + 마취총)을 구현. 마취총이라는 아이템/장비 개념이 아직 없으므로 "이미 마취총을 들고 있다"고 가정하고, 전용 입력 액션 `capture`(C 키, `project.godot`의 `[input]` 섹션에 신규 등록)를 마취총 발사로 취급했다. `_try_capture()`가 `health < MAX_HEALTH * 0.08`이면 `captured` 시그널을 emit하고 `queue_free()`, 아니면 실패 메시지만 출력한다.
  - `ATTACK_DAMAGE`를 34 → 31로 조정했다. 기존 34는 100→66→32→(-2, 즉사) 순서라 정수 체력이 8%(8) 미만인 1~7 구간에 절대 도달하지 못해 포획이 원천적으로 불가능한 구조였다. 31로 바꾸면 100→69→38→7이 되어 3회 공격 후 정확히 7(8% 미만)에서 멈추므로, 플레이어가 거기서 공격을 멈추고 포획으로 전환할 수 있다. 이는 design.md가 명시한 포획 조건을 실제로 도달 가능하게 만들기 위한 균형 조정이라 이번 세션 범위로 포함했다(새 기능이 아니라 기존 수치가 새 기능을 원천 차단하는 결함 수정에 가까움).
  - `scripts/main.gd`: `capturable` 그룹의 `captured` 시그널을 구독해 포획한 동물을 `captured_animals` 딕셔너리에 누적하고 `UI/CaptureLabel`에 "포획: 동물 x1" 형식으로 표시. 포획은 소비되는 자원이 아니라 "잡아서 소유하게 된 개체"라는 점이 채집/사냥 자원과 달라 기존 `inventory`/`InventoryLabel`과 분리했다.
  - `scenes/Main.tscn`: `UI/CaptureLabel`(Label) 추가, `InventoryLabel` 바로 아래(offset 16,110~300,194)에 배치해 겹치지 않게 함.
  - `tests/animal_hunt_headless_test.gd`: `ATTACK_DAMAGE` 변경(34→31)에 맞춰 1회 공격 후 기대 체력 라벨을 "66/100" → "69/100"으로, 주석의 "3회 -> 사망"을 "4회 -> 사망"으로 갱신.
  - `tests/animal_capture_headless_test.gd` 신설: (1) 체력이 100/100(8% 이상)일 때 `capture` 액션을 눌러도 포획되지 않는지, (2) `ui_accept`로 3회 공격해 체력을 7/100(8% 미만)까지 낮춘 뒤 `capture`를 누르면 실제로 동물이 사라지고 `CaptureLabel`이 "포획: 동물 x1"이 되는지, (3) 이때 죽인 것이 아니므로 `InventoryLabel`(고기)에는 아무것도 기록되지 않는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음 — `project.godot`에 `[input]` 섹션을 직접 추가했음에도 형식 오류 없이 파싱됨). `godot --headless --path . --script res://tests/animal_capture_headless_test.gd` → `HEADLESS_ANIMAL_CAPTURE_TEST: PASS`. 회귀 확인을 위해 재실행한 `tests/animal_hunt_headless_test.gd`(`HEADLESS_ANIMAL_HUNT_TEST: PASS (hits=4)`), `tests/tree_harvest_headless_test.gd`(`HEADLESS_TREE_HARVEST_TEST: PASS`), `tests/boundary_headless_test.gd`(`HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)`) 모두 이상 없음.
- 남은 제약: `capture` 액션은 아무 제약 없이 근접만 하면 누구나 즉시 쏠 수 있다 — 실제 마취총이라면 재장전/사거리/탄약 개념이 있어야 하지만 이는 design.md가 "범위 밖"으로 명시한 밸런스 수치라 이번 세션에서는 다루지 않았다. 포획된 동물은 `queue_free()`로 사라지고 "포획 개체 수"만 라벨에 남을 뿐, 실제로 포획한 동물을 나중에 활용(사육/전시/판매 등)하는 시스템은 아직 없다 — design.md에도 포획 이후 활용은 명시되어 있지 않아 범위 밖으로 남겨둠. 도주 AI(발소리/시야/피격 감지)는 여전히 구현되지 않아, design.md의 "동물은 죽일 수도, 포획할 수도 있다"는 이제 두 경로 모두 갖췄지만 "고정되어 도망가지 않는" 상태는 그대로다.
- 다음 할 일: design.md 로드맵상 다음으로 자연스러운 단위는 **도주 AI**의 첫 조각이다. 세 트리거(발소리 감지/시야 감지/피격 감지) 중 가장 작게 쪼갤 수 있는 것은 "피격당했을 때 도망" — 이미 `_attack()`이 호출되는 시점이 있으므로, 여기에 이동 로직(예: 플레이어 반대 방향으로 일정 시간 이동)만 추가하면 되어 새로운 감지 시스템(시야 레이캐스트, 발소리 반경 등)을 설계하지 않아도 된다. inbox.md에 새 지시가 없다면 다음 세션은 이 방향을 규칙 4(기능 하나만)에 따라 진행하는 것을 권장한다.

---

### #21 — 2026-09-01 11:53 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #20이 남긴 다음 할 일(도주 AI 첫 조각 — 피격당했을 때 도망)을 그대로 이어받음.
- 한 일:
  - `scripts/animal.gd`: `is_fleeing`/`flee_timer`/`flee_direction` 상태와 `FLEE_SPEED`(220.0)/`FLEE_DURATION`(0.6초) 상수를 추가. `_attack()`이 동물을 죽이지 않고 살아남긴 경우(체력 0 초과) `_start_fleeing()`을 호출해, 공격 시점의 `player_nearby` 위치 반대 방향(`global_position - player_nearby.global_position`을 정규화, 두 위치가 같으면 임의로 오른쪽)을 `flee_direction`으로 설정하고 도주 상태에 진입시킨다. 새로 추가한 `_physics_process(delta)`가 도주 중일 때만 `global_position += flee_direction * FLEE_SPEED * delta`로 이동시키고 `flee_timer`가 0 이하가 되면 도주를 종료한다. Animal이 `Area2D`(물리 바디가 아님)라 `move_and_slide()` 대신 직접 `global_position`을 갱신하는 방식을 택했다.
  - 포획 시도(`_try_capture`, capture 액션/마취총)는 피해를 주는 "공격"이 아니라 별도 행동으로 판단해 도주를 유발하지 않도록 그대로 뒀다 — design.md가 도주 트리거로 명시한 것은 "공격(피격)당했을 때"이지 포획 시도가 아니기 때문. 이 판단은 이번 세션의 임의 해석이라 status.md에 근거를 남긴다.
  - 도주로 동물의 위치가 바뀌면 기존 `Area2D` 상호작용 범위(반경 50px)를 벗어나 `player_nearby`가 `null`이 되므로, 기존 `tests/animal_hunt_headless_test.gd`/`tests/animal_capture_headless_test.gd`가 "제자리에서 연속 공격"을 가정하고 있던 부분이 깨졌다. 두 테스트 모두 매 공격 이후 `animal.is_fleeing`이 `false`로 돌아올 때까지 기다린 뒤 `player.global_position`을 동물의 새 위치로 다시 옮겨 "플레이어가 추격해서 재접근한다"는 상황을 흉내내도록 갱신했다.
  - `tests/animal_flee_headless_test.gd` 신설: Player를 Animal 왼쪽에 두고 1회 공격한 뒤 (1) 공격 직후 `is_fleeing`이 true가 되는지, (2) `flee_direction`이 플레이어 반대쪽(+x)인지, (3) 일정 시간 뒤 도주가 끝나는지(`is_fleeing == false`), (4) 실제로 동물의 위치가 유의미하게(20px 이상) 이동했는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/animal_flee_headless_test.gd` → `HEADLESS_ANIMAL_FLEE_TEST: PASS (moved_distance=132.0)`. 회귀 확인을 위해 재실행한 `tests/animal_hunt_headless_test.gd`(`HEADLESS_ANIMAL_HUNT_TEST: PASS (hits=4)`), `tests/animal_capture_headless_test.gd`(`HEADLESS_ANIMAL_CAPTURE_TEST: PASS`), `tests/boundary_headless_test.gd`(`HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)`), `tests/tree_harvest_headless_test.gd`(`HEADLESS_TREE_HARVEST_TEST: PASS`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 도주는 섬 경계(바다)를 고려하지 않는다 — `Animal`은 `Area2D`라 `IslandBounds`(`StaticBody2D`) 벽과 물리적으로 충돌하지 않으므로, 이론상 도주 방향이 바다 쪽이면 동물이 섬 밖으로 나갈 수 있다. design.md에 이에 대한 제약이 명시되지 않았고 이번 조각은 "피격 시 도망" 자체의 최소 구현에 집중했으므로 의도적으로 남겨둔 범위 밖 항목이다. 나머지 두 트리거(발소리 감지, 시야 감지)도 여전히 미구현이며, 도주 중 플레이어가 다시 근접하면 즉시 상호작용이 재개되는 것도 상식적 기본값일 뿐 별도로 "도주 중에는 상호작용 불가" 같은 명시적 차단은 없다.
- 다음 할 일: 도주 AI를 계속 이어가려면 다음 후보는 (1) 남은 두 도주 트리거 중 하나(발소리 감지 또는 시야 감지 — 둘 다 새로운 감지 로직 설계가 필요해 피격 감지보다 큰 단위), 또는 (2) 이번에 남겨둔 제약인 "도주가 섬 경계를 넘지 않도록 제한"(간단히는 `Island` 범위 내로 `global_position`을 클램프)이다. 후자가 상대적으로 더 작은 단위이므로 규칙 4(기능 하나만)에 따라 먼저 고려해볼 만하다. inbox.md에 새 지시가 없다면 다음 세션은 이 중 하나를 선택해 진행한다.

---

### #22 — 2026-09-01 11:56 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #21이 남긴 두 후보(남은 도주 트리거 vs 섬 경계 클램프) 중 "섬 경계 클램프"를 선택했다 — #21 자체가 이쪽을 상대적으로 더 작은 단위로 평가했고, 발소리/시야 감지는 새로운 감지 로직 설계가 필요해 규칙 4(기능 하나만)를 넘어서기 때문.
  - `scripts/terrain.gd`: `_ready()`에서 `add_to_group("terrain")` 추가. `get_island_bounds() -> Rect2`를 신설해 `island.position`과 `ISLAND_SIZE`로부터 섬의 월드 좌표 경계 사각형을 계산해 반환하도록 함. `ISLAND_SIZE`를 이 스크립트 한 곳에서만 정의하고 다른 스크립트는 이 함수로 조회하게 만들어, #15에서 배운 "값 중복으로 인한 잠재 버그"를 반복하지 않도록 함.
  - `scripts/animal.gd`: `_ready()`에서 `get_tree().get_first_node_in_group("terrain")`으로 Terrain 참조를 캐싱. `_physics_process()`에서 도주 이동(`global_position += flee_direction * FLEE_SPEED * delta`) 직후, `terrain.get_island_bounds()`로 얻은 사각형 범위로 `global_position.x`/`y`를 `clamp()`. Animal은 `Area2D`라 `IslandBounds`(`StaticBody2D`) 벽과 물리적으로 충돌하지 않아 도주 방향이 바다 쪽이면 섬 밖으로 나갈 수 있었던 #21의 남은 제약을 해소함.
  - `tests/animal_flee_headless_test.gd`: 기존 시나리오(왼쪽에서 공격 → 오른쪽으로 도주 확인) 뒤에 두 번째 시나리오를 추가 — Terrain의 `get_island_bounds()`로 실제 경계를 가져와, 동물을 섬 오른쪽 경계 바로 안쪽(경계에서 20px)에 놓고 왼쪽에서 공격해 도주 방향이 경계 바깥(+x, 바다 쪽)이 되게 한 뒤, 도주가 끝날 때까지 기다렸다가 동물의 최종 x좌표가 섬 경계(`bounds.end.x`)를 넘지 않는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/animal_flee_headless_test.gd` → `HEADLESS_ANIMAL_FLEE_TEST: PASS (moved_distance=132.0, boundary_x=1576.0, island_right_edge=1576.0)` — 경계에 정확히 걸려 멈추는 것을 확인. 회귀 확인을 위해 재실행한 `tests/animal_hunt_headless_test.gd`(`HEADLESS_ANIMAL_HUNT_TEST: PASS (hits=4)`), `tests/animal_capture_headless_test.gd`(`HEADLESS_ANIMAL_CAPTURE_TEST: PASS`), `tests/tree_harvest_headless_test.gd`(`HEADLESS_TREE_HARVEST_TEST: PASS`), `tests/boundary_headless_test.gd`(`HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 상/하/좌 방향 경계 클램프는 오른쪽과 동일한 코드 경로(`get_island_bounds()` + `clamp()`)로 동작하므로 로직상 대칭적으로 작동할 것으로 예상하지만, 이번 테스트는 오른쪽 경계 시나리오만 검증했다(#15가 남겼던 것과 같은 종류의 제약). 도주 트리거는 여전히 "피격당했을 때" 하나뿐이며, 발소리 감지와 시야 감지는 미구현이다.
- 다음 할 일: design.md의 도주 트리거 세 가지 중 남은 두 가지(발소리 감지, 시야 감지)를 계속 이어가는 것이 로드맵상 자연스럽다. 이 중 상대적으로 더 작게 쪼갤 수 있는 쪽은 "시야 감지"다 — 발소리는 "발소리"라는 개념 자체(플레이어가 이동 중일 때만 발생, 감지 반경 등)를 새로 정의해야 하는 반면, 시야는 이미 있는 `player_nearby`형 근접 감지(Area2D 반경)를 재사용하거나 약간 확장해 "일정 거리 안에 플레이어가 있으면(장애물 유무는 범위 밖으로 남기고) 도망친다"는 형태로 상대적으로 쉽게 구현할 수 있다. inbox.md에 새 지시가 없다면 다음 세션은 이 방향을 규칙 4(기능 하나만)에 따라 진행하는 것을 권장한다.

---

### #23 — 2026-09-01 12:01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #22가 남긴 다음 할 일(도주 트리거 중 상대적으로 더 작은 단위인 "시야 감지")을 그대로 이어받음.
- 한 일:
  - `scenes/Animal.tscn`: 기존 상호작용용 `CollisionShape2D`(반경 50, Animal 본체의 Area2D 충돌 모양)와 별개로, 자식 노드 `SightArea`(Area2D) + `CollisionShape2D`(반경 180)를 추가. "가까이서 상호작용(공격/포획) 가능"과 "멀리서 눈에 띔(시야)"을 서로 다른 반경의 Area2D 두 개로 분리했다 — 하나의 Area2D 반경만으로는 두 개념을 동시에 표현할 수 없기 때문.
  - `scripts/animal.gd`: `player_in_sight` 상태와 `sight_area.body_entered`/`body_exited` 핸들러를 추가. 플레이어가 `SightArea`에 **처음** 들어올 때(진입 이벤트 1회) `_start_fleeing()`을 호출해 도주를 시작한다 — 시야 안에 머무는 동안 매 프레임 재유발하지 않는 이유는, #21에서 구현한 피격 도주와 같은 "자극 하나당 도주 한 번" 패턴을 유지해 근접 전투 범위 안에서 동물이 끊임없이 미세하게 진동하며 도망다니는 부자연스러운 동작을 피하기 위함이다. 다시 도주를 유발하려면 일단 시야에서 완전히 벗어났다가 재진입해야 한다.
  - `_start_fleeing()`을 `_start_fleeing(threat: Node2D = null)`로 리팩터링해, 피격 도주(기존 `player_nearby` 기준)와 시야 도주(신규 `player_in_sight`/`SightArea`에서 넘어온 body 기준)가 "위협의 반대 방향으로 도망"이라는 동일한 로직을 공유하도록 함 — 두 트리거를 위해 방향 계산 코드를 중복 작성하지 않기 위함.
  - `tests/animal_sight_flee_headless_test.gd` 신설: (1) 시야 범위(180) 밖에서는 도주도 체력 감소도 일어나지 않는지, (2) 상호작용 범위(50) 밖이지만 시야 범위(180) 안(거리 120)으로 접근하면 **공격 입력 없이도** 도주가 시작되는지, 방향이 플레이어 반대쪽인지, 체력은 그대로인지(공격이 아니므로) 검증.
  - 기존 `tests/animal_hunt_headless_test.gd`, `tests/animal_capture_headless_test.gd`, `tests/animal_flee_headless_test.gd`는 모두 플레이어를 동물과 매우 가까운 거리(0~40px)로 텔레포트하는 방식이라, 텔레포트 즉시 시야 범위(180)에도 동시에 진입해 시야 도주가 함께 트리거될 수 있는 상황이었다. 실행해 직접 확인한 결과, 이번 조각에서 발생하는 추가 도주 이동량(프레임당 최대 ~3.7px)이 상호작작 반경(50)이나 섬 경계 클램프 로직에 영향을 줄 만큼 크지 않아 세 테스트 모두 **수정 없이 그대로 통과**했다 — 다만 이는 현재 테스트가 쓰는 특정 거리 값에서 우연히 문제가 없었던 것이지, 시야 도주가 기존 상호작용 로직과 항상 무관하다는 뜻은 아니므로 다음에 상호작용/시야 반경 수치를 조정할 때는 이 네 테스트를 함께 재확인해야 한다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/animal_sight_flee_headless_test.gd` → `HEADLESS_ANIMAL_SIGHT_FLEE_TEST: PASS`. 회귀 확인을 위해 재실행한 `tests/animal_hunt_headless_test.gd`(`HEADLESS_ANIMAL_HUNT_TEST: PASS (hits=4)`), `tests/animal_capture_headless_test.gd`(`HEADLESS_ANIMAL_CAPTURE_TEST: PASS`), `tests/animal_flee_headless_test.gd`(`HEADLESS_ANIMAL_FLEE_TEST: PASS (moved_distance=135.7, boundary_x=1576.0, island_right_edge=1576.0)`), `tests/boundary_headless_test.gd`(`HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)`), `tests/tree_harvest_headless_test.gd`(`HEADLESS_TREE_HARVEST_TEST: PASS`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: design.md의 도주 트리거 세 가지 중 "발소리 감지"만 아직 미구현이다. 시야 도주는 장애물/시야각(FOV) 개념 없이 단순히 원형 반경(180) 안에 있으면 "보인다"고 판정하는 상식적 기본값이다 — 벽/지형에 가려도 감지되는 것은 design.md에 시야각·차폐 규칙이 명시되지 않아 이번 조각의 범위 밖으로 남겨둠. 또한 시야 반경(180)과 상호작용 반경(50) 값은 design.md의 "범위 밖" 밸런스 수치에 해당해 하네스가 임의로 정한 상식적 기본값이며, 플레이했을 때 너무 예민하거나 둔감하면 이후 세션에서 조정 가능하다.
- 다음 할 일: design.md의 동물 도주 트리거 3종 중 남은 하나는 **발소리 감지**다. "발소리"라는 개념을 정의해야 하는데, 가장 작은 단위로는 플레이어가 이동 중(속도 0 초과)일 때만 발동하는 별도의 넓은 반경 감지(예: SightArea보다는 좁고 상호작용 반경보다는 넓은, 예컨대 120px)로 단순화해 "이동 중인 플레이어가 일정 거리 안에 들어오면 도망"으로 구현하는 것을 권장한다 — 시야 감지와 달리 "정지해 있으면 감지되지 않는다"는 조건 하나만 추가하면 되므로, 이번 세션에서 만든 시야 감지 코드(SightArea + 진입 이벤트 1회 트리거 패턴)를 거의 그대로 재사용할 수 있다. 이 세 번째 트리거까지 완성되면 design.md의 "동물 AI — 도주 트리거" 절이 완전히 구현되므로, 그 다음은 로드맵상 "등급·장비" 단계로 넘어가는 것을 고려할 시점이 된다. inbox.md에 새 지시가 없다면 다음 세션은 이 방향으로 진행한다.

---

### #24 — 2026-09-01 15:32 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #23이 남긴 다음 할 일(도주 트리거 3종 중 마지막 남은 "발소리 감지")을 그대로 이어받음. (부수: 세션 시작 시 git status에 #23 기록 커밋이 누락된 채 남아있던 것을 발견해, 이번 세션 작업 전에 먼저 별도 커밋으로 정리했다 — 커밋 `8494771`.)
- 한 일:
  - `scenes/Animal.tscn`: `SoundArea`(Area2D) + `CollisionShape2D`(반경 250)를 새 자식 노드로 추가.
  - `scripts/animal.gd`: `player_in_sound_range` 상태와 `sound_area.body_entered`/`body_exited` 핸들러 추가. 시야 감지(진입 이벤트 1회로 즉시 트리거)와 달리, 발소리는 "정지해 있으면 감지되지 않는다"는 조건이 design.md에 명시돼 있어 진입 시점에 바로 트리거하지 않고 `_physics_process()`에서 매 프레임 `player_in_sound_range`가 있고 그 `velocity`(CharacterBody2D 내장 속성)가 0보다 큰지(이동 중인지) 확인해서 `_start_fleeing()`을 호출하도록 구현했다.
  - **반경 설계 판단**: status.md #23은 SoundArea를 SightArea(180)보다 좁게(예: 120) 잡을 것을 제안했었으나, 실제로 구현해보니 SightArea ⊂ SoundArea 관계(좁은 반경)로 만들면 플레이어가 걸어서 접근할 때 반드시 SoundArea보다 SightArea를 먼저 지나가게 되어(원이 중첩) 시야 감지가 항상 먼저 발동하고 발소리 감지는 사실상 도달 불가능한 죽은 코드가 되는 문제를 발견했다. 그래서 이번 세션은 제안을 따르지 않고 반대로 SoundArea 반경을 SightArea보다 넓게(250) 설계했다 — "발소리는 눈으로 보기 전에 먼저 들린다"는 상식에 부합하고, 정지한 동물이 시야보다 먼저 소리로 이동 중인 플레이어를 감지하는 시나리오가 실제로 발생 가능해진다. design.md의 "범위 밖" 밸런스 수치에 해당하는 하네스의 판단이라 근거를 여기 남긴다.
  - `tests/animal_sound_flee_headless_test.gd` 신설: 플레이어를 시야 범위(180) 밖·발소리 범위(250) 안(거리 220)에 두고 (1) 정지 상태에서는 도주도 체력 감소도 일어나지 않는지, (2) `Input.action_press("ui_left")`로 이동을 흉내내면 공격 입력 없이도 도주가 시작되는지, 방향이 플레이어 반대쪽인지, 체력은 그대로인지 검증. 기존 테스트들(`animal_hunt`/`animal_capture`/`animal_flee`/`boundary`/`tree_harvest`)은 코드 변경 없이 재실행만 해 회귀 여부를 확인했다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/animal_sound_flee_headless_test.gd` → `HEADLESS_ANIMAL_SOUND_FLEE_TEST: PASS`. 회귀 확인을 위해 재실행한 `tests/animal_hunt_headless_test.gd`(`HEADLESS_ANIMAL_HUNT_TEST: PASS (hits=4)`), `tests/animal_capture_headless_test.gd`(`HEADLESS_ANIMAL_CAPTURE_TEST: PASS`), `tests/animal_flee_headless_test.gd`(`HEADLESS_ANIMAL_FLEE_TEST: PASS (moved_distance=135.7, boundary_x=1576.0, island_right_edge=1576.0)`), `tests/animal_sight_flee_headless_test.gd`(`HEADLESS_ANIMAL_SIGHT_FLEE_TEST: PASS`), `tests/boundary_headless_test.gd`(`HEADLESS_BOUNDARY_TEST: PASS (final_x=1560.0, island_right_edge=1576.0)`), `tests/tree_harvest_headless_test.gd`(`HEADLESS_TREE_HARVEST_TEST: PASS`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 이제 design.md가 명시한 동물 도주 트리거 3종(발소리/시야/피격)이 모두 구현되었다. 다만 세 감지 모두 원형 반경 기반의 단순 판정이며 장애물/차폐, 벽 뒤 은신 같은 개념은 없다(design.md에 명시되지 않아 범위 밖). SoundArea(250)·SightArea(180)·상호작용 반경(50) 수치는 모두 하네스가 임의로 정한 상식적 기본값이라, 실제 플레이해보고 너무 예민하거나 둔감하면 조정 여지가 있다. 동물은 여전히 한 종류뿐이고 등급 개념도 아직 없다.
- 다음 할 일: design.md의 "동물 AI — 도주 트리거" 절이 이번 세션으로 완전히 구현되었으므로, design.md 로드맵(캐릭터 이동/카메라 → 섬 기본 지형 → 채집/사냥/포획 → **등급·장비** → 튜토리얼 → 캐릭터 커스터마이징/슬롯 → 멀티플레이)상 다음 큰 단계는 **등급·장비**다. 아직 등급 체계가 전혀 없으므로, 가장 작은 단위 후보로는 (1) 나무/동물에 등급(예: 1~3단계) 속성을 추가해 등급이 높을수록 체력/채집 시간이 늘어나게 하는 최소 구현, 또는 (2) 등급을 매기기 전에 먼저 "장비"라는 개념 자체가 없다는 점을 고려해 플레이어의 기본 장비(도끼/마취총 등, 지금은 ui_accept/capture 키로 암묵적으로 가정만 하고 있음) 슬롯을 명시적으로 도입하는 것 중 하나다. 등급 쪽이 기존 나무/동물 스크립트에 속성만 얹으면 되어 상대적으로 더 작은 단위이므로 우선 고려할 만하다. inbox.md에 새 지시가 없다면 다음 세션은 규칙 4(기능 하나만)에 따라 이 중 하나를 골라 진행한다.

---

### #25 — 2026-09-01 15:36 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #24가 남긴 두 후보(등급 속성 추가 vs 장비 슬롯 도입) 중 "등급 속성 추가"를 선택했다 — #24 자체가 기존 나무/동물 스크립트에 속성만 얹으면 되어 상대적으로 더 작은 단위라고 평가했고, 장비 슬롯은 아이템 종류·인벤토리 UI까지 새로 설계해야 해 규칙 4(기능 하나만)를 넘어서기 때문.
- 한 일:
  - `scripts/tree.gd`: `@export_range(1, 3) var grade: int = 1` 추가. 기존에는 상호작용 범위 안에서 `ui_accept`를 1회 누르면 즉시 채집되던 것을, `hits_taken` 카운터를 두어 `hits_taken >= grade`가 될 때까지 반복 상호작용이 필요하도록 변경(`_harvest()`를 직접 부르던 자리를 `_register_hit()`으로 감쌈). grade=1이면 기존과 완전히 동일하게 1회 채집되므로 하위호환.
  - `scripts/animal.gd`: 동일하게 `grade` 속성 추가. 기존 `const MAX_HEALTH: int = 100`은 이름을 그대로 유지(기존 헤드리스 테스트들이 `animal.MAX_HEALTH`로 직접 참조하고 있어 이름을 바꾸면 회귀 위험)하되, 실제 체력 상한으로 쓰이는 새 변수 `max_health = MAX_HEALTH * grade`를 도입해 `health`/`health_label`/포획 조건(`CAPTURE_HEALTH_RATIO`)이 모두 이 값을 기준으로 동작하게 했다. `ATTACK_DAMAGE`는 그대로 두어, 등급이 높을수록 사냥에 필요한 타격 횟수가 자연히 늘어나는 방식으로 난이도를 구현했다(별도의 방어력 개념 없이 가장 단순한 형태).
  - 두 스크립트 모두 등급을 시각적으로 확인할 수 있도록 `GradeLabel`(Label, "Lv.N")을 오브젝트 머리 위에 추가(`scenes/Tree.tscn`, `scenes/Animal.tscn`) — `HealthLabel`과 같은 "Node2D 자식 Label" 패턴(#19에서 확립) 재사용.
  - `scenes/Main.tscn`: grade=2인 `Tree2`(1300,650), `Animal2`(700,800) 인스턴스를 각각 하나씩 추가해 기존 grade=1 개체(Tree, Animal)와 나란히 배치, 기능이 실제로 노출되고 검증 가능하도록 함. `main.gd`는 "harvestable"/"capturable" 그룹을 순회하는 방식이라 새 인스턴스도 코드 수정 없이 자동으로 인벤토리/포획 UI에 반영됨.
  - `tests/grade_headless_test.gd` 신설: Tree2가 1회 상호작용으로는 사라지지 않고 2회(grade)째에 사라지는지, Animal2의 `max_health`가 200(=100×2)인지, `ATTACK_DAMAGE`(31) 기준 6회 공격 후 체력이 14/200(8% 미만)에서 여전히 살아있는지, 그 상태에서 `capture`를 누르면 포획되는지 검증. 기존 grade=1 개체(Tree, Animal)는 건드리지 않아 기존 테스트와 시나리오가 겹치지 않는다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/grade_headless_test.gd` → `HEADLESS_GRADE_TEST: PASS`. 회귀 확인을 위해 기존 6종을 모두 재실행: `tests/tree_harvest_headless_test.gd`(`PASS`), `tests/animal_hunt_headless_test.gd`(`PASS (hits=4)`), `tests/animal_capture_headless_test.gd`(`PASS`), `tests/animal_flee_headless_test.gd`(`PASS (moved_distance=135.7, boundary_x=1576.0, island_right_edge=1576.0)`), `tests/animal_sight_flee_headless_test.gd`(`PASS`), `tests/animal_sound_flee_headless_test.gd`(`PASS`), `tests/boundary_headless_test.gd`(`PASS (final_x=1560.0, island_right_edge=1576.0)`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 등급이 채집/사냥 난이도(상호작용 횟수/체력)에만 영향을 주고, 채집·사냥 보상(자원 종류·수량)에는 영향을 주지 않는다 — design.md가 보상 차등까지는 명시하지 않아 범위 밖으로 남겨둠. 마찬가지로 "장비"는 여전히 전혀 없다(플레이어는 여전히 ui_accept/capture 키만으로 무기 없이 상호작용). 등급은 1~3 범위로 export되어 있지만 현재 씬에는 1과 2 등급만 배치되어 있어 3등급 개체는 아직 시각적으로 확인되지 않았다.
- 다음 할 일: design.md 로드맵상 "등급·장비" 단계를 계속 이어가려면, 다음 후보는 (1) status.md #24가 제안했던 "장비" 개념의 첫 조각 — 예를 들어 플레이어에게 명시적인 "도끼"/"마취총" 장비 슬롯을 도입해, 장비가 없으면 채집/사냥/포획 자체가 불가능하도록 만드는 최소 구현, 또는 (2) 이번 세션에서 다루지 않은 "장비 강화" 개념을 준비하기 위한 기초(예: 장비에도 등급/성능 값 부여) 중 하나다. (1)이 design.md의 "유저는 더 높은 등급을 상대하기 위해 장비를 맞춰(강화/교체) 나간다"는 문장에서 아직 구현되지 않은 첫 조각이라 더 자연스럽다. inbox.md에 새 지시가 없다면 다음 세션은 규칙 4(기능 하나만)에 따라 (1)을 우선 고려하는 것을 권장한다.

---

### #26 — 2026-09-01 15:40 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #25가 남긴 두 후보((1) 장비 슬롯 도입 vs (2) 장비 강화 기초) 중 #25 자신이 "더 자연스럽다"고 권장한 (1) 장비 슬롯 도입을 그대로 이어받았다.
- 한 일:
  - `scripts/player.gd`: `equipment: Dictionary`(`{"tool": "도끼", "weapon": "마취총"}`)와 `has_equipped(slot)`/`equip(slot, item_name)`/`unequip(slot)` 헬퍼를 추가했다. 기본값을 빈 슬롯이 아니라 이미 장착된 상태로 준 이유: design.md가 "기본 코디(의상) 제공"을 명시했고, 아직 장비를 얻거나 교체할 상점/제작 시스템이 전혀 없는 현재 단계에서 슬롯을 비워두면 플레이가 처음부터 막히기 때문이다. 즉 "기본 장비 지급"은 상식적 기본값이고, 이번 조각에서 실제로 새로 생긴 것은 "슬롯이 비면(unequip) 상호작용이 실제로 막힌다"는 게이트 로직이다.
  - `scripts/tree.gd`: `_register_hit()`에 `player_nearby.has_equipped("tool")` 체크를 추가 — 도끼가 없으면 상호작용 범위 안이라도 채집이 진행되지 않고 안내 메시지만 출력한다.
  - `scripts/animal.gd`: `_attack()`에 `has_equipped("tool")`, `_try_capture()`에 `has_equipped("weapon")` 체크를 추가 — 기존에 ui_accept(채집·공격)와 capture 액션(포획)으로 나뉘어 있던 키 구분을 그대로 tool/weapon 슬롯 구분에 대응시켰다.
  - `tests/equipment_gate_headless_test.gd` 신설: (1) tool 슬롯을 비우면 나무의 `hits_taken`이 늘지 않고 재장착하면 정상 채집되는지, (2) tool 슬롯을 비우면 동물 공격으로 체력이 줄지 않는지, (3) 체력을 8% 미만(7/100)까지 낮춘 뒤 weapon 슬롯을 비우면 포획이 실패하고 재장착하면 성공하는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/equipment_gate_headless_test.gd` → `HEADLESS_EQUIPMENT_GATE_TEST: PASS`. 회귀 확인을 위해 기존 8종을 모두 재실행: `tests/tree_harvest_headless_test.gd`(`PASS`), `tests/animal_hunt_headless_test.gd`(`PASS (hits=4)`), `tests/animal_capture_headless_test.gd`(`PASS`), `tests/animal_flee_headless_test.gd`(`PASS (moved_distance=139.3, boundary_x=1576.0, island_right_edge=1576.0)`), `tests/animal_sight_flee_headless_test.gd`(`PASS`), `tests/animal_sound_flee_headless_test.gd`(`PASS`), `tests/boundary_headless_test.gd`(`PASS (final_x=1560.0, island_right_edge=1576.0)`), `tests/grade_headless_test.gd`(`PASS`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 장비는 여전히 "tool"/"weapon" 두 슬롯뿐이고, 아이템 종류·강화 수치·상점/제작으로 장비를 얻거나 교체하는 시스템은 전혀 없다(플레이어는 항상 기본 장비를 장착한 채로 시작하며, 벗겨지는 경로도 코드상 `unequip()` 호출뿐 게임 내 UI/이벤트는 없음). 장비 등급(성능 차등)도 아직 없어, "장비를 맞춰(강화/교체) 나간다"는 design.md 문장은 이번 조각으로는 "장비가 있어야 상호작용 가능하다"는 전제만 충족했을 뿐, 강화·교체 자체는 여전히 범위 밖이다.
- 다음 할 일: "등급·장비" 단계를 계속 이어가려면 다음 후보는 (1) 장비를 실제로 얻거나 교체할 수 있는 최소 경로(예: 나무 채집으로 얻는 "통나무"를 소비해 새로운 도끼로 교체, 또는 단순히 인벤토리에 여러 등급의 도끼를 두고 플레이어가 골라 장착하는 UI 없는 최소 로직), 또는 (2) 장비에도 등급/성능 값을 부여해 "높은 등급 장비일수록 채집 속도가 빠르거나 공격력이 세다"처럼 등급 시스템과 장비 시스템을 실제로 연결하는 것 중 하나다. (2)는 이미 있는 `grade`(나무/동물)와 `equipment`(플레이어) 개념을 서로 이어주는 자연스러운 다음 조각이라 규모가 더 작을 수 있다. inbox.md에 새 지시가 없다면 다음 세션은 규칙 4(기능 하나만)에 따라 이 중 하나를 골라 진행한다.

---

### #27 — 2026-09-01 15:45 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #26이 남긴 두 후보((1) 장비 획득/교체 경로 vs (2) 등급-장비 연동) 중 #26 자신이 "규모가 더 작을 수 있다"고 평가한 (2) 등급-장비 연동을 그대로 이어받았다.
- 한 일:
  - `scripts/player.gd`: `equipment` 딕셔너리의 각 슬롯 값을 문자열(`"도끼"`)에서 `{"name": "도끼", "grade": 1}` 형태로 변경. `get_equipment_grade(slot) -> int` 헬퍼를 추가하고, `has_equipped()`는 `name` 필드로, `equip(slot, item_name, grade: int = 1)`은 새 인자(기본값 1)로 등급을 함께 저장하도록 확장. `unequip()`도 `{"name": "", "grade": 0}`으로 초기화. 기본 장비의 grade를 1로 시작한 이유: 지금까지 배치된 모든 나무/동물이 grade=1(Tree, Animal)이거나 grade=2(Tree2, Animal2)뿐이라, 최소 기준을 1로 두어야 grade=1 개체는 기본 장비로 그대로 상호작용 가능하면서도 grade=2 개체에서 새 게이트가 실제로 의미를 갖는다.
  - `scripts/tree.gd`(`_register_hit()`)/`scripts/animal.gd`(`_attack()`, `_try_capture()`): 기존 "장비가 있는가"(`has_equipped`) 체크 뒤에 "장비 등급이 대상 등급 이상인가"(`get_equipment_grade(slot) < grade`) 체크를 추가했다. 장비가 있어도 등급이 낮으면 안내 메시지만 출력하고 진행하지 않는다 — design.md의 "유저는 더 높은 등급을 상대하기 위해 장비를 맞춰(강화/교체) 나간다"는 문장이 #26까지는 "장비 유무"에만 걸려 있어 실질적 의미가 없었는데, 이번 조각으로 처음 등급 자체가 장비 선택에 영향을 주게 됐다.
  - `tests/grade_headless_test.gd` 갱신: 기존 검증(등급 2 나무 2회 채집, 등급 2 동물 체력 200/6회 공격 후 14/200, 포획)에 각 상호작용 직전 "등급 1 장비로 시도 → 실패(상태 불변) 확인 → 등급 2 장비로 교체 → 성공" 단계를 추가해 새 게이트가 실제로 동작을 좌우하는지 검증했다. `tests/equipment_gate_headless_test.gd`는 grade=1 개체만 다루고 `equip(slot, name)`을 그대로 호출(새 `grade` 인자는 기본값 1로 채워짐)하므로 수정 없이 그대로 통과.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/grade_headless_test.gd` → `HEADLESS_GRADE_TEST: PASS`(등급 1 장비 시도 시 "등급이 부족해..." 메시지 출력 후 실패, 등급 2 장비 교체 후 성공 로그 확인). 회귀 확인을 위해 기존 8종 모두 재실행: `tests/equipment_gate_headless_test.gd`(`PASS`), `tests/tree_harvest_headless_test.gd`(`PASS`), `tests/animal_hunt_headless_test.gd`(`PASS (hits=4)`), `tests/animal_capture_headless_test.gd`(`PASS`), `tests/animal_flee_headless_test.gd`(`PASS (moved_distance=135.7, boundary_x=1576.0, island_right_edge=1576.0)`), `tests/animal_sight_flee_headless_test.gd`(`PASS`), `tests/animal_sound_flee_headless_test.gd`(`PASS`), `tests/boundary_headless_test.gd`(`PASS (final_x=1560.0, island_right_edge=1576.0)`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 장비 등급을 실제로 "얻거나 교체"할 방법은 여전히 코드상 `player.equip()` 호출뿐 — 게임 내에서 플레이어가 상점/제작/드롭 등을 통해 더 높은 등급 장비를 손에 넣는 경로가 전혀 없다. 즉 design.md의 "장비를 맞춰(강화/교체) 나간다"는 문장은 이제 "등급이 안 맞으면 막힌다"는 조건까지만 구현됐고, 실제로 "맞춰 나가는" 행위 자체(획득 경로)는 여전히 범위 밖이다. 등급 3(export_range 최댓값) 장비/개체도 씬에 아직 배치되지 않아 시각적으로 확인되지 않았다.
- 다음 할 일: design.md 로드맵상 "등급·장비" 단계를 마무리하려면 status.md #26이 처음 제안했던 (1) 장비를 실제로 얻거나 교체할 수 있는 최소 경로가 자연스러운 다음 조각이다 — 가장 작은 단위로는 나무 채집으로 얻는 "통나무"를 일정 개수 모으면(또는 단순히 즉시) 등급이 더 높은 도끼로 교체되는 최소 로직(상점 UI 없이, 예를 들어 특정 키 입력이나 자동 승급) 하나만 구현하는 것을 권장한다. 이 조각까지 끝나면 design.md의 "채집/사냥/포획 → 등급·장비" 로드맵 구간이 실질적으로 완결되므로, 그 다음은 로드맵의 다음 큰 단계인 **튜토리얼**로 넘어가는 것을 고려할 시점이 된다. inbox.md에 새 지시가 없다면 다음 세션은 이 방향으로 진행한다.

---

### #28 — 2026-09-01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #27이 남긴 다음 할 일(장비를 실제로 얻거나 교체할 수 있는 최소 경로)을 그대로 이어받았다.
- 한 일:
  - `scripts/main.gd`: 채집/사냥으로 자원을 모을 때(`_on_harvested`) 자동으로 장비 등급을 올리는 `_try_upgrade_equipment()`를 추가했다. `RESOURCE_TO_SLOT` 매핑(`"통나무" -> "tool"`, `"고기" -> "weapon"`)에 따라, 해당 자원이 `UPGRADE_COST`(5개) 이상 쌓이고 현재 장비 등급이 `MAX_EQUIPMENT_GRADE`(3, 나무/동물의 `@export_range(1,3)`과 맞춤) 미만이면 자원을 소비하고 `player.equip()`으로 등급을 1 올린다. 상점 UI나 재료 선택지 없이 "모으면 자동으로 승급"하는 가장 단순한 형태를 택했다 — design.md가 강화 방식의 세부를 명시하지 않았고(범위 밖), 상점/제작 UI를 새로 설계하면 규칙 4(기능 하나만)를 넘어서기 때문이다.
  - `scenes/Main.tscn`: `UI/EquipmentLabel`(Label, InventoryLabel/CaptureLabel 아래 offset 16,204~300,288)을 추가해 현재 도끼/마취총 등급을 "이름 Lv.N" 형식으로 항상 표시하도록 했다(`_update_equipment_label()`).
  - `tests/equipment_upgrade_headless_test.gd` 신설: 실제 씬의 나무 2그루만으로는 통나무를 비용(5)만큼 모을 수 없어(최대 2개), `main._on_harvested()`를 직접 호출해 자원을 모은 상황을 흉내냈다(기존 `grade_headless_test.gd`가 `player.equip()`을 직접 호출해 장비 상태를 세팅한 것과 같은 방식). (1) 비용 미달(4개)로는 승급하지 않고 자원도 유지되는지, (2) 5개가 되면 도끼가 Lv.2로 승급하고 자원이 소비되는지, (3) `EquipmentLabel`에 반영되는지, (4) 최대 등급(3) 도달 후에는 자원을 더 모아도 승급도, 소비도 되지 않는지, (5) 고기 → 마취총 경로도 동일하게 동작하는지 검증.
  - > [!CAUTION]
    > 처음 작성한 테스트에서 `_on_harvested("통나무", 5)`를 의도치 않게 한 번 더(총 3회) 호출해 인벤토리 잔량 계산이 어긋나(기대 5, 실제 10) `HEADLESS_EQUIPMENT_UPGRADE_TEST: FAIL`이 발생했다 — 원인은 게임 로직이 아니라 테스트 스크립트의 중복 호출(오프바이원 실수)이었다. 최대 등급 도달 확인과 "그 이후에는 소비되지 않음" 확인을 분리해 호출 횟수를 정리한 뒤 재실행하여 `HEADLESS_EQUIPMENT_UPGRADE_TEST: PASS`로 해결을 확인했다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/equipment_upgrade_headless_test.gd` → `HEADLESS_EQUIPMENT_UPGRADE_TEST: PASS`(수정 후). 회귀 확인을 위해 기존 9종 모두 재실행: `tests/animal_capture_headless_test.gd`(`PASS`), `tests/animal_flee_headless_test.gd`(`PASS (moved_distance=143.0, boundary_x=1576.0, island_right_edge=1576.0)`), `tests/animal_hunt_headless_test.gd`(`PASS (hits=4)`), `tests/animal_sight_flee_headless_test.gd`(`PASS`), `tests/animal_sound_flee_headless_test.gd`(`PASS`), `tests/boundary_headless_test.gd`(`PASS (final_x=1560.0, island_right_edge=1576.0)`), `tests/equipment_gate_headless_test.gd`(`PASS`), `tests/grade_headless_test.gd`(`PASS`), `tests/tree_harvest_headless_test.gd`(`PASS`) 모두 이상 없음.
- 남은 제약: 승급 비용(통나무/고기 5개)과 승급량(1등급씩)은 design.md의 "범위 밖" 밸런스 수치에 해당하는 하네스의 상식적 기본값이다 — 실제 플레이해보고 너무 빠르거나 느리면 조정 여지가 있다. 승급은 자원명이 "통나무"/"고기"일 때만 반응하므로, 앞으로 새 채집/사냥 자원이 추가되면 `RESOURCE_TO_SLOT`에 매핑을 추가하거나 의도적으로 제외해야 한다. 여전히 상점/제작 UI, 장비 종류 다양화(예: 도끼 외 다른 도구)는 없다.
- 다음 할 일: 이번 조각으로 design.md의 "채집/사냥/포획 → 등급·장비" 로드맵 구간이 실질적으로 완결되었다고 판단한다(장비 유무 게이트 → 등급 게이트 → 등급을 실제로 올리는 경로까지 갖춤). inbox.md에 새 지시가 없다면, 다음 세션은 로드맵의 다음 큰 단계인 **튜토리얼**의 첫 조각(예: 게임 시작 시 기본 조작·상호작용 키 안내를 보여주는 최소 UI 하나)을 규칙 4(기능 하나만)에 따라 시작하는 것을 권장한다.

---

### #29 — 2026-09-01 15:53 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #28이 남긴 다음 할 일(로드맵의 다음 큰 단계인 **튜토리얼**의 첫 조각)을 그대로 이어받았다.
- 한 일:
  - `scenes/Main.tscn`: `UI/TutorialOverlay`(Control, 화면 전체를 덮음)를 신설. 자식으로 반투명 검정 `ColorRect`(Background, alpha 0.6)와 화면 중앙에 배치된 `TutorialLabel`(방향키 이동, Space/Enter로 채집·공격, C로 포획 조건을 안내하고 "아무 키나 눌러 시작하기"로 마무리하는 안내문)을 추가했다. design.md는 "퀘스트는 없고 처음에 튜토리얼로 기본 조작과 시스템을 안내한다"고만 명시해 세부 형식은 범위 밖이므로, 별도 씬 전환이나 단계별 진행 없이 시작 화면에 한 번 덮어 보여주고 닫는 가장 단순한 형태를 택했다.
  - `scripts/main.gd`: `_ready()`에서 `tutorial_overlay.visible = true`로 시작 시 항상 노출시키고, `_unhandled_input(event)`에서 오버레이가 보이는 동안 아무 `InputEventKey`나 눌리면 오버레이를 숨기고 `set_input_as_handled()`로 소비한다. 닫는 입력을 `ui_accept` 같은 특정 게임 액션이 아니라 "아무 키"로 정한 이유는, 특정 액션을 재사용하면 오버레이를 닫는 입력이 동시에 근처 나무/동물과의 상호작용 입력으로도 해석될 위험이 있기 때문이다(현재 Player 시작 위치는 어떤 상호작용 범위와도 겹치지 않아 실제 충돌은 없지만, 이 우연에 의존하지 않는 편을 택했다).
  - `tests/tutorial_headless_test.gd` 신설: `Main.tscn`을 인스턴스화해 (1) 시작 시 `TutorialOverlay.visible`이 true인지, (2) `Input.parse_input_event()`로 임의의 키 입력(Space)을 흉내내면 오버레이가 숨겨지는지, (3) 이후 다른 키(A)를 더 눌러도 다시 나타나지 않는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/tutorial_headless_test.gd` → `HEADLESS_TUTORIAL_TEST: PASS`. 회귀 확인을 위해 기존 10종 모두 재실행: `tests/animal_capture_headless_test.gd`(`PASS`), `tests/animal_flee_headless_test.gd`(`PASS (moved_distance=135.7, boundary_x=1576.0, island_right_edge=1576.0)`), `tests/animal_hunt_headless_test.gd`(`PASS (hits=4)`), `tests/animal_sight_flee_headless_test.gd`(`PASS`), `tests/animal_sound_flee_headless_test.gd`(`PASS`), `tests/boundary_headless_test.gd`(`PASS (final_x=1560.0, island_right_edge=1576.0)`), `tests/equipment_gate_headless_test.gd`(`PASS`), `tests/equipment_upgrade_headless_test.gd`(`PASS`), `tests/grade_headless_test.gd`(`PASS`), `tests/tree_harvest_headless_test.gd`(`PASS`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 튜토리얼은 매 실행마다 항상 뜨며(설정 저장/"다시 보지 않기" 없음), 텍스트 하나로 모든 조작을 나열할 뿐 단계별 진행이나 실제 조작 유도(예: "지금 이동해보세요"처럼 플레이어 행동에 반응하는 안내)는 없다 — design.md가 튜토리얼의 정확한 내용을 "범위 밖"으로 명시해 이번 조각은 가장 단순한 형태(정적 안내 후 닫기)로 최소 구현했다. 안내 텍스트에는 현재 구현된 조작(이동/채집/공격/포획)만 담았고, 아직 없는 캐릭터 커스터마이징·멀티플레이 등은 다루지 않았다.
- 다음 할 일: design.md 로드맵(캐릭터 이동/카메라 → 섬 기본 지형 → 채집/사냥/포획 → 등급·장비 → **튜토리얼** → 캐릭터 커스터마이징/슬롯 → 멀티플레이)상 튜토리얼의 최소 형태가 이번 조각으로 갖춰졌다고 판단한다. inbox.md에 새 지시가 없다면, 다음 세션은 로드맵의 다음 큰 단계인 **캐릭터 커스터마이징/슬롯**(예: 계정당 3개 캐릭터 슬롯 중 하나를 만드는 최소 흐름, 또는 외형 커스터마이징의 가장 작은 조각) 중 규칙 4(기능 하나만)에 맞는 가장 작은 단위를 골라 진행하는 것을 권장한다.

---

### #30 — 2026-09-01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #29가 남긴 다음 할 일(로드맵의 다음 큰 단계인 **캐릭터 커스터마이징/슬롯**) 중, "계정당 3개 캐릭터 슬롯"은 저장/불러오기 시스템까지 새로 설계해야 해 규칙 4(기능 하나만)를 넘어서는 반면, "외형 커스터마이징의 가장 작은 조각"은 이미 있는 절차적 단색 텍스처 생성 코드에 색만 바꿔 끼우면 되어 더 작은 단위라고 판단해 이쪽을 선택했다.
- 한 일:
  - `scripts/player.gd`: 기존에 `_ready()` 안에 있던 "32x32 파란색 단색 텍스처 생성" 코드를 `_apply_body_color(color: Color)` 함수로 분리하고, `body_color` 변수와 외부에서 호출 가능한 `set_body_color(color: Color)`를 추가했다. 이제 캐릭터 외형(색)을 게임 실행 중에도 바꿔 끼울 수 있는 최소 구조가 생겼다.
  - `scenes/Main.tscn`: `UI/CustomizationOverlay`(Control, 튜토리얼 오버레이와 같은 반투명 배경 패턴)를 신설. 안내 라벨과 함께 파랑/빨강/초록/보라 4가지 색을 보여주는 `ColorRect` 스와치(Swatch1~4)를 배치해, 숫자 키 1~4에 대응하는 색을 시각적으로 미리 보여준다. 기존 `UI/TutorialOverlay`는 시작 시 `visible = false`로 바꾸고, 커스터마이징이 끝난 뒤에야 나타나도록 순서를 바꿨다(외형 선택 → 조작 안내 → 플레이).
  - `scripts/main.gd`: `_ready()`에서 `customization_overlay.visible = true`로 시작. `_unhandled_input()`을 확장해, 커스터마이징 오버레이가 보이는 동안 숫자 키 1~4(`BODY_COLOR_CHOICES` 딕셔너리로 스와치 색과 매핑)를 누르면 `player.set_body_color()`를 호출해 색을 적용하고 오버레이를 튜토리얼로 전환한다. 기존 튜토리얼의 "아무 키나 눌러 시작하기" 닫기 로직은 그대로 유지.
  - `tests/customization_headless_test.gd` 신설: (1) 시작 시 커스터마이징 오버레이만 보이고 튜토리얼은 가려져 있는지, (2) 숫자 키(2: 빨강)를 누르면 오버레이가 전환되는지, (3) `player.body_color`와 실제 스프라이트 텍스처 픽셀이 선택한 색으로 바뀌는지 검증.
  - `tests/tutorial_headless_test.gd` 갱신: 순서가 바뀌었으므로, 튜토리얼 오버레이를 확인하기 전에 커스터마이징 색 선택(키 1)을 먼저 흉내내도록 수정했다.
  - > [!CAUTION]
    > `godot --headless --path . --quit`이 `Parse Error: Parse error. [Resource file res://scenes/Main.tscn:99] at: _parse_node_tag`로 실패했다 — 원인은 새로 추가한 `ColorRect` 스와치들의 `color = Color(0.2, 0.6, 1.0)`처럼 **3개 인자(R,G,B)만 준 `Color()`** 표기였다. GDScript 코드에서는 3-인자 `Color()`(알파 기본값 1.0)가 정상 동작하지만, `.tscn` 텍스트 리소스 포맷의 파서는 이 축약형을 지원하지 않고 항상 4개 인자(R,G,B,A)를 요구한다는 것을 이번에 처음 확인했다(기존 `Background` 노드들의 `color = Color(0, 0, 0, 0.6)`은 이미 4개 인자라 우연히 문제가 없었다). `res://scenes/_debug_test.tscn`에 최소 재현 씬을 만들어 원인을 좁힌 뒤, 5개의 `Color()` 호출 모두에 `, 1.0`을 추가(4-인자 형태로 수정)해 해결했다. 재확인 결과 `godot --headless --path . --quit` 정상 통과, 신규/기존 테스트 12종 모두 PASS.
    >
    > 같은 원인으로 신규 테스트에서도 한 번 더 걸렸다: 스프라이트 텍스처 픽셀 색을 `!=` 로 정확히 비교했더니 `FORMAT_RGBA8`(채널당 8비트, 1/255 단위 양자화) 때문에 `0.9`가 `0.898...`로 저장되어 실패했다. 정확 비교 대신 채널별 오차 허용(0.01) 비교로 바꿔 해결했다.
- 확인: `godot --headless --path . --quit` 에러 없음(위 캡션의 파싱 에러 수정 후 재확인). 신규 `tests/customization_headless_test.gd` → `HEADLESS_CUSTOMIZATION_TEST: PASS`. 회귀 확인을 위해 기존 11종 모두 재실행: `tests/tutorial_headless_test.gd`(`PASS`, 순서 변경 반영), `tests/animal_capture_headless_test.gd`(`PASS`), `tests/animal_flee_headless_test.gd`(`PASS`), `tests/animal_hunt_headless_test.gd`(`PASS (hits=4)`), `tests/animal_sight_flee_headless_test.gd`(`PASS`), `tests/animal_sound_flee_headless_test.gd`(`PASS`), `tests/boundary_headless_test.gd`(`PASS`), `tests/equipment_gate_headless_test.gd`(`PASS`), `tests/equipment_upgrade_headless_test.gd`(`PASS`), `tests/grade_headless_test.gd`(`PASS`), `tests/tree_harvest_headless_test.gd`(`PASS`) 모두 이상 없음.
- 남은 제약: "계정당 3개 캐릭터 슬롯"(design.md)은 여전히 전혀 없다 — 지금은 캐릭터가 하나뿐이고 저장/불러오기 개념 자체가 없어(세션 중 메모리에만 존재), 슬롯을 만들려면 별도의 저장 시스템 설계가 필요하다. 외형 커스터마이징도 색 4종 중 선택뿐이라 매우 소박하며(체형, 얼굴 등은 다루지 않음), design.md가 명시한 "기본 코디(의상) 제공"과의 관계도 아직 정리되지 않았다(현재는 색만 있고 "의상"이라는 별도 레이어는 없음). 선택한 색은 세션 중에만 유지되고 저장되지 않는다.
- 다음 할 일: design.md 로드맵상 "캐릭터 커스터마이징/슬롯" 단계를 계속 이어가려면, 다음 후보는 (1) 계정당 3개 캐릭터 슬롯을 만드는 최소 흐름(저장 없이, 예를 들어 세션 시작 시 슬롯 번호를 고르고 슬롯별로 다른 외형을 기억하는 정도의 가장 단순한 형태), 또는 (2) design.md의 "멀티플레이"로 로드맵을 넘어가기 전에 필요한 기초 작업 중 하나다. (1)이 로드맵 순서상 자연스러운 다음 조각이지만, 진짜 저장/불러오기까지 가면 규모가 커지므로 규칙 4(기능 하나만)에 따라 "슬롯 선택 UI + 세션 중 슬롯별 외형 구분"처럼 저장을 뺀 가장 작은 조각부터 시작하는 것을 권장한다. inbox.md에 새 지시가 없다면 다음 세션은 이 방향으로 진행한다.

---

### #31 — 2026-09-01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #30이 남긴 다음 할 일 중 (1) "계정당 3개 캐릭터 슬롯을 만드는 최소 흐름(저장 없이, 슬롯 선택 UI + 세션 중 슬롯별 외형 구분)"을 그대로 이어받았다. (2) 멀티플레이 기초 작업보다 로드맵 순서상 자연스럽고, #30이 이미 "가장 작은 조각"으로 명시해뒀기 때문이다.
- 한 일:
  - `scripts/main.gd`: 게임 시작 흐름 맨 앞에 `SlotOverlay`(슬롯 1~3 선택) 단계를 추가했다. `slot_colors: Dictionary`(슬롯 번호 -> 그 슬롯에서 마지막으로 고른 색)와 `current_slot`, `pending_tutorial`(튜토리얼을 아직 한 번도 보여주지 않았는가) 상태를 도입해: 처음 고르는 슬롯이면 커스터마이징 오버레이로 이어져 색을 고르고 그 결과를 `slot_colors`에 저장하며, 이미 고른 적 있는 슬롯이면 저장해둔 색을 즉시 적용한다. 이번 세션 처음이자 유일하게 커스터마이징이 끝난 시점에만 튜토리얼로 이어지고(`_maybe_show_tutorial()`), 이후에는 게임 중 아무 때나 `Tab` 키로 `SlotOverlay`를 다시 열어 슬롯을 바꿀 수 있다 — 튜토리얼은 다시 뜨지 않는다. 진짜 계정/파일 저장(불러오기, 영구 저장)은 여전히 범위 밖이며, "세션 중" 슬롯별 외형을 기억하는 것까지만 다뤘다(design.md가 슬롯 세부 저장 방식을 명시하지 않았고, 파일 I/O·계정 시스템까지 설계하면 규칙 4를 넘어서기 때문).
  - `scenes/Main.tscn`: `UI/SlotOverlay`(Control, 기존 오버레이들과 같은 반투명 배경 패턴) 신설 — "1: 슬롯 1  2: 슬롯 2  3: 슬롯 3"과 "Tab으로 언제든 전환 가능" 안내를 담은 라벨. 시작 시 `visible = true`, `UI/CustomizationOverlay`는 이제 두 번째 단계이므로 `visible = false`로 바꿨다(기존 씬에서 `visible = true`였던 것을 시작 순서가 하나 밀리면서 조정).
  - `tests/slot_headless_test.gd` 신설: 슬롯 1을 처음 고르면 커스터마이징으로 이어지는지, 색을 고르면 튜토리얼로 이어지고 색이 저장되는지, `Tab`으로 슬롯 오버레이를 다시 열 수 있는지, 처음 고르는 슬롯 2는 커스터마이징으로만 이어지고 튜토리얼은 다시 뜨지 않는지, `Tab`으로 이미 골랐던 슬롯 1로 돌아가면 커스터마이징 없이 저장해둔 색이 즉시 적용되는지까지 전체 흐름을 검증.
  - `tests/tutorial_headless_test.gd`/`tests/customization_headless_test.gd` 갱신: 시작 흐름 맨 앞에 슬롯 선택(키 1) 단계가 추가됐으므로, 두 테스트 모두 커스터마이징 단계 이전에 슬롯 선택을 흉내내도록 수정했다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 `tests/slot_headless_test.gd` → `HEADLESS_SLOT_TEST: PASS`. 회귀 확인을 위해 갱신된 2종 포함 기존 12종 모두 재실행: `tests/customization_headless_test.gd`(`PASS`), `tests/tutorial_headless_test.gd`(`PASS`), `tests/equipment_gate_headless_test.gd`(`PASS`), `tests/equipment_upgrade_headless_test.gd`(`PASS`), `tests/grade_headless_test.gd`(`PASS`), `tests/tree_harvest_headless_test.gd`(`PASS`), `tests/boundary_headless_test.gd`(`PASS`), `tests/animal_capture_headless_test.gd`(`PASS`), `tests/animal_flee_headless_test.gd`(`PASS`), `tests/animal_hunt_headless_test.gd`(`PASS (hits=4)`), `tests/animal_sight_flee_headless_test.gd`(`PASS`), `tests/animal_sound_flee_headless_test.gd`(`PASS`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 슬롯은 여전히 "세션 중"에만 의미가 있다 — 게임을 다시 실행하면 `slot_colors`가 초기화되어 이전에 고른 슬롯 색이 사라진다(파일 저장 없음). 슬롯별로 구분되는 것은 외형 색뿐이며, design.md가 말하는 "계정" 개념(로그인, 여러 캐릭터를 동시에 목록에서 고르는 화면 등)은 없다. 슬롯을 3개로 제한하는 것은 `SLOT_KEYS`에 1~3만 등록해뒀을 뿐, 실제로 "4번째를 만들려 하면 막힌다"는 식의 명시적 안내는 없다(애초에 키가 없어 자연스럽게 3개로 제한됨).
- 다음 할 일: 이번 조각으로 design.md의 "캐릭터 커스터마이징/슬롯" 로드맵 구간이 (저장 기능을 뺀) 최소 형태로는 갖춰졌다고 판단한다. inbox.md에 새 지시가 없다면, 다음 세션은 로드맵의 마지막 큰 단계인 **멀티플레이**(세션 서버 방식)의 가장 작은 착수 조각을 검토하는 것을 권장한다 — 다만 멀티플레이는 지금까지의 어떤 조각보다 아키텍처 결정(로컬 vs 서버 권위, 동기화 방식 등)의 비중이 커서, 곧바로 코드를 작성하기보다 먼저 design.md 범위 안에서 가장 작은 착수점(예: Godot의 `MultiplayerAPI`/`ENetMultiplayerPeer`로 로컬 루프백 접속만 성립시키는 최소 스파이크)이 무엇인지 판단하고 그 근거를 status.md에 남기는 것부터 시작하는 것이 안전하다. 그 전에, 지금까지 쌓인 여러 오버레이(슬롯/커스터마이징/튜토리얼)의 순서와 상태 전이가 복잡해지고 있으므로, 사람이 직접 에디터로 전체 시작 흐름(슬롯 선택 -> 커스터마이징 -> 튜토리얼 -> Tab 전환)을 플레이해 자연스러운지 확인하는 것도 함께 권장한다.

---

### #32 — 2026-09-01 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #31이 남긴 다음 할 일(멀티플레이의 가장 작은 착수점 — 로컬 루프백 접속만 성립시키는 스파이크)을 그대로 이어받았다. 게임 상태 동기화(플레이어 스폰/이동 동기화 등)는 아키텍처 결정 비중이 커서 규칙 4(기능 하나만)를 넘어서므로, 이번 세션은 "접속 자체가 되는가"만 검증하는 스파이크로 범위를 한정했다.
- 한 일:
  - `scripts/network_manager.gd` 신설, `project.godot`에 `NetworkManager` 자동로드로 등록. `host(port)`(`ENetMultiplayerPeer.create_server`)/`join(address, port)`(`create_client`)/`stop()` 3개 함수와 `peer_connected`/`peer_disconnected` 시그널 로깅만 다룬다. design.md가 명시한 "세션 서버" 방향에 맞춰 서버-클라이언트 역할을 분리한 구조로 시작했고, 실제 게임 오브젝트 동기화는 이번 조각에서 의도적으로 다루지 않았다.
  - **판단(아키텍처 아님, 테스트 방법론)**: 실제 네트워크 핸드셰이크를 검증하려면 서버/클라이언트가 서로 다른 프로세스여야 한다(한 프로세스 안에서 서버·클라이언트 역할을 동시에 흉내내면 진짜 접속을 거치지 않아 검증 의미가 없음). 그래서 `tests/network_server_headless.gd`(서버 역할, 단독 실행 가능한 headless 스크립트)를 별도로 만들고, `tests/network_spike_headless_test.gd`(클라이언트 역할이자 실제 테스트)가 `OS.create_process()`로 서버 스크립트를 백그라운드 프로세스로 띄운 뒤 `127.0.0.1` 루프백으로 접속을 시도해 `MultiplayerPeer.CONNECTION_CONNECTED` 상태에 도달하는지 확인하고, 끝나면 `OS.kill()`로 서버 프로세스를 정리한다.
  - > [!CAUTION]
    > 처음 구현에서 두 가지 에러를 겪었다. (1) `--script`로 커스텀 메인루프(SceneTree 상속 스크립트)를 실행하는 모드에서는 자동로드(`NetworkManager`)의 전역 식별자(bare `NetworkManager` 코드상 이름)가 컴파일되지 않아 `SCRIPT ERROR: Compile Error: Identifier not found: NetworkManager`가 발생했다 — 원인은 이 전역 식별자가 일반 씬 실행 경로에서만 생성되고, `--script` 오버라이드 모드에선 자동로드 노드 자체는 트리에 붙지만(`root.get_node("NetworkManager")`로는 찾아짐) 전역 이름이 생성되지 않는 것으로 확인됨. `root.get_node("NetworkManager")`로 직접 참조하도록 두 테스트 스크립트를 수정해 해결했다. (2) 그 상태에서도 `network_server_headless.gd`가 `_initialize()`에서 바로 `host()`를 호출하면 `Invalid assignment of property... on a base object of type 'null instance'`(`multiplayer.multiplayer_peer` 대입 실패) 에러가 났다 — `_initialize()` 시점엔 자동로드 노드가 트리 계층엔 붙어 있어도 `is_inside_tree()`가 아직 `false`라 `multiplayer`(=`get_tree().get_multiplayer()`) 프로퍼티가 null을 반환하기 때문이었다(디버그 스크립트로 `is_inside_tree: false`를 직접 확인). `host()` 호출을 `_initialize()`에서 첫 `_process()` 프레임으로 옮겨 해결했다. 재확인 결과 `HEADLESS_NETWORK_SPIKE_TEST: PASS`(2회 연속 실행 모두 성공, 서버 프로세스도 정상 종료되어 잔여 프로세스 없음 확인).
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/network_spike_headless_test.gd` → `HEADLESS_NETWORK_SPIKE_TEST: PASS (client_peer_id=...)` (2회 연속 실행 모두 성공, `ps aux`로 서버 프로세스가 남지 않음을 확인). 자동로드 추가가 기존 시스템에 영향이 없는지 대표 회귀 테스트 7종을 재실행: `tests/tree_harvest_headless_test.gd`(`PASS`), `tests/boundary_headless_test.gd`(`PASS`), `tests/slot_headless_test.gd`(`PASS`), `tests/tutorial_headless_test.gd`(`PASS`), `tests/customization_headless_test.gd`(`PASS`), `tests/equipment_upgrade_headless_test.gd`(`PASS`), `tests/grade_headless_test.gd`(`PASS`) 모두 이상 없음.
- 남은 제약: 이번 조각은 "접속이 성립하는가"만 확인했을 뿐, 실제 게임 상태 동기화(플레이어 스폰, 위치/애니메이션 동기화, 서버 권위적 판정 등)는 전혀 다루지 않았다. `NetworkManager`는 아직 어떤 씬에도 실제로 연결되어 있지 않고(Main.tscn이 host/join을 호출하지 않음), 포트(8921)·최대 클라이언트 수(8)는 하네스가 임의로 정한 상식적 기본값이다. 서버 프로세스 기동 대기 시간(1.5초)·접속 타임아웃(8초)도 로컬 환경 기준 넉넉하게 잡은 값으로, CI 등 느린 환경에서는 조정이 필요할 수 있다.
- 다음 할 일: 멀티플레이를 계속 이어가려면 다음 후보는 (1) `Main.tscn`/`player.gd`를 실제로 `NetworkManager`와 연결해, 호스트가 접속을 받으면 접속한 피어마다 Player 인스턴스를 스폰하는 최소 로직(아직 위치 동기화 없이 "접속하면 각자의 화면에 캐릭터가 나타난다"는 수준), 또는 (2) 플레이어 이동을 `MultiplayerSynchronizer`로 동기화하는 것 중 하나다. (1)이 (2)의 전제 조건이므로 로드맵상 자연스러운 다음 조각이다. 여러 인스턴스가 필요한 검증이라 이번 세션에서 쓴 "headless 서버 프로세스 + headless 클라이언트 프로세스" 패턴을 그대로 재사용할 수 있다. inbox.md에 새 지시가 없다면 다음 세션은 이 방향으로 진행한다.

---

### #33 — 2026-09-01 16:18 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #32가 남긴 두 후보((1) 피어마다 Player 인스턴스 스폰 vs (2) 이동 동기화) 중 #32 자신이 "(2)의 전제 조건"이라고 명시한 (1)을 그대로 이어받았다.
- 한 일:
  - `scenes/Main.tscn`: 지금까지 `.tscn`에 정적으로 박혀 있던 `Player` 인스턴스 노드를 제거하고, 그 자리에 `PlayerSpawner`(`MultiplayerSpawner`, `_spawnable_scenes = ["res://scenes/Player.tscn"]`, `spawn_path = NodePath("..")` — Main 자신을 가리킴)를 추가했다. 이제 Player는 정적 배치가 아니라 런타임에 `main.gd`가 `add_child()`로 스폰하며, `MultiplayerSpawner`가 그 스폰/제거를 다른 접속자에게 자동으로 복제한다.
  - `scripts/main.gd`: `_ready()`에서 `/root/NetworkManager`(자동로드)의 `peer_connected_to_me`/`peer_disconnected_from_me` 시그널(status.md #32에서 이미 정의해뒀지만 그때는 아무도 구독하지 않던 시그널)을 구독하고, `multiplayer.is_server()`이면(오프라인 기본 상태도 항상 `is_server() == true`이므로 싱글플레이에서도 동일 경로를 탐) 자기 자신을 스폰한다. `_spawn_player(id)`/`_on_peer_connected(id)`/`_on_peer_disconnected(id)`를 신설 — 서버만 스폰/제거를 결정하고(클라이언트는 복제로만 받음), 자기 자신(호스트, ENet 규약상 항상 id=1)은 기존과 동일하게 노드 이름 `"Player"`로 스폰해 기존 12개 헤드리스 테스트가 `main.get_node("Player")`에 의존하던 것을 그대로 유지했다. 이후 접속하는 피어는 `"Player_<id>"`로 구분한다. 이 판단(이름 규칙)은 새 기능을 위해 기존 회귀 테스트 12개를 전부 고치는 대신, 기존 이름 체계와 충돌 없는 규칙을 골라 하위호환을 지킨 것이라 근거를 남긴다.
  - `tests/network_player_spawn_headless_test.gd` 신설: 실제 2-프로세스 ENet 접속은 status.md #32의 `network_spike_headless_test.gd`가 이미 검증했으므로, 이번 조각에서 새로 생긴 로직(접속/해제 시 Player를 실제로 스폰/제거하는가)만 단일 프로세스에서 직접 검증한다. 오프라인 기본 멀티플레이어 피어 상태(`multiplayer.is_server() == true`)를 이용해 `main._on_peer_connected(2)`/`main._on_peer_disconnected(2)`를 직접 호출(기존 `main._on_harvested()` 직접 호출 패턴과 동일)하여, (1) 시작 시 자기 자신이 `"Player"`로 스폰돼 있는지, (2) 새 피어 접속 시 `"Player_2"`가 스폰되고 `"player"` 그룹에 속하는지, (3) 동일 피어의 중복 접속 신호로 중복 스폰되지 않는지, (4) 접속 해제 시 `Player_2`만 제거되고 자기 자신(`Player`)은 남는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음 — `MultiplayerSpawner`/`_spawnable_scenes`/`spawn_path` 문법이 한 번에 정상 파싱됨). 신규 `tests/network_player_spawn_headless_test.gd` → `HEADLESS_NETWORK_PLAYER_SPAWN_TEST: PASS`. 회귀 확인을 위해 기존 13종(12개 헤드리스 테스트 + status.md #32의 `network_spike_headless_test.gd`) 모두 재실행: `tree_harvest_headless_test`(`PASS`), `boundary_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`) 모두 이상 없음. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 이번 조각은 "스폰/제거 로직 자체"만 단일 프로세스로 검증했을 뿐, 실제로 서로 다른 두 프로세스(호스트+클라이언트)가 접속했을 때 `MultiplayerSpawner`가 그 스폰을 정말로 상대방 화면까지 복제하는지는 아직 실측하지 않았다 — 이는 Godot 엔진이 보장하는 표준 동작에 의존한 것이며, 다음 세션에서 실제로 확인해볼 가치가 있다. 또한 `player.gd`의 `_physics_process()`가 아직 `is_multiplayer_authority()`를 확인하지 않아, 실제로 두 개 이상의 Player 인스턴스가 한 화면에 존재하면(호스트 화면에 자신+접속자가 모두 보이는 경우) 로컬 키보드 입력이 모든 Player 인스턴스를 동시에 움직이는 문제가 있다 — "위치 동기화는 다음 단계"라는 전제하에 의도적으로 남겨둔 범위 밖이다. 같은 이유로 `Camera2D`도 인스턴스마다 하나씩 있어, 여러 Player가 존재하면 어느 카메라가 활성화될지 명시적으로 제어되지 않는다. `Main.tscn`의 다른 UI(장비/인벤토리 라벨, 커스터마이징 등)는 여전히 `get_first_node_in_group("player")`로 단일 플레이어만 가정하고 있어 멀티플레이 상황에서는 호스트 기준으로만 동작한다.
- 다음 할 일: design.md의 "멀티플레이" 로드맵을 계속 이어가려면 다음 후보는 (1) 실제로 서버 프로세스에 `Main.tscn`을 로드시키고 클라이언트가 접속한 뒤 클라이언트 쪽 화면(프로세스)에도 호스트의 Player와 자신의 Player가 복제되어 나타나는지 2-프로세스로 실측하는 것(이번 조각이 "남은 제약"으로 미룬 부분), 또는 (2) `player.gd`에 `is_multiplayer_authority()` 체크를 추가해 각 클라이언트가 자신의 Player만 입력으로 움직이게 하는 것(이동 동기화의 전제 조건) 중 하나다. (2)는 실제 위치 동기화(`MultiplayerSynchronizer`)를 붙이기 전에 반드시 필요한 안전장치이자 상대적으로 작은 단위이므로 먼저 고려할 만하다. inbox.md에 새 지시가 없다면 다음 세션은 이 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행한다.

---

### #34 — 2026-09-01 16:24 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #33이 남긴 두 후보 중, "실제 위치 동기화를 붙이기 전에 반드시 필요한 안전장치이자 상대적으로 작은 단위"라고 스스로 명시했던 **(2) `player.gd`에 `is_multiplayer_authority()` 체크 추가**를 이어받았다.
- 한 일:
  - `scripts/main.gd`: 지금까지 `PlayerSpawner`(`MultiplayerSpawner`)는 `_spawnable_scenes`만 지정한 채 서버가 `add_child()`하면 자동으로 원격 피어에도 같은 씬이 재인스턴스화되는 기본 방식이었다. 이 방식은 서버 쪽 로컬 노드에 `set_multiplayer_authority()`를 호출해도 그 값이 로컬에만 적용되고 다른 피어에는 전달되지 않는다는 문제가 있어(각 피어가 스스로 새로 `instantiate()`할 뿐, 서버가 설정한 임의의 속성을 그대로 복제하지 않음), `player_spawner.spawn_function`에 새 함수 `_create_player_instance(id)`를 등록하는 방식으로 바꿨다. 커스텀 `spawn_function`은 `spawn(data)` 호출 시 그 인자(`id`)를 받아 스폰을 전달받는 모든 피어에서 동일하게 실행되므로, 그 안에서 `player.set_multiplayer_authority(id)`를 호출하면 모든 피어가 "이 Player 노드는 id 피어가 조작한다"는 동일한 결론에 도달한다. `_spawn_player(id)`는 이제 직접 `instantiate()`+`add_child()`하는 대신 `player_spawner.spawn(id)`를 호출한다.
  - `scripts/player.gd`: `_physics_process()` 맨 앞에 `if not is_multiplayer_authority(): return`을 추가해, 자신의 소유 피어가 아닌 Player 인스턴스는 로컬 키보드 입력에 반응하지 않도록 했다. 오프라인(멀티플레이 피어 미설정) 상태에서는 authority 기본값(1)과 `multiplayer.get_unique_id()` 기본값(1)이 항상 같으므로, 지금까지의 싱글플레이 동작(및 기존 13개 헤드리스 테스트가 의존하던 `Player` 이동 로직)에는 영향이 없다.
  - 카메라(`Camera2D`)는 authority propagation(재귀 전파, 기본값)으로 함께 넘어가지만 `enabled` 값 자체를 authority에 따라 켜고 끄는 로직은 이번 조각에서 다루지 않았다 — status.md #33이 이미 별도 남은 제약으로 기록해뒀고, 이번 조각의 범위("입력으로 자신의 Player만 움직이게 한다")를 벗어나는 별개 사안이라 규칙 4(기능 하나만)에 따라 남겨둔다.
- 확인: 에러/QA 실패 없이 진행됨. `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음 — `MultiplayerSpawner.spawn_function` 대입, `Callable` 문법 정상 파싱). 회귀 확인을 위해 기존 15종 모두 재실행: `network_player_spawn_headless_test`(`PASS`), `network_spike_headless_test`(`PASS (client_peer_id=...)`, 2-프로세스 접속도 정상), `boundary_headless_test`(`PASS (final_x=1560.0, island_right_edge=1576.0)`), `tree_harvest_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS (moved_distance=135.7, ...)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `slot_headless_test`(`PASS`) 모두 이상 없음. `boundary_headless_test` 등이 Player를 실제로 이동시켜 벽/충돌을 검증하므로, authority 체크 추가 후에도 오프라인 상태의 이동 로직이 정상 동작함이 그대로 확인된다.
- 남은 제약: (1) 이번 조각은 authority가 "모든 피어에서 동일한 결론에 도달한다"는 것을 코드 구조(커스텀 spawn_function)로 보장했을 뿐, 실제 2-프로세스 환경에서 클라이언트가 자신의 캐릭터만 움직이고 호스트 캐릭터는 움직이지 못하는지는 아직 실측하지 않았다 — 다음 세션의 유력한 후보. (2) `Camera2D.enabled`는 여전히 authority와 무관하게 기본값(모든 인스턴스에서 true)이라, 한 화면에 여러 Player가 존재하면(호스트가 접속자를 함께 보는 상황) 어느 카메라가 활성 상태일지 명시적으로 제어되지 않는다(status.md #33에서 이미 지적된 사안, 이번 조각의 범위 밖). (3) 여전히 위치 자체의 동기화(`MultiplayerSynchronizer`)는 없다 — 이번 조각은 그 전제조건(입력 소유권 분리)만 마련했다.
- 다음 할 일: design.md의 "멀티플레이" 로드맵을 계속 이어가려면 다음 후보는 (1) 실제 2-프로세스(호스트+클라이언트)로 접속해, 각자 자신의 Player만 로컬 입력으로 움직일 수 있고 상대방의 Player는 움직이지 않는지 실측하는 것(status.md #33이 미뤄둔 부분과 사실상 동일한 실측 과제), 또는 (2) 이동 자체를 실제로 동기화하는 `MultiplayerSynchronizer`를 `Player.tscn`에 추가해 `position`(및 필요하면 `velocity`)을 복제하는 것이다. (2)가 로드맵상 다음으로 의미 있는 조각이지만, 이번 조각처럼 단일 프로세스 헤드리스 테스트만으로는 "다른 피어 화면에서 실제로 움직이는 것처럼 보이는가"를 검증하기 어려우므로, 2-프로세스 테스트 패턴(status.md #32/#33)을 확장해 위치 값이 실제로 복제되는지 확인하는 절차를 함께 마련하는 것을 권장한다. inbox.md에 새 지시가 없다면 다음 세션은 이 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행한다.

---

### #35 — 2026-09-01 20:26 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #34가 남긴 두 후보((1) 2-프로세스 authority 실측 vs (2) `MultiplayerSynchronizer`로 `position` 동기화) 중, #34가 "로드맵상 다음으로 의미 있는 조각"이라고 명시한 (2)를 이어받았다. (1)은 검증(실측) 성격이라 "만들기"보다는 "확인"에 가깝고, (2)는 실제로 새 기능(위치 복제)을 만드는 조각이라 규칙 4(한 바퀴의 순서: 읽기 -> 하나 만들기 -> 확인)의 "만들기" 단계에 더 부합한다고 판단했다. 다만 만들고 나서 바로 확인(QA)까지 해야 하므로, #34가 함께 권장한 대로 2-프로세스 실측 테스트도 이번 조각에 포함시켰다(새 기능을 만들었는데 검증을 다음 세션으로 미루면, 그 사이에 실제로 동작하는지 모르는 채로 다음 조각을 쌓게 되기 때문).
- 한 일:
  - `scenes/Player.tscn`: `SceneReplicationConfig` 서브리소스(`properties/0/path = NodePath(".:position")`, `spawn = true`, `replication_mode = 1`(Always))를 만들고, 이를 참조하는 `MultiplayerSynchronizer` 자식 노드를 추가했다. `MultiplayerSynchronizer.root_path` 기본값(`NodePath("..")`, 곧 부모인 Player 자신)을 그대로 써서 별도 설정 없이 `position`이 Player 노드의 값으로 해석되게 했다. status.md #34가 이미 `player.gd`에 `is_multiplayer_authority()` 체크를 넣어둔 덕분에, 각 피어는 자신이 조작하는 Player의 위치만 로컬에서 바꾸고 그 값이 자동으로 다른 피어에 복제되는 구조가 이번 조각으로 완성됐다 — 별도 스크립트 코드 없이 씬 리소스 설정만으로 구현됨(Godot의 `MultiplayerSynchronizer`가 authority 기반 복제를 엔진 차원에서 처리).
  - `tests/network_sync_server_headless.gd` 신설(헬퍼, 단독 실행 대상 아님): `NetworkManager.host()`로 서버를 띄우고 `Main.tscn`을 로드해 자기 자신의 Player를 스폰한 뒤, 클라이언트가 접속하면 1.5초 대기 후 자신의 Player 위치를 `(999, 111)`로 강제 이동시킨다. status.md #32의 `network_server_headless.gd`(접속 여부만 확인)보다 한 단계 더 나아가, "실제 게임 상태(Main.tscn 전체)를 가진 서버가 위치를 바꾼다"는 시나리오를 재현한다.
  - `tests/network_position_sync_headless_test.gd` 신설(테스트 본체, 클라이언트 역할): `OS.create_process()`로 위 서버를 백그라운드로 띄운 뒤 `NetworkManager.join()`으로 접속하고, 연결이 확인되면 자신도 `Main.tscn`을 로드한다. `MultiplayerSpawner`가 이미 서버에 존재하던 "Player"(호스트, id=1)를 늦게 접속한 클라이언트에도 복제해 스폰해준다는 엔진 동작에 기대어, 로컬에 나타난 원격 `"Player"` 노드의 `position`이 서버가 옮긴 목표 좌표 `(999, 111)`에 오차 1px 이내로 도달하는지 폴링(최대 8초)한다. 포트는 기존 `network_spike_headless_test.gd`(8921)와 겹치지 않도록 8922를 새로 썼다 — 같은 세션에서 연달아 여러 네트워크 테스트를 돌릴 때 소켓 정리 타이밍 문제를 피하기 위함(상식적 방어, 실제로 문제를 겪은 것은 아님).
- 확인: 에러/QA 실패 없이 진행됨. `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음 — `SceneReplicationConfig`/`MultiplayerSynchronizer` 문법 정상 파싱). 신규 `tests/network_position_sync_headless_test.gd` → `HEADLESS_NETWORK_POSITION_SYNC_TEST: PASS (remote_position=(999.0, 111.0))` — 서버가 옮긴 위치가 오차 없이 클라이언트 화면에 그대로 복제됨을 실측 확인. 회귀 확인을 위해 기존 15종 모두 개별 재실행: `network_spike_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `boundary_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `slot_headless_test`(`PASS`) 모두 이상 없음. `ps aux`로 테스트 종료 후 잔여 godot 서버 프로세스가 없음을 확인.
- 남은 제약: 이번 조각은 "서버 -> 클라이언트" 방향(호스트가 움직이면 클라이언트 화면에 보이는가)만 실측했다. status.md #34가 이미 마련해둔 authority 체크 덕분에 "클라이언트 -> 서버" 방향(클라이언트가 자기 Player를 움직이면 서버/다른 클라이언트에도 보이는가)도 대칭적으로 동작할 것으로 기대되지만(같은 `MultiplayerSynchronizer` 설정이 authority 방향과 무관하게 적용됨), 이번 세션에서 그 방향까지 별도로 실측하지는 않았다. `velocity`는 동기화 대상에 포함하지 않았다 — `move_and_slide()`가 매 프레임 `position`을 갱신하므로 `position` 하나만으로도 다른 피어 화면에서 캐릭터가 움직이는 것처럼 보이기에 충분하고, `velocity`까지 동기화하면 순간적인 스냅/보간 처리(예: 위치 예측)가 필요해져 규칙 4(기능 하나만)를 넘어서기 때문에 의도적으로 범위 밖으로 뒀다. 여전히 위치는 매 네트워크 틱 그대로(`ALWAYS` 모드) 전송되고 있어 보간(interpolation)이 없다 — 로컬 네트워크(루프백)에서는 눈에 띄지 않지만, 실제 지연(latency)이 있는 환경에서는 다른 피어의 캐릭터가 뚝뚝 끊겨 보일 수 있다.
- 다음 할 일: design.md의 "멀티플레이" 로드맵상, 이번 조각으로 "접속 -> 스폰 -> 이동 권한 분리 -> 위치 동기화(최소 한 방향 실측)"까지 핵심 골격이 갖춰졌다고 판단한다. inbox.md에 새 지시가 없다면, 다음 세션은 다음 후보 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행하는 것을 권장한다: (1) 이번 조각이 실측하지 않은 "클라이언트 -> 서버(또는 다른 클라이언트)" 방향의 위치 동기화를 대칭적으로 실측(2-프로세스 테스트를 클라이언트가 직접 자신의 Player를 옮기는 시나리오로 확장), (2) 여러 Player가 한 화면에 존재할 때 `Camera2D.enabled`가 authority와 무관하게 항상 true인 문제(status.md #33/#34가 이미 지적한 남은 제약)를 해결해 각 피어에서 자신의 카메라만 활성화되도록 하는 것. (2)는 실제 플레이 경험(여러 명이 접속했을 때 화면이 뒤섞이지 않는가)에 직결되는 문제라 우선순위가 높아 보인다.

---

### #36 — 2026-09-01 20:30 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #35가 남긴 두 후보((1) 클라이언트 -> 서버 방향 위치 동기화 실측 vs (2) `Camera2D.enabled`를 authority에 맞게 제어) 중, #35 스스로 "실제 플레이 경험에 직결되는 문제라 우선순위가 높다"고 명시한 (2)를 이어받았다.
- 한 일:
  - `scripts/player.gd`: `_ready()`에서 `camera.enabled = is_multiplayer_authority()`를 추가(그 전에는 `Camera2D`가 씬 기본값(`true`)을 그대로 유지해, 한 화면(주로 호스트)에 여러 Player가 존재하면 여러 카메라가 동시에 활성 상태가 되어 어느 화면이 실제로 보일지 엔진이 임의로 결정하는 상태였다). `set_multiplayer_authority(id)`는 `main.gd`의 커스텀 `spawn_function`(`_create_player_instance`, status.md #34)이 `add_child()` 이전에 이미 호출해두므로, `_ready()` 시점에는 모든 피어가 이미 같은 authority 값을 보고 있어 별도 시그널 없이 한 줄로 처리할 수 있었다. 오프라인(싱글플레이) 상태에서는 authority 기본값(1)과 `multiplayer.get_unique_id()` 기본값(1)이 항상 같아 `is_multiplayer_authority()`가 항상 `true`이므로 기존 동작(카메라 항상 켜짐)에는 영향이 없다.
  - `tests/camera_authority_headless_test.gd` 신설: `network_player_spawn_headless_test.gd`와 동일한 패턴(오프라인 기본 멀티플레이어 피어 상태에서 `main._on_peer_connected(2)`를 직접 호출)으로 "다른 피어(id=2)"의 Player를 스폰시킨 뒤, 자기 자신(`Player`)의 카메라는 켜져 있고 다른 피어(`Player_2`)의 카메라는 꺼져 있는지 검증.
- 확인: 에러/QA 실패 없이 진행됨. `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 `tests/camera_authority_headless_test.gd` → `HEADLESS_CAMERA_AUTHORITY_TEST: PASS`. 회귀 확인을 위해 기존 16종 모두 재실행: `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS (moved_distance=135.7, ...)`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `boundary_headless_test`(`PASS (final_x=1560.0, island_right_edge=1576.0)`), `customization_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`, 2-프로세스 접속 정상), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`, 2-프로세스 위치 동기화 정상) 모두 이상 없음. `ps aux`로 테스트 종료 후 잔여 godot 서버 프로세스가 없음을 확인.
- 남은 제약: 이번 조각은 오프라인 기본 피어 상태(authority 값이 로컬/원격을 흉내낸 것)에서만 검증했다 — 실제 2-프로세스 환경에서 클라이언트 쪽 화면에 호스트+자기 자신의 Player가 함께 존재할 때도 자신의 카메라만 켜지는지는 아직 실측하지 않았다(다만 `is_multiplayer_authority()`는 이미 status.md #34에서 이동 권한 분리에 동일한 방식으로 쓰였고 2-프로세스로 실측된 바 있어, 카메라도 같은 메커니즘을 재사용하므로 대칭적으로 동작할 것으로 기대된다). status.md #35가 남긴 "클라이언트 -> 서버 방향 위치 동기화 실측"은 여전히 미실행 상태다.
- 다음 할 일: design.md의 "멀티플레이" 로드맵 후보로 (1) status.md #35가 남긴 "클라이언트가 자신의 Player를 옮기면 서버/다른 클라이언트에도 보이는가"(클라이언트 -> 서버 방향) 실측, (2) 이번 조각의 카메라 authority 처리를 실제 2-프로세스 환경에서 육안 대신 헤드리스로 확인(예: 클라이언트 프로세스에서 자신의 `Player.camera.enabled`가 true이고 원격으로 복제된 호스트 `Player`의 카메라는 false인지 폴링)이 남아 있다. inbox.md에 새 지시가 없다면 다음 세션은 이 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행한다.

---

### #37 — 2026-09-01 20:51 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #36이 남긴 두 후보 중 (1) "클라이언트 -> 서버 방향 위치 동기화 실측"을 이어받았다. 세션 시작 시 `git status`에서 이전 세션이 커밋하지 못하고 남긴 미커밋 상태(`scripts/main.gd` 수정, `tests/network_client_move_headless.gd`·`tests/network_client_to_server_sync_headless_test.gd`·`tests/_scratch_debug.gd`·`_debug_out.log`)를 발견했는데, 파일 내용과 코드 주석을 확인해보니 정확히 이 (1) 작업을 진행하다 중단된 상태였다(`_debug_out.log`에 `HEADLESS_NETWORK_CLIENT_TO_SERVER_SYNC_TEST: FAIL` 기록이 남아 있었음). 새로 작업을 시작하는 대신, 이 미완성 작업을 이어받아 마무리하는 것이 규칙 2(세션 시작 순서)의 취지(파일에 남은 기록이 유일한 연속성)에 맞다고 판단했다.
  - `scripts/main.gd`(이전 세션이 이미 작성해둔 변경, 이번 세션에서 검증 후 그대로 커밋): `_create_player_instance(id)`가 호스트(id=1)와 겹치는 좌표에 새 피어를 스폰하면, Godot `CharacterBody2D`가 스폰 직후 첫 물리 프레임에서 겹침을 자동으로 밀어내는 특성 때문에 위치 동기화 스냅샷이 실제 값과 어긋나는 문제가 있었다. 새로 접속하는 피어만 `JOINING_PLAYER_SPAWN_OFFSET`(60, 0)만큼 옮겨 스폰해 겹침 자체를 없앴다. 호스트 스폰 위치는 기존 헤드리스 테스트들이 `PLAYER_SPAWN_POSITION`을 그대로 가정하고 있어 건드리지 않았다.
  - `tests/network_client_to_server_sync_headless_test.gd`(이전 세션이 작성): 서버(관찰자) 역할로 `Main.tscn`을 직접 로드하고, `tests/network_client_move_headless.gd`를 백그라운드 프로세스(클라이언트, 이동시키는 쪽)로 띄운 뒤, 접속한 원격 피어의 Player가 실제로 스폰되고(`get_multiplayer().get_peers()`로 얻은 무작위 31비트 id 기준 노드 이름 계산) 클라이언트가 옮긴 목표 좌표(222, 777)에 서버 쪽에서도 오차 1px 이내로 도달하는지 검증한다. status.md #35(서버->클라이언트 방향)와 반대 역할 배치를 재사용한 패턴.
  - `tests/network_client_move_headless.gd`(이전 세션이 작성): 위 테스트가 띄우는 클라이언트 역할. 서버에 접속해 자신에게 배정된 고유 id로 자신의 Player 노드를 찾아 위치를 직접 옮긴다.
  - `tests/_scratch_debug.gd`와 `_debug_out.log`는 이전 세션이 문제를 좁히는 과정에서 남긴 디버깅용 스크래치 파일(임시 재현 스크립트, 디버그 print 로그)이었고 최종 기능과 무관해 삭제했다. `player.gd`에 있었을 것으로 보이는 `PHYSDBG` 디버그 print도 이미 제거된 상태였다(현재 `scripts/player.gd`에 흔적 없음).
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). `godot --headless --path . --script res://tests/network_client_to_server_sync_headless_test.gd` → `HEADLESS_NETWORK_CLIENT_TO_SERVER_SYNC_TEST: PASS (server_side_position=(222.0, 777.0))` — 클라이언트가 옮긴 위치가 서버 쪽에도 정확히 복제됨을 확인. 회귀 확인을 위해 기존 17종 모두 재실행: `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `boundary_headless_test`(`PASS`), `camera_authority_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `network_spike_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`) 모두 이상 없음. 이번 세션 자체는 에러/QA 실패 없이 진행됨(이전 세션이 겪은 실패는 커밋 전 상태에서 이미 해결되어 있었음).
- 남은 제약: status.md #35/#36이 남긴 남은 과제 중 "카메라 authority 처리를 2-프로세스 환경에서 헤드리스로 확인"은 여전히 미실행이다. `JOINING_PLAYER_SPAWN_OFFSET`(60px)은 겹침을 없애기 위한 최소한의 상식적 기본값이라, 3명 이상 동시 접속 시 여러 신규 피어가 같은 오프셋 좌표에 다시 겹쳐 스폰될 수 있다는 한계가 있다(design.md에 동시 접속 인원 수가 명시되지 않아 범위 밖으로 남겨둠 — 접속자별로 오프셋을 다르게 하려면 접속 순서를 세는 카운터가 필요한데, 이번 조각의 범위("두 프로세스 간 위치 동기화 실측")를 넘어선다).
- 다음 할 일: design.md의 "멀티플레이" 로드맵상, 이제 서버<->클라이언트 양방향 위치 동기화가 모두 실측되었다. inbox.md에 새 지시가 없다면 다음 세션은 (1) status.md #36이 남긴 "카메라 authority를 2-프로세스 환경에서 헤드리스로 확인", 또는 (2) 이번 세션이 남긴 "3명 이상 동시 접속 시 스폰 위치 겹침" 한계 보완(예: 접속 순서 기반 오프셋) 중 규칙 4(기능 하나만)에 따라 하나를 골라 진행한다.

---

### #38 — 2026-09-01 20:55 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #37이 남긴 두 후보((1) 카메라 authority 2-프로세스 확인 vs (2) 3명 이상 동시 접속 시 스폰 위치 겹침 보완) 중 (2)를 이어받았다. (1)은 새 기능을 만드는 것이 아니라 이미 구현된 로직을 다른 방식(2-프로세스)으로 다시 확인하는 성격이라 "확인" 단계에 가깝고, (2)는 status.md #37이 명시적으로 남긴 미해결 한계(고정 오프셋 벡터라 신규 피어가 2명 이상이면 서로 겹쳐 스폰됨)를 실제로 고치는 조각이라 CLAUDE.md 한 바퀴의 "하나 만들기" 단계에 더 부합한다고 판단했다.
  - `scripts/main.gd`: `_create_player_instance(id)`가 쓰던 고정 오프셋 상수 `JOINING_PLAYER_SPAWN_OFFSET`(60, 0)을 제거하고, 접속 "순서"를 세는 `_join_spawn_index`(호스트 제외, 매 신규 피어 스폰마다 1씩 증가)와 `_join_spawn_offset(index)`로 대체했다. 각 신규 피어는 `PLAYER_SPAWN_POSITION`에서 반지름 `JOINING_PLAYER_SPAWN_RADIUS`(60px) 고정, 각도만 `JOINING_PLAYER_SPAWN_ANGLE_STEP`(45도)씩 회전한 위치에 스폰된다. 반지름을 고정하고 각도만 바꾸는 원형 배치를 택한 이유: 한 방향으로만 계속 밀어내면(예: 60,120,180...) 인원이 늘수록 섬 경계(바다) 밖으로 스폰될 위험이 커지지만, 각도만 바꾸면 인원이 아무리 늘어도 스폰 지점에서 벗어나는 거리가 항상 일정하게 유지된다.
  - 이 카운터가 모든 피어(서버+클라이언트)에서 항상 같은 값에 도달하는 이유: `_create_player_instance`는 `MultiplayerSpawner.spawn_function`으로 등록되어 있어, 서버가 `spawn(id)`를 호출하면 그 이벤트가 모든 피어에 같은 순서로 복제되어 재생된다(#34에서 이미 확립된 커스텀 spawn_function 패턴). 각 피어가 로컬 시계나 접속 타이밍으로 독립 판단하는 것이 아니라 같은 이벤트 스트림을 같은 순서로 재생하므로, `_join_spawn_index`도 모든 피어에서 항상 동일한 값으로 증가한다.
  - `tests/join_spawn_offset_headless_test.gd` 신설: `network_player_spawn_headless_test.gd`와 같은 패턴(오프라인 기본 상태에서 `main._on_peer_connected()`를 직접 호출)으로 피어 2, 3, 4가 연달아 접속하는 상황을 흉내내, (1) 4개 Player 인스턴스(호스트+3명)가 모두 스폰되는지, (2) 서로의 위치가 전혀 겹치지 않는지(모든 쌍의 거리 ≥ 1px), (3) 신규 피어 각각이 호스트로부터 정확히 `JOINING_PLAYER_SPAWN_RADIUS`만큼 떨어져 있는지(오차 0.5px 이내) 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 `tests/join_spawn_offset_headless_test.gd` → `HEADLESS_JOIN_SPAWN_OFFSET_TEST: PASS`. 회귀 확인을 위해 기존 17종 모두 재실행: `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `boundary_headless_test`(`PASS`), `camera_authority_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `network_client_to_server_sync_headless_test`(`PASS (server_side_position=(222.0, 777.0))`) 모두 이상 없음. `ps aux`로 테스트 종료 후 잔여 godot 서버 프로세스가 없음을 확인. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 원형 배치도 완벽하지 않다 — 접속자가 8명을 넘으면 각도가 360도를 넘어 한 바퀴 돌아 처음 각도(0도)와 다시 겹치기 시작한다(반지름은 그대로라 완전히 같은 좌표는 아니지만, 8명 간격으로 방향이 반복됨). design.md에 동시 접속 인원 상한이 명시되지 않아 이번 조각에서는 손대지 않았고, 실제로 8명 이상 동시 접속이 유의미한 시나리오가 되면 반지름도 함께 늘리는 방식(예: 나선형 배치)으로 확장할 수 있다. 반지름(60px)과 각도 간격(45도)은 design.md의 "범위 밖" 밸런스 수치에 해당하는 하네스의 상식적 기본값이다.
- 다음 할 일: design.md의 "멀티플레이" 로드맵상 접속/스폰/이동 동기화/카메라 authority/스폰 겹침까지 기본 골격이 갖춰졌다고 판단한다. inbox.md에 새 지시가 없다면 다음 세션은 (1) status.md #36이 남긴 "카메라 authority를 2-프로세스 환경에서 헤드리스로 확인"(여러 세션째 미뤄지고 있는 순수 검증 과제), 또는 (2) 지금까지 쌓인 오버레이(슬롯/커스터마이징/튜토리얼)와 멀티플레이 기능이 실제로 두 프로세스에서 함께 동작할 때 시각적으로 자연스러운지 사람이 직접 확인하는 것 중 하나를 고려한다. 특히 (1)은 여러 세션 동안 "다음 후보"로만 남아있었으므로, 다음 세션은 다른 새 기능보다 이 검증을 우선하는 것도 고려할 만하다.

---

### #39 — 2026-09-01 21:05 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #38이 "여러 세션 동안 다음 후보로만 남아있었다"며 우선 진행을 권한 (1) "카메라 authority를 2-프로세스 환경에서 헤드리스로 확인"을 이어받았다. 새 게임 기능을 만드는 것이 아니라 status.md #36에서 이미 구현한 로직(scripts/player.gd의 `camera.enabled = is_multiplayer_authority()`)을 다른 검증 방식으로 확인하는 조각이라, 규칙 4의 "만들기"보다는 "확인"에 가깝지만, 실제 코드(신규 헤드리스 테스트 2개)를 새로 작성하는 작업이라 이번 세션의 "하나 만들기"로 진행했다.
  - `tests/camera_authority_2proc_server_headless.gd` 신설(헬퍼, 단독 실행 대상 아님): status.md #35/#37이 확립한 "호스트 역할" 패턴(`network_sync_server_headless.gd`, `network_client_to_server_sync_headless_test.gd`)을 재사용해 `host()` 후 `Main.tscn`을 로드하고, 접속한 원격 피어의 Player가 스폰될 때까지 기다린 뒤 (1) 자기 자신(호스트, authority)의 카메라가 켜져 있는지, (2) 원격으로 복제된 클라이언트 Player의 카메라가 꺼져 있는지 확인한다.
  - **새로 필요했던 것(기존 2-프로세스 테스트와의 차이)**: 지금까지의 2-프로세스 테스트(#32/#33/#35/#37)는 모두 테스트를 실행하는 쪽(클라이언트 또는 서버 중 하나) 한쪽만 단정하면 충분한 시나리오였다. 이번엔 "양쪽 모두 자신의 카메라는 켜고 상대의 복제본은 꺼야 한다"는 대칭 조건이라 양쪽 프로세스의 관찰 결과가 모두 필요했다. 두 프로세스는 서로의 씬 트리에 직접 접근할 수 없으므로, 서버가 자신의 검증 결과("PASS" 또는 "FAIL: 이유")를 `res://tests/_camera_authority_2proc_result.tmp` 파일에 적어두고 종료하면, 클라이언트 쪽 테스트가 서버 프로세스 종료(`OS.is_process_running()`)를 기다렸다가 그 파일을 읽어 자신의 검증 결과와 합치는 방식을 새로 도입했다. 파일은 테스트 종료 시(성공/실패 모두) 항상 삭제해 다음 실행에 영향을 주지 않게 했다.
  - `tests/camera_authority_2proc_headless_test.gd` 신설(테스트 본체, 클라이언트 역할): status.md #35의 `network_position_sync_headless_test.gd`와 동일한 역할 배치(테스트 자신이 클라이언트, 서버를 백그라운드 프로세스로 띄움)로 서버에 접속하고, 접속 후 자신의 고유 id로 계산한 자기 Player 이름과 호스트의 "Player"가 모두 스폰될 때까지 기다린 뒤 (1) 자기 자신의 카메라가 켜져 있는지, (2) 원격으로 복제된 호스트 Player의 카메라가 꺼져 있는지, (3) 자신의 Player와 호스트의 Player가 서로 다른 노드인지(오프라인 상태의 우연한 통과를 배제하기 위한 안전장치) 확인한다. 포트는 기존 8921/8922/8923과 겹치지 않도록 8924를 새로 썼다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 `tests/camera_authority_2proc_headless_test.gd` → `HEADLESS_CAMERA_AUTHORITY_2PROC_TEST: PASS (client=Player_1734457290, server=PASS)` — 실제 2-프로세스 환경에서도 각 피어가 자신의 카메라만 켜고 원격으로 복제된 상대의 카메라는 꺼진 채로 유지됨을 실측 확인(클라이언트에 배정된 무작위 31비트 id도 status.md #37이 이미 관찰한 것과 동일한 패턴으로 정상 처리됨). 회귀 확인을 위해 기존 18종(신규 포함 전) 모두 재실행: `boundary_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `camera_authority_headless_test`(`PASS`, 기존 단일 프로세스 시뮬레이션 버전), `network_client_to_server_sync_headless_test`(`PASS (server_side_position=(222.0, 777.0))`), `join_spawn_offset_headless_test`(`PASS`) 모두 이상 없음. `ps aux`로 테스트 종료 후 잔여 godot 서버 프로세스가 없음과, 결과 임시 파일(`_camera_authority_2proc_result.tmp`)이 정리되어 남지 않음을 확인. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 이번 조각으로 status.md #36/#38이 미뤄온 검증 과제는 해소됐지만, 기존 단일 프로세스 시뮬레이션 테스트(`camera_authority_headless_test.gd`)를 대체하지 않고 그대로 남겨뒀다 — 2-프로세스 테스트는 실제 네트워크 핸드셰이크·프로세스 기동 시간 때문에 더 느리고(수 초 vs 즉시), 두 테스트가 서로 다른 것을 검증한다(단일 프로세스: 로직 자체의 정확성 / 2-프로세스: 실제 복제 환경에서도 그 로직이 같은 결론에 도달하는가)고 판단해 의도적으로 둘 다 유지했다. status.md #38이 언급한 "지금까지 쌓인 오버레이(슬롯/커스터마이징/튜토리얼)와 멀티플레이 기능이 실제로 두 프로세스에서 함께 동작할 때 시각적으로 자연스러운지"는 여전히 사람이 직접 확인하지 않은 상태다.
- 다음 할 일: design.md의 "멀티플레이" 로드맵상 접속/스폰/이동 동기화(양방향)/카메라 authority(단일·2-프로세스 모두)/스폰 겹침까지 기본 골격이 헤드리스 테스트로 뒷받침된 상태로 갖춰졌다고 판단한다. inbox.md에 새 지시가 없다면 다음 세션은 (1) 사람이 직접 두 개의 에디터/실행 인스턴스로 접속해 슬롯·커스터마이징·튜토리얼 오버레이와 멀티플레이가 함께 자연스럽게 동작하는지 시각적으로 확인, 또는 (2) design.md 로드맵에서 아직 다루지 않은 세부(예: 포획한 동물의 실제 활용, 장비 획득 경로의 UI화, 물고기 채집 등 design.md가 언급했지만 구현되지 않은 대상) 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행하는 것을 권장한다.

---

### #40 — 2026-09-01 21:16 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #39가 남긴 두 후보((1) 사람이 직접 두 인스턴스로 접속해 시각적으로 확인 vs (2) design.md가 언급했지만 구현되지 않은 세부, 특히 "물고기 채집") 중, 이 세션이 비대화형 자동 세션이라 (1)은 수행할 수 없어(사람이 화면을 봐야 함) 제외하고 (2)를 이어받았다. design.md의 세계관 문장("섬에는 다양한 식물, 나무, 동물, 물고기가 서식한다")이 명시한 네 대상 중 나무(채집)와 동물(사냥/포획)은 이미 구현되어 있었지만 물고기는 전혀 없었다 — design.md 원문에 이름이 직접 등장하는 항목이라 "범위 밖"이 아니라 명확히 만들어야 할 대상으로 판단했다.
- 한 일:
  - `scripts/fish.gd`, `scenes/Fish.tscn` 신설: `scripts/tree.gd`의 패턴(정적 채집물 + 등급(grade 1~3) + 장비 게이팅 + hits_required=grade)을 그대로 재사용하되, 도끼/마취총과 구분되는 새 장비 슬롯 "rod"(낚싯대)를 요구하도록 했다. 실제 수영/캐스팅 등 물 위 이동 메커닉은 design.md "범위 밖"(지형 생성 방식 미정)이라, 이번 조각은 물고기를 섬 위 걸어서 도달 가능한 위치(해안가에 가까운 지점)에 배치해 나무와 동일한 방식(근접 + ui_accept)으로 상호작용하는 최소 구현으로 범위를 좁혔다.
  - `scripts/player.gd`: `equipment` 딕셔너리에 `"rod": {"name": "낚싯대", "grade": 1}` 추가 — "기본 코디 제공"과 동일한 논리(장비를 얻을 상점/제작 시스템이 아직 없어 기본 장착 상태로 시작하지 않으면 물고기와 아예 상호작용할 수 없음).
  - `scripts/main.gd`: `RESOURCE_TO_SLOT`에 `"물고기": "rod"` 추가 — 기존 통나무/고기와 동일한 자동 강화 경로(`_try_upgrade_equipment`)에 물고기도 그대로 올라타도록 함. `harvested`/`equipment_label` 로직은 이미 그룹 기반(`harvestable`, `RESOURCE_TO_SLOT.values()`)으로 일반화되어 있어 fish 전용 코드 추가 없이 자동으로 연결됨.
  - `scenes/Main.tscn`: `Fish`(1450, 850, grade 1), `Fish2`(150, 200, grade 2) 배치 — 기존 Tree/Tree2/Animal/Animal2/Player 스폰 위치와 겹치지 않는 섬 안쪽 지점. 튜토리얼 문구에 "물고기 낚시" 한 줄 추가.
  - `tests/fish_harvest_headless_test.gd` 신설: `tree_harvest_headless_test.gd`와 동일한 패턴(범위 밖 무반응 확인 -> 범위 안 이동 -> 상호작용 -> 인벤토리 반영 확인)에, fish.gd가 장비 게이팅 패턴을 실제로 상속했는지 확인하기 위해 낚싯대를 해제한 상태에서는 낚시가 되지 않는 케이스도 추가로 검증했다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 `tests/fish_harvest_headless_test.gd` -> `HEADLESS_FISH_HARVEST_TEST: PASS`. 회귀 확인을 위해 기존 20종 모두 개별 재실행: `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `boundary_headless_test`(`PASS`), `camera_authority_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `join_spawn_offset_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS`), `network_client_to_server_sync_headless_test`(`PASS`), `camera_authority_2proc_headless_test`(`PASS`) 모두 이상 없음. `ps aux`로 잔여 godot 프로세스 없음 확인. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 물고기가 실제 물(바다) 위가 아니라 섬 육지 위에 배치되어 있다 — "해안가 낚시터" 정도로 눈감아 넘긴 근사치다. design.md가 지형 생성 방식·섬 크기를 아직 확정하지 않았으므로(범위 밖), 실제 해안선을 따라 낚시 지점을 배치하거나 물 위에서의 낚싯줄 캐스팅을 구현하는 것은 지형 시스템이 더 구체화된 이후 세션의 과제로 남긴다. 등급별 보상 차등(현재는 등급과 무관하게 항상 "물고기" x1)도 design.md에 명시되지 않아 다루지 않았다.
- 다음 할 일: 이제 design.md가 명시한 네 가지 서식 대상(식물/나무/동물/물고기) 중 나무·동물·물고기 세 가지가 구현되었다. "식물"만 아직 별도 채집 대상으로 존재하지 않는다(나무가 넓은 의미의 식물에 포함된다고 볼 수도 있으나, design.md가 나무와 식물을 별도 항목으로 나열한 점을 볼 때 구분된 대상으로 보는 것이 원문에 더 충실하다). inbox.md에 새 지시가 없다면, 다음 세션은 (1) 식물(예: 채집 가능한 풀/열매 - 나무보다 가볍고 장비 없이도 채집 가능한 대상으로 차별화하는 것을 고려) 채집 시스템 추가, 또는 (2) status.md #39가 남긴 "사람이 직접 두 인스턴스로 접속해 시각적으로 확인" 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행한다.
