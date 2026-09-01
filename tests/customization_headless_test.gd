extends SceneTree

# 헤드리스 환경에서 캐릭터 커스터마이징(외형 색 선택) 오버레이를 검증하는
# 통합 테스트.
# 실행: godot --headless --path . --script res://tests/customization_headless_test.gd
# status.md #31에서 슬롯 선택 오버레이가 커스터마이징보다 먼저 뜨도록
# 바뀌어, 이 테스트도 먼저 슬롯(키 1)을 고르는 단계를 흉내낸다.
# (1) 슬롯을 고르면(처음 고르는 슬롯이라) 커스터마이징 오버레이가 보이고
# 튜토리얼은 아직 가려져 있는지, (2) 색 선택 키(2: 빨강)를 누르면 플레이어
# 스프라이트 텍스처가 해당 색으로 바뀌고 오버레이가 사라지는지, (3) 튜토리얼
# 오버레이로 자연스럽게 넘어가는지 확인한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var slot_overlay: Control = main.get_node("UI/SlotOverlay")
	var customization_overlay: Control = main.get_node("UI/CustomizationOverlay")
	var tutorial_overlay: Control = main.get_node("UI/TutorialOverlay")
	var player := main.get_node("Player")

	var ok := true

	var slot_event := InputEventKey.new()
	slot_event.keycode = KEY_1
	slot_event.pressed = true
	Input.parse_input_event(slot_event)
	await process_frame

	if slot_overlay.visible:
		push_error("FAIL: 슬롯 선택 후에도 슬롯 오버레이가 사라지지 않음")
		ok = false

	if not customization_overlay.visible:
		push_error("FAIL: 처음 고른 슬롯인데 커스터마이징 오버레이가 보이지 않음")
		ok = false

	if tutorial_overlay.visible:
		push_error("FAIL: 커스터마이징 전인데 튜토리얼 오버레이가 이미 보임")
		ok = false

	var key_event := InputEventKey.new()
	key_event.keycode = KEY_2
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await process_frame

	if customization_overlay.visible:
		push_error("FAIL: 색 선택 후에도 커스터마이징 오버레이가 사라지지 않음")
		ok = false

	if not tutorial_overlay.visible:
		push_error("FAIL: 커스터마이징 후 튜토리얼 오버레이로 넘어가지 않음")
		ok = false

	var expected_color := Color(0.9, 0.2, 0.2)
	if player.body_color != expected_color:
		push_error("FAIL: player.body_color가 선택한 색으로 갱신되지 않음 (실제: %s)" % [player.body_color])
		ok = false

	# FORMAT_RGBA8 텍스처는 채널당 8비트(1/255 단위)로 양자화되므로 완전
	# 일치 대신 근사 비교(허용오차 1/255보다 넉넉한 0.01)를 쓴다 - 예: 0.9는
	# 정확히 표현되지 못하고 229/255 ≈ 0.898로 저장된다.
	var image: Image = player.sprite.texture.get_image()
	var pixel: Color = image.get_pixel(0, 0)
	var close_enough := (
		absf(pixel.r - expected_color.r) < 0.01
		and absf(pixel.g - expected_color.g) < 0.01
		and absf(pixel.b - expected_color.b) < 0.01
	)
	if not close_enough:
		push_error("FAIL: 플레이어 스프라이트 텍스처 픽셀이 선택한 색이 아님 (실제: %s)" % [pixel])
		ok = false

	if ok:
		print("HEADLESS_CUSTOMIZATION_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_CUSTOMIZATION_TEST: FAIL")
		quit(1)
