extends SceneTree
## Dispatch/budget/asset contract. Headless passes do NOT attest audible quality.
class Emitter extends Node:
	signal presentation_event(kind: StringName, position: Vector2, context: Dictionary)
class Actor extends Node2D:
	signal damaged(health: float, armor: float, position: Vector2, context: Dictionary)
var failures := PackedStringArray()
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	if not value: failures.append(label)
func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var camera := Camera2D.new()
	stage.add_child(camera)
	var audio := CombatFeedbackAudio.new()
	stage.add_child(audio)
	var profile: CombatAudioProfile = load("res://game/features/hit_feedback/configs/default_combat_audio.tres")
	check(profile.is_valid(), "valid default")
	for kind in [&"shot", &"melee", &"cast", &"hit", &"armor", &"lethal"]:
		var stream := profile.stream_for(kind)
		check(stream != null and stream.get_length() > 0 and stream.get_length() < 5, "short imported stream " + kind)
	check(audio.configure(profile, camera), "configured")
	check(audio.play_event(&"melee", Vector2.ZERO), "trigger accepted")
	check(audio.play_event(&"hit", Vector2.ZERO), "same-frame contact not masked by trigger")
	for index in 1000: audio.play_event(&"hit", Vector2.ZERO)
	check(audio.accepted == 2 and audio.dropped == 1000 and audio.voices.size() == 8, "burst bounded")
	audio.set_enabled(false)
	check(not audio.play_event(&"cast", Vector2.ZERO), "muted")
	check(profile.enabled, "mute isolated from source")
	audio.set_enabled(true)
	check(not audio.play_event(&"cast", Vector2(901, 0)), "distant culled")
	check(not audio.play_event(&"cast", Vector2(INF, 0)), "nonfinite culled")
	var invalid := profile.duplicate(true)
	invalid.maximum_voices = 9
	check(not audio.configure(invalid, camera), "invalid rejected without losing old pool")
	check(audio.configure(profile, camera) and audio.get_child_count() == 8 and audio.accepted == 0, "reconfigure no pool leak")
	var director := HitFeedbackDirector.new()
	stage.add_child(director)
	check(director.configure(camera, load("res://game/features/hit_feedback/configs/default_hit_feedback.tres")), "director configured")
	var emitter := Emitter.new()
	stage.add_child(emitter)
	check(director.register_attack_source(emitter) and director.register_attack_source(emitter), "idempotent future emitter")
	emitter.presentation_event.emit(&"cast", Vector2.ZERO, {})
	check(director.audio_feedback.accepted == 1, "single cast delivery")
	var actor := Actor.new()
	stage.add_child(actor)
	check(director.register_actor(actor), "actor registered")
	actor.damaged.emit(0, 0, Vector2.ZERO, {})
	check(director.total_hits == 0 and director.audio_feedback.accepted == 1, "zero damage silent")
	actor.damaged.emit(0, 10, Vector2.ZERO, {})
	check(director.audio_feedback.events.get(&"armor", 0) == 1, "actual armor contact")
	# The audio budget uses monotonic wall time, not simulated frame delta.
	# Headless startup can advance a SceneTreeTimer before that budget expires.
	var after_budget := Time.get_ticks_usec() + ceili(maxf(profile.global_interval, profile.event_interval) * 1000000.0) + 1000
	while Time.get_ticks_usec() < after_budget:
		await process_frame
	actor.damaged.emit(20, 0, Vector2.ZERO, {&"lethal":true})
	check(director.audio_feedback.events.get(&"lethal", 0) == 1 and director.total_lethal_hits == 1, "actual lethal contact")
	stage.queue_free()
	for frame in 4: await process_frame
	if failures.is_empty():
		print("COMBAT_AUDIO_OK six_streams same_frame_contact bounded_pool mute culling actual_damage teardown")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)
