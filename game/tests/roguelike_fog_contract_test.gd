extends SceneTree
const FIELD := preload("res://game/features/fog_of_war/visibility_field.gd")
var failures: Array[String] = []
var capture_dir := ""
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()

class Geometry extends Node2D:
	var data: Dictionary
	func get_fog_geometry() -> Dictionary: return data.duplicate(true)
	func get_visibility_region(_position: Vector2) -> Dictionary: return {&"mode": &"room", &"room_index": 0}
	func get_visibility_room_rects() -> Array[Rect2]: return []
	func _draw() -> void:
		var bounds: Rect2i = data.bounds
		for y in range(bounds.size.y):
			for x in range(bounds.size.x):
				var kind: int = data.terrain[y * bounds.size.x + x]
				draw_rect(Rect2(Vector2(x,y)*32, Vector2(32,32)), Color("5a6570") if kind == 2 else Color("284353"))


class SpaceGeometry extends Geometry:
	func get_visibility_spaces() -> Array[Dictionary]:
		return [
			{&"space_id":0,&"kind":&"room",&"world_rect":Rect2(0,0,384,608)},
			{&"space_id":1,&"kind":&"room",&"world_rect":Rect2(416,0,448,608)},
		]

func _initialize() -> void:
	node_added.connect(isolation.isolate)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	call_deferred(&"_run")


func _geometry() -> Dictionary:
	var terrain := PackedByteArray()
	terrain.resize(27 * 19)
	terrain.fill(1)
	for y in 19:
		if y != 9: terrain[y * 27 + 12] = 2
	return {&"bounds": Rect2i(0,0,27,19), &"cell_size": 32.0, &"terrain": terrain}


func _run() -> void:
	var field := FIELD.new()
	var geometry := _geometry()
	var open_field := FIELD.new()
	var open_geometry := _geometry()
	open_geometry.terrain.fill(1)
	_check(open_field.configure(open_geometry), "open geometry")
	open_geometry.terrain.fill(2)
	open_field.update(Vector2(432,304),8,{})
	for y in range(-8,9):
		for x in range(-8,9):
			if x*x+y*y <= 64:
				_check(open_field.visible_cells.has(Vector2i(13+x,9+y)), "unobstructed circle and copied geometry")
	_check(not FIELD.new().configure({&"bounds":Rect2i(0,0,0,0)}), "invalid geometry rejected")
	_check(field.configure(geometry), "valid geometry")
	var original := Vector2(208, 144)
	_check(field.update(original, 20, {}), "initial update")
	_check(field.state_at(Vector2(400,144)) == &"visible", "wall face visible")
	_check(field.state_at(Vector2(528,144)) == &"unexplored", "wall blocks hidden room")
	_check(field.state_at(Vector2(112,144)) == &"visible", "rear as visible as front")
	var updates := field.updates
	field.update(original,20,{})
	_check(field.updates == updates, "idle computation cached")
	field.update(Vector2(528,144),20,{})
	_check(field.state_at(original) == &"explored", "departed floor remembered")
	field.update(original,4,{})
	_check(field.state_at(Vector2(528,144)) == &"explored", "penalty cannot erase explored terrain")
	var corner := FIELD.new()
	var corners := _geometry()
	corners.terrain[2*27+3] = 2
	corners.terrain[3*27+2] = 2
	corner.configure(corners)
	corner.update(Vector2(80,80),10,{})
	_check(corner.state_at(Vector2(112,112)) == &"unexplored", "sealed diagonal corner")
	for a in [Vector2i(2,2),Vector2i(5,6),Vector2i(8,9)]:
		for b in [Vector2i(15,9),Vector2i(10,2),Vector2i(7,12)]:
			_check(corner.has_line_of_sight(a,b) == corner.has_line_of_sight(b,a), "floor reciprocity")
	field.configure(geometry)
	_check(field.explored_cells.is_empty(), "new session clears memory")
	await _render_test()
	await _space_render_test()
	await _generated_maps()
	for failure in failures: push_error(failure)
	if failures.is_empty():
		print("ROGUELIKE_FOG_OK three_states circular_rear walls corners memory idle_cache doors thin_doors session_reset maps_3")
		print("ROGUELIKE_FOG_PIXELS_", "SKIPPED" if DisplayServer.get_name() == "headless" else "OK")
		print("SPACE_FOG_PIXELS_", "SKIPPED" if DisplayServer.get_name() == "headless" else "OK")
	quit(0 if failures.is_empty() else 1)


