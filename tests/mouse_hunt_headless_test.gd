extends SceneTree

# 헤드리스 환경에서 마우스 기반 사냥 입력(inbox.md #4 2번, status.md #49)의
# 핵심 메커니즘 — 탄종류 전환(우클릭/switch_ammo)과 탄약 소모/재장전(R/reload) —
# 을 검증하는 통합 테스트. 공격/포획 판정 자체(등급 게이트, 8% 미만 포획
# 조건)는 animal_hunt/animal_capture/equipment_gate/grade 테스트가 이미
# 검증하므로, 이 테스트는 그 판정을 "무엇이 트리거하는가"(fire + ammo_type)와
# "몇 발 남았는가"(current_ammo)에 집중한다.
# 실행: godot --headless --path . --script res://tests/mouse_hunt_headless_test.gd

const TestInputHelper := preload("res://tests/test_input_helper.gd")

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var animal2: Area2D = main.get_node("Animal2")
	var health_label: Label = animal2.get_node("HealthLabel")

	var ok := true

	# 기본 상태: 일반탄, 탄창 가득(6/6).
	if player.ammo_type != "normal" or player.current_ammo != 6:
		push_error("FAIL: 초기 탄종류/탄약이 기대와 다름 (ammo_type=%s, current_ammo=%d)" % [player.ammo_type, player.current_ammo])
		ok = false

	# 우클릭(switch_ammo)을 누르면 마취탄으로, 한 번 더 누르면 다시 일반탄으로
	# 돌아와야 한다(현재 탄종류는 2개뿐이라 순환).
	await TestInputHelper.simulate_click(self, "switch_ammo")
	if player.ammo_type != "tranquilizer":
		push_error("FAIL: switch_ammo 1회 후 탄종류가 마취탄으로 바뀌지 않음 (실제: %s)" % player.ammo_type)
		ok = false

	await TestInputHelper.simulate_click(self, "switch_ammo")
	if player.ammo_type != "normal":
		push_error("FAIL: switch_ammo 2회 후 탄종류가 일반탄으로 돌아오지 않음 (실제: %s)" % player.ammo_type)
		ok = false

	# Player를 등급 2 동물(Animal2, 최대 체력 200) 위치로 이동시킨다 —
	# ATTACK_DAMAGE(31) 기준 6발을 맞아도(31*6=186) 죽지 않아(14/200) 탄창을
	# 다 비울 때까지 관찰할 수 있다.
	player.equip("tool", "도끼", 2)
	player.global_position = animal2.global_position
	for i in range(5):
		await physics_frame

	# 탄창(6발)을 모두 소모할 때까지 발사한다.
	for i in range(6):
		await TestInputHelper.simulate_click(self, "fire")

		var wait_frames := 0
		while animal2.is_fleeing and wait_frames < 120:
			await physics_frame
			wait_frames += 1
		player.global_position = animal2.global_position
		for j in range(5):
			await physics_frame

	if player.current_ammo != 0:
		push_error("FAIL: 6발을 쐈는데도 탄창이 0이 아님 (실제: %d)" % player.current_ammo)
		ok = false
	if not is_instance_valid(animal2) or not animal2.is_inside_tree() or health_label.text != "14/200":
		push_error("FAIL: 6발 공격 후 등급 2 동물의 체력이 기대한 값(14/200)이 아님 (실제: %s)" % health_label.text)
		ok = false

	# 탄창이 빈 상태에서 fire를 눌러도 아무 효과가 없어야 한다(체력 불변, 탄약 여전히 0).
	await TestInputHelper.simulate_click(self, "fire")
	if health_label.text != "14/200":
		push_error("FAIL: 탄창이 비었는데도 발사가 진행되어 체력이 변함 (실제: %s)" % health_label.text)
		ok = false
	if player.current_ammo != 0:
		push_error("FAIL: 탄창이 빈 상태에서 fire를 눌렀는데 탄약 수치가 바뀜 (실제: %d)" % player.current_ammo)
		ok = false

	# R(reload)을 누르면 탄창이 가득 찬다.
	await TestInputHelper.simulate_click(self, "reload")
	if player.current_ammo != 6:
		push_error("FAIL: 재장전 후 탄약이 6/6이 아님 (실제: %d)" % player.current_ammo)
		ok = false

	if ok:
		print("HEADLESS_MOUSE_HUNT_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_MOUSE_HUNT_TEST: FAIL")
		quit(1)
