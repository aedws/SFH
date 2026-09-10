extends SceneTree
## GPU perception gate at reduced scale and both floor luminances. Not normal-play QA.
var failures := PackedStringArray()
var rows: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()
func freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): freeze(child)
func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("VFX_READABILITY_REQUIRES_RENDERER")
		quit(1)
		return
	root.size = Vector2i(640,400)
	root.content_scale_size = Vector2i.ZERO
	var cases: Array[String] = ["shot","projectile","melee_arc","melee_thrust","hit_low","kill"]
	for file in DirAccess.get_files_at("res://game/features/combat_skills/definitions"):
		if file.ends_with(".tres"): cases.append(file)
	if cases.size() < 46: failures.append("Missing supported skill definitions")
	DirAccess.make_dir_recursive_absolute("res://outputs/vfx-readability")
	for light in [false,true]:
		for key in cases:
			var stage := Node2D.new()
			root.add_child(stage)
			var background := Polygon2D.new()
			background.polygon = PackedVector2Array([Vector2.ZERO,Vector2(640,0),Vector2(640,400),Vector2(0,400)])
			background.color = Color("85918f") if light else Color("14232c")
			stage.add_child(background)
			for i in 16:
				var stripe := Polygon2D.new()
				stripe.polygon = PackedVector2Array([Vector2(i*40,0),Vector2(i*40+2,0),Vector2(i*40+2,400),Vector2(i*40,400)])
				stripe.color = Color(0.1,0.15,0.2,0.25)
				stage.add_child(stripe)
			var world := Node2D.new()
			world.scale = Vector2.ONE * 0.65
			world.position = Vector2(220,200)
			stage.add_child(world)
			var player: Node2D = load("res://game/features/player/player.tscn").instantiate()
			world.add_child(player)
			player.get_node("Camera2D").enabled = false
			var targets := Node2D.new()
			world.add_child(targets)
			var victim: Node2D = load("res://game/features/enemies/enemy.tscn").instantiate()
			victim.max_health = 10000 # Fixture only: allows every skill to render against one target.
			targets.add_child(victim)
			victim.position = Vector2(180,0)
			# Moving actor sprites or status bars must not make a missing effect pass the pixel gate.
			for actor in [player,victim]:
				for child in actor.get_children():
					if child is CanvasItem: child.hide()
			freeze(stage)
			await process_frame
			await RenderingServer.frame_post_draw
			var before := root.get_texture().get_image()
			if key.ends_with(".tres"):
				var skill: Resource = load("res://game/features/combat_skills/definitions/"+key)
				var result: Dictionary = skill.effect.activate(player,{&"target_container":targets,&"effect_parent":world,&"target":victim,&"target_point":victim.global_position,&"direction":Vector2.RIGHT,&"damage_enabled":false})
				if not result.get(&"success",false): failures.append(key+" activation")
				if result.get(&"runtime") is TacticalPatternRuntime:
					result.runtime.advance(skill.effect.delay+0.08)
				for effect in get_nodes_in_group(&"combat_skill_electric_effect"):
					if stage.is_ancestor_of(effect): effect._process(0.08)
			elif key == "shot":
				var fx := WeaponShotFX.new()
				world.add_child(fx)
				fx.play(player.global_position,Vector2.RIGHT,Color("02e5e1"))
				fx._process(0.08)
			elif key == "projectile":
				var fx: Node2D = load("res://game/features/weapons/projectile.tscn").instantiate()
				world.add_child(fx)
				fx.launch(Vector2.RIGHT,1)
				fx._physics_process(0.1)
			elif key.begins_with("melee"):
				var fx := WeaponMeleeStrike.new()
				world.add_child(fx)
				fx.execute(Vector2.RIGHT,0,{&"attack_mode":key,&"target_range_px":170.0,&"spread_angle_deg":110.0},[],{})
				fx._process(0.08)
			else:
				var fx := HitFeedbackDirector.new()
				world.add_child(fx)
				fx.configure(player.get_node("Camera2D"),load("res://game/features/hit_feedback/configs/default_hit_feedback.tres"))
				fx._on_actor_damaged(1,0,victim.global_position,{&"lethal":key=="kill"},victim)
				fx._process(0.08)
			freeze(stage)
			await process_frame
			await RenderingServer.frame_post_draw
			var after := root.get_texture().get_image()
			var changed := 0
			var bright := 0
			for y in range(20,380):
				for x in range(20,620):
					var a := after.get_pixel(x,y)
					var b := before.get_pixel(x,y)
					if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.3:
						changed += 1
						if minf(a.r,minf(a.g,a.b)) > 0.72: bright += 1
			rows.append({"effect":key,"bright_floor":light,"changed_pixels":changed,"white_core_pixels":bright})
			if changed < 60 or bright < 8: failures.append("%s light=%s changed=%d white=%d" %[key,light,changed,bright])
			after.save_png("res://outputs/vfx-readability/%s-%s.png" %[key.trim_suffix(".tres"),"light" if light else "dark"])
			stage.free()
			await process_frame
	var file := FileAccess.open("res://outputs/vfx-readability/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"cases":rows,"failures":failures},"  "))
	file.close()
	for error in failures: printerr(error)
	print("VFX_READABILITY_OK cases=%d scale=0.65 contact_age=0.08 dark_light=true" % rows.size() if failures.is_empty() else "VFX_READABILITY_FAILED")
	quit(0 if failures.is_empty() else 1)
