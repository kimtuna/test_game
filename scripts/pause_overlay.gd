extends Control

# status.md #50이 남긴 "게임 중 메인 메뉴로 나가는 흐름"을 채우는 조각.
# ESC로 일시정지 메뉴를 열면 get_tree().paused = true로 실제 게임플레이
# (Player/Animal 등 물리 처리)를 멈춘다. 이 노드(및 자식 버튼들)만
# process_mode = ALWAYS로 둬서, 트리가 멈춘 동안에도 "이어하기"/"메인 메뉴로"
# 버튼과 ESC 재입력은 계속 반응한다 — Main 자신은 기본 process_mode(PAUSABLE)
# 그대로 둬서 다른 게임플레이 노드(Player/Animal/Tree 등, Main의 형제가 아니라
# 자식들)까지 함께 멈추게 하려는 의도다. Main.process_mode를 ALWAYS로 바꾸는
# 방식은 상속 때문에 모든 자식(Player 포함)이 함께 멈추지 않게 되어 버려서
# 쓰지 않았다.

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_resume()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	_resume()

func _resume() -> void:
	get_tree().paused = false
	visible = false

func _on_main_menu_pressed() -> void:
	# change_scene_to_file 이후에도 SceneTree.paused는 씬 전환과 무관하게
	# 유지되는 전역 상태라, 여기서 풀지 않으면 새로 뜬 메인 메뉴가 계속
	# 일시정지 상태로 남아 버튼이 눌리지 않는다(메인 메뉴 자체는 process_mode
	# 기본값이라 paused 상태에서 입력을 못 받는다).
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
