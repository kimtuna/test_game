extends SceneTree

# 헤드리스 환경에서 동물의 좌우 방향(flip_h)이 도주 방향을 따라가는지 검증.
# inbox.md #13 문제 1(방향 반전 로직 부재) 회귀 방지용.
# 실행: godot --headless --path . --script res://tests/animal_facing_headless_test.gd

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var animal: Area2D = main.get_node("Animal")

	var ok := true

	# 플레이어가 동물의 왼쪽에 있으면, 도주는 오른쪽(+x)으로 향하므로
	# flip_h는 false(기본 방향)여야 한다.
	player.global_position = animal.global_position + Vector2(-40, 0)
	for i in range(5):
		await physics_frame
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame

	if not animal.is_fleeing:
		push_error("FAIL: 공격 후 도주 상태가 되지 않음")
		ok = false
	if animal.sprite.flip_h:
		push_error("FAIL: 오른쪽(+x)으로 도주하는데 flip_h가 true임")
		ok = false

	var wait_frames := 0
	while animal.is_fleeing and wait_frames < 120:
		await physics_frame
		wait_frames += 1

	# 정지 상태(deer_base.png)로 돌아온 뒤에도 flip_h는 유지돼야 한다
	# (텍스처 전환이 flip_h를 되돌리면 안 된다는 것이 문제 1의 핵심 요구).
	if animal.sprite.texture != animal.base_texture:
		push_error("FAIL: 도주가 끝났는데도 정지 텍스처로 돌아오지 않음")
		ok = false
	if animal.sprite.flip_h:
		push_error("FAIL: 도주 종료 후 정지 텍스처에서 flip_h가 뒤집힘")
		ok = false

	# 이번엔 플레이어가 동물의 오른쪽에 있으면, 도주는 왼쪽(-x)으로 향하므로
	# flip_h는 true여야 한다. 두 번째 발사를 실제 입력으로 다시 시뮬레이션하면
	# status.md #54/#66이 이미 남긴 기존 "fire 입력 이중 소비" 플레이키니스와
	# 뒤섞여 이 테스트의 목적(방향 반전 로직 자체 검증)과 무관하게 흔들릴 수
	# 있으므로, 여기서는 animal.gd가 실제로 쓰는 것과 동일한 함수
	# (_start_fleeing)를 직접 호출해 방향 계산 로직만 결정적으로 확인한다.
	player.global_position = animal.global_position + Vector2(40, 0)
	animal.is_fleeing = false
	animal.flee_timer = 0.0
	animal._start_fleeing(player)

	if not animal.is_fleeing:
		push_error("FAIL: _start_fleeing 호출 후 도주 상태가 되지 않음")
		ok = false
	if not animal.sprite.flip_h:
		push_error("FAIL: 왼쪽(-x)으로 도주하는데 flip_h가 false임")
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_FACING_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_ANIMAL_FACING_TEST: FAIL")
		quit(1)
