extends SceneTree

# 헤드리스 환경에서 섬 경계 충돌(바다로 못 나가는지)을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/boundary_headless_test.gd
# Player에 직접 속도를 주고 move_and_slide를 반복 호출해, 섬 오른쪽 경계 벽에
# 실제로 부딪혀 더 이상 전진하지 못하는지 확인한다.

const ISLAND_CENTER := Vector2(576, 324)
const ISLAND_HALF_WIDTH := 1000.0
const SPEED := 300.0

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	player.global_position = ISLAND_CENTER

	for i in range(250):
		player.velocity = Vector2.RIGHT * SPEED
		player.move_and_slide()
		await physics_frame

	var island_right_edge := ISLAND_CENTER.x + ISLAND_HALF_WIDTH
	var x := player.global_position.x

	var ok := true
	if x >= island_right_edge:
		push_error("FAIL: Player가 섬 경계(x=%.1f)를 넘어 바다로 나감 (x=%.1f)" % [island_right_edge, x])
		ok = false
	if x < island_right_edge - 100.0:
		push_error("FAIL: Player가 경계까지 충분히 접근하지 못함 (x=%.1f, 경계=%.1f) — 벽 충돌이 아니라 다른 원인으로 멈췄을 가능성" % [x, island_right_edge])
		ok = false

	if ok:
		print("HEADLESS_BOUNDARY_TEST: PASS (final_x=%.1f, island_right_edge=%.1f)" % [x, island_right_edge])
		quit(0)
	else:
		print("HEADLESS_BOUNDARY_TEST: FAIL")
		quit(1)
