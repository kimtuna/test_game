extends Node2D

# 채집/사냥 결과를 화면에서 확인할 수 있게 하는 최소 UI.
# "harvestable" 그룹(나무, 처치된 동물)의 harvested 시그널을 구독해 자원별
# 개수를 인벤토리 라벨에 표시하고, "capturable" 그룹(동물)의 captured
# 시그널을 구독해 포획한 동물을 별도 라벨에 표시한다. 포획은 소비되는
# 자원이 아니라 "잡아서 소유하게 된 개체"라는 점이 달라 인벤토리와 분리했다.
#
# status.md #27까지는 장비 등급이 대상 등급보다 낮으면 상호작용이 막히기만
# 할 뿐, 등급을 실제로 "맞춰 나갈" 방법이 게임 내에 전혀 없었다(코드에서
# player.equip()을 직접 호출하는 테스트뿐). 이번 조각은 design.md 로드맵의
# "채집/사냥/포획 -> 등급·장비" 구간을 마무리하기 위해, 이미 모으고 있는
# 자원(통나무/고기)을 일정량 소비해 대응하는 장비(도끼/마취총) 등급을 자동으로
# 1씩 올리는 최소 경로를 추가했다. 상점 UI나 재료 선택 없이 "모으면 자동으로
# 승급"하는 가장 단순한 형태를 택했다 — design.md가 강화 방식의 세부를
# 명시하지 않았고(범위 밖), 상점/제작 UI를 새로 설계하면 규칙 4(기능 하나만)를
# 넘어서기 때문이다.

const UPGRADE_COST: int = 5
const MAX_EQUIPMENT_GRADE: int = 3
const RESOURCE_TO_SLOT: Dictionary = {
	"통나무": "tool",
	"고기": "weapon",
	"물고기": "rod",
	"채소": "sickle",
}

# inbox.md #6 3번: 인벤토리를 E키로 열고 닫는 그리드 UI. 마인크래프트/코어키퍼
# 참고 지시대로 "가방 없이 기본 9칸"을 자원 종류(distinct key) 개수 제한으로
# 구현했다 — 지금까지 inventory Dictionary는 종류 수 제한이 전혀 없었으므로,
# 이미 9칸을 채운 뒤 새로운 종류의 자원을 얻으면(이미 갖고 있던 종류를 더
# 얻는 것은 항상 허용) 그 자원은 얻지 못하고 버려진다. design.md/inbox
# 어디에도 초과분 처리(드롭, 대체 등)가 명시되지 않았고, 아직 아이템을
# 바닥에 버리는 시스템 자체가 없어(제작/줍기와 함께 범위 밖으로 미뤄짐,
# inbox #4 5번) 가장 단순하고 상식적인 기본값으로 판단했다.
const INVENTORY_CAPACITY: int = 9

# inbox.md #6 4번: 착용형 장비(복장/악세서리) 7슬롯의 UI 표시. player.gd의
# WEARABLE_SLOTS(영문 키)와 순서가 같아야 WearableColumn의 자식 순서와
# 대응된다 — 마인크래프트 인벤토리 화면처럼 인벤토리 그리드(E)와 같은 화면
# 안에 장비 슬롯 칸을 두는 편이, 아직 옷을 얻는 방법이 없는 지금 단계에서
# 별도 키 바인딩(지시에 명시되지 않음)을 새로 만드는 것보다 자연스럽다고
# 판단했다.
const WEARABLE_SLOT_NAMES: Dictionary = {
	"hat": "모자",
	"top": "상의",
	"bottom": "하의",
	"shoes": "신발",
	"earring": "귀걸이",
	"ring": "반지",
	"bag": "가방",
}

