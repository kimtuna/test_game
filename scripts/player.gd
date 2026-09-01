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
const DEFAULT_SKIN_COLOR := Color(0.2, 0.6, 1.0)
const DEFAULT_EYE_COLOR := Color(0.05, 0.05, 0.05)
const DEFAULT_HAIR_TYPE := "short"

# inbox.md #5: "총인데 직접 다가가서 때려야 한다"는 지적에 따라, 발사 판정을
# animal.gd의 근접 Area2D(player_nearby, 반경 50)에서 실제 사거리 기반으로
# 바꾼다. FIRE_RANGE 밖의 대상은 아예 맞힐 수 없고, FIRE_RANGE 안이라도
# POINT_BLANK_DISTANCE(기존 근접 반경과 동일한 50)보다 먼 대상은 조준 방향
# (facing_direction) 쪽 FIRE_ANGLE_TOLERANCE_DEG 안에 있어야 맞는다 — 완전히
# 붙어있을 때는 어느 쪽을 보고 있든 맞는 것이 상식적이라 각도 검사를
# 건너뛴다. facing_direction은 실제 마우스 커서 방향 대신 "현재 이동
# 방향"(inbox #5가 명시적으로 허용한 두 옵션 중 하나)으로 정했다 — 이
# 저장소의 다른 입력들(switch_ammo/reload, player.gd 주석 참고)과 마찬가지로
# 헤드리스 테스트는 실제 마우스 위치를 흉내낼 수단이 없어, 마우스 기반으로
# 하면 자동 QA로 검증이 불가능해지기 때문이다.
const FIRE_RANGE := 350.0
const POINT_BLANK_DISTANCE := 50.0
const FIRE_ANGLE_TOLERANCE_DEG := 25.0

var facing_direction: Vector2 = Vector2.DOWN

# inbox.md #6 1번: 위 status.md #53 판단(마우스 시뮬레이션이 불가능해 조준을
# 이동 방향으로 대체)이 실제로는 "마우스로 조준해도 원하는 대로 안 맞는다"는
# 버그로 이어졌다 — 총이라면 이동 방향이 아니라 실제 마우스 커서 방향을
# 조준해야 한다. `aim_direction`을 조준 판정과 조준선 표시 양쪽에 쓰는 단일
# 값으로 두고, 매 물리 프레임 `_update_aim_direction()`에서 갱신한다.
# 헤드리스 환경(자동 QA)에서는 실제 마우스 좌표가 없어(get_global_mouse_position()이
# 항상 (0,0) 근처의 의미 없는 값을 반환) `facing_direction`(이동 방향, 기존
# 헤드리스 테스트들이 직접 설정해 조준을 결정론적으로 통제하는 값)으로
# 그대로 대체한다 — main_menu.gd의 DisplayServer.get_name() == "headless" 분기와
# 동일한 패턴.
var aim_direction: Vector2 = Vector2.DOWN

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

# inbox.md #7 3번: 커스터마이징 범위를 몸 색 하나(body_color)에서 눈/피부색/
# 머리카락 종류 세 가지로 나눈다. 절차적 도트 스타일을 유지하기 위해 머리는
# 색상 선택이 아니라 "종류"(모양+고정색 조합) 선택으로 둔다 — HAIR_STYLES가
# 종류별 색과 그릴 x 범위를 함께 갖는다. "bald"(대머리)는 HAIR_STYLES에 키가
# 없어 머리를 아예 그리지 않는 것으로 표현한다.
var skin_color: Color = DEFAULT_SKIN_COLOR
var eye_color: Color = DEFAULT_EYE_COLOR
var hair_type: String = DEFAULT_HAIR_TYPE

# inbox.md #8 5번: 첫 실제 도트 스프라이트 적용. tools/sprite_gen.py로 10장의
# "player_body_base" 후보를 생성해 비교 그리드를 시각적으로 확인하고
# 선정한 #08(시드 style_v1, status.md #64)의 비례를 그대로 이 상수 세 개로
# 옮겨왔다 — head_ratio=0.372(머리를 크게 그려 식별하기 쉬움),
# body_width_ratio=0.637, body_top_ratio=0.302. 아래 그리기 함수들은 이
# 비례로 정한 머리/몸통 타원 실루엣 기준으로 좌표를 잡는다(전체를 채우던
# 단색 사각형과 달리, 캔버스 모서리는 이제 투명하다).
const HEAD_RATIO := 0.372
const BODY_WIDTH_RATIO := 0.637
const BODY_TOP_RATIO := 0.302
const HEAD_CENTER_Y_RATIO := 0.24
const OUTFIT_START_Y := 20

