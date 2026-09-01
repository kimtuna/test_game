extends SceneTree

# 헤드리스 환경에서 휴대 장비 핫바(숫자 1~5) 최소 동작을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/hotbar_headless_test.gd
# inbox.md #6 5번(핫바, 인벤토리 9칸과 별도 데이터 구조)의 구현을 검증한다:
# (1) 기본값은 5칸 전부 빈 상태(- 로 표시)이고 active_hotbar_index는 0인지.
# (2) 실제 플레이 상태에서 숫자 키(1~5)를 누르면 active_hotbar_index가 바뀌고
#     UI에서 해당 슬롯만 강조(self_modulate)되는지.
# (3) 핫바 데이터(player.hotbar)와 인벤토리 데이터(main.inventory)가 서로 다른
#     구조라 한쪽을 바꿔도 다른 쪽이 영향받지 않는지.
# (4) 슬롯 저장/불러오기(equipment_wearable_headless_test.gd와 동일한 절차)에
#     핫바 내용물과 active_hotbar_index가 함께 영속화되는지.

func _clean_saves() -> void:
	for i in range(1, 4):
		var path := "user://saves/slot_%d.save" % i
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if FileAccess.file_exists("user://saves/tutorial_seen.flag"):
		DirAccess.remove_absolute("user://saves/tutorial_seen.flag")

func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame

func _initialize() -> void:
	_clean_saves()
	var ok := true

	var main1: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main1)
	await process_frame

	await _press_key(KEY_1)
	await _press_key(KEY_2)
	await _press_key(KEY_SPACE)

	var player1: CharacterBody2D = main1.get_node("Player")
	var hotbar_row1: HBoxContainer = main1.get_node("UI/Hotbar")

	# (1) 기본값: 5칸 전부 빈 상태, active_hotbar_index는 0.
	for i in range(player1.HOTBAR_SIZE):
		if player1.get_hotbar_item(i) != "":
			push_error("FAIL: 기본 상태인데 핫바 슬롯 %d이 비어있지 않음" % i)
			ok = false
	if player1.active_hotbar_index != 0:
		push_error("FAIL: 기본 active_hotbar_index가 0이 아님 (실제: %d)" % player1.active_hotbar_index)
		ok = false
	if hotbar_row1.get_child_count() != 5:
		push_error("FAIL: Hotbar 자식 개수가 5가 아님 (실제: %d)" % hotbar_row1.get_child_count())
		ok = false

	# (2) 숫자 키로 슬롯을 선택하면 active_hotbar_index와 강조 표시가 바뀌는지.
	await _press_key(KEY_3)
	if player1.active_hotbar_index != 2:
		push_error("FAIL: 3번 키를 눌러도 active_hotbar_index가 2가 되지 않음 (실제: %d)" % player1.active_hotbar_index)
		ok = false
	var slot2_panel: Panel = hotbar_row1.get_child(2)
	var slot0_panel: Panel = hotbar_row1.get_child(0)
	if slot2_panel.self_modulate == slot0_panel.self_modulate:
		push_error("FAIL: 선택된 슬롯(3번)과 선택되지 않은 슬롯(1번)의 강조 색이 구분되지 않음")
		ok = false

	# (3) 핫바와 인벤토리는 별도 데이터 구조 — 한쪽을 바꿔도 다른 쪽은 영향받지 않음.
	player1.set_hotbar_item(2, "낫")
	main1._on_harvested("통나무", 1)
	if main1.inventory.has("낫"):
		push_error("FAIL: 핫바에 담긴 아이템이 인벤토리 데이터에 섞여 들어감")
		ok = false
	if player1.get_hotbar_item(2) != "낫":
		push_error("FAIL: 인벤토리 조작 후 핫바 슬롯 내용물이 유지되지 않음 (실제: %s)" % player1.get_hotbar_item(2))
		ok = false

	# (4) 저장: 3번 슬롯에 아이템을 담고 활성 인덱스를 2로 둔 상태로 슬롯 1을 저장.
	main1._save_slot(1)

	main1.queue_free()
	await process_frame
	await process_frame

	var main2: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main2)
	await process_frame
	await _press_key(KEY_1)

	var player2: CharacterBody2D = main2.get_node("Player")
	if player2.get_hotbar_item(2) != "낫":
		push_error("FAIL: 저장된 슬롯 1의 핫바 내용물이 복원되지 않음 (실제: %s)" % player2.get_hotbar_item(2))
		ok = false
	if player2.active_hotbar_index != 2:
		push_error("FAIL: 저장된 슬롯 1의 active_hotbar_index가 복원되지 않음 (실제: %d)" % player2.active_hotbar_index)
		ok = false

	_clean_saves()

	if ok:
		print("HEADLESS_HOTBAR_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_HOTBAR_TEST: FAIL")
		quit(1)
