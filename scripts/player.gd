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
#
# 각 슬롯에 "grade"를 추가했다 — design.md의 "유저는 더 높은 등급을 상대하기
# 위해 장비를 맞춰(강화/교체) 나간다"는 문장을 실제로 의미 있게 만들려면,
# 나무/동물의 grade(status.md #25)와 비교할 플레이어 쪽 수치가 있어야 하기
# 때문이다. 기본 장비의 grade는 1로 시작한다 — 지금까지 배치된 grade=1
# 나무/동물(Tree, Animal)은 기본 장비로 그대로 상호작용 가능해야 하므로.
var equipment: Dictionary = {
	"tool": {"name": "도끼", "grade": 1},
	"weapon": {"name": "마취총", "grade": 1},
}

const SPEED := 300.0
const DEFAULT_BODY_COLOR := Color(0.2, 0.6, 1.0)

var body_color: Color = DEFAULT_BODY_COLOR

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	_apply_body_color(body_color)
	# status.md #33/#34가 남긴 제약: 카메라는 authority propagation으로
	# 모든 피어에 복제되지만 enabled 값 자체는 authority와 무관하게 항상
	# true였다 — 호스트 화면에 접속자의 Player까지 함께 존재하면(스폰
	# 이후) 카메라가 두 개 이상 동시에 활성 상태가 되어 어느 쪽이 실제로
	# 보이는 화면인지 엔진이 임의로 결정하는 문제였다. 각 피어는 자신이
	# 조작하는(authority인) Player의 카메라만 켜야 한다.
	camera.enabled = is_multiplayer_authority()

# design.md의 "캐릭터 외형을 커스터마이징할 수 있다"의 첫 조각. 아직 별도
# 아트 리소스가 없어(범위 밖) 지금까지 절차적 단색 텍스처를 써온 패턴을
# 그대로 유지하되, 색을 외부(커스터마이징 UI)에서 바꿀 수 있도록 만든 것이
# 이번 조각에서 새로 생긴 부분이다.
func _apply_body_color(color: Color) -> void:
	body_color = color
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)

func set_body_color(color: Color) -> void:
	_apply_body_color(color)

# status.md #33까지는 여러 Player 인스턴스가 한 화면(호스트)에 존재하면
# 로컬 키보드 입력이 전부를 동시에 움직였다 — main.gd가 스폰 시
# set_multiplayer_authority(id)로 각 인스턴스의 소유 피어를 지정해두었으므로,
# 그 소유자(authority)가 아닌 피어에서는 입력을 무시해 자기 자신의 Player만
# 움직이게 한다. 오프라인(멀티플레이 피어 미설정) 상태에서는 authority
# 기본값(1)과 unique_id 기본값(1)이 항상 같아 기존 싱글플레이 동작에는
# 영향이 없다.
func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()

func has_equipped(slot: String) -> bool:
	return equipment.get(slot, {}).get("name", "") != ""

func get_equipment_grade(slot: String) -> int:
	return equipment.get(slot, {}).get("grade", 0)

func equip(slot: String, item_name: String, grade: int = 1) -> void:
	equipment[slot] = {"name": item_name, "grade": grade}

func unequip(slot: String) -> void:
	equipment[slot] = {"name": "", "grade": 0}
