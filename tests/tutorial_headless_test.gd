extends SceneTree

# 헤드리스 환경에서 튜토리얼 오버레이의 최소 동작을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/tutorial_headless_test.gd
# status.md #31에서 캐릭터 슬롯 선택 오버레이가 커스터마이징보다 먼저 뜨도록
# 앞단이 하나 더 추가되어, 이 테스트도 먼저 슬롯 선택(키 1) -> 커스터마이징
# 색 선택(키 1)을 흉내낸 뒤 튜토리얼 오버레이가 보이는지부터 검증하도록
# 갱신했다.
# (1) 색을 고르면 튜토리얼 오버레이가 나타나는지, (2) 아무 키나 누르면
# 사라지는지, (3) 사라진 뒤에는 다시 나타나지 않는지 확인한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var overlay: Control = main.get_node("UI/TutorialOverlay")
	var slot_overlay: Control = main.get_node("UI/SlotOverlay")
	var customization_overlay: Control = main.get_node("UI/CustomizationOverlay")

	var ok := true

	var slot_event := InputEventKey.new()
	slot_event.keycode = KEY_1
	slot_event.pressed = true
	Input.parse_input_event(slot_event)
	await process_frame

	if slot_overlay.visible:
		push_error("FAIL: 슬롯 선택 후에도 슬롯 오버레이가 사라지지 않음")
		ok = false

	var color_event := InputEventKey.new()
	color_event.keycode = KEY_1
	color_event.pressed = true
	Input.parse_input_event(color_event)
	await process_frame

	if customization_overlay.visible:
		push_error("FAIL: 색 선택 후에도 커스터마이징 오버레이가 사라지지 않음")
		ok = false

	if not overlay.visible:
		push_error("FAIL: 커스터마이징 후 튜토리얼 오버레이가 보이지 않음")
		ok = false

	var key_event := InputEventKey.new()
	key_event.keycode = KEY_SPACE
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await process_frame

	if overlay.visible:
		push_error("FAIL: 키 입력 후에도 튜토리얼 오버레이가 사라지지 않음")
		ok = false

	var key_event2 := InputEventKey.new()
	key_event2.keycode = KEY_A
	key_event2.pressed = true
	Input.parse_input_event(key_event2)
	await process_frame

	if overlay.visible:
		push_error("FAIL: 한 번 닫힌 튜토리얼 오버레이가 다시 나타남")
		ok = false

	if ok:
		print("HEADLESS_TUTORIAL_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_TUTORIAL_TEST: FAIL")
		quit(1)
