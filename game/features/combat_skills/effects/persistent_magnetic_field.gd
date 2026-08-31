class_name PersistentMagneticField
extends Node2D

## 플레이어를 따라다니며 고정 주기로 범위 피해를 누적하는 런타임 효과입니다.

const ELECTRIC_EFFECT_SCRIPT := preload(
	"res://game/features/combat_skills/effects/electric_arc_effect.gd"
)

var player: Node2D
var target_container: Node
var effect_parent: Node2D
var electric_profile: Resource
var radius: float = 230.0
var tick_damage: float = 6.0
var duration_seconds: float = 5.0
var tick_interval_seconds: float = 0.5
var damage_enabled: bool = true
var elapsed_seconds: float = 0.0
var tick_accumulator: float = 0.0
var tick_count: int = 0
var total_hits: int = 0
var applied_status_id: StringName = &"shock"
var status_duration: float = 3.0


func configure(
	new_player: Node2D,
	new_target_container: Node,
	new_effect_parent: Node2D,
	new_radius: float,
	new_tick_damage: float,
	new_duration_seconds: float,
	new_tick_interval_seconds: float,
	new_damage_enabled: bool,
	new_electric_profile: Resource,
	new_applied_status_id: StringName = &"shock",
	new_status_duration: float = 3.0
) -> bool:
	if (
		not is_instance_valid(new_player)
		or not is_instance_valid(new_target_container)
		or new_radius <= 0.0
		or new_duration_seconds <= 0.0
		or new_tick_interval_seconds <= 0.0
	):
		return false
	player = new_player
	target_container = new_target_container
	effect_parent = new_effect_parent
	radius = new_radius
	tick_damage = maxf(0.0, new_tick_damage)
	duration_seconds = new_duration_seconds
	tick_interval_seconds = new_tick_interval_seconds
	damage_enabled = new_damage_enabled
	electric_profile = new_electric_profile
	applied_status_id = new_applied_status_id
	status_duration = maxf(0.0, new_status_duration)
	add_to_group(&"combat_skill_runtime_effect")
	global_position = player.global_position
	_spawn_visual()
	_apply_damage_tick()
	return true


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position
	var safe_delta := maxf(0.0, delta)
	elapsed_seconds += safe_delta
	tick_accumulator += safe_delta
	while tick_accumulator >= tick_interval_seconds and elapsed_seconds < duration_seconds:
		tick_accumulator -= tick_interval_seconds
		_apply_damage_tick()
	if elapsed_seconds >= duration_seconds:
		queue_free()


func get_snapshot() -> Dictionary:
	return {
		&"radius": radius,
		&"tick_damage": tick_damage if damage_enabled else 0.0,
		&"duration_seconds": duration_seconds,
		&"tick_interval_seconds": tick_interval_seconds,
		&"tick_count": tick_count,
		&"total_hits": total_hits,
		&"remaining_seconds": maxf(0.0, duration_seconds - elapsed_seconds),
		&"applied_status_id": applied_status_id,
	}


func _apply_damage_tick() -> void:
	if not is_instance_valid(target_container) or not is_instance_valid(player):
		return
	tick_count += 1
	for target_index in target_container.get_child_count():
		var target := target_container.get_child(target_index)
		if (
			target is Node2D
			and target.has_method(&"take_damage")
			and player.global_position.distance_squared_to((target as Node2D).global_position)
			<= radius * radius
		):
			if damage_enabled:
				target.call(&"take_damage", tick_damage, {
					&"source_kind": &"magnetic_field",
					&"source_position": player.global_position,
					&"impact_direction": player.global_position.direction_to(
						(target as Node2D).global_position
					),
					&"impact_strength": clampf(tick_damage / 8.0, 0.3, 0.8),
				})
			if applied_status_id != &"" and target.has_method(&"apply_status"):
				target.call(&"apply_status", applied_status_id, status_duration, 1)
			total_hits += 1


func _spawn_visual() -> void:
	if not is_instance_valid(effect_parent) or electric_profile == null:
		return
	var visual_profile := electric_profile.duplicate(true)
	visual_profile.set("lifetime_seconds", duration_seconds)
	var electric := ELECTRIC_EFFECT_SCRIPT.new()
	effect_parent.add_child(electric)
	electric.global_position = player.global_position
	if not electric.configure_radial(radius, visual_profile, player):
		electric.queue_free()
