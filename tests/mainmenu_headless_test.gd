extends SceneTree

# 헤드리스 환경에서 메인 메뉴(MainMenu.tscn)의 최소 동작을 검증하는 통합
# 테스트.
# 실행: godot --headless --path . --script res://tests/mainmenu_headless_test.gd
# inbox.md #4 4번: 게임 실행 시 바로 플레이 화면으로 들어가지 않고 메인
# 메뉴(시작/설정/종료)를 먼저 보여줘야 한다. 버튼 클릭은 실제 마우스 좌표를
# 흉내내는 대신, 씬에 연결된 것과 동일한 "pressed" 시그널을 직접 발생시켜
# 검증한다 - 이 씬의 버튼들은 .tscn의 [connection]으로 각 핸들러에 연결되어
# 있으므로, 시그널을 쏘는 것이 실제 클릭과 동일한 코드 경로를 탄다.
# (1) 시작 시 메인 패널만 보이는지, (2) 설정 버튼 -> 설정 패널로 전환되는지,
# (3) 뒤로 버튼 -> 다시 메인 패널로 돌아오는지, (4) 시작 버튼 -> Main.tscn으로
# 씬 전환되는지 확인한다.

func _initialize() -> void:
	var main_menu: Control = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(main_menu)
	current_scene = main_menu
	await process_frame

	var main_panel: Control = main_menu.get_node("MainPanel")
	var settings_panel: Control = main_menu.get_node("SettingsPanel")
	var fullscreen_check: CheckButton = main_menu.get_node("SettingsPanel/FullscreenCheck")

	var ok := true

	if not main_panel.visible or settings_panel.visible:
		push_error("FAIL: 시작 시 메인 패널만 보여야 하는데 그렇지 않음")
		ok = false
	if fullscreen_check.button_pressed:
		push_error("FAIL: 헤드리스 환경인데 전체화면 체크가 초기부터 켜져 있음")
		ok = false

	main_menu.get_node("MainPanel/SettingsButton").emit_signal("pressed")
	await process_frame
	if main_panel.visible or not settings_panel.visible:
		push_error("FAIL: 설정 버튼을 눌러도 설정 패널로 전환되지 않음")
		ok = false

	# 헤드리스 환경에서는 실제 창 모드를 바꾸지 않지만, 토글 자체가 에러 없이
	# 처리되는지는 확인한다.
	fullscreen_check.emit_signal("toggled", true)
	await process_frame

	main_menu.get_node("SettingsPanel/BackButton").emit_signal("pressed")
	await process_frame
	if not main_panel.visible or settings_panel.visible:
		push_error("FAIL: 뒤로 버튼을 눌러도 메인 패널로 돌아오지 않음")
		ok = false

	main_menu.get_node("MainPanel/StartButton").emit_signal("pressed")
	await process_frame
	await process_frame

	if current_scene == null or current_scene.name != "Main":
		push_error("FAIL: 시작 버튼을 눌러도 Main 씬으로 전환되지 않음 (실제: %s)" % [current_scene])
		ok = false

	if ok:
		print("HEADLESS_MAINMENU_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_MAINMENU_TEST: FAIL")
		quit(1)
