extends SceneTree

# status.md #36/#38이 여러 세션째 "다음 후보"로만 남겨둔 과제: 카메라
# authority 처리(scripts/player.gd의 camera.enabled = is_multiplayer_authority())가
# tests/camera_authority_headless_test.gd의 단일 프로세스 시뮬레이션(오프라인
# 기본 피어 상태에서 main._on_peer_connected(2)를 직접 호출)이 아니라, 실제로
# 서로 다른 두 프로세스가 ENet으로 접속했을 때도 각자 자신의 Player 카메라만
# 켜고 원격으로 복제된 Player의 카메라는 꺼진 채로 유지하는지 실측한다. 새
# 게임 기능 코드는 만들지 않는다 — 이미 status.md #36에서 구현된 로직을 다른
# 방식으로 검증하는 것뿐이다.
#
# status.md #32/#33/#35/#37이 확립한 "headless 서버 프로세스 + headless
# 클라이언트 프로세스" 패턴을 그대로 재사용한다(이 테스트 자신이 클라이언트
# 역할, tests/camera_authority_2proc_server_headless.gd를 백그라운드 서버로
# 띄움 — status.md #35의 network_position_sync_headless_test.gd와 동일한 역할
# 배치). 다만 지금까지의 2-프로세스 테스트는 한쪽(테스트를 실행하는 쪽)만
# 단정하면 충분했던 반면, 이번엔 "양쪽 모두 자신의 카메라는 켜고 상대의
# 복제본은 꺼야 한다"는 대칭 조건이라 서버 쪽 결과도 필요하다. 서버 프로세스가
# 자신의 관찰 결과를 RESULT_PATH 파일에 적고 종료하면, 이 스크립트가 그 종료를
# 기다렸다가 파일을 읽어 두 결과를 합친다.
#
# 포트는 기존 network_spike(8921)/network_position_sync(8922)/
# network_client_to_server_sync(8923)와 겹치지 않도록 8924를 쓴다.
# 실행: godot --headless --path . --script res://tests/camera_authority_2proc_headless_test.gd

const PORT := 8924
const RESULT_PATH := "res://tests/_camera_authority_2proc_result.tmp"
const SERVER_STARTUP_GRACE_SECONDS := 1.5
const CONNECT_TIMEOUT_SECONDS := 8.0
const SPAWN_REPLICATION_TIMEOUT_SECONDS := 5.0
const SERVER_EXIT_TIMEOUT_SECONDS := 10.0

enum Stage { WAIT_SERVER_STARTUP, CONNECTING, WAIT_PLAYERS, WAIT_SERVER_RESULT }

var stage: int = Stage.WAIT_SERVER_STARTUP
var server_pid := -1
var network_manager: Node
var main: Node
var stage_elapsed := 0.0
var own_player_node_name := ""
var client_side_ok := false

func _initialize() -> void:
	# 이전 실행이 비정상 종료해 결과 파일이 남아있을 수 있으니 먼저 지운다.
	if FileAccess.file_exists(RESULT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RESULT_PATH))
	network_manager = root.get_node("NetworkManager")
	server_pid = OS.create_process("godot", [
		"--headless", "--path", ".", "--script", "res://tests/camera_authority_2proc_server_headless.gd"
	])
	if server_pid <= 0:
		push_error("FAIL: 서버 프로세스를 띄우지 못함")
		print("HEADLESS_CAMERA_AUTHORITY_2PROC_TEST: FAIL")
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
				var own_id := get_multiplayer().get_unique_id()
				own_player_node_name = "Player" if own_id == 1 else "Player_%d" % own_id
				stage = Stage.WAIT_PLAYERS
				stage_elapsed = 0.0
				return false
			if stage_elapsed >= CONNECT_TIMEOUT_SECONDS:
				return _fail("접속 타임아웃")
			return false

		Stage.WAIT_PLAYERS:
			var own_player: Node = main.get_node_or_null(own_player_node_name)
			var host_player: Node = main.get_node_or_null("Player")
			if own_player != null and host_player != null:
				if not own_player.camera.enabled:
					return _fail("클라이언트 자신(authority)의 카메라가 꺼져 있음")
				if own_player == host_player:
					return _fail("자신의 Player가 호스트의 Player와 같은 노드로 인식됨 (own=%s)" % own_player_node_name)
				if host_player.camera.enabled:
					return _fail("원격 복제된 호스트(Player)의 카메라가 켜져 있음")
				client_side_ok = true
				stage = Stage.WAIT_SERVER_RESULT
				stage_elapsed = 0.0
				return false
			if stage_elapsed >= SPAWN_REPLICATION_TIMEOUT_SECONDS:
				return _fail("자신(%s) 또는 호스트(Player)의 Player가 복제되지 않음" % own_player_node_name)
			return false

		Stage.WAIT_SERVER_RESULT:
			if OS.is_process_running(server_pid):
				if stage_elapsed >= SERVER_EXIT_TIMEOUT_SECONDS:
					return _fail("서버 프로세스가 결과를 남기지 않고 종료 대기 타임아웃")
				return false
			return _finish_with_server_result()

	return false

func _finish_with_server_result() -> bool:
	if not client_side_ok:
		return _fail("클라이언트 쪽 검증을 통과하지 못한 채로 서버 결과 대기 단계에 도달함")
	if not FileAccess.file_exists(RESULT_PATH):
		return _fail("서버가 결과 파일을 남기지 않음")
	var file := FileAccess.open(RESULT_PATH, FileAccess.READ)
	var server_result := file.get_as_text()
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RESULT_PATH))
	if server_result != "PASS":
		return _fail("서버 쪽 검증 실패: %s" % server_result)
	print("HEADLESS_CAMERA_AUTHORITY_2PROC_TEST: PASS (client=%s, server=PASS)" % own_player_node_name)
	_cleanup()
	quit(0)
	return true

func _fail(reason: String) -> bool:
	push_error("FAIL: %s" % reason)
	print("HEADLESS_CAMERA_AUTHORITY_2PROC_TEST: FAIL")
	_cleanup()
	quit(1)
	return true

func _cleanup() -> void:
	network_manager.stop()
	if server_pid > 0 and OS.is_process_running(server_pid):
		OS.kill(server_pid)
	if FileAccess.file_exists(RESULT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RESULT_PATH))
