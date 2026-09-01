extends SceneTree

# tests/camera_authority_2proc_headless_test.gd가 백그라운드 프로세스로 띄우는
# "서버(호스트)" 역할. 단독으로는 실행할 필요가 없다.
#
# status.md #36/#38이 여러 세션째 "다음 후보"로만 남겨둔 과제 — 카메라
# authority 처리(scripts/player.gd의 camera.enabled = is_multiplayer_authority())가
# 단일 프로세스 시뮬레이션(tests/camera_authority_headless_test.gd)이 아니라
# 실제 2-프로세스 환경에서도 성립하는지 실측한다. 새 게임 기능 코드는 만들지
# 않는다 — 이미 있는 로직을 다른 검증 방식으로 확인하는 것뿐이다.
#
# 호스트 쪽에서는 (1) 자기 자신(authority)의 Player 카메라가 켜져 있는지,
# (2) 원격으로 복제된 클라이언트의 Player 카메라가 꺼져 있는지 확인한다.
# 클라이언트 쪽 검증은 tests/camera_authority_2proc_headless_test.gd가 자신의
# 프로세스 안에서 대칭으로 수행한다 — 두 프로세스는 서로의 씬 트리에 직접
# 접근할 수 없으므로, 이 스크립트는 자신이 관찰한 결과를 RESULT_PATH 파일에
# 적어두고, 클라이언트 쪽 테스트가 이 프로세스 종료를 기다렸다가 파일을 읽어
# 두 프로세스의 결과를 하나로 합친다(status.md #32/#33이 "headless 서버
# 프로세스 + headless 클라이언트 프로세스" 패턴을 확립했지만, 지금까지는
# 한쪽(클라이언트)만 단정하면 충분한 시나리오였다 — 이번은 양쪽 다 단정이
# 필요한 첫 사례라 결과 파일 공유를 새로 추가했다).
#
# 실행(수동 확인용): godot --headless --path . --script res://tests/camera_authority_2proc_server_headless.gd

const PORT := 8924
const RESULT_PATH := "res://tests/_camera_authority_2proc_result.tmp"
const PEER_WAIT_TIMEOUT_SECONDS := 10.0
const SPAWN_REPLICATION_TIMEOUT_SECONDS := 5.0

enum Stage { HOST, WAIT_PEER, WAIT_REMOTE_PLAYER, DONE }

var stage: int = Stage.HOST
var network_manager: Node
var main: Node
var stage_elapsed := 0.0
var remote_player_node_name := ""

func _process(delta: float) -> bool:
	stage_elapsed += delta
	match stage:
		Stage.HOST:
			network_manager = root.get_node("NetworkManager")
			var err: Error = network_manager.host(PORT)
			if err != OK:
				return _finish("FAIL: 서버 호스팅 실패 (%d)" % err)
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
				return _finish("FAIL: 클라이언트 접속 대기 타임아웃")
			return false

		Stage.WAIT_REMOTE_PLAYER:
			var remote_player: Node = main.get_node_or_null(remote_player_node_name)
			if remote_player != null:
				return _check_and_finish(remote_player)
			if stage_elapsed >= SPAWN_REPLICATION_TIMEOUT_SECONDS:
				return _finish("FAIL: 클라이언트(%s)가 스폰되지 않음" % remote_player_node_name)
			return false

	return false

func _check_and_finish(remote_player: Node) -> bool:
	var own_player: Node = main.get_node_or_null("Player")
	if own_player == null:
		return _finish("FAIL: 자기 자신(호스트)의 Player가 없음")
	if not own_player.camera.enabled:
		return _finish("FAIL: 호스트 자신(authority)의 카메라가 꺼져 있음")
	if remote_player.camera.enabled:
		return _finish("FAIL: 원격 복제된 클라이언트(%s)의 카메라가 켜져 있음" % remote_player_node_name)
	return _finish("PASS")

func _finish(result: String) -> bool:
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(result)
		file.close()
	print("CAMERA_AUTHORITY_2PROC_SERVER: %s" % result)
	if network_manager != null:
		network_manager.stop()
	quit(0 if result == "PASS" else 1)
	return true
