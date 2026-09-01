extends SceneTree

const MAX_EQUIPMENT_GRADE_FOR_TEST: int = 3

# 헤드리스 환경에서 "자원을 모아 장비 등급을 올리는" 최소 경로(main.gd의
# _try_upgrade_equipment)를 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/equipment_upgrade_headless_test.gd
#
# 실제 씬에 배치된 나무 2그루만으로는 통나무를 UPGRADE_COST(5)만큼 모을 수
# 없으므로(최대 2개), main._on_harvested()를 직접 호출해 "자원을 이만큼
# 모았다"는 상황을 흉내낸다 — grade_headless_test.gd가 player.equip()을 직접
# 호출해 장비 상태를 세팅하는 것과 같은 방식이다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var ok := true

	if player.get_equipment_grade("tool") != 1:
		push_error("FAIL: 초기 도끼 등급이 1이 아님 (실제: %d)" % player.get_equipment_grade("tool"))
		ok = false

	# 통나무 4개(비용 미달)로는 승급하지 않아야 한다.
	main._on_harvested("통나무", 4)
	if player.get_equipment_grade("tool") != 1:
		push_error("FAIL: 통나무 4개(비용 5 미달)로 도끼가 승급함")
		ok = false
	if main.inventory.get("통나무", 0) != 4:
		push_error("FAIL: 통나무 4개가 소비되지 않고 인벤토리에 남아있어야 함 (실제: %d)" % main.inventory.get("통나무", 0))
		ok = false

	# 통나무 1개를 더 모아 총 5개가 되면 도끼가 Lv.2로 승급하고, 비용만큼 소비돼야 한다.
	main._on_harvested("통나무", 1)
	if player.get_equipment_grade("tool") != 2:
		push_error("FAIL: 통나무 5개를 모았는데 도끼가 Lv.2로 승급하지 않음 (실제 등급: %d)" % player.get_equipment_grade("tool"))
		ok = false
	if main.inventory.get("통나무", 0) != 0:
		push_error("FAIL: 승급 비용(5)만큼 통나무가 소비되지 않음 (실제: %d)" % main.inventory.get("통나무", 0))
		ok = false

	var equipment_label: Label = main.get_node("UI/EquipmentLabel")
	if not equipment_label.text.contains("도끼 Lv.2"):
		push_error("FAIL: EquipmentLabel에 승급된 도끼 등급이 표시되지 않음 (실제: %s)" % equipment_label.text)
		ok = false

	# 통나무 5개를 한 번 더 모으면 도끼가 Lv.3(MAX_EQUIPMENT_GRADE)로 승급한다.
	main._on_harvested("통나무", 5)
	if player.get_equipment_grade("tool") != MAX_EQUIPMENT_GRADE_FOR_TEST:
		push_error("FAIL: 통나무 5개를 더 모았는데 도끼가 Lv.3으로 승급하지 않음 (실제 등급: %d)" % player.get_equipment_grade("tool"))
		ok = false

	# 이미 최대 등급이므로, 통나무를 더 모아도 승급하지 않고 소비되지도 않아야 한다.
	main._on_harvested("통나무", 5)
	if player.get_equipment_grade("tool") != MAX_EQUIPMENT_GRADE_FOR_TEST:
		push_error("FAIL: 최대 등급(3)을 넘어 도끼가 승급함 (실제 등급: %d)" % player.get_equipment_grade("tool"))
		ok = false
	if main.inventory.get("통나무", 0) != 5:
		push_error("FAIL: 최대 등급에서는 자원이 소비되지 않아야 함 (실제: %d)" % main.inventory.get("통나무", 0))
		ok = false

	# 고기(weapon 슬롯) 승급 경로도 동일하게 동작해야 한다.
	if player.get_equipment_grade("weapon") != 1:
		push_error("FAIL: 초기 마취총 등급이 1이 아님 (실제: %d)" % player.get_equipment_grade("weapon"))
		ok = false
	main._on_harvested("고기", 5)
	if player.get_equipment_grade("weapon") != 2:
		push_error("FAIL: 고기 5개를 모았는데 마취총이 Lv.2로 승급하지 않음 (실제 등급: %d)" % player.get_equipment_grade("weapon"))
		ok = false
	if not equipment_label.text.contains("마취총 Lv.2"):
		push_error("FAIL: EquipmentLabel에 승급된 마취총 등급이 표시되지 않음 (실제: %s)" % equipment_label.text)
		ok = false

	if ok:
		print("HEADLESS_EQUIPMENT_UPGRADE_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_EQUIPMENT_UPGRADE_TEST: FAIL")
		quit(1)
