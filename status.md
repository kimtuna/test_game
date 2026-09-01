# status.md — 인수인계서

새 항목은 번호를 이어서 맨 아래에 추가한다. 기존 항목은 수정/삭제하지 않는다. 가장 마지막 번호가 이번 세션의 출발점이다.

**세션 시작 시 이 파일은 전체를 다 읽지 말고, 마지막 5~10개 항목만 읽어서 이어받을 것** (근거: `CLAUDE.md`의 토큰 절감 규칙 참고). #1~#36은 `status_archive.md`로 옮겨졌다 — 그 시절의 판단 근거가 궁금할 때만 그 파일을 열어본다.

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

---

### #41 — 2026-09-01 21:08 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #40이 남긴 두 후보((1) 식물 채집 시스템 추가 vs (2) 사람이 직접 두 인스턴스로 접속해 시각적으로 확인) 중, 이번 세션도 비대화형 자동 세션이라 (2)는 수행할 수 없어 (1)을 이어받았다.
- 한 일:
  - `scripts/plant.gd`, `scenes/Plant.tscn` 신설: `tree.gd`/`fish.gd`의 패턴(정적 채집물 + 등급(grade 1~3) + hits_required=grade)을 재사용하되, status.md #40이 이미 남긴 판단(식물을 "나무보다 가볍고 장비 없이도 채집 가능한 대상"으로 차별화)에 따라 장비 게이팅(tool/weapon/rod 요구)을 의도적으로 넣지 않았다. design.md 원문이 "식물, 나무, 동물, 물고기"를 별개 항목으로 나열한 점에 충실하기 위해 나무와는 구분되는 대상으로 만들었다.
  - `scenes/Main.tscn`: `Plant`(576, 600, grade 1), `Plant2`(1000, 300, grade 2) 배치 — 기존 Player/Tree/Tree2/Animal/Animal2/Fish/Fish2 스폰 위치와 겹치지 않는 섬 안쪽 지점(반경 100px 이상 이격). 튜토리얼 문구를 "나무 채집" -> "식물/나무 채집"으로 갱신.
  - `tests/plant_harvest_headless_test.gd` 신설: `tree_harvest_headless_test.gd`와 동일한 패턴(범위 밖 무반응 -> 범위 안 이동 -> 상호작용 -> 인벤토리 반영)에, plant.gd가 실제로 장비 게이팅 없이 동작하는지 확인하기 위해 tool/weapon/rod를 모두 해제한 상태에서 채집이 성립하는지도 함께 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 `tests/plant_harvest_headless_test.gd` -> `HEADLESS_PLANT_HARVEST_TEST: PASS`. 회귀 확인을 위해 기존 21종(신규 포함 전) 모두 개별 재실행: `boundary_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `join_spawn_offset_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `camera_authority_headless_test`(`PASS`), `fish_harvest_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `network_client_to_server_sync_headless_test`(`PASS (server_side_position=(222.0, 777.0))`), `camera_authority_2proc_headless_test`(`PASS`) 모두 이상 없음. `ps aux`로 잔여 godot 프로세스 없음 확인. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 식물의 채집 보상("채소" 1종)은 현재 어떤 장비 슬롯과도 연결되지 않아(`main.gd`의 `RESOURCE_TO_SLOT`에 미등록) 등급 강화 경로에 기여하지 않는다 — design.md가 식물 전용 장비(예: 낫)나 요리/가공 시스템을 명시하지 않아 범위 밖으로 남겨둔 의도적 선택이다. 등급별 보상 차등(현재는 등급과 무관하게 항상 "채소" x1)도 나무/물고기와 동일하게 다루지 않았다.
- 다음 할 일: 이제 design.md가 명시한 네 가지 서식 대상(식물/나무/동물/물고기)이 모두 최소 구현되었다. inbox.md에 새 지시가 없다면, 다음 세션은 (1) 사람이 직접 에디터/두 인스턴스로 접속해 지금까지 쌓인 채집(식물/나무/물고기)·사냥/포획(동물)·등급/장비·튜토리얼·캐릭터 슬롯/커스터마이징·멀티플레이가 함께 자연스럽게 동작하는지 시각적으로 확인, 또는 (2) design.md 로드맵에서 아직 다루지 않은 세부(포획한 동물의 실제 활용, 장비 획득 경로의 UI화, 채소/식물 전용 장비·보상 연결 등) 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행하는 것을 권장한다.

---

### #42 — 2026-09-01 21:12 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #41이 남긴 두 후보((1) 사람이 직접 접속해 시각적으로 확인 vs (2) 아직 다루지 않은 세부: 포획한 동물의 실제 활용/장비 획득 경로의 UI화/채소·식물 전용 장비·보상 연결) 중, 이번 세션도 비대화형 자동 세션이라 (1)은 수행할 수 없어 (2)를 검토했다. 코드를 다시 읽던 중, design.md 원문("보스는 없다. 대신 식물/나무/동물/물고기 각각에 등급이 존재하고, 높은 등급일수록 잡거나 채집하기 어렵다. 유저는 더 높은 등급을 상대하기 위해 장비를 맞춰(강화/교체) 나간다.")이 네 서식 대상 모두에 동일한 등급·장비 원칙을 명시하고 있는데, `scripts/plant.gd`(status.md #41)만 유일하게 장비 게이팅이 전혀 없이 항상 상호작용 가능한 예외로 남아있는 것을 발견했다. #41은 "식물, 나무, 동물, 물고기를 별개 항목으로 나열한 점"에 근거해 식물을 차별화했지만, 다시 읽어보니 그 근거는 서식 대상의 "종류가 다르다"는 것이지 "등급·장비 원칙에서 제외된다"는 근거가 되지 못한다 — design.md의 등급·장비 문장은 네 대상을 예외 없이 함께 묶어 말하고 있다. 규칙 1(합격 기준)에 따라 이는 새 게임플레이 확장이 아니라 design.md 원문과 기존 구현 사이의 불일치를 바로잡는 수정으로 판단해 이번 세션 작업으로 진행했다.
  - `scripts/player.gd`: `equipment` 딕셔너리에 `"sickle": {"name": "낫", "grade": 1}` 추가 — tool(도끼)/weapon(마취총)/rod(낚싯대)와 동일하게 기본 장착 상태로 시작(장비를 얻을 상점/제작 시스템이 없는 현재 단계에서 빈 슬롯으로 시작하면 식물과 아예 상호작용할 수 없기 때문, 기존 세 슬롯과 동일한 논리).
  - `scripts/plant.gd`: `_register_hit()`에 tree.gd/fish.gd와 동일한 패턴의 장비 게이팅(`has_equipped("sickle")`, `get_equipment_grade("sickle") < grade`) 추가. 파일 상단 주석에 #41의 판단을 왜 뒤집었는지 근거를 남김.
  - `scripts/main.gd`: `RESOURCE_TO_SLOT`에 `"채소": "sickle"` 추가 — 통나무/고기/물고기와 동일한 자동 강화 경로(`_try_upgrade_equipment`)에 채소도 그대로 올라타, #41이 "남은 제약"으로 남겼던 "채소가 어떤 장비 슬롯과도 연결되지 않아 등급 강화 경로에 기여하지 않는다"는 문제도 함께 해소됨.
  - `tests/plant_harvest_headless_test.gd`: #41이 작성한 "장비 없이도 채집 가능해야 한다" 검증을 `fish_harvest_headless_test.gd`와 동일한 패턴(낫 해제 시 채집 실패 -> 낫 재장착 시 채집 성공)으로 교체.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 동작을 반영한 `tests/plant_harvest_headless_test.gd` -> `HEADLESS_PLANT_HARVEST_TEST: PASS`. 회귀 확인을 위해 기존 21종(신규 포함 전) 모두 개별 재실행: `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `boundary_headless_test`(`PASS`), `camera_authority_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `join_spawn_offset_headless_test`(`PASS`), `fish_harvest_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `network_client_to_server_sync_headless_test`(`PASS (server_side_position=(222.0, 777.0))`), `camera_authority_2proc_headless_test`(`PASS`) 모두 이상 없음. `ps aux`로 잔여 godot 프로세스 없음 확인. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 낫(sickle)의 기본 grade는 1이라 이미 배치된 Plant(grade 1)/Plant2(grade 2)는 나무/물고기와 동일하게 승급이 필요해졌다 — 시각적으로 확인하면 처음에는 Plant2가 채집되지 않는 것이 정상 동작이니 참고할 것. 등급별 보상 차등(채소는 등급과 무관하게 항상 x1)은 나무/물고기와 마찬가지로 이번 조각에서 다루지 않았다.
- 다음 할 일: design.md가 명시한 네 서식 대상(식물/나무/동물/물고기)이 이제 등급·장비 게이팅까지 일관되게 구현되었다. inbox.md에 새 지시가 없다면, 다음 세션은 (1) 사람이 직접 에디터/두 인스턴스로 접속해 지금까지 쌓인 기능 전체(채집 4종·사냥/포획·등급/장비·튜토리얼·슬롯/커스터마이징·멀티플레이)가 함께 자연스럽게 동작하는지 시각적으로 확인, 또는 (2) design.md 로드맵에서 아직 다루지 않은 세부(포획한 동물의 실제 활용, 장비 획득 경로의 UI화, 등급별 보상 차등 등) 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행하는 것을 권장한다. 특히 (1)은 여러 세션째 비대화형 환경 제약으로 미뤄지고 있으므로, 사람이 실행 가능한 세션에서는 이를 우선 고려할 만하다.

---

