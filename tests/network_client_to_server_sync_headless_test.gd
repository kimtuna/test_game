extends SceneTree

# design.md 로드맵 "멀티플레이"의 다음 조각. status.md #35는 "서버 -> 클라이언트"
# 방향(호스트가 움직이면 클라이언트 화면에 보이는가)만 실측했고, "클라이언트 ->
# 서버" 방향(클라이언트가 자기 Player를 움직이면 서버/다른 클라이언트에도
# 보이는가)은 미실행 상태로 남겨뒀다(status.md #36이 남긴 과제). 이번 조각은
# 그 반대 방향을 실측한다. 새 기능 코드는 만들지 않는다 — status.md #34의
# is_multiplayer_authority() 체크와 #35의 MultiplayerSynchronizer가 이미 대칭
# 동작할 것으로 "기대"만 되어 있던 것을, 실제로 두 프로세스로 검증한다.
#
# status.md #32/#33/#35가 검증에 쓴 "headless 서버 프로세스 + headless
# 클라이언트 프로세스" 패턴을 재사용하되, 이번에는 이 테스트 스크립트 자신이
# 서버(관찰자) 역할을 하고 클라이언트(이동시키는 쪽)를 백그라운드 프로세스로
# 띄운다 — status.md #35와 반대 역할 배치.
#
# status.md #32의 caution에서 확인된 제약대로, host() 호출은 _initialize()가
# 아니라 첫 _process() 프레임에서 수행한다(_initialize() 시점에는 자동로드
# 노드가 아직 is_inside_tree()==false라 multiplayer 프로퍼티가 null을 반환하기
# 때문).
#
# 포트는 기존 network_spike(8921)/network_position_sync(8922) 테스트와 겹치지
# 않도록 8923을 쓴다.
#
# Godot의 고수준 멀티플레이어는 접속하는 클라이언트에게 순차적인 ID(2, 3, ...)가
# 아니라 무작위 31비트 고유 ID를 배정한다(호스트만 항상 1). 그래서 클라이언트의
# Player 노드 이름을 "Player_2"로 고정 가정했다가 실제 2-프로세스 실행에서
# 실패를 관찰했다(예: 실제 배정된 id가 593892253 등 임의의 큰 수) — 접속된
# 피어 목록(get_multiplayer().get_peers())에서 실제 id를 읽어 노드 이름을
# 계산하도록 고쳤다.
# 실행: godot --headless --path . --script res://tests/network_client_to_server_sync_headless_test.gd

const PORT := 8923
const TARGET_POSITION := Vector2(222.0, 777.0)
const POSITION_TOLERANCE := 1.0
const PEER_WAIT_TIMEOUT_SECONDS := 10.0
const SPAWN_REPLICATION_TIMEOUT_SECONDS := 5.0
const SYNC_TIMEOUT_SECONDS := 8.0

enum Stage { HOST, WAIT_PEER, WAIT_REMOTE_PLAYER, WAIT_POSITION_SYNC }

var stage: int = Stage.HOST
var client_pid := -1
var network_manager: Node
var main: Node
var stage_elapsed := 0.0
var remote_player_node_name := ""

func _initialize() -> void:
	client_pid = OS.create_process("godot", [
		"--headless", "--path", ".", "--script", "res://tests/network_client_move_headless.gd"
	])
	if client_pid <= 0:
		push_error("FAIL: 클라이언트 프로세스를 띄우지 못함")
		print("HEADLESS_NETWORK_CLIENT_TO_SERVER_SYNC_TEST: FAIL")
		quit(1)

func _process(delta: float) -> bool:
	stage_elapsed += delta
	match stage:
		Stage.HOST:
			network_manager = root.get_node("NetworkManager")
			var err: Error = network_manager.host(PORT)
			if err != OK:
				return _fail("서버 호스팅 실패 (%d)" % err)
			main = load("res://scenes/Main.tscn").instantiate()
			root.add_child(main)
			stage = Stage.WAIT_PEER
			stage_elapsed = 0.0
			return false

		Stage.WAIT_PEER:
			var peers := get_multiplayer().get_peers()
			if not peers.is_empty():
				var remote_id: int = peers[0]
				remote_player_node_name = "Player" if remote_id == 1 else "Player_%d" % remote_id
				stage = Stage.WAIT_REMOTE_PLAYER
				stage_elapsed = 0.0
				return false
			if stage_elapsed >= PEER_WAIT_TIMEOUT_SECONDS:
				return _fail("클라이언트 접속 대기 타임아웃")
			return false

		Stage.WAIT_REMOTE_PLAYER:
			if main.get_node_or_null(remote_player_node_name) != null:
				stage = Stage.WAIT_POSITION_SYNC
				stage_elapsed = 0.0
				return false
			if stage_elapsed >= SPAWN_REPLICATION_TIMEOUT_SECONDS:
				return _fail("클라이언트(%s)가 스폰되지 않음" % remote_player_node_name)
			return false

		Stage.WAIT_POSITION_SYNC:
			var remote_player: Node = main.get_node_or_null(remote_player_node_name)
			if remote_player == null:
				return _fail("동기화 대기 중 원격 Player가 사라짐")
			if remote_player.position.distance_to(TARGET_POSITION) <= POSITION_TOLERANCE:
				print("HEADLESS_NETWORK_CLIENT_TO_SERVER_SYNC_TEST: PASS (server_side_position=%s)" % remote_player.position)
				_cleanup()
				quit(0)
				return true
			if stage_elapsed >= SYNC_TIMEOUT_SECONDS:
				return _fail("위치 동기화 타임아웃 (마지막 위치=%s)" % remote_player.position)
			return false

	return false

func _fail(reason: String) -> bool:
	push_error("FAIL: %s" % reason)
	print("HEADLESS_NETWORK_CLIENT_TO_SERVER_SYNC_TEST: FAIL")
	_cleanup()
	quit(1)
	return true

func _cleanup() -> void:
	if network_manager != null:
		network_manager.stop()
	if client_pid > 0 and OS.is_process_running(client_pid):
		OS.kill(client_pid)
