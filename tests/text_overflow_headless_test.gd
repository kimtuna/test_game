extends SceneTree

# CLAUDE.md 규칙 4의 자동검사 QA 항목 중 `text_overflow_check` 도구
# (inbox.md #17 — 4개 자동검사 도구 중 구현 난이도가 가장 낮다고 추천된 것부터
# 골랐다). "Label/RichTextLabel 등 UI 텍스트가 화면 또는 소속 컨테이너 밖으로
# 넘어가지 않는가"를 사람이 매번 스크린샷을 보지 않고 기계적으로 판정한다.
# 실행: godot --headless --path . --script res://tests/text_overflow_headless_test.gd
#
# 판정 방법 (Control 계열 노드: Label/RichTextLabel/Button 전부):
# 1. 소속 컨테이너 오버플로 — Godot Control은 anchor로 계산한 rect가 자신의
#    get_minimum_size()(텍스트를 담는 데 필요한 최소 크기)보다 작으면 그
#    rect를 무시하고 자동으로 minimum_size까지 스스로 커진다(clip_text=true가
#    아닌 한 절대 그보다 작아지지 않는다 — 실측으로 확인함, 아래 CAUTION
#    참고). 즉 "자기 rect vs 자기 min_size" 비교는 거의 항상 통과하는
#    무의미한 검사가 된다 — 실제로 눈에 보이는 문제는 그렇게 커진 라벨이
#    "자신을 담고 있어야 할 부모 박스"(Hotbar 슬롯 Panel, VBoxContainer 등)
#    밖으로 삐져나오는 것이다. 그래서 이 도구는 각 노드의 rect를 **부모
#    Control의 rect**와 비교한다 — 부모 로컬 좌표계에서 자식의 rect가
#    (0,0)~부모.size 범위를 벗어나면 오버플로로 판정한다.
# 2. 화면 오버플로 — get_global_rect()가 GameSettings.BASE_RESOLUTION 기준
#    논리 화면(콘텐츠 스케일 좌표계, game_settings.gd 참고) 밖으로 나가는지.
#
# 정적으로 씬에 적힌 텍스트뿐 아니라, 인벤토리/장비/포획 라벨처럼 실제
# 플레이로 값이 자라나는 라벨도 inventory_headless_test.gd와 같은 방식으로
# main._on_harvested()/_on_captured()를 여러 번 호출해 "오래 플레이한 뒤"
# 상태를 흉내내 함께 검사한다 — 초기 빈 상태만 보면 이런 라벨은 항상
# 통과하지만, 실제로 문제가 생기는 건 내용이 쌓였을 때이기 때문이다.

const EPSILON := 0.5

var failures: Array[String] = []

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

func _is_under_canvas_layer(node: Node) -> bool:
	var current: Node = node.get_parent()
	while current != null:
		if current is CanvasLayer:
			return true
		current = current.get_parent()
	return false

func _scan(node: Node, scene_label: String, base_resolution: Vector2i) -> void:
	# 현재 화면에 실제로 보이지 않는 가지는 건너뛴다 — Godot Container(VBox/
	# HBox/GridContainer 등)는 실제로 화면에 보여야만 sort_children이 온전히
	# 반영되는 경우가 있어(ResolutionOption에서 실측 확인, 아래 CAUTION 참고),
	# 숨겨진 채로 검사하면 "아직 크기가 확정 안 됨"을 "텍스트가 넘친다"로
	# 오탐할 수 있다. 대신 이 스크립트는 각 오버레이를 실제로 열어본 뒤
	# (`_scan_forced_visible` 또는 실제 버튼 클릭) 별도로 검사하므로, 닫힌
	# 상태를 건너뛰어도 검사 범위가 줄지 않는다.
	if node is Control and not node.is_visible_in_tree():
		return
	if node is Label or node is RichTextLabel or node is Button:
		_check_container_overflow(node, scene_label)
		# 화면 경계 검사는 CanvasLayer(고정 UI) 아래에 있는 노드에만 적용한다.
		# GradeLabel/HealthLabel처럼 Tree/Animal/Fish/Plant 같은 Node2D 월드
		# 오브젝트에 직접 매달린 라벨은 카메라를 따라 화면 밖 세계 좌표에도
		# 정상적으로 존재할 수 있으므로(섬이 한 화면보다 넓다), "화면 밖으로
		# 넘어감"의 대상이 아니다 — 이런 라벨에도 소속 컨테이너 오버플로 검사는
		# 그대로 적용된다(칸이 너무 작아 텍스트가 잘리는 문제는 위치와 무관).
		if _is_under_canvas_layer(node):
			_check_screen_overflow(node, scene_label, base_resolution)
	for child in node.get_children():
		_scan(child, scene_label, base_resolution)

