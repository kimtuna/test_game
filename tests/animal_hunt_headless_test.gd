extends SceneTree

# 헤드리스 환경에서 동물 사냥 상호작용을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/animal_hunt_headless_test.gd
# Player를 Animal 위치로 이동시켜 상호작용 범위에 들어가게 한 뒤, ui_accept를
# 반복 입력해 체력이 0 이하가 되면 실제로 사라지고(사냥됨) 인벤토리에 반영되는지 확인한다.
# 공격당한 동물은 살아있는 동안 플레이어 반대 방향으로 잠시 도망가므로(피격 도주),
# 매 공격 사이에 도망이 끝날 때까지 기다린 뒤 Player를 동물 위치로 다시 이동시켜
# "추격해서 다시 근접한다"는 상황을 흉내낸다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var animal: Area2D = main.get_node("Animal")

	var ok := true

	# 범위 밖에서는 ui_accept를 눌러도 체력이 줄지 않아야 한다.
	player.global_position = animal.global_position + Vector2(500, 500)
	await physics_frame
	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame
	if animal.health != animal.MAX_HEALTH:
		push_error("FAIL: 범위 밖인데도 동물 체력이 줄어듦 (health=%d)" % animal.health)
		ok = false

	# Player를 동물 위치로 이동시켜 상호작용 범위에 들어가게 한다.
	player.global_position = animal.global_position
	for i in range(5):
		await physics_frame

	if animal.player_nearby == null:
		push_error("FAIL: Player가 Animal의 상호작용 범위에 들어갔는데도 player_nearby가 설정되지 않음")
		ok = false

	# 체력이 0 이하가 될 때까지 반복 공격 (MAX_HEALTH=100, ATTACK_DAMAGE=31 -> 4회).
	var health_label: Label = animal.get_node("HealthLabel")
	var hits := 0
	while is_instance_valid(animal) and animal.is_inside_tree() and hits < 10:
		Input.action_press("ui_accept")
		await process_frame
		Input.action_release("ui_accept")
		await process_frame
		hits += 1
		if hits == 1 and health_label.text != "69/100":
			push_error("FAIL: 1회 공격 후 체력 라벨이 기대한 값(69/100)이 아님 (실제: %s)" % health_label.text)
			ok = false

		if is_instance_valid(animal) and animal.is_inside_tree():
			var wait_frames := 0
			while animal.is_fleeing and wait_frames < 120:
				await physics_frame
				wait_frames += 1
			player.global_position = animal.global_position
			for i in range(5):
				await physics_frame

	if is_instance_valid(animal) and animal.is_inside_tree():
		push_error("FAIL: 반복 공격했는데도 동물이 사냥되지 않음")
		ok = false

	var inventory_label: Label = main.get_node("UI/InventoryLabel")
	if inventory_label.text != "고기: 1":
		push_error("FAIL: 사냥 후 인벤토리 라벨이 기대한 값(고기: 1)이 아님 (실제: %s)" % inventory_label.text)
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_HUNT_TEST: PASS (hits=%d)" % hits)
		quit(0)
	else:
		print("HEADLESS_ANIMAL_HUNT_TEST: FAIL")
		quit(1)
