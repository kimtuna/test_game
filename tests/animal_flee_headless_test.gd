extends SceneTree

# 헤드리스 환경에서 동물의 피격 도주(design.md 도주 트리거 중 "피격당했을 때")를
# 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/animal_flee_headless_test.gd
# Player를 Animal 왼쪽에 두고 한 번 공격한 뒤, 동물이 (1) 즉시 is_fleeing 상태가
# 되고 (2) 플레이어 반대 방향(오른쪽)으로 실제 위치가 이동하며 (3) 일정 시간 뒤
# 도주가 끝나 is_fleeing이 다시 false로 돌아오는지 확인한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var animal: Area2D = main.get_node("Animal")

	var ok := true

	# Player를 동물 왼쪽에 붙여 상호작용 범위에 들어가게 한다.
	player.global_position = animal.global_position + Vector2(-40, 0)
	for i in range(5):
		await physics_frame

	if animal.player_nearby == null:
		push_error("FAIL: Player가 Animal의 상호작용 범위에 들어갔는데도 player_nearby가 설정되지 않음")
		ok = false

	var position_before_attack := animal.global_position

	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame

	if not animal.is_fleeing:
		push_error("FAIL: 공격당한 직후에도 동물이 도주 상태(is_fleeing)가 되지 않음")
		ok = false

	# 도주 방향은 플레이어(왼쪽)의 반대, 즉 오른쪽(+x)이어야 한다.
	if animal.flee_direction.x <= 0.0:
		push_error("FAIL: 도주 방향이 플레이어 반대쪽(+x)이 아님 (flee_direction=%s)" % animal.flee_direction)
		ok = false

	# 도주가 끝날 때까지 기다린다.
	var wait_frames := 0
	while animal.is_fleeing and wait_frames < 120:
		await physics_frame
		wait_frames += 1

	if animal.is_fleeing:
		push_error("FAIL: 일정 시간이 지나도 도주가 끝나지 않음 (wait_frames=%d)" % wait_frames)
		ok = false

	var moved_distance := animal.global_position.distance_to(position_before_attack)
	if moved_distance < 20.0:
		push_error("FAIL: 도주 후에도 동물이 거의 이동하지 않음 (moved_distance=%.1f)" % moved_distance)
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_FLEE_TEST: PASS (moved_distance=%.1f)" % moved_distance)
		quit(0)
	else:
		print("HEADLESS_ANIMAL_FLEE_TEST: FAIL")
		quit(1)
