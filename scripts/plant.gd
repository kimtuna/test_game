extends Area2D

# design.md가 명시한 네 가지 서식 대상(식물/나무/동물/물고기) 중 마지막으로
# 남아있던 식물. tree.gd/fish.gd(정적 채집물 + 등급 + 장비 게이팅) 패턴을
# 기반으로 한다.
#
# status.md #41은 "식물은 나무보다 가볍고 장비 없이도 채집 가능한 대상"으로
# 장비 게이팅을 의도적으로 뺐었다. 하지만 design.md 원문을 다시 보면
# "식물/나무/동물/물고기 각각에 등급이 존재하고, 높은 등급일수록 잡거나
# 채집하기 어렵다. 유저는 더 높은 등급을 상대하기 위해 장비를 맞춰(강화/교체)
# 나간다"고 네 대상 모두에 동일한 원칙을 명시하고 있다 — 즉 식물만 예외로
# 두면 design.md의 핵심 문장과 어긋난다. 이번 조각에서 그 결정을 뒤집어,
# 나무/물고기와 동일하게 전용 장비 슬롯("sickle", 낫)을 요구하도록 바꿨다.
# 종류별로 별도 슬롯을 쓰는 이유(도끼/마취총/낚싯대와 동일)도 그대로다 —
# 대상별로 "장비를 맞춰 나간다"는 문장이 의미를 가지려면 자원별로 구분된
# 장비가 있어야 한다.
#
# tree.gd/fish.gd와 동일하게, 채집 보상 수량도 grade와 같은 값으로 맞췄다
# (등급별 보상 차등). 자세한 근거는 tree.gd 주석 참고.

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

# inbox.md #7 2번: 상호작용을 전부 좌클릭(fire)으로 통일했다 — 근거는
# tree.gd 주석 참고. 근접(player_nearby) 판정은 그대로다.
func _process(_delta: float) -> void:
	if player_nearby != null and Input.is_action_just_pressed("fire"):
		_register_hit()

func _register_hit() -> void:
	if not player_nearby.has_equipped("sickle"):
		print("낫이 없어 채집할 수 없다.")
		return
	if player_nearby.get_equipment_grade("sickle") < grade:
		print("낫 등급이 부족해 채집할 수 없다. (필요 등급: %d, 보유 등급: %d)" % [grade, player_nearby.get_equipment_grade("sickle")])
		return
	hits_taken += 1
	if hits_taken >= grade:
		_harvest()
	else:
		print("식물을 채집 중... (%d/%d)" % [hits_taken, grade])

func _harvest() -> void:
	print("식물을 채집했다: 채소 x%d" % grade)
	harvested.emit("채소", grade)
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
