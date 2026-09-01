extends SceneTree

# 헤드리스 환경에서 "등급별 보상 차등"을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/grade_reward_headless_test.gd
#
# status.md #41/#42가 "남은 제약"으로 남긴 대로, 지금까지는 등급이 높을수록
# 채집/사냥이 어려워지기만 할 뿐 보상은 항상 x1로 고정돼 있었다. 이번 세션은
# tree.gd/fish.gd/plant.gd/animal.gd의 보상 수량을 grade와 같은 값으로 맞췄다.
# 이 테스트는 Main.tscn에 이미 배치된 등급 2 개체(Tree2/Fish2/Plant2/Animal2)를
# 대상으로, 등급 1 개체(다른 테스트가 이미 검증)와 달리 보상이 x2로 나오는지
# 확인한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var inventory_label: Label = main.get_node("UI/InventoryLabel")
	var ok := true

	# --- 등급 2 나무: 통나무 x2가 나와야 한다 ---
	var tree2: Area2D = main.get_node("Tree2")
	player.equip("tool", "도끼", 2)
	player.global_position = tree2.global_position
	for i in range(5):
		await physics_frame
	for i in range(tree2.grade):
		Input.action_press("fire")
		await process_frame
		Input.action_release("fire")
		await process_frame

	if is_instance_valid(tree2) and tree2.is_inside_tree():
		push_error("FAIL: 등급만큼 채집했는데도 등급 2 나무가 남아있음")
		ok = false
	if not inventory_label.text.contains("통나무: 2"):
		push_error("FAIL: 등급 2 나무 채집 후 인벤토리에 기대한 값(통나무: 2)이 없음 (실제: %s)" % inventory_label.text)
		ok = false

	# --- 등급 2 물고기: 물고기 x2가 나와야 한다 ---
	var fish2: Area2D = main.get_node("Fish2")
	player.equip("rod", "낚싯대", 2)
	player.global_position = fish2.global_position
	for i in range(5):
		await physics_frame
	for i in range(fish2.grade):
		Input.action_press("fire")
		await process_frame
		Input.action_release("fire")
		await process_frame

	if is_instance_valid(fish2) and fish2.is_inside_tree():
		push_error("FAIL: 등급만큼 낚았는데도 등급 2 물고기가 남아있음")
		ok = false
	if not inventory_label.text.contains("물고기: 2"):
		push_error("FAIL: 등급 2 물고기 낚시 후 인벤토리에 기대한 값(물고기: 2)이 없음 (실제: %s)" % inventory_label.text)
		ok = false

	# --- 등급 2 식물: 채소 x2가 나와야 한다 ---
	var plant2: Area2D = main.get_node("Plant2")
	player.equip("sickle", "낫", 2)
	player.global_position = plant2.global_position
	for i in range(5):
		await physics_frame
	for i in range(plant2.grade):
		Input.action_press("fire")
		await process_frame
		Input.action_release("fire")
		await process_frame

	if is_instance_valid(plant2) and plant2.is_inside_tree():
		push_error("FAIL: 등급만큼 채집했는데도 등급 2 식물이 남아있음")
		ok = false
	if not inventory_label.text.contains("채소: 2"):
		push_error("FAIL: 등급 2 식물 채집 후 인벤토리에 기대한 값(채소: 2)이 없음 (실제: %s)" % inventory_label.text)
		ok = false

	# --- 등급 2 동물: 사냥하면 고기 x2가 나와야 한다 ---
	# inbox.md #4 2번(status.md #49)로 동물 공격 입력이 ui_accept에서
	# fire(+ammo_type="normal")로 바뀌었다(나무/식물/물고기도 inbox #7 2번으로
	# 같은 fire를 쓴다). 7회 발사가 필요해 기본 탄창(6발)을
	# 넘으므로, 탄약 소모가 아니라 보상 수량을 검증하는 이 테스트에서는
	# 넉넉히 채워둔다.
	var animal2: Area2D = main.get_node("Animal2")
	player.equip("tool", "도끼", 2)
	player.ammo_type = "normal"
	player.current_ammo = 999
	# ATTACK_DAMAGE(31) 기준 200 체력을 없애려면 7회 공격이 필요하다(31*7=217).
	for i in range(7):
		player.global_position = animal2.global_position
		for j in range(5):
			await physics_frame
		if not is_instance_valid(animal2) or not animal2.is_inside_tree():
			break
		Input.action_press("fire")
		await process_frame
		Input.action_release("fire")
		await process_frame
		var wait_frames := 0
		while is_instance_valid(animal2) and animal2.is_fleeing and wait_frames < 120:
			await physics_frame
			wait_frames += 1

	if is_instance_valid(animal2) and animal2.is_inside_tree():
		push_error("FAIL: 7회 공격 후에도 등급 2 동물이 사망하지 않음")
		ok = false
	if not inventory_label.text.contains("고기: 2"):
		push_error("FAIL: 등급 2 동물 사냥 후 인벤토리에 기대한 값(고기: 2)이 없음 (실제: %s)" % inventory_label.text)
		ok = false

	if ok:
		print("HEADLESS_GRADE_REWARD_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_GRADE_REWARD_TEST: FAIL")
		quit(1)
