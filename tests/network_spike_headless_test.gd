extends SceneTree

# design.md 로드맵의 마지막 큰 단계 "멀티플레이"의 첫 착수점 검증.
# status.md #31의 판단(아키텍처 결정 비중이 커서, 게임 로직에 앞서 가장 작은
# 착수점부터 검증)에 따라, ENetMultiplayerPeer로 실제 로컬 루프백(127.0.0.1)
# 접속이 성립하는지만 확인한다. 한 프로세스 안에서는 진짜 네트워크 핸드셰이크를
# 거치지 않으므로, 서버 역할은 별도 headless Godot 프로세스(network_server_headless.gd)
# 로 띄우고 이 프로세스는 클라이언트가 되어 접속을 시도한다.
# 실행: godot --headless --path . --script res://tests/network_spike_headless_test.gd

const PORT := 8921
const CONNECT_TIMEOUT_SECONDS := 8.0
const SERVER_STARTUP_GRACE_SECONDS := 1.5

var server_pid := -1
var startup_elapsed := 0.0
var waited_for_startup := false
var connect_elapsed := 0.0
var network_manager: Node

func _initialize() -> void:
	network_manager = root.get_node("NetworkManager")
	server_pid = OS.create_process("godot", [
		"--headless", "--path", ".", "--script", "res://tests/network_server_headless.gd"
	])
	if server_pid <= 0:
		push_error("FAIL: 서버 프로세스를 띄우지 못함")
		print("HEADLESS_NETWORK_SPIKE_TEST: FAIL")
		quit(1)

func _process(delta: float) -> bool:
	if not waited_for_startup:
		startup_elapsed += delta
		if startup_elapsed < SERVER_STARTUP_GRACE_SECONDS:
			return false
		waited_for_startup = true
		var err: Error = network_manager.join("127.0.0.1", PORT)
		if err != OK:
			push_error("FAIL: 클라이언트 접속 시도 실패 (%d)" % err)
			_cleanup()
			print("HEADLESS_NETWORK_SPIKE_TEST: FAIL")
			quit(1)
			return true
		return false

	connect_elapsed += delta
	var peer := get_multiplayer().multiplayer_peer
	if peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("HEADLESS_NETWORK_SPIKE_TEST: PASS (client_peer_id=%d)" % get_multiplayer().get_unique_id())
		_cleanup()
		quit(0)
		return true
	if connect_elapsed >= CONNECT_TIMEOUT_SECONDS:
		push_error("FAIL: 접속 타임아웃")
		print("HEADLESS_NETWORK_SPIKE_TEST: FAIL")
		_cleanup()
		quit(1)
		return true
	return false

func _cleanup() -> void:
	network_manager.stop()
	if server_pid > 0 and OS.is_process_running(server_pid):
		OS.kill(server_pid)
