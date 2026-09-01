extends Node

# design.md의 "세션 서버 방식 멀티플레이"를 향한 최소 착수점.
# ENetMultiplayerPeer로 호스트(서버)/조인(클라이언트) 역할을 만드는 것까지만
# 다루고, 실제 게임 상태 동기화(플레이어 스폰/위치 등)는 아직 다루지 않는다
# (status.md #31 — 아키텍처 결정 비중이 커서 가장 작은 스파이크부터 검증).

const DEFAULT_PORT := 8921
const MAX_CLIENTS := 8

signal peer_connected_to_me(id: int)
signal peer_disconnected_from_me(id: int)

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("NetworkManager: 서버 생성 실패 (port=%d, err=%d)" % [port, err])
		return err
	multiplayer.multiplayer_peer = peer
	print("NetworkManager: 호스팅 시작 (port=%d, peer_id=%d)" % [port, multiplayer.get_unique_id()])
	return OK

func join(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("NetworkManager: 클라이언트 생성 실패 (%s:%d, err=%d)" % [address, port, err])
		return err
	multiplayer.multiplayer_peer = peer
	print("NetworkManager: 접속 시도 (%s:%d)" % [address, port])
	return OK

func stop() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func _on_peer_connected(id: int) -> void:
	print("NetworkManager: 피어 접속 -> %d" % id)
	peer_connected_to_me.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("NetworkManager: 피어 접속 해제 -> %d" % id)
	peer_disconnected_from_me.emit(id)
