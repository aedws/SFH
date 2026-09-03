extends SceneTree

const QUOTE := preload("res://game/features/p5_hub_progression/shop_quote_policy.gd")
const SHOP := preload("res://game/features/p5_hub_progression/rotating_shop_service.gd")
const PROFILE := preload("res://game/features/persistent_profile/persistent_profile.gd")
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()
var failures: Array[String] = []


func _init() -> void:
	node_added.connect(isolation.isolate)
	call_deferred(&"_run")


func _run() -> void:
	_verify_quotes()
	await _verify_game_flow()
	paused = false
	if failures.is_empty():
		print("P7_SHOP_BROWSER_OK quote_no_mutation unit_price_compare quality_pending selected_purchase no_double_click stale_rotation locked_insufficient invalid_data snapshot_copy esc_restore viewports_4 optional isolated_saves")
		quit(0)
	else:
		printerr("P7_SHOP_BROWSER_FAILED: %s" % " / ".join(failures))
		quit(1)


func _verify_quotes() -> void:
	var profile := PROFILE.new()
	root.add_child(profile)
	profile.configure("", false)
	var catalog: Array[Dictionary] = [
		{&"offer_id": &"cheap", &"display_name": "손상품", &"quality": &"damaged", &"target_type": &"item", &"target_id": &"test_item", &"quantity": 1, &"price": 10, &"performance_multiplier": 0.8},
		{&"offer_id": &"normal", &"display_name": "표준품", &"quality": &"standard", &"target_type": &"item", &"target_id": &"test_item", &"quantity": 2, &"price": 80, &"performance_multiplier": 1.0},
		{&"offer_id": &"high", &"display_name": "고성능", &"quality": &"high_performance", &"target_type": &"item", &"target_id": &"test_item", &"quantity": 1, &"price": 100, &"performance_multiplier": 1.25},
	]
	var shop := SHOP.new()
	_check(shop.configure(profile, catalog, 77101, 25, 3), "catalog configure")
	var before := profile.get_snapshot()
	var quote: Dictionary = shop.quote(&"cheap")
	_check(quote.purchasable and is_equal_approx(float(quote.price_ratio), 0.25), "per-unit comparison")
	_check(not quote.quality_applied and quote.delivery == "창고 수량 지급", "no false runtime quality claim")
	quote.offer.price = 0
	_check(shop.quote(&"cheap").offer.price == 10 and profile.get_snapshot() == before, "quotes read-only copied")
	var old_revision: int = shop.rotation_index
	shop.refresh(false)
	_check(not shop.purchase(&"cheap", &"stale", old_revision).success and profile.get_snapshot() == before, "stale quote never charged")
	_check(shop.purchase(&"cheap", &"purchase", shop.rotation_index).success, "selected purchase")
	var paid := profile.get_snapshot()
	_check(not shop.purchase(&"cheap", &"purchase", shop.rotation_index).success and profile.get_snapshot() == paid, "same transaction duplicate")
	var locked: Dictionary = catalog[0].duplicate(true)
	locked.required_unlock_id = &"missing_unlock"
	_check(not QUOTE.quote(locked, catalog, before, 1).purchasable, "locked quote")
	var poor := before.duplicate(true)
	poor.banked_credits = 0
	_check(not QUOTE.quote(catalog[0], catalog, poor, 1).purchasable, "insufficient quote")
	for invalid in [{&"price": -1}, {&"price": 1.5}, {&"quantity": 0}, {&"quantity": -2}, {&"quality": &"unknown"}, {&"target_type": &"unsupported"}, {&"performance_multiplier": INF}]:
		var bad: Dictionary = catalog[0].duplicate(true)
		bad.merge(invalid, true)
		_check(not QUOTE.quote(bad, catalog, before, 1).purchasable, "invalid quote rejected %s" % invalid)
	profile.free()


