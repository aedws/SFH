extends SceneTree
## Input/visible-affordance acceptance, not a claim that a human finds the game fun.
var failures := PackedStringArray()
var last_prompt := ""
var isolation: RefCounted

func _init() -> void:
	isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()

func _run() -> void:
	var zone = load("res://game/features/extraction/extraction_zone.tscn").instantiate()
	root.add_child(zone)
	zone.set_process(false)
	zone.interaction_availability_changed.connect(func(_available, prompt): last_prompt = prompt)
	var actor := CharacterBody2D.new()
	actor.collision_layer = 1
	actor.collision_mask = 0
	actor.add_to_group(&"player")
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	collider.shape = circle
	actor.add_child(collider)
	actor.position = Vector2(80, 0)
	root.add_child(actor)
	for frame in 5: await physics_frame
	_check(zone.nearby_player == actor, "real body overlap at 80px")
	_check(not zone.request_extraction(actor), "center outside 72px cannot start defense")
	_check(not last_prompt.contains("F · 탈출 방어전 시작"), "outer overlap must not promise a usable F action")
	actor.position = Vector2(70, 0)
	for frame in 5: await physics_frame
	zone.advance(0.0)
	_check(last_prompt.contains("탈출 방어전 시작"), "moving inside without body re-entry refreshes prompt")
	await _tap(KEY_F)
	_check(zone.get_snapshot().defense_active, "physical F starts defense without injecting nearby actor")
	zone.advance(1.0)
	var remaining: float = zone.defense_remaining_seconds
	actor.position = Vector2(80, 0)
	zone.advance(1.0)
	_check(zone.defense_paused and is_equal_approx(remaining, zone.defense_remaining_seconds), "outer overlap pauses without consuming time")
	_check(last_prompt.contains("복귀"), "paused defense explains how to resume")
	actor.position = Vector2(70, 0)
	zone.advance(0.0)
	_check(not zone.defense_paused, "center re-entry resumes")
	zone._cancel_defense()
	zone.set_locked(true, "신호 대기")
	await _tap(KEY_F)
	_check(not zone.get_snapshot().defense_active, "locked F cannot bypass timer")
	zone.interaction_radius = 96.0
	zone.configure(Vector2.ZERO)
	for frame in 4: await physics_frame
	_check(is_equal_approx(zone.get_node("CollisionShape2D").shape.radius, 96.0), "configured radius updates physical area")
	zone.free()
	actor.free()
	var game = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	for frame in 6: await process_frame
	# A visible "F" promise must use the same gate as the actual input, not a
	# separate 150px HUD threshold or an Area-only input shortcut.
	game.start_hub.position += Vector2(35, 25)
	var gate_position: Vector2 = game.start_hub.to_global(game.start_hub.get_operation_position())
	game.player.global_position = gate_position + Vector2(-140, 0)
	for frame in 5: await physics_frame
	game._update_hub_wayfinding(1.0)
	_check(not game.hub_objective_label.text.contains("F로"), "hub outside gate must not promise usable F")
	await _tap(KEY_F)
	_check(not game.run_setup_overlay.visible and not paused, "hub outside input does not open briefing")
	game.player.global_position = gate_position + Vector2(-118, 0)
	for frame in 5: await physics_frame
	_check(game.start_hub.nearby_player == null, "hub fixture outside rectangular overlap but inside request radius")
	game._update_hub_wayfinding(1.0)
	_check(game.hub_objective_label.text.contains("F로"), "hub radius eligibility shown")
	await _tap(KEY_F)
	_check(game.run_setup_overlay.visible and paused, "hub radius single F opens briefing")
	if game.run_setup_overlay.visible: await _tap(KEY_ESCAPE)
	game.start_hub.interaction_radius = 160.0
	game.player.global_position = gate_position + Vector2(-155, 0)
	for frame in 5: await physics_frame
	game._update_hub_wayfinding(1.0)
	_check(game.hub_objective_label.text.contains("F로"), "hub configured radius propagated to HUD")
	await _tap(KEY_F)
	_check(game.run_setup_overlay.visible, "hub configured radius propagated to input")
	if game.run_setup_overlay.visible: await _tap(KEY_ESCAPE)
	game.player.global_position = gate_position + Vector2(-180, 0)
	for frame in 5: await physics_frame
	game._update_hub_wayfinding(1.0)
	_check(not game.hub_objective_label.text.contains("F로"), "hub exit clears action promise")
	await _tap(KEY_F)
	_check(not game.run_setup_overlay.visible and not paused, "hub exit prevents stale interaction")
	game._open_run_setup()
	for frame in 4: await process_frame
	_check(game.operation_setup_presenter.get_snapshot().layout_fits, "first briefing layout fits before any resize")
	root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(1280,720), Vector2i(1024,720), Vector2i(844,720), Vector2i(800,720), Vector2i(640,720)]:
		root.size = dimensions
		for frame in 6: await process_frame
		_check(game.operation_setup_presenter.get_snapshot().layout_fits, "briefing fits at %d" % dimensions.x)
		_check(game.operation_setup_presenter.selected_tier_detail.text.contains("동시 적"), "selected detail is visible without hover")
		for button in game.operation_setup_presenter.tier_buttons.values():
			var font: Font = button.get_theme_font("font")
			var available: float = button.size.x - button.get_theme_stylebox("normal").get_minimum_size().x
			for line in button.text.split("\n"):
				_check(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x <= available + 1.0,
					"visible tier text fits at %d: %s" % [dimensions.x, line])
	game.free()
	for frame in 3: await process_frame
	if failures.is_empty():
		print("FUN_QA_AFFORDANCE_OK real_overlap center_gate physical_F pause_resume locked radius_sync hub_gate_shared_eligibility hub_radius_input hub_transformed hub_exit tier_text_widths_5")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _tap(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
