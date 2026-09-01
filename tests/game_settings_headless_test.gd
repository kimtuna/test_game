extends SceneTree

# 헤드리스 환경에서 GameSettings(scripts/game_settings.gd)가 선택한 해상도를
# 실제로 get_window()에 반영하는지 검증한다.
# 실행: godot --headless --path . --script res://tests/game_settings_headless_test.gd
#
# inbox.md #12: 설정 메뉴에서 해상도를 골라도 실제 창 크기가 안 바뀌는
# 버그가 있었다. 원인 후보로 지목된 "화면비 유지 모드/기준 해상도가
# project.godot의 정적 [display] 설정에 의존하고 있어, 에디터가 그 설정을
# 지우면 스트레치 계산이 꼬인다"는 문제를 해결하기 위해 game_settings.gd가
# content_scale_mode/aspect/size까지 런타임 코드로 직접 강제하도록
# 바꿨다. 헤드리스는 디스플레이가 없어 화면을 눈으로 볼 수는 없지만,
# get_window().size/content_scale_* 프로퍼티는 헤드리스에서도 그대로
# 읽고 쓸 수 있다(DisplayServer의 실제 OS 창 제어 API와 달리) - 그 점을
# 이용해 "설정한 값이 실제로 window 프로퍼티에 적용됐는지"를 코드로
# 회귀 검증한다.

func _initialize() -> void:
	await process_frame
	var game_settings: Node = root.get_node("GameSettings")
	var window := root.get_window()

	var ok := true

	# 기준 해상도(content_scale_size)는 선택한 창 크기가 무엇이든 절대
	# 바뀌면 안 된다(inbox #11의 공정성 요구사항과 직결).
	for i in range(game_settings.RESOLUTIONS.size()):
		game_settings.set_resolution(i)

		if window.size != game_settings.RESOLUTIONS[i]:
			push_error("FAIL: 해상도 인덱스 %d를 선택했는데 get_window().size가 다름 (실제: %s, 기대: %s)" % [i, window.size, game_settings.RESOLUTIONS[i]])
			ok = false
		if window.content_scale_mode != Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
			push_error("FAIL: content_scale_mode가 CANVAS_ITEMS가 아님 (인덱스 %d, 실제: %d)" % [i, window.content_scale_mode])
			ok = false
		if window.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
			push_error("FAIL: content_scale_aspect가 KEEP이 아님 (인덱스 %d, 실제: %d)" % [i, window.content_scale_aspect])
			ok = false
		if window.content_scale_size != game_settings.BASE_RESOLUTION:
			push_error("FAIL: content_scale_size가 BASE_RESOLUTION과 다름 (인덱스 %d, 실제: %s, 기대: %s)" % [i, window.content_scale_size, game_settings.BASE_RESOLUTION])
			ok = false

	if ok:
		print("HEADLESS_GAME_SETTINGS_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_GAME_SETTINGS_TEST: FAIL")
		quit(1)