func _verify_game_flow() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	for _frame in 5: await process_frame
	var panel: Control = game.get("shop_browser_panel")
	if panel == null:
		_check(false, "shop UI assembled")
		game.free()
		return
	_check(game.start_hub != null and not game.run_started and not paused, "boot hub unchanged")
	var profile: Node = game.persistent_profile
	var initial: Dictionary = profile.get_snapshot()
	# Real gate F -> preparation step 2 -> real shop button click.
	game.player.global_position = game.start_hub.get_snapshot().operation_position
	for _frame in 4: await physics_frame
	await _tap(KEY_F)
	await _click(game.operation_setup_presenter.next_button)
	await _click(game.shop_button)
	_check(panel.visible and not game.run_setup_overlay.visible and paused, "open shop hides setup")
	_check(profile.get_snapshot() == initial and panel.get_snapshot().selected_id == &"" and not panel.get_snapshot().purchase_enabled, "open never purchases")
	for id in panel.offer_buttons.keys():
		await _click(panel.offer_buttons[id])
		_check(panel.get_snapshot().selected_id == id and profile.get_snapshot() == initial, "three qualities selectable no charge")
		_check("후속 구현" in panel.detail_label.text, "unapplied quality disclosed")
	var selected: Dictionary = panel.get_snapshot().selected_quote
	await _click(panel.buy_button)
	var after: Dictionary = profile.get_snapshot()
	_check(int(initial.banked_credits) - int(after.banked_credits) == int(selected.offer.price), "selected offer exact price")
	_check(int(after.warehouse.get(selected.offer.target_id, 0)) - int(initial.warehouse.get(selected.offer.target_id, 0)) == int(selected.offer.quantity), "selected offer exact quantity")
	await _click(panel.buy_button)
	_check(profile.get_snapshot() == after and not panel.get_snapshot().purchase_enabled, "double click no extra grant")
	_check("구매 완료" in panel.status_label.text, "success receipt visible")
	# A balance change after viewing a quote must also be visible and non-destructive.
	var remaining_credits := int(after.banked_credits)
	profile.spend(remaining_credits)
	panel.refresh()
	for id in panel.offer_buttons.keys():
		await _click(panel.offer_buttons[id])
		_check(not panel.get_snapshot().purchase_enabled and "크레딧 부족" in panel.status_label.text, "insufficient balance visible")
	var poor_state: Dictionary = profile.get_snapshot()
	await _click(panel.buy_button)
	_check(profile.get_snapshot() == poor_state, "disabled purchase changes nothing")
	profile.add_credits(remaining_credits)
	await _tap(KEY_ESCAPE)
	_check(not panel.visible and game.run_setup_overlay.visible and paused, "ESC restores paused briefing")
	await _tap(KEY_ESCAPE)
	_check(not game.run_setup_overlay.visible and not paused and game.start_hub != null, "second ESC returns moving hub")
	# Layout and pause restoration independent from a paused preparation screen.
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(640, 360), Vector2i(390, 844)]:
		root.size = dimensions
		panel.open_panel()
		for _frame in 7: await process_frame
		var bounds := root.get_visible_rect().grow(1.0)
		_check(bounds.encloses(panel.panel.get_global_rect()), "viewport panel %s / %s" % [dimensions, panel.panel.get_global_rect()])
		_check(bounds.encloses(panel.buy_button.get_global_rect()) and bounds.encloses(panel.close_button.get_global_rect()), "visible actions %s" % dimensions)
		_check(not panel.buy_button.get_global_rect().intersects(panel.close_button.get_global_rect()), "actions not overlapping")
		_check(panel.cards.columns == (1 if dimensions.x < 764 else 3), "responsive columns")
		await _tap(KEY_ESCAPE)
		_check(not paused and not panel.visible, "hub pause restored %s" % dimensions)
	root.size = Vector2i(1280, 720)
	# Purchases and repeated modal visits must not break the next real operation.
	game.player.global_position = game.start_hub.get_snapshot().operation_position
	for _frame in 4: await physics_frame
	await _tap(KEY_F)
	await _click(game.operation_setup_presenter.next_button)
	await _click(game.operation_setup_presenter.next_button)
	await _click(game.operation_setup_presenter.launch_button)
	for _frame in 8: await physics_frame
	_check(game.run_started and is_instance_valid(game.player) and not panel.visible and not paused, "operation after shopping starts")
	game.free()
	var optional: Node = load("res://game/scenes/game.tscn").instantiate()
	var features: Resource = optional.features.duplicate(true)
	features.shop_browser_enabled = false
	optional.features = features
	root.add_child(optional)
	for _frame in 3: await process_frame
	_check(optional.shop_browser_panel == null and optional.p5_hub_progression_service != null and optional.start_hub != null, "UI optional domain preserved")
	var optional_before: Dictionary = optional.persistent_profile.get_snapshot()
	optional.call(&"_purchase_medkit")
	_check(optional.persistent_profile.get_snapshot() == optional_before, "disabled UI never silently purchases")
	optional.free()


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
	for _frame in 3: await process_frame


func _click(button: Button) -> void:
	if not button.is_visible_in_tree():
		_check(false, "clicked hidden button %s" % button.name)
		return
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas() * (button.size * 0.5)
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	for _frame in 4: await process_frame


func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
