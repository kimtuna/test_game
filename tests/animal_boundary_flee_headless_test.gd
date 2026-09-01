extends SceneTree

# inbox.md #13 문제 2 회귀 테스트: 동물이 도주 중 섬 경계에 닿았을 때
# 제자리에 얼어붙지 않고(flee_direction이 반사되어) 계속 움직이는지 확인한다.
# 실행: godot --headless --path . --script res://tests/animal_boundary_flee_headless_test.gd
#
# 이전 버그: _physics_process()가 이동 후 위치만 clamp하고 flee_direction은
# 그대로 바깥쪽을 향해 남겨둬서, 경계에 닿으면 매 프레임 같은 좌표로 다시
# clamp되어 사실상 정지했다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var animal: Area2D = main.get_node("Animal")
	var terrain: Node = main.get_node("Terrain")
	var bounds: Rect2 = terrain.get_island_bounds()

	var ok := true

	# 동물을 섬 오른쪽 경계에 붙이고, 바다 쪽(오른쪽)으로 도주하게 강제한다.
	animal.global_position = Vector2(bounds.end.x - 1.0, bounds.position.y + bounds.size.y / 2.0)
	animal.is_fleeing = true
	animal.flee_timer = 3.0
	animal.flee_direction = Vector2.RIGHT

	var positions: Array[Vector2] = []
	for i in range(60):
		await physics_frame
		positions.append(animal.global_position)

	# 경계를 넘어가지 않아야 한다.
	if animal.global_position.x > bounds.end.x + 0.5:
		push_error("FAIL: 반사 처리 후에도 동물이 섬 경계를 넘어감 (x=%.1f, edge=%.1f)" % [animal.global_position.x, bounds.end.x])
		ok = false

	# 얼어붙지 않고 실제로 계속 움직여야 한다 — 마지막 30프레임 동안의 위치가
	# 전부 동일하면(고정 소수점 오차 감안 0.01 이하) 멈춘 것으로 판단한다.
	var distinct_positions := 0
	for i in range(30, positions.size() - 1):
		if positions[i].distance_to(positions[i + 1]) > 0.01:
			distinct_positions += 1

	if distinct_positions == 0:
		push_error("FAIL: 경계 근처에서 동물이 움직이지 않고 얼어붙음")
		ok = false

	if animal.flee_direction.x >= 0.0:
		push_error("FAIL: 경계에 닿았는데도 flee_direction.x가 반사되지 않음 (flee_direction=%s)" % animal.flee_direction)
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_BOUNDARY_FLEE_TEST: PASS (final_x=%.1f, edge=%.1f, flee_direction=%s)" % [animal.global_position.x, bounds.end.x, animal.flee_direction])
		quit(0)
	else:
		print("HEADLESS_ANIMAL_BOUNDARY_FLEE_TEST: FAIL")
		quit(1)
