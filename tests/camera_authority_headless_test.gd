extends SceneTree

# status.md #33/#34가 남긴 제약("Camera2D.enabled가 authority와 무관하게
# 항상 true")을 이번 조각(player.gd의 _ready()에서 camera.enabled =
# is_multiplayer_authority()로 설정)으로 고쳤는지 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/camera_authority_headless_test.gd
#
# 실제 ENet 접속 여부는 network_spike_headless_test.gd가 이미 검증했으므로,
# network_player_spawn_headless_test.gd와 동일하게 오프라인 기본 멀티플레이어
# 피어 상태(multiplayer.get_unique_id() == 1)에서 main._on_peer_connected(2)를
# 직접 호출해 "다른 피어(id=2)의 Player"를 스폰시키고, 그 카메라가 꺼져 있는지
# 확인한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var ok := true

	var own_player: Node = main.get_node_or_null("Player")
	if own_player == null:
		push_error("FAIL: 시작 시 자기 자신(id=1)의 Player 인스턴스가 스폰되지 않음")
		ok = false
	elif not own_player.camera.enabled:
		push_error("FAIL: 자기 자신(authority)의 카메라가 꺼져 있음")
		ok = false

	main._on_peer_connected(2)
	await process_frame

	var other_player: Node = main.get_node_or_null("Player_2")
	if other_player == null:
		push_error("FAIL: 새 피어(id=2) 접속 시 Player_2 인스턴스가 스폰되지 않음")
		ok = false
	elif other_player.camera.enabled:
		push_error("FAIL: 다른 피어(authority가 아닌) Player_2의 카메라가 켜져 있음")
		ok = false

	if ok:
		print("HEADLESS_CAMERA_AUTHORITY_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_CAMERA_AUTHORITY_TEST: FAIL")
		quit(1)