func _render_test() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(864,608)
	var map := Geometry.new()
	map.data = _geometry()
	root.add_child(map)
	var actor := Node2D.new()
	actor.position = Vector2(208,304)
	root.add_child(actor)
	var target := ColorRect.new()
	target.color = Color.RED
	target.position = Vector2(512,288)
	target.size = Vector2(32,32)
	root.add_child(target)
	var fog: Node = load("res://game/features/fog_of_war/fog_of_war.tscn").instantiate()
	root.add_child(fog)
	_check(fog.configure(actor,map), "runtime configured")
	await _frames()
	_check(fog.get_visibility_state(Vector2(528,304)) == &"visible", "open doorway LOS")
	if DisplayServer.get_name() != "headless":
		var before := await _pixel(Vector2i(528,304))
		_check(before.r > 0.9 and before.g < 0.1, "current target actually visible")
	await _capture("fog-open")
	var door := preload("res://game/features/room_encounters/room_door_barrier.gd").new()
	root.add_child(door)
	door.configure(Vector2(400,304),Vector2(32,32))
	await _frames()
	_check(fog.get_snapshot().dynamic_blocker_count > 0, "door blocker recognized while stationary")
	if DisplayServer.get_name() != "headless":
		var hidden := await _pixel(Vector2i(528,304))
		target.color = Color.BLUE
		await _frames()
		var changed := await _pixel(Vector2i(528,304))
		_check(hidden.r < 0.3 and changed.is_equal_approx(hidden), "memory hides live enemy color changes")
	await _capture("fog-closed-memory")
	door.queue_free()
	await _frames()
	_check(fog.get_snapshot().dynamic_blocker_count == 0, "door removal immediate")
	if DisplayServer.get_name() != "headless":
		var reopened := await _pixel(Vector2i(528,304))
		_check(reopened.b > 0.9, "reopen restores live target")
		for angle in [0.0, 0.12, -0.12]:
			root.canvas_transform = Transform2D(angle, Vector2(0.8,0.8), 0, Vector2(45,30))
			await _frames()
			var projected := Vector2i(root.canvas_transform * Vector2(528,304))
			var camera_pixel := await _pixel(projected)
			_check(camera_pixel.b > 0.9, "camera zoom/rotation preserves visible target")
		root.canvas_transform = Transform2D.IDENTITY
	# Real barriers sit between grid cells. Standing next to one must not leak past it.
	door = preload("res://game/features/room_encounters/room_door_barrier.gd").new()
	root.add_child(door)
	door.configure(Vector2(384,304),Vector2(14,32))
	actor.position = Vector2(368,304)
	target.position = Vector2(392,296)
	target.size = Vector2(16,16)
	target.color = Color.RED
	await _frames()
	if DisplayServer.get_name() != "headless":
		var thin_hidden := await _pixel(Vector2i(400,304))
		_check(thin_hidden.r < 0.3, "thin door blocks same-cell target leak")
	fog.set_visibility_multiplier(0.5)
	_check(is_equal_approx(float(fog.get_snapshot().sight_radius),320), "penalty scales world radius")
	door.free()
	fog.free()
	actor.free()
	target.free()
	map.free()


func _space_render_test() -> void:
	var map := SpaceGeometry.new()
	map.data = _geometry()
	root.add_child(map)
	var actor := Node2D.new()
	actor.position = Vector2(208,304)
	root.add_child(actor)
	var target := ColorRect.new()
	target.position = Vector2(512,288)
	target.size = Vector2(32,32)
	target.color = Color.RED
	root.add_child(target)
	var fog: Node = load("res://game/features/fog_of_war/fog_of_war.tscn").instantiate()
	root.add_child(fog)
	_check(fog.configure(actor,map),"space renderer config")
	await _frames()
	_check(fog.get_visibility_state(Vector2(528,304))==&"unexplored","open doorway does not reveal next space")
	if DisplayServer.get_name()!="headless":
		_check((await _pixel(Vector2i(528,304))).r<0.3,"undiscovered space opaque on GPU")
	actor.position=Vector2(528,304)
	await _frames()
	fog._process(0.3)
	await _frames()
	if DisplayServer.get_name()!="headless":
		_check((await _pixel(Vector2i(528,304))).r>0.9,"whole entered space visible on GPU")
	actor.position=Vector2(208,304)
	await _frames()
	fog._process(0.3)
	await _frames()
	_check(fog.get_visibility_state(Vector2(528,304))==&"explored","departed space terrain memory")
	if DisplayServer.get_name()!="headless":
		var remembered := await _pixel(Vector2i(528,304))
		target.color=Color.BLUE
		await _frames()
		_check(remembered.r<0.3 and (await _pixel(Vector2i(528,304))).is_equal_approx(remembered),"space memory hides live actors on GPU")
	await _capture("space-memory")
	fog.free()
	target.free()
	actor.free()
	map.free()

func _frames() -> void:
	for _frame in 8: await process_frame


func _generated_maps() -> void:
	root.size = Vector2i(1280,720)
	for tier in [&"small", &"medium", &"large"]:
		var game: Node = load("res://game/scenes/game.tscn").instantiate()
		root.add_child(game)
		await _frames()
		_check(game.start_run(tier), "generated map starts %s" % tier)
		await _frames()
		if game.operation_tutorial_overlay != null: game.operation_tutorial_overlay.dismiss()
		var geometry: Dictionary = game.map_generator.get_fog_geometry()
		var benchmark := FIELD.new()
		_check(benchmark.configure(geometry), "geometry exported %s" % tier)
		var samples: Array[int] = []
		var start: Vector2 = game.player.global_position
		for i in 40:
			benchmark.update(start + Vector2((i % 10)*32, (i / 10)*32), 20, {})
			samples.append(benchmark.last_compute_usec)
		samples.sort()
		print("FOG_CPU_SAMPLE tier=%s updates=40 median_usec=%d p95_usec=%d mask_bytes=%d" % [tier,samples[20],samples[37],geometry.bounds.size.x*geometry.bounds.size.y*4])
		var observed: Dictionary = preload("res://game/tests/support/roguelike_fog_contract.gd").verify(game.fog_of_war,game.map_generator,game.player)
		_check(observed.passed, "generated door/corridor/warp %s %s" % [tier,observed.errors])
		await _frames()
		await _capture("fog-game-"+String(tier))
		game.free()
		await _frames()


func _pixel(point: Vector2i) -> Color:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().get_pixelv(point)


func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(label+".png"))


func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
