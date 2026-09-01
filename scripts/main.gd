extends Node2D

var score := 0
var total_items := 0

@onready var score_label: Label = $UI/ScoreLabel
@onready var clear_label: Label = $UI/ClearLabel

func _ready() -> void:
	var items := get_tree().get_nodes_in_group("items")
	total_items = items.size()
	for item in items:
		item.collected.connect(_on_item_collected)
	_update_label()

func _on_item_collected() -> void:
	score += 1
	_update_label()
	if score >= total_items:
		clear_label.visible = true

func _update_label() -> void:
	score_label.text = "Score: %d" % score