func _check_container_overflow(ctrl: Control, scene_label: String) -> void:
	var parent := ctrl.get_parent()
	if not (parent is Control):
		return
	# ColorRect 배경(Background)처럼 오버레이 전체를 덮는 장식용 부모는 자식을
	# "담는 박스"로 볼 수 없어(자기 자신이 화면 전체 크기) 검사 대상에서
	# 제외한다 — 실제로 텍스트를 담아야 하는 박스(Panel/Container)만 본다.
	if parent is ColorRect:
		return
	var parent_size: Vector2 = parent.size
	var ctrl_rect := Rect2(ctrl.position, ctrl.size)
	if ctrl_rect.position.x < -EPSILON or ctrl_rect.position.y < -EPSILON \
			or ctrl_rect.position.x + ctrl_rect.size.x > parent_size.x + EPSILON \
			or ctrl_rect.position.y + ctrl_rect.size.y > parent_size.y + EPSILON:
		failures.append("%s: %s(%s) 소속 컨테이너(%s, 크기 %s) 밖으로 넘어감 rect=%s — text=\"%s\"" % [
			scene_label, ctrl.name, ctrl.get_path(), parent.name, parent_size, ctrl_rect, _short_text(ctrl)])

func _check_screen_overflow(ctrl: Control, scene_label: String, base_resolution: Vector2i) -> void:
	var grect: Rect2 = ctrl.get_global_rect()
	if grect.position.x < -EPSILON or grect.position.y < -EPSILON \
			or grect.position.x + grect.size.x > base_resolution.x + EPSILON \
			or grect.position.y + grect.size.y > base_resolution.y + EPSILON:
		failures.append("%s: %s(%s) 화면 경계(%dx%d)를 벗어남 rect=%s" % [
			scene_label, ctrl.name, ctrl.get_path(), base_resolution.x, base_resolution.y, grect])

func _scan_forced_visible(main: Node, overlay_path: String, scene_label: String, base_resolution: Vector2i) -> void:
	# ResolutionOption에서 확인한 것과 같은 이유(VBoxContainer/GridContainer는
	# 실제로 화면에 보여야 sort_children이 온전히 반영되는 경우가 있음) —
	# PauseOverlay/InventoryOverlay도 각각 VBoxContainer/HBoxContainer/
	# GridContainer를 쓰므로, 숨겨진 채 스캔하지 않고 강제로 보이게 만든 뒤
	# 스캔하고 원래 상태로 되돌린다.
	var overlay: Control = main.get_node(overlay_path)
	var was_visible: bool = overlay.visible
	overlay.visible = true
	await process_frame
	await process_frame
	_scan(overlay, scene_label, base_resolution)
	overlay.visible = was_visible
	await process_frame

func _short_text(ctrl: Control) -> String:
	var text: String = ""
	if ctrl is Label:
		text = ctrl.text
	elif ctrl is RichTextLabel:
		text = ctrl.text
	elif ctrl is Button:
		text = ctrl.text
	text = text.replace("\n", " / ")
	if text.length() > 40:
		text = text.substr(0, 40) + "..."
	return text

