extends Node2D

@onready var ocean: Sprite2D = $Ocean
@onready var island: Sprite2D = $Island

func _ready() -> void:
	_set_flat_texture(ocean, 3000, 2000, Color(0.2, 0.5, 0.8))
	_set_flat_texture(island, 2000, 1300, Color(0.35, 0.65, 0.25))

func _set_flat_texture(sprite: Sprite2D, width: int, height: int, color: Color) -> void:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)
