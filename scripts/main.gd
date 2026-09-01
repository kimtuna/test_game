extends Node2D

# 채집/사냥 결과를 화면에서 확인할 수 있게 하는 최소 UI.
# "harvestable" 그룹(나무, 처치된 동물)의 harvested 시그널을 구독해 자원별
# 개수를 인벤토리 라벨에 표시하고, "capturable" 그룹(동물)의 captured
# 시그널을 구독해 포획한 동물을 별도 라벨에 표시한다. 포획은 소비되는
# 자원이 아니라 "잡아서 소유하게 된 개체"라는 점이 달라 인벤토리와 분리했다.
#
# status.md #27까지는 장비 등급이 대상 등급보다 낮으면 상호작용이 막히기만
# 할 뿐, 등급을 실제로 "맞춰 나갈" 방법이 게임 내에 전혀 없었다(코드에서
# player.equip()을 직접 호출하는 테스트뿐). 이번 조각은 design.md 로드맵의
# "채집/사냥/포획 -> 등급·장비" 구간을 마무리하기 위해, 이미 모으고 있는
# 자원(통나무/고기)을 일정량 소비해 대응하는 장비(도끼/마취총) 등급을 자동으로
# 1씩 올리는 최소 경로를 추가했다. 상점 UI나 재료 선택 없이 "모으면 자동으로
# 승급"하는 가장 단순한 형태를 택했다 — design.md가 강화 방식의 세부를
# 명시하지 않았고(범위 밖), 상점/제작 UI를 새로 설계하면 규칙 4(기능 하나만)를
# 넘어서기 때문이다.

const UPGRADE_COST: int = 5
const MAX_EQUIPMENT_GRADE: int = 3
const RESOURCE_TO_SLOT: Dictionary = {
	"통나무": "tool",
	"고기": "weapon",
}

var inventory: Dictionary = {}
var captured_animals: Dictionary = {}

@onready var inventory_label: Label = $UI/InventoryLabel
@onready var capture_label: Label = $UI/CaptureLabel
@onready var equipment_label: Label = $UI/EquipmentLabel
@onready var customization_overlay: Control = $UI/CustomizationOverlay
@onready var tutorial_overlay: Control = $UI/TutorialOverlay

# 색상 선택 키(1~4)와 스와치 색상을 한 곳에 묶어, 씬의 Swatch 노드 색과
# 어긋나지 않도록 함(#15/#22에서 배운 "값 중복으로 인한 잠재 버그" 반복 방지).
const BODY_COLOR_CHOICES: Dictionary = {
	KEY_1: Color(0.2, 0.6, 1.0),
	KEY_2: Color(0.9, 0.2, 0.2),
	KEY_3: Color(0.25, 0.75, 0.3),
	KEY_4: Color(0.6, 0.3, 0.8),
}

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("harvestable"):
		node.harvested.connect(_on_harvested)
	for node in get_tree().get_nodes_in_group("capturable"):
		node.captured.connect(_on_captured)
	_update_label()
	_update_capture_label()
	_update_equipment_label()
	customization_overlay.visible = true

# design.md의 "캐릭터 외형을 커스터마이징할 수 있다"의 첫 조각. 계정당 3개
# 캐릭터 슬롯(design.md)은 저장/불러오기 시스템까지 필요해 규칙 4(기능
# 하나만)를 넘어서므로 이번 조각에서는 다루지 않고, 슬롯 없이도 의미가 있는
# "외형 색 선택" 하나만 최소 구현했다. 숫자 키 1~4로 색을 고르면 즉시
# 캐릭터에 적용되고, 곧바로 기존 튜토리얼 오버레이(#29)로 이어진다 — 새
# 플레이어가 게임을 시작할 때 겪는 첫 화면 순서를 "외형 선택 -> 조작 안내"로
# 자연스럽게 잇기 위함이다.
func _unhandled_input(event: InputEvent) -> void:
	if customization_overlay.visible and event is InputEventKey and event.pressed and not event.echo:
		if BODY_COLOR_CHOICES.has(event.keycode):
			var player := get_tree().get_first_node_in_group("player")
			if player != null:
				player.set_body_color(BODY_COLOR_CHOICES[event.keycode])
			customization_overlay.visible = false
			tutorial_overlay.visible = true
			get_viewport().set_input_as_handled()
		return
	if tutorial_overlay.visible and event is InputEventKey and event.pressed and not event.echo:
		tutorial_overlay.visible = false
		get_viewport().set_input_as_handled()

func _on_harvested(resource_name: String, amount: int) -> void:
	inventory[resource_name] = inventory.get(resource_name, 0) + amount
	_try_upgrade_equipment(resource_name)
	_update_label()

func _try_upgrade_equipment(resource_name: String) -> void:
	var slot: String = RESOURCE_TO_SLOT.get(resource_name, "")
	if slot == "":
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var current_grade: int = player.get_equipment_grade(slot)
	if current_grade >= MAX_EQUIPMENT_GRADE:
		return
	if inventory.get(resource_name, 0) < UPGRADE_COST:
		return
	inventory[resource_name] -= UPGRADE_COST
	var item_name: String = player.equipment[slot]["name"]
	var new_grade: int = current_grade + 1
	player.equip(slot, item_name, new_grade)
	print("%s x%d을 소비해 %s을(를) Lv.%d로 강화했다." % [resource_name, UPGRADE_COST, item_name, new_grade])
	_update_equipment_label()

func _on_captured(animal_name: String) -> void:
	captured_animals[animal_name] = captured_animals.get(animal_name, 0) + 1
	_update_capture_label()

func _update_label() -> void:
	if inventory.is_empty():
		inventory_label.text = ""
		return
	var lines: Array[String] = []
	for resource_name in inventory.keys():
		lines.append("%s: %d" % [resource_name, inventory[resource_name]])
	inventory_label.text = "\n".join(lines)

func _update_capture_label() -> void:
	if captured_animals.is_empty():
		capture_label.text = ""
		return
	var lines: Array[String] = []
	for animal_name in captured_animals.keys():
		lines.append("포획: %s x%d" % [animal_name, captured_animals[animal_name]])
	capture_label.text = "\n".join(lines)

func _update_equipment_label() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		equipment_label.text = ""
		return
	var lines: Array[String] = []
	for slot in RESOURCE_TO_SLOT.values():
		var item: Dictionary = player.equipment.get(slot, {})
		lines.append("%s Lv.%d" % [item.get("name", "-"), item.get("grade", 0)])
	equipment_label.text = "\n".join(lines)
