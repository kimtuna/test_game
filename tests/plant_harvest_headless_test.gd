extends SceneTree

# 헤드리스 환경에서 식물 채집 상호작용을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/plant_harvest_headless_test.gd
# tree_harvest_headless_test.gd/fish_harvest_headless_test.gd와 동일한 패턴
# (범위 밖 무반응 -> 범위 안 이동 -> 상호작용(fire, inbox #7 2번) -> 인벤토리
# 반영 확인)에, plant.gd가
# 나무/물고기와 동일한 장비 게이팅 패턴(이번 세션에서 새로 연결한 "sickle" 슬롯)을
# 실제로 따르는지 확인하기 위해 낫을 해제한 상태에서는 채집이 되지 않는 케이스도
# 함께 검증한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var plant: Area2D = main.get_node("Plant")

	var ok := true

	# 아직 범위 밖일 때는 fire를 눌러도 식물이 사라지지 않아야 한다.
	player.global_position = plant.global_position + Vector2(500, 500)
	await physics_frame
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame
	if not is_instance_valid(plant) or plant.is_inside_tree() == false:
		push_error("FAIL: 범위 밖인데도 식물이 채집됨")
		ok = false

	# 낫을 해제한 상태에서는 범위 안이어도 채집이 되지 않아야 한다.
	player.unequip("sickle")
	player.global_position = plant.global_position
	for i in range(5):
		await physics_frame

	if plant.player_nearby == null:
		push_error("FAIL: Player가 Plant의 상호작용 범위에 들어갔는데도 player_nearby가 설정되지 않음")
		ok = false

	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame

	if not is_instance_valid(plant) or plant.is_inside_tree() == false:
		push_error("FAIL: 낫 없이도 식물이 채집됨")
		ok = false

	# 낫을 다시 장착하면 채집이 성립해야 한다.
	player.equip("sickle", "낫", 1)
	Input.action_press("fire")
	await process_frame
	Input.action_release("fire")
	await process_frame

	if is_instance_valid(plant) and plant.is_inside_tree():
		push_error("FAIL: 범위 안에서 낫을 장착하고 fire를 눌렀는데도 식물이 사라지지 않음")
		ok = false

	var inventory_label: Label = main.get_node("UI/InventoryLabel")
	if not inventory_label.text.contains("채소: 1"):
		push_error("FAIL: 채집 후 인벤토리 라벨에 기대한 값(채소: 1)이 없음 (실제: %s)" % inventory_label.text)
		ok = false

	if ok:
		print("HEADLESS_PLANT_HARVEST_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_PLANT_HARVEST_TEST: FAIL")
		quit(1)
