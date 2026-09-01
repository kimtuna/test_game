extends SceneTree

# 헤드리스 환경에서 동물 포획(마취총) 상호작용을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/animal_capture_headless_test.gd
# 1) 체력이 8% 이상일 때 capture 액션을 눌러도 포획되지 않아야 한다.
# 2) ui_accept로 체력을 8% 미만(ATTACK_DAMAGE=31 기준 3회 공격 -> 7/100)까지
#    낮춘 뒤 capture 액션을 누르면 실제로 포획되어(사라지고) CaptureLabel에
#    반영되며, 이때는 harvested(고기)가 아니라 captured 경로이므로 인벤토리는
#    비어 있어야 한다.
# 공격당한 동물은 피격 도주로 잠시 자리를 이동하므로, 매 공격 사이에 도망이
# 끝날 때까지 기다린 뒤 Player를 동물 위치로 다시 이동시켜 추격 상황을 흉내낸다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var animal: Area2D = main.get_node("Animal")
	var health_label: Label = animal.get_node("HealthLabel")
	var capture_label: Label = main.get_node("UI/CaptureLabel")
	var inventory_label: Label = main.get_node("UI/InventoryLabel")

	var ok := true

	player.global_position = animal.global_position
	for i in range(5):
		await physics_frame

	# 체력이 아직 100/100(8% 이상)일 때 포획을 시도하면 실패해야 한다.
	Input.action_press("capture")
	await process_frame
	Input.action_release("capture")
	await process_frame
	if not is_instance_valid(animal) or not animal.is_inside_tree():
		push_error("FAIL: 체력이 충분히 높은데도 포획이 성공함")
		ok = false

	# ui_accept로 3회 공격 -> 100 -> 69 -> 38 -> 7 (8% 미만).
	for i in range(3):
		Input.action_press("ui_accept")
		await process_frame
		Input.action_release("ui_accept")
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

	# 이제 체력이 8% 미만이므로 capture 액션을 누르면 포획되어야 한다.
	Input.action_press("capture")
	await process_frame
	Input.action_release("capture")
	await process_frame

	if is_instance_valid(animal) and animal.is_inside_tree():
		push_error("FAIL: 체력이 8%% 미만인데도 포획이 성공하지 않음")
		ok = false

	if capture_label.text != "포획: 동물 x1":
		push_error("FAIL: 포획 후 CaptureLabel이 기대한 값(포획: 동물 x1)이 아님 (실제: %s)" % capture_label.text)
		ok = false

	if inventory_label.text != "":
		push_error("FAIL: 포획(죽이지 않음)인데도 인벤토리에 자원이 기록됨 (실제: %s)" % inventory_label.text)
		ok = false

	if ok:
		print("HEADLESS_ANIMAL_CAPTURE_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_ANIMAL_CAPTURE_TEST: FAIL")
		quit(1)
