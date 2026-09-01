extends SceneTree

# 헤드리스 환경에서 기본 코디(의상)가 실제로 그려지는지 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/outfit_headless_test.gd
# design.md "기본 코디(의상) 제공"을 시각적으로 구현한 조각(status.md #46) —
# 커스터마이징을 전혀 하지 않은 기본 상태에서도 상의(커스터마이징 색)와
# 하의(고정된 기본 복장 색)가 서로 다른 색으로 그려지는지 확인한다.
#
# inbox.md #8 5번(status.md #65): player.gd가 32x32 전체를 채우던 단색
# 사각형 대신 머리/몸통 타원 실루엣 + 3톤 하드 엣지 음영을 그리도록 바뀌어,
# 더 이상 (0,0)/(0,31) 같은 고정 코너 픽셀이 항상 몸 색/코디 색인 것이
# 보장되지 않는다(실루엣 밖은 투명, 실루엣 안이라도 highlight/shadow
# 톤이면 정확히 같은 색이 아니다). 대신 "실루엣 안 어딘가에 기대한 기본
# 톤(3톤 중 그라데이션 없는 순수 base)이 실제로 칠해져 있는가"를 넓은
# 영역에서 찾는 방식으로 검증한다 — 정확한 픽셀 좌표를 손으로 계산해
# 하드코딩하는 것보다 실루엣 비례(player.HEAD_RATIO 등)가 조금 바뀌어도
# 깨지지 않는다.

func _find_pixel(image: Image, x0: int, y0: int, x1: int, y1: int, expected: Color) -> bool:
	for y in range(y0, y1):
		for x in range(x0, x1):
			var p := image.get_pixel(x, y)
			if p.a < 0.5:
				continue
			if (
				absf(p.r - expected.r) < 0.01
				and absf(p.g - expected.g) < 0.01
				and absf(p.b - expected.b) < 0.01
			):
				return true
	return false

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player := main.get_node("Player")
	var ok := true

	var image: Image = player.sprite.texture.get_image()
	# 몸통(상의 부분) 전체 영역에서 기본 피부색이 어딘가 나타나는지, 몸통
	# 아래쪽(하의 영역, OUTFIT_START_Y 이후)에서 기본 코디색이 나타나는지 확인.
	var expected_top: Color = player.DEFAULT_SKIN_COLOR
	var expected_bottom: Color = player.OUTFIT_COLOR

	if not _find_pixel(image, 0, 0, 32, player.OUTFIT_START_Y, expected_top):
		push_error("FAIL: 상의 영역에 기본 몸 색이 보이지 않음")
		ok = false

	if not _find_pixel(image, 0, player.OUTFIT_START_Y, 32, 32, expected_bottom):
		push_error("FAIL: 하의 영역에 기본 코디 색이 보이지 않음")
		ok = false

	# 커스터마이징으로 피부색을 바꿔도(빨강) 하의(기본 코디)는 바뀌지 않아야 한다.
	player.set_appearance(Color(0.9, 0.2, 0.2), player.eye_color, player.hair_type)
	var image2: Image = player.sprite.texture.get_image()
	if not _find_pixel(image2, 0, player.OUTFIT_START_Y, 32, 32, expected_bottom):
		push_error("FAIL: 커스터마이징 후에도 기본 코디 색이 유지되어야 하는데 사라짐")
		ok = false

	if ok:
		print("HEADLESS_OUTFIT_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_OUTFIT_TEST: FAIL")
		quit(1)
