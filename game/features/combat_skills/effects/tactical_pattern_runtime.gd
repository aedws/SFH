class_name TacticalPatternRuntime
extends Node2D

var actor: Node2D
var targets: Node
var spec: Resource
var enabled := true
var direction := Vector2.RIGHT
var displayed_direction := Vector2.RIGHT
var elapsed := 0.0
var emitted := 0
var hits := 0
var selected: Node2D
var flash := 0.0
var source_id: StringName
var beam_points := PackedVector2Array()

func configure(player: Node2D, definition: Resource, context: Dictionary) -> void:
	actor = player
	targets = context.target_container
	spec = definition.duplicate(true)
	var modifiers: Dictionary = context.get(&"mechanic_override", {})
	spec.damage *= float(modifiers.get(&"damage_multiplier", 1.0))
	spec.radius *= float(modifiers.get(&"radius_multiplier", 1.0))
	spec.inner_radius *= float(modifiers.get(&"radius_multiplier", 1.0))
	selected = context.get(&"target") as Node2D
	direction = context.get(&"direction", Vector2.RIGHT)
	displayed_direction = direction
	global_position = context.get(&"target_point", actor.global_position) if spec.anchor_on_target else actor.global_position
	enabled = bool(context.get(&"damage_enabled", true))
	source_id = StringName("pattern_%d" % get_instance_id())
	if spec.defense_add != 0 or spec.speed_multiplier != 1:
		actor.call(&"set_runtime_modifier_source", source_id, {
			&"defense": {&"add": spec.defense_add, &"multiply": 1.0},
			&"movement_speed": {&"add": 0.0, &"multiply": spec.speed_multiplier}})
	add_to_group(&"combat_skill_runtime_effect")
	advance(0)

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not is_instance_valid(actor) or not is_instance_valid(targets):
		queue_free()
		return
	elapsed += maxf(0, delta)
	flash = maxf(0, flash - delta)
	if spec.follow_player: global_position = actor.global_position
	# Exact scheduled pulse count, including low frame-rate catch-up; never tick beyond lifetime.
	while emitted < spec.pulses and elapsed + 0.00001 >= spec.delay + emitted * spec.interval:
		displayed_direction = direction
		_pulse()
		emitted += 1
		direction = direction.rotated(deg_to_rad(spec.rotation_per_pulse))
	var end_time: float = spec.delay + (spec.pulses - 1) * spec.interval + 0.24
	if spec.defense_add != 0 or spec.speed_multiplier != 1: end_time = maxf(end_time, spec.buff_duration)
	if elapsed >= spec.buff_duration and source_id != &"":
		actor.call(&"remove_runtime_modifier_source", source_id)
		source_id = &""
	if elapsed >= end_time: queue_free()
	queue_redraw()

func _pulse() -> void:
	flash = 0.24
	beam_points.clear()
	var candidates: Array[Node2D] = []
	for node in targets.get_children():
		if node is Node2D and not node.is_queued_for_deletion() and node.has_method(&"take_damage"):
			candidates.append(node)
	candidates.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	var used := 0
	var chain_origin := global_position
	for target in candidates:
		if used >= spec.maximum_targets: break
		if spec.shape == "single" and target != selected: continue
		if spec.shape == "chain":
			if chain_origin.distance_to(target.global_position) > (spec.radius if used == 0 else spec.chain_range): continue
		elif not _contains(target.global_position): continue
		if not _visible_from(chain_origin if spec.shape == "chain" else global_position, target.global_position): continue
		var amount: float = spec.damage
		if enabled:
			if spec.consume_status_id != &"" and target.has_method(&"consume_status") and target.call(&"consume_status", spec.consume_status_id, 1):
				amount *= spec.combo_multiplier
			target.call(&"take_damage", amount, {&"source_kind": &"tactical_skill", &"source_position": global_position,
				&"impact_direction": global_position.direction_to(target.global_position), &"impact_strength": 0.7,
				&"impact_color":spec.color, &"impact_radius_multiplier":1.15, &"camera_trauma_multiplier":0.65 if spec.pulses > 1 else 1.0})
			if spec.status_id != &"" and target.has_method(&"apply_status") and not target.is_queued_for_deletion():
				target.call(&"apply_status", spec.status_id, spec.status_duration, 1)
		beam_points.append(to_local(target.global_position))
		chain_origin = target.global_position
		used += 1
		hits += 1

