extends Control

# inbox.md #4 4번: 게임 실행 시 바로 플레이 화면(Main.tscn)으로 들어가지 않고
# 시작/설정/종료를 고르는 메인 메뉴를 먼저 보여준다. 슬롯 선택·커스터마이징·
# 저장/불러오기는 이미 Main.tscn의 SlotOverlay/CustomizationOverlay가
# 담당하므로(status.md #31~#33, 이번 세션에서 디스크 저장 추가), 이 씬은
# "시작" 선택 시 Main.tscn으로 전환하는 진입점 역할만 한다.

@onready var main_panel: VBoxContainer = $MainPanel
@onready var settings_panel: VBoxContainer = $SettingsPanel
@onready var fullscreen_check: CheckButton = $SettingsPanel/FullscreenCheck
@onready var resolution_option: OptionButton = $SettingsPanel/ResolutionOption

func _ready() -> void:
	# 헤드리스 실행(DisplayServer가 실제 창을 갖지 않음)에서는 창 모드 조회/
	# 변경이 의미가 없으므로 건드리지 않는다 - 헤드리스 테스트가 이 씬을
	# 그대로 인스턴스화해 버튼 동작을 검증하기 때문에, 여기서 예외가 나면
	# 안 된다.
	if DisplayServer.get_name() != "headless":
		fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	for i in range(GameSettings.RESOLUTIONS.size()):
		resolution_option.add_item(GameSettings.resolution_label(i))
	resolution_option.select(GameSettings.resolution_index)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_pressed() -> void:
	main_panel.visible = false
	settings_panel.visible = true

func _on_back_pressed() -> void:
	settings_panel.visible = false
	main_panel.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_fullscreen_toggled(pressed: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_resolution_selected(index: int) -> void:
	GameSettings.set_resolution(index)
