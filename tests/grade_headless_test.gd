extends SceneTree

# 헤드리스 환경에서 등급(grade) 시스템을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/grade_headless_test.gd
# Main.tscn에 배치된 등급 2 나무(Tree2)와 등급 2 동물(Animal2)을 대상으로,
# 기본 등급(1)보다 채집/사냥에 더 많은 상호작용이 필요한지 확인한다.
# 기존 grade=1 개체(Tree, Animal)는 건드리지 않아 기존 테스트와 겹치지 않는다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var tree2: Area2D = main.get_node("Tree2")
	var animal2: Area2D = main.get_node("Animal2")

	var ok := true

	# --- 등급 2 나무: grade=2이므로 1회 상호작용으로는 채집되지 않아야 한다 ---
	if tree2.grade != 2:
		push_error("FAIL: Tree2의 grade가 2가 아님 (실제: %d)" % tree2.grade)
		ok = false

	player.global_position = tree2.global_position
	for i in range(5):
		await physics_frame

	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame

	if not is_instance_valid(tree2) or not tree2.is_inside_tree():
		push_error("FAIL: 등급 2 나무가 1회 채집으로 사라짐 (grade가 난이도에 반영되지 않음)")
		ok = false

	Input.action_press("ui_accept")
	await process_frame
	Input.action_release("ui_accept")
	await process_frame

	if is_instance_valid(tree2) and tree2.is_inside_tree():
		push_error("FAIL: 등급 2 나무가 2회 채집(grade만큼) 후에도 사라지지 않음")
		ok = false

	# --- 등급 2 동물: 최대 체력이 grade에 비례해 늘어나야 한다 ---
	if animal2.grade != 2 or animal2.max_health != 200:
		push_error("FAIL: Animal2의 grade/max_health가 기대와 다름 (grade=%d, max_health=%d)" % [animal2.grade, animal2.max_health])
		ok = false

	var health_label: Label = animal2.get_node("HealthLabel")
	if health_label.text != "200/200":
		push_error("FAIL: 등급 2 동물의 초기 체력 라벨이 기대한 값(200/200)이 아님 (실제: %s)" % health_label.text)
		ok = false

	# ATTACK_DAMAGE(31) 기준 6회 공격해야 8%(16) 미만인 14/200에 도달한다.
	player.global_position = animal2.global_position
	for i in range(5):
		await physics_frame

	for i in range(6):
		Input.action_press("ui_accept")
		await process_frame
		Input.action_release("ui_accept")
		await process_frame

		var wait_frames := 0
		while animal2.is_fleeing and wait_frames < 120:
			await physics_frame
			wait_frames += 1
		player.global_position = animal2.global_position
		for j in range(5):
			await physics_frame

	if not is_instance_valid(animal2) or not animal2.is_inside_tree():
		push_error("FAIL: 등급 2 동물이 6회 공격만으로 사망함 (grade가 체력에 반영되지 않음)")
		ok = false
	elif health_label.text != "14/200":
		push_error("FAIL: 6회 공격 후 등급 2 동물의 체력 라벨이 기대한 값(14/200)이 아님 (실제: %s)" % health_label.text)
		ok = false

	Input.action_press("capture")
	await process_frame
	Input.action_release("capture")
	await process_frame

	if is_instance_valid(animal2) and animal2.is_inside_tree():
		push_error("FAIL: 체력이 8%% 미만(14/200)인데도 등급 2 동물이 포획되지 않음")
		ok = false

	if ok:
		print("HEADLESS_GRADE_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_GRADE_TEST: FAIL")
		quit(1)
