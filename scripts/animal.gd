extends Area2D

# 사냥 가능한 동물. design.md가 명시한 포획 조건(체력 8% 미만 + 마취총)을
# 갖추고 있다 — 마취총이라는 아이템/장비 개념이 아직 없으므로, "이미 마취총을
# 들고 있다"고 가정하고 전용 입력 액션("capture", project.godot에 C 키로
# 등록)을 마취총 발사로 취급하는 최소 구현이다.
#
# ATTACK_DAMAGE를 34 -> 31로 조정했다: 기존 34는 100 -> 66 -> 32 -> (-2, 즉사)
# 순서라 체력이 8%(8) 미만인 1~7 구간에 정수로는 절대 도달하지 못해 포획이
# 원천적으로 불가능했다. 31로 바꾸면 100 -> 69 -> 38 -> 7 순서가 되어 3회
# 공격 후 정확히 7(8% 미만)에서 멈추므로, 플레이어가 거기서 공격을 멈추고
# 포획으로 전환할 수 있는 여지가 생긴다.
#
# design.md의 도주 트리거 세 가지(발소리 감지/시야 감지/피격 감지) 중
# "피격당했을 때"에 이어 이번 단계에서 "시야 감지"를 추가했다 — 이미 있는
# player_nearby(상호작용 반경 50) 패턴을 재사용하되, 그보다 넓은 반경(180)의
# 별도 Area2D(SightArea)를 두어 "가까이서 상호작용 가능"과 "멀리서 눈에 띔"을
# 구분했다. 플레이어가 SightArea에 처음 들어오면(진입 이벤트 1회) 도주를
# 시작한다 — 계속 시야 안에 있다고 매 프레임 재유발하지 않는 이유는, 피격
# 도주와 동일하게 "자극 하나당 도주 한 번" 패턴을 유지해 동물이 근접 전투
# 범위 안에서 끊임없이 미세 진동하며 도망다니는 부자연스러운 동작을 피하기
# 위함이다. 다시 도주하려면 일단 시야에서 벗어났다가 재진입해야 한다.
#
# 발소리 감지("SoundArea", 반경 250)를 마지막 도주 트리거로 추가했다. 시야
# 감지와 달리 "정지해 있으면 감지되지 않는다"는 조건이 핵심이라, 진입
# 이벤트 한 번으로 즉시 트리거하지 않고 매 물리 프레임 player_in_sound_range
# 대상의 velocity(CharacterBody2D 내장 속성)가 0보다 큰지(이동 중인지) 확인해
# 도주를 시작한다. 반경을 SightArea(180)보다 넓게(250) 잡은 것은 이번
# 세션의 판단이다 — 두 영역이 SightArea ⊂ SoundArea 관계였다면(예: 120반경)
# 플레이어가 걸어서 접근할 때는 반드시 SoundArea보다 먼저 SightArea를
# 지나가므로 시야 감지가 항상 먼저 발동해 발소리 감지가 사실상 죽은 코드가
# 된다. "발소리는 눈으로 보기 전에 먼저 들린다"는 상식에 맞게 반경을 시야보다
# 넓게 잡아, 정지한 동물이 이동 중인 플레이어를 시야보다 먼저 소리로
# 감지하는 시나리오가 실제로 발생하도록 했다.
#
# 공격받아 죽지 않고 살아남으면(피격 도주), 시야에 처음 들어오면(시야
# 도주), 또는 이동 중인 플레이어가 발소리 감지 범위 안에 있으면(발소리
# 도주) 플레이어 반대 방향으로 FLEE_DURATION초 동안 FLEE_SPEED 속도로
# 이동한다. 포획 시도(capture, 마취총)는 피해를 주는 "공격"이 아니라 별도
# 행동이므로 도주를 유발하지 않는다.
#
# design.md의 "등급·장비" 단계 첫 조각으로 등급(grade, 1~3)을 추가했다.
# 높은 등급일수록 잡기 어렵다는 요구를, 최대 체력을 grade에 비례해 늘리는
# 방식(max_health = MAX_HEALTH * grade)으로 구현했다 — ATTACK_DAMAGE는
# 그대로 두어 등급이 높을수록 사냥에 필요한 타격 횟수가 자연스럽게 늘어난다.
# 포획 조건(체력 8% 미만)도 max_health 기준 비율이라 grade와 무관하게 동일한
# 규칙으로 동작한다. MAX_HEALTH라는 이름은 기존 헤드리스 테스트가
# `animal.MAX_HEALTH`로 직접 참조하고 있어 grade=1 기준값(기본 개체 100)으로
# 그대로 유지했다.
#
# "장비" 단계 첫 조각으로, Player의 장비 슬롯(player.gd의 equipment)이 비어
# 있으면 공격/포획이 진행되지 않는다. 공격은 "tool"(도끼) 슬롯을, 포획은
# "weapon"(마취총) 슬롯을 요구한다 — 지금까지 ui_accept가 채집·공격을,
# capture 액션이 포획을 담당해온 키 구분을 그대로 장비 슬롯 구분에 대응시켰다.

