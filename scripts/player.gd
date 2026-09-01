extends CharacterBody2D

const SPEED := 300.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.6, 1.0))
	sprite.texture = ImageTexture.create_from_image(image)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()
