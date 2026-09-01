extends Node2D

# 채집 결과를 화면에서 확인할 수 있게 하는 최소 인벤토리 UI.
# "harvestable" 그룹(현재는 Tree)의 harvested 시그널을 구독해 자원별 개수를
# 누적하고, 좌상단 Label에 "자원명: 개수" 형식으로 표시한다. 등급/장비 등
# 본격적인 인벤토리 시스템은 design.md 로드맵상 이후 단계라 손대지 않는다.

var inventory: Dictionary = {}

@onready var inventory_label: Label = $UI/InventoryLabel

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("harvestable"):
		node.harvested.connect(_on_harvested)
	_update_label()

func _on_harvested(resource_name: String, amount: int) -> void:
	inventory[resource_name] = inventory.get(resource_name, 0) + amount
	_update_label()

func _update_label() -> void:
	if inventory.is_empty():
		inventory_label.text = ""
		return
	var lines: Array[String] = []
	for resource_name in inventory.keys():
		lines.append("%s: %d" % [resource_name, inventory[resource_name]])
	inventory_label.text = "\n".join(lines)