### #43 — 2026-09-02 01:25 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #42가 남긴 두 후보((1) 사람이 직접 접속해 시각적으로 확인 vs (2) 아직 다루지 않은 세부: 포획한 동물의 실제 활용/장비 획득 경로의 UI화/등급별 보상 차등) 중, 이번 세션도 비대화형 자동 세션이라 (1)은 수행할 수 없어 (2)를 검토했다. 세 후보 중 "등급별 보상 차등"을 골랐다 — #41/#42가 이미 "남은 제약"으로 명시적으로 남긴 항목이라 판단 근거가 이미 정리돼 있었고, "포획한 동물의 실제 활용"은 design.md가 세부(사육/방목/번식 등)를 전혀 명시하지 않아 규칙 4(기능 하나만)를 넘어서는 설계 결정이 먼저 필요했으며, "장비 획득 경로의 UI화"는 현재 equipment_label이 이미 실시간으로 갱신되고 있어(status.md #27) 얻는 실익이 상대적으로 작다고 판단했다.
- 한 일:
  - `scripts/tree.gd`/`scripts/fish.gd`/`scripts/plant.gd`/`scripts/animal.gd`: 채집/사냥 성공 시 `harvested.emit(resource_name, 1)`로 항상 고정이던 보상 수량을 `harvested.emit(resource_name, grade)`로 바꿔, 대상의 등급만큼 보상이 나오도록 했다. design.md가 "높은 등급일수록 잡거나 채집하기 어렵다"고만 말하고 보상 차등을 명시하진 않았지만, 지금까지는 등급이 오를수록 상호작용 난이도만 올라가고 얻는 자원은 동일해 "장비를 맞춰 더 높은 등급에 도전할" 유인이 부족했다 — 별도 보상 테이블을 새로 설계하지 않고, 이미 난이도 표현에 쓰던 `grade` 값 하나를 보상 수량에도 그대로 재사용해 규칙 4(기능 하나만) 범위를 넘지 않게 했다. 동물 포획(capture)은 자원 소비가 아니라 개체를 그대로 소유하는 별개 경로라 이번 변경 대상에서 제외했다.
  - `tests/grade_reward_headless_test.gd` 신설: Main.tscn에 이미 배치된 등급 2 개체(Tree2/Fish2/Plant2/Animal2)를 대상으로 등급만큼 상호작용한 뒤 인벤토리에 통나무/물고기/채소/고기가 각각 x2로 반영되는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 `tests/grade_reward_headless_test.gd` -> `HEADLESS_GRADE_REWARD_TEST: PASS`. 회귀 확인을 위해 기존 21종 모두 개별 재실행: `boundary_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `camera_authority_headless_test`(`PASS`), `network_client_to_server_sync_headless_test`(`PASS (server_side_position=(222.0, 777.0))`), `join_spawn_offset_headless_test`(`PASS`), `fish_harvest_headless_test`(`PASS`), `plant_harvest_headless_test`(`PASS`), `camera_authority_2proc_headless_test`(`PASS`) 모두 이상 없음. 기존 테스트들이 전부 grade=1 개체(Tree/Fish/Plant/Animal)를 대상으로 하고 있어 `amount = grade = 1`이 그대로 유지돼 회귀 없이 통과했다. `ps aux`로 잔여 godot 프로세스 없음 확인. 이번 세션은 에러/QA 실패 없이 진행됨.
- 다음 할 일: design.md가 명시한 네 서식 대상(식물/나무/동물/물고기)의 등급·장비·보상 체계가 이제 일관되게 구현되었다. inbox.md에 새 지시가 없다면, 다음 세션은 (1) 사람이 직접 에디터/두 인스턴스로 접속해 지금까지 쌓인 기능 전체(채집 4종·사냥/포획·등급/장비/보상·튜토리얼·슬롯/커스터마이징·멀티플레이)가 함께 자연스럽게 동작하는지 시각적으로 확인, 또는 (2) design.md 로드맵에서 아직 다루지 않은 세부(포획한 동물의 실제 활용 — 사육/방목/번식 등 세부 설계가 먼저 필요, 장비 획득 경로의 UI화, 섬 경계/지형의 다양화 등) 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행하는 것을 권장한다. (1)은 여러 세션째 비대화형 환경 제약으로 미뤄지고 있으므로, 사람이 실행 가능한 세션에서는 이를 우선 고려할 만하다.

---

### #44 — 2026-09-02 01:29 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #43이 남긴 후보 중 (1) 사람이 직접 접속해 시각적으로 확인은 이번 세션도 비대화형이라 수행할 수 없어 제외했다. (2)의 세 세부(포획한 동물의 실제 활용/장비 획득 경로의 UI화/섬 경계·지형의 다양화) 중 "섬 경계·지형의 다양화"를 골랐다 — 포획한 동물 활용은 design.md에 사육·방목·번식 등 세부가 전혀 없어 규칙 4(기능 하나만)를 넘어서는 설계 결정이 먼저 필요하고, 장비 획득 경로 UI화는 이미 equipment_label이 실시간으로 갱신되고 있어(#27) 얻는 실익이 상대적으로 작다고 판단했다. 반면 지형은 현재 잔디(섬)와 바다 단 두 가지 색뿐이라 시각적으로 단조로웠고, design.md도 "섬의 구체적 지형"은 범위 밖으로 남겨뒀을 뿐 지형 자체를 다양화하는 것을 막지는 않는다.
- 한 일:
  - `scripts/terrain.gd`: `BEACH_MARGIN`(150px)과 `BEACH_SIZE`(`ISLAND_SIZE` + 마진의 2배) 상수, `beach: Sprite2D` 참조를 추가하고 `_ready()`에서 모래색(0.85, 0.75, 0.5)으로 채운 텍스처를 입혔다. 걸어다닐 수 있는 영역이나 충돌 경계(`_create_boundary_walls`가 여전히 `ISLAND_SIZE` 기준으로만 벽을 세움)는 건드리지 않고, 그 바깥에 "보이기만 하는" 모래띠만 추가했다 — `boundary_headless_test`를 비롯해 `ISLAND_HALF_WIDTH`(1000)를 가정하는 기존 경계 관련 테스트들이 그대로 통과하도록 의도적으로 범위를 좁혔다.
  - `scenes/Main.tscn`: `Terrain` 아래 `Ocean`과 `Island` 사이에 `Beach` `Sprite2D` 노드(같은 위치 576,324)를 추가했다. Godot 2D는 같은 부모 아래 형제 노드를 트리 순서대로 그리므로(나중 노드가 위에 그려짐), Ocean -> Beach -> Island 순서로 두어 잔디 섬 가장자리에 모래 링이 보이게 했다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 기존 22종 헤드리스 테스트를 모두 개별 재실행: `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS (moved_distance=135.7, boundary_x=1576.0, island_right_edge=1576.0)`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `boundary_headless_test`(`PASS (final_x=1560.0, island_right_edge=1576.0)`), `camera_authority_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `fish_harvest_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `grade_reward_headless_test`(`PASS`), `join_spawn_offset_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `plant_harvest_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `network_client_to_server_sync_headless_test`(`PASS (server_side_position=(222.0, 777.0))`), `camera_authority_2proc_headless_test`(`PASS`) 모두 이상 없음 — 섬 경계 관련 좌표값(`island_right_edge=1576.0` 등)도 변경 전과 동일해 시각적 지형 추가가 충돌/이동 로직에 전혀 영향을 주지 않았음을 확인. `ps aux`로 잔여 godot 프로세스 없음 확인. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 모래는 섬 전체를 균일한 마진(150px)으로 두른 단순한 사각 링이라, 실제 해안선처럼 굴곡지거나 만(灣)·곶 같은 지형 굴곡은 없다(design.md가 지형 생성 방식·섬 모양을 아직 확정하지 않아 범위 밖). 물고기(#40)가 "해안가 낚시터"의 근사치로 섬 육지 위에 배치되어 있다는 점도 이번 조각으로 바뀌지 않았다 — 모래 링이 걸어다닐 수 없는 순수 시각 요소라, 물고기를 모래 위로 옮기면 오히려 상호작용 불가 지점에 배치하는 셈이 되어 손대지 않았다.
- 다음 할 일: design.md의 핵심 루프(이동/카메라 -> 섬 지형 -> 채집/사냥/포획 -> 등급/장비/보상 -> 튜토리얼 -> 슬롯/커스터마이징 -> 멀티플레이)가 모두 최소 구현과 다중 세션에 걸친 견고성 점검을 거친 상태다. inbox.md에 새 지시가 없다면, 다음 세션은 (1) 사람이 직접 에디터/두 인스턴스로 접속해 지금까지 쌓인 기능 전체가 함께 자연스럽게 동작하는지 시각적으로 확인(여러 세션째 비대화형 제약으로 미뤄지고 있어 사람이 실행 가능한 세션에서는 우선 고려할 만함), 또는 (2) 아직 다루지 않은 세부(포획한 동물의 실제 활용 — 먼저 사육/방목/번식 등 하네스가 판단할 최소 설계가 필요, 해안선 굴곡이 있는 섬 모양, 장비 획득 경로의 UI화) 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행한다.

---

### #45 — 2026-09-02 01:33 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #44가 남긴 세 후보((1) 사람이 직접 접속해 시각적으로 확인 vs (2) 포획한 동물의 실제 활용/해안선 굴곡이 있는 섬 모양/장비 획득 경로의 UI화) 중, 이번 세션도 비대화형이라 (1)은 제외했다. (2)의 세부 중 "해안선 굴곡이 있는 섬 모양"을 골랐다 — #44가 "남은 제약"으로 직접 명시한 항목이라 판단 근거가 이미 정리돼 있었고, 포획한 동물 활용은 여전히 사육/방목/번식 등 design.md에 없는 세부 설계가 먼저 필요해 규칙 4(기능 하나만)를 넘어서며, 장비 획득 경로 UI화는 #43/#42에서 반복 검토했듯 equipment_label이 이미 실시간 갱신 중이라 실익이 작다고 판단했다.
  - `scripts/terrain.gd`: 모래(Beach)의 바깥 경계를 "섬 중심 기준 사각형까지의 유클리드 거리(사각형 SDF)"로 계산하던 고정 마진(`BEACH_MARGIN`=150px) 대신, 그 마진을 각도(angle)에 따라 사인파 두 개(주파수 5·9, 진폭 합 45px)로 흔드는 방식으로 바꿔 만(灣)·곶처럼 보이는 불규칙한 해안선을 만들었다. 각도가 -PI/PI에서 순환하므로 주파수를 정수로 골라 이음매가 보이지 않게 했다.
  - **섬 자체(잔디)와 충돌 경계(`IslandBounds`, `get_island_bounds()`)는 의도적으로 그대로 뒀다** — #44와 같은 이유로, 실제 걸어다닐 수 있는 영역이나 `boundary_headless_test`/`animal_flee_headless_test`가 가정하는 사각형 벽 위치(`island_right_edge=1576.0` 등)를 건드리면 회귀 위험이 커지고, "해안선 굴곡"이라는 시각적 개선의 취지에도 충돌 로직 변경은 필요하지 않다고 판단했다. 대신 모래만 흔들어도 섬 가장자리가 더 이상 완전한 직사각형으로 보이지 않는 효과는 충분히 달성된다.
  - 성능: 텍스처 전체(최대 2390x1690 ≈ 404만 픽셀)를 픽셀 단위로 훑으면 매 `Main.tscn` 인스턴스화(테스트마다 반복)마다 느려질 것을 우려해, 실제로 모래가 그려질 수 있는 가장자리 띠(두께 `BEACH_MAX_MARGIN`≈195px)만 계산하도록 `_set_beach_texture`/`_paint_beach_span`을 작성했다(약 144만 픽셀만 순회, 섬 안쪽 깊은 영역은 애초에 건너뜀).
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음, 0.6초 내 종료). 기존 22종 헤드리스 테스트를 모두 개별 재실행: `boundary_headless_test`(`PASS (final_x=1560.0, island_right_edge=1576.0)`), `animal_flee_headless_test`(`PASS (moved_distance=135.7, boundary_x=1576.0, island_right_edge=1576.0)`), `animal_capture_headless_test`(`PASS`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `camera_authority_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `fish_harvest_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `grade_reward_headless_test`(`PASS`), `join_spawn_offset_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `plant_harvest_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `network_client_to_server_sync_headless_test`(`PASS (server_side_position=(222.0, 777.0))`), `camera_authority_2proc_headless_test`(`PASS`) 모두 이상 없음 — 특히 `boundary_headless_test`/`animal_flee_headless_test`의 좌표값이 변경 전(#44)과 완전히 동일해, 모래 해안선 변경이 실제 충돌/이동 로직에 전혀 영향을 주지 않았음을 확인했다. `ps aux`로 잔여 godot 프로세스 없음 확인. 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: 파형은 섬 중심에서의 각도 하나로만 결정되므로, 사각형 섬(2000x1300, 정사각형이 아님)의 긴 변과 짧은 변에서 같은 각도 변화당 실제 픽셀 이동 거리가 달라 굴곡의 "조밀함"이 위치마다 살짝 다르게 느껴질 수 있다 — 시각적으로 확인하지는 못했으므로(비대화형 세션), 사람이 직접 봤을 때 특정 구간이 부자연스럽다면 주파수/진폭을 조정할 수 있다. 물고기(#40)가 여전히 섬 육지 위(해안가 근사치)에 배치되어 있다는 점도 이번 조각으로 바뀌지 않았다.
- 다음 할 일: design.md의 핵심 루프가 모두 최소 구현과 다중 세션에 걸친 견고성/시각 다양화 점검을 거친 상태다. inbox.md에 새 지시가 없다면, 다음 세션은 (1) 사람이 직접 에디터/두 인스턴스로 접속해 지금까지 쌓인 기능 전체(채집 4종·사냥/포획·등급/장비/보상·튜토리얼·슬롯/커스터마이징·멀티플레이·해안선)가 함께 자연스럽게 동작하고 보기 좋은지 시각적으로 확인(여러 세션째 비대화형 제약으로 미뤄지고 있어 사람이 실행 가능한 세션에서는 최우선으로 고려할 만함), 또는 (2) 아직 다루지 않은 세부(포획한 동물의 실제 활용 — 사육/방목/번식 등 최소 설계 필요, 장비 획득 경로의 UI화) 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행한다.

---

### #46 — 2026-09-02 01:39 (자동 세션)

- 계기: inbox.md에 미처리 항목 없음. status.md #45가 남긴 두 후보((1) 사람이 직접 접속해 시각적으로 확인 vs (2) 포획한 동물의 실제 활용/장비 획득 경로의 UI화) 중, 이번 세션도 비대화형이라 (1)은 제외했다. (2)의 두 세부는 여러 세션(#42/#43) 동안 이미 "실익이 작다"/"설계가 먼저 필요해 범위를 넘어선다"고 반복 판단된 상태라 그대로 고르지 않고, 코드를 다시 읽으며 design.md 원문과 구현 사이의 격차를 다시 찾았다. `scripts/player.gd`의 "기본 코디(의상) 제공" 관련 주석(장비 슬롯을 처음부터 채워두는 것으로 해석)을 다시 보니, design.md 원문("별도로 맞추지 않아도 입고 시작할 수 있는 기본 복장이 있다")은 장비(도구) 지급이 아니라 눈에 보이는 옷차림을 말하는 문장에 더 가깝다고 판단했다. 실제로 캐릭터는 커스터마이징 가능한 단색 사각형 하나뿐이라 "복장을 입고 있다"는 시각적 근거가 전혀 없었다 — #44/#45가 지형(해안선)에 대해 했던 것과 같은 종류의, "이미 있는 요소를 design.md 원문에 더 충실하게 만드는" 보강으로 판단해 이번 세션 작업으로 진행했다.
  - `scripts/player.gd`: `_apply_body_color()`가 그리던 32x32 단색 텍스처를 상/하 두 구역으로 나눴다 — 상단(row 0~19, 커스터마이징 색 `body_color`, 상의 역할)은 그대로 두고, 하단(row 20~31)을 고정된 신규 상수 `OUTFIT_COLOR`(갈색 계열)로 덮어 그려 "기본 코디(하의)"를 표현했다. 여러 부위를 각각 고를 수 있는 커스터마이징 UI는 새 시스템이라 규칙 4(기능 하나만)를 넘어서므로, 하의 색은 고정값으로 최소 구현했다.
  - `tests/outfit_headless_test.gd` 신설: 기본 상태에서 상의(0,0 픽셀)와 하의(0,31 픽셀)가 서로 다른 색으로 그려지는지, 커스터마이징으로 몸 색을 바꿔도(빨강) 하의 색은 그대로 유지되는지 검증.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 신규 `tests/outfit_headless_test.gd` -> `HEADLESS_OUTFIT_TEST: PASS`. 기존 23종 모두 개별 재실행: `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS (moved_distance=139.3, boundary_x=1576.0, island_right_edge=1576.0)`), `animal_hunt_headless_test`(`PASS (hits=4)`), `animal_sight_flee_headless_test`(`PASS`), `animal_sound_flee_headless_test`(`PASS`), `boundary_headless_test`(`PASS (final_x=1560.0, island_right_edge=1576.0)`), `camera_authority_headless_test`(`PASS`), `customization_headless_test`(`PASS`) — `player.body_color`/텍스처 (0,0) 픽셀만 검사하는 이 테스트는 하단 영역 변경과 무관하게 그대로 통과함, `equipment_gate_headless_test`(`PASS`), `equipment_upgrade_headless_test`(`PASS`), `fish_harvest_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `grade_reward_headless_test`(`PASS`), `join_spawn_offset_headless_test`(`PASS`), `network_player_spawn_headless_test`(`PASS`), `network_spike_headless_test`(`PASS`), `plant_harvest_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tree_harvest_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `network_position_sync_headless_test`(`PASS (remote_position=(999.0, 111.0))`), `network_client_to_server_sync_headless_test`(`PASS (server_side_position=(222.0, 777.0))`) 모두 이상 없음. `ps aux`로 잔여 godot 서버 프로세스 없음 확인. 이번 세션은 에러/QA 실패 없이 진행됨.

  > [!CAUTION]
  > `camera_authority_2proc_headless_test`가 첫 실행에서 `FAIL: 자신(Player_814845876) 또는 호스트(Player)의 Player가 복제되지 않음`으로 실패했다 — 원인: 이 테스트는 실제 두 개의 godot 프로세스(서버/클라이언트)를 띄워 ENet 핸드셰이크와 스폰 복제가 끝나기를 기다리는 방식이라(status.md #39), 시스템 부하 등으로 타이밍이 어긋나면 간헐적으로 실패할 수 있는 구조다. 이번 세션에서 변경한 내용(player.gd의 텍스처 그리기, 신규 outfit 테스트)은 네트워킹/스폰 코드와 전혀 무관해 회귀로 보기 어려웠다. 같은 테스트를 다시 실행하니 `HEADLESS_CAMERA_AUTHORITY_2PROC_TEST: PASS (client=Player_1559711739, server=PASS)`로 통과해, 이번 실패가 이번 세션 변경과 무관한 기존의 간헐적 타이밍 이슈였음을 확인했다.

- 남은 제약: 하의 색(`OUTFIT_COLOR`)은 고정값이라 아직 커스터마이징 대상이 아니다. 상의/하의 2분할도 "복장을 입고 있다"를 표현하는 최소한의 시각적 근사치일 뿐, 실제 의상 아이템(교체 가능한 옷)이나 여러 벌의 코디 선택지는 design.md가 세부를 명시하지 않아(범위 밖) 다루지 않았다. `camera_authority_2proc_headless_test`의 간헐적 타이밍 실패 가능성 자체는 이번 세션에서 고치지 않았다 — 재실행하면 통과하는 기존 특성이라, 원인(프로세스 기동/핸드셰이크 타이밍)을 근본적으로 없애려면 재시도 로직이나 타임아웃 확대 같은 별도 조각이 필요하다.
- 다음 할 일: inbox.md에 새 지시가 없다면, 다음 세션은 (1) 사람이 직접 에디터/두 인스턴스로 접속해 지금까지 쌓인 기능 전체(채집 4종·사냥/포획·등급/장비/보상·튜토리얼·슬롯/커스터마이징·멀티플레이·해안선·기본 코디)가 함께 자연스럽게 동작하고 보기 좋은지 시각적으로 확인(여러 세션째 비대화형 제약으로 미뤄지고 있어 최우선으로 고려할 만함), 또는 (2) 아직 다루지 않은 세부(포획한 동물의 실제 활용, 장비 획득 경로의 UI화, `camera_authority_2proc_headless_test`의 간헐적 타이밍 실패에 대한 재시도/타임아웃 보강) 중 하나를 규칙 4(기능 하나만)에 따라 골라 진행한다.

---

### #47 — 2026-09-02 01:41 (사용자 요청, 자동 세션 아님)

- 계기: 사용자가 토큰 사용량이 너무 많다며 (1) 절감 방법과 (2) design.md 로드맵을 다 채우면 루프가 계속 돌지 말고 멈추길 요청함. `status_archive.md`(#1~36) 확인 결과, design.md "진행 방식에 대한 참고"에 나열된 로드맵 7개 항목이 모두 실질적으로 구현되고 각각 헤드리스 테스트로 QA를 통과한 상태임을 확인했다:
  - 캐릭터 이동/카메라 — #13(Camera2D 추적)
  - 섬 기본 지형 — #14~#16 등(TileMap/지형), #44~#45(해안선)
  - 채집/사냥/포획 — #16(Tree 채집), #19~#23(동물 사냥/포획/도주 3종)
  - 등급·장비 — #24~#27(grade/equipment_gate/equipment_upgrade), #43(등급별 보상)
  - 튜토리얼 — #28~#30대(tutorial_headless_test)
  - 캐릭터 커스터마이징/슬롯 — #31~#33(customization/slot), #46(기본 코디)
  - 멀티플레이(세션 서버) — #34~#42(스폰 복제, 이동 권한, 카메라 authority, 위치 동기화, 2-프로세스 테스트)
  - 위 판단은 "완벽하게 다듬어졌는가"가 아니라 design.md·CLAUDE.md 규칙 1의 객관적 기준인 "각 항목이 실제로 구현되고 QA를 통과했는가"로만 판단했다 (사용자 지시: 다듬기 끝까지가 아니라 QA까지 끝나면 멈추는 것).
- 조치:
  - `status.md`를 정리해 #1~36을 `status_archive.md`로 옮기고(내용 그대로, 삭제 아님), 이 파일에는 최근 10개 항목만 남겼다. 매 세션이 전체를 읽지 않고 최근 항목만 읽도록 상단에 안내를 추가했다.
  - `CLAUDE.md`에 토큰 절감 규칙(상태 파일 최근 항목만 읽기, QA 시 관련 테스트만 선별 실행, status.md 30개 항목 초과 시 재아카이브)과, 로드맵 완료 시 루프를 멈추는 규칙(`HARNESS_STOP` 마커)을 추가했다.
  - `.harness/run_cycle.sh`가 매 사이클 종료 후 `status.md`에서 `HARNESS_STOP`을 감지하면 반복을 멈추고 launchd 등록을 해제하도록 수정했다.
  - launchd 데몬을 완전히 중단(`launchctl bootout`)했다. 지금은 자동 루프가 돌고 있지 않다.

> [!IMPORTANT]
> HARNESS_STOP: design.md 로드맵 1차 완료 확인, 사용자 요청으로 자동 루프 중단.

- 다음 할 일 (자동 세션 재개 없음 — 사용자가 직접 재개해야 함): 사용자가 `inbox.md`에 새 지시(다듬기, 새 기능, 특정 로드맵 항목 심화 등)를 남기고 `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.kdw240.testgame.harness.plist`로 데몬을 다시 켜면, 다음 세션은 그 지시를 이어받아 진행하고, 새로운 완료 조건에 도달하면 다시 `HARNESS_STOP`을 남긴다.

---

### #48 — 2026-09-02 01:58 (수동 실행, 사용자가 하네스 사이클 1회를 직접 요청)

- 계기: `HARNESS_STOP`(#47) 이후 자동 루프는 꺼져 있었지만, 사용자가 이번에는 하네스 사이클을 한 번 수동으로 실행해 달라고 요청했다. `inbox.md`를 확인하니 #4(미처리)가 있어, 규칙("`status.md`의 다음 작업보다 `inbox.md`의 미처리 항목이 우선")에 따라 이를 이어받았다. `inbox.md` #4는 우선순위가 매겨진 5개 항목(1. WASD 이동, 2. 마우스 기반 사냥, 3. 채집은 스페이스 유지, 4. 메인메뉴+슬롯+저장, 5. 제작/줍기/인벤토리 제외)을 담고 있는데, 규칙 4(기능 하나만)에 따라 이번 세션은 우선순위 1번(WASD 이동)만 구현했다.
- 한 일:
  - `project.godot`: `[input]` 섹션에 `move_left`/`move_right`/`move_up`/`move_down` 액션을 새로 정의하고 각각 물리 키코드 A(65)/D(68)/W(87)/S(83)에 바인딩했다. 기존 `ui_left`/`ui_right`/`ui_up`/`ui_down`(Godot 기본 액션, 화살표 키만 바인딩된 상태)은 건드리지 않았다 — 다른 곳에서 UI 포커스 이동 등에 쓰일 수 있는 엔진 기본 액션이라 재정의 대신 새 액션을 추가하는 쪽이 더 안전하다고 판단했다.
  - `scripts/player.gd`: `_physics_process`의 `Input.get_vector("ui_left","ui_right","ui_up","ui_down")`를 `Input.get_vector("move_left","move_right","move_up","move_down")`로 교체.
  - `tests/animal_sound_flee_headless_test.gd`: 발소리 감지 도주를 검증하기 위해 이동을 흉내내던 `Input.action_press/release("ui_left")`를 `"move_left"`로 갱신 — 이 테스트는 실제로 플레이어 이동 입력을 트리거해야 성립하므로, 액션 이름이 바뀌면 그대로 두면 거짓 통과(이동이 감지되지 않아도 이전 상태에 의존해 우연히 통과)나 실패 위험이 있어 이번 변경과 직접 관련된 테스트로 판단해 함께 수정했다.
  - `git diff project.godot`로 확인해보니, 이 파일에는 이번 세션과 무관한 기존 미커밋 변경(세션 시작 시 이미 `M project.godot` 상태 — `[display]`의 `window/size/viewport_width`·`viewport_height`·`window/stretch/aspect` 제거, 파일 상단 표준 주석 추가)도 섞여 있었다. 실행 중이던 `godot -e`(에디터, 사용자가 열어둔 것으로 보이는 PID, 세션 시작 이전부터 떠 있었음)가 저장하며 남긴 것으로 추정된다. 같은 파일이라 분리 커밋이 불가능했고, 사용자가 에디터에서 직접 만든 변경을 되돌리는 것은 범위 밖 판단이라 그대로 두고 함께 커밋했다 — 문제가 있다면 사용자가 직접 되돌릴 수 있다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 이번 변경과 직접 관련된 테스트만 개별 재실행(규칙 4 QA 지침 — 전체 24종을 다 돌리지 않음): `animal_sound_flee_headless_test`(`PASS`, 새 액션으로 도주 트리거 확인), `boundary_headless_test`(`PASS (final_x=1560.0, island_right_edge=1576.0)`, 좌표 변경 없음), `animal_flee_headless_test`(`PASS (moved_distance=135.7, ...)`), `animal_sight_flee_headless_test`(`PASS`), `customization_headless_test`(`PASS`, 이동과 무관하지만 player.gd를 같이 건드려 확인차 포함) 모두 이상 없음. `ps aux`로 확인한 결과 세션이 새로 띄운 잔여 godot 프로세스는 없었다(에디터 PID는 세션 시작 전부터 사용자가 띄워둔 것이라 그대로 둠). 이번 세션은 에러/QA 실패 없이 진행됨.
- 남은 제약: `inbox.md` #4의 2~5번(마우스 기반 사냥/좌클릭 발사·우클릭 탄종류·R 재장전, 채집 스페이스 유지 확인, 메인메뉴+슬롯+저장 시스템, 범위 제외 항목)은 아직 손대지 않았다. 특히 2번은 `scripts/animal.gd`의 `ui_accept` 기반 공격/포획 입력을 좌클릭 발사로 교체하는 작업이라 다음 세션이 이어받아야 한다.
- 다음 할 일: 자동 루프는 여전히 꺼진 상태(#47 `HARNESS_STOP`)이므로, 다음 실행도 사용자가 수동으로 요청하거나 launchd를 다시 켜야 한다. 다음에 이어받을 때는 `inbox.md` #4의 우선순위 2번(마우스 기반 사냥: 좌클릭 발사=공격/포획 트리거, 우클릭=탄종류 슬롯 UI, R=재장전)을 규칙 4(기능 하나만)에 따라 진행할 것을 권장한다 — 이미 이번 세션에서 관련 로직 위치(`scripts/animal.gd`의 `_attack`/포획 처리, `player.gd`의 장비 슬롯)를 확인해뒀다.

---

### #49 — 2026-09-02 02:07 (수동 실행, 사용자가 하네스 사이클 1회를 직접 요청)

- 계기: `HARNESS_STOP`(#47) 이후 자동 루프는 꺼져 있었지만, 사용자가 하네스 사이클을 한 번 더 수동 실행해 달라고 요청했다. `inbox.md` #4는 여전히 "부분 처리"(1번만 #48에서 반영)라 규칙("`status.md`의 다음 작업보다 `inbox.md`의 미처리 항목이 우선")과 #48이 남긴 권장사항에 따라 2번(마우스 기반 사냥: 좌클릭 발사/우클릭 탄종류 변경/R 재장전)을 이어받았다.
- 한 일:
  - `project.godot`: `[input]`에 `fire`(마우스 좌클릭, button_index=1), `switch_ammo`(마우스 우클릭, button_index=2), `reload`(물리 키 R=82) 액션을 추가했다. 더 이상 쓰이지 않게 된 기존 `capture`(C 키) 액션은 제거했다 — 이번 변경으로 대체되는 것이 바로 이 액션이라 남겨두면 죽은 설정으로 남는다.
  - `scripts/player.gd`: 탄종류(`ammo_type`: `"normal"`=일반탄/공격, `"tranquilizer"`=마취탄/포획)와 탄창(`current_ammo`, `MAGAZINE_SIZE=6`) 상태를 추가했다. `switch_ammo_type()`(우클릭 시 두 탄종류를 순환), `reload()`(R 시 탄창을 가득 채움), `try_consume_ammo()`(발사 시도마다 호출 — 무엇을 맞혔는지와 무관하게 탄을 소모한다는 상식적 판단이며, 탄이 없으면 false를 반환해 공격/포획 자체가 진행되지 않게 함)를 만들었다. 화면 좌상단에 현재 탄종류/잔탄을 보여주는 HUD(`Player.tscn`에 `CanvasLayer/Label` 추가)도 함께 넣었다 — 카메라와 동일한 이유로 `is_multiplayer_authority()`가 아닌 원격 Player 인스턴스에서는 꺼둔다.
    - 처음에는 `switch_ammo`/`reload`를 `_unhandled_input(event)` 콜백으로 짰으나, 기존 헤드리스 테스트들이 입력을 흉내낼 때 쓰는 `Input.action_press()`/`action_release()`는 Input 싱글턴의 폴링 상태만 바꿀 뿐 실제 `InputEvent`를 만들어 `_input`/`_unhandled_input`으로 전달하지 않는다는 것을 뒤늦게 확인했다 — 그대로였다면 실제 마우스/키보드로는 동작하지만 헤드리스 테스트로는 검증이 불가능했다. `animal.gd`가 `fire`를 `_process`에서 `Input.is_action_just_pressed()`로 폴링하는 기존 패턴과 일관되도록, `switch_ammo`/`reload`도 `_physics_process` 안에서 폴링하는 방식으로 바꿨다.
  - `scripts/animal.gd`: `_process`의 `ui_accept`(공격)/`capture`(포획) 두 입력을 `fire` 하나로 합쳤다. `fire`가 눌리면 먼저 `player_nearby.try_consume_ammo()`로 탄약을 확인/소모하고, `player_nearby.ammo_type`이 `"tranquilizer"`면 `_try_capture()`를, 아니면 `_attack()`을 호출한다 — 두 함수 내부의 기존 판정 로직(도끼/마취총 장비·등급 게이트, 8% 미만 포획 조건)은 전혀 건드리지 않았다. 이는 inbox.md #4 2번이 명시적으로 요구한 것("판정 로직 자체는 이미 있으니 입력 방식만 바꾸는 것")이다.
  - 관련 헤드리스 테스트 6종(`animal_hunt`, `animal_capture`, `animal_flee`, `equipment_gate`, `grade`, `grade_reward`)에서 동물을 대상으로 한 `ui_accept`/`capture` 입력을 `fire`(+필요시 `player.ammo_type` 사전 설정)로 갱신했다. 나무/물고기/식물(Tree/Fish/Plant) 대상 `ui_accept`는 inbox.md #4 3번("채집은 스페이스 유지")에 따라 그대로 두었다. `grade`/`grade_reward` 테스트는 반복 발사 횟수(최대 7~9회)가 기본 탄창(6발)을 넘어서, 등급/보상 판정을 검증하는 본 목적과 무관한 탄약 소모가 결과를 흐리지 않도록 `player.current_ammo`를 테스트 시작 시 넉넉한 값으로 직접 설정해뒀다(주석으로 이유 명시).
  - `tests/mouse_hunt_headless_test.gd`(신규): 위 6종은 대부분 등급/장비 게이트를 검증하던 기존 테스트를 새 입력으로 옮긴 것뿐이라, 이번에 실제로 추가된 메커니즘(탄종류 순환, 탄약 소모/고갈, 재장전)을 직접 검증하는 테스트가 없었다. 등급 2 동물(Animal2, 최대 체력 200)을 대상으로 (1) 초기 상태가 일반탄 6/6인지, (2) 우클릭 두 번으로 마취탄 → 일반탄으로 순환하는지, (3) 6발을 쏘면 탄창이 정확히 0이 되는지(체력도 14/200로 등급 테스트와 일치), (4) 탄창이 빈 상태에서 발사해도 체력/탄약이 변하지 않는지, (5) R을 누르면 6/6으로 재장전되는지를 확인한다.
- 확인: `godot --headless --path . --quit` 에러 없음. 이번 변경과 직접 관련된 테스트만 재실행(규칙 4 QA 지침): `animal_hunt_headless_test`(`PASS`), `animal_capture_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `grade_reward_headless_test`(`PASS`), `mouse_hunt_headless_test`(`PASS`, 신규) 모두 통과. `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다(에디터 PID 두 개는 세션 시작 전부터 사용자가 띄워둔 것). 에러 없이 진행됨.
- 남은 제약: `ammo_type`이 `"normal"`이면 여전히 `_attack()`(도끼/`tool` 슬롯 게이트)을, `"tranquilizer"`면 `_try_capture()`(마취총/`weapon` 슬롯 게이트)을 그대로 호출한다 — "좌클릭 발사=장착된 총으로 쏜다"는 서술과 "공격은 도끼 장비가 있어야 한다"는 기존 판정이 개념적으로는 다소 어긋나지만, inbox.md #4 2번이 판정 로직은 그대로 재사용하라고 명시했으므로 의도적으로 남겨둔 불일치다(입력 방식 통합이 목적이지 장비 시스템 재설계가 아님). 필요하다면 나중에 tool/weapon 슬롯을 하나의 "총" 개념으로 통합하는 것은 별도 지시로 판단할 문제다. `inbox.md` #4의 3~5번(채집 스페이스 유지 확인은 이번에 건드리지 않았으므로 이미 충족, 메인메뉴+슬롯+저장 시스템, 제작/줍기/인벤토리 제외)은 아직 미착수.
- 다음 할 일: 자동 루프는 여전히 꺼진 상태(#47 `HARNESS_STOP`)이므로 다음 실행도 수동 요청이나 launchd 재등록이 필요하다. 다음 세션은 `inbox.md` #4의 4번(메인 메뉴 + 슬롯 선택 + 저장/불러오기 시스템)을 이어받을 것을 권장한다 — 이번 세션이 끝난 지금 남은 인박스 항목 중 유일하게 손대지 않은, 그리고 가장 규모가 큰 조각이다.

---

### #50 — 2026-09-02 02:15 (수동 실행, 사용자가 하네스 사이클 1회를 직접 요청)

- 계기: `HARNESS_STOP`(#47) 이후 자동 루프는 꺼져 있었지만, 사용자가 하네스 사이클을 한 번 더 수동 실행해 달라고 요청했다. `inbox.md` #4는 4번(메인 메뉴 + 슬롯 선택 + 저장/불러오기 시스템)만 남아 "부분 처리" 상태였고, #49가 다음 세션에 이를 권장해뒀으므로 이어받았다.
- 한 일:
  - `scenes/MainMenu.tscn` + `scripts/main_menu.gd` 신설: 게임 실행 시 바로 플레이 화면(Main.tscn)으로 들어가지 않고 "시작/설정/종료" 3개 버튼이 있는 메인 메뉴를 먼저 보여준다. 설정 패널은 세부 옵션이 design.md에 명시되지 않아(범위 밖) 전체화면 토글 하나만 최소로 두었다. `project.godot`의 `run/main_scene`을 `Main.tscn`에서 `MainMenu.tscn`으로 바꿨다. 헤드리스 환경(`DisplayServer.get_name() == "headless"`)에서는 창 모드 조회/변경이 의미가 없어 건너뛰도록 방어 코드를 넣었다 — 헤드리스 테스트가 이 씬을 그대로 인스턴스화하기 때문에, 여기서 예외가 나면 테스트 자체가 깨진다.
  - `scripts/main.gd`: 지금까지 슬롯별 외형(`slot_colors`)이 프로세스(세션) 안에서만 기억되던 것을, `user://saves/slot_N.save`에 JSON으로 저장하도록 바꿨다 — inbox.md #4 4번이 명시한 "기존에 저장된 슬롯 선택 시 저장된 상태 그대로 이어서 시작"은 프로세스를 새로 켜도 유지되어야 의미가 있는데, 기존 구현은 세션이 끝나면 항상 사라졌다. 저장 대상은 외형(색)뿐 아니라 장비 등급, 인벤토리, 포획 목록까지 포함했다 — "이어서 시작"이 색만 남고 나머지 진행 상황은 초기화되면 절반짜리 저장이라고 판단했다. 슬롯 선택 시 (1) 이번 세션에 이미 고른 슬롯이면 메모리 값을 그대로 쓰고, (2) 세션 중엔 처음이지만 디스크에 저장 파일이 있으면 그걸 불러와 커스터마이징 없이 바로 적용하고, (3) 저장 파일도 없는 진짜 새 슬롯이면 기존처럼 커스터마이징으로 이어지도록 분기했다. 채집(`_on_harvested`)·포획(`_on_captured`)·장비 강화 시점마다 즉시 저장해, 중간에 게임이 꺼져도 마지막 저장 시점부터 이어질 수 있게 했다.
  - 튜토리얼은 design.md가 "처음에" 한 번만 안내한다고 명시해(캐릭터별이 아니라 계정 전체 기준) `pending_tutorial`을 슬롯과 무관한 파일(`user://saves/tutorial_seen.flag`) 존재 여부로 판단하도록 바꿨다 — 슬롯별로 저장하면 저장된 슬롯을 새로 골랐을 때 "이미 계정에서 튜토리얼을 본 적 있는데" 슬롯 데이터에 그 정보가 없어 다시 뜨는 문제가 생기기 때문이다.
  - `scenes/Main.tscn`의 `TutorialOverlay` 안내 문구가 status.md #48/#49(WASD 이동, 마우스 기반 사냥)로 조작 체계가 바뀐 뒤에도 "방향키 이동", "C: 포획" 같은 옛 설명 그대로 남아있던 것을 발견해, 실제 조작(W/A/S/D, 좌클릭 발사/우클릭 탄종류/R 재장전)에 맞게 함께 고쳤다 — 이번에 메인 메뉴~튜토리얼 흐름 전체를 손대는 김에 발견한, 사용자가 실제로 보는 화면의 잘못된 정보라 범위 안으로 판단했다.
  - 신규 헤드리스 테스트 2종을 추가했다: `tests/mainmenu_headless_test.gd`(메인 메뉴의 시작/설정/뒤로/시작 버튼 흐름과 `Main.tscn`으로의 씬 전환을 검증 — 버튼의 `pressed`/`toggled` 시그널을 직접 발생시켜 검증했다. `.tscn`의 `[connection]`으로 연결된 동일한 코드 경로를 타므로 실제 클릭과 동등하다고 판단했다), `tests/save_load_headless_test.gd`(슬롯 1을 새로 골라 커스터마이징+나무 채집을 한 뒤 `Main.tscn` 인스턴스를 완전히 없애고 새로 하나 더 만들어, 저장 파일에서 실제로 색/인벤토리가 복원되는지 검증 — 인스턴스를 새로 만드는 이유는 같은 프로세스 안에서는 메모리 상태(`slot_colors`)가 남아있어 디스크 읽기를 우회해도 우연히 통과할 수 있기 때문).
  - 기존 `tests/slot_headless_test.gd`/`customization_headless_test.gd`/`tutorial_headless_test.gd`는 모두 "슬롯 1을 처음 고른다"는 전제에 의존하는데, 새로 생긴 디스크 저장 때문에 이전 실행(다른 테스트나 수동 플레이)이 남긴 저장 파일이 있으면 그 전제가 깨진다. 세 테스트 모두 시작 전/종료 후에 `user://saves/*` 저장 파일과 튜토리얼 플래그를 지우는 `_clean_saves()`를 추가해 결정론을 지키고, 다른 실행에 영향을 남기지 않게 했다.
