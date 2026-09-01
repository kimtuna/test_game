extends SceneTree

# 헤드리스 환경에서 나무 채집 상호작용을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/tree_harvest_headless_test.gd
# Player를 Tree 위치로 이동시켜 Area2D 상호작용 범위에 들어가게 한 뒤,
# ui_accept 입력을 인위적으로 눌러 나무가 실제로 사라지는지(harvested 그룹에서
# 제거되는지) 확인한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var tree: Area2D = main.get_node("Tree")

	var ok := true

	# 아직 범위 밖일 때는 ui_accept를 눌러도 나무가 사라지지 않아야 한다.
	player.global_position = tree.global_position + Vector2(500, 500)
	await physics_frame
	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame
	if not is_instance_valid(tree) or tree.is_inside_tree() == false:
		push_error("FAIL: 범위 밖인데도 나무가 채집됨")
		ok = false

	# Player를 나무 위치로 이동시켜 상호작용 범위에 들어가게 한다.
	player.global_position = tree.global_position
	for i in range(5):
		await physics_frame

	if tree.player_nearby == null:
		push_error("FAIL: Player가 Tree의 상호작용 범위에 들어갔는데도 player_nearby가 설정되지 않음")
		ok = false

	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame

	if is_instance_valid(tree) and tree.is_inside_tree():
		push_error("FAIL: 범위 안에서 ui_accept를 눌렀는데도 나무가 사라지지 않음")
		ok = false

	if ok:
		print("HEADLESS_TREE_HARVEST_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_TREE_HARVEST_TEST: FAIL")
		quit(1)
