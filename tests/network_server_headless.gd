extends SceneTree

# network_spike_headless_test.gd가 백그라운드 프로세스로 띄우는 "서버" 역할.
# 단독으로는 실행할 필요가 없다 (테스트가 OS.create_process()로 이 스크립트를
# 자동으로 띄운다). 클라이언트가 접속하면 표식을 출력하고 즉시 종료한다.
# 실행(수동 확인용): godot --headless --path . --script res://tests/network_server_headless.gd

const PORT := 8921
const TIMEOUT_SECONDS := 8.0

var elapsed := 0.0
var started := false

func _process(delta: float) -> bool:
	if not started:
		# 자동로드 노드는 _initialize() 시점엔 아직 is_inside_tree()가 false라
		# multiplayer_peer를 설정할 수 없다(get_multiplayer()가 null 반환). 트리가
		# 실제로 시작된 첫 _process 프레임까지 기다렸다가 host()를 호출한다.
		started = true
		var network_manager: Node = root.get_node("NetworkManager")
		var err: Error = network_manager.host(PORT)
		if err != OK:
			print("NETWORK_SERVER: HOST_FAILED (%d)" % err)
			quit(1)
			return true
		return false

	elapsed += delta
	if not get_multiplayer().get_peers().is_empty():
		print("NETWORK_SERVER: PEER_CONNECTED")
		quit(0)
		return true
	if elapsed >= TIMEOUT_SECONDS:
		print("NETWORK_SERVER: TIMEOUT")
		quit(1)
		return true
	return false