- 확인: `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음). 이번 변경과 직접 관련된 테스트 5종만 재실행(규칙 4 QA 지침 — 전체를 다 돌리지 않음): `mainmenu_headless_test`(`PASS`, 신규), `save_load_headless_test`(`PASS`, 신규), `slot_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`) 모두 통과. `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다(에디터 프로세스 2개는 세션 시작 전부터 사용자가 띄워둔 것). 에러 없이 진행됨.
- 남은 제약: 설정 메뉴는 전체화면 토글 하나뿐이다(볼륨 등은 design.md가 사운드를 후순위로 미뤄 범위 밖). 게임 플레이 중 메인 메뉴로 돌아가는 기능(예: ESC)은 이번에 추가하지 않았다 — inbox.md #4 4번이 "실행 시 진입" 흐름만 명시했고, 범위를 넓히면 규칙 4를 넘어선다고 판단했다. 저장은 채집/포획/강화 시점에만 이뤄지고 이동 위치 등은 저장하지 않는다(재접속 시 항상 `PLAYER_SPAWN_POSITION`에서 시작) — design.md가 세부를 명시하지 않았고, 위치 저장까지 다루면 새 결정(스폰 로직과의 상호작용)이 늘어나 범위를 넘어선다고 판단했다. `inbox.md` #4의 5번(제작/줍기/인벤토리 정리 제외)은 애초에 "하지 말 것" 지시라 그대로 미착수 상태를 유지했다.
- 다음 할 일: `inbox.md` #4(WASD 이동/마우스 사냥/채집 유지/메인메뉴+저장/제외 항목)의 5개 항목이 모두 반영됐다(1~4번 구현, 5번은 "하지 말 것" 지시라 미착수 자체가 이행). 다음 세션은 `inbox.md`에 새 지시가 없다면, 사람이 직접 플레이해 메인 메뉴~슬롯~커스터마이징~튜토리얼~게임플레이 전체 흐름이 자연스러운지 시각적으로 확인하거나(여러 세션째 미뤄지고 있음), design.md 로드맵 중 아직 다루지 않은 세부(포획한 동물의 실제 활용, 게임 중 메인 메뉴로 나가는 흐름)를 규칙 4에 따라 하나 골라 진행할 것을 권장한다.

