extends SceneTree

var failures := PackedStringArray()
const CONFIG = preload("res://game/features/combat_resources/configs/default_combat_resources.tres")
const RESOURCE_SCENE = preload("res://game/features/combat_resources/combat_resource_system.tscn")
const LOADOUT = preload("res://game/features/combat_skills/configs/default_combat_skills.tres")

class Actor extends Node:
	var moving := false
	func heal(_amount: float, _source: StringName = &"") -> void: pass
	func get_health_snapshot() -> Dictionary: return {&"current": 100.0, &"maximum": 100.0}
	func is_moving_for_resource_recovery() -> bool: return moving

func _init() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if not value: failures.append(label)
func near(a: float, b: float, label: String) -> void:
	check(is_equal_approx(a,b), "%s: %s != %s" % [label,a,b])

func _run() -> void:
	var csv := FileAccess.get_file_as_string("res://game/features/character_selection/data/character_catalog.csv")
	var parsed := CharacterTable.parse(csv)
	check(parsed.errors.is_empty(), "locked catalog valid")
	var definition: Resource = parsed.definitions[0]
	check(definition.character_id == &"vanguard" and definition.passive_id == &"tactical_adaptation", "stable character identity, one new passive")
	near(definition.skill_damage_multiplier,1,"old damage bonus removed")
	var modifiers: Dictionary = definition.resource_modifiers()
	var actor := Actor.new()
	var world := Node2D.new()
	root.add_child(actor)
	root.add_child(world)
	var resources = RESOURCE_SCENE.instantiate()
	root.add_child(resources)
	resources.set_process(false)
	check(resources.configure(actor,world,LOADOUT,CONFIG,1,modifiers),"resource setup")
	near(resources.get_snapshot().energy_maximum,115,"AP cap")
	near(resources.current_energy,115,"initial AP")
	check(resources.consume_for_skill(0),"normal skill cost")
	var spent: float = resources.current_energy
	resources.advance(1)
	near(resources.current_energy,spent,"same recovery delay")
	resources.advance(0.5)
	near(resources.current_energy,spent+5,"stationary recovery")
	actor.moving = true
	resources.advance(0.5)
	near(resources.current_energy,spent+11,"moving recovery")
	var saved: Dictionary = resources.export_runtime_state()
	resources.advance(0.1)
	check(resources.restore_runtime_state(saved),"training restoration")
	near(resources.current_energy,saved.energy,"restored AP")
	resources.set_resource_modifiers({})
	var baseline: float = resources.current_energy
	resources.set_resource_modifiers(modifiers)
	resources.set_resource_modifiers(modifiers)
	near(resources.current_energy,baseline,"selection repeated no refill")
	check(not resources.set_resource_modifiers({&"capacity_multiplier":NAN}),"nonfinite rejected")
	check(not resources.set_resource_modifiers({&"capacity_multiplier":6}),"range rejected")
	check(not resources.set_resource_modifiers({&"unknown":1}),"unknown field rejected")
	near(resources.get_maximum_energy(),115,"invalid keeps last good")
	modifiers[&"capacity_multiplier"] = 2
	near(resources.get_maximum_energy(),115,"frozen modifiers")
	resources.restore_energy(1000)
	near(resources.current_energy,115,"drop clamped to passive cap")
	near(CONFIG.maximum_energy,100,"shared base not mutated")
	check(resources.configure(actor,world,LOADOUT,CONFIG,1),"reconfigure without passive")
	near(resources.current_energy,100,"no passive leakage")
	check(not CharacterTable.parse(csv.replace(",1.15,1.2",",bad,1.2")).errors.is_empty(),"bad CSV numeric rejected")
	var legacy_lines := PackedStringArray()
	for line in csv.split("\n", false):
		legacy_lines.append(String(line.rsplit(",", true, 2)[0]))
	var legacy := CharacterTable.parse("\n".join(legacy_lines))
	check(legacy.errors.is_empty(),"older live CSV accepted")
	if not legacy.definitions.is_empty():
		near(legacy.definitions[0].energy_capacity_multiplier,1,"older live CSV neutral capacity")
		near(legacy.definitions[0].moving_energy_regeneration_multiplier,1,"older live CSV neutral recovery")
	world.queue_free()
	actor.queue_free()
	resources.queue_free()
	await process_frame
	await _movement_contract()
	await _game_flow()
	if failures.is_empty():
		print("VANGUARD_RESOURCE_OK cap115 regen10_12 immutable no_refill training run hub optional")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _movement_contract() -> void:
	var player = load("res://game/features/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	await physics_frame
	player.velocity = Vector2(120,0)
	player.move_and_slide()
	check(player.is_moving_for_resource_recovery(),"actual displacement enables recovery")
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	check(not player.is_moving_for_resource_recovery(),"stopped displacement disables recovery")
	player.position += Vector2(100,0)
	check(not player.is_moving_for_resource_recovery(),"warp does not count as locomotion")
	var wall := StaticBody2D.new()
	wall.collision_layer = 16
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10,200)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = player.position + Vector2(40,0)
	root.add_child(wall)
	for frame in 30:
		await physics_frame
		player.velocity = Vector2(300,0)
		player.move_and_slide()
	check(not player.is_moving_for_resource_recovery(),"held velocity into wall does not earn moving bonus")
	wall.free()
	player.free()

