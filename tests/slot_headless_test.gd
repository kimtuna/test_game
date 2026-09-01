extends SceneTree

# 헤드리스 환경에서 캐릭터 슬롯 선택/전환의 최소 동작을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/slot_headless_test.gd
# design.md의 "계정당 3개 캐릭터 슬롯"의 첫 조각(저장 없이, 세션 중 슬롯별
# 외형을 기억하는 것까지만 다룸)을 검증한다.
# (1) 시작 시 슬롯 오버레이만 보이는지, (2) 처음 고르는 슬롯(1)은 커스터마이징
# 으로 이어지는지, (3) 색을 고르면 튜토리얼로 이어지고 색이 저장되는지,
# (4) 튜토리얼을 닫은 뒤 Tab으로 슬롯 오버레이를 다시 열 수 있는지,
# (5) 처음 고르는 슬롯(2)은 다시 커스터마이징으로 이어지되 튜토리얼은 다시
# 뜨지 않는지, (6) Tab으로 이미 골랐던 슬롯(1)으로 돌아가면 커스터마이징
# 없이 저장해둔 색이 즉시 적용되는지 확인한다.

func _press_key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var slot_overlay: Control = main.get_node("UI/SlotOverlay")
	var customization_overlay: Control = main.get_node("UI/CustomizationOverlay")
	var tutorial_overlay: Control = main.get_node("UI/TutorialOverlay")
	var player := main.get_node("Player")

	var ok := true

	if not slot_overlay.visible:
		push_error("FAIL: 시작 시 슬롯 오버레이가 보이지 않음")
		ok = false
	if customization_overlay.visible or tutorial_overlay.visible:
		push_error("FAIL: 시작 시 슬롯 오버레이 외에 다른 오버레이가 보임")
		ok = false

	# 슬롯 1을 처음 선택 -> 커스터마이징으로 이어져야 한다.
	await _press_key(KEY_1)
	if slot_overlay.visible or not customization_overlay.visible:
		push_error("FAIL: 슬롯 1을 처음 골랐는데 커스터마이징으로 이어지지 않음")
		ok = false

	# 빨강(키 2)을 선택 -> 튜토리얼로 이어지고 슬롯 1의 색으로 저장되어야 한다.
	await _press_key(KEY_2)
	if customization_overlay.visible or not tutorial_overlay.visible:
		push_error("FAIL: 색 선택 후 튜토리얼로 이어지지 않음")
		ok = false
	var red := Color(0.9, 0.2, 0.2)
	if player.body_color != red:
		push_error("FAIL: 슬롯 1의 색이 선택한 빨강으로 저장되지 않음 (실제: %s)" % [player.body_color])
		ok = false

	# 튜토리얼을 닫는다(아무 키).
	await _press_key(KEY_SPACE)
	if tutorial_overlay.visible:
		push_error("FAIL: 키 입력 후에도 튜토리얼 오버레이가 사라지지 않음")
		ok = false

	# Tab으로 슬롯 오버레이를 다시 연다.
	await _press_key(KEY_TAB)
	if not slot_overlay.visible:
		push_error("FAIL: Tab을 눌러도 슬롯 오버레이가 다시 열리지 않음")
		ok = false

	# 슬롯 2를 처음 선택 -> 커스터마이징으로 이어지되, 튜토리얼은 다시 뜨면 안 된다.
	await _press_key(KEY_2)
	if slot_overlay.visible or not customization_overlay.visible:
		push_error("FAIL: 슬롯 2를 처음 골랐는데 커스터마이징으로 이어지지 않음")
		ok = false

	# 초록(키 3)을 선택.
	await _press_key(KEY_3)
	if customization_overlay.visible:
		push_error("FAIL: 슬롯 2 색 선택 후에도 커스터마이징 오버레이가 남아있음")
		ok = false
	if tutorial_overlay.visible:
		push_error("FAIL: 이미 튜토리얼을 본 뒤인데 슬롯 전환 시 튜토리얼이 다시 뜸")
		ok = false
	var green := Color(0.25, 0.75, 0.3)
	if player.body_color != green:
		push_error("FAIL: 슬롯 2의 색이 선택한 초록으로 저장되지 않음 (실제: %s)" % [player.body_color])
		ok = false

	# Tab -> 슬롯 1로 돌아가면, 커스터마이징 없이 저장해둔 빨강이 즉시 적용돼야 한다.
	await _press_key(KEY_TAB)
	await _press_key(KEY_1)
	if slot_overlay.visible or customization_overlay.visible:
		push_error("FAIL: 이미 골랐던 슬롯 1로 돌아왔는데 오버레이가 남아있음")
		ok = false
	if player.body_color != red:
		push_error("FAIL: 슬롯 1로 되돌아왔는데 저장해둔 빨강이 적용되지 않음 (실제: %s)" % [player.body_color])
		ok = false

	if ok:
		print("HEADLESS_SLOT_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_SLOT_TEST: FAIL")
		quit(1)