---

### #51 — 2026-09-02 02:21 (수동 실행, 사용자가 하네스 사이클 1회를 직접 요청)

- 계기: `inbox.md`에 미처리 항목이 없어(#4까지 모두 처리 완료), `status.md` #50이 다음 후보로 남긴 두 가지(포획한 동물의 실제 활용 / 게임 중 메인 메뉴로 나가는 흐름) 중 규칙 4(기능 하나만)에 맞게 더 작고 확실한 "게임 중 메인 메뉴로 나가는 흐름"을 골랐다.
- 한 일:
  - `scripts/pause_overlay.gd` 신설 + `scenes/Main.tscn`의 `UI` 아래 `PauseOverlay`(배경 반투명 패널 + "이어하기 (ESC)"/"메인 메뉴로" 버튼) 추가. ESC를 누르면 `scripts/main.gd`의 `_unhandled_input`이(다른 오버레이가 떠 있지 않을 때만) `pause_overlay.visible = true`와 `get_tree().paused = true`를 설정해 실제 게임플레이(Player/Animal 등 물리 처리)를 멈춘다.
  - 핵심 판단: `PauseOverlay` 노드 자신만 `process_mode = ALWAYS`로 설정했다. Main(루트) 전체를 ALWAYS로 바꾸면 process_mode 상속 규칙상 자식(Player/Animal/Tree 등, Main의 자식이자 UI의 형제)까지 함께 "항상 처리"로 바뀌어 애초에 멈추지 않게 되므로, 오버레이 노드만 예외로 두는 편이 Godot 4의 표준 일시정지 메뉴 패턴과도 일치한다고 판단했다. 이 덕분에 paused 상태에서도 오버레이의 버튼 클릭과 ESC 재입력(재개)은 `pause_overlay.gd` 자신의 `_unhandled_input`을 통해 정상 동작한다.
  - "메인 메뉴로" 버튼은 `get_tree().paused = false`를 먼저 호출한 뒤 `MainMenu.tscn`으로 전환한다 — `SceneTree.paused`는 씬 전환과 무관하게 유지되는 전역 상태라, 풀지 않고 전환하면 새로 뜬 메인 메뉴가 계속 멈춘 채로 남아 버튼조차 눌리지 않는 문제를 미리 막았다.
  - `TutorialOverlay`의 조작 안내 문구에 "ESC: 일시정지(메인 메뉴로 나가기)" 한 줄을 추가해, 새로 생긴 조작을 사용자가 튜토리얼에서 바로 알 수 있게 했다(status.md #50이 이미 조작 변경 시 이 문구를 함께 갱신해온 패턴을 따름).
  - 신규 헤드리스 테스트 `tests/pause_menu_headless_test.gd` 추가: 슬롯 선택→커스터마이징→튜토리얼을 지나 실제 플레이 상태에 도달한 뒤 (1) ESC로 열림 + `SceneTree.paused == true`, (2) paused 상태에서 ESC로 재개(`pause_overlay.gd` 자신의 process_mode=ALWAYS 경로 검증), (3) "메인 메뉴로" 버튼 클릭(시그널 직접 발생) 후 `paused == false` 및 `MainMenu` 씬 전환을 확인한다.
- 확인: `godot --headless --path . --quit` 에러 없음. 이번 변경과 직접 관련된 테스트만 재실행(규칙 4 QA 지침): `pause_menu_headless_test`(`PASS`, 신규), `mainmenu_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `save_load_headless_test`(`PASS`) 모두 통과 — Main.tscn/main.gd의 `_unhandled_input`에 새 분기를 추가한 변경이라 기존 오버레이(슬롯/커스터마이징/튜토리얼) 흐름과 저장/불러오기가 깨지지 않았는지 함께 확인했다. `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다(에디터 프로세스 2개는 세션 시작 전부터 사용자가 띄워둔 것). 에러 없이 진행됨.
- 남은 제약: 저장은 여전히 채집/포획/강화 시점에만 이뤄진다 — "메인 메뉴로" 버튼을 눌러 나가는 시점에는 명시적으로 저장하지 않는다(design.md가 세부를 정하지 않았고, 마지막 채집/포획/강화 이후의 순수 이동만 사라지는 정도라 status.md #50이 이미 남긴 제약과 동일선상이라고 판단했다. 나가기 시점 저장을 새로 추가하면 저장 트리거 시점을 늘리는 별개의 결정이 되어 규칙 4를 넘어선다). Tab(슬롯 전환) 오버레이가 떠 있는 동안에는 ESC로 일시정지 메뉴를 열 수 없게 막아뒀다(의도된 것 — 슬롯 선택 중 이탈 경로가 두 개로 겹치는 것을 방지).
- 다음 할 일: `inbox.md`에 새 지시가 없다면, `status.md` #50이 남긴 나머지 후보인 "포획한 동물의 실제 활용"을 규칙 4에 따라 다음 조각으로 진행하거나, 사람이 직접 플레이해 지금까지 쌓인 메뉴/저장/일시정지 흐름 전체를 시각적으로 확인할 것을 권장한다.

---

### #52 — 2026-09-02 02:25 (사용자 요청, 자동 세션 아님)

- 계기: 사용자가 "사이클이 계속 도는 이유"를 확인해 달라고 요청함. 원인 확인: 규칙 7이 "로드맵을 최초로 다 채우면 한 번 멈춘다"는 일회성 이벤트로만 되어 있었고, 그 뒤 `inbox.md` #4가 처리된 뒤에도 세션이 `status.md`에 스스로 남긴 "다음 후보"(포획한 동물의 실제 활용, 게임 중 메인 메뉴 진입 등)를 계속 이어서 실행하는 바람에 실질적으로 다시는 멈추지 않고 있었다(#49, #50, #51은 전부 `inbox.md`가 아니라 세션이 스스로 제안한 후보를 이어받은 것).
- 조치: `CLAUDE.md` 규칙 7을 고쳤다 — 이제부터는 "`inbox.md`에 미처리 항목이 있을 때만" 자동으로 다음 작업을 진행하고, 미처리 항목이 없으면 `status.md`가 제안하는 "다음 후보"를 스스로 실행하지 않고 그 자리에서 `HARNESS_STOP`을 남기도록 명확히 했다. 즉 지금부터 자동 루프가 계속 도는 유일한 조건은 "inbox.md에 사용자가 남긴 미처리 지시가 있다"이다.
- 확인: `inbox.md`의 #1~#4 모두 "처리 완료" 상태 — 현재 미처리 항목 없음.

> [!IMPORTANT]
> HARNESS_STOP: inbox.md에 미처리 항목 없음 + 규칙 7 재정의(자체 후보 계속 실행 금지) 반영 — 자동 루프를 여기서 멈춘다.

- 다음 할 일 (자동 세션 재개 없음 — 사용자가 직접 재개해야 함): 사용자가 직접 플레이해보고 원하는 것을 `inbox.md`에 새 항목으로 남긴 뒤 `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.kdw240.testgame.harness.plist`로 데몬을 다시 켜면, 다음 세션이 그 지시만 처리하고 다시 멈춘다. `status.md` #50/#51이 남긴 "포획한 동물의 실제 활용" 등은 세션이 임의로 진행하지 않으므로, 원하면 `inbox.md`로 명시적으로 지시해야 한다.

---

### #53 — 2026-09-02 02:48 (수동 실행, 사용자가 하네스 사이클 1회를 직접 요청)

- 계기: `inbox.md` #5(미처리)를 이어받았다 — "총인데 직접 다가가서 때려야 한다"는 지적에 따라 동물 사냥 발사 판정을 근접(`player_nearby`, 반경 50 Area2D)에서 실제 사거리 기반으로 바꾸는 작업.
- 한 일:
  - 판정 주체를 `animal.gd`(각 동물이 `_process`에서 `player_nearby`를 폴링)에서 `player.gd`로 옮겼다. `player.gd`에 `FIRE_RANGE`(350px)와 `POINT_BLANK_DISTANCE`(50px, 기존 근접 반경과 동일)를 추가하고, `_physics_process`에서 `fire`가 눌리면 `_find_fire_target()`으로 "capturable" 그룹(동물) 중 사거리 안 + 조준 방향(`facing_direction`) `FIRE_ANGLE_TOLERANCE_DEG`(25도) 이내에서 가장 가까운 대상을 찾아 그 동물의 새 공개 메서드 `handle_fire(shooter)`를 직접 호출한다. `POINT_BLANK_DISTANCE`보다 가까우면 조준 방향과 무관하게 맞는다(완전히 붙어있을 때 어느 쪽을 보고 있든 맞는 게 상식적이라는 판단).
  - `facing_direction`은 마우스 커서 방향이 아니라 "현재 이동 방향"으로 정했다 — inbox #5가 "마우스 커서 방향 또는 현재 조준 방향" 둘 다 허용했는데, 이 저장소는 헤드리스 테스트로만 자동 QA를 하고 실제 마우스 위치를 흉내낼 수단이 없어(다른 입력들도 이미 이 이유로 폴링 방식을 씀, player.gd 기존 주석 참고) 마우스 기반으로 하면 자동 검증이 불가능해지기 때문이다.
  - `animal.gd`: `_attack()`/`_try_capture()`가 암묵적으로 쓰던 `player_nearby`를 명시적 `shooter` 매개변수로 바꿔 어느 플레이어가 쐈는지 `player.gd`가 골라 넘겨주도록 했다. 기존 게이트 로직(장비 유무, 등급 체크, 8% 미만 포획 조건)과 탄약 소비 순서는 전혀 바꾸지 않았다 — inbox #5가 명시적으로 "무엇을 맞힐 수 있는가"만 바꾸라고 했다. `player_nearby` 자체와 그 Area2D는 지우지 않았다(점블랭크 판정과 기존 헤드리스 테스트의 근접 확인 용도로 계속 쓰임).
  - 신규 헤드리스 테스트 `tests/animal_ranged_hunt_headless_test.gd`: 기존 테스트들은 전부 플레이어를 동물과 정확히 같은 좌표(거리 0, 점블랭크 안)에 두고 발사하므로 이번에 새로 생긴 "사거리 안 + 조준 방향이 맞아야 한다"는 조건 자체는 검증하지 못했다. 이 테스트는 `player.facing_direction`을 테스트가 직접 설정해(마우스 시뮬레이션 없이 조준 방향을 결정론적으로 통제) (1) 사거리(350) 밖 + 올바른 조준 → 빗나감, (2) 사거리 안(200px) + 반대 방향 조준 → 빗나감, (3) 사거리 안(200px) + 올바른 조준 → 명중을 확인한다.

> [!CAUTION]
> 새 테스트를 작성하는 과정에서 두 가지 버그를 발견해 QA 단계에서 고쳤다.
> 1) `Vector2.angle_to()`가 반환하는 부호 있는 각도(-180~180)를 `abs()` 없이 그대로 `> FIRE_ANGLE_TOLERANCE_DEG`와 비교해, 정반대 방향을 조준해도(부호가 -180으로 나오는 부동소수점 분기 때문에) 맞아버리는 버그가 있었다. `absf()`로 감싸서 고쳤다.
> 2) `fire`/`switch_ammo`/`reload`를 `elif` 체인으로 묶었더니, `mouse_hunt_headless_test`에서 `reload`가 전혀 호출되지 않고 탄약이 0에 머무는 회귀가 발생했다 — 원인은 헤드리스 테스트가 `fire`를 누른 뒉 `physics_frame`을 기다리지 않고 바로 `process_frame`만 기다려서, "방금 눌림" 상태가 물리 프레임에 아직 소비되지 않은 채 다음 `reload` 물리 프레임까지 남아있었고, `elif` 체인이 그 stale한 `fire` 분기를 먼저 타면서 `reload` 분기 자체를 가로챈 것이었다. 세 액션은 논리적으로도 서로 배타적일 필요가 없으므로 독립된 `if`문 세 개로 분리해 고쳤다.
> 재확인 결과: `animal_ranged_hunt_headless_test`(신규, PASS), `mouse_hunt_headless_test`(PASS)를 포함해 아래 확인 항목 전체가 정상 통과했다.
- 확인: `godot --headless --path . --quit` 에러 없음. 이번 변경과 직접 관련된 테스트만 재실행(규칙 4 QA 지침): `animal_ranged_hunt_headless_test`(`PASS`, 신규), `animal_hunt_headless_test`(`PASS`), `animal_capture_headless_test`(`PASS`), `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `grade_reward_headless_test`(`PASS`), `mouse_hunt_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`, `_attack`이 이제 `shooter`를 받아 `_start_fleeing(shooter)`로 넘기는 경로라 도주 방향 계산이 깨지지 않았는지 확인차 포함) 모두 통과. `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다.
- 남은 제약: `FIRE_RANGE`(350)/`POINT_BLANK_DISTANCE`(50)/`FIRE_ANGLE_TOLERANCE_DEG`(25도) 수치는 design.md에 명시되지 않은 밸런스 값이라 하네스가 상식적으로 정한 기본값이다 — 총기 사거리 체감이나 조준 관용도는 실제 플레이해보고 조정이 필요할 수 있다. `facing_direction`은 이동 입력 기반이라, 제자리에 멈춰 서서 이동 없이 여러 방향을 조준하는 것은 아직 불가능하다(직전에 이동한 방향을 계속 조준 방향으로 유지) — 실제 마우스 조준 UI/레티클은 범위 밖으로 남겨뒀다. 나무/물고기/식물(Tree/Fish/Plant)의 채집(`ui_accept`, 근접)은 이번 변경 대상이 아니라 그대로다.
- 다음 할 일: `inbox.md`에 새 지시가 없다면(현재 #1~#5 모두 처리 완료), CLAUDE.md 규칙 7에 따라 세션이 스스로 다음 후보를 골라 진행하지 않고 여기서 멈춘다. 다음에 참고할 후보(직접 코드로 만들지는 않음): 실제 마우스 커서 방향 조준으로 전환(레티클 UI 포함), 포획한 동물의 실제 활용, 사거리/조준 관용도 수치 밸런싱.

> [!IMPORTANT]
> HARNESS_STOP: inbox.md #5까지 모두 처리 완료 + 미처리 항목 없음 — 자동 루프를 여기서 멈춘다.

---

### #54 — 2026-09-02 03:09 (수동 실행, 사용자가 하네스 사이클 1회를 직접 요청)

- 계기: `inbox.md` #6(미처리)을 이어받았다 — 사용자가 직접 플레이해보고 "총이 제대로 작동이 안된다"고 지적. 원인은 `status.md` #53이 만든 `facing_direction`(발사 조준 기준)이 실제로는 마우스 커서 방향이 아니라 "현재 이동 방향"으로 계산되고 있었던 것 — 마우스로 동물을 조준해 클릭해도 판정은 마지막으로 걸었던 방향 기준이라 조준과 무관하게 맞거나 빗나갔다. `inbox.md` #6은 우선순위 순으로 5개 항목을 나열했고 "여러 세션에 걸쳐 순서대로 처리할 것"이라고 명시했으므로, 규칙 4(기능 하나만)에 따라 `[최우선, 버그]`로 표시된 1번과, 같은 데이터(조준 방향)를 눈으로 검증하기 위한 시각적 짝인 2번(조준선 표시)까지를 이번 세션의 "하나"로 묶어 처리했다(둘 다 `[최우선]`이고, 조준선이 없으면 1번의 수정이 실제로 마우스를 따라가는지 사람이 확인할 방법이 없어 사실상 같은 조각이라고 판단). 3~5번(인벤토리, 장비 슬롯, 핫바)은 이번에 손대지 않았다.
- 한 일:
  - `scripts/player.gd`: 조준 판정과 조준선 표시 양쪽에 쓰는 단일 값 `aim_direction`을 새로 추가했다. 매 물리 프레임 `_update_aim_direction()`에서 갱신하는데, 헤드리스 환경(`DisplayServer.get_name() == "headless"`, `main_menu.gd`가 이미 쓰던 것과 동일한 패턴)에서는 실제 마우스 좌표가 없어 기존처럼 `facing_direction`(이동 방향)으로 대체하고, 그 외(실제 창이 있는 환경)에서는 `get_global_mouse_position() - global_position`을 정규화해 실제 마우스 커서 방향을 쓴다. `_find_fire_target()`이 참조하던 `facing_direction`을 `aim_direction`으로 바꿨다 — 이제 조준 판정 자체는 마우스 기준이 된다.
  - 같은 파일에 `_draw()`를 추가해 플레이어 위치에서 `aim_direction * FIRE_RANGE` 방향으로 반투명 빨간 선을 그린다. 판정에 쓰는 값과 동일한 `aim_direction`을 그대로 그리므로 표시와 실제 판정이 항상 일치한다. authority가 아닌 원격 Player와 헤드리스 환경에서는 그리지 않는다(카메라/탄약 HUD와 동일한 이유).
  - 창 스트레치 모드(`project.godot`의 `window/stretch/mode="canvas_items"`)가 걸려있어도 `get_global_mouse_position()`은 뷰포트의 캔버스 변환을 이미 반영한 월드 좌표를 반환하므로(Godot 4 표준 동작) 별도 좌표 변환은 필요하지 않았다.
  - 조준선을 항상 보이게 할지, 특정 장비(총)를 들고 있을 때만 보이게 할지 고민했다 — design.md/inbox 어디에도 "총"이 별도 장착 슬롯으로 명시되어 있지 않고(현재는 좌클릭 발사가 곧 기본 상호작용이라 사실상 항상 "총을 들고 있는" 상태), 게이팅 조건을 새로 만들면 이번 지시(조준 정확성 버그 수정 + 시각적 확인) 범위를 넘어서는 새 결정이 되므로 authority인 로컬 플레이어에게는 항상 표시하는 쪽으로 판단했다.
  - 헤드리스 테스트는 새로 추가하지 않았다 — 이번 변경의 핵심(마우스 좌표 기반 계산)은 헤드리스 환경에서 원천적으로 검증 불가능하고(다른 마우스/스트레치 관련 로직도 이 저장소에서 자동 QA 대상이 아니었다), 헤드리스 경로(`facing_direction`으로 대체)는 기존 `animal_ranged_hunt_headless_test`/`mouse_hunt_headless_test`가 그대로 검증한다(둘 다 `player.facing_direction`을 직접 설정해 조준을 통제하는 방식이라 `aim_direction`이 그 값을 그대로 이어받는지 자연히 확인됨).
- 확인:
  - `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음).
  - 이번 변경과 직접 관련된 테스트만 재실행(규칙 4 QA 지침): `animal_ranged_hunt_headless_test`(`PASS`), `mouse_hunt_headless_test`(`PASS`) — 둘 다 조준 방향(`aim_direction`, 헤드리스에서는 `facing_direction`과 동일)을 직접 검증하는 테스트로, 이름만 바뀌었을 뿐 판정 결과가 그대로 유지됨을 확인했다.
  - `equipment_gate_headless_test`(`PASS`), `grade_headless_test`(`PASS`), `grade_reward_headless_test`(`PASS`), `animal_flee_headless_test`(`PASS`)도 함께 재확인했다 — 전부 점블랭크 거리(0)에서 발사해 각도 검사 자체를 건너뛰는 경로라 이번 변경의 영향을 받지 않아야 하며, 실제로 그대로 통과했다.

> [!CAUTION]
> QA 중 `animal_hunt_headless_test`와 `animal_capture_headless_test` 두 개가 실패(전자는 최초 실행 시 5분 넘게 멈춘 뒤 결국 FAIL, 후자는 즉시 FAIL)하는 것을 발견했다. 원인을 좁히기 위해 `git stash`로 이번 세션의 변경을 완전히 제거한 원래 코드에서 같은 두 테스트를 다시 돌려봤는데, 변경 전 코드에서도 동일하게 FAIL했다(`animal_hunt`: "1회 공격 후 체력 라벨이 기대한 값(69/100)이 아님(실제: 38/100)" — 즉 한 번의 fire 입력 사이클에서 공격이 두 번 들어감, `animal_capture`: 마취탄 발사 전에 이미 여러 발이 들어가 포획 시점에 체력이 예상과 달라짐). 즉 이번 세션이 만든 버그가 아니라, `Input.action_press`/`action_release` + `await process_frame`만으로 물리 프레임 타이밍을 흉내내는 기존 테스트 패턴 자체에 있던 사전 존재 플레이키니스(가끔 한 번의 "눌림"이 두 물리 프레임에 걸쳐 두 번 소비됨)로 판단했다. 이번 세션 범위(조준 방향 버그 수정)와 무관하고, 재현이 결정론적이지도 않아(같은 코드로 재실행하면 통과할 때도, 실패할 때도 있음) 이번 세션에서 고치지 않고 다음에 참고하도록 여기 남긴다. 다만 최초 실행에서 `animal_hunt_headless_test.gd` 프로세스(PID 56652)가 5분 넘게 멈춰 있다가 이 세션의 Bash 권한(`Bash(godot *)`만 허용, `kill`은 미허용)으로는 정리하지 못한 채 남아있을 수 있다 — 사용자가 직접 `kill`로 정리해야 할 수 있다.
- 남은 제약: 조준선은 authority인 로컬 플레이어에게 항상 표시되며, 특정 장비를 들고 있을 때만 보이게 하는 게이팅은 없다(위 판단 근거 참고). `inbox.md` #6의 3번(인벤토리 E키 9칸)/4번(장비 슬롯 7종)/5번(핫바 1~5)은 아직 미착수 — "여러 세션에 걸쳐 순서대로 처리"가 명시된 지시라 다음 세션이 이어받아야 한다. 위 CAUTION의 `animal_hunt`/`animal_capture` 테스트 플레이키니스는 미해결 상태로 남아있다(원인은 좁혔으나 고치지는 않음).
- 다음 할 일: 다음 세션은 `inbox.md` #6의 3번(인벤토리, E키, 9칸, 마인크래프트/코어키퍼 참고)부터 이어받을 것을 권장한다. 여유가 있다면 위 CAUTION에 남긴 `animal_hunt_headless_test`/`animal_capture_headless_test`의 fire 입력 이중 소비 플레이키니스 원인 조사(테스트의 `Input.action_press`/`action_release` 타이밍 문제로 추정)도 별도로 다뤄볼 만하다. `inbox.md` #6에 아직 3~5번이 남아있으므로 규칙 7에 따라 `HARNESS_STOP`을 남기지 않고 다음 세션이 계속 이어간다.

---

### #55 — 2026-09-02 03:16 (수동 실행, 사용자가 하네스 사이클 1회를 직접 요청)

- 계기: `inbox.md` #6(부분 처리 중)을 이어받았다 — status.md #54가 다음으로 권장한 3번(인벤토리, E키, 9칸, 마인크래프트/코어키퍼 참고)을 규칙 4(기능 하나만)에 따라 이번 세션의 조각으로 골랐다. 4번(장비 슬롯 7종)·5번(핫바 1~5)은 이번에 손대지 않았다 — inbox #6 자체가 "여러 세션에 걸쳐 순서대로 처리"를 명시했다.
- 한 일:
  - `scenes/Main.tscn`의 `UI` 아래 `InventoryOverlay`(반투명 배경 + "인벤토리 (E로 닫기)" 제목 + 3x3 `GridContainer`, 슬롯 9개 `Panel`+`SlotLabel`) 신설. `scripts/main.gd`의 `_unhandled_input`에 E키 분기를 추가했다 — 다른 오버레이(슬롯/커스터마이징/튜토리얼)가 열려있지 않고 일시정지 상태가 아닐 때만 E로 열리고, 열린 상태에서 E를 다시 누르면 닫힌다.
  - 핵심 판단: 인벤토리 오버레이는 `pause_overlay.gd`와 달리 `get_tree().paused`를 건드리지 않는 단순 시각 토글로 만들었다. design.md의 멀티플레이(세션 서버) 로드맵을 고려하면, 인벤토리를 열 때마다 SceneTree 전체를 멈추면 한 명이 인벤토리를 확인하는 동안 같은 세션의 다른 플레이어까지 함께 멈추게 되므로 부적절하다고 판단했다.
  - 용량 구현: 기존 `main.gd`의 `inventory: Dictionary`(자원 종류 -> 개수)는 종류 수 제한이 전혀 없었다. `INVENTORY_CAPACITY = 9`를 추가하고 `_on_harvested()`에서 "이미 갖고 있는 종류를 더 얻는 것"은 계속 허용하되, "9종을 이미 채운 상태에서 새로운 종류를 얻으려는 시도"는 거부(자원 손실, 콘솔에 안내 문구)하도록 했다. design.md/inbox 어디에도 초과분 처리(드롭, 교체 등)가 명시되지 않았고 바닥에 아이템을 버리는 시스템 자체가 아직 없어(제작/줍기와 함께 범위 밖, inbox #4 5번) 가장 단순한 기본값으로 판단했다.
  - `_update_inventory_grid()`: `inventory.keys()` 순서대로 9칸에 "이름\n개수"를 채우고 남는 칸은 "-"로 표시한다. 아이콘 리소스가 없어(범위 밖, design.md "아트 스타일") 텍스트만 표시했다 — 기존 `InventoryLabel`(항상 보이는 목록형 표시)과 별개로 유지, 서로 충돌하지 않는다.
  - `TutorialOverlay` 안내 문구에 "E: 인벤토리 (9칸)" 한 줄 추가(status.md #50/#51이 이미 조작 변경 시 이 문구를 함께 갱신해온 패턴을 따름).
  - 신규 헤드리스 테스트 `tests/inventory_headless_test.gd`: 실제 플레이 상태에서 (1) E로 열림/닫힘 + `paused`가 바뀌지 않는지, (2) `main._on_harvested()`로 얻은 자원이 그리드에 "이름\n개수"로 표시되는지, (3) 서로 다른 9종을 채운 뒤 10번째 새 종류는 거부되고(`inventory.size()`가 9를 넘지 않음) 이미 있던 종류는 계속 늘어나는지 확인한다. 실제 씬의 자원 종류가 4종뿐이라(통나무/고기/물고기/채소) 9종을 자연스럽게 모을 수 없어, `equipment_upgrade_headless_test.gd`와 동일한 방식으로 `main._on_harvested()`를 직접 호출해 상황을 흉내냈다.
- 확인:
  - `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음).
  - 이번 변경과 직접 관련된 테스트만 재실행(규칙 4 QA 지침): `inventory_headless_test`(`PASS`, 신규), `pause_menu_headless_test`(`PASS`, 같은 `_unhandled_input` 오버레이 우선순위 체인에 새 분기를 끼워넣은 변경이라 ESC 흐름이 깨지지 않았는지 확인), `mainmenu_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `customization_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`, 문구 변경 확인), `equipment_upgrade_headless_test`(`PASS`, `_on_harvested()`에 용량 체크를 추가한 변경이 기존 승급 경로를 깨지 않았는지 확인), `save_load_headless_test`(`PASS`) 모두 통과. `ps aux`로 확인한 결과 남은 godot 프로세스는 없었다.

> [!CAUTION]
> 신규 테스트 작성 중 두 가지를 실수로 잘못 짚어 QA 단계에서 고쳤다(둘 다 로직 버그가 아니라 테스트 코드 자체의 오류였다).
> 1) `SceneTree`를 상속하는 헤드리스 테스트에서 `get_tree().paused`를 썼다가 "Function get_tree() not found in base self" 파싱 에러가 났다 — `SceneTree` 자신에는 `get_tree()`가 없고(그건 `Node`의 메서드), `paused`는 `SceneTree` 자신의 프로퍼티라 `paused`로 직접 읽어야 한다(기존 `pause_menu_headless_test.gd`가 이미 이렇게 쓰고 있었는데 이번에 새로 옮겨적으며 놓쳤다). `get_tree()` 없이 `paused`로 고쳤다.
> 2) 용량이 가득 찬 뒤에도 "이미 있던 종류는 계속 늘어나야 한다"를 검증하려고 "통나무"를 재사용했는데, "통나무"는 `RESOURCE_TO_SLOT`에 매핑된 자원이라 `_try_upgrade_equipment()`가 끼어들어 5개가 쌓이는 순간 장비 승급 비용으로 자동 소비돼(기존 의도된 동작) 개수가 0으로 변해 테스트가 실패했다. 이건 테스트가 세운 시나리오가 실제 게임 로직(장비 자동 승급)과 우연히 충돌한 것이지 인벤토리 용량 로직의 버그는 아니었다 — 장비 슬롯에 매핑되지 않은 "자원1"(테스트가 앞서 만든 자원)으로 바꿔서 검증하도록 고쳤다.
> 재확인 결과: `inventory_headless_test`(PASS)를 포함해 위 확인 항목 전체가 정상 통과했다.
- 남은 제약: 인벤토리는 열려 있어도 플레이어 이동/발사를 막지 않는다(design.md/inbox가 이동 잠금을 요구하지 않았고, 새로 잠금 로직을 추가하면 규칙 4를 넘어서는 별개의 결정이 된다고 판단). 슬롯 안에는 아이콘 없이 텍스트(이름+개수)만 표시한다(아트 리소스 범위 밖). 9칸을 넘겼을 때 자원은 그냥 버려진다 — 드롭/교체 UI는 없다. `inbox.md` #6의 4번(장비 슬롯 7종)·5번(핫바 1~5)은 아직 미착수.
- 다음 할 일: 다음 세션은 `inbox.md` #6의 4번(모자/상의/하의/신발/귀걸이/반지/가방 7종 장비 슬롯)부터 이어받을 것을 권장한다. `inbox.md` #6에 아직 4~5번이 남아있으므로 규칙 7에 따라 `HARNESS_STOP`을 남기지 않고 다음 세션이 계속 이어간다.

---

### #56 — 2026-09-02 03:24 (자동 세션)

- 계기: `inbox.md` #6(부분 처리 중)을 이어받았다 — status.md #55가 다음으로 권장한 4번(모자/상의/하의/신발/귀걸이/반지/가방 7종 장비 슬롯)을 규칙 4(기능 하나만)에 따라 이번 세션의 조각으로 골랐다. 5번(핫바 1~5)은 이번에 손대지 않았다 — inbox #6 자체가 "여러 세션에 걸쳐 순서대로 처리"를 명시했다.
- 참고: 이번 세션 시작 시 `CLAUDE.md`에 이미 반영돼 있던(이 세션이 작성하지 않음) 규칙 하나를 확인했다 — `status.md`/`inbox.md` 제목 괄호 안에는 항상 정확히 "(자동 세션)"만 적고, "(수동 실행, ...)" 같은 확인 불가능한 표현은 쓰지 않는다(세션 스스로는 이 실행이 사람이 방금 시작한 것인지 루프의 다음 반복인지 구별할 방법이 없기 때문). 이번 항목부터 그 형식을 따른다.
- 한 일:
  - `scripts/player.gd`: 기존 `equipment` 딕셔너리("tool"/"weapon"/"rod"/"sickle", 상호작용에 실제로 쓰이는 "도구" 개념)와 별개로 `wearables` 딕셔너리("hat"/"top"/"bottom"/"shoes"/"earring"/"ring"/"bag", "복장/악세서리" 개념)를 추가했다. `WEARABLE_SLOTS` 상수(7개 영문 키, 순서 고정)와 `equip_wearable(slot, item_name)`/`unequip_wearable(slot)`/`get_wearable(slot)`을 뒀다. 기본값은 7슬롯 전부 빈 문자열이다 — "기본 코디 제공"은 이미 `OUTFIT_COLOR`로 그리는 하의 색으로 충족되어 있고(player.gd 기존 주석), 아직 옷/장신구를 얻는 방법(상점/제작/줍기)이 게임 안에 전혀 없어(범위 밖, inbox #4 5번) 기본으로 채울 아이템 자체가 없기 때문이다.
  - `scenes/Main.tscn`의 `InventoryOverlay`를 개편했다 — 기존에는 `InventoryPanel` 아래 `SlotGrid`(9칸)만 있었는데, 그 사이에 `Body`(HBoxContainer)를 끼워넣고 왼쪽에 `WearableColumn`(7개 Panel+Label, 모자~가방 순서)을, 오른쪽에 기존 `SlotGrid`를 나란히 배치했다. 새 키 바인딩을 만들지 않고 기존 인벤토리(E) 화면 안에 장비 슬롯을 포함시킨 이유: (1) inbox #6에 장비 슬롯을 여는 별도 키가 명시돼 있지 않았고, (2) inbox #6 3번이 이미 "마인크래프트 인벤토리를 참고"하라고 지시했는데 마인크래프트의 인벤토리 화면 자체가 그리드와 방어구 슬롯을 한 화면에 같이 보여주는 구조라 참고 지시와도 맞는다. `InventoryPanel`의 가로 폭을 320→460으로 늘려 새 칸이 들어갈 공간을 확보했다.
  - `scripts/main.gd`: `WEARABLE_SLOT_NAMES`(영문 키 -> 한글 라벨, `player.WEARABLE_SLOTS`와 순서 동일) 상수와 `_update_wearable_slots()`를 추가해 E로 인벤토리를 열 때 `_update_inventory_grid()`와 함께 호출한다. `wearable_slot_column`(`@onready`) 참조도 추가했다. `inventory_slot_grid`의 노드 경로가 씬 구조 변경으로 `.../InventoryPanel/SlotGrid`에서 `.../InventoryPanel/Body/SlotGrid`로 바뀌어 함께 수정했다.
  - 저장/불러오기(`_save_slot`/`_apply_slot_data`)에 `wearables`를 추가해, 착용 상태도 인벤토리/장비 등급과 마찬가지로 슬롯별로 영속화되게 했다.
  - 신규 헤드리스 테스트 `tests/equipment_wearable_headless_test.gd`: (1) 기본 상태에서 7슬롯이 전부 비어있고 `WearableColumn` 자식이 7개인지, (2) `equip_wearable`/`unequip_wearable`이 인벤토리 오버레이 UI에 "이름: 아이템"/"이름: -"로 즉시 반영되는지, (3) `save_load_headless_test.gd`와 동일한 절차(인스턴스를 완전히 없애고 새로 만들어 디스크에서 실제로 복원되는지 확인)로 착용 상태가 슬롯 저장/불러오기에 영속화되는지 확인한다. 아직 옷을 얻는 게임 내 방법이 없어 `equipment_upgrade_headless_test.gd`와 동일하게 `equip_wearable()`을 테스트가 직접 호출해 상황을 흉내냈다.
- 확인:
  - `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음).
  - 이번 변경과 직접 관련된 테스트만 재실행(규칙 4 QA 지침): `equipment_wearable_headless_test`(`PASS`, 신규), `inventory_headless_test`(`PASS`, `SlotGrid` 노드 경로 변경 반영 후), `save_load_headless_test`(`PASS`), `pause_menu_headless_test`(`PASS`, 같은 `_unhandled_input` 오버레이 체인을 다시 확인), `equipment_upgrade_headless_test`(`PASS`, 기존 `equipment`(도구) 강화 경로가 새 `wearables` 딕셔너리와 이름이 겹치지 않아 그대로 동작하는지 확인) 모두 통과. `ps aux`로 확인한 결과 남은 godot 프로세스는 없었다.

