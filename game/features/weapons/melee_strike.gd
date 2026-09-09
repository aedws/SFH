class_name WeaponMeleeStrike
extends Node2D
## One instantaneous swing, one hit per target. Short-lived visual never reapplies damage.
signal hit_confirmed(target: Node, world_position: Vector2, context: Dictionary)
const Geometry = preload("res://game/features/weapons/melee_strike_policy.gd")
const Distance = preload("res://game/features/weapon_balance/weapon_distance_policy.gd")
var reach := 100.0
var arc := 90.0
var mode: StringName = &"melee_arc"
var color := Color("02e5e1")
var age := 0.0
var duration := 0.18
var hit_count := 0

func execute(direction: Vector2, damage: float, snapshot: Dictionary, candidates: Array, context: Dictionary) -> void:
	rotation = direction.angle()
	reach = float(snapshot.get(&"target_range_px", 100.0))
	arc = float(snapshot.get(&"spread_angle_deg", 90.0))
	mode = StringName(snapshot.get(&"attack_mode", &"melee_arc"))
	color = snapshot.get(&"projectile_color", color)
	duration = clampf(float(snapshot.get(&"projectile_lifetime_sec", 0.18)), 0.08, 0.3)
	var points := Distance.parse(String(snapshot.get(&"distance_damage_curve", Distance.NEUTRAL)))
	var ordered: Array[Node2D] = []
	var seen := {}
	for candidate in candidates:
		if not is_instance_valid(candidate) or not candidate is Node2D or candidate.is_queued_for_deletion(): continue
		if not candidate.has_method(&"take_damage") or seen.has(candidate.get_instance_id()): continue
		seen[candidate.get_instance_id()] = true
		if Geometry.contains(candidate.global_position - global_position, direction, reach, arc, mode): ordered.append(candidate)
	ordered.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	for target in ordered:
		if not is_instance_valid(target) or target.is_queued_for_deletion(): continue
		if hit_count >= int(snapshot.get(&"pierce_count", 0)) + 1: break
		# Same world-obstacle layer as projectiles, but no enemy layer: enemies do not block a sweep.
		var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 16)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var distance_px := global_position.distance_to(target.global_position)
		var multiplier := Distance.multiplier(points, distance_px, reach)
		var applied := damage * multiplier * pow(float(snapshot.get(&"pierce_damage_retention", 1.0)), hit_count)
		var hit := context.duplicate(true)
		hit.merge({&"source_kind": &"weapon_melee", &"source_position": global_position,
			&"impact_direction": direction, &"impact_strength": clampf(applied / 8.0, 0.6, 1.8),
			&"distance_px": distance_px, &"distance_multiplier": multiplier, &"applied_damage": applied}, true)
		target.call(&"take_damage", applied, hit)
		hit_count += 1
		hit_confirmed.emit(target, target.global_position, hit)
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= duration: queue_free()
	queue_redraw()

func _draw() -> void:
	var tint := color
	tint.a = maxf(0.0, 1.0 - age / duration)
	if mode == &"melee_thrust":
		draw_line(Vector2(12, 0), Vector2(reach, 0), tint, 5.0)
		draw_polyline(PackedVector2Array([Vector2(reach-18, -9), Vector2(reach, 0), Vector2(reach-18, 9)]), tint, 3.0)
	else:
		var half_arc := deg_to_rad(arc * 0.5)
		draw_arc(Vector2.ZERO, reach * 0.9, -half_arc, half_arc, 24, tint, 5.0)
		tint.a *= 0.3
		draw_arc(Vector2.ZERO, reach * 0.68, -half_arc, half_arc, 24, tint, 10.0)
