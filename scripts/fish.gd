extends Area2D

# design.md가 명시한 네 가지 서식 대상(식물/나무/동물/물고기) 중 마지막으로
# 남아있던 물고기 채집. tree.gd(정적 채집물 + 등급 + 장비 게이팅) 패턴을
# 그대로 재사용하되, 장비 슬롯만 새로 만든 "rod"(낚싯대)를 쓴다 — 도끼/마취총과
# 별개 슬롯인 이유는 design.md의 "장비를 맞춰(강화/교체) 나간다"는 문장이
# 대상별로 의미를 가지려면 나무는 도끼로, 물고기는 낚싯대로 등급을 갖춰야
# 하는 것이 상식적이기 때문이다.
#
# 실제 수영/낚싯줄 캐스팅 등 물 위에서의 이동은 design.md "범위 밖"(섬
# 크기·지형 생성 방식 미정)이라, 이번 조각은 물고기를 섬 위 걸어서 도달 가능한
# 위치(예: 해안가)에 배치하고 나무와 동일한 방식(근접 + 좌클릭)으로
# 상호작용하는 최소 구현으로 범위를 좁혔다. 실제 물 위 낚시 메커닉은 이후
# 세션이 지형/이동 체계를 더 구체화한 뒤에 다룰 문제다.
#
# tree.gd와 동일하게, 낚시 보상 수량도 grade와 같은 값으로 맞췄다(등급별 보상
# 차등). 자세한 근거는 tree.gd 주석 참고.

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
	sprite.texture = _create_fish_texture()
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
	if not player_nearby.has_equipped("rod"):
		print("낚싯대가 없어 낚시할 수 없다.")
		return
	if player_nearby.get_equipment_grade("rod") < grade:
		print("낚싯대 등급이 부족해 낚시할 수 없다. (필요 등급: %d, 보유 등급: %d)" % [grade, player_nearby.get_equipment_grade("rod")])
		return
	hits_taken += 1
	if hits_taken >= grade:
		_harvest()
	else:
		print("물고기를 낚는 중... (%d/%d)" % [hits_taken, grade])

func _harvest() -> void:
	print("물고기를 낚았다: 물고기 x%d" % grade)
	harvested.emit("물고기", grade)
	queue_free()

func _create_fish_texture() -> ImageTexture:
	var image := Image.create(40, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(30):
		for y in range(24):
			var cx: float = x - 13.0
			var cy: float = y - 12.0
			if (cx * cx) / (13.0 * 13.0) + (cy * cy) / (10.0 * 10.0) <= 1.0:
				image.set_pixel(x, y, Color(0.3, 0.55, 0.8))
	for x in range(28, 40):
		for y in range(24):
			var t: float = (x - 28.0) / 12.0
			var half_height: float = 10.0 * (1.0 - t)
			if abs(y - 12.0) <= half_height:
				image.set_pixel(x, y, Color(0.3, 0.55, 0.8))
	return ImageTexture.create_from_image(image)
