extends SceneTree

# 헤드리스 환경에서 "장비" 게이트(player.gd의 equipment 슬롯)를 검증하는
# 통합 테스트. 실행: godot --headless --path . --script res://tests/equipment_gate_headless_test.gd
# 1) tool(도끼) 슬롯을 비우면 상호작용 범위 안이라도 나무 채집이 진행되지
#    않아야 한다. 다시 장착하면 정상적으로 채집된다.
# 2) tool 슬롯을 비우면 동물 공격도 진행되지 않아야 한다(체력 불변).
# 3) 공격으로 체력을 8% 미만까지 낮춘 뒤 weapon(마취총) 슬롯을 비우면
#    포획이 실패해야 하고, 다시 장착하면 포획에 성공해야 한다.
# inbox.md #4 2번(status.md #49)로 동물 공격/포획 입력이 모두 fire(좌클릭)로
# 바뀌었다 — ammo_type("normal"/"tranquilizer")으로 어느 판정을 트리거할지 결정한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var tree: Area2D = main.get_node("Tree")
	var animal: Area2D = main.get_node("Animal")
	var health_label: Label = animal.get_node("HealthLabel")

	var ok := true

	# --- 1) 도끼 없이는 채집이 진행되지 않는다 ---
	player.global_position = tree.global_position
	for i in range(5):
		await physics_frame
	if tree.player_nearby == null:
		push_error("FAIL: Player가 Tree 상호작용 범위에 들어갔는데도 player_nearby가 설정되지 않음")
		ok = false

	player.unequip("tool")
	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame
	if not is_instance_valid(tree) or not tree.is_inside_tree() or tree.hits_taken != 0:
		push_error("FAIL: 도끼 없이도 나무 채집(hits_taken 증가 또는 사라짐)이 진행됨")
		ok = false

	# 도끼를 다시 장착하면 정상적으로 채집된다(grade=1이므로 1회면 충분).
	player.equip("tool", "도끼")
	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame
	if is_instance_valid(tree) and tree.is_inside_tree():
		push_error("FAIL: 도끼를 재장착했는데도 나무가 채집되지 않음")
		ok = false

	# --- 2) 도끼 없이는 동물 공격이 진행되지 않는다 ---
	player.global_position = animal.global_position
	for i in range(5):
		await physics_frame
	if animal.player_nearby == null:
		push_error("FAIL: Player가 Animal 상호작용 범위에 들어갔는데도 player_nearby가 설정되지 않음")
		ok = false

	player.unequip("tool")
	player.ammo_type = "normal"
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame
	if health_label.text != "100/100":
		push_error("FAIL: 도끼 없이도 동물 체력이 감소함 (실제: %s)" % health_label.text)
		ok = false

	# --- 3) 도끼를 재장착해 체력을 8% 미만까지 낮춘다 (100 -> 69 -> 38 -> 7) ---
	player.equip("tool", "도끼")
	for i in range(3):
		Input.action_press("fire")
		await process_frame
		Input.action_release("fire")
		await process_frame

		var wait_frames := 0
		while animal.is_fleeing and wait_frames < 120:
			await physics_frame
			wait_frames += 1
		player.global_position = animal.global_position
		for j in range(5):
			await physics_frame

	if health_label.text != "7/100":
		push_error("FAIL: 3회 공격 후 체력 라벨이 기대한 값(7/100)이 아님 (실제: %s)" % health_label.text)
		ok = false

	# 마취총 없이는 포획이 실패해야 한다.
	player.unequip("weapon")
	player.ammo_type = "tranquilizer"
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame
	if not is_instance_valid(animal) or not animal.is_inside_tree():
		push_error("FAIL: 마취총 없이도 포획이 성공함")
		ok = false

	# 마취총을 재장착하면 포획에 성공해야 한다.
	player.equip("weapon", "마취총")
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame
	if is_instance_valid(animal) and animal.is_inside_tree():
		push_error("FAIL: 마취총을 재장착했는데도 포획되지 않음")
		ok = false

	if ok:
		print("HEADLESS_EQUIPMENT_GATE_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_EQUIPMENT_GATE_TEST: FAIL")
		quit(1)
