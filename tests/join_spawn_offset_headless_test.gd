extends SceneTree

# status.md #37이 남긴 한계("3명 이상 동시 접속 시 여러 신규 피어가 같은
# 오프셋 좌표에 겹쳐 스폰될 수 있음")를 보완한 접속 순서 기반 원형 오프셋
# 로직을 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/join_spawn_offset_headless_test.gd
#
# 실제 2-프로세스 ENet 접속은 status.md #32/#37이 이미 검증했으므로, 이번
# 조각에서 새로 생긴 것은 "여러 피어가 연달아 접속했을 때 서로 겹치지 않는
# 위치에 스폰되는가"라는 게임 쪽 로직이다. network_player_spawn_headless_test.gd와
# 같은 패턴으로 오프라인 기본 상태에서 _on_peer_connected를 여러 번 직접
# 호출해 검증한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var ok := true

	# 피어 2, 3, 4가 연달아 접속한다고 가정.
	main._on_peer_connected(2)
	await process_frame
	main._on_peer_connected(3)
	await process_frame
	main._on_peer_connected(4)
	await process_frame

	var host_player: Node2D = main.get_node_or_null("Player")
	var p2: Node2D = main.get_node_or_null("Player_2")
	var p3: Node2D = main.get_node_or_null("Player_3")
	var p4: Node2D = main.get_node_or_null("Player_4")

	if host_player == null or p2 == null or p3 == null or p4 == null:
		push_error("FAIL: 접속한 4개 피어(1,2,3,4)의 Player 인스턴스가 모두 스폰되지 않음")
		ok = false
	else:
		var positions: Array[Vector2] = [host_player.position, p2.position, p3.position, p4.position]
		for i in positions.size():
			for j in range(i + 1, positions.size()):
				if positions[i].distance_to(positions[j]) < 1.0:
					push_error("FAIL: 서로 다른 피어의 스폰 위치가 겹침 (%s == %s)" % [positions[i], positions[j]])
					ok = false

		# 신규 접속 피어는 host 스폰 지점에서 반지름(JOINING_PLAYER_SPAWN_RADIUS)
		# 만큼만 떨어져야 한다 — 인원이 늘어도 섬 경계 밖으로 밀려나지 않도록
		# 방향이 아니라 각도로 분산시키는 설계이기 때문.
		for p in [p2, p3, p4]:
			var dist: float = p.position.distance_to(host_player.position)
			if absf(dist - main.JOINING_PLAYER_SPAWN_RADIUS) > 0.5:
				push_error("FAIL: 신규 피어 스폰 반지름이 예상과 다름 (실제: %f)" % dist)
				ok = false

	if ok:
		print("HEADLESS_JOIN_SPAWN_OFFSET_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_JOIN_SPAWN_OFFSET_TEST: FAIL")
		quit(1)
