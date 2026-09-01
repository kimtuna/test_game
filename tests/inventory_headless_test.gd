extends SceneTree

# 헤드리스 환경에서 인벤토리(E키 토글, 9칸 용량) 최소 동작을 검증하는
# 통합 테스트.
# 실행: godot --headless --path . --script res://tests/inventory_headless_test.gd
# inbox.md #6 3번(인벤토리, E키, 9칸)의 구현을 검증한다:
# (1) 실제 플레이 상태에서 E를 누르면 InventoryOverlay가 열리고, 다시 누르면
#     닫히는지.
# (2) main._on_harvested()로 자원을 얻으면 9칸 그리드에 이름+개수로 표시되는지
#     (아이콘 리소스가 없어 텍스트로만 표시, main.gd 주석 참고).
# (3) 이미 서로 다른 9종을 채운 뒤 10번째 새 종류를 얻으려 하면 거부되고
#     (inventory.size()가 9를 넘지 않음), 이미 갖고 있던 종류를 더 얻는 것은
#     계속 허용되는지.
# equipment_upgrade_headless_test.gd와 동일한 이유로, 실제 씬의 자원 종류가
# 4종뿐이라 9종을 자연스럽게 모을 수 없으므로 main._on_harvested()를 직접
# 호출해 상황을 흉내낸다.

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

func _initialize() -> void:
	_clean_saves()
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	# 슬롯 선택 -> 커스터마이징 -> 튜토리얼 닫기를 흉내내 "실제 플레이 상태"까지
	# 진행한다(pause_menu_headless_test.gd와 동일한 절차).
	_press_key(KEY_1)
	await process_frame
	_press_key(KEY_1)
	await process_frame
	_press_key(KEY_SPACE)
	await process_frame

	var inventory_overlay: Control = main.get_node("UI/InventoryOverlay")
	var slot_grid: GridContainer = main.get_node("UI/InventoryOverlay/InventoryPanel/Body/SlotGrid")
	var ok := true

	if inventory_overlay.visible:
		push_error("FAIL: 플레이 상태 진입 직후인데 인벤토리가 이미 열려있음")
		ok = false

	_press_key(KEY_E)
	await process_frame
	if not inventory_overlay.visible:
		push_error("FAIL: E를 눌러도 인벤토리가 열리지 않음")
		ok = false
	if paused:
		push_error("FAIL: 인벤토리를 열었을 뿐인데 SceneTree가 멈춤(멀티플레이에서 다른 플레이어까지 멈추면 안 됨)")
		ok = false

	_press_key(KEY_E)
	await process_frame
	if inventory_overlay.visible:
		push_error("FAIL: 열린 상태에서 E를 다시 눌러도 인벤토리가 닫히지 않음")
		ok = false

	# 자원을 얻으면 그리드에 이름+개수로 표시되는지 확인.
	main._on_harvested("통나무", 3)
	_press_key(KEY_E)
	await process_frame
	var slot0_label: Label = slot_grid.get_node("Slot0/SlotLabel")
	if not slot0_label.text.contains("통나무") or not slot0_label.text.contains("3"):
		push_error("FAIL: 자원을 얻어도 인벤토리 슬롯에 표시되지 않음 (실제: %s)" % slot0_label.text)
		ok = false
	_press_key(KEY_E)
	await process_frame

	# 9칸 용량 검증: 서로 다른 9종을 채운 뒤(이미 있던 "통나무" 포함, 8종 추가),
	# 10번째 새 종류는 거부되고 기존 종류를 더 얻는 것은 계속 허용돼야 한다.
	for i in range(1, 9):
		main._on_harvested("자원%d" % i, 1)
	if main.inventory.size() != 9:
		push_error("FAIL: 9종을 모았는데 inventory.size()가 9가 아님 (실제: %d)" % main.inventory.size())
		ok = false

	main._on_harvested("자원10", 1)
	if main.inventory.has("자원10"):
		push_error("FAIL: 인벤토리가 가득 찼는데도 10번째 새 종류가 추가됨")
		ok = false
	if main.inventory.size() != 9:
		push_error("FAIL: 가득 찬 뒤에도 inventory.size()가 9를 넘지 않아야 함 (실제: %d)" % main.inventory.size())
		ok = false

	# "자원1"은 RESOURCE_TO_SLOT에 매핑되지 않아 장비 자동 승급(_try_upgrade_equipment)이
	# 끼어들어 소비되지 않으므로, "이미 있던 종류는 계속 늘어난다"를 순수하게 검증할 수 있다.
	main._on_harvested("자원1", 2)
	if main.inventory.get("자원1", 0) != 3:
		push_error("FAIL: 인벤토리가 가득 차도 이미 갖고 있던 종류(자원1)는 계속 늘어나야 함 (실제: %d)" % main.inventory.get("자원1", 0))
		ok = false

	_clean_saves()

	if ok:
		print("HEADLESS_INVENTORY_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_INVENTORY_TEST: FAIL")
		quit(1)
