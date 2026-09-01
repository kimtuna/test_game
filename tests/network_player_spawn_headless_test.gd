extends SceneTree

# 헤드리스 환경에서 "호스트가 접속을 받으면 접속한 피어마다 Player 인스턴스를
# 스폰하고, 접속 해제되면 제거한다"는 최소 로직을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/network_player_spawn_headless_test.gd
#
# 실제 2-프로세스 ENet 접속(호스트/클라이언트)이 성립하는가는 status.md #32의
# network_spike_headless_test.gd가 이미 검증했다. 이번 조각에서 새로 생긴 것은
# "접속했을 때 Main이 실제로 Player 인스턴스를 스폰하는가"라는 게임 쪽 로직이므로,
# 별도 프로세스를 띄우지 않고 기본(오프라인) 멀티플레이어 피어 상태
# (multiplayer.is_server() == true)에서 NetworkManager의
# peer_connected_to_me/peer_disconnected_from_me 시그널 핸들러를 직접 호출해
# 서버 쪽 분기를 검증한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var ok := true

	# 오프라인 기본 상태에서도 자기 자신(peer id 1)은 기존과 동일하게 "Player"로
	# 스폰되어 있어야 한다 — 기존 12개 헤드리스 테스트가 이 이름에 의존한다.
	if main.get_node_or_null("Player") == null:
		push_error("FAIL: 시작 시 자기 자신(id=1)의 Player 인스턴스가 스폰되지 않음")
		ok = false

	# 새 피어(id=2)가 접속했다고 가정하고 시그널 핸들러를 직접 호출.
	main._on_peer_connected(2)
	await process_frame

	var joined_player: Node = main.get_node_or_null("Player_2")
	if joined_player == null:
		push_error("FAIL: 새 피어(id=2) 접속 시 Player_2 인스턴스가 스폰되지 않음")
		ok = false
	elif not joined_player.is_in_group("player"):
		push_error("FAIL: 새로 스폰된 Player_2가 'player' 그룹에 속하지 않음")
		ok = false

	var player_count := main.get_tree().get_nodes_in_group("player").size()
	if player_count != 2:
		push_error("FAIL: 'player' 그룹 노드 수가 2가 아님 (실제: %d)" % player_count)
		ok = false

	# 같은 피어의 접속 신호가 중복으로 와도 중복 스폰되면 안 된다.
	main._on_peer_connected(2)
	await process_frame
	player_count = main.get_tree().get_nodes_in_group("player").size()
	if player_count != 2:
		push_error("FAIL: 동일 피어 재접속 신호로 Player가 중복 스폰됨 (실제: %d)" % player_count)
		ok = false

	# 접속 해제되면 해당 피어의 Player만 제거되고, 다른 피어(자기 자신)는 남아야 한다.
	main._on_peer_disconnected(2)
	await process_frame
	await process_frame
	if main.get_node_or_null("Player_2") != null:
		push_error("FAIL: 피어(id=2) 접속 해제 후에도 Player_2가 남아있음")
		ok = false
	if main.get_node_or_null("Player") == null:
		push_error("FAIL: 다른 피어의 접속 해제가 자기 자신(id=1)의 Player까지 지워버림")
		ok = false

	if ok:
		print("HEADLESS_NETWORK_PLAYER_SPAWN_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_NETWORK_PLAYER_SPAWN_TEST: FAIL")
		quit(1)