func _contains(point: Vector2) -> bool:
	var offset := point - global_position
	var distance := offset.length()
	match spec.shape:
		"self": return false
		"ring": return distance <= spec.radius and distance >= spec.inner_radius
		"cone": return distance <= spec.radius and absf(direction.angle_to(offset)) <= deg_to_rad(spec.angle_degrees * 0.5)
		"line":
			var along := offset.dot(direction)
			return along >= 0 and along <= spec.radius and absf(offset.cross(direction)) <= spec.width * 0.5
	return distance <= spec.radius

func _visible_from(start: Vector2, end: Vector2) -> bool:
	if start.is_equal_approx(end): return true
	var query := PhysicsRayQueryParameters2D.create(start, end, 16)
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _exit_tree() -> void:
	if is_instance_valid(actor) and source_id != &"": actor.call(&"remove_runtime_modifier_source", source_id)

func _draw() -> void:
	if spec == null: return
	var tint: Color = spec.color
	var pulse := clampf(flash / 0.24, 0, 1)
	tint.a = 0.24 + pulse * 0.65
	var core := Color(0.85, 1, 1, pulse * 0.9)
	# Boundaries use the same live radius/width/direction as the damage geometry.
	match spec.shape:
		"line":
			var end: Vector2 = displayed_direction * spec.radius
			var side: Vector2 = displayed_direction.orthogonal() * spec.width * 0.5
			draw_colored_polygon(PackedVector2Array([-side, side, end+side, end-side]), Color(tint, 0.035*pulse))
			draw_polyline(PackedVector2Array([-side, side, end+side, end-side, -side]), tint, 1.5)
			draw_line(Vector2.ZERO, end, tint, 5.0 + pulse*3.0)
			draw_line(Vector2.ZERO, end, core, 1.5)
		"cone":
			var first := displayed_direction.angle() - deg_to_rad(spec.angle_degrees * 0.5)
			var last := displayed_direction.angle() + deg_to_rad(spec.angle_degrees * 0.5)
			draw_arc(Vector2.ZERO, spec.radius, first, last, 24, tint, 2.5)
			draw_line(Vector2.ZERO, Vector2.from_angle(first)*spec.radius, tint, 1.5)
			draw_line(Vector2.ZERO, Vector2.from_angle(last)*spec.radius, tint, 1.5)
			if pulse > 0: draw_arc(Vector2.ZERO, spec.radius*(1.0-0.18*pulse), first, last, 24, core, 2)
		"chain", "single":
			var start := Vector2.ZERO
			for point in beam_points:
				draw_line(start, point, tint, 5)
				draw_line(start, point, core, 1.5)
				draw_arc(point, 8.0+10.0*(1.0-pulse), 0, TAU, 12, tint, 2)
				if spec.shape == "chain": start = point
		"self": draw_arc(Vector2.ZERO, 30, 0, TAU, 24, tint, 3)
		_:
			draw_arc(Vector2.ZERO, spec.radius, 0, TAU, 48, tint, 2)
			if spec.shape == "ring": draw_arc(Vector2.ZERO, spec.inner_radius, 0, TAU, 32, tint, 2)
			if pulse > 0:
				var inner: float = spec.inner_radius if spec.shape == "ring" else spec.radius * 0.8
				draw_arc(Vector2.ZERO, lerpf(inner, spec.radius, 1.0-pulse), 0, TAU, 48, core, 1.5)
