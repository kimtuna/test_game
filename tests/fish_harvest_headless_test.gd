extends SceneTree

# 헤드리스 환경에서 물고기 낚시 상호작용을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/fish_harvest_headless_test.gd
# tree_harvest_headless_test.gd와 동일한 패턴 — Player를 Fish 위치로 이동시켜
# Area2D 상호작용 범위에 들어가게 한 뒤, fire(좌클릭) 입력을 인위적으로 눌러
# 물고기가 실제로 사라지고(harvested) 인벤토리 라벨에 반영되는지 확인한다.
# inbox.md #7 2번으로 채집 트리거가 ui_accept에서 fire로 바뀌었다.
# 추가로, tree.gd/animal.gd와 동일한 장비 게이팅 패턴이 fish.gd에도 실제로
# 연결됐는지 확인하기 위해 rod 장비를 해제한 상태에서는 낚시가 되지 않는
# 케이스도 함께 검증한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var fish: Area2D = main.get_node("Fish")

	var ok := true

	# 범위 밖일 때는 fire를 눌러도 물고기가 사라지지 않아야 한다.
	player.global_position = fish.global_position + Vector2(500, 500)
	await physics_frame
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame
	if not is_instance_valid(fish) or fish.is_inside_tree() == false:
		push_error("FAIL: 범위 밖인데도 물고기가 낚임")
		ok = false

	# 낚싯대를 해제한 상태에서는 범위 안이어도 낚시가 되지 않아야 한다.
	player.unequip("rod")
	player.global_position = fish.global_position
	for i in range(5):
		await physics_frame

	if fish.player_nearby == null:
		push_error("FAIL: Player가 Fish의 상호작용 범위에 들어갔는데도 player_nearby가 설정되지 않음")
		ok = false

	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame

	if not is_instance_valid(fish) or fish.is_inside_tree() == false:
		push_error("FAIL: 낚싯대 없이도 물고기가 낚임")
		ok = false

	# 낚싯대를 다시 장착하면 낚시가 성립해야 한다.
	player.equip("rod", "낚싯대", 1)
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame

	if is_instance_valid(fish) and fish.is_inside_tree():
		push_error("FAIL: 범위 안에서 낚싯대를 장착하고 fire를 눌렀는데도 물고기가 사라지지 않음")
		ok = false

	var inventory_label: Label = main.get_node("UI/InventoryLabel")
	if not inventory_label.text.contains("물고기: 1"):
		push_error("FAIL: 낚시 후 인벤토리 라벨에 기대한 값(물고기: 1)이 없음 (실제: %s)" % inventory_label.text)
		ok = false

	if ok:
		print("HEADLESS_FISH_HARVEST_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_FISH_HARVEST_TEST: FAIL")
		quit(1)
