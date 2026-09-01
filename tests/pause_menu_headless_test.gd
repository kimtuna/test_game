extends SceneTree

# 헤드리스 환경에서 게임 중 ESC 일시정지 메뉴(PauseOverlay)의 최소 동작을
# 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/pause_menu_headless_test.gd
# status.md #50이 남긴 "게임 중 메인 메뉴로 나가는 흐름" 공백을 메우는 조각의
# 검증용. (1) 실제 플레이 상태(슬롯/커스터마이징/튜토리얼을 모두 지난 뒤)에서
# ESC를 누르면 오버레이가 뜨고 SceneTree.paused가 true가 되는지, (2) ESC를
# 다시 누르면(PauseOverlay 자신의 process_mode=ALWAYS를 통해) paused 상태에서도
# 반응해 재개되는지, (3) 다시 연 뒤 "메인 메뉴로" 버튼을 누르면 paused가
# 풀리고 MainMenu 씬으로 전환되는지 확인한다.
# 버튼 클릭은 mainmenu_headless_test.gd와 동일한 이유로 실제 마우스 좌표
# 대신 "pressed" 시그널을 직접 발생시켜 검증한다(.tscn의 [connection]과 동일한
# 코드 경로).

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

	# 슬롯 선택 -> 커스터마이징 3단계(피부색/눈색/머리종류, inbox.md #7 3번) ->
	# 튜토리얼 닫기를 흉내내 "실제 플레이 상태"까지 진행한다
	# (tutorial_headless_test.gd와 동일한 절차).
	_press_key(KEY_1)
	await process_frame
	for i in range(3):
		_press_key(KEY_1)
		await process_frame
	_press_key(KEY_SPACE)
	await process_frame

	var pause_overlay: Control = main.get_node("UI/PauseOverlay")
	var ok := true

	if pause_overlay.visible or paused:
		push_error("FAIL: 플레이 상태 진입 직후인데 일시정지 메뉴가 이미 떠 있거나 트리가 멈춰 있음")
		ok = false

	_press_key(KEY_ESCAPE)
	await process_frame

	if not pause_overlay.visible or not paused:
		push_error("FAIL: ESC를 눌러도 일시정지 메뉴가 뜨지 않거나 트리가 멈추지 않음")
		ok = false

	_press_key(KEY_ESCAPE)
	await process_frame

	if pause_overlay.visible or paused:
		push_error("FAIL: 일시정지 상태에서 ESC를 다시 눌러도 재개되지 않음")
		ok = false

	_press_key(KEY_ESCAPE)
	await process_frame
	if not pause_overlay.visible or not paused:
		push_error("FAIL: 재개 후 ESC로 일시정지 메뉴를 다시 열 수 없음")
		ok = false

	pause_overlay.get_node("PausePanel/MainMenuButton").emit_signal("pressed")
	await process_frame
	await process_frame

	if paused:
		push_error("FAIL: 메인 메뉴로 이동한 뒤에도 트리가 멈춘 상태로 남음")
		ok = false
	if current_scene == null or current_scene.name != "MainMenu":
		push_error("FAIL: '메인 메뉴로' 버튼을 눌러도 MainMenu 씬으로 전환되지 않음 (실제: %s)" % [current_scene])
		ok = false

	_clean_saves()

	if ok:
		print("HEADLESS_PAUSE_MENU_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_PAUSE_MENU_TEST: FAIL")
		quit(1)
