extends SceneTree
var failures: Array[String] = []
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()
var capture_dir := ""

func _initialize() -> void:
	node_added.connect(isolation.isolate)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir=arg.trim_prefix("--capture-dir=")
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _run() -> void:
	var catalog := preload("res://game/features/map_generation/facility_catalog.gd").new()
	_check(catalog.rows.size()==5,"locked Facility rows")
	var before := catalog.get_rows()
	_check(not catalog.load_csv("invalid") and catalog.get_rows()==before,"invalid table preserves last valid rows")
	var csv := preload("res://game/features/map_generation/data/facility_payload.tres").csv_text
	_check(catalog.load_csv(csv.replace("warehouse,",'"warehouse",')),"quoted Sheets CSV")
	var parsed := preload("res://game/features/balance_data/csv_rows.gd").parse("id,note\n1,\"두 줄\n설명 \"\"인용\"\"\"\n")
	_check(parsed.size()==2 and parsed[1][1]=="두 줄\n설명 \"인용\"","multiline planner note and escaped quote")
	_check(preload("res://game/features/balance_data/csv_rows.gd").parse('id,"unfinished').is_empty(),"malformed quotes rejected")
	for tier in ["small","medium","large"]:
		for seed_value in [90801,90802,90803]:
			var map = load("res://game/features/map_generation/map_generator.tscn").instantiate()
			root.add_child(map)
			map.generate(load("res://game/features/map_generation/configs/%s.tres"%tier),seed_value)
			_check(map.get_district_snapshot().street_cycles>=9,"loop topology")
			for room: Dictionary in map.get_room_encounter_snapshot():
				_check(room.open_directions.size()>=2,"two facility exits %s/%d/%d"%[tier,seed_value,room.room_index])
				_check(not map.get_world_path(map.start_position,room.center).is_empty(),"all facilities reachable")
			_check(map.get_extraction_candidates().size()==2,"two exits")
			var footprint: Array=map.rooms.duplicate()
			map.generate(load("res://game/features/map_generation/configs/%s.tres"%tier),seed_value)
			_check(footprint==map.rooms,"seed reproducibility")
			map.free()
		await _session(tier)
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("EXTRACTION_DISTRICT_OK geometry_seeds_9 launch_tiers_3 seeded_cycles two_entrances space_memory doorway_hysteresis retreat persistent_patrol no_respawn optional_vault credit_boxes terminal_warp two_exits single_settlement locked_csv")
	quit(0 if failures.is_empty() else 1)

