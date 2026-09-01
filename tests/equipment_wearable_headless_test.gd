extends SceneTree

# 헤드리스 환경에서 착용형 장비(복장/악세서리) 7슬롯을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/equipment_wearable_headless_test.gd
# inbox.md #6 4번(모자/상의/하의/신발/귀걸이/반지/가방 7슬롯)의 구현을 검증한다:
# (1) 기본값은 7슬롯 전부 빈 상태(- 로 표시)인지.
# (2) player.equip_wearable()로 착용하면 인벤토리(E) 오버레이의 WearableColumn에
#     "이름: 아이템"으로 표시되는지, unequip_wearable()로 벗으면 다시 "-"로
#     돌아오는지.
# (3) 슬롯 저장/불러오기(save_load_headless_test.gd와 동일한 절차 — 인스턴스를
#     완전히 없애고 새로 만들어 디스크에서 실제로 복원되는지 확인)에 착용
#     상태가 함께 영속화되는지.
# 아직 옷/장신구를 얻는 게임 내 방법이 없어(범위 밖, inbox #4 5번) equip_wearable()을
# 직접 호출해 상황을 흉내낸다 — equipment_upgrade_headless_test.gd와 동일한 방식.

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

	# 슬롯 선택 -> 커스터마이징 3단계(피부색/눈색/머리종류, inbox.md #7 3번) ->
	# 튜토리얼 닫기.
	await _press_key(KEY_1)
	await _press_key(KEY_2)
	await _press_key(KEY_1)
	await _press_key(KEY_1)
	await _press_key(KEY_SPACE)

	var player1: CharacterBody2D = main1.get_node("Player")
	var wearable_column1: VBoxContainer = main1.get_node("UI/InventoryOverlay/InventoryPanel/Body/WearableColumn")

	# (1) 기본값: 7슬롯 전부 빈 상태.
	for i in range(player1.WEARABLE_SLOTS.size()):
		if player1.get_wearable(player1.WEARABLE_SLOTS[i]) != "":
			push_error("FAIL: 기본 상태인데 %s 슬롯이 비어있지 않음" % player1.WEARABLE_SLOTS[i])
			ok = false
	if wearable_column1.get_child_count() != 7:
		push_error("FAIL: WearableColumn 자식 개수가 7이 아님 (실제: %d)" % wearable_column1.get_child_count())
		ok = false

	# (2) 착용/해제가 UI에 반영되는지.
	player1.equip_wearable("hat", "밀짚모자")
	await _press_key(KEY_E)
	var hat_label1: Label = wearable_column1.get_child(0).get_node("WearableLabel")
	if hat_label1.text != "모자: 밀짚모자":
		push_error("FAIL: 모자를 착용해도 UI에 반영되지 않음 (실제: %s)" % hat_label1.text)
		ok = false
	await _press_key(KEY_E)

	player1.unequip_wearable("hat")
	await _press_key(KEY_E)
	if hat_label1.text != "모자: -":
		push_error("FAIL: 모자를 벗어도 UI가 갱신되지 않음 (실제: %s)" % hat_label1.text)
		ok = false
	await _press_key(KEY_E)

	# (3) 저장: 가방을 착용한 상태로 슬롯 1을 저장.
	player1.equip_wearable("bag", "가죽가방")
	main1._save_slot(1)

	main1.queue_free()
	await process_frame
	await process_frame

	var main2: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main2)
	await process_frame
	await _press_key(KEY_1)

	var player2: CharacterBody2D = main2.get_node("Player")
	if player2.get_wearable("bag") != "가죽가방":
		push_error("FAIL: 저장된 슬롯 1의 착용 장비(가방)가 복원되지 않음 (실제: %s)" % player2.get_wearable("bag"))
		ok = false

	await _press_key(KEY_E)
	var wearable_column2: VBoxContainer = main2.get_node("UI/InventoryOverlay/InventoryPanel/Body/WearableColumn")
	var bag_label2: Label = wearable_column2.get_child(6).get_node("WearableLabel")
	if bag_label2.text != "가방: 가죽가방":
		push_error("FAIL: 복원된 착용 장비가 UI에 반영되지 않음 (실제: %s)" % bag_label2.text)
		ok = false

	_clean_saves()

	if ok:
		print("HEADLESS_EQUIPMENT_WEARABLE_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_EQUIPMENT_WEARABLE_TEST: FAIL")
		quit(1)
