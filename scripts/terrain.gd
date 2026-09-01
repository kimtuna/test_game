extends Node2D

const OCEAN_SIZE := Vector2(3000, 2000)
const ISLAND_SIZE := Vector2(2000, 1300)
# BEACH_MARGIN: 섬(잔디) 가장자리 바깥으로 모래를 얼마나 두를지. 지형이 잔디
# 한 가지 색뿐이라 단조로웠던 것을 보강하는 순수 시각적 조각이다(design.md가
# 섬 크기·지형 생성 방식을 아직 확정하지 않았으므로, 걸어다닐 수 있는 영역
# 자체를 넓히는 대신 기존 충돌 경계(IslandBounds, ISLAND_SIZE 기준)는 그대로
# 두고 그 바로 바깥에 보이는 모래띠만 추가했다 — boundary_headless_test 등
# 기존 경계 관련 테스트가 가정하는 벽 위치를 건드리지 않기 위함).
const BEACH_MARGIN := 150.0
# status.md #44가 남긴 제약("모래가 균일한 마진의 단순한 사각 링이라 해안선
# 굴곡이 없다")을 해소하기 위해, 마진을 섬 중심 기준 각도(angle)에 따라
# 사인파 두 개(서로 다른 주파수)로 흔들어 만(灣)·곶처럼 보이는 불규칙한
# 해안선을 만든다. 정수 주파수를 쓰는 이유: 각도는 -PI/PI에서 순환하므로,
# 정수배가 아니면 그 경계에서 파형이 끊겨 보이는 이음매가 생긴다.
const BEACH_WAVE_AMPLITUDE := 45.0
const BEACH_MAX_MARGIN := BEACH_MARGIN + BEACH_WAVE_AMPLITUDE
const BEACH_SIZE := ISLAND_SIZE + Vector2(BEACH_MAX_MARGIN, BEACH_MAX_MARGIN) * 2.0
const WALL_THICKNESS := 40.0

@onready var ocean: Sprite2D = $Ocean
@onready var beach: Sprite2D = $Beach
@onready var island: Sprite2D = $Island

func _ready() -> void:
	add_to_group("terrain")
	_set_flat_texture(ocean, OCEAN_SIZE, Color(0.2, 0.5, 0.8))
	_set_beach_texture(beach, ISLAND_SIZE, BEACH_SIZE, Color(0.85, 0.75, 0.5))
	_set_flat_texture(island, ISLAND_SIZE, Color(0.35, 0.65, 0.25))
	_create_boundary_walls(island.position, ISLAND_SIZE)

# 섬의 경계 사각형(월드 좌표)을 반환한다. 도주 중인 동물처럼 물리 충돌 없이
# 직접 global_position을 옮기는 대상이 섬 밖(바다)으로 나가지 않도록
# 클램프할 때 쓴다. ISLAND_SIZE를 여기 한 곳에서만 정의하고 다른 스크립트는
# 이 함수로 조회하게 해, 크기가 바뀌어도 값이 어긋나지 않게 한다.
func get_island_bounds() -> Rect2:
	return Rect2(island.position - ISLAND_SIZE / 2.0, ISLAND_SIZE)

func _set_flat_texture(sprite: Sprite2D, size: Vector2, color: Color) -> void:
	var image := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)

# 모래띠는 사각형 링이 아니라 섬 가장자리를 따라 폭이 흔들리는 불규칙한
# 해안선으로 그린다. 텍스처 전체(가로세로 최대 2390x1690)를 픽셀 단위로
# 훑으면 느리므로, 실제로 모래가 그려질 수 있는 가장자리 띠(두께
# BEACH_MAX_MARGIN)만 계산한다 — 섬 안쪽 깊은 곳은 항상 투명(섬 스프라이트가
# 그 위에 따로 그려짐)이라 애초에 칠할 필요가 없기 때문.
func _set_beach_texture(sprite: Sprite2D, island_size: Vector2, texture_size: Vector2, color: Color) -> void:
	var w := int(texture_size.x)
	var h := int(texture_size.y)
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var half_island := island_size / 2.0
	var center := Vector2(w, h) / 2.0
	var band := int(ceil(BEACH_MAX_MARGIN))
	for y in range(h):
		if y >= band and y < h - band:
			_paint_beach_span(image, y, 0, band, center, half_island, color)
			_paint_beach_span(image, y, w - band, w, center, half_island, color)
		else:
			_paint_beach_span(image, y, 0, w, center, half_island, color)
	sprite.texture = ImageTexture.create_from_image(image)

# [x_start, x_end) 구간의 각 픽셀에 대해, 섬 경계까지의 유클리드 거리
# (사각형 SDF)가 각도별로 흔들리는 허용 마진 안에 들어오면 모래색을 칠한다.
func _paint_beach_span(image: Image, y: int, x_start: int, x_end: int, center: Vector2, half_island: Vector2, color: Color) -> void:
	for x in range(x_start, x_end):
		var local := Vector2(x, y) - center
		var outside := Vector2(maxf(absf(local.x) - half_island.x, 0.0), maxf(absf(local.y) - half_island.y, 0.0))
		var distance_outside := outside.length()
		if distance_outside <= 0.0:
			continue
		var angle := local.angle()
		var wave := BEACH_WAVE_AMPLITUDE * 0.6 * sin(5.0 * angle + 0.7) + BEACH_WAVE_AMPLITUDE * 0.4 * sin(9.0 * angle + 2.3)
		if distance_outside <= BEACH_MARGIN + wave:
			image.set_pixel(x, y, color)

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
