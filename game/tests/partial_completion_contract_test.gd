extends SceneTree

const QUOTE := preload("res://game/features/p5_hub_progression/shop_quote_policy.gd")
const FLOOR := preload("res://game/features/map_generation/dungeon_floor_layer.gd")
const SENSOR := preload("res://game/features/smart_targeting/target_candidate_area.gd")
var failures := PackedStringArray()
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()

func _init() -> void:
	node_added.connect(isolation.isolate)
	_run.call_deferred()

func _run() -> void:
	var standard := {&"quality": &"standard", &"target_id": &"medkit", &"target_type": &"item", &"quantity": 2, &"price": 80}
	var offer := {&"quality": &"damaged", &"target_id": &"medkit", &"target_type": &"item", &"quantity": 1, &"price": 10, &"performance_multiplier": 0.8}
	var catalog: Array[Dictionary] = [standard, offer]
	var profile := {&"banked_credits": 100}
	_check(QUOTE.quote(offer, catalog, profile, 0).purchasable, "25% unit price accepted")
	for price in [8, 12]:
		offer.price = price
		_check(QUOTE.quote(offer, catalog, profile, 0).purchasable, "inclusive price boundary")
	for price in [7, 13, 40]:
		offer.price = price
		_check(not QUOTE.quote(offer, catalog, profile, 0).purchasable, "invalid price blocked before spending")
	for performance in [0.69, 0.91]:
		offer.price = 10
		offer.performance_multiplier = performance
		_check(not QUOTE.quote(offer, catalog, profile, 0).purchasable, "invalid performance blocked")
	for performance in [0.7, 0.9]:
		offer.performance_multiplier = performance
		_check(QUOTE.quote(offer, catalog, profile, 0).purchasable, "inclusive performance boundary")
	var absent: Array[Dictionary] = [offer]
	_check(not QUOTE.quote(offer, absent, profile, 0).purchasable, "missing standard blocked")
	var conflicting := standard.duplicate()
	conflicting.price = 120
	catalog.append(conflicting)
	_check(not QUOTE.quote(offer, catalog, profile, 0).purchasable, "ambiguous standard blocked")
	var floor_layer := FLOOR.new()
	root.add_child(floor_layer)
	var cells := {Vector2i(-2, -1): true, Vector2i.ZERO: true, Vector2i(2, 3): true}
	floor_layer.rebuild(cells, 32.0, Color.BLACK, Color.BLUE)
	_check(floor_layer.get_used_cells().size() == 3, "negative and positive tiles populated")
	_check(floor_layer.map_to_local(Vector2i.ZERO) == Vector2(16, 16), "tiles align with world cell centers")
	_check(not floor_layer.get_snapshot().collision_enabled and not floor_layer.get_snapshot().navigation_enabled, "no duplicate physics")
	floor_layer.rebuild({Vector2i.ONE: true}, 64.0, Color.RED, Color.GREEN)
	_check(floor_layer.get_used_cells().size() == 1, "regenerate clears previous map")
	_check(floor_layer.map_to_local(Vector2i.ZERO) == Vector2(32, 32), "cell size changes supported")
	floor_layer.free()
	var sensor := SENSOR.new()
	root.add_child(sensor)
	var target := CharacterBody2D.new()
	target.collision_layer = 2
	target.collision_mask = 0
	target.position = Vector2(30, 0)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	target.add_child(shape)
	root.add_child(target)
	var allowed: Array = [target]
	_check(sensor.collect(allowed, Vector2.ZERO, 100).size() == 1, "first-frame spawn not lost")
	for frame in 5: await physics_frame
	_check(sensor.get_overlapping_bodies().has(target), "real Area2D overlap")
	_check(sensor.collect(allowed, Vector2.ZERO, 100).size() == 1, "primed candidate detected")
	_check(sensor.collect([], Vector2.ZERO, 100).is_empty(), "foreign targets excluded")
	target.position = Vector2(110, 0)
	_check(sensor.collect(allowed, Vector2.ZERO, 100).is_empty(), "stale overlap outside center range excluded")
	for frame in 5: await physics_frame
	_check(sensor.collect(allowed, Vector2.ZERO, 150).size() == 1, "range increase immediate")
	target.free()
	_check(sensor.collect(allowed, Vector2.ZERO, 150).is_empty(), "freed target safe")
	sensor.free()
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	for frame in 4: await process_frame
	_check(game.start_run("small"), "normal game launch")
	root.content_scale_size = Vector2i.ZERO
	for viewport_size in [Vector2i(1100, 720), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for frame in 4: await process_frame
		for detail in [&"weapon", &"equipment"]:
			game.combat_hud_presenter.reveal_detail(detail)
			for frame in 2: await process_frame
			var hud: Dictionary = game.combat_hud_presenter.get_snapshot(game.get_node("UI/HUDMargin"))
			_check(hud.detail_safe_clear, "revealed card leaves player sightline clear")
			var rect: Rect2 = hud.get(&"weapon_rect" if detail == &"weapon" else &"equipment_rect")
			_check(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(rect), "revealed card inside viewport")
			_check(not rect.intersects(hud.core_rect) and not rect.intersects(hud.telemetry_rect), "revealed card avoids vitals")
	game.free()
	for frame in 4: await process_frame
	if failures.is_empty():
		print("PARTIAL_COMPLETION_OK shop_band tile_layer area_candidates")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
