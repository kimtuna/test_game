extends SceneTree

# 헤드리스 환경에서 동물의 발소리 감지 도주(design.md 도주 트리거 중
# "사람의 발소리를 감지했을 때")를 검증하는 통합 테스트. 시야 감지와 달리
# "플레이어가 정지해 있으면 감지되지 않고, 이동 중일 때만 감지된다"는
# 조건을 확인한다. 플레이어를 시야 범위(SightArea, 180) 밖 · 발소리 범위
# (SoundArea, 250) 안에 두어 두 트리거가 섞이지 않게 격리한다.
# 실행: godot --headless --path . --script res://tests/animal_sound_flee_headless_test.gd

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var animal: Area2D = main.get_node("Animal")

	var ok := true

	# 시야 범위(180) 밖, 발소리 범위(250) 안(거리 220)에 플레이어를 세워둔다.
	# 아직 움직이지 않았으므로(정지 상태) 아무 일도 일어나지 않아야 한다.
	player.global_position = animal.global_position + Vector2(-220, 0)
	for i in range(5):
		await physics_frame

	if animal.player_nearby != null:
		push_error("FAIL: 상호작용 범위(50) 밖인데도 player_nearby가 설정됨 — 테스트 거리 가정이 틀림")
		ok = false
	if animal.player_in_sight != null:
		push_error("FAIL: 시야 범위(180) 밖인데도 player_in_sight가 설정됨 — 테스트 거리 가정이 틀림")
		ok = false
	if animal.is_fleeing:
		push_error("FAIL: 플레이어가 정지해 있는데도 발소리 감지만으로 동물이 도주함")
		ok = false
	if animal.health != animal.MAX_HEALTH:
		push_error("FAIL: 공격하지 않았는데도 동물 체력이 줄어듦 (health=%d)" % animal.health)
		ok = false

	# 이제 플레이어가 왼쪽으로 이동(발소리 발생)한다. 공격/포획 입력은 없다.
	Input.action_press("move_left")
	for i in range(5):
		await physics_frame
	Input.action_release("move_left")

	if not animal.is_fleeing:
		push_error("FAIL: 이동 중인 플레이어가 발소리 범위 안에 있는데도 동물이 도주하지 않음")
		ok = false

	if animal.flee_direction.x <= 0.0:
		push_error("FAIL: 발소리 도주 방향이 플레이어 반대쪽(+x)이 아님 (flee_direction=%s)" % animal.flee_direction)
		ok = false

	if animal.health != animal.MAX_HEALTH:
		push_error("FAIL: 발소리 도주만으로 체력이 줄어듦 (공격이 아니어야 함, health=%d)" % animal.health)
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_SOUND_FLEE_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_ANIMAL_SOUND_FLEE_TEST: FAIL")
		quit(1)