# inbox.md #4 4번(메인 메뉴 + 슬롯 선택 + 저장/불러오기 시스템)의 저장/불러오기
# 조각. 지금까지 슬롯별 외형(slot_colors)은 세션(프로세스) 안에서만
# 기억되어, "기존에 저장된 슬롯 선택 시 저장된 상태 그대로 이어서 시작"이
# 프로세스를 새로 켜면 항상 초기화됐다. 계정 시스템·클라우드 저장은 범위
# 밖이므로, 로컬 user:// 아래 슬롯별 JSON 파일에 외형/장비/인벤토리/포획
# 목록을 저장하는 가장 단순한 방식을 택했다. 튜토리얼은 design.md가 "처음에"
# 한 번만 안내한다고 명시해(캐릭터별이 아니라 계정 전체 기준) 슬롯과
# 별도로 파일 하나(TUTORIAL_SEEN_FLAG_PATH)의 존재 여부로만 판단한다.
const SAVE_DIR: String = "user://saves"
const TUTORIAL_SEEN_FLAG_PATH: String = "user://saves/tutorial_seen.flag"

var inventory: Dictionary = {}
var captured_animals: Dictionary = {}

@onready var inventory_label: Label = $UI/InventoryLabel
@onready var capture_label: Label = $UI/CaptureLabel
@onready var equipment_label: Label = $UI/EquipmentLabel
@onready var slot_overlay: Control = $UI/SlotOverlay
@onready var customization_overlay: Control = $UI/CustomizationOverlay
@onready var tutorial_overlay: Control = $UI/TutorialOverlay
@onready var pause_overlay: Control = $UI/PauseOverlay
@onready var inventory_overlay: Control = $UI/InventoryOverlay
@onready var inventory_slot_grid: GridContainer = $UI/InventoryOverlay/InventoryPanel/Body/SlotGrid
@onready var wearable_slot_column: VBoxContainer = $UI/InventoryOverlay/InventoryPanel/Body/WearableColumn
@onready var hotbar_row: HBoxContainer = $UI/Hotbar

# 색상 선택 키(1~4)와 스와치 색상을 한 곳에 묶어, 씬의 Swatch 노드 색과
# 어긋나지 않도록 함(#15/#22에서 배운 "값 중복으로 인한 잠재 버그" 반복 방지).
const BODY_COLOR_CHOICES: Dictionary = {
	KEY_1: Color(0.2, 0.6, 1.0),
	KEY_2: Color(0.9, 0.2, 0.2),
	KEY_3: Color(0.25, 0.75, 0.3),
	KEY_4: Color(0.6, 0.3, 0.8),
}

# 슬롯 선택 키(1~3)와 슬롯 번호 매핑. design.md의 "계정당 3개 캐릭터 슬롯".
# 이번 세션부터 슬롯별 외형/장비/인벤토리/포획 목록은 user://saves 아래
# 파일로도 저장되어(SAVE_DIR 근처 주석 참고) 프로세스를 새로 켜도 유지된다.
const SLOT_KEYS: Dictionary = {
	KEY_1: 1,
	KEY_2: 2,
	KEY_3: 3,
}

# inbox.md #6 5번: 휴대 장비 핫바 선택 키. SLOT_KEYS/BODY_COLOR_CHOICES와 같은
# 숫자 키(1~5)를 쓰지만, 이 매핑은 slot_overlay/customization_overlay가 모두
# 닫혀 있는 "실제 플레이 상태"에서만 확인한다(_unhandled_input에서 두 오버레이
# 분기가 먼저 return하므로 겹치지 않는다).
const HOTBAR_KEYS: Dictionary = {
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2,
	KEY_4: 3,
	KEY_5: 4,
}

