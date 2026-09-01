extends CharacterBody2D

# design.md의 "등급·장비" 단계 중 "장비" 개념의 첫 조각. 지금까지 나무 채집
# (ui_accept)과 동물 공격/포획(ui_accept/capture)은 장비 유무와 무관하게
# 근접만 하면 항상 가능했다 — design.md의 "유저는 더 높은 등급을 상대하기
# 위해 장비를 맞춰(강화/교체) 나간다"는 문장을 충족하려면, 우선 장비가 없으면
# 애초에 상호작용이 불가능하다는 전제부터 명시적으로 있어야 한다.
#
# 장비 슬롯은 "tool"(도끼, 채집·사냥에 사용)과 "weapon"(마취총, 포획 전용)
# 두 가지로 시작한다. 기본값을 빈 슬롯이 아니라 이미 장착된 상태로 준 이유는
# design.md가 "기본 코디(의상) 제공"을 명시했고, 아직 장비를 얻거나 바꾸는
# 상점/제작 시스템이 전혀 없는 현재 단계에서 장비 자체를 얻을 방법이 없으면
# 플레이가 처음부터 막히기 때문이다 — 즉 "기본 장비 지급"은 상식적 기본값이고,
# 정말 새로운 것은 슬롯이 비면(unequip) 상호작용이 실제로 막힌다는 점이다.
var equipment: Dictionary = {
	"tool": "도끼",
	"weapon": "마취총",
}

const SPEED := 300.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("player")
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.6, 1.0))
	sprite.texture = ImageTexture.create_from_image(image)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()

func has_equipped(slot: String) -> bool:
	return equipment.get(slot, "") != ""

func equip(slot: String, item_name: String) -> void:
	equipment[slot] = item_name

func unequip(slot: String) -> void:
	equipment[slot] = ""
