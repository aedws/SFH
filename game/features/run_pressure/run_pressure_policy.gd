class_name RunPressurePolicy
extends Resource
## Approved timing; enemy strength remains a replaceable provisional balance profile.

@export var recommended_start_seconds := 900.0
@export var corruption_seconds := 1200.0
@export var collapse_seconds := 1800.0
@export var warning_seconds := 60.0
@export var enemy_damage_multiplier := 1.35
@export var enemy_speed_multiplier := 1.15
@export var hunter_speed_multiplier := 1.08
@export var hunter_attack_multiplier := 1.12
@export var hunter_health := 120.0
@export var hunter_armor := 20.0
@export var hunter_spawn_distance := 640.0
@export var spawn_retry_seconds := 1.0


func is_valid() -> bool:
	for value in [recommended_start_seconds, corruption_seconds, collapse_seconds,
		warning_seconds, enemy_damage_multiplier, enemy_speed_multiplier,
		hunter_speed_multiplier, hunter_attack_multiplier, hunter_health,
		hunter_spawn_distance, spawn_retry_seconds]:
		if not is_finite(value) or value <= 0.0: return false
	return (recommended_start_seconds < corruption_seconds
		and corruption_seconds < collapse_seconds
		and warning_seconds < collapse_seconds - corruption_seconds
		and is_finite(hunter_armor) and hunter_armor >= 0.0
		and enemy_damage_multiplier >= 1.0 and enemy_speed_multiplier >= 1.0)


func snapshot(elapsed: float) -> Dictionary:
	var remaining := maxf(0.0, collapse_seconds - elapsed)
	return {
		&"elapsed_seconds": elapsed, &"remaining_seconds": remaining,
		&"collapse_seconds": collapse_seconds,
		&"corruption_seconds": corruption_seconds,
		&"corrupted": elapsed >= corruption_seconds,
		&"urgent": remaining <= warning_seconds,
		&"recommended": elapsed >= recommended_start_seconds and elapsed < corruption_seconds,
		&"recommendation": "권장 생환 %d~%d분" % [int(recommended_start_seconds / 60.0), int(corruption_seconds / 60.0)],
		&"enemy_damage_multiplier": enemy_damage_multiplier if elapsed >= corruption_seconds else 1.0,
		&"enemy_speed_multiplier": enemy_speed_multiplier if elapsed >= corruption_seconds else 1.0,
	}