# slot_colors: 슬롯 번호 -> 그 슬롯에서 마지막으로 고른 색. 아직 한 번도
# 커스터마이징하지 않은 슬롯은 키 자체가 없어, 처음 선택 시 커스터마이징
# 오버레이로 자연스럽게 이어진다.
# design.md의 "멀티플레이(세션 서버 방식)" 로드맵의 다음 조각. status.md #32가
# 만든 NetworkManager는 접속 자체(핸드셰이크)만 검증했고 실제 게임 오브젝트는
# 아직 하나도 연결되어 있지 않았다. 이번 조각은 "위치 동기화 없이, 접속하면
# 각자의 화면에 캐릭터가 나타난다"는 최소 수준까지만 다룬다 — 서버(호스트)가
# peer_connected_to_me/peer_disconnected_from_me 시그널을 받아 Player 인스턴스를
# 스폰/제거하면, Main.tscn에 새로 추가한 MultiplayerSpawner가 그 추가/제거를
# 다른 접속자에게 자동으로 복제한다. 이동/애니메이션 동기화(MultiplayerSynchronizer)
# 는 다음 단계로 미룬다.
#
# 자기 자신(호스트, peer id는 ENet 규약상 항상 1)은 기존과 동일하게 "Player"라는
# 이름으로 스폰한다 — 지금까지 쌓인 12개의 헤드리스 테스트가 모두
# `main.get_node("Player")`로 이 이름에 의존하고 있어, 이름을 바꾸면 멀티플레이와
# 무관한 기존 회귀 테스트가 전부 깨지기 때문이다. 이후 접속하는 피어는
# "Player_<id>"로 구분한다.
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const PLAYER_SPAWN_POSITION := Vector2(576, 324)

@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

var slot_colors: Dictionary = {}
var current_slot: int = 0
# pending_tutorial: 튜토리얼을 아직 한 번도 보여준 적이 없는가. _ready()에서
# TUTORIAL_SEEN_FLAG_PATH 존재 여부로 실제 값을 정하므로(계정 전체 기준,
# 프로세스를 새로 켜도 유지) 여기 기본값(true)은 파일이 없는 최초 실행에서만
# 그대로 쓰인다. 최초 슬롯 선택 -> (필요 시 커스터마이징) 흐름의 끝에서만
# true -> false로 소비되고, 이후 Tab으로 슬롯을 바꿀 때는 다시 띄우지 않는다.
var pending_tutorial: bool = true

func _ready() -> void:
	pending_tutorial = not FileAccess.file_exists(TUTORIAL_SEEN_FLAG_PATH)
	player_spawner.spawn_function = _create_player_instance
	var network_manager := get_node("/root/NetworkManager")
	network_manager.peer_connected_to_me.connect(_on_peer_connected)
	network_manager.peer_disconnected_from_me.connect(_on_peer_disconnected)
	if multiplayer.is_server():
		_spawn_player(multiplayer.get_unique_id())

	for node in get_tree().get_nodes_in_group("harvestable"):
		node.harvested.connect(_on_harvested)
	for node in get_tree().get_nodes_in_group("capturable"):
		node.captured.connect(_on_captured)
	_update_label()
	_update_capture_label()
	_update_equipment_label()
	_update_hotbar_ui()
	slot_overlay.visible = true

func _player_node_name(id: int) -> String:
	return "Player" if id == 1 else "Player_%d" % id

func _spawn_player(id: int) -> void:
	var node_name := _player_node_name(id)
	if has_node(node_name):
		return
	player_spawner.spawn(id)

