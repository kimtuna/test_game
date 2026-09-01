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
# "weapon"(마취총) 슬롯을 요구한다.
#
# inbox.md #4 2번(status.md #49): 이전까지는 ui_accept가 공격을, 전용 capture
# 액션이 포획을 담당해 키 입력만으로 둘을 구분했다. 이제 둘 다 좌클릭
# 발사(fire) 하나로 들어오므로, player.gd에 추가된 ammo_type("normal"=일반탄/
# 공격, "tranquilizer"=마취탄/포획)으로 어느 쪽을 트리거할지 결정한다.
# 판정 로직(등급 체크, 체력 8% 미만 포획 조건 등)은 그대로 재사용한다.
#
# 이어서 등급(grade)과 장비를 실제로 연결했다: 장착한 도끼/마취총의 grade가
# 동물의 grade보다 낮으면 각각 공격/포획이 진행되지 않는다. tree.gd와 동일한
# 판단(장비가 있는 것만으로는 부족하고, 대상의 등급 이상인 장비를 갖춰야
# 상호작용이 통한다)을 여기에도 그대로 적용했다.
#
# tree.gd/fish.gd/plant.gd와 동일하게, 사냥 보상(고기) 수량도 grade와 같은
# 값으로 맞췄다(등급별 보상 차등). 포획(capture)은 동물을 자원으로 소비하는
# 것이 아니라 개체를 그대로 소유하게 되는 별개 경로라 보상 수량 개념이 없고,
# 이번 변경 대상이 아니다.
#
# inbox.md #5: "총인데 근접해야 맞는다"는 지적에 따라, "무엇을 맞힐 수
# 있는가"의 판정 주체를 이 스크립트(player_nearby 기반 폴링)에서 player.gd로
# 옮겼다. player.gd가 사거리/조준 방향을 확인해 대상을 고른 뒤 handle_fire()를
# 직접 호출하고, 그 안에서 탄약 소모와 공격/포획 분기(위 문단들의 게이트
# 로직)는 그대로 재사용한다. player_nearby 자체(및 Area2D)는 지우지 않았다 —
# 여전히 "완전히 붙어있을 때는 조준 방향과 무관하게 맞는다"는 최소 사거리
# 처리(player.gd의 POINT_BLANK_DISTANCE)와 기존 헤드리스 테스트의 근접 확인
# 용도로 쓰인다.
#
# inbox.md #9 2~4번: 절차적 단색 사각형을 PixelLab으로 생성한 실제 사슴 도트
# 그림(assets/sprites/animal/deer_base.png, 정지 상태 + deer_walk_00~15.png,
# 걷기 16프레임)으로 교체했다. player.gd의 걷기 애니메이션 패턴(WALK_FRAME_
# DURATION마다 프레임 순환, 멈추면 즉시 첫 프레임/기본 텍스처로 복귀)을 그대로
# 재사용했다 — 이 동물은 도주(is_fleeing) 중에만 실제로 이동하므로, "이동
# 중"의 기준을 player처럼 입력 방향이 아니라 is_fleeing으로 잡았다. 현재
# 게임에 동물 종류가 사슴 하나뿐이라(scenes/Main.tscn에 Animal 인스턴스 1개)
# 텍스처 경로를 사슴 전용으로 하드코딩했다 — 종류가 늘어나면 텍스처 셋을
# 파라미터화해야 한다(다음 세션 과제, 지금은 범위 밖).
#
# inbox.md #13 문제 1: 도주 방향에 따라 좌우로 뒤집는 로직이 아예 없어서
# 정지/도주 텍스처가 이동 방향과 무관하게 항상 같은 모습으로 보이던 문제를
# 고쳤다. _start_fleeing()이 flee_direction을 정할 때마다 _update_facing()을
# 호출해 sprite.flip_h를 그 방향의 x 부호로 설정한다 — Godot에서 texture와
# flip_h는 독립 프로퍼티라, 이후 _update_walk_animation()이 정지/걷기 텍스처를
# 오가도 flip_h는 그대로 유지되어 "자기 자신과 최소한 일관됨"(지시 원문)이
# 보장된다. deer_base.png/deer_walk_*.png를 확대해 직접 비교해봤는데 둘 다
# 정면(카메라 쪽)을 향한 유사한 포즈라 "기본 정면" 기준이 서로 다르다고 볼
# 근거는 없어서 별도 보정값은 추가하지 않았다.
#
# inbox.md #13 문제 2: 기존 코드는 이동 후 위치만 clamp하고 flee_direction은
# 그대로 바깥쪽을 향한 채 남겨둬서, 경계에 닿으면 매 프레임 같은 자리로
# 다시 clamp되며 사실상 멈춰버렸다. _reflect_direction()을 추가해 이동 후
# 위치가 경계를 넘은 축의 방향 성분 부호를 뒤집어(반사) 다음 프레임부터
# 안쪽으로 이동하도록 고쳤다. 이 함수는 position/direction/bounds만 받는
# 순수 함수라 문제 3(배회)의 경계 처리에도 그대로 재사용할 수 있게 만들었다
# (인스턴스 상태를 건드리지 않으므로 static으로 선언했다). 방향이 실제로
# 바뀐 프레임에는 _update_facing()도 다시 호출해 flip_h가 반사된 방향을
# 따라가도록 했다 — 안 그러면 문제 1에서 고친 방향 반전이 경계에서 튕길 때만
# 어긋나 보이게 된다.
#
# inbox.md #13 문제 3: 도주 중이 아니면 동물이 아예 움직이지 않던 문제를
# 고쳤다. "정지 → 무작위 방향으로 잠깐 이동 → 다시 정지"를 반복하는 배회
# 행동을 추가했다(_process_wandering). 이동/정지 구간의 이동 로직은 도주
# 이동과 완전히 같은 모양(이동 적용 → 경계 반사 → clamp)이라, 그 공통 부분을
# _move_with_reflection()으로 뽑아 도주(_physics_process)와 배회 양쪽에서
# 재사용한다 — _reflect_direction()이 순수 함수로 만들어져 있었던 덕분에
# 그대로 가져다 쓸 수 있었다. 도주가 시작되면(_start_fleeing) 배회 상태를
# 즉시 정지로 리셋해 두 행동이 같은 프레임에 겹쳐 움직이지 않게 했고, 도주가
# 끝나면 배회는 다음 무작위 정지 구간부터 다시 시작한다(도주 직후 곧바로
# 다시 움직이면 "쫓기다가 바로 다시 태연히 돌아다니는" 것처럼 보여 부자연스럽다).

