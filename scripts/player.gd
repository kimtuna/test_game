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
	"rod": {"name": "낚싯대", "grade": 1},
	"sickle": {"name": "낫", "grade": 1},
}

# inbox.md #4 2번: 동물 대상 상호작용을 ui_accept/capture 키 입력에서 마우스
# 기반(좌클릭 발사/우클릭 탄종류 변경/R 재장전)으로 바꾸는 조각. animal.gd의
# 기존 판정 로직(_attack은 tool 게이트, _try_capture는 weapon 게이트)은 그대로
# 두고 "무엇을 트리거하는가"만 탄종류로 결정한다 — 좌클릭 발사가 곧 "장착된
# 총으로 쏜다"는 서술이지만, 실제 판정에 쓰이는 장비 슬롯(tool/weapon)까지
# 새로 통합하는 것은 이번 지시 범위(입력 방식 교체)를 넘어선다.
const AMMO_TYPE_NAMES := {"normal": "일반탄 (사살용)", "tranquilizer": "마취탄 (포획용)"}
const MAGAZINE_SIZE := 6
var ammo_type: String = "normal"
var current_ammo: int = MAGAZINE_SIZE

const SPEED := 300.0
const DEFAULT_BODY_COLOR := Color(0.2, 0.6, 1.0)

# design.md "기본 코디(의상) 제공: 별도로 맞추지 않아도 입고 시작할 수 있는
# 기본 복장이 있다"를 지금까지는 "장비 슬롯이 처음부터 채워져 있다"로만
# 해석했다(player.gd 상단 주석 참고) — 실제로 화면에 "옷을 입고 있다"고 보일
# 시각 요소는 없이 몸 전체가 단색 사각형 하나였다. status.md #45가 남긴
# 두 후보(포획 동물 활용/장비 UI화) 모두 이미 여러 세션째 낮은 실익으로
# 보류돼 있어, 이번 세션은 design.md 원문에 더 직접적으로 대응하는 이
# 시각적 격차를 골랐다. 몸(상의, 커스터마이징 색 적용)과 하의(고정된 기본
# 복장 색)를 나눠 그려, 커스터마이징을 하지 않아도 "기본 복장을 입은
# 캐릭터"로 보이게 한다. 하의 색은 아직 커스터마이징 대상이 아니다 — 여러
# 부위 커스터마이징 UI는 새 시스템이라 규칙 4(기능 하나만)를 넘어선다.
const OUTFIT_COLOR := Color(0.35, 0.25, 0.15)

var body_color: Color = DEFAULT_BODY_COLOR

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var ammo_label: Label = $HUD/AmmoLabel

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
	# 카메라와 동일한 이유로, 탄종류 HUD도 authority가 아닌(원격) Player
	# 인스턴스에서는 화면에 겹쳐 보이면 안 되므로 꺼둔다.
	ammo_label.visible = is_multiplayer_authority()
	_update_ammo_label()

# design.md의 "캐릭터 외형을 커스터마이징할 수 있다"의 첫 조각. 아직 별도
# 아트 리소스가 없어(범위 밖) 지금까지 절차적 단색 텍스처를 써온 패턴을
# 그대로 유지하되, 색을 외부(커스터마이징 UI)에서 바꿀 수 있도록 만든 것이
# 이번 조각에서 새로 생긴 부분이다.
func _apply_body_color(color: Color) -> void:
	body_color = color
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	# 하단(다리 위치)만 고정된 기본 복장 색으로 덮어 그려, 상의(커스터마이징
	# 색)와 하의(기본 코디)가 시각적으로 구분되게 한다. customization_headless_test/
	# slot_headless_test는 (0,0) 픽셀(상의 영역)만 검사하므로 영향받지 않는다.
	for x in range(32):
		for y in range(20, 32):
			image.set_pixel(x, y, OUTFIT_COLOR)
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
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()

	# 우클릭(탄종류 변경)과 R(재장전)을 처리한다. 발사(좌클릭)는 animal.gd가
	# player_nearby로 근접 여부를 이미 판정하고 있으므로 그쪽에서 직접
	# Input.is_action_just_pressed("fire")를 읽는 기존 패턴(ui_accept/capture가
	# tree.gd/animal.gd에서 쓰던 폴링 방식)과 일관되게, 여기서도 _unhandled_input
	# 대신 폴링을 쓴다 — 기존 헤드리스 테스트들이 Input.action_press()로 입력을
	# 흉내내는데, 이 방식은 실제 InputEvent를 만들어 _input/_unhandled_input으로
	# 전달하지 않고 Input 싱글턴의 폴링 상태만 바꾸기 때문에, 이벤트 콜백
	# 방식으로 짜면 헤드리스 테스트로 검증할 수 없다.
	if Input.is_action_just_pressed("switch_ammo"):
		switch_ammo_type()
	elif Input.is_action_just_pressed("reload"):
		reload()

func switch_ammo_type() -> void:
	var types: Array = AMMO_TYPE_NAMES.keys()
	var next_index := (types.find(ammo_type) + 1) % types.size()
	ammo_type = types[next_index]
	print("탄종류 변경: %s" % AMMO_TYPE_NAMES[ammo_type])
	_update_ammo_label()

func reload() -> void:
	current_ammo = MAGAZINE_SIZE
	print("재장전 완료: %d/%d" % [current_ammo, MAGAZINE_SIZE])
	_update_ammo_label()

# 발사(좌클릭)가 방아쇠를 당길 때마다 호출된다. 무엇을 맞혔는지와 무관하게
# (빗나가거나 장비 게이트로 판정이 막히더라도) 탄은 소모된다는 상식적
# 판단이다. 탄이 없으면 false를 반환해 animal.gd가 공격/포획을 아예
# 진행하지 않도록 한다.
func try_consume_ammo() -> bool:
	if current_ammo <= 0:
		print("탄창이 비었다. R로 재장전하세요.")
		return false
	current_ammo -= 1
	_update_ammo_label()
	return true

func _update_ammo_label() -> void:
	ammo_label.text = "%s (%d/%d)" % [AMMO_TYPE_NAMES[ammo_type], current_ammo, MAGAZINE_SIZE]

func has_equipped(slot: String) -> bool:
	return equipment.get(slot, {}).get("name", "") != ""

func get_equipment_grade(slot: String) -> int:
	return equipment.get(slot, {}).get("grade", 0)

func equip(slot: String, item_name: String, grade: int = 1) -> void:
	equipment[slot] = {"name": item_name, "grade": grade}

func unequip(slot: String) -> void:
	equipment[slot] = {"name": "", "grade": 0}
