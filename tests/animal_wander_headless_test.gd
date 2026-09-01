extends SceneTree

# inbox.md #13 문제 3 회귀 테스트: 도주 중이 아닐 때 동물이 가만히 서있지
# 않고 주기적으로 무작위 방향으로 배회하는지, 그리고 도주가 시작되면 배회가
# 즉시 멈추고 도주 로직이 우선하는지 확인한다.
# 실행: godot --headless --path . --script res://tests/animal_wander_headless_test.gd
#
# 이전 버그: is_fleeing이 아니면 _physics_process()가 아무 이동도 적용하지
# 않아 동물이 도주 중이 아닐 때는 항상 완전히 정지해 있었다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var animal: Area2D = main.get_node("Animal")
	var start_position: Vector2 = animal.global_position

	var ok := true

	# 배회 타이머를 짧게 강제해 곧바로 이동 상태로 전환되게 한다.
	animal.wander_timer = 0.01
	animal.is_wander_moving = false

	var moved := false
	for i in range(180):
		await physics_frame
		if animal.global_position.distance_to(start_position) > 1.0:
			moved = true
			break

	if not moved:
		push_error("FAIL: 도주 중이 아닌데도 동물이 배회하며 움직이지 않음 (start=%s, now=%s)" % [start_position, animal.global_position])
		ok = false
	elif animal.is_fleeing:
		push_error("FAIL: 배회 테스트 도중 의도치 않게 도주 상태로 전환됨")
		ok = false

	# 배회 중에 도주가 시작되면 배회가 즉시 멈추고 도주 로직이 우선해야 한다.
	animal.is_wander_moving = true
	animal.wander_direction = Vector2.LEFT
	animal._start_fleeing(null)

	if animal.is_wander_moving:
		push_error("FAIL: 도주 시작 후에도 is_wander_moving이 여전히 true")
		ok = false
	if not animal.is_fleeing:
		push_error("FAIL: _start_fleeing() 호출 후 is_fleeing이 true가 아님")
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_WANDER_TEST: PASS (start=%s, moved_to=%s)" % [start_position, animal.global_position])
		quit(0)
	else:
		print("HEADLESS_ANIMAL_WANDER_TEST: FAIL")
		quit(1)
