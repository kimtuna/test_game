extends SceneTree

# 헤드리스 환경에서 캐릭터 커스터마이징(피부색/눈색/머리종류 3단계) 오버레이를
# 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/customization_headless_test.gd
# inbox.md #7 3번: 커스터마이징이 몸 색 하나에서 피부색/눈색/머리종류 3단계로
# 늘어났다 — (1) 슬롯을 고르면 0단계(피부색)로 커스터마이징 오버레이가 뜨는지,
# (2) 피부색을 고르면 1단계(눈색)로 넘어가고(오버레이는 계속 보임) 즉시
# 미리보기가 반영되는지, (3) 눈색을 고르면 2단계(머리종류)로 넘어가는지,
# (4) 머리종류까지 고르면 오버레이가 닫히고 튜토리얼로 이어지며 player의
# skin_color/eye_color/hair_type이 모두 선택한 값으로 반영되는지 확인한다.

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
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var slot_overlay: Control = main.get_node("UI/SlotOverlay")
	var customization_overlay: Control = main.get_node("UI/CustomizationOverlay")
	var tutorial_overlay: Control = main.get_node("UI/TutorialOverlay")
	var player := main.get_node("Player")

	var ok := true

	await _press_key(KEY_1)

	if slot_overlay.visible:
		push_error("FAIL: 슬롯 선택 후에도 슬롯 오버레이가 사라지지 않음")
		ok = false
	if not customization_overlay.visible:
		push_error("FAIL: 처음 고른 슬롯인데 커스터마이징 오버레이가 보이지 않음")
		ok = false
	if main.customization_step != 0:
		push_error("FAIL: 커스터마이징 시작 단계가 0(피부색)이 아님 (실제: %d)" % main.customization_step)
		ok = false
	if tutorial_overlay.visible:
		push_error("FAIL: 커스터마이징 전인데 튜토리얼 오버레이가 이미 보임")
		ok = false

	# 0단계: 피부색 2번(빨강) 선택 -> 1단계(눈색)로 이동, 오버레이는 유지.
	await _press_key(KEY_2)

	if not customization_overlay.visible:
		push_error("FAIL: 피부색 선택 직후 커스터마이징 오버레이가 닫힘(2단계 더 남아있어야 함)")
		ok = false
	if main.customization_step != 1:
		push_error("FAIL: 피부색 선택 후 1단계(눈색)로 넘어가지 않음 (실제: %d)" % main.customization_step)
		ok = false
	var expected_skin := Color(0.9, 0.2, 0.2)
	if player.skin_color != expected_skin:
		push_error("FAIL: player.skin_color가 선택한 피부색으로 갱신되지 않음 (실제: %s)" % [player.skin_color])
		ok = false

	# 1단계: 눈색 2번(파랑) 선택 -> 2단계(머리종류)로 이동.
	await _press_key(KEY_2)

	if not customization_overlay.visible:
		push_error("FAIL: 눈색 선택 직후 커스터마이징 오버레이가 닫힘(1단계 더 남아있어야 함)")
		ok = false
	if main.customization_step != 2:
		push_error("FAIL: 눈색 선택 후 2단계(머리종류)로 넘어가지 않음 (실제: %d)" % main.customization_step)
		ok = false
	var expected_eye := Color(0.15, 0.35, 0.75)
	if player.eye_color != expected_eye:
		push_error("FAIL: player.eye_color가 선택한 눈색으로 갱신되지 않음 (실제: %s)" % [player.eye_color])
		ok = false

	# 2단계: 머리종류 2번(모히칸) 선택 -> 커스터마이징 완료, 튜토리얼로 이어짐.
	await _press_key(KEY_2)

	if customization_overlay.visible:
		push_error("FAIL: 머리종류 선택 후에도 커스터마이징 오버레이가 사라지지 않음")
		ok = false
	if not tutorial_overlay.visible:
		push_error("FAIL: 커스터마이징 후 튜토리얼 오버레이로 넘어가지 않음")
		ok = false
	if player.hair_type != "mohawk":
		push_error("FAIL: player.hair_type이 선택한 머리종류로 갱신되지 않음 (실제: %s)" % player.hair_type)
		ok = false

	# FORMAT_RGBA8 텍스처는 채널당 8비트(1/255 단위)로 양자화되므로 완전
	# 일치 대신 근사 비교(허용오차 1/255보다 넉넉한 0.01)를 쓴다.
	var image: Image = player.sprite.texture.get_image()
	var skin_pixel: Color = image.get_pixel(0, 0)
	var skin_close := (
		absf(skin_pixel.r - expected_skin.r) < 0.01
		and absf(skin_pixel.g - expected_skin.g) < 0.01
		and absf(skin_pixel.b - expected_skin.b) < 0.01
	)
	if not skin_close:
		push_error("FAIL: 플레이어 스프라이트 (0,0) 픽셀이 선택한 피부색이 아님 (실제: %s)" % [skin_pixel])
		ok = false

	# 눈은 EYE_LEFT_X=[8,11), EYE_ROWS=[10,13) 범위에 그려진다(player.gd 참고).
	var eye_pixel: Color = image.get_pixel(9, 11)
	var eye_close := (
		absf(eye_pixel.r - expected_eye.r) < 0.01
		and absf(eye_pixel.g - expected_eye.g) < 0.01
		and absf(eye_pixel.b - expected_eye.b) < 0.01
	)
	if not eye_close:
		push_error("FAIL: 플레이어 스프라이트 눈 픽셀이 선택한 눈색이 아님 (실제: %s)" % [eye_pixel])
		ok = false

	_clean_saves()

	if ok:
		print("HEADLESS_CUSTOMIZATION_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_CUSTOMIZATION_TEST: FAIL")
		quit(1)