func _session(tier: String) -> void:
	var game = load("res://game/scenes/game.tscn").instantiate()
	game.features=game.features.duplicate(true)
	game.features.run_setup_enabled=false
	game.features.start_hub_enabled=false
	game.features.map_size=tier
	game.features.map_seed=90803
	root.add_child(game)
	await process_frame
	_check(game.run_started,"game launch %s"%tier)
	if not game.run_started: game.free(); return
	game.player.set_runtime_modifier_source(&"qa",{&"max_health":{&"add":100000,&"multiply":1}})
	var fog_evidence: Dictionary=preload("res://game/tests/support/space_fog_contract.gd").verify(game.fog_of_war,game.map_generator,game.player)
	_check(fog_evidence.passed,"space fog %s %s"%[tier,fog_evidence.errors])
	var encounters = game.room_encounter_system
	encounters.set_process(false)
	var patrol: Dictionary={}
	var vault: Dictionary={}
	for room: Dictionary in game.map_generator.get_room_encounter_snapshot():
		if room.is_start_room or room.is_extraction_room: continue
		if room.encounter=="objective": vault=room
		elif patrol.is_empty(): patrol=room
	game.player.global_position=patrol.center
	encounters._process(0)
	var active: Dictionary=encounters.get_snapshot()
	_check(active.patrol_enemy_count>=active.minimum_horde_size,"minimum patrol horde")
	_check(active.locked_door_count==0,"ordinary entry never locks")
	game.player.global_position=game.map_generator.start_position
	encounters._process(0)
	_check(encounters.get_snapshot().patrol_enemy_count==active.patrol_enemy_count,"retreat does not remove enemies")
	for enemy in game.enemy_spawner.get_active_targets(): enemy.free()
	encounters._process(1)
	_check(encounters.is_room_completed(patrol.room_index),"patrol cleared")
	var spawned: int=game.enemy_spawner.get_snapshot().total_spawned
	game.player.global_position=patrol.center
	encounters._process(0)
	_check(game.enemy_spawner.get_snapshot().total_spawned==spawned,"no repeat patrol farm")
	_check(encounters.get_snapshot().rewards_spawned==0,"ordinary clear not objective credit box")
	game.player.global_position=vault.center
	encounters._process(0)
	_check(encounters.get_snapshot().active_room_index<0,"vault not auto-triggered")
	_check(not encounters.try_start_room(vault.room_index,&"external"),"remote trigger rejected")
	_check(encounters.try_start_room(vault.room_index,&"terminal"),"explicit vault terminal")
	_check(encounters.get_snapshot().locked_door_count>=2,"vault seals all entrances")
	_check(not game.room_warp_system.request_warp(0),"locked vault cannot warp")
	await _capture(game,tier+"-vault")
	for enemy in game.enemy_spawner.get_active_targets(): enemy.free()
	encounters._process(0)
	var clear: Dictionary=encounters.get_snapshot()
	_check(clear.locked_door_count==0 and clear.last_reward_box_count>=1 and clear.last_reward_box_count<=5,"vault opens and rewards")
	_check(game.extraction_unlocked and game.extraction_unlock_seconds==0,"no timer/full-clear gate")
	game.player.global_position=game.map_generator.start_position
	var nearby_threat := Node2D.new()
	root.add_child(nearby_threat)
	nearby_threat.add_to_group(&"enemies")
	nearby_threat.global_position=game.player.global_position+Vector2(64,0)
	_check(not game.room_warp_system.request_warp(0),"nearby threat rejects terminal warp")
	nearby_threat.free()
	_check(game.room_warp_system.request_warp(0),"safe terminal warp")
	game.player.global_position=vault.center
	_check(not game.room_warp_system.request_warp(0),"remote warp rejected")
	var zone=game.extraction_zone
	_check(zone.get_snapshot().exit_count==2,"game wires two exits")
	var alternative: Node=zone.alternatives[0]
	game.player.global_position=alternative.global_position
	if game.operation_tutorial_overlay != null: game.operation_tutorial_overlay.dismiss()
	for frame in 5: await physics_frame
	# Close an optional loot comparison using its public command before F is
	# expected to address the exit. No nearby-player injection/direct extraction.
	game.field_loot_acquisition_service.cancel_preview()
	await _tap(KEY_F)
	_check(zone.get_snapshot().defense_active,"alternate exit accepts physical F")
	zone.advance(1)
	var remaining: float=zone.get_snapshot().defense_remaining_seconds
	game.player.global_position+=Vector2(300,0)
	zone.advance(1)
	_check(zone.get_snapshot().defense_paused and zone.get_snapshot().defense_remaining_seconds==remaining,"alternate pause preserves countdown")
	game.player.global_position=alternative.global_position
	zone.advance(0.1)
	_check(not zone.get_snapshot().defense_paused,"alternate resumes")
	await _capture(game,tier+"-exit")
	zone.advance(200)
	_check(game.run_ended,"alternate settles operation")
	_check(not zone.request_extraction(game.player),"completed exit rejects repeated settlement")
	game.queue_free()
	await process_frame
	await process_frame

func _tap(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame

func _capture(game: Node, label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless": return
	if game.operation_tutorial_overlay != null: game.operation_tutorial_overlay.dismiss()
	var camera := root.get_camera_2d()
	if camera != null: camera.reset_smoothing()
	for i in 24: await process_frame
	game.fog_of_war.call(&"_process",0.3)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.get_texture().get_image().save_png(capture_dir.path_join(label+".png"))
