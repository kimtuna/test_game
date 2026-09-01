extends SceneTree

# network_position_sync_headless_test.gd가 백그라운드 프로세스로 띄우는 "서버" 역할.
# 단독으로는 실행할 필요가 없다. 클라이언트가 접속하면 잠시 기다린 뒤 자신의
# Player 위치를 강제로 옮겨, 그 변화가 클라이언트 쪽에 복제되는지 확인할 수 있게
# 한다.
# 실행(수동 확인용): godot --headless --path . --script res://tests/network_sync_server_headless.gd

const PORT := 8922
const TARGET_POSITION := Vector2(999.0, 111.0)
const MOVE_DELAY_AFTER_CONNECT_SECONDS := 1.5
const LIFETIME_TIMEOUT_SECONDS := 12.0

var network_manager: Node
var main: Node
var hosted := false
var moved := false
var elapsed_since_connect := 0.0
var total_elapsed := 0.0

func _process(delta: float) -> bool:
	total_elapsed += delta

	if not hosted:
		hosted = true
		network_manager = root.get_node("NetworkManager")
		var err: Error = network_manager.host(PORT)
		if err != OK:
			print("NETWORK_SYNC_SERVER: HOST_FAILED (%d)" % err)
			quit(1)
			return true
		main = load("res://scenes/Main.tscn").instantiate()
		root.add_child(main)
		return false

	if not moved:
		if get_multiplayer().get_peers().is_empty():
			if total_elapsed >= LIFETIME_TIMEOUT_SECONDS:
				print("NETWORK_SYNC_SERVER: TIMEOUT_NO_PEER")
				quit(1)
				return true
			return false
		elapsed_since_connect += delta
		if elapsed_since_connect < MOVE_DELAY_AFTER_CONNECT_SECONDS:
			return false
		var player: Node = main.get_node_or_null("Player")
		if player == null:
			print("NETWORK_SYNC_SERVER: NO_LOCAL_PLAYER")
			quit(1)
			return true
		player.position = TARGET_POSITION
		moved = true
		print("NETWORK_SYNC_SERVER: MOVED")
		return false

	if total_elapsed >= LIFETIME_TIMEOUT_SECONDS:
		print("NETWORK_SYNC_SERVER: DONE")
		quit(0)
		return true
	return false
