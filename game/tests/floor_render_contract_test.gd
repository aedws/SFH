extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, why: String) -> void:
	if not ok: failures.append(why)
func _run() -> void:
	var floor_layer = load("res://game/features/map_generation/dungeon_floor_layer.gd").new()
	root.add_child(floor_layer)
	floor_layer.chunk_cells = 32
	var cells := {Vector2i(-1, -1):true, Vector2i(-1, 0):true, Vector2i.ZERO:true, Vector2i(31, 0):true, Vector2i(32, 0):true, Vector2i(100000, 0):true}
	floor_layer.rebuild(cells, 32.5, Color.RED, Color.BLUE)
	check(floor_layer.get_snapshot().tile_count == 6, "cell count")
	check(floor_layer.get_snapshot().chunk_count == 5, "bounded sparse chunks, not giant map texture")
	check(floor_layer.get_snapshot().texture_bytes == 5 * 32 * 32 * 4, "bounded upload bytes")
	for cell: Vector2i in cells:
		var chunk := Vector2i(floori(cell.x / 32.0), floori(cell.y / 32.0))
		var local := cell - chunk * 32
		var image: Image = floor_layer._textures[chunk].get_image()
		check(image.get_pixelv(local).is_equal_approx(Color.RED if (cell.x + cell.y) % 2 == 0 else Color.BLUE), "checker parity at %s" % cell)
	check(floor_layer._textures[Vector2i.ZERO].get_image().get_pixel(1, 0).a == 0, "holes transparent")
	check(floor_layer.map_to_local(Vector2i(-1, 0)) == Vector2(-16.25, 16.25), "fractional size and negative cell center")
	# Actual framebuffer verifies nearest-cell edges and transparency without screenshots in timed samples.
	if DisplayServer.get_name() != "headless":
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		root.content_scale_size = Vector2i.ZERO
		root.size = Vector2i(320, 160)
		root.canvas_transform = Transform2D(0, Vector2(96, 64))
		for frame in 3: await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.get_pixel(112, 80).is_equal_approx(Color.RED), "rendered positive cell")
		check(image.get_pixel(79, 80).is_equal_approx(Color.BLUE), "rendered negative cell")
		check(not image.get_pixel(145, 80).is_equal_approx(Color.RED) and not image.get_pixel(145, 80).is_equal_approx(Color.BLUE), "rendered hole")
	floor_layer.rebuild(cells,32.5,Color.RED,Color.BLUE,{Vector2i.ZERO:Color.CYAN,Vector2i(-1,-1):Color.YELLOW,Vector2i(1,0):Color.GREEN})
	check(floor_layer._textures[Vector2i.ZERO].get_image().get_pixel(0,0).is_equal_approx(Color.CYAN), "city surface color overrides checker")
	check(floor_layer._textures[Vector2i(-1,-1)].get_image().get_pixel(31,31).is_equal_approx(Color.YELLOW), "city color across negative chunks")
	check(floor_layer._textures[Vector2i.ZERO].get_image().get_pixel(1,0).a==0, "palette cannot paint absent floor")
	floor_layer.rebuild({Vector2i.ONE:true}, 64, Color.GREEN, Color.RED)
	check(floor_layer._textures[Vector2i.ZERO].get_image().get_pixel(1,1).is_equal_approx(Color.GREEN), "legacy rebuild clears city palette")
	check(floor_layer.get_snapshot().chunk_count == 1 and floor_layer.get_used_cells().size() == 1, "regeneration discards chunks")
	floor_layer.rebuild({}, 32, Color.RED, Color.BLUE)
	check(floor_layer.get_snapshot().texture_bytes == 0, "empty map clears uploads")
	floor_layer.free()
	if failures.is_empty(): print("FLOOR_RENDER_OK negative parity boundaries holes fractional sparse bounded regenerate empty pixels")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
