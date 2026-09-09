extends SceneTree
## Isolated GPU + audio mixer fixture. Not a normal 10-minute play acceptance.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("TACTICAL_FEEDBACK_REQUIRES_RENDERER")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i.ZERO
	root.title = "SFH isolated FX verification"
	var stage := Node2D.new()
	root.add_child(stage)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,800),Vector2(0,800)])
	background.color = Color("101c24")
	stage.add_child(background)
	var shapes := ["line", "cone", "chain", "single", "circle", "ring", "self"]
	for index in shapes.size():
		var label := Label.new()
		label.text = shapes[index].to_upper() + " / actual shape, preview scale"
		label.position = Vector2(20 + index % 4 * 320, 30 + index / 4 * 400)
		stage.add_child(label)
		var effect := TacticalPatternRuntime.new()
		effect.position = Vector2(55 + index % 4 * 320, 230 + index / 4 * 400)
		if shapes[index] in ["circle", "ring", "self"]: effect.position.x += 105
		effect.scale = Vector2.ONE * 0.32
		effect.spec = TacticalPatternEffect.new()
		effect.spec.shape = shapes[index]
		effect.spec.radius = 350
		effect.spec.width = 120
		effect.spec.inner_radius = 180
		effect.spec.angle_degrees = 70
		effect.beam_points = PackedVector2Array([Vector2(120,-60),Vector2(240,40),Vector2(340,-30)])
		if shapes[index] == "single": effect.beam_points.resize(1)
		effect.flash = 0.18
		stage.add_child(effect)
		effect.set_process(false)
	var camera := Camera2D.new()
	camera.enabled = false
	camera.position = Vector2(640,400)
	stage.add_child(camera)
	var director := HitFeedbackDirector.new()
	stage.add_child(director)
	director.configure(camera, load("res://game/features/hit_feedback/configs/default_hit_feedback.tres"))
	director._on_actor_damaged(20,0,Vector2(1100,630),{&"lethal":true},stage)
	director._process(0.025)
	director.set_process(false)
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 0.5
	AudioServer.add_bus_effect(0, capture)
	var effect_index := AudioServer.get_bus_effect_count(0)-1
	var audio := CombatFeedbackAudio.new()
	stage.add_child(audio)
	audio.configure(load("res://game/features/hit_feedback/configs/default_combat_audio.tres"),camera)
	var audible := 0
	for kind in [&"shot", &"melee", &"cast", &"hit", &"armor", &"lethal"]:
		await create_timer(0.15).timeout
		capture.clear_buffer()
		audio.play_event(kind, camera.position)
		await create_timer(0.2).timeout
		var frames := capture.get_buffer(capture.get_frames_available())
		var peak := 0.0
		for sample in frames: peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if peak > 0.00001: audible += 1
		print("AUDIO_MIX kind=%s frames=%d peak=%.6f" % [kind,frames.size(),peak])
		audio.set_enabled(false)
		audio.set_enabled(true)
	AudioServer.remove_bus_effect(0, effect_index)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://outputs/tactical-feedback")
	var result := root.get_texture().get_image().save_png("res://outputs/tactical-feedback/overview.png")
	stage.queue_free()
	for frame in 5: await process_frame
	print("TACTICAL_FEEDBACK_RENDER_OK mixed_streams=%d image=%d" % [audible,result])
	quit(0 if audible == 6 and result == OK else 1)
