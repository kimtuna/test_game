extends Area2D

signal collected

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("items")
	body_entered.connect(_on_body_entered)
	var image := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.85, 0.2))
	sprite.texture = ImageTexture.create_from_image(image)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collected.emit()
		queue_free()
