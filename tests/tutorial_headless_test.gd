extends SceneTree

# 헤드리스 환경에서 튜토리얼 오버레이의 최소 동작을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/tutorial_headless_test.gd
# (1) 게임 시작 시 튜토리얼 오버레이가 보이는지, (2) 아무 키나 누르면
# 사라지는지, (3) 사라진 뒤에는 다시 나타나지 않는지 확인한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var overlay: Control = main.get_node("UI/TutorialOverlay")

	var ok := true

	if not overlay.visible:
		push_error("FAIL: 시작 시 튜토리얼 오버레이가 보이지 않음")
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