func _initialize() -> void:
	_clean_saves()
	var base_resolution: Vector2i = Vector2i(1152, 648)

	# 1) MainMenu.tscn — 시작 패널 + 설정 패널(해상도 드롭다운 등) 모두
	# 시각 여부와 무관하게 anchor 기반 rect가 이미 계산돼 있어 그대로 스캔한다.
	var main_menu: Control = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(main_menu)
	current_scene = main_menu
	await process_frame
	await process_frame
	var game_settings: Node = root.get_node("GameSettings")
	base_resolution = game_settings.BASE_RESOLUTION
	_scan(main_menu, "MainMenu.tscn(시작 패널)", base_resolution)

	# 설정 패널은 기본적으로 visible=false라, 숨겨진 채로 스캔하면 일부
	# 컨테이너(VBoxContainer 등)가 아직 자식 크기를 채우지 못했을 수 있다
	# (Godot Container는 화면에 실제로 보여야 sort_children이 온전히 반영되는
	# 경우가 있다) — 실제 사용자가 보는 상태와 동일하게 설정 버튼을 눌러
	# 연 뒤 다시 스캔해서, "숨겨진 레이아웃 미확정" 오탐과 "실제 텍스트
	# 오버플로"를 구분한다.
	main_menu.get_node("MainPanel/SettingsButton").emit_signal("pressed")
	await process_frame
	await process_frame
	_scan(main_menu, "MainMenu.tscn(설정 패널 열림)", base_resolution)

	main_menu.queue_free()
	await process_frame

	# 2) Main.tscn — 슬롯 선택 -> 커스터마이징 3단계 -> 튜토리얼 닫기로 실제
	# 플레이 상태까지 진행한 뒤(다른 헤드리스 테스트들과 동일한 절차), 정적으로
	# 씬에 적힌 라벨(SlotLabel/CustomizationLabel/TutorialLabel/PauseLabel/
	# InventoryTitle/WearableLabel/HotbarLabel 등)을 먼저 스캔한다.
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	# 슬롯/커스터마이징/튜토리얼 오버레이는 실제 플레이에서 순서대로 한 번씩만
	# 보이고 이후 다시 열리지 않는 온보딩 화면이라, 흐름을 다 지나기 전에
	# (기본 상태 그대로) 먼저 열어서 검사해둔다. SlotOverlay는 이미
	# visible=true가 기본값이라 그대로 스캔해도 되지만, 일관성을 위해 나머지와
	# 같은 강제 표시 경로를 쓴다.
	await _scan_forced_visible(main, "UI/SlotOverlay", "Main.tscn(슬롯 선택 화면)", base_resolution)
	await _scan_forced_visible(main, "UI/CustomizationOverlay", "Main.tscn(커스터마이징 화면, 1단계 기본 텍스트)", base_resolution)
	await _scan_forced_visible(main, "UI/TutorialOverlay", "Main.tscn(튜토리얼 화면)", base_resolution)

	_press_key(KEY_1)
	await process_frame
	for i in range(3):
		_press_key(KEY_1)
		await process_frame
	_press_key(KEY_SPACE)
	await process_frame

	_scan(main, "Main.tscn(초기 상태)", base_resolution)

	# PauseOverlay/InventoryOverlay는 플레이 도중엔 기본적으로 닫혀 있어
	# _scan(main, ...)만으로는 그 안의 Container들이 실제로 보였을 때와 같은
	# 크기를 갖는지 보장할 수 없다 — 위 MainMenu 설정 패널과 동일한 이유로
	# 강제로 열어서 각각 스캔한다.
	await _scan_forced_visible(main, "UI/PauseOverlay", "Main.tscn(일시정지 메뉴 열림)", base_resolution)
	await _scan_forced_visible(main, "UI/InventoryOverlay", "Main.tscn(인벤토리 열림, 초기 상태)", base_resolution)

	# 3) 오래 플레이한 뒤를 흉내낸 상태 — 실제 자원 4종을 큰 수량으로 채우고
	# (장비 자동 승급도 함께 트리거됨), inventory_headless_test.gd와 동일한
	# 방식으로 자원 5종을 추가로 채워 9칸을 꽉 채운 뒤, 포획 기록도 여러 번
	# 쌓는다 — 이런 라벨들은 초기 빈 상태에서는 항상 통과하고, 실제로
	# 오버플로가 드러나는 건 내용이 쌓였을 때이기 때문이다.
	main._on_harvested("통나무", 9999)
	main._on_harvested("고기", 9999)
	main._on_harvested("물고기", 9999)
	main._on_harvested("채소", 9999)
	for i in range(1, 6):
		main._on_harvested("자원%d" % i, 9999)
	for i in range(20):
		main._on_captured("사슴")

	var player := get_first_node_in_group("player")
	if player != null:
		for i in range(5):
			player.set_hotbar_item(i, "마취총")

	main._update_inventory_grid()
	main._update_wearable_slots()
	main._update_hotbar_ui()
	main._update_capture_label()
	main._update_equipment_label()
	await process_frame
	await process_frame

	_scan(main, "Main.tscn(장기 플레이 상태 흉내)", base_resolution)
	await _scan_forced_visible(main, "UI/InventoryOverlay", "Main.tscn(인벤토리 열림, 장기 플레이 상태 흉내)", base_resolution)

	main.queue_free()
	await process_frame
	_clean_saves()

	if failures.is_empty():
		print("HEADLESS_TEXT_OVERFLOW_TEST: PASS")
		quit(0)
	else:
		for f in failures:
			push_error("FAIL: %s" % f)
		print("HEADLESS_TEXT_OVERFLOW_TEST: FAIL (%d건)" % failures.size())
		quit(1)
