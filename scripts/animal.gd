extends Area2D

# 사냥 가능한 동물. design.md의 도주 트리거(발소리/시야/피격 감지)는 아직
# 구현하지 않은 고정 개체다. 이번 단계에서 design.md가 명시한 포획 조건
# (체력 8% 미만 + 마취총)을 추가했다 — 마취총이라는 아이템/장비 개념이 아직
# 없으므로, "이미 마취총을 들고 있다"고 가정하고 전용 입력 액션("capture",
# project.godot에 C 키로 등록)을 마취총 발사로 취급하는 최소 구현이다.
#
# ATTACK_DAMAGE를 34 -> 31로 조정했다: 기존 34는 100 -> 66 -> 32 -> (-2, 즉사)
# 순서라 체력이 8%(8) 미만인 1~7 구간에 정수로는 절대 도달하지 못해 포획이
# 원천적으로 불가능했다. 31로 바꾸면 100 -> 69 -> 38 -> 7 순서가 되어 3회
# 공격 후 정확히 7(8% 미만)에서 멈추므로, 플레이어가 거기서 공격을 멈추고
# 포획으로 전환할 수 있는 여지가 생긴다.

signal harvested(resource_name: String, amount: int)
signal captured(animal_name: String)

const MAX_HEALTH: int = 100
const ATTACK_DAMAGE: int = 31
const CAPTURE_HEALTH_RATIO: float = 0.08

var health: int = MAX_HEALTH
var player_nearby: CharacterBody2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	add_to_group("harvestable")
	add_to_group("capturable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.texture = _create_animal_texture()
	_update_health_label()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_nearby = null

func _process(_delta: float) -> void:
	if player_nearby == null:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_attack()
	elif Input.is_action_just_pressed("capture"):
		_try_capture()

func _attack() -> void:
	health -= ATTACK_DAMAGE
	print("동물을 공격했다. 남은 체력: %d" % health)
	if health <= 0:
		print("동물을 사냥했다: 고기 x1")
		harvested.emit("고기", 1)
		queue_free()
		return
	_update_health_label()

func _try_capture() -> void:
	if health < MAX_HEALTH * CAPTURE_HEALTH_RATIO:
		print("동물을 포획했다.")
		captured.emit("동물")
		queue_free()
	else:
		print("체력이 충분히 낮아야(8%% 미만) 포획할 수 있다. (현재 %d/%d)" % [health, MAX_HEALTH])

func _update_health_label() -> void:
	health_label.text = "%d/%d" % [health, MAX_HEALTH]

func _create_animal_texture() -> ImageTexture:
	var image := Image.create(40, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(40):
		for y in range(32):
			image.set_pixel(x, y, Color(0.6, 0.4, 0.2))
	return ImageTexture.create_from_image(image)
