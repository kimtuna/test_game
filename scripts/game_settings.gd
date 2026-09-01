extends Node

# inbox.md #10: 창 크기를 project.godot의 정적 window/size 설정에 맡기지 않고
# 런타임 코드로 지정한다 - 에디터가 프로젝트를 저장할 때 그 정적 설정을
# 건드려 깨진 적이 있었기 때문에(status.md #70 이전 관찰), 실제 실행되는
# 해상도는 항상 이 오토로드가 최종 결정하게 만든다.

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