> [!CAUTION]
> 신규 테스트 작성 중 헤드리스 테스트에서 처음에는 실패(FAIL)가 났다 — 슬롯 1을 새로 골라 색을 정하면(코어키퍼 슬롯 흐름) 곧바로 튜토리얼 오버레이가 뜨는데, 테스트가 이를 닫지 않고 바로 E를 눌러 인벤토리를 열려고 했다. `main.gd`의 `_unhandled_input`은 튜토리얼 오버레이가 열려 있으면 어떤 키를 눌러도 그 오버레이만 닫고 다른 분기(E로 인벤토리 열기 등)는 실행하지 않으므로, "모자를 착용해도 UI에 반영되지 않음(E가 사실 튜토리얼을 닫는 데 소비됨)"으로 나타났다. `inventory_headless_test.gd`가 이미 쓰던 패턴(슬롯 선택 → 색 선택 → 스페이스로 튜토리얼 닫기)을 그대로 따라 커스터마이징 직후 스페이스바 입력을 추가해 고쳤다 — `main.gd`/`player.gd` 로직 자체의 버그는 아니었다.
> 재확인 결과: `equipment_wearable_headless_test`(PASS)를 포함해 위 확인 항목 전체가 정상 통과했다.
- 남은 제약: 7개 착용형 슬롯은 데이터 구조와 UI 표시(인벤토리 화면 안)만 갖춰졌다 — 아직 옷/장신구를 얻는 방법(상점/제작/줍기)도, 인벤토리에서 클릭/드래그로 장착하는 상호작용도 없다(범위 밖, inbox #4 5번이 제작/줍기 자체를 미룸). 캐릭터 스프라이트에 착용한 아이템이 시각적으로 반영되지도 않는다(아트 리소스 범위 밖). `inbox.md` #6의 5번(핫바 1~5)은 아직 미착수.
- 다음 할 일: 다음 세션은 `inbox.md` #6의 5번(휴대 장비 핫바, 숫자 1~5, 인벤토리 9칸과 별도 데이터 구조)부터 이어받을 것을 권장한다. `inbox.md` #6에 아직 5번이 남아있으므로 규칙 7에 따라 `HARNESS_STOP`을 남기지 않는다.

---

### #57 — 2026-09-02 03:29 (자동 세션)

- 계기: `inbox.md` #6(부분 처리 중, 5번만 남음)을 이어받았다 — status.md #56이 다음으로 권장한 5번(휴대 장비 핫바, 숫자 1~5, 인벤토리 9칸과 별도 데이터 구조)을 규칙 4(기능 하나만)에 따라 이번 세션의 조각으로 골랐다. 이 항목이 처리되면 inbox #6의 5개 항목이 모두 반영되어 `inbox.md` 전체에 미처리 항목이 남지 않는다.
- 한 일:
  - `scripts/player.gd`: `HOTBAR_SIZE`(5) 상수와 `hotbar: Array[String]`(5칸, 기본 전부 빈 문자열), `active_hotbar_index: int`(기본 0)를 추가했다. `get_hotbar_item(index)`/`set_hotbar_item(index, item_name)`/`select_hotbar_slot(index)` 세 메서드를 뒀다 — wearables(inbox #6 4번, status.md #56)와 동일한 패턴으로, 아직 인벤토리에서 핫바로 아이템을 옮기는 상호작용(드래그 등)이 게임 안에 전혀 없어(범위 밖, 줍기/제작과 함께 inbox #4 5번이 미룬 영역) 슬롯 내용물은 항상 빈 문자열로 시작하고, 이번 조각은 "숫자 1~5로 슬롯을 선택할 수 있다"는 데이터 구조 + UI만 갖춘다.
  - `scenes/Main.tscn`: `UI` 아래 `Hotbar`(HBoxContainer, 화면 하단 중앙 고정)를 신설했다 — `HotbarSlot0~4`(각 64x64 Panel + "번호\n내용물" 텍스트 Label)로 구성. `InventoryOverlay`(E로 토글)와 달리 항상 보이게 만들었다 — 마인크래프트/코어키퍼 참고 지시(inbox #6 3번에서 이미 확립)와 마찬가지로, 실제 플레이 중에도 어떤 슬롯이 선택돼 있는지 눈으로 계속 확인할 수 있어야 의미가 있는 UI라고 판단했다.
  - `scripts/main.gd`: `HOTBAR_KEYS`(KEY_1~KEY_5 -> 인덱스 0~4) 상수와 `_update_hotbar_ui()`를 추가했다. `_unhandled_input`에서 slot_overlay/customization_overlay/tutorial_overlay/inventory_overlay/pause_overlay가 모두 닫혀있을 때만(각 오버레이 분기가 이미 그 앞에서 return하므로) 숫자 키 1~5를 핫바 슬롯 선택으로 처리한다 — SLOT_KEYS/BODY_COLOR_CHOICES도 같은 숫자 키(1~4)를 쓰지만 각각 slot_overlay/customization_overlay가 열려있을 때만 반응하는 별도 분기라 실제로 겹치지 않는다. 선택된 슬롯은 `self_modulate`를 노란빛으로 바꿔 강조한다(아이콘 리소스가 없어 텍스트+색으로만 구분, 기존 인벤토리 슬롯과 동일한 제약).
  - 저장/불러오기(`_save_slot`/`_apply_slot_data`)에 `hotbar`/`active_hotbar_index`를 추가해, 핫바 내용물과 선택 상태도 슬롯별로 영속화되게 했다.
  - 신규 헤드리스 테스트 `tests/hotbar_headless_test.gd`: (1) 기본 상태에서 5슬롯이 전부 비어있고 `active_hotbar_index`가 0이며 `Hotbar` 자식이 5개인지, (2) 숫자 키(3번)를 누르면 `active_hotbar_index`가 바뀌고 선택된 슬롯의 `self_modulate`가 다른 슬롯과 구분되는지, (3) `player.set_hotbar_item()`으로 담은 아이템과 `main._on_harvested()`로 얻은 인벤토리 자원이 서로 섞이지 않는지(별도 데이터 구조 검증), (4) `equipment_wearable_headless_test.gd`와 동일한 절차(인스턴스를 완전히 없애고 새로 만들어 디스크에서 실제로 복원되는지 확인)로 핫바 내용물과 `active_hotbar_index`가 슬롯 저장/불러오기에 영속화되는지 확인한다.
- 확인:
  - `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음).
  - 이번 변경과 직접 관련된 테스트만 재실행(규칙 4 QA 지침): `hotbar_headless_test`(`PASS`, 신규), `inventory_headless_test`(`PASS`, 핫바와 인벤토리 데이터가 섞이지 않는지 교차 확인), `equipment_wearable_headless_test`(`PASS`, 같은 인벤토리 오버레이/저장 경로를 공유하는 wearables가 이번 변경으로 깨지지 않았는지 확인), `pause_menu_headless_test`(`PASS`, 같은 `_unhandled_input` 오버레이 우선순위 체인에 새 분기를 끼워넣은 변경이라 ESC 흐름이 깨지지 않았는지 확인), `save_load_headless_test`(`PASS`), `slot_headless_test`(`PASS`), `tutorial_headless_test`(`PASS`, 문구 변경 확인) 모두 통과. `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다.
- 남은 제약: 핫바 5칸은 데이터 구조와 UI 표시(항상 화면 하단)만 갖춰졌다 — 아직 인벤토리에서 핫바로 아이템을 드래그/할당하는 상호작용도, 핫바에 담긴 아이템을 실제로 "사용"하는 로직(현재 상호작용은 대상 종류별로 자동으로 tool/weapon/rod/sickle 장비를 참조하는 구조라, 핫바 선택이 실제 판정에 아직 아무 영향을 주지 않는다)도 없다. 이는 인벤토리/장비 UI와 마찬가지로 아이템을 얻는 방법(상점/제작/줍기) 자체가 게임에 없기 때문이며, 그 방법이 범위 밖으로 남아있는 한(inbox #4 5번) 핫바도 데이터+UI 이상으로 확장할 근거가 아직 없다.
- 다음 할 일: `inbox.md`의 #1~#6이 모두 처리 완료 상태다 — 현재 미처리 항목 없음. design.md 로드맵(캐릭터 이동/카메라 → 섬 기본 지형 → 채집/사냥/포획 → 등급·장비 → 튜토리얼 → 캐릭터 커스터마이징/슬롯 → 멀티플레이) 각 단계가 최소 하나의 실질적 구현 + QA 통과 상태에 도달했다고 판단된다. 규칙 7에 따라 세션이 스스로 다음 후보를 골라 진행하지 않고 여기서 멈춘다. 다음에 참고할 후보(직접 코드로 만들지는 않음): 아이템 줍기/제작(인벤토리·핫바·장비 슬롯을 실제로 채울 방법), 핫바 선택이 실제 상호작용 판정에 영향을 주도록 연결, 위 CAUTION들에 남아있던 `animal_hunt`/`animal_capture` 테스트 플레이키니스(status.md #54) 원인 조사.

> [!IMPORTANT]
> HARNESS_STOP: inbox.md #1~#6 모두 처리 완료 + 미처리 항목 없음 — 자동 루프를 여기서 멈춘다.

---

### #58 — 2026-09-02 03:32 (자동 세션)

- 계기: 하네스 사이클 1회 실행 요청을 받아 `design.md` → `status.md` → `inbox.md` 순서로 읽었다. `status.md` #57이 이미 "inbox.md #1~#6 모두 처리 완료 + 미처리 항목 없음"으로 `HARNESS_STOP`을 남긴 상태였고, `inbox.md`를 다시 전체 확인한 결과 #57 이후 사용자가 추가한 새 항목이 없다(여전히 #1~#6 전부 "처리 완료"로 표시됨).
- 한 일: 새 기능 구현은 하지 않았다. CLAUDE.md 규칙 7("inbox.md에 미처리 항목이 없으면 자동 루프를 멈춘다")에 따르면, inbox에 미처리 지시가 없는 상태에서는 세션이 스스로 "다음 후보"(status.md #57이 남긴 참고용 아이디어: 아이템 줍기/제작, 핫바-상호작용 연결, `animal_hunt`/`animal_capture` 테스트 플레이키니스 조사 등)를 골라 진행해서는 안 되므로, 그대로 따랐다 — 코드 변경 없음.
- 확인: 코드 변경이 없어 QA(godot --headless 실행 등)를 새로 돌릴 대상이 없다. `git status`로 작업 트리에 추적되지 않은 변경이 이번 세션이 만든 것 외에 없는지만 확인했다.
- 남은 제약: #57과 동일 — 아이템 줍기/제작, 핫바 선택이 실제 상호작용에 영향을 주는 연결, `animal_hunt_headless_test`/`animal_capture_headless_test`의 fire 입력 이중 소비 플레이키니스(status.md #54 CAUTION)가 여전히 미해결/미착수 상태로 남아있다.
- 다음 할 일: 사용자가 `inbox.md`에 새 지시를 남기고 하네스 데몬을 재기동해야 다음 실질적 작업이 시작된다. 그 전까지는 이번 항목과 동일한 이유로 계속 멈춰있는 것이 맞다.

> [!IMPORTANT]
> HARNESS_STOP: inbox.md에 여전히 미처리 항목 없음(#1~#6 모두 처리 완료 유지) — 자동 루프를 다시 멈춘다.

---

### #59 — 2026-09-02 03:52 (Tab 슬롯 전환 메뉴 제거, inbox #7 1번 처리)

요약: `inbox.md` #7의 3개 지시 중 우선순위 1번(게임 중 Tab 키로 슬롯 전환 메뉴가 열리는 것 제거)을 규칙 4(기능 하나만)에 따라 이번 세션의 조각으로 처리했다. 슬롯 선택은 이제 메인 메뉴(게임 시작 시점)에서만 가능하다. 이 기능 하나에 의존하던 헤드리스 테스트(`slot_headless_test.gd`)가 있어, Tab 재오픈 대신 `save_load_headless_test.gd`가 쓰는 "인스턴스를 없애고 새로 만들어 새 실행을 흉내내는" 패턴으로 다시 작성해야 했다.

- 계기: `status.md` #58이 `HARNESS_STOP`으로 멈춘 뒤, 사용자가 `inbox.md`에 새 항목 #7(2026-09-02 03:49, 3개 지시: Tab 슬롯메뉴 제거 / 상호작용 좌클릭 통일 / 커스터마이징 눈·피부색·머리카락 확장)을 남겼다. `inbox.md`에 미처리 항목이 다시 생겼으므로 규칙 7에 따라 자동 루프를 재개하고, 그중 사용자가 명시한 우선순위 1번(가장 작고 확실한 조각)을 골랐다.
- 한 일:
  - `scripts/main.gd`의 `_unhandled_input`에서 `if event.keycode == KEY_TAB: slot_overlay.visible = true` 분기(기존 315~318번 줄)를 삭제했다. 이제 `SlotOverlay`는 게임 시작 시 슬롯을 처음 고를 때(또는 커스터마이징 미완료 슬롯을 고를 때)만 보이고, 실제 플레이 상태에서는 어떤 키로도 다시 열리지 않는다.
  - 관련 주석 두 곳을 갱신: `_unhandled_input` 위쪽 설명 주석("게임 중에도 Tab 키로 언제든 슬롯 오버레이를 다시 열어 슬롯을 바꿀 수 있다" → "슬롯 선택은 게임 시작(메인 메뉴) 시점에만 하며, 게임 플레이 중에는 슬롯을 바꾸는 기능이 없다"), `scenes/Main.tscn`의 `SlotLabel` 안내 문구에서 "(게임 중에는 Tab 키로 언제든 슬롯을 바꿀 수 있습니다)" 문장 삭제.
  - `tests/slot_headless_test.gd`를 전면 재작성했다: 기존 테스트는 튜토리얼을 닫은 뒤 `KEY_TAB`으로 슬롯 오버레이를 다시 열어 슬롯 2 선택 → 슬롯 1로 복귀 흐름을 같은 프로세스 안에서 검증했는데, 이 경로 자체가 없어졌다. `save_load_headless_test.gd`가 이미 쓰고 있던 패턴(Main.tscn 인스턴스를 `queue_free()`로 완전히 없앤 뒤 새 인스턴스를 만들어 "새로 실행한 상황"을 흉내내는 방식)을 그대로 가져와, 3개의 별도 Main 인스턴스(1: 슬롯1 최초 선택+커스터마이징+튜토리얼, 2: 슬롯2 최초 선택+커스터마이징, 튜토리얼 재노출 안 됨 확인, 3: 슬롯1 재선택 시 커스터마이징 없이 저장된 색 즉시 적용 확인)로 나눠 같은 시나리오를 검증하도록 바꿨다.
- 확인:
  - `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음).
  - 이번 변경과 직접 관련된 테스트만 재실행(규칙 4 QA 지침): `slot_headless_test`(재작성 후 `PASS`), `pause_menu_headless_test`(`PASS` — 같은 `_unhandled_input` 오버레이 우선순위 체인에서 분기 하나를 제거한 변경이라 ESC 흐름이 깨지지 않았는지 확인), `save_load_headless_test`(`PASS` — 슬롯 저장/복원 자체가 Tab 제거로 영향받지 않는지 확인). `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다(편집기로 열려있던 기존 프로세스 1개는 이번 세션 시작 전부터 떠 있던 것으로 무관함).
- 남은 제약: `inbox.md` #7의 2번(상호작용을 전부 마우스 좌클릭으로 통일 — Tree/Plant/Fish의 `ui_accept`를 `fire`로 변경)과 3번(커스터마이징을 눈/피부색/머리카락 종류로 확장)은 아직 미착수 상태다. status.md #57/#58이 남긴 "아이템 줍기/제작", "핫바-상호작용 연결", "`animal_hunt`/`animal_capture` fire 입력 이중 소비 플레이키니스(status.md #54 CAUTION)"도 여전히 미해결이다.
- 다음 할 일: 다음 세션은 `inbox.md` #7의 2번(상호작용 좌클릭 통일)을 이어서 처리한다 — `scripts/tree.gd`/`scripts/plant.gd`/`scripts/fish.gd`의 `Input.is_action_just_pressed("ui_accept")`를 `fire` 액션으로 바꾸되 `player_nearby` 근접 판정은 유지하는 방향(inbox #7 2번에 이미 사용자가 제안한 방향)으로 진행하면 된다. 그 다음 3번(커스터마이징 확장)까지 처리되면 `inbox.md` #7이 모두 처리 완료된다.

---

### #60 — 2026-09-02 03:57 (상호작용 좌클릭 통일, inbox #7 2번 처리)

요약: `inbox.md` #7의 남은 2개 지시 중 2번(나무/식물/물고기 상호작용을 `ui_accept`에서 좌클릭(`fire`)으로 통일)을 규칙 4(기능 하나만)에 따라 이번 세션의 조각으로 처리했다. 사용자가 제안한 방향(근접 판정은 유지, 트리거 키만 변경) 그대로 반영했다.

- 계기: `status.md` #59가 "다음 세션은 inbox #7 2번을 이어서 처리한다"고 명시적으로 남겼고, `inbox.md` #7이 여전히 부분 처리 상태(1번만 완료)였다.
- 한 일:
  - `scripts/tree.gd`/`scripts/plant.gd`/`scripts/fish.gd`의 `_process()`에서 `Input.is_action_just_pressed("ui_accept")`를 `Input.is_action_just_pressed("fire")`로 바꿨다. `player_nearby`(Area2D 근접) 판정 자체는 손대지 않았다 — 동물 사냥처럼 `player.gd`의 사거리/조준각 판정(`FIRE_RANGE`)을 새로 붙이지 않은 이유는, inbox #7 2번이 "나무/식물/물고기는 근접 도구라 총처럼 긴 사거리일 필요는 없다"고 명시적으로 판단해뒀기 때문이다 — 트리거 키(무엇을 누르면 되는가)만 통일하고, "무엇을 상호작용할 수 있는가"의 판정 방식은 대상 종류별로 다르게 유지했다.
  - `tree.gd` 상단 주석을 갱신해 이번 변경의 근거(inbox #7 2번, 동물 사냥과 트리거 키를 통일하되 판정은 근접 유지)를 남기고, `plant.gd`/`fish.gd`에는 tree.gd를 참고하라는 짧은 주석만 남겨 중복 설명을 피했다.
  - 이 트리거를 직접 사용하던 7개 헤드리스 테스트(`tree_harvest_headless_test.gd`, `plant_harvest_headless_test.gd`, `fish_harvest_headless_test.gd`, `grade_headless_test.gd`, `grade_reward_headless_test.gd`, `equipment_gate_headless_test.gd`, `save_load_headless_test.gd`)의 `Input.action_press/release("ui_accept")` 호출과 관련 주석/에러 메시지를 전부 `"fire"` 기준으로 갱신했다. (`animal_hunt_headless_test.gd` 등 동물 관련 테스트는 이미 `fire`를 쓰고 있어 손대지 않았다.)
- 확인:
  - `godot --headless --path . --quit` 에러 없음(파싱/런타임 에러 없음).
  - 이번 변경과 직접 관련된 테스트 7개를 개별 실행(규칙 4 QA 지침 — Bash 도구가 셸 변수 치환이 들어간 for 루프 명령을 거부해 부득이 파일별로 하나씩 실행함): `tree_harvest_headless_test`(PASS), `plant_harvest_headless_test`(PASS), `fish_harvest_headless_test`(PASS), `equipment_gate_headless_test`(PASS), `grade_headless_test`(PASS), `grade_reward_headless_test`(PASS), `save_load_headless_test`(PASS) 모두 통과. `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다(에디터로 이미 열려있던 기존 프로세스 2개는 세션 시작 전부터 떠 있던 것으로 무관함).
- 남은 제약: `inbox.md` #7의 3번(캐릭터 커스터마이징을 눈/피부색/머리카락 종류로 확장)이 아직 미착수다. status.md #57/#58이 남긴 "아이템 줍기/제작", "핫바-상호작용 연결", "`animal_hunt`/`animal_capture` fire 입력 이중 소비 플레이키니스(status.md #54 CAUTION)"도 여전히 미해결이다.
- 다음 할 일: 다음 세션은 `inbox.md` #7의 3번(커스터마이징을 눈/피부색/머리카락 종류로 확장, 저장/불러오기에도 슬롯별로 반영)을 이어받는다. 이 항목까지 처리되면 `inbox.md` #7이 모두 처리 완료되어, 규칙 7에 따라 다음 세션이 `HARNESS_STOP`을 남기고 멈출 조건이 된다(단, 그 전에 사용자가 새 지시를 추가하면 그것이 우선).

---

### #61 — 2026-09-02 04:05 (커스터마이징 피부색/눈색/머리종류 3단계 확장, inbox #7 3번 처리)

요약: `inbox.md` #7의 남은 3번(커스터마이징을 눈/피부색/머리카락 종류로 확장)을 처리했다. `player.gd`의 단일 `body_color`를 `skin_color`/`eye_color`/`hair_type` 셋으로 나누고, `main.gd`의 커스터마이징 오버레이를 3단계 순차 선택으로 바꿨다. 이 항목으로 `inbox.md` #7 전체(1~3번)와 design.md 로드맵이 다시 "완료" 상태가 되어, 규칙 7에 따라 이번 세션에서 `HARNESS_STOP`을 남긴다.

- 계기: `status.md` #60이 다음 세션은 `inbox.md` #7 3번을 이어받으라고 명시했다.
- 한 일:
  - `scripts/player.gd`: `body_color`/`DEFAULT_BODY_COLOR`를 `skin_color`/`eye_color`/`hair_type`(문자열, "short"/"mohawk"/"bald") 세 변수로 분리했다. `HAIR_STYLES`(종류->색+그릴 x범위) 상수로 머리를, `EYE_LEFT_X`/`EYE_RIGHT_X`/`EYE_ROWS`로 눈 도트를 그린다. 그리기 순서는 피부 전체 채우기 -> 머리(상단 밴드) -> 눈(좌우 도트) -> 하의(기존 OUTFIT_COLOR) — 머리/눈의 x범위를 (0,0)/(0,31) 코너 밖으로 잡아 기존 `outfit_headless_test`가 검사하던 상의/하의 코너 픽셀 구분이 그대로 유지되게 했다. `set_body_color()` 대신 `set_appearance(skin, eye, hair)`로 통합했다.
  - `scripts/main.gd`: `BODY_COLOR_CHOICES` 대신 `SKIN_COLORS`/`EYE_COLORS`/`HAIR_TYPES` 배열과 `CUSTOMIZATION_KEYS`(1~4)를 인덱스로 대응시켜, 스와치 색과 키 매핑이 한 배열에서만 나오게 했다(예전에 겪었던 "키 Dictionary와 스와치 노드 색이 따로 하드코딩되어 어긋날 뻔한" 문제 재발 방지). `customization_step`(0=피부, 1=눈, 2=머리)을 두고 `_unhandled_input`의 `customization_overlay` 분기를 3단계 순차 처리로 바꿨다 — 각 단계 선택 즉시 플레이어에 미리보기가 반영되고, 마지막 단계(머리)까지 고르면 `slot_appearance[current_slot]`(옛 `slot_colors`를 Dictionary 구조로 확장)에 저장하고 오버레이를 닫는다. 스와치 4개(`Swatch1~4`)는 `_update_customization_overlay()`가 매 단계 색/표시 여부를 다시 칠한다(머리 단계는 선택지가 2개뿐이라 나머지는 숨김).
  - `_save_slot`/`_apply_slot_data`: 저장 데이터의 `color` 필드를 `skin`/`eye`/`hair` 세 필드로 바꿨다.
  - 영향받은 9개 헤드리스 테스트(`customization_headless_test`, `slot_headless_test`, `save_load_headless_test`, `outfit_headless_test`, `tutorial_headless_test`, `pause_menu_headless_test`, `inventory_headless_test`, `equipment_wearable_headless_test`, `hotbar_headless_test`)를 갱신했다 — 대부분 "슬롯 선택 -> 색 1회 선택 -> 튜토리얼 닫기"였던 부트스트랩 시퀀스를 "슬롯 선택 -> 3단계 선택 -> 튜토리얼 닫기"로 늘리고, `body_color`/`set_body_color` 참조를 `skin_color`/`set_appearance`로 바꿨다.
- 확인:
  - `godot --headless --path . --quit` 에러 없음.
  - 영향받은 9개 테스트 전부 개별 실행해 `PASS` 확인: `customization_headless_test`, `slot_headless_test`, `save_load_headless_test`, `outfit_headless_test`, `pause_menu_headless_test`, `tutorial_headless_test`, `inventory_headless_test`, `equipment_wearable_headless_test`, `hotbar_headless_test`. `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다(에디터로 이미 열려있던 기존 프로세스 2개는 세션 시작 전부터 떠 있던 것으로 무관함).

> [!CAUTION]
> 처음 `pause_menu_headless_test`/`tutorial_headless_test`/`inventory_headless_test`/`equipment_wearable_headless_test`/`hotbar_headless_test`를 돌렸을 때 FAIL이 났다 — 원인은 코드 버그가 아니라, 이 테스트들이 "슬롯 선택 후 색 1번만 누르면 커스터마이징이 끝난다"는 옛 1단계 전제로 부트스트랩 시퀀스를 짜뒀는데, 이번 세션에서 3단계로 늘어나 1번만 눌러서는 커스터마이징 오버레이가 계속 열려있었기 때문이다. 각 테스트의 부트스트랩 키 입력을 3회로 늘려 재확인했고, 전체 `PASS`로 재확인했다.
- 남은 제약: 머리 종류는 색상 선택 없이 종류(모양+고정색)만 고르는 최소 구현이다(2D 도트 스타일 제약, design.md 범위 밖 판단). 아트 리소스가 없어 여전히 절차적 사각형 텍스처다. status.md #57/#58이 남긴 "아이템 줍기/제작", "핫바-상호작용 연결", `animal_hunt`/`animal_capture` fire 입력 이중 소비 플레이키니스(status.md #54 CAUTION)도 여전히 미해결이다.
- 다음 할 일: `inbox.md`의 #1~#7이 모두 처리 완료 상태다 — 현재 미처리 항목 없음. design.md 로드맵 각 단계가 최소 하나의 실질적 구현 + QA 통과 상태에 도달했다고 판단된다. 규칙 7에 따라 세션이 스스로 다음 후보를 골라 진행하지 않고 여기서 멈춘다. 다음에 참고할 후보(직접 코드로 만들지는 않음): 아이템 줍기/제작, 핫바-상호작용 연결, `animal_hunt`/`animal_capture` 테스트 플레이키니스 조사, 머리 종류에 색상 선택 추가.

> [!IMPORTANT]
> HARNESS_STOP: inbox.md #1~#7 모두 처리 완료 + 미처리 항목 없음 — 자동 루프를 여기서 멈춘다.

---

### #62 — 2026-09-02 04:12 (아트 스타일 가이드 문서 작성, inbox #8 1번 처리)

요약: `#61`이 `HARNESS_STOP`을 남긴 뒤 사용자가 `inbox.md` #8(Python/Pillow 기반 도트 스프라이트 생성 파이프라인, 5단계 지시)을 새로 남겨 자동 루프가 재개됐다. 5단계 중 규칙 4(기능 하나만)에 따라 1번(아트 스타일 가이드 확립 및 문서화)만 이번 세션에서 처리했다 — `assets/ART_STYLE.md`를 새로 만들어 시점/캔버스 규칙/색상 팔레트(3톤 명암 공식 + 기존 코드 대표색 앵커 표)/외곽선/광원 방향/애니메이션 규칙/파일 구성 규칙을 정의했다.

- 계기: `inbox.md` #8(2026-09-02 04:09)이 스프라이트 생성 파이프라인을 5단계 우선순위로 지시했고, 그중 1번이 "본격적으로 스프라이트를 만들기 전에 스타일 가이드부터 문서로 확립"할 것을 명시했다. `inbox.md` #7이 이미 모두 처리 완료(`#61`)라 이 항목이 이번 세션이 이어받을 유일한 미처리 지시였다.
- 한 일:
  - `assets/ART_STYLE.md` 신설: 코드베이스를 먼저 조사해(`player.gd`/`animal.gd`/`tree.gd`/`plant.gd`/`fish.gd`/`terrain.gd`의 실제 `Image.create()` 크기·`Color()` 값) 지금까지 절차적으로 그려온 스프라이트들의 관례(탑다운 시점, 플레이어 32×32 기준 스케일, 외곽선 없음)를 그대로 문서의 기준값으로 삼았다 — 완전히 새로운 스타일을 임의로 정하면 기존 절차적 사각형들과 새 도트 그림이 한 화면에서 서로 다른 규칙을 따르게 되기 때문이다.
  - 색상 팔레트는 "기본색 1 + 그림자색 1(명도 −20%, 채도 +5%) + 밝은색 1(명도 +15%)"의 3톤 공식으로 정의했다 — 다음 세션(inbox #8 2번, Pillow 생성 도구)이 `colorsys` 모듈로 기계적으로 계산할 수 있는 형태로 미리 맞춰뒀다.
  - 코드 조사 중 `plant.gd`가 28×28 캔버스를 쓰고 있어 이 가이드의 "8의 배수" 규칙과 어긋난다는 걸 발견했다 — 지금 코드를 고치는 건 이번 세션 범위(문서 작성)를 벗어나므로, 문서에 그 사실과 "실제 도트 그림으로 교체할 때 8의 배수로 맞춘다"는 메모만 남겨뒀다.
  - 캔버스/광원/애니메이션 규칙에서 아직 결정할 수 없는 세부(팔레트 색상 수 상한 등)는 "아직 정해지지 않음" 섹션으로 명시해, 실제 첫 스프라이트(플레이어, inbox #8 5번)를 만들며 구체화하도록 남겨뒀다.
- 확인: `godot --headless --path . --quit` 에러 없음(코드 변경이 전혀 없어 문서 추가만으로는 애초에 영향이 없지만, 규칙 4의 기본 quit 체크는 그대로 수행). `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다(에디터로 이미 열려있던 기존 프로세스 1개는 세션 시작 전부터 떠 있던 것으로 무관함).
- 남은 제약: `inbox.md` #8의 2~5번(Pillow 생성 도구, 후보 10장 생성→비교 그리드→Read로 시각 판단하는 절차, 애니메이션 자연스러움 확인 루프, 플레이어 캐릭터 첫 적용)이 아직 미착수다. 실제 도트 그림은 여전히 하나도 없고, 모든 스프라이트는 절차적 단색/그라디언트 없는 사각형이다. status.md #57/#58/#61이 남긴 "아이템 줍기/제작", "핫바-상호작용 연결", `animal_hunt`/`animal_capture` fire 입력 이중 소비 플레이키니스(status.md #54 CAUTION), 머리 종류 색상 선택 부재도 여전히 미해결이다.
- 다음 할 일: 다음 세션은 `inbox.md` #8의 2번(Python(Pillow) 기반 스프라이트 생성 스크립트, 한 대상당 후보 10장 생성 가능하도록)을 이어받는다. 이 문서(`assets/ART_STYLE.md`)의 3톤 색상 공식과 캔버스 크기 규칙을 그대로 구현에 반영할 것. 생성 도구가 만드는 후보 산출물 경로는 저장소에 커밋하지 않도록 `.gitignore`에 추가하는 것도 이번에 함께 처리하면 된다(`ART_STYLE.md`의 "파일 구성 규칙" 참고). `inbox.md` #8은 아직 부분 처리 상태이므로 규칙 7의 `HARNESS_STOP` 조건(미처리 항목 없음)에 해당하지 않는다 — 이번 세션은 멈추지 않고 정상 종료한다.

---

### #63 — 2026-09-02 04:17 (Pillow 스프라이트 후보 생성 도구 추가, inbox #8 2번 처리)

요약: `inbox.md` #8의 2번(Python(Pillow) 기반 스프라이트 생성 스크립트)을 처리했다. `tools/sprite_gen.py`를 새로 만들어 `assets/ART_STYLE.md`의 3톤 색상 공식·좌상단 45도 광원·하드 엣지 규칙을 코드로 구현하고, 첫 target(`player_body_base`, 32x32)으로 실제 10장을 생성해 6배 확대 스트립을 Read 도구로 직접 확인했다 — 계획대로 하드 엣지 3톤 명암과 비례 변주가 눈으로 보기에도 잘 나타났다.

- 계기: `status.md` #62가 다음 세션은 `inbox.md` #8의 2번을 이어받으라고 명시했다. `inbox.md` #8은 5단계 지시 중 1번(스타일 가이드 문서화)만 처리된 상태였다.
- 한 일:
  - `tools/sprite_gen.py`: 재사용 가능한 생성 도구를 만들었다.
    - `three_tone(base_rgb)`: `ART_STYLE.md`가 정의한 HSV 3톤 공식(그림자=V−20%/S+5%, 밝은색=V+15%)을 `colorsys`로 그대로 구현.
    - `_shade_for_position(dx, dy)`: 좌상단 45도 광원 기준으로 그라디언트 없이 계단식(하드 엣지)으로 highlight/base/shadow 세 구간만 나누는 방식 — bbox 내 상대좌표의 `((1-dx)+dy)/2` 값으로 세 구간을 구분해, Pillow의 보간(리사이즈 시 `Image.NEAREST`만 쓰는 것과 별개로) 없이 순수 픽셀 단위로 하드 엣지를 만든다.
    - `TARGETS` 딕셔너리에 target 이름 -> {캔버스 크기, 그리기 함수}를 등록하는 구조로 만들어, 다음 세션들이 동물/나무/아이템 등 새 target을 함수 하나 추가하는 것만으로 확장할 수 있게 했다.
    - 첫 target `player_body_base`(32x32, `ART_STYLE.md` 권장 캔버스 그대로)를 등록했다 — 머리 크기 비율/몸통 너비 비율/몸통 시작 높이를 후보마다 `random.Random(seed)`로 조금씩 변주해 "색상/비례/디테일을 조금씩 다르게" 요구사항을 충족시켰다. 색상 자체는 `ART_STYLE.md`의 피부 앵커색((0.2, 0.6, 1.0))을 그대로 썼다(임의 변경 금지 원칙).
    - CLI(`--target`/`--count`(기본 10)/`--out`/`--seed`/`--list`)와 `generate()`가 후보 PNG + `manifest.json`(다음 세션이 어떤 후보가 몇 번 인덱스인지 추적할 수 있도록)을 `tools/sprite_candidates/<target>/`에 저장한다.
  - `.gitignore`에 `tools/sprite_candidates/`를 추가했다 — `ART_STYLE.md`가 "후보 비교용 산출물은 최종 채택본이 아니므로 커밋하지 않는다"고 명시했기 때문.
  - 이번 세션은 생성 도구 자체(#8 2번)만 만들었고, 비교 그리드 합성 + Read로 선택하는 표준 절차(#8 3번), 애니메이션 프레임 확인 루프(#8 4번), 실제 플레이어 캐릭터 적용(#8 5번)은 규칙 4(기능 하나만)에 따라 손대지 않았다. 다만 생성 결과가 실제로 규칙(하드 엣지/광원/비례 변주)대로 나오는지 확인하기 위해 임시로(커밋 대상 아님, `/tmp`) 10장을 가로로 이어붙인 6배 확대 스트립을 만들어 Read 도구로 직접 봤다 — 파란 물방울 형태의 몸체가 좌상단은 밝고 우하단은 어두운 하드 엣지 3톤으로 잘 나뉘어 있었고, 10장 사이에 머리/몸통 비례가 미세하게 달랐다.
- 확인:
  - `python3 tools/sprite_gen.py --list` / `--target player_body_base --count 10` 정상 동작, `manifest.json` 포함 11개 파일 생성 확인.
  - `python3 -c "from PIL import Image; ..."`로 생성된 PNG가 32x32 RGBA인지 확인.
  - `git check-ignore -v tools/sprite_candidates/player_body_base/player_body_base_00.png`로 `.gitignore` 규칙이 실제로 해당 경로를 잡아내는지 확인.
  - `godot --headless --path . --quit` 에러 없음(GDScript 변경 없음, 규칙 4의 기본 체크로 수행). `ps aux`로 확인한 결과 이번 세션이 새로 띄운 채 남은 godot 프로세스는 없었다(에디터로 이미 열려있던 기존 프로세스 1개는 세션 시작 전부터 떠 있던 것으로 무관함).
- 남은 제약: `inbox.md` #8의 3~5번(비교 그리드+Read 선택 표준 절차, 애니메이션 확인 루프, 플레이어 실제 적용)이 아직 미착수 — 지금 생성된 `player_body_base` 후보들은 어디까지나 도구 검증용이며 아직 게임에 적용되지 않았고 저장소에도 없다(gitignore). `TARGETS`에는 target이 하나뿐이라 동물/나무/아이템 등은 아직 생성 불가능하다. status.md #57/#58/#61이 남긴 "아이템 줍기/제작", "핫바-상호작용 연결", `animal_hunt`/`animal_capture` fire 입력 이중 소비 플레이키니스(status.md #54 CAUTION), 머리 종류 색상 선택 부재도 여전히 미해결이다.
- 다음 할 일: 다음 세션은 `inbox.md` #8의 3번(생성 → 비교 그리드 합성 → Read 도구로 시각 비교 → 선택, 근거를 `status.md`에 기록)을 이어받는다. `tools/sprite_gen.py`의 `generate()`가 반환하는 파일 목록을 그대로 활용해 그리드 합성 함수를 추가하는 방향이 자연스러워 보인다(이번 세션이 임시로 만든 "가로 스트립 이어붙이기" 코드가 참고가 될 것). `inbox.md` #8은 아직 부분 처리 상태이므로 규칙 7의 `HARNESS_STOP` 조건에 해당하지 않는다 — 이번 세션은 멈추지 않고 정상 종료한다.
