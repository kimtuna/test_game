extends SceneTree

# 헤드리스 환경에서 기본 코디(의상)가 실제로 그려지는지 검증하는 통합 테스트.
# 실행: godot --headless --path . --script res://tests/outfit_headless_test.gd
# design.md "기본 코디(의상) 제공"을 시각적으로 구현한 조각(status.md #46) —
# 커스터마이징을 전혀 하지 않은 기본 상태에서도 상의(커스터마이징 색)와
# 하의(고정된 기본 복장 색)가 서로 다른 색으로 그려지는지 확인한다.

func _initialize() -> void:
	var main: Node2D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var player := main.get_node("Player")
	var ok := true

	var image: Image = player.sprite.texture.get_image()
	var top_pixel: Color = image.get_pixel(0, 0)
	var bottom_pixel: Color = image.get_pixel(0, 31)

	var expected_top: Color = player.DEFAULT_SKIN_COLOR
	var expected_bottom: Color = player.OUTFIT_COLOR

	var top_close := (
		absf(top_pixel.r - expected_top.r) < 0.01
		and absf(top_pixel.g - expected_top.g) < 0.01
		and absf(top_pixel.b - expected_top.b) < 0.01
	)
	if not top_close:
		push_error("FAIL: 상의(0,0) 픽셀이 기본 몸 색이 아님 (실제: %s)" % [top_pixel])
		ok = false

	var bottom_close := (
		absf(bottom_pixel.r - expected_bottom.r) < 0.01
		and absf(bottom_pixel.g - expected_bottom.g) < 0.01
		and absf(bottom_pixel.b - expected_bottom.b) < 0.01
	)
	if not bottom_close:
		push_error("FAIL: 하의(0,31) 픽셀이 기본 코디 색이 아님 (실제: %s)" % [bottom_pixel])
		ok = false

	if top_pixel.is_equal_approx(bottom_pixel):
		push_error("FAIL: 상의와 하의 색이 서로 구분되지 않음")
		ok = false

	# 커스터마이징으로 피부색을 바꿔도(빨강) 하의(기본 코디)는 바뀌지 않아야 한다.
	player.set_appearance(Color(0.9, 0.2, 0.2), player.eye_color, player.hair_type)
	var image2: Image = player.sprite.texture.get_image()
	var bottom_pixel2: Color = image2.get_pixel(0, 31)
	var bottom_close2 := (
		absf(bottom_pixel2.r - expected_bottom.r) < 0.01
		and absf(bottom_pixel2.g - expected_bottom.g) < 0.01
		and absf(bottom_pixel2.b - expected_bottom.b) < 0.01
	)
	if not bottom_close2:
		push_error("FAIL: 커스터마이징 후에도 기본 코디 색이 유지되어야 하는데 바뀜 (실제: %s)" % [bottom_pixel2])
		ok = false

	if ok:
		print("HEADLESS_OUTFIT_TEST: PASS")
		quit(0)
	else:
		print("HEADLESS_OUTFIT_TEST: FAIL")
		quit(1)
