extends SceneTree

# network_client_to_server_sync_headless_test.gd가 백그라운드 프로세스로 띄우는
# "클라이언트" 역할. 단독으로는 실행할 필요가 없다. 서버에 접속한 뒤 자신이
# authority를 가진 Player를 찾아 위치를 강제로 옮겨, 그 변화가 서버 쪽에도
# 복제되는지 확인할 수 있게 한다 — status.md #35가 실측한 "서버 -> 클라이언트"
# 방향과 반대 방향(status.md #36이 남긴 과제).
#
# Godot의 고수준 멀티플레이어는 접속하는 클라이언트에게 순차적인 ID(2, 3, ...)가
# 아니라 무작위 31비트 고유 ID를 배정한다(호스트만 항상 1). 그래서 스폰되는 자신의
# Player 노드 이름("Player" 또는 "Player_<id>", scripts/main.gd의 _player_node_name과
# 동일한 규칙)도 접속 전에는 알 수 없어, 접속 후 get_multiplayer().get_unique_id()로
# 실제 배정된 id를 확인해 노드 이름을 계산한다(처음엔 "Player_2"로 고정 가정했다가
# 실제 실행에서 무작위 id가 배정되는 것을 확인하고 고쳤다).
# 실행(수동 확인용): godot --headless --path . --script res://tests/network_client_move_headless.gd

const PORT := 8923
const TARGET_POSITION := Vector2(222.0, 777.0)
const SERVER_STARTUP_GRACE_SECONDS := 1.5
const CONNECT_TIMEOUT_SECONDS := 8.0
const SPAWN_TIMEOUT_SECONDS := 8.0
const LIFETIME_TIMEOUT_SECONDS := 12.0

enum Stage { WAIT_SERVER_STARTUP, CONNECTING, WAIT_OWN_PLAYER, DONE }

var stage: int = Stage.WAIT_SERVER_STARTUP
var network_manager: Node
var main: Node
var stage_elapsed := 0.0
var total_elapsed := 0.0

func _process(delta: float) -> bool:
	total_elapsed += delta
	stage_elapsed += delta
	match stage:
		Stage.WAIT_SERVER_STARTUP:
			if stage_elapsed < SERVER_STARTUP_GRACE_SECONDS:
				return false
			network_manager = root.get_node("NetworkManager")
			var err: Error = network_manager.join("127.0.0.1", PORT)
			if err != OK:
				print("NETWORK_CLIENT_MOVE: JOIN_FAILED (%d)" % err)
				quit(1)
				return true
			stage = Stage.CONNECTING
			stage_elapsed = 0.0
			return false

		Stage.CONNECTING:
			var peer := get_multiplayer().multiplayer_peer
			if peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				main = load("res://scenes/Main.tscn").instantiate()
				root.add_child(main)
				stage = Stage.WAIT_OWN_PLAYER
				stage_elapsed = 0.0
				return false
			if stage_elapsed >= CONNECT_TIMEOUT_SECONDS:
				print("NETWORK_CLIENT_MOVE: CONNECT_TIMEOUT")
				quit(1)
				return true
			return false

		Stage.WAIT_OWN_PLAYER:
			var own_id := get_multiplayer().get_unique_id()
			var player_node_name := "Player" if own_id == 1 else "Player_%d" % own_id
			var player: Node = main.get_node_or_null(player_node_name)
			if player != null:
				player.position = TARGET_POSITION
				print("NETWORK_CLIENT_MOVE: MOVED pos=%s authority=%s own_id=%s" % [player.position, player.get_multiplayer_authority(), own_id])
				stage = Stage.DONE
				stage_elapsed = 0.0
				return false
			if stage_elapsed >= SPAWN_TIMEOUT_SECONDS:
				print("NETWORK_CLIENT_MOVE: SPAWN_TIMEOUT")
				quit(1)
				return true
			return false

		Stage.DONE:
			if total_elapsed >= LIFETIME_TIMEOUT_SECONDS:
				print("NETWORK_CLIENT_MOVE: DONE")
				quit(0)
				return true
			return false

	return false
