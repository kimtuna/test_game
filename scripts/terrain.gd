extends Node2D

const OCEAN_SIZE := Vector2(3000, 2000)
const ISLAND_SIZE := Vector2(2000, 1300)
const WALL_THICKNESS := 40.0

@onready var ocean: Sprite2D = $Ocean
@onready var island: Sprite2D = $Island

func _ready() -> void:
	_set_flat_texture(ocean, OCEAN_SIZE, Color(0.2, 0.5, 0.8))
	_set_flat_texture(island, ISLAND_SIZE, Color(0.35, 0.65, 0.25))
	_create_boundary_walls(island.position, ISLAND_SIZE)

func _set_flat_texture(sprite: Sprite2D, size: Vector2, color: Color) -> void:
	var image := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)

# Island(육지) 바깥 경계를 따라 얇은 정적 충돌벽 4개를 둘러싸서, Player가
# CharacterBody2D의 move_and_slide()로 이동하다가 바다로 나가지 못하게 막는다.
# 벽 크기는 ISLAND_SIZE(텍스처 크기)에서 그대로 계산해, 섬 크기가 바뀌어도
# 벽과 텍스처가 어긋나지 않도록 한다.
func _create_boundary_walls(center: Vector2, size: Vector2) -> void:
	var bounds := StaticBody2D.new()
	bounds.name = "IslandBounds"
	add_child(bounds)
	var half := size / 2.0
	_add_wall(bounds, Vector2(center.x, center.y - half.y - WALL_THICKNESS / 2.0), Vector2(size.x + WALL_THICKNESS * 2, WALL_THICKNESS))
	_add_wall(bounds, Vector2(center.x, center.y + half.y + WALL_THICKNESS / 2.0), Vector2(size.x + WALL_THICKNESS * 2, WALL_THICKNESS))
	_add_wall(bounds, Vector2(center.x - half.x - WALL_THICKNESS / 2.0, center.y), Vector2(WALL_THICKNESS, size.y + WALL_THICKNESS * 2))
	_add_wall(bounds, Vector2(center.x + half.x + WALL_THICKNESS / 2.0, center.y), Vector2(WALL_THICKNESS, size.y + WALL_THICKNESS * 2))

func _add_wall(bounds: StaticBody2D, wall_position: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = wall_position
	bounds.add_child(collision)