signal harvested(resource_name: String, amount: int)
signal captured(animal_name: String)

const MAX_HEALTH: int = 100
const ATTACK_DAMAGE: int = 31
const CAPTURE_HEALTH_RATIO: float = 0.08
const FLEE_SPEED: float = 220.0
const FLEE_DURATION: float = 0.6

const WANDER_SPEED: float = 55.0
const WANDER_MOVE_MIN: float = 1.0
const WANDER_MOVE_MAX: float = 2.5
const WANDER_PAUSE_MIN: float = 1.5
const WANDER_PAUSE_MAX: float = 4.0

const BASE_TEXTURE_PATH := "res://assets/sprites/animal/deer_base.png"
const WALK_FRAME_COUNT := 16
const WALK_FRAME_PATH_FORMAT := "res://assets/sprites/animal/deer_walk_%02d.png"
const WALK_FRAME_DURATION := 0.08

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

var is_wander_moving: bool = false
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

var base_texture: Texture2D = null
var walk_frames: Array[Texture2D] = []
var is_walking: bool = false
var walk_timer: float = 0.0
var walk_frame_index: int = 0

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
	base_texture = load(BASE_TEXTURE_PATH)
	for i in range(WALK_FRAME_COUNT):
		walk_frames.append(load(WALK_FRAME_PATH_FORMAT % i))
	sprite.texture = base_texture
	max_health = MAX_HEALTH * grade
	health = max_health
	grade_label.text = "Lv.%d" % grade
	_update_health_label()
	terrain = get_tree().get_first_node_in_group("terrain")
	wander_timer = randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)

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

