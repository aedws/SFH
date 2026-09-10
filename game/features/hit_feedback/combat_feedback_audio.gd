class_name CombatFeedbackAudio
extends Node
## Bounded pool + per-event/global budgets. No damage ownership, no timers per hit.
var profile: CombatAudioProfile
var listener: Node2D
var voices: Array[AudioStreamPlayer2D] = []
var last_event := {}
var last_lane := {}
var accepted := 0
var dropped := 0
var events := {}

func configure(new_profile: CombatAudioProfile, new_listener: Node2D) -> bool:
	if new_profile == null or not new_profile.is_valid() or not is_instance_valid(new_listener): return false
	for voice in voices: voice.free()
	voices.clear()
	profile = new_profile.duplicate(true)
	listener = new_listener
	last_event.clear()
	last_lane.clear()
	accepted = 0
	dropped = 0
	events.clear()
	for index in profile.maximum_voices:
		var voice := AudioStreamPlayer2D.new()
		voice.max_distance = profile.maximum_distance
		voice.volume_db = profile.volume_db
		add_child(voice)
		voices.append(voice)
	return true

func play_event(kind: StringName, position: Vector2) -> bool:
	if profile == null or not profile.enabled or not is_instance_valid(listener): return false
	if not position.is_finite() or position.distance_to(listener.global_position) > profile.maximum_distance: return false
	var stream := profile.stream_for(kind)
	if stream == null: return false
	var now := Time.get_ticks_usec() / 1000000.0
	# A melee/instant skill can hit in the same frame as its trigger. Its contact
	# must not be silenced by the trigger budget; both lanes still share 8 voices.
	var lane := &"trigger" if kind in [&"shot", &"melee", &"cast"] else &"contact"
	if now - float(last_lane.get(lane, -100.0)) < profile.global_interval or now - float(last_event.get(kind, -100.0)) < profile.event_interval:
		dropped += 1
		return false
	for voice in voices:
		if voice.playing: continue
		voice.stream = stream
		voice.global_position = position
		# Deterministic presentation variation, isolated from loot/spawn randomness.
		voice.pitch_scale = 0.97 + float(accepted % 4) * 0.02
		# Headless CI has no listener/audio device: validate dispatch without queuing
		# unconsumed Dummy-driver Vorbis playbacks at process shutdown.
		if DisplayServer.get_name() != "headless": voice.play()
		last_event[kind] = now
		last_lane[lane] = now
		accepted += 1
		events[kind] = int(events.get(kind, 0)) + 1
		return true
	dropped += 1
	return false

func set_enabled(value: bool) -> void:
	if profile != null: profile.enabled = value
	if not value:
		for voice in voices: voice.stop()

func get_snapshot() -> Dictionary:
	return {&"voices":voices.size(), &"playing":voices.filter(func(v): return v.playing).size(),
		&"accepted":accepted, &"dropped":dropped, &"events":events.duplicate(), &"enabled":profile != null and profile.enabled,
		&"audible_backend":DisplayServer.get_name() != "headless"}

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
