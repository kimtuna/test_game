extends Area2D

# design.md가 명시한 네 가지 서식 대상(식물/나무/동물/물고기) 중 마지막으로
# 남아있던 식물. tree.gd/fish.gd(정적 채집물 + 등급 + 장비 게이팅) 패턴을
# 기반으로 하되, 장비 게이팅은 의도적으로 넣지 않았다 — status.md #40이
# 남긴 판단대로 "나무보다 가볍고 장비 없이도 채집 가능한 대상"으로
# 식물을 나무와 차별화하는 것이 design.md 원문("식물, 나무, 동물, 물고기"를
# 별개 항목으로 나열)에 더 충실하다고 보았다. 대신 등급이 높을수록 더 여러 번
# 상호작용해야 하는 hits_required=grade 규칙은 그대로 유지해 "높은 등급일수록
# 채집이 어렵다"는 design.md 요구를 지킨다.

signal harvested(resource_name: String, amount: int)

@export_range(1, 3) var grade: int = 1

var player_nearby: CharacterBody2D = null
var hits_taken: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var grade_label: Label = $GradeLabel

func _ready() -> void:
	add_to_group("harvestable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.texture = _create_plant_texture()
	grade_label.text = "Lv.%d" % grade

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_nearby = null

func _process(_delta: float) -> void:
	if player_nearby != null and Input.is_action_just_pressed("ui_accept"):
		_register_hit()

func _register_hit() -> void:
	hits_taken += 1
	if hits_taken >= grade:
		_harvest()
	else:
		print("식물을 채집 중... (%d/%d)" % [hits_taken, grade])

func _harvest() -> void:
	print("식물을 채집했다: 채소 x1")
	harvested.emit("채소", 1)
	queue_free()

func _create_plant_texture() -> ImageTexture:
	var image := Image.create(28, 28, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(28):
		for y in range(28):
			var cx: float = x - 14.0
			var cy: float = y - 14.0
			if (cx * cx) / (13.0 * 13.0) + (cy * cy) / (10.0 * 10.0) <= 1.0:
				image.set_pixel(x, y, Color(0.3, 0.7, 0.25))
	for x in range(12, 16):
		for y in range(18, 28):
			image.set_pixel(x, y, Color(0.55, 0.35, 0.15))
	return ImageTexture.create_from_image(image)
