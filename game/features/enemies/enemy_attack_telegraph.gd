class_name EnemyAttackTelegraph
extends Node2D
## One locked strike per telegraph. Caller owns pursuit and recovery cadence.
var policy: EnemyAttackPolicy
var active := false
var elapsed := 0.0
var origin := Vector2.ZERO
var direction := Vector2.RIGHT
var victim: Node2D

func configure(value: EnemyAttackPolicy) -> bool:
	if active or value == null or not value.is_valid():
		return false
	policy = value.duplicate(true)
	return true

func cancel() -> void:
	var was_active := active
	active = false
	victim = null
	elapsed = 0.0
	if was_active: queue_redraw()

func advance(delta: float, source: Vector2, target: Node2D, damage: float, wall_mask: int = 16) -> bool:
	if not is_finite(delta) or delta < 0.0 or policy == null:
		return false
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.has_method(&"take_damage"):
		cancel()
		return false
	if not active:
		if source.distance_to(target.global_position) > policy.reach or _blocked(source, target.global_position, wall_mask):
			return false
		origin = source
		direction = source.direction_to(target.global_position)
		if direction.is_zero_approx(): direction = Vector2.RIGHT
		victim = target
		active = true
		elapsed = 0.0
		queue_redraw()
		# Never consume the acquisition frame: the warning must exist before damage.
		return false
	if target != victim or source.distance_to(origin) > policy.displacement_tolerance:
		cancel()
		return false
	elapsed += delta
	queue_redraw()
	if elapsed < policy.windup_seconds:
		return false
	if policy.contains(victim.global_position - origin, direction) and not _blocked(origin, victim.global_position, wall_mask):
		victim.call(&"take_damage", damage, {
			&"source_kind": &"enemy_contact", &"source_position": origin,
			&"impact_direction": direction, &"impact_strength": 0.65,
		})
	cancel()
	return true # Misses also consume the strike/recovery; no instant reacquisition.

func _blocked(start: Vector2, end: Vector2, mask: int) -> bool:
	if mask == 0 or start.is_equal_approx(end): return false
	var query := PhysicsRayQueryParameters2D.create(start, end, mask)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func get_snapshot() -> Dictionary:
	return {&"active": active, &"elapsed": elapsed, &"origin": origin, &"direction": direction,
		&"windup_seconds": policy.windup_seconds if policy != null else 0.0,
		&"reach": policy.reach if policy != null else 0.0, &"half_width": policy.half_width if policy != null else 0.0}

func _draw() -> void:
	if not active or policy == null: return
	var normal := direction.orthogonal() * policy.half_width
	var tip := origin + direction * policy.reach
	var corners := PackedVector2Array([to_local(origin-normal), to_local(tip-normal), to_local(tip+normal), to_local(origin+normal)])
	draw_colored_polygon(corners, Color(policy.warning_color, 0.18))
	var outline := corners.duplicate()
	outline.append(corners[0])
	draw_polyline(outline, policy.warning_color, 2.0)
	var progress := clampf(elapsed / policy.windup_seconds, 0.0, 1.0)
	draw_line(to_local(origin), to_local(origin + direction * policy.reach * progress), policy.warning_color, 3.0)
