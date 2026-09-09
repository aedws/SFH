class_name CombatAudioProfile
extends Resource
## Presentation only. Stream replacement never changes combat or gameplay RNG.
@export var enabled := true
@export var shot: AudioStream
@export var melee: AudioStream
@export var cast: AudioStream
@export var hit: AudioStream
@export var armor: AudioStream
@export var lethal: AudioStream
@export_range(-60, -20, 1) var volume_db := -24.0
@export_range(1, 8, 1) var maximum_voices := 8
@export var maximum_distance := 900.0
@export var event_interval := 0.07
@export var global_interval := 0.025

func is_valid() -> bool:
	return maximum_voices in range(1,9) and is_finite(volume_db) and volume_db <= -20 and volume_db >= -60 and is_finite(maximum_distance) and maximum_distance > 0 and is_finite(event_interval) and event_interval >= 0.01 and is_finite(global_interval) and global_interval >= 0.01

func stream_for(kind: StringName) -> AudioStream:
	match kind:
		&"shot": return shot
		&"melee": return melee
		&"cast": return cast
		&"armor": return armor
		&"lethal": return lethal
	return hit
