extends Node

# inbox.md #10: 창 크기를 project.godot의 정적 window/size 설정에 맡기지 않고
# 런타임 코드로 지정한다 - 에디터가 프로젝트를 저장할 때 그 정적 설정을
# 건드려 깨진 적이 있었기 때문에(status.md #70 이전 관찰), 실제 실행되는
# 해상도는 항상 이 오토로드가 최종 결정하게 만든다.

# inbox.md #11: 향후 PvP를 넣을 계획이라, 해상도 선택이 시야(맵이 보이는
# 범위)에 영향을 주면 안 된다. project.godot의 window/stretch/aspect="keep"
# 설정과 짝을 이뤄, 여기 목록은 반드시 전부 같은 화면비(16:9)여야 한다 -
# 화면비가 섞이면 레터박스 여부가 갈려 해상도가 게임플레이 이점이 될 수
# 있다. 새 해상도를 추가할 때도 16:9(가로:세로 = 16:9)만 넣을 것.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(800, 450),
	Vector2i(1152, 648),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
const DEFAULT_RESOLUTION_INDEX := 1
const SETTINGS_PATH := "user://settings.cfg"

var resolution_index: int = DEFAULT_RESOLUTION_INDEX

func _ready() -> void:
	_load_settings()
	_apply_window_size()

func resolution_label(index: int) -> String:
	var size: Vector2i = RESOLUTIONS[index]
	return "%d x %d" % [size.x, size.y]

func set_resolution(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size():
		return
	resolution_index = index
	_apply_window_size()
	_save_settings()

func _apply_window_size() -> void:
	if DisplayServer.get_name() == "headless":
		return
	get_window().size = RESOLUTIONS[resolution_index]

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	var loaded: int = int(cfg.get_value("display", "resolution_index", DEFAULT_RESOLUTION_INDEX))
	resolution_index = loaded if loaded >= 0 and loaded < RESOLUTIONS.size() else DEFAULT_RESOLUTION_INDEX

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "resolution_index", resolution_index)
	cfg.save(SETTINGS_PATH)
