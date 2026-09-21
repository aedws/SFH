extends SceneTree

class ExitProvider:
	extends Node
	func get_extraction_candidates() -> Array:
		return [{&"position": Vector2.ZERO}, {&"position": Vector2(500, 0)}]

func _init() -> void:
	call_deferred(&"_run")

func _run() -> void:
	var zone := ExtractionZone.new()
	root.add_child(zone)
	zone.set_process(false)
	zone.configure(Vector2.ZERO, 20.0)
	var actor := Node2D.new()
	root.add_child(actor)
	actor.add_to_group(&"player")
	assert(zone.request_extraction(actor))
	zone.advance(8.0)
	assert(is_equal_approx(zone.defense_remaining_seconds, 12.0))
	actor.position = Vector2(200, 0)
	zone.advance(2.0)
	assert(is_equal_approx(zone.defense_remaining_seconds, 12.0), "Grace preserves time")
	zone.advance(1.5)
	assert(is_equal_approx(zone.defense_remaining_seconds, 13.5), "Outside grace regresses one second per second")
	assert(zone.get_snapshot().exit_decay_active and "역행" in zone.defense_status_label())
	assert(zone.get_snapshot().defense_hud_label == "역행 13.5초")
	zone.advance(500.0)
	assert(is_equal_approx(zone.defense_remaining_seconds, 20.0), "Cannot exceed initial defense duration")
	assert(not zone.request_extraction(actor), "Outside F cannot reset grace or finish")
	assert(zone.get_snapshot().exit_decay_active)
	actor.position = Vector2.ZERO
	assert(zone.request_extraction(actor))
	assert(zone.outside_seconds == 0.0 and not zone.defense_paused)
	zone.advance(4.0)
	actor.position = Vector2(200, 0)
	zone.advance(1.9)
	assert("유예" in zone.defense_status_label())
	assert(zone.get_snapshot().defense_hud_label == "유예 0.1초")
	zone.advance(0.2)
	assert(is_equal_approx(zone.defense_remaining_seconds, 16.1), "Boundary crossing only counts 0.1s")
	var before := zone.defense_remaining_seconds
	zone.advance(-1.0)
	zone.advance(NAN)
	zone.advance(INF)
	assert(is_equal_approx(zone.defense_remaining_seconds, before))
	var policy := ExtractionExitPolicy.new()
	assert(not zone.configure_exit_policy(policy), "Running session policy cannot be mutated")
	zone._cancel_defense()
	policy.grace_seconds = -1.0
	assert(not zone.configure_exit_policy(policy))
	policy.grace_seconds = NAN
	assert(not policy.is_valid())
	policy.grace_seconds = 0.5
	policy.decay_seconds_per_second = 2.0
	assert(zone.configure_exit_policy(policy))
	policy.decay_seconds_per_second = 9.0
	assert(zone.exit_policy.decay_seconds_per_second == 2.0, "Copy-on-configure policy snapshot")
	actor.position = Vector2.ZERO
	assert(zone.request_extraction(actor))
	zone.advance(4.0)
	actor.position = Vector2(200,0)
	zone.advance(1.0)
	assert(is_equal_approx(zone.defense_remaining_seconds, 17.0), "Configurable grace and decay")
	actor.free()
	zone.advance(1.0)
	assert(not zone.get_snapshot().defense_active and not zone.defense_paused and zone.outside_seconds == 0.0)
	zone.free()
	# Both physical exits use the same policy; choosing one retains single settlement.
	for selected in [0, 1]:
		var exits := MultiExtractionZone.new()
		root.add_child(exits)
		exits.set_process(false)
		exits.configure(Vector2.ZERO, 10.0)
		var provider := ExitProvider.new()
		exits.configure_candidates(provider)
		provider.free()
		policy.grace_seconds = 2.0
		policy.decay_seconds_per_second = 1.0
		assert(exits.configure_exit_policy(policy))
		var player := Node2D.new()
		root.add_child(player)
		player.add_to_group(&"player")
		player.position = Vector2(500 * selected, 0)
		var origin := player.position
		var completions := [0]
		exits.extraction_completed.connect(func(_who): completions[0] += 1)
		assert(exits.request_extraction(player))
		exits.advance(4.0)
		player.position += Vector2(200, 0)
		exits.advance(2.5)
		assert(is_equal_approx(exits.get_snapshot().defense_remaining_seconds, 6.5))
		assert(exits.get_snapshot().exit_decay_active)
		assert(not exits.configure_exit_policy(policy), "Alternative active also freezes policy")
		player.position = origin
		exits.advance(0.5)
		assert(not exits.get_snapshot().defense_paused and exits.get_snapshot().outside_seconds == 0.0)
		exits.advance(6.0)
		exits.advance(100.0)
		assert(completions[0] == 1 and not exits.request_extraction(player))
		exits.free()
		player.free()
	# Pure math is independent of frame slicing and supports explicit legacy pause.
	assert(is_equal_approx(policy.regression(0.0,3.5), policy.regression(0.0,1.9)+policy.regression(1.9,2.1)+policy.regression(2.1,3.5)))
	policy.decay_seconds_per_second = 0.0
	assert(policy.regression(0.0,100.0) == 0.0 and not policy.is_decaying(100.0))
	var config := ExtractionDefenseConfig.new()
	config.exit_policy = policy
	assert(config.is_valid())
	policy.decay_seconds_per_second = INF
	assert(not config.is_valid())
	print("EXTRACTION_DECAY_OK grace_boundary frame_slicing cap reentry invalid_delta immutable_policy both_exits single_settlement hud_labels cancel_actor_cleanup legacy_policy")
	quit()
