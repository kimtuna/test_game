extends SceneTree

# 헤드리스 환경에서 inbox.md #5(사냥 판정을 근접에서 실제 사거리 기반으로
# 변경)를 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/animal_ranged_hunt_headless_test.gd
#
# 기존 animal_hunt/animal_capture 등은 player를 animal과 정확히 같은 위치에
# 두므로(거리 0, player.gd의 POINT_BLANK_DISTANCE 안) 이번 변경으로 새로
# 생긴 "사거리 안에서 조준 방향이 맞아야 맞는다"는 조건 자체는 검증하지
# 못한다. 이 테스트는 player.gd의 facing_direction을 직접 설정해(마우스
# 시뮬레이션 없이도 조준 방향을 결정론적으로 통제하기 위함 — player.gd의
# facing_direction 관련 주석 참고) 세 가지를 확인한다:
# 1) 사거리 안(200px) + 올바른 조준 방향 -> 명중
# 2) 사거리 안(200px) + 반대 방향 조준 -> 빗나감(체력 불변)
# 3) 사거리 밖(400px) + 올바른 조준 방향 -> 빗나감(체력 불변)

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var animal: Area2D = main.get_node("Animal")
	var health_label: Label = animal.get_node("HealthLabel")

	var ok := true

	# --- 3) 사거리 밖(400px)에서는 조준이 정확해도 맞지 않아야 한다 ---
	player.global_position = animal.global_position + Vector2(-400, 0)
	player.facing_direction = Vector2.RIGHT
	for i in range(5):
		await physics_frame
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame
	if health_label.text != "100/100":
		push_error("FAIL: 사거리(350) 밖인데도 명중해 체력이 감소함 (실제: %s)" % health_label.text)
		ok = false

	# --- 2) 사거리 안(200px)이라도 반대 방향을 조준하면 맞지 않아야 한다 ---
	player.global_position = animal.global_position + Vector2(-200, 0)
	player.facing_direction = Vector2.LEFT
	for i in range(5):
		await physics_frame
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame
	if health_label.text != "100/100":
		push_error("FAIL: 조준 방향이 반대인데도 명중해 체력이 감소함 (실제: %s)" % health_label.text)
		ok = false

	# --- 1) 사거리 안(200px) + 올바른 조준 방향 -> 명중해야 한다 ---
	player.global_position = animal.global_position + Vector2(-200, 0)
	player.facing_direction = Vector2.RIGHT
	for i in range(5):
		await physics_frame
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame
	if health_label.text != "69/100":
		push_error("FAIL: 사거리 안 + 올바른 조준인데도 명중하지 않음 (실제: %s)" % health_label.text)
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_RANGED_HUNT_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_ANIMAL_RANGED_HUNT_TEST: FAIL")
		quit(1)