const HAIR_STYLES: Dictionary = {
	"short": {"color": Color(0.25, 0.15, 0.05), "x_range": [8, 24]},
	"mohawk": {"color": Color(0.05, 0.05, 0.05), "x_range": [14, 18]},
}
const HAIR_ROWS := [2, 6]
const EYE_ROWS := [9, 11]
const EYE_LEFT_X := [12, 14]
const EYE_RIGHT_X := [18, 20]

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var ammo_label: Label = $HUD/AmmoLabel

func _ready() -> void:
	add_to_group("player")
	_apply_appearance()
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

# design.md의 "캐릭터 외형을 커스터마이징할 수 있다"의 첫 조각을 실제 도트
# 실루엣으로 교체한 버전(inbox.md #8 5번). 이전에는 32x32 전체를 skin_color로
# 채운 뒤 아래쪽만 OUTFIT_COLOR로 덮는 "단색 사각형"이었다 — assets/ART_STYLE.md
# 규칙(하드 엣지 3톤 명암, 좌상단 45도 광원)을 지키는 실제 실루엣이 아니었다.
# 이제 tools/sprite_gen.py로 선정한 머리/몸통 타원 비례(HEAD_RATIO 등)로
# 사람 형태 실루엣을 그리고, 그 위에 3톤(그림자/기본/밝은색) 하드 엣지 음영을
# 입힌다 — _three_tone()/_shade_for_position()이 ART_STYLE.md의 공식(그림자
# V-20%/S+5%, 밝은색 V+15%)을 GDScript로 그대로 구현한 것으로,
# tools/sprite_gen.py의 동명 함수와 동일한 계산이다(파이썬 쪽은 후보 생성
# 전용이라 런타임 커스터마이징에는 쓸 수 없어 GDScript에도 같은 공식을 옮겨야
# 했다). 캔버스 모서리는 실루엣 밖이라 이제 투명하다 — outfit_headless_test/
# customization_headless_test가 더 이상 (0,0)/(0,31) 코너 픽셀을 검사하지
# 않는 이유다(테스트도 이번 세션에서 실루엣 내부 영역을 검사하도록 갱신).
func _apply_appearance() -> void:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var skin_tones := _three_tone(skin_color)
	var outfit_tones := _three_tone(OUTFIT_COLOR)

	var head_r := 32.0 * HEAD_RATIO / 2.0
	var head_cx := 16.0
	var head_cy := 32.0 * HEAD_CENTER_Y_RATIO
	var head_x0 := roundi(head_cx - head_r)
	var head_x1 := roundi(head_cx + head_r)
	var head_y0 := roundi(head_cy - head_r)
	var head_y1 := roundi(head_cy + head_r)
	_draw_shaded_ellipse(image, head_x0, head_y0, head_x1, head_y1, skin_tones)

	var body_w := 32.0 * BODY_WIDTH_RATIO
	var body_x0 := roundi((32.0 - body_w) / 2.0)
	var body_x1 := roundi((32.0 + body_w) / 2.0)
	var body_y0 := roundi(32.0 * BODY_TOP_RATIO)
	var body_y1 := 32
	_draw_shaded_ellipse(image, body_x0, body_y0, body_x1, body_y1, skin_tones)
	# 하의(기본 코디)는 몸통 타원의 아래쪽(OUTFIT_START_Y 이하)만 덮어써서
	# 실루엣은 그대로 두고 색만 바꾼다 — 별도 타원을 새로 그리면 몸통과 다른
	# 윤곽이 생겨 실루엣이 어긋난다.
	_draw_shaded_ellipse(image, body_x0, body_y0, body_x1, body_y1, outfit_tones, OUTFIT_START_Y)

	_draw_hair(image)
	_draw_eyes(image)
	sprite.texture = ImageTexture.create_from_image(image)

# assets/ART_STYLE.md 3톤 공식(HSV 기준): 그림자 = 명도-20%/채도+5%,
# 밝은색 = 명도+15%. tools/sprite_gen.py의 three_tone()과 동일한 계산이다.
func _three_tone(base: Color) -> Dictionary:
	var shadow := Color.from_hsv(
		base.h, clampf(base.s + 0.05, 0.0, 1.0), clampf(base.v - 0.20, 0.0, 1.0)
	)
	var highlight := Color.from_hsv(base.h, base.s, clampf(base.v + 0.15, 0.0, 1.0))
	return {"shadow": shadow, "base": base, "highlight": highlight}

# 좌상단 45도 광원 기준 하드 엣지 3톤 분류(dx/dy: bbox 내부 0~1 상대 좌표).
# tools/sprite_gen.py의 _shade_for_position()과 동일한 공식 — 그라디언트
# 대신 계단식 경계로만 명암을 나눠 ART_STYLE.md의 "안티앨리어싱 금지" 규칙을
# 지킨다.
func _shade_for_position(dx: float, dy: float) -> String:
	var metric := ((1.0 - dx) + dy) / 2.0
	if metric > 0.62:
		return "highlight"
	if metric < 0.38:
		return "shadow"
	return "base"

