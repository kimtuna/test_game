extends Area2D

# 채집 가능한 나무. Player가 상호작용 범위(Area2D)에 들어온 상태에서
# 좌클릭(fire 액션)을 누르면 나무가 사라지고 자원을 얻는다.
#
# inbox.md #7 2번: 이전까지는 ui_accept(Space/Enter)로 채집했는데, 동물
# 사냥이 이미 fire(좌클릭)로 통일돼 있어(inbox #4/#5) 대상마다 트리거 키가
# 다른 상태였다. 도구/무기를 모두 장비로 드는 구조이니 상호작용을 전부
# 좌클릭으로 통일한다 — 다만 나무/식물/물고기는 근접 도구(도끼/낫/낚싯대)라
# 총처럼 긴 사거리일 필요는 없으므로, 트리거 키만 fire로 바꾸고 판정은 기존
# 근접(player_nearby, Area2D) 방식을 그대로 유지한다.
#
# design.md의 "등급·장비" 단계 첫 조각으로 등급(grade, 1~3)을 추가했다.
# 높은 등급일수록 채집이 어렵다는 design.md 요구를 가장 단순하게 만족시키기
# 위해, 필요한 채집 횟수(hits_required)를 grade 값 그대로 사용했다 — 별도의
# 시간/확률 시스템 없이 "몇 번 더 상호작용해야 하는가"만으로 난이도를
# 표현하는 상식적 기본값이다. 등급별 보상(자원 종류/수량) 차등은 design.md에
# 명시되지 않아 이번 조각에서는 다루지 않는다.
#
# "장비" 단계 첫 조각으로, Player에 새로 생긴 장비 슬롯(player.gd의
# equipment["tool"])이 비어 있으면 상호작용 범위 안이라도 채집이 진행되지
# 않는다 — design.md의 "장비를 맞춰 나간다"는 문장이 실제로 의미를 가지려면
# 장비 없이는 아예 상호작용이 불가능해야 하기 때문이다.
#
# 이어서 등급(grade)과 장비를 실제로 연결했다: 장착한 도끼의 grade가 나무의
# grade보다 낮으면 채집이 진행되지 않는다. "장비를 맞춰(강화/교체) 나간다"는
# design.md 문장이 지금까지는 "장비가 있으면 등급과 무관하게 항상 통한다"는
# 상태였는데, 이제는 더 높은 등급을 상대하려면 실제로 더 높은 등급의 장비로
# 교체해야 하는 의미가 생긴다.
#
# status.md #41/#42가 "남은 제약"으로 남긴 대로, 지금까지는 등급이 높을수록
# 채집이 어려워지기만 할 뿐 보상은 항상 x1로 고정돼 "더 어려운 대상을 상대할
# 유인"이 부족했다. 별도 보상 테이블 없이 가장 단순하게, 채집 시 보상 수량을
# hits_required와 동일한 grade 값으로 맞췄다 — "몇 번 더 상호작용해야 하는가"로
# 난이도를 표현한 기존 방식과 같은 축을 그대로 재사용해 새 개념을 늘리지 않았다.

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
	if player_nearby != null and Input.is_action_just_pressed("fire"):
		_register_hit()

func _register_hit() -> void:
	if not player_nearby.has_equipped("tool"):
		print("도끼가 없어 채집할 수 없다.")
		return
	if player_nearby.get_equipment_grade("tool") < grade:
		print("도끼 등급이 부족해 채집할 수 없다. (필요 등급: %d, 보유 등급: %d)" % [grade, player_nearby.get_equipment_grade("tool")])
		return
	hits_taken += 1
	if hits_taken >= grade:
		_harvest()
	else:
		print("나무를 채집 중... (%d/%d)" % [hits_taken, grade])

func _harvest() -> void:
	print("나무를 채집했다: 통나무 x%d" % grade)
	harvested.emit("통나무", grade)
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
