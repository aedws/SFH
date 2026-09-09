extends SceneTree
## Render-only isolated map review, no saves or player state injection.
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1280,720)
	var map=load("res://game/features/map_generation/map_generator.tscn").instantiate()
	root.add_child(map)
	map.generate(load("res://game/features/map_generation/configs/small.tres"),90808)
	var camera := Camera2D.new()
	root.add_child(camera)
	var plan: Dictionary=map.get_regional_plan()
	var room: Rect2i=map.rooms[1]
	var captures := {"street":Vector2(plan.street_axes[1].at+5,plan.street_axes[-2].at+6)*map.cell_size,"building":Vector2(room.position.x+room.size.x/2,room.position.y)*map.cell_size,"interior":Vector2(room.get_center())*map.cell_size,"overview":Vector2(room.get_center())*map.cell_size}
	DirAccess.make_dir_recursive_absolute("res://outputs/urban-review")
	for label: String in captures:
		camera.zoom=Vector2.ONE*(0.3 if label=="overview" else 1.0)
		camera.position=captures[label]
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://outputs/urban-review/%s.png"%label)
	print("URBAN_VISUAL_REVIEW_OK ",JSON.stringify(map.floor_layer.get_snapshot()))
	map.free()
	quit()