# player.gd가 사거리/조준 판정(inbox.md #5)을 통과시켜 이 동물을 발사
# 대상으로 골랐을 때 호출한다. player_nearby(근접 Area2D, 상호작용 반경 50)와
# 무관하게 shooter가 곧 발사한 플레이어다 — 탄약 소모 후 ammo_type에 따라
# 공격/포획으로 분기하는 기존 로직은 그대로 유지한다.
func handle_fire(shooter: CharacterBody2D) -> void:
	if not shooter.try_consume_ammo():
		return
	if shooter.ammo_type == "tranquilizer":
		_try_capture(shooter)
	else:
		_attack(shooter)

func _physics_process(delta: float) -> void:
	if not is_fleeing:
		if player_in_sound_range != null and player_in_sound_range.velocity.length() > 0.0:
			_start_fleeing(player_in_sound_range)
		else:
			_process_wandering(delta)
			return
	flee_direction = _move_with_reflection(flee_direction, FLEE_SPEED, delta)
	flee_timer -= delta
	if flee_timer <= 0.0:
		is_fleeing = false
	_update_walk_animation(delta, is_fleeing)

# inbox.md #13 문제 3: 도주 중이 아닐 때 호출된다. wander_timer가 0이 되면
# 정지↔이동 상태를 전환한다 — 정지에서 이동으로 바뀔 때만 새 무작위 방향을
# 뽑고(이동 중에는 방향을 유지해야 갈지자로 떨림 없이 자연스럽다), 각 상태의
# 지속 시간도 매번 새로 무작위로 뽑아 모든 개체가 같은 박자로 움직이지 않게
# 한다.
func _process_wandering(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		if is_wander_moving:
			is_wander_moving = false
			wander_timer = randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
		else:
			is_wander_moving = true
			wander_direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
			_update_facing(wander_direction)
			wander_timer = randf_range(WANDER_MOVE_MIN, WANDER_MOVE_MAX)
	if is_wander_moving:
		wander_direction = _move_with_reflection(wander_direction, WANDER_SPEED, delta)
	_update_walk_animation(delta, is_wander_moving)

# 도주 이동과 배회 이동이 공유하는 "이동 적용 → 경계에서 반사 → clamp"
# 로직을 하나로 묶었다(inbox #13 문제 2에서 만든 _reflect_direction()이 순수
# 함수라 그대로 재사용 가능했다). 방향이 실제로 바뀐 프레임에는
# _update_facing()도 함께 호출해 flip_h가 반사된 방향을 따라가게 한다.
func _move_with_reflection(direction: Vector2, speed: float, delta: float) -> Vector2:
	global_position += direction * speed * delta
	var result := direction
	if terrain != null:
		var bounds: Rect2 = terrain.get_island_bounds()
		var reflected := _reflect_direction(global_position, direction, bounds)
		if reflected != direction:
			result = reflected
			_update_facing(result)
		global_position.x = clamp(global_position.x, bounds.position.x, bounds.end.x)
		global_position.y = clamp(global_position.y, bounds.position.y, bounds.end.y)
	return result

# player.gd의 _update_walk_animation과 동일한 패턴(inbox #9 4번) — 이동 중일
# 때만 WALK_FRAME_DURATION마다 프레임을 순환시키고, 멈추면 즉시 정지 텍스처
# (deer_base.png)로 되돌린다. 이 동물은 도주(is_fleeing) 상태가 곧 "이동
# 중"이므로 player처럼 입력 방향 대신 moving 인자에 is_fleeing을 그대로 넘긴다.
func _update_walk_animation(delta: float, moving: bool) -> void:
	if not moving:
		if is_walking:
			is_walking = false
			walk_timer = 0.0
			walk_frame_index = 0
			sprite.texture = base_texture
		return
	is_walking = true
	walk_timer += delta
	if walk_timer >= WALK_FRAME_DURATION:
		walk_timer -= WALK_FRAME_DURATION
		walk_frame_index = (walk_frame_index + 1) % walk_frames.size()
		sprite.texture = walk_frames[walk_frame_index]

func _attack(shooter: CharacterBody2D) -> void:
	if not shooter.has_equipped("tool"):
		print("도구가 없어 공격할 수 없다.")
		return
	if shooter.get_equipment_grade("tool") < grade:
		print("도구 등급이 부족해 공격할 수 없다. (필요 등급: %d, 보유 등급: %d)" % [grade, shooter.get_equipment_grade("tool")])
		return
	health -= ATTACK_DAMAGE
	print("동물을 공격했다. 남은 체력: %d" % health)
	if health <= 0:
		print("동물을 사냥했다: 고기 x%d" % grade)
		harvested.emit("고기", grade)
		queue_free()
		return
	_update_health_label()
	_start_fleeing(shooter)

func _start_fleeing(threat: Node2D = null) -> void:
	is_fleeing = true
	is_wander_moving = false
	wander_timer = randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
	flee_timer = FLEE_DURATION
	var reference: Node2D = threat if threat != null else player_nearby
	if reference != null:
		var away := global_position - reference.global_position
		flee_direction = away.normalized() if away.length() > 0.001 else Vector2.RIGHT
	else:
		flee_direction = Vector2.RIGHT
	_update_facing(flee_direction)

# inbox.md #13 문제 1: 정지 텍스처(deer_base.png)와 걷기 프레임(deer_walk_*.png)에
# 동일하게 적용되도록 sprite.flip_h를 여기서만 갱신한다 — 텍스처를 바꾸는
# _update_walk_animation()은 flip_h를 건드리지 않으므로(Godot에서 texture와
# flip_h는 독립 프로퍼티), 한 번 설정한 좌우 방향이 정지/애니메이션 전환과
# 무관하게 그대로 유지된다. x 성분이 거의 0(순수 상하 이동)이면 직전 방향을
# 그대로 둔다 — 좌우 정보가 없는데 임의로 뒤집으면 오히려 더 부자연스럽다.
func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) < 0.01:
		return
	sprite.flip_h = direction.x < 0.0

