extends SceneTree

# 헤드리스 환경에서 동물의 시야 감지 도주(design.md 도주 트리거 중
# "동물의 시야 안에 사람이 보일 때")를 검증하는 통합 테스트. 피격 도주와
# 달리 공격 입력을 전혀 하지 않고도, 플레이어가 시야 범위(SightArea, 반경
# 180) 안에 들어오는 것만으로 도주가 시작되는지 확인한다.
# 실행: godot --headless --path . --script res://tests/animal_sight_flee_headless_test.gd

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var animal: Area2D = main.get_node("Animal")

	var ok := true

	# 시야 범위(180) 밖에 플레이어를 둔다 — 아무 일도 일어나지 않아야 한다.
	player.global_position = animal.global_position + Vector2(500, 500)
	for i in range(5):
		await physics_frame

	if animal.is_fleeing:
		push_error("FAIL: 시야 밖인데도 동물이 도주 상태가 됨")
		ok = false
	if animal.health != animal.MAX_HEALTH:
		push_error("FAIL: 공격하지 않았는데도 동물 체력이 줄어듦 (health=%d)" % animal.health)
		ok = false

	# 상호작용 범위(50) 밖, 시야 범위(180) 안(거리 120)으로 접근한다.
	# 공격/포획 입력은 전혀 하지 않는다.
	player.global_position = animal.global_position + Vector2(-120, 0)
	for i in range(5):
		await physics_frame

	if animal.player_nearby != null:
		push_error("FAIL: 상호작용 범위(50) 밖인데도 player_nearby가 설정됨 — 테스트 거리 가정이 틀림")
		ok = false

	if not animal.is_fleeing:
		push_error("FAIL: 시야 범위 안에 들어갔는데도(공격 없이) 동물이 도주하지 않음")
		ok = false

	if animal.flee_direction.x <= 0.0:
		push_error("FAIL: 시야 도주 방향이 플레이어 반대쪽(+x)이 아님 (flee_direction=%s)" % animal.flee_direction)
		ok = false

	if animal.health != animal.MAX_HEALTH:
		push_error("FAIL: 시야 도주만으로 체력이 줄어듦 (공격이 아니어야 함, health=%d)" % animal.health)
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_SIGHT_FLEE_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_ANIMAL_SIGHT_FLEE_TEST: FAIL")
		quit(1)
