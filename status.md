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