# MultiplayerSpawner.spawn_function으로 등록되어, spawn(id) 호출 시 서버뿐
# 아니라 그 스폰을 전달받는 모든 피어에서 동일하게 실행된다(단순 add_child
# 감지 방식과 달리, 커스텀 spawn_function은 모든 피어가 같은 인자로 재실행하는
# 방식이라 이 안에서 정한 상태가 각 피어에 동일하게 반영된다). 여기서
# multiplayer_authority를 id로 지정해야, 이후 player.gd의
# is_multiplayer_authority() 체크가 모든 피어에서 "이 Player는 id 피어가
# 조작한다"는 동일한 결론에 도달한다 — set_multiplayer_authority를 서버에서만
# 호출하면 그 값은 로컬에만 적용되고 다른 피어에는 전달되지 않기 때문이다.
#
# 클라이언트 -> 서버 위치 동기화를 실측(tests/network_client_to_server_sync_headless_test.gd)
# 하다가 발견한 문제: 호스트(id=1)와 새로 접속한 피어가 똑같은
# PLAYER_SPAWN_POSITION에 겹쳐서 스폰되면, Godot의 CharacterBody2D가 "새로
# 생성된 바디가 다른 바디와 겹친 상태로 첫 물리 프레임을 맞으면 자동으로
# 겹침에서 빠져나오려 한다"는 특성 때문에(velocity가 0이어도 move_and_slide()
# 호출 시 발생) 새로 스폰된 쪽이 스스로도 모르게 몇십 픽셀 밀려나고, 그 순간의
# 위치가 위치 동기화(스폰 시점 스냅샷)와 뒤엉켜 다른 피어가 보는 좌표가
# 실제 값과 어긋나는 상태로 굳어버렸다. 호스트(id=1)는 다른 헤드리스 테스트가
# 이미 PLAYER_SPAWN_POSITION을 그대로 가정하고 있어 건드리지 않고, 새로
# 접속하는 피어만 겹치지 않는 위치로 스폰해 문제의 원인 자체(겹침)를 없앤다.
#
# status.md #37은 이 오프셋이 고정 벡터(60, 0)라 동시에(또는 순차적으로) 2명
# 이상 접속하면 신규 피어 전원이 똑같은 좌표에 다시 겹쳐 스폰되는 한계를
# 남겼다. 이번 조각은 접속 "순서"를 세는 카운터를 두고, 그 순서에 따라 매번
# 다른 각도로 회전한 위치에 스폰해 겹침을 없앤다. 원형 배치를 택한 이유는
# 방향 하나로만 계속 밀면(예: 60,120,180...) 인원이 늘수록 섬 경계(바다)를
# 넘어갈 수 있는 반면, 반지름을 고정하고 각도만 바꾸면 인원이 아무리 늘어도
# 스폰 지점에서 벗어나는 거리가 일정하게 유지되기 때문이다. 이 카운터는
# MultiplayerSpawner가 모든 피어에 같은 순서로 복제하는 spawn(id) 이벤트에
# 의해서만 증가하므로(각 피어가 로컬 시계로 독립 판단하는 것이 아니라 같은
# 이벤트 스트림을 같은 순서로 재생), 모든 피어에서 항상 같은 결과에 도달한다.
const JOINING_PLAYER_SPAWN_RADIUS: float = 60.0
const JOINING_PLAYER_SPAWN_ANGLE_STEP: float = PI / 4.0

var _join_spawn_index: int = 0

func _create_player_instance(id: int) -> Node:
	var player := PLAYER_SCENE.instantiate()
	player.name = _player_node_name(id)
	if id == 1:
		player.position = PLAYER_SPAWN_POSITION
	else:
		player.position = PLAYER_SPAWN_POSITION + _join_spawn_offset(_join_spawn_index)
		_join_spawn_index += 1
	player.set_multiplayer_authority(id)
	return player

func _join_spawn_offset(index: int) -> Vector2:
	var angle := index * JOINING_PLAYER_SPAWN_ANGLE_STEP
	return Vector2(JOINING_PLAYER_SPAWN_RADIUS, 0).rotated(angle)

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(id)

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var node := get_node_or_null(_player_node_name(id))
		if node:
			node.queue_free()

