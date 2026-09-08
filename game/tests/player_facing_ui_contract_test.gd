extends SceneTree

var failures: Array[String] = []
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()
var capture_dir := ""


func _initialize() -> void:
	node_added.connect(isolation.isolate)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir = argument.trim_prefix("--capture-dir=")
	call_deferred(&"_run")


func _run() -> void:
	var shop_text := preload("res://game/features/shop_browser/shop_offer_presenter.gd")
	_check("창고 수량 지급" in shop_text.receipt({&"granted": 2}), "legacy receipt is not mislabeled as bag")
	_check("가방 실물 아이템 지급" in shop_text.receipt({&"delivery": {&"delivery": "가방 실물 아이템 지급"}}), "physical receipt uses provider")
	_check("품질 효과 미적용" in shop_text.detail({&"offer": {}, &"quality_applied": false}), "legacy quote cannot promise quality instances")
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	await _frames()
	var view: RefCounted = game.operation_result_presenter
	var result := {&"extracted": true, &"map_name": "중형 작전", &"elapsed_seconds": 601,
		&"kills": 186, &"boss_kills": 1, &"operation_credits": 1200, &"salvage": 8,
		&"loot": {&"success": true, &"converted_credits": 80, &"wallet_credits": 20,
			&"warehouse_items": {&"rifle": 2}, &"permanent_unlocks": {&"vest": 1}}}
	var before := result.duplicate(true)
	var profile_before: Dictionary = game.persistent_profile.get_snapshot()
	var transcript := "랭킹: 로컬 테스트 기록 · 온라인 경쟁 아님\n외부 경험치 +25 · 캐릭터/무기/방어구 성장\n".repeat(12)
	game.game_over_overlay.show()
	game.start_hub_hud.hide()
	game.restart_button.text = "시작 거점으로 복귀 (Enter)"
	paused = true
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(640, 360), Vector2i(390, 844)]:
		root.size = dimensions
		view.render(result, "탈출 성공", transcript)
		await _frames()
		var snapshot: Dictionary = view.get_snapshot()
		var bounds := root.get_visible_rect().grow(1)
		_check(bounds.encloses(snapshot.panel_rect) and bounds.encloses(snapshot.return_rect), "result/actions fit %s" % dimensions)
		_check(not snapshot.details_visible and snapshot.reward_count == 5, "summary default and all recovered categories")
		_check(_all_text(view.metrics).contains("10:01") and _all_text(view.rewards).contains("1200 C"), "actual time and credit values")
		_check(_all_text(view.rewards).contains("100 C"), "loot conversion separate from operation settlement")
		await _capture("result-%dx%d" % [dimensions.x, dimensions.y])
		# Scroll focus makes keyboard navigation reach collapsed details on small screens.
		view.details_button.grab_focus()
		await _frames()
		await _tap(KEY_SPACE)
		_check(view.get_snapshot().details_visible and game.game_over_summary.text == transcript, "keyboard details preserves full evidence")
		await _frames()
		_check(bounds.encloses(view.return_button.get_global_rect()), "expanded transcript cannot push return off screen")
	_check(result == before and game.persistent_profile.get_snapshot() == profile_before, "view never mutates settlement/profile")
	root.size = Vector2i(1280, 720)
	view.render({&"extracted": false, &"operation_credits": 71, &"loot": {&"success": true, &"lost_items": {&"a": 2, &"b": 3}}}, "작전 실패", "실패 기록")
	await _frames()
	_check(_all_text(view.rewards).contains("분실 크레딧") and _all_text(view.rewards).contains("5개 / 2종"), "failure does not imply recovered loot")
	_check(view.get_snapshot().reward_count == 2 and not view.get_snapshot().details_visible, "new result clears previous success/details")
	await _capture("result-failure")
	view.render({}, "초기화 복구 필요", "서비스를 준비하지 못했습니다.")
	_check(view.get_snapshot().details_visible and view.get_snapshot().reward_count == 0, "initialization recovery has no fabricated reward")
	game.game_over_overlay.hide()
	paused = false
	game.shop_browser_panel.open_panel()
	await _frames()
	var offer_buttons: Dictionary = game.shop_browser_panel.offer_buttons
	_check(not offer_buttons.is_empty(), "shop catalog assembled")
	for id in offer_buttons:
		var card: Button = offer_buttons[id]
		_check(card.get_script().resource_path.ends_with("shop_offer_card.gd"), "native selectable offer card")
		_check(card.toggle_mode and card.focus_mode == Control.FOCUS_ALL, "mouse/keyboard card affordance")
		var quote: Dictionary = game.p5_hub_progression_service.quote_shop_offer(id)
		_check(_all_text(card).contains(str(quote.offer.price) + " C"), "card uses authoritative price")
	game.shop_browser_panel.select_offer(offer_buttons.keys()[0])
	await _frames()
	await _capture("shop-1280x720")
	root.size = Vector2i(390, 844)
	await _frames()
	await _capture("shop-390x844")
	game.shop_browser_panel.close_panel()
	game.free()
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("PLAYER_FACING_UI_OK result_success_failure_recovery viewports_4 details_keyboard immutable_receipts card_price native_focus")
	quit(0 if failures.is_empty() else 1)


func _all_text(node: Node) -> String:
	var value: String = node.text + "\n" if node is Label else ""
	for child in node.get_children(): value += _all_text(child)
	return value


func _frames() -> void:
	for _frame in 8: await process_frame


func _tap(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames()


func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK, "capture " + label)


func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