signal harvested(resource_name: String, amount: int)
signal captured(animal_name: String)

const MAX_HEALTH: int = 100
const ATTACK_DAMAGE: int = 31
const CAPTURE_HEALTH_RATIO: float = 0.08
const FLEE_SPEED: float = 220.0
const FLEE_DURATION: float = 0.6

@export_range(1, 3) var grade: int = 1

var max_health: int = MAX_HEALTH
var health: int = MAX_HEALTH
var player_nearby: CharacterBody2D = null
var player_in_sight: CharacterBody2D = null
var player_in_sound_range: CharacterBody2D = null
var is_fleeing: bool = false
var flee_timer: float = 0.0
var flee_direction: Vector2 = Vector2.ZERO
var terrain: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_label: Label = $HealthLabel
@onready var grade_label: Label = $GradeLabel
@onready var sight_area: Area2D = $SightArea
@onready var sound_area: Area2D = $SoundArea

func _ready() -> void:
	add_to_group("harvestable")
	add_to_group("capturable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sight_area.body_entered.connect(_on_sight_body_entered)
	sight_area.body_exited.connect(_on_sight_body_exited)
	sound_area.body_entered.connect(_on_sound_body_entered)
	sound_area.body_exited.connect(_on_sound_body_exited)
	sprite.texture = _create_animal_texture()
	max_health = MAX_HEALTH * grade
	health = max_health
	grade_label.text = "Lv.%d" % grade
	_update_health_label()
	terrain = get_tree().get_first_node_in_group("terrain")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_nearby = null

func _on_sight_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_sight = body
	if not is_fleeing:
		_start_fleeing(body)

func _on_sight_body_exited(body: Node2D) -> void:
	if body == player_in_sight:
		player_in_sight = null

func _on_sound_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_sound_range = body

func _on_sound_body_exited(body: Node2D) -> void:
	if body == player_in_sound_range:
		player_in_sound_range = null

func _process(_delta: float) -> void:
	if player_nearby == null:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_attack()
	elif Input.is_action_just_pressed("capture"):
		_try_capture()

func _physics_process(delta: float) -> void:
	if not is_fleeing:
		if player_in_sound_range != null and player_in_sound_range.velocity.length() > 0.0:
			_start_fleeing(player_in_sound_range)
		else:
			return
	global_position += flee_direction * FLEE_SPEED * delta
	if terrain != null:
		var bounds: Rect2 = terrain.get_island_bounds()
		global_position.x = clamp(global_position.x, bounds.position.x, bounds.end.x)
		global_position.y = clamp(global_position.y, bounds.position.y, bounds.end.y)
	flee_timer -= delta
	if flee_timer <= 0.0:
		is_fleeing = false

func _attack() -> void:
	if not player_nearby.has_equipped("tool"):
		print("도구가 없어 공격할 수 없다.")
		return
	health -= ATTACK_DAMAGE
	print("동물을 공격했다. 남은 체력: %d" % health)
	if health <= 0:
		print("동물을 사냥했다: 고기 x1")
		harvested.emit("고기", 1)
		queue_free()
		return
	_update_health_label()
	_start_fleeing()

func _start_fleeing(threat: Node2D = null) -> void:
	is_fleeing = true
	flee_timer = FLEE_DURATION
	var reference: Node2D = threat if threat != null else player_nearby
	if reference != null:
		var away := global_position - reference.global_position
		flee_direction = away.normalized() if away.length() > 0.001 else Vector2.RIGHT
	else:
		flee_direction = Vector2.RIGHT

func _try_capture() -> void:
	if not player_nearby.has_equipped("weapon"):
		print("마취총이 없어 포획할 수 없다.")
		return
	if health < max_health * CAPTURE_HEALTH_RATIO:
		print("동물을 포획했다.")
		captured.emit("동물")
		queue_free()
	else:
		print("체력이 충분히 낮아야(8%% 미만) 포획할 수 있다. (현재 %d/%d)" % [health, max_health])

func _update_health_label() -> void:
	health_label.text = "%d/%d" % [health, max_health]

func _create_animal_texture() -> ImageTexture:
	var image := Image.create(40, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(40):
		for y in range(32):
			image.set_pixel(x, y, Color(0.6, 0.4, 0.2))
	return ImageTexture.create_from_image(image)
