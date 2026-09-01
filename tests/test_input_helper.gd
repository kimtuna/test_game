extends RefCounted

# 헤드리스 테스트에서 fire 같은 액션 클릭(누르고 뗌)을 결정적으로 흉내낸다.
#
# 근본 원인(inbox.md #14): `Input.action_press()` 직후 `await process_frame`(idle 프레임)로
# 기다리다가 release도 `await process_frame`으로 기다리면, 그 사이 실제 물리 스텝
# (`_physics_process`)이 0번 또는 2번 도는 경우가 생긴다 — 물리 프레임 카운터와 idle
# 프레임 카운터가 (앞선 `await physics_frame` 체이싱 루프 등으로) 어긋나 있으면, 엔진이
# 한 idle 이터레이션 안에서 밀린 물리 스텝을 2번 몰아서 처리할 수 있기 때문이다. 이때
# `is_action_just_pressed("fire")`가 그 2번의 물리 스텝 모두에서 참으로 평가되어 입력이
# 두 번 소비된다(실제로 診断 스크립트로 재현: 첫 클릭 한 번에 체력이 69가 아니라 38로
# 두 번 깎임). idle 프레임을 아예 섞지 않고 물리 프레임(`physics_frame`)만으로 press/release를
# 감싸면 이 어긋남 자체가 발생하지 않는다(재현 스크립트로 200회 반복 시 process_frame만
# 썼을 때도 드물게 프레임이 밀렸으나, 게임 로직은 전부 `_physics_process`에서 동작하므로
# physics_frame 기준으로 통일하면 관찰/소비 시점이 항상 정확히 일치한다).
static func simulate_click(tree: SceneTree, action: String) -> void:
	Input.action_press(action)
	await tree.physics_frame
	Input.action_release(action)
	await tree.physics_frame
