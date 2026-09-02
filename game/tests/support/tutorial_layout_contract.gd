extends RefCounted

const SCENE := preload("res://game/features/operation_tutorial/operation_tutorial_overlay.tscn")


func verify(tree: SceneTree) -> String:
	for viewport_size in [Vector2i(1280, 720), Vector2i(1024, 720), Vector2i(768, 720), Vector2i(480, 854)]:
		var viewport := SubViewport.new()
		viewport.size = viewport_size
		tree.root.add_child(viewport)
		var tutorial: Control = SCENE.instantiate()
		viewport.add_child(tutorial)
		tutorial.call(&"configure", {&"move": "WASD", &"dash": "Shift", &"skills": "7/8/9", &"map": "Tab", &"interact": "V"})
		tutorial.call(&"show_first_operation")
		for step in 4:
			for _frame in 4:
				await tree.process_frame
			var snapshot: Dictionary = tutorial.call(&"get_snapshot")
			var rect: Rect2 = snapshot[&"panel_rect"]
			var safe_zone := Rect2(Vector2(viewport_size) * Vector2(0.22, 0.18), Vector2(viewport_size) * Vector2(0.56, 0.54))
			var body := String(snapshot[&"body"])
			var failure := ""
			if not snapshot[&"panel_inside_viewport"] or not snapshot[&"buttons_accessible"] or not snapshot[&"body_inside_panel"]:
				failure = "패널·본문·44px 버튼 경계 실패"
			elif rect.size.x > 338.0 or rect.intersects(safe_zone) or float(snapshot[&"panel_area_ratio"]) > 0.11:
				failure = "튜토리얼 화면 점유·중앙 시야 실패"
			elif step == 0 and ("Shift 대시" not in body or "점멸은 별도 스킬" not in body):
				failure = "대시·점멸 의미 구분 실패"
			elif step == 1 and "7/8/9 스킬" not in body:
				failure = "재설정 스킬 키 안내 실패"
			elif step == 3 and ("Tab 지도" not in body or "V" not in body):
				failure = "재설정 지도·상호작용 키 안내 실패"
			if not failure.is_empty():
				viewport.queue_free()
				return "%s / %s step %d: %s" % [failure, viewport_size, step, snapshot]
			tutorial.call(&"next_step")
		if tutorial.visible or bool(tutorial.call(&"show_first_operation")):
			viewport.queue_free()
			return "완료 후 숨김·세션당 1회 표시 실패"
		viewport.queue_free()
		await tree.process_frame
	return ""
