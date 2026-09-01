extends Area2D

# 채집 가능한 나무. Player가 상호작용 범위(Area2D)에 들어온 상태에서
# ui_accept(기본: Space/Enter — 커스텀 입력맵 없이 Godot 기본 액션을 그대로
# 사용해 project.godot의 InputEventKey 리소스를 직접 편집하는 위험을 피함)를
# 누르면 나무가 사라지고 자원을 얻는다.
#
# design.md의 "등급·장비" 단계 첫 조각으로 등급(grade, 1~3)을 추가했다.
# 높은 등급일수록 채집이 어렵다는 design.md 요구를 가장 단순하게 만족시키기
# 위해, 필요한 채집 횟수(hits_required)를 grade 값 그대로 사용했다 — 별도의
# 시간/확률 시스템 없이 "몇 번 더 상호작용해야 하는가"만으로 난이도를
# 표현하는 상식적 기본값이다. 등급별 보상(자원 종류/수량) 차등은 design.md에
# 명시되지 않아 이번 조각에서는 다루지 않는다.

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
	sprite.texture = _create_tree_texture()
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
		print("나무를 채집 중... (%d/%d)" % [hits_taken, grade])

func _harvest() -> void:
	print("나무를 채집했다: 통나무 x1")
	harvested.emit("통나무", 1)
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
