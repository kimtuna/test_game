extends Area2D

# 채집 가능한 나무. Player가 상호작용 범위(Area2D)에 들어온 상태에서
# ui_accept(기본: Space/Enter — 커스텀 입력맵 없이 Godot 기본 액션을 그대로
# 사용해 project.godot의 InputEventKey 리소스를 직접 편집하는 위험을 피함)를
# 누르면 나무가 사라지고 자원을 얻는다. design.md의 등급/장비 시스템은 아직
# 범위 밖이므로, 이번 단계는 "채집" 상호작용의 가장 작은 단위만 구현한다.

var player_nearby: CharacterBody2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("harvestable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.texture = _create_tree_texture()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_nearby = null

func _process(_delta: float) -> void:
	if player_nearby != null and Input.is_action_just_pressed("ui_accept"):
		_harvest()

func _harvest() -> void:
	print("나무를 채집했다: 통나무 x1")
	queue_free()

func _create_tree_texture() -> ImageTexture:
	var image := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(18, 30):
		for y in range(40, 64):
			image.set_pixel(x, y, Color(0.45, 0.3, 0.15))
	for x in range(48):
		for y in range(44):
			image.set_pixel(x, y, Color(0.15, 0.5, 0.2))
	return ImageTexture.create_from_image(image)
