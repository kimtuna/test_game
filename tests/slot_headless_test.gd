extends SceneTree

# 헤드리스 환경에서 캐릭터 슬롯 선택/전환의 최소 동작을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/slot_headless_test.gd
# design.md의 "계정당 3개 캐릭터 슬롯"을 검증한다.
# (1) 시작 시 슬롯 오버레이만 보이는지, (2) 처음 고르는 슬롯(1)은 커스터마이징
# 으로 이어지는지, (3) 색을 고르면 튜토리얼로 이어지고 색이 저장되는지,
# (4) 튜토리얼을 닫은 뒤에도(inbox.md #7 1번 — 게임 중 Tab으로 슬롯 오버레이를
# 다시 여는 기능은 제거됐다) 저장 파일이 남아, 새 인스턴스(=새 실행)에서
# 슬롯 1을 다시 고르면 커스터마이징 없이 저장해둔 색이 즉시 적용되는지,
# (5) 같은 새 실행에서 처음 고르는 슬롯(2)은 커스터마이징으로 이어지되
# 튜토리얼은 다시 뜨지 않는지 확인한다.

func _press_key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame

# 이전 실행(수동 플레이 포함)이 남긴 저장 파일이 있으면 "처음 고르는 슬롯"
# 전제가 깨지므로, 시작 전에 지워 결정론을 지키고 끝에도 지워 이후 실행에
# 영향을 남기지 않는다.
func _clean_saves() -> void:
	for i in range(1, 4):
		var path := "user://saves/slot_%d.save" % i
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if FileAccess.file_exists("user://saves/tutorial_seen.flag"):
		DirAccess.remove_absolute("user://saves/tutorial_seen.flag")

func _initialize() -> void:
	_clean_saves()
	var ok := true

	# 1단계: 첫 실행 — 슬롯 1을 처음 고르고 빨강으로 커스터마이징한다.
	var main1: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main1)
	await process_frame

	var slot_overlay1: Control = main1.get_node("UI/SlotOverlay")
	var customization_overlay1: Control = main1.get_node("UI/CustomizationOverlay")
	var tutorial_overlay1: Control = main1.get_node("UI/TutorialOverlay")
	var player1 := main1.get_node("Player")

	if not slot_overlay1.visible:
		push_error("FAIL: 시작 시 슬롯 오버레이가 보이지 않음")
		ok = false
	if customization_overlay1.visible or tutorial_overlay1.visible:
		push_error("FAIL: 시작 시 슬롯 오버레이 외에 다른 오버레이가 보임")
		ok = false

	await _press_key(KEY_1)
	if slot_overlay1.visible or not customization_overlay1.visible:
		push_error("FAIL: 슬롯 1을 처음 골랐는데 커스터마이징으로 이어지지 않음")
		ok = false

	await _press_key(KEY_2)
	if customization_overlay1.visible or not tutorial_overlay1.visible:
		push_error("FAIL: 색 선택 후 튜토리얼로 이어지지 않음")
		ok = false
	var red := Color(0.9, 0.2, 0.2)
	if player1.body_color != red:
		push_error("FAIL: 슬롯 1의 색이 선택한 빨강으로 저장되지 않음 (실제: %s)" % [player1.body_color])
		ok = false

	await _press_key(KEY_SPACE)
	if tutorial_overlay1.visible:
		push_error("FAIL: 키 입력 후에도 튜토리얼 오버레이가 사라지지 않음")
		ok = false

	# 게임 중 슬롯을 바꾸는 기능이 없으므로(inbox.md #7 1번), 첫 인스턴스를
	# 완전히 없애 새로 실행한 것과 같은 상황을 만든다.
	main1.queue_free()
	await process_frame
	await process_frame

	# 2단계: 두 번째 실행 — 슬롯 2를 처음 고르면 커스터마이징으로 이어지되,
	# 이미 튜토리얼을 본 뒤이므로 다시 뜨면 안 된다.
	var main2: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main2)
	await process_frame

	var slot_overlay2: Control = main2.get_node("UI/SlotOverlay")
	var customization_overlay2: Control = main2.get_node("UI/CustomizationOverlay")
	var tutorial_overlay2: Control = main2.get_node("UI/TutorialOverlay")
	var player2 := main2.get_node("Player")

	await _press_key(KEY_2)
	if slot_overlay2.visible or not customization_overlay2.visible:
		push_error("FAIL: 슬롯 2를 처음 골랐는데 커스터마이징으로 이어지지 않음")
		ok = false

	await _press_key(KEY_3)
	if customization_overlay2.visible:
		push_error("FAIL: 슬롯 2 색 선택 후에도 커스터마이징 오버레이가 남아있음")
		ok = false
	if tutorial_overlay2.visible:
		push_error("FAIL: 이미 튜토리얼을 본 뒤인데 슬롯 전환 시 튜토리얼이 다시 뜸")
		ok = false
	var green := Color(0.25, 0.75, 0.3)
	if player2.body_color != green:
		push_error("FAIL: 슬롯 2의 색이 선택한 초록으로 저장되지 않음 (실제: %s)" % [player2.body_color])
		ok = false

	main2.queue_free()
	await process_frame
	await process_frame

	# 3단계: 세 번째 실행 — 이미 골랐던 슬롯 1을 다시 고르면, 커스터마이징 없이
	# 저장해둔 빨강이 즉시 적용돼야 한다.
	var main3: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main3)
	await process_frame

	var slot_overlay3: Control = main3.get_node("UI/SlotOverlay")
	var customization_overlay3: Control = main3.get_node("UI/CustomizationOverlay")
	var player3 := main3.get_node("Player")

	await _press_key(KEY_1)
	if slot_overlay3.visible or customization_overlay3.visible:
		push_error("FAIL: 이미 골랐던 슬롯 1을 다시 골랐는데 오버레이가 남아있음")
		ok = false
	if player3.body_color != red:
		push_error("FAIL: 슬롯 1을 다시 골랐는데 저장해둔 빨강이 적용되지 않음 (실제: %s)" % [player3.body_color])
		ok = false

	_clean_saves()

	if ok:
		print("HEADLESS_SLOT_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_SLOT_TEST: FAIL")
		quit(1)
