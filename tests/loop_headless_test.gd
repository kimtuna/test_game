extends SceneTree

# 헤드리스(비대화형) 환경에서 핵심 루프(이동 → 수집 → 점수 → 클리어)를
# 실제로 Main.tscn을 실행해 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/loop_headless_test.gd
# player를 각 아이템 위치로 순간이동시켜 실제 Area2D 충돌을 물리 프레임으로 발생시킨다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: Node2D = main.get_node("Player")
	var items := get_nodes_in_group("items").duplicate()

	if items.is_empty():
		_fail("아이템이 하나도 없음 (Main.tscn 배치 확인 필요)")
		return

	for item in items:
		if not is_instance_valid(item):
			continue
		player.global_position = item.global_position
		for i in range(5):
			await physics_frame

	await process_frame

	var ok := true
	var score_label: Label = main.get_node("UI/ScoreLabel")
	var clear_label: Label = main.get_node("UI/ClearLabel")

	var expected_score_text := "Score: %d / %d" % [main.total_items, main.total_items]
	if score_label.text != expected_score_text:
		push_error("FAIL: ScoreLabel = '%s', expected '%s'" % [score_label.text, expected_score_text])
		ok = false

	if not clear_label.visible:
		push_error("FAIL: ClearLabel이 표시되지 않음")
		ok = false

	var remaining := get_nodes_in_group("items")
	if remaining.size() != 0:
		push_error("FAIL: 아이템이 %d개 남아있음 (전부 수집되어야 함)" % remaining.size())
		ok = false

	if ok:
		print("HEADLESS_LOOP_TEST: PASS (score=%s, clear=%s)" % [score_label.text, clear_label.visible])
		quit(0)
	else:
		print("HEADLESS_LOOP_TEST: FAIL")
		quit(1)

func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	print("HEADLESS_LOOP_TEST: FAIL")
	quit(1)