# design.md의 "캐릭터 슬롯"과 "캐릭터 외형을 커스터마이징할 수 있다"를 잇는
# 흐름. 시작 시 슬롯(1~3)을 고르면 (1) 이번 세션에서 이미 고른 적 있는
# 슬롯이면 메모리에 있는 slot_colors를 즉시 적용하고, (2) 세션 중엔 처음
# 골랐지만 디스크에 저장 파일이 있는 슬롯이면 그 파일을 불러와 적용하고
# (_apply_slot_data), (3) 저장 파일도 없는 진짜 새 슬롯이면 커스터마이징
# 오버레이로 이어진다. 게임 중에도 Tab 키로 언제든 슬롯 오버레이를 다시 열어
# 슬롯을 바꿀 수 있다. 계정 시스템(로그인 등)은 여전히 범위 밖이다.
#
# status.md #50이 남긴 "게임 중 메인 메뉴로 나가는 흐름" 공백을 메우는 조각.
# 다른 오버레이(슬롯/커스터마이징/튜토리얼)가 떠 있지 않을 때만 ESC로
# 일시정지 메뉴(PauseOverlay)를 연다 — 슬롯 선택 중에 ESC를 누르면 메뉴 밖으로
# 나가버리는 경우를 막기 위함이다. 실제 재개/메인 메뉴 이동 로직은
# pause_overlay.gd에 있다(그 노드만 process_mode=ALWAYS라 get_tree().paused
# 상태에서도 입력을 받을 수 있기 때문에, 그 이후의 입력 처리는 이 함수가 아니라
# 그 스크립트가 맡는다).
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if slot_overlay.visible:
		if SLOT_KEYS.has(event.keycode):
			current_slot = SLOT_KEYS[event.keycode]
			slot_overlay.visible = false
			if slot_colors.has(current_slot):
				var player := get_tree().get_first_node_in_group("player")
				if player != null:
					player.set_body_color(slot_colors[current_slot])
				_maybe_show_tutorial()
			elif _has_save(current_slot):
				_apply_slot_data(_load_slot(current_slot))
				_maybe_show_tutorial()
			else:
				customization_overlay.visible = true
			get_viewport().set_input_as_handled()
		return

	if customization_overlay.visible:
		if BODY_COLOR_CHOICES.has(event.keycode):
			var color: Color = BODY_COLOR_CHOICES[event.keycode]
			var player := get_tree().get_first_node_in_group("player")
			if player != null:
				player.set_body_color(color)
			slot_colors[current_slot] = color
			customization_overlay.visible = false
			_save_slot(current_slot)
			_maybe_show_tutorial()
			get_viewport().set_input_as_handled()
		return

	if tutorial_overlay.visible:
		tutorial_overlay.visible = false
		get_viewport().set_input_as_handled()
		return

	# inbox.md #6 3번: 인벤토리 오버레이는 게임을 멈추지 않는(process_mode를
	# 건드리지 않는) 단순 토글이다 — pause_overlay처럼 SceneTree를 멈추면 여러
	# 접속자가 있는 멀티플레이 세션에서 한 명이 인벤토리를 열 때마다 다른
	# 플레이어까지 함께 멈추게 되므로, 그 방식은 부적절하다고 판단했다.
	if inventory_overlay.visible:
		if event.keycode == KEY_E:
			inventory_overlay.visible = false
			get_viewport().set_input_as_handled()
		return

	if pause_overlay.visible:
		return

	# inbox.md #6 5번: 숫자 1~5로 핫바 슬롯을 선택한다. 위에서 이미 slot_overlay/
	# customization_overlay/tutorial_overlay/inventory_overlay/pause_overlay가
	# 열려있으면 전부 return했으므로, 여기 도달했다는 것은 그 숫자 키들이 다른
	# 오버레이의 의미(슬롯 선택, 색상 선택)와 겹치지 않는 "실제 플레이 상태"라는
	# 뜻이다.
	if HOTBAR_KEYS.has(event.keycode):
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			player.select_hotbar_slot(HOTBAR_KEYS[event.keycode])
			_update_hotbar_ui()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_ESCAPE:
		pause_overlay.visible = true
		get_tree().paused = true
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_TAB:
		slot_overlay.visible = true
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_E:
		_update_inventory_grid()
		_update_wearable_slots()
		inventory_overlay.visible = true
		get_viewport().set_input_as_handled()

func _maybe_show_tutorial() -> void:
	if pending_tutorial:
		tutorial_overlay.visible = true
		pending_tutorial = false
		_mark_tutorial_seen()

func _mark_tutorial_seen() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(TUTORIAL_SEEN_FLAG_PATH, FileAccess.WRITE)
	file.store_string("1")
	file.close()