# bbox(x0,y0,x1,y1) 안에 내접하는 타원을 3톤 하드 엣지로 채운다. min_row을
# 주면 그 행 위쪽은 건너뛰어(투명 유지) 같은 bbox 안에서 아래쪽 일부만 다른
# 색으로 덮어쓸 수 있다(하의를 몸통 타원의 아래쪽에만 입히는 용도).
func _draw_shaded_ellipse(
	image: Image, x0: int, y0: int, x1: int, y1: int, tones: Dictionary, min_row: int = -1
) -> void:
	var w := maxi(1, x1 - x0)
	var h := maxi(1, y1 - y0)
	var cx := (x0 + x1) / 2.0
	var cy := (y0 + y1) / 2.0
	var rx := w / 2.0
	var ry := h / 2.0
	for y in range(y0, y1):
		if min_row >= 0 and y < min_row:
			continue
		for x in range(x0, x1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			var dx := float(x - x0) / w
			var dy := float(y - y0) / h
			var tone_key := _shade_for_position(dx, dy)
			image.set_pixel(x, y, tones[tone_key])

func _draw_hair(image: Image) -> void:
	if not HAIR_STYLES.has(hair_type):
		return
	var style: Dictionary = HAIR_STYLES[hair_type]
	var x_range: Array = style["x_range"]
	var color: Color = style["color"]
	for x in range(x_range[0], x_range[1]):
		for y in range(HAIR_ROWS[0], HAIR_ROWS[1]):
			image.set_pixel(x, y, color)

func _draw_eyes(image: Image) -> void:
	for x in range(EYE_LEFT_X[0], EYE_LEFT_X[1]):
		for y in range(EYE_ROWS[0], EYE_ROWS[1]):
			image.set_pixel(x, y, eye_color)
	for x in range(EYE_RIGHT_X[0], EYE_RIGHT_X[1]):
		for y in range(EYE_ROWS[0], EYE_ROWS[1]):
			image.set_pixel(x, y, eye_color)

func set_appearance(new_skin_color: Color, new_eye_color: Color, new_hair_type: String) -> void:
	skin_color = new_skin_color
	eye_color = new_eye_color
	hair_type = new_hair_type
	_apply_appearance()

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
	if direction.length() > 0.0:
		facing_direction = direction.normalized()

	_update_aim_direction()

	# 좌클릭(발사)/우클릭(탄종류 변경)/R(재장전) 모두 여기서 폴링한다 — 기존
	# 헤드리스 테스트들이 Input.action_press()로 입력을 흉내내는데, 이 방식은
	# 실제 InputEvent를 만들어 _input/_unhandled_input으로 전달하지 않고 Input
	# 싱글턴의 폴링 상태만 바꾸기 때문에, 이벤트 콜백 방식으로 짜면 헤드리스
	# 테스트로 검증할 수 없다. 세 액션을 elif로 묶으면, 한 액션의 "방금 눌림"
	# 상태가 (헤드리스 테스트가 physics_frame을 기다리지 않아) 아직 소비되지
	# 않은 채 다음 물리 프레임까지 남아있을 때 다른 액션의 elif 분기를 가로채
	# 아예 실행되지 않게 만드는 문제가 있었다(실제로 mouse_hunt 테스트에서
	# reload가 fire에 가려 호출되지 않는 회귀로 나타남). 서로 다른 입력이라
	# 논리적으로도 배타적일 필요가 없으므로 독립된 if로 분리한다.
	if Input.is_action_just_pressed("fire"):
		_fire()
	if Input.is_action_just_pressed("switch_ammo"):
		switch_ammo_type()
	if Input.is_action_just_pressed("reload"):
		reload()

# 사거리/조준 조건을 만족하는 가장 가까운 동물을 찾아 발사 판정을 넘긴다.
# "무엇을 맞힐 수 있는가"만 여기서 결정하고, 탄약 소모나 공격/포획 게이트 같은
# 기존 판정은 그대로 animal.gd의 handle_fire()가 담당한다(inbox.md #5).
func _fire() -> void:
	var target := _find_fire_target()
	if target != null:
		target.handle_fire(self)

func _find_fire_target() -> Node:
	var best_target: Node = null
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("capturable"):
		var to_target: Vector2 = candidate.global_position - global_position
		var distance := to_target.length()
		if distance > FIRE_RANGE:
			continue
		if distance > POINT_BLANK_DISTANCE:
			# angle_to()는 -180~180 사이의 부호 있는 각도를 반환한다. abs() 없이
			# 그대로 비교하면 정반대 방향(180도 근처, 부호에 따라 -180으로 나올
			# 수 있음)이 오히려 tolerance보다 "작다"고 잘못 판정돼 반대쪽을
			# 조준해도 맞아버리는 버그가 생긴다.
			var angle := absf(rad_to_deg(aim_direction.angle_to(to_target.normalized())))
			if angle > FIRE_ANGLE_TOLERANCE_DEG:
				continue
		if distance < best_distance:
			best_distance = distance
			best_target = candidate
	return best_target

# inbox.md #6 1번: 조준 판정에 쓰는 aim_direction을 실제 마우스 커서 방향으로
# 갱신한다. 창 스트레치 모드(project.godot의 window/stretch/mode="canvas_items")가
# 걸려있어도 get_global_mouse_position()은 뷰포트의 캔버스 변환을 반영한 월드
# 좌표를 반환하므로 별도 변환이 필요 없다(Godot 4 표준 동작).
func _update_aim_direction() -> void:
	if DisplayServer.get_name() == "headless":
		aim_direction = facing_direction
	else:
		var to_mouse := get_global_mouse_position() - global_position
		aim_direction = to_mouse.normalized() if to_mouse.length() > 0.0 else facing_direction
	queue_redraw()

# inbox.md #6 2번: 조준선(에임 라인) 표시. 2D 게임에서 실제 어디를 조준하는지
# 눈으로 확인할 수단이 없으면 마우스 조준이 맞는지 스스로 검증할 수 없다는
# 지적에 따른 것 — aim_direction과 동일한 값을 그대로 그려, 판정과 시각 표시가
# 항상 일치하게 했다. 원격(비authority) 플레이어와 헤드리스 환경에서는 그리지
# 않는다(카메라/HUD와 동일한 이유 — 화면에 보일 일이 없거나, 애초에 그릴
# 디스플레이가 없다).
func _draw() -> void:
	if not is_multiplayer_authority():
		return
	if DisplayServer.get_name() == "headless":
		return
	draw_line(Vector2.ZERO, aim_direction * FIRE_RANGE, Color(1.0, 0.2, 0.2, 0.5), 2.0)

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

# inbox.md #6 4번: 착용형 장비(복장/악세서리) 슬롯. 위 equipment 딕셔너리
# ("tool"/"weapon"/"rod"/"sickle")는 상호작용에 실제로 쓰이는 "도구" 개념이고,
# 이 7개는 design.md의 "캐릭터 외형을 커스터마이징할 수 있다"에 해당하는
# "복장/악세서리" 개념이라 별개 딕셔너리(wearables)로 분리했다. 아직 옷/장신구를
# 얻는 방법(상점/제작/줍기)이 전혀 없어(범위 밖, inbox #4 5번) 기본값은 전부
# 빈 슬롯이다 — "기본 코디 제공"은 이미 OUTFIT_COLOR로 그리는 하의 색으로
# 충족되어 있어(위 주석 참고) 이 슬롯들까지 기본으로 채울 필요는 없다고
# 판단했다.
const WEARABLE_SLOTS: Array[String] = ["hat", "top", "bottom", "shoes", "earring", "ring", "bag"]

var wearables: Dictionary = {
	"hat": "", "top": "", "bottom": "", "shoes": "", "earring": "", "ring": "", "bag": "",
}

func get_wearable(slot: String) -> String:
	return wearables.get(slot, "")

func equip_wearable(slot: String, item_name: String) -> void:
	wearables[slot] = item_name

func unequip_wearable(slot: String) -> void:
	wearables[slot] = ""

# inbox.md #6 5번: 휴대 장비 핫바. 인벤토리(E, 9칸 저장용 그리드)와는 별개로
# "지금 손에 들고 있는 것"을 가리키는 슬롯 5개다 — inbox #6이 "인벤토리 그리드
# 9칸과 섞이지 않게 UI/데이터 구조를 분리할 것"이라고 명시했으므로, inventory
# Dictionary(자원 종류->개수)와는 완전히 별개인 배열로 둔다. wearables(inbox #6
# 4번, status.md #56)와 마찬가지로 아직 인벤토리에서 핫바로 아이템을 옮기는
# 상호작용(드래그 등)이 없어(범위 밖, 줍기/제작과 함께 inbox #4 5번이 미룬
# 영역) 슬롯 내용물은 항상 빈 문자열이고, 이번 조각은 "숫자 1~5로 슬롯을
# 선택할 수 있다"는 데이터 구조 + UI만 갖춘다.
const HOTBAR_SIZE: int = 5

var hotbar: Array[String] = ["", "", "", "", ""]
var active_hotbar_index: int = 0

func get_hotbar_item(index: int) -> String:
	return hotbar[index] if index >= 0 and index < hotbar.size() else ""

func set_hotbar_item(index: int, item_name: String) -> void:
	if index >= 0 and index < hotbar.size():
		hotbar[index] = item_name

func select_hotbar_slot(index: int) -> void:
	if index >= 0 and index < hotbar.size():
		active_hotbar_index = index
