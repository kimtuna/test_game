extends Area2D

# 사냥 가능한 동물의 첫 조각. design.md의 도주 트리거(발소리/시야/피격 감지)는
# 아직 구현하지 않은 고정 개체다 — 이번 단계는 "사냥" 상호작용의 뼈대(반복
# 공격으로 체력을 깎아 잡으면 자원을 얻는 흐름)만 다룬다. 포획(마취총, 체력
# 8% 미만 조건)은 별도 무기/아이템 시스템이 필요해 다음 단계로 미룬다.

signal harvested(resource_name: String, amount: int)

const MAX_HEALTH: int = 100
const ATTACK_DAMAGE: int = 34

var health: int = MAX_HEALTH
var player_nearby: CharacterBody2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	add_to_group("harvestable")
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
	if player_nearby != null and Input.is_action_just_pressed("ui_accept"):
		_attack()

func _attack() -> void:
	health -= ATTACK_DAMAGE
	print("동물을 공격했다. 남은 체력: %d" % health)
	if health <= 0:
		print("동물을 사냥했다: 고기 x1")
		harvested.emit("고기", 1)
		queue_free()
		return
	_update_health_label()

func _update_health_label() -> void:
	health_label.text = "%d/%d" % [health, MAX_HEALTH]

func _create_animal_texture() -> ImageTexture:
	var image := Image.create(40, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(40):
		for y in range(32):
			image.set_pixel(x, y, Color(0.6, 0.4, 0.2))
	return ImageTexture.create_from_image(image)
