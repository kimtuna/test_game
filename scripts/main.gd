extends Node2D

var score := 0

@onready var score_label: Label = $UI/ScoreLabel

func _ready() -> void:
	for item in get_tree().get_nodes_in_group("items"):
		item.collected.connect(_on_item_collected)
	_update_label()

func _on_item_collected() -> void:
	score += 1
	_update_label()

func _update_label() -> void:
	score_label.text = "Score: %d" % score
