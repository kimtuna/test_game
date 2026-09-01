extends SceneTree

# design.md 로드맵 "멀티플레이"의 다음 조각. status.md #34가 Player.tscn에
# MultiplayerSynchronizer(position)를 추가한 뒤 "실제 2-프로세스 환경에서
# 한쪽의 이동이 반대쪽 화면에도 복제되는지는 아직 실측하지 않았다"고 남긴
# 과제를 이번 조각(MultiplayerSynchronizer 추가 자체)과 함께 검증한다.
# status.md #32/#33이 검증에 쓴 "headless 서버 프로세스 + headless 클라이언트
# 프로세스" 패턴을 그대로 재사용한다. 포트는 기존 network_spike 테스트(8921)와
# 겹치지 않도록 8922를 쓴다 — 같은 세션에서 두 테스트를 연달아 돌릴 때 소켓이
# 완전히 정리되기 전에 재사용되는 것을 피하기 위함.
# 실행: godot --headless --path . --script res://tests/network_position_sync_headless_test.gd

const PORT := 8922
const TARGET_POSITION := Vector2(999.0, 111.0)
const POSITION_TOLERANCE := 1.0
const SERVER_STARTUP_GRACE_SECONDS := 1.5
const CONNECT_TIMEOUT_SECONDS := 8.0
const SPAWN_REPLICATION_TIMEOUT_SECONDS := 5.0
const SYNC_TIMEOUT_SECONDS := 8.0

enum Stage { WAIT_SERVER_STARTUP, CONNECTING, WAIT_REMOTE_PLAYER, WAIT_POSITION_SYNC }

var stage: int = Stage.WAIT_SERVER_STARTUP
var server_pid := -1
var network_manager: Node
var main: Node
var stage_elapsed := 0.0

func _initialize() -> void:
	network_manager = root.get_node("NetworkManager")
	server_pid = OS.create_process("godot", [
		"--headless", "--path", ".", "--script", "res://tests/network_sync_server_headless.gd"
	])
	if server_pid <= 0:
		push_error("FAIL: 서버 프로세스를 띄우지 못함")
		print("HEADLESS_NETWORK_POSITION_SYNC_TEST: FAIL")
		quit(1)

func _process(delta: float) -> bool:
	stage_elapsed += delta
	match stage:
		Stage.WAIT_SERVER_STARTUP:
			if stage_elapsed < SERVER_STARTUP_GRACE_SECONDS:
				return false
			var err: Error = network_manager.join("127.0.0.1", PORT)
			if err != OK:
				return _fail("클라이언트 접속 시도 실패 (%d)" % err)
			stage = Stage.CONNECTING
			stage_elapsed = 0.0
			return false

		Stage.CONNECTING:
			var peer := get_multiplayer().multiplayer_peer
			if peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				main = load("res://scenes/Main.tscn").instantiate()
				root.add_child(main)
				stage = Stage.WAIT_REMOTE_PLAYER
				stage_elapsed = 0.0
				return false
			if stage_elapsed >= CONNECT_TIMEOUT_SECONDS:
				return _fail("접속 타임아웃")
			return false

		Stage.WAIT_REMOTE_PLAYER:
			if main.get_node_or_null("Player") != null:
				stage = Stage.WAIT_POSITION_SYNC
				stage_elapsed = 0.0
				return false
			if stage_elapsed >= SPAWN_REPLICATION_TIMEOUT_SECONDS:
				return _fail("원격(호스트) Player가 복제되지 않음")
			return false

		Stage.WAIT_POSITION_SYNC:
			var remote_player: Node = main.get_node_or_null("Player")
			if remote_player == null:
				return _fail("동기화 대기 중 원격 Player가 사라짐")
			if remote_player.position.distance_to(TARGET_POSITION) <= POSITION_TOLERANCE:
				print("HEADLESS_NETWORK_POSITION_SYNC_TEST: PASS (remote_position=%s)" % remote_player.position)
				_cleanup()
				quit(0)
				return true
			if stage_elapsed >= SYNC_TIMEOUT_SECONDS:
				return _fail("위치 동기화 타임아웃 (마지막 위치=%s)" % remote_player.position)
			return false

	return false

func _fail(reason: String) -> bool:
	push_error("FAIL: %s" % reason)
	print("HEADLESS_NETWORK_POSITION_SYNC_TEST: FAIL")
	_cleanup()
	quit(1)
	return true

func _cleanup() -> void:
	network_manager.stop()
	if server_pid > 0 and OS.is_process_running(server_pid):
		OS.kill(server_pid)
