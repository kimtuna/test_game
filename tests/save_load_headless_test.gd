extends SceneTree

# 헤드리스 환경에서 슬롯 저장/불러오기(디스크 영속화)를 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/save_load_headless_test.gd
# inbox.md #4 4번(메인 메뉴 + 슬롯 선택 + 저장/불러오기 시스템)의 핵심인
# "기존에 저장된 슬롯 선택 시 저장된 상태 그대로 이어서 시작"을, 실제로
# Main.tscn 인스턴스를 한 번 만들고 없앤 뒤 새로 하나 더 만드는 방식으로
# 프로세스를 새로 켠 상황과 최대한 비슷하게 확인한다(같은 프로세스 안에서는
# slot_colors 등 메모리 상태가 그대로 남아있어 디스크 저장을 우회해도 통과할
# 수 있으므로, 인스턴스를 아예 새로 만들어야 디스크에서 실제로 읽어오는지
# 검증된다).

func _clean_saves() -> void:
	for i in range(1, 4):
		var path := "user://saves/slot_%d.save" % i
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if FileAccess.file_exists("user://saves/tutorial_seen.flag"):
		DirAccess.remove_absolute("user://saves/tutorial_seen.flag")

func _press_key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame

func _initialize() -> void:
	_clean_saves()
	var ok := true

	# 1단계: 새 슬롯 1을 골라 빨강으로 커스터마이징하고, 나무를 채집해
	# 인벤토리도 채운 뒤 저장 파일이 실제로 생기는지 확인한다.
	var main1: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main1)
	await process_frame

	await _press_key(KEY_1)
	await _press_key(KEY_2)

	var player1: CharacterBody2D = main1.get_node("Player")
	var tree1: Area2D = main1.get_node("Tree")
	player1.global_position = tree1.global_position
	for i in range(5):
		await physics_frame
	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame

	var save_path := "user://saves/slot_1.save"
	if not FileAccess.file_exists(save_path):
		push_error("FAIL: 커스터마이징+채집 후에도 슬롯 1 저장 파일이 생성되지 않음")
		ok = false

	var inventory_label1: Label = main1.get_node("UI/InventoryLabel")
	if inventory_label1.text != "통나무: 1":
		push_error("FAIL: 저장 전 인벤토리가 기대와 다름 (실제: %s)" % inventory_label1.text)
		ok = false

	# 2단계: 첫 인스턴스를 완전히 없애 메모리 상태(slot_colors 등)를 지우고,
	# 새 Main 인스턴스를 만들어 "프로세스를 새로 켠 뒤 슬롯 1을 다시 고른"
	# 상황을 흉내낸다.
	main1.queue_free()
	await process_frame
	await process_frame

	var main2: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main2)
	await process_frame

	var slot_overlay2: Control = main2.get_node("UI/SlotOverlay")
	var customization_overlay2: Control = main2.get_node("UI/CustomizationOverlay")
	await _press_key(KEY_1)

	if slot_overlay2.visible or customization_overlay2.visible:
		push_error("FAIL: 저장된 슬롯 1을 골랐는데도 커스터마이징을 다시 거침")
		ok = false

	var player2: CharacterBody2D = main2.get_node("Player")
	var expected_red := Color(0.9, 0.2, 0.2)
	if player2.body_color != expected_red:
		push_error("FAIL: 저장된 슬롯 1의 색이 복원되지 않음 (실제: %s)" % [player2.body_color])
		ok = false

	if main2.inventory.get("통나무", 0) != 1:
		push_error("FAIL: 저장된 슬롯 1의 인벤토리가 복원되지 않음 (실제: %s)" % [main2.inventory])
		ok = false

	var inventory_label2: Label = main2.get_node("UI/InventoryLabel")
	if inventory_label2.text != "통나무: 1":
		push_error("FAIL: 슬롯 복원 후 인벤토리 라벨이 갱신되지 않음 (실제: %s)" % inventory_label2.text)
		ok = false

	_clean_saves()

	if ok:
		print("HEADLESS_SAVE_LOAD_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_SAVE_LOAD_TEST: FAIL")
		quit(1)