func _slot_save_path(slot: int) -> String:
	return "%s/slot_%d.save" % [SAVE_DIR, slot]

func _has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_save_path(slot))

func _save_slot(slot: int) -> void:
	if slot <= 0 or not slot_colors.has(slot):
		return
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var player := get_tree().get_first_node_in_group("player")
	var data := {
		"color": [slot_colors[slot].r, slot_colors[slot].g, slot_colors[slot].b],
		"equipment": player.equipment if player != null else {},
		"wearables": player.wearables if player != null else {},
		"hotbar": player.hotbar if player != null else [],
		"active_hotbar_index": player.active_hotbar_index if player != null else 0,
		"inventory": inventory,
		"captured_animals": captured_animals,
	}
	var file := FileAccess.open(_slot_save_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _load_slot(slot: int) -> Dictionary:
	var file := FileAccess.open(_slot_save_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

# 저장된 슬롯을 선택했을 때(_has_save == true), 저장 시점의 외형/장비/
# 인벤토리/포획 목록을 그대로 복원한다. "새 슬롯"과 달리 커스터마이징
# 오버레이를 거치지 않고 곧바로 이어서 시작한다.
func _apply_slot_data(data: Dictionary) -> void:
	var c: Array = data.get("color", [])
	if c.size() == 3:
		slot_colors[current_slot] = Color(c[0], c[1], c[2])
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		if slot_colors.has(current_slot):
			player.set_body_color(slot_colors[current_slot])
		var equip_data: Dictionary = data.get("equipment", {})
		for slot_name in equip_data.keys():
			var item: Dictionary = equip_data[slot_name]
			player.equip(slot_name, item.get("name", ""), int(item.get("grade", 1)))
		var wearable_data: Dictionary = data.get("wearables", {})
		for slot_name in wearable_data.keys():
			player.equip_wearable(slot_name, String(wearable_data[slot_name]))
		var hotbar_data: Array = data.get("hotbar", [])
		for i in range(hotbar_data.size()):
			player.set_hotbar_item(i, String(hotbar_data[i]))
		player.select_hotbar_slot(int(data.get("active_hotbar_index", 0)))
	inventory.clear()
	for key in data.get("inventory", {}).keys():
		inventory[key] = int(data["inventory"][key])
	captured_animals.clear()
	for key in data.get("captured_animals", {}).keys():
		captured_animals[key] = int(data["captured_animals"][key])
	_update_label()
	_update_capture_label()
	_update_equipment_label()
	_update_hotbar_ui()

func _on_harvested(resource_name: String, amount: int) -> void:
	if not inventory.has(resource_name) and inventory.size() >= INVENTORY_CAPACITY:
		print("인벤토리가 가득 찼다 (%d/%d칸). %s을(를) 얻지 못했다." % [INVENTORY_CAPACITY, INVENTORY_CAPACITY, resource_name])
		return
	inventory[resource_name] = inventory.get(resource_name, 0) + amount
	_try_upgrade_equipment(resource_name)
	_update_label()
	if inventory_overlay.visible:
		_update_inventory_grid()
	_save_slot(current_slot)

func _try_upgrade_equipment(resource_name: String) -> void:
	var slot: String = RESOURCE_TO_SLOT.get(resource_name, "")
	if slot == "":
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var current_grade: int = player.get_equipment_grade(slot)
	if current_grade >= MAX_EQUIPMENT_GRADE:
		return
	if inventory.get(resource_name, 0) < UPGRADE_COST:
		return
	inventory[resource_name] -= UPGRADE_COST
	var item_name: String = player.equipment[slot]["name"]
	var new_grade: int = current_grade + 1
	player.equip(slot, item_name, new_grade)
	print("%s x%d을 소비해 %s을(를) Lv.%d로 강화했다." % [resource_name, UPGRADE_COST, item_name, new_grade])
	_update_equipment_label()

func _on_captured(animal_name: String) -> void:
	captured_animals[animal_name] = captured_animals.get(animal_name, 0) + 1
	_update_capture_label()
	_save_slot(current_slot)

func _update_label() -> void:
	if inventory.is_empty():
		inventory_label.text = ""
		return
	var lines: Array[String] = []
	for resource_name in inventory.keys():
		lines.append("%s: %d" % [resource_name, inventory[resource_name]])
	inventory_label.text = "\n".join(lines)

# inbox.md #6 3번: 9칸 그리드에 inventory(Dictionary, 종류->개수)의 각 항목을
# 순서대로 채우고, 남는 칸은 빈 슬롯("-")으로 표시한다. 아이콘 리소스가 없어
# (범위 밖, design.md "아트 스타일" 참고) 슬롯 안에는 자원 이름과 개수만
# 텍스트로 표시한다.
func _update_inventory_grid() -> void:
	var keys: Array = inventory.keys()
	var slots := inventory_slot_grid.get_children()
	for i in range(slots.size()):
		var label: Label = slots[i].get_node("SlotLabel")
		if i < keys.size():
			var resource_name: String = keys[i]
			label.text = "%s\n%d" % [resource_name, inventory[resource_name]]
		else:
			label.text = "-"

# inbox.md #6 4번: WearableColumn의 7개 Panel을 WEARABLE_SLOT_NAMES 순서(=
# player.gd의 WEARABLE_SLOTS 순서)대로 훑으며 "이름: 착용중인 아이템(없으면 -)"을
# 표시한다.
func _update_wearable_slots() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var panels := wearable_slot_column.get_children()
	var slot_keys: Array = WEARABLE_SLOT_NAMES.keys()
	for i in range(panels.size()):
		var label: Label = panels[i].get_node("WearableLabel")
		var slot_key: String = slot_keys[i]
		var item_name: String = player.get_wearable(slot_key)
		label.text = "%s: %s" % [WEARABLE_SLOT_NAMES[slot_key], item_name if item_name != "" else "-"]

# inbox.md #6 5번: 항상 화면 하단에 보이는 5칸 핫바. 인벤토리(E) 오버레이와
# 달리 토글되지 않고 계속 표시된다(마인크래프트/코어키퍼 참고 지시와 동일하게
# 실제 게임 플레이 중에도 어떤 슬롯이 선택돼 있는지 항상 보여야 의미가 있다).
# 선택된 슬롯은 self_modulate로 강조하고, 슬롯 안에는 번호+내용물(아직 비어
# 있으면 "-")을 표시한다.
const HOTBAR_ACTIVE_COLOR := Color(1.0, 0.85, 0.3)
const HOTBAR_INACTIVE_COLOR := Color(1.0, 1.0, 1.0)

func _update_hotbar_ui() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var panels := hotbar_row.get_children()
	for i in range(panels.size()):
		var panel: Panel = panels[i]
		var label: Label = panel.get_node("HotbarLabel")
		var item_name: String = player.get_hotbar_item(i) if player != null else ""
		label.text = "%d\n%s" % [i + 1, item_name if item_name != "" else "-"]
		var is_active: bool = player != null and player.active_hotbar_index == i
		panel.self_modulate = HOTBAR_ACTIVE_COLOR if is_active else HOTBAR_INACTIVE_COLOR

func _update_capture_label() -> void:
	if captured_animals.is_empty():
		capture_label.text = ""
		return
	var lines: Array[String] = []
	for animal_name in captured_animals.keys():
		lines.append("포획: %s x%d" % [animal_name, captured_animals[animal_name]])
	capture_label.text = "\n".join(lines)

func _update_equipment_label() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		equipment_label.text = ""
		return
	var lines: Array[String] = []
	for slot in RESOURCE_TO_SLOT.values():
		var item: Dictionary = player.equipment.get(slot, {})
		lines.append("%s Lv.%d" % [item.get("name", "-"), item.get("grade", 0)])
	equipment_label.text = "\n".join(lines)
