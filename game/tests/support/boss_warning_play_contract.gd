extends RefCounted


func verify(tree: SceneTree, game: Node, boss: Node2D, tap_key: Callable) -> String:
	var hud = game.get("boss_warning_hud")
	if hud == null:
		return "작전 보스 경고 HUD 미설치"
	hud.call(&"_process", 0.0)
	var appeared: Dictionary = hud.call(&"get_snapshot")
	if not appeared[&"warning_visible"] or "보스 등장" not in appeared[&"warning_text"]:
		return "50% 회수 보스 생성 직후 시각 경고 없음"
	var original_position := boss.global_position
	var original_processing := boss.is_physics_processing()
	boss.set_physics_process(false)
	var to_world: Transform2D = game.get("player").get_canvas_transform().affine_inverse()
	var view: Vector2 = tree.root.get_visible_rect().size
	boss.global_position = to_world * Vector2(view.x + 300.0, view.y * 0.5)
	hud.call(&"_process", 0.0)
	var offscreen: Dictionary = hud.call(&"get_snapshot")
	var found := false
	for marker: Dictionary in offscreen[&"indicators"]:
		if marker[&"id"] == boss.get_instance_id():
			found = absf(float(marker[&"angle"])) < 0.01 and marker[&"position"].x < view.x
	if not found:
		return "실제 카메라 기준 우측 화면 밖 보스 방향 누락"
	await tap_key.call(KEY_I)
	await tree.process_frame
	if hud.is_visible_in_tree():
		return "I 가방에서 보스 경고가 겹침"
	await tap_key.call(KEY_ESCAPE)
	await tree.process_frame
	if not hud.is_visible_in_tree():
		return "ESC 전투 복귀 후 보스 경고 미복원"
	boss.global_position = to_world * (view * 0.5)
	hud.call(&"_process", 0.0)
	for marker: Dictionary in hud.call(&"get_snapshot")[&"indicators"]:
		if marker[&"id"] == boss.get_instance_id():
			return "화면 안으로 들어온 보스에 화살표 잔류"
	boss.global_position = original_position
	boss.set_physics_process(original_processing)
	hud.call(&"_process", 0.0)
	return ""
