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