func _game_flow() -> void:
	var game = load("res://game/scenes/game.tscn").instantiate()
	var features: Resource = game.features.duplicate(true)
	var directory := OS.get_cache_dir().path_join("sfh-vanguard-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	for field in ["persistent_profile", "conditional_ranking", "meta_progression", "key_mapping", "skill_binding", "presentation_settings", "desktop_progress"]:
		features.set(field + "_storage_path", directory.path_join(field + ".json"))
	game.features = features
	root.add_child(game)
	for frame in 6: await process_frame
	near(game.training_combat_resource_system.get_maximum_energy(),115,"hub training initial")
	game.character_selection_service.select_character(&"runner")
	near(game.training_combat_resource_system.get_maximum_energy(),100,"hub runner")
	game.character_selection_service.select_character(&"vanguard")
	near(game.training_combat_resource_system.get_maximum_energy(),115,"hub vanguard")
	near(game.training_combat_resource_system.current_energy,100,"hub swap no free refill")
	for tier in ["small","medium","large"]:
		game.persistent_profile.reset_profile(true)
		var launched: bool = game.start_run(tier)
		check(launched,"operation launch %s: %s" % [tier,game.status_label.text])
		if not launched: break
		for frame in 2: await process_frame
		var runtime: Node = game.combat_resource_system
		near(runtime.get_maximum_energy(),115,"operation cap " + tier)
		near(runtime.current_energy,115,"operation initial " + tier)
		check(game.player.has_method(&"is_moving_for_resource_recovery"),"movement public provider")
		check(not game.player.is_moving_for_resource_recovery(),"stationary actor")
		check(runtime.get_skill_resource_snapshot(0).energy_maximum == runtime.get_maximum_energy(),"HUD resource agreement")
		game.character_selection_service.select_character(&"runner")
		near(runtime.get_maximum_energy(),115,"running contract frozen")
		game._abandon_run_to_start_hub()
		for frame in 2: await process_frame
		game.character_selection_service.select_character(&"vanguard")
	game.queue_free()
	for frame in 3: await process_frame
	var optional = load("res://game/scenes/game.tscn").instantiate()
	optional.features = features.duplicate(true)
	optional.features.character_selection_enabled = false
	root.add_child(optional)
	for frame in 5: await process_frame
	near(optional.training_combat_resource_system.get_maximum_energy(),100,"disabled character module training fallback")
	check(optional.start_run("small"),"disabled character module launch")
	if optional.combat_resource_system != null:
		near(optional.combat_resource_system.get_maximum_energy(),100,"disabled character module resource fallback")
	optional.queue_free()
	for frame in 3: await process_frame
