extends SceneTree
## Controlled GPU presentation fixture, not an ordinary-play acceptance claim.

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("COMBAT_FX_RENDER_REQUIRES_GPU")
		quit(1)
		return
	root.size = Vector2i(960, 540)
	var stage := Node2D.new()
	root.add_child(stage)
	var floor_panel := Polygon2D.new()
	floor_panel.polygon = PackedVector2Array([Vector2.ZERO,Vector2(960,0),Vector2(960,540),Vector2(0,540)])
	floor_panel.color = Color("101c24")
	stage.add_child(floor_panel)
	for index in 4:
		var label := Label.new()
		label.text = ["FIRE / bounded muzzle flash", "BLINK / departure + arrival", "FIELD / stable radius, 80% lifetime", "BOOST / active aura"][index]
		label.position = Vector2(28 + (index % 2) * 480, 16 + (index / 2) * 270)
		stage.add_child(label)
		var player := Polygon2D.new()
		player.polygon = PackedVector2Array([Vector2(-12,-12),Vector2(12,-12),Vector2(12,12),Vector2(-12,12)])
		player.position = Vector2(210 + (index % 2) * 480, 148 + (index / 2) * 270)
		player.color = Color("02e5e1")
		stage.add_child(player)
		if index == 0:
			var fx = load("res://game/features/weapons/weapon_shot_fx.gd").new()
			stage.add_child(fx)
			fx.play(player.position, Vector2.RIGHT, Color("02e5e1"))
			fx._process(0.025)
			fx.set_process(false)
		else:
			var effect = load("res://game/features/combat_skills/effects/electric_arc_effect.gd").new()
			stage.add_child(effect)
			var file: String = ["", "blink", "magnetic", "speed"][index]
			var profile = load("res://game/features/combat_skills/effects/profiles/"+file+"_electric.tres").duplicate(true)
			effect.position = player.position
			if index == 1:
				effect.position.x -= 150.0
				effect.configure_trail(Vector2(240,0),profile)
			else:
				effect.configure_radial(100.0 if index == 2 else 78.0,profile)
				effect._process(profile.lifetime_seconds * 0.8 if index == 2 else 1.0)
			effect.set_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://outputs/combat-fx")
	var image := root.get_texture().get_image()
	var result := image.save_png("res://outputs/combat-fx/overview.png")
	print("COMBAT_FX_RENDER_OK" if result == OK else "COMBAT_FX_RENDER_FAILED")
	stage.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