# inbox.md #13 문제 2: position은 이동을 적용한 뒤의 값이어야 하며, 그
# 위치가 경계를 넘은 축의 방향 성분만 부호를 뒤집어(반사) 반환한다 — 두 축
# 모두 넘었다면(코너) 둘 다 뒤집는다. 인스턴스 상태를 참조하지 않는 순수
# 함수라 문제 3(배회)의 경계 처리에도 그대로 재사용할 수 있다.
static func _reflect_direction(position: Vector2, direction: Vector2, bounds: Rect2) -> Vector2:
	var reflected := direction
	if position.x <= bounds.position.x or position.x >= bounds.end.x:
		reflected.x = -reflected.x
	if position.y <= bounds.position.y or position.y >= bounds.end.y:
		reflected.y = -reflected.y
	return reflected

func _try_capture(shooter: CharacterBody2D) -> void:
	if not shooter.has_equipped("weapon"):
		print("마취총이 없어 포획할 수 없다.")
		return
	if shooter.get_equipment_grade("weapon") < grade:
		print("마취총 등급이 부족해 포획할 수 없다. (필요 등급: %d, 보유 등급: %d)" % [grade, shooter.get_equipment_grade("weapon")])
		return
	if health < max_health * CAPTURE_HEALTH_RATIO:
		print("동물을 포획했다.")
		captured.emit("동물")
		queue_free()
	else:
		print("체력이 충분히 낮아야(8%% 미만) 포획할 수 있다. (현재 %d/%d)" % [health, max_health])

func _update_health_label() -> void:
	health_label.text = "%d/%d" % [health, max_health]
