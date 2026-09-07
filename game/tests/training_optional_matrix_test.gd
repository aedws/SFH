extends SceneTree

const GAME := preload("res://game/scenes/game.tscn")
var isolation: RefCounted
var failures := PackedStringArray()

func _init() -> void:
	isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()

func _run() -> void:
	var cases := [
		{&"training_ground_enabled": false},
		{&"session_sockets_enabled": false},
		{&"combat_resources_enabled": false},
		{&"skill_binding_enabled": false, &"field_loot_skill_equip_enabled": false},
		{&"loadout_investment_enabled": false},
	]
	for flags in cases:
		var game = GAME.instantiate()
		game.features = game.features.duplicate(true)
		for flag in flags: game.features.set(flag, flags[flag])
		_check(game.features.validation_errors().is_empty(), "valid fixture %s" % flags)
		root.add_child(game)
		for frame in 4: await process_frame
		_check(is_instance_valid(game.start_hub) and not game.run_started, "hub preserved %s" % flags)
		if flags.has(&"training_ground_enabled"):
			_check(not is_instance_valid(game.training_ground_service), "training removed")
		else:
			game._cycle_hub_training()
			await process_frame
			var service: Node = game.training_ground_service
			_check(service.get_loadout_snapshot().active, "optional trial starts %s" % flags)
			if not flags.has(&"combat_resources_enabled"):
				_check(is_instance_valid(game.training_combat_skill_hud) and game.training_combat_skill_hud.visible, "complete skill runtime installation %s" % flags)
			if flags.has(&"combat_resources_enabled"):
				for button in game.training_loadout_presenter.skill_buttons:
					_check(button.disabled, "absent skill runtime is not clickable")
				_check(game.training_loadout_presenter.socket_button.disabled, "absent sockets not clickable")
			if flags.has(&"session_sockets_enabled"):
				_check(service.get_loadout_snapshot().socket_catalog.is_empty(), "sockets removed independently")
			if flags.has(&"loadout_investment_enabled"):
				var skills: Node = game.training_combat_skill_system
				var before: Dictionary = game.training_combat_resource_system.export_runtime_state()
				_check(not service.cycle_training_skill(0).success, "same skill not a free cooldown reset")
				_check(game.training_combat_resource_system.export_runtime_state() == before, "no-op resource unchanged")
				var adapter: Node = skills.binding_provider
				adapter.configure(skills.loadout, game.skill_binding_service)
				_check(adapter.original_ids.size() == skills.loadout.skills.size(), "adapter reconfigure replaces arrays")
			_check(game._finish_hub_training(), "optional training restores %s" % flags)
		game._open_run_setup()
		_check(game.run_setup_overlay.visible, "briefing preserved %s" % flags)
		game._close_run_setup()
		_check(is_instance_valid(game.start_hub), "cancel returns hub %s" % flags)
		_check(game.start_run("medium"), "medium launch survives optional modules %s" % flags)
		for frame in 4: await process_frame
		_check(game.run_started and is_instance_valid(game.player) and is_instance_valid(game.map_generator), "playable operation installed %s" % flags)
		game.queue_free()
		for frame in 3: await process_frame
	if failures.is_empty():
		print("TRAINING_OPTIONAL_MATRIX_OK cases_5 hub brief_cancel medium_launch controls_disabled no_self_reset adapter_reconfigure")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
