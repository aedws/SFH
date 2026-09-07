class_name HitFeedbackDirector
extends Node2D

## damaged Signal을 시각 충격과 카메라 반응으로 변환하며 피해 계산에는 관여하지 않습니다.

var camera: Camera2D
var profile
var impacts: Array[Dictionary] = []
var registered_actor_ids: Dictionary = {}
var trauma: float = 0.0
var elapsed: float = 0.0
var total_hits: int = 0
var total_player_hits: int = 0
var total_lethal_hits: int = 0
var peak_active_impacts: int = 0
var directional_kick := Vector2.ZERO


func configure(new_camera: Camera2D, new_profile: Resource) -> bool:
	if (
		not is_instance_valid(new_camera)
		or new_profile == null
		or not new_profile.has_method(&"is_valid")
		or not new_profile.call(&"is_valid")
	):
		return false
	camera = new_camera
	profile = new_profile
	z_index = 70
	set_process(not impacts.is_empty() or trauma > 0.0)
	return true


func register_actor(actor: Node) -> bool:
	if (
		profile == null
		or not is_instance_valid(actor)
		or not actor.has_signal(&"damaged")
		or registered_actor_ids.has(actor.get_instance_id())
	):
		return false
	actor.connect(&"damaged", Callable(self, &"_on_actor_damaged").bind(actor))
	registered_actor_ids[actor.get_instance_id()] = true
	actor.tree_exited.connect(_on_actor_tree_exited.bind(actor.get_instance_id()), CONNECT_ONE_SHOT)
	return true


func get_snapshot() -> Dictionary:
	return {
		&"configured": profile != null and is_instance_valid(camera),
		&"registered_actor_count": registered_actor_ids.size(),
		&"active_impacts": impacts.size(),
		&"peak_active_impacts": peak_active_impacts,
		&"maximum_active_impacts": int(profile.maximum_active_impacts) if profile != null else 0,
		&"total_hits": total_hits,
		&"total_player_hits": total_player_hits,
		&"total_lethal_hits": total_lethal_hits,
		&"trauma": trauma,
		&"directional_kick_pixels": directional_kick.length(),
		&"processing": is_processing(),
	}


func _process(delta: float) -> void:
	if profile == null:
		return
	var safe_delta: float = maxf(0.0, delta)
	elapsed += safe_delta
	for index in range(impacts.size() - 1, -1, -1):
		impacts[index][&"remaining"] = maxf(
			0.0,
			float(impacts[index][&"remaining"]) - safe_delta
		)
		if float(impacts[index][&"remaining"]) <= 0.0:
			impacts.remove_at(index)
	trauma = maxf(0.0, trauma - float(profile.camera_decay_per_second) * safe_delta)
	_update_camera_offset()
	directional_kick *= exp(-float(profile.directional_kick_decay) * safe_delta)
	queue_redraw()
	if impacts.is_empty() and trauma <= 0.001 and directional_kick.length() < 0.02:
		directional_kick = Vector2.ZERO
		if is_instance_valid(camera): camera.offset = Vector2.ZERO
		set_process(false)


func _draw() -> void:
	if profile == null:
		return
	for impact in impacts:
		var lifetime: float = maxf(0.001, float(impact[&"lifetime"]))
		var ratio: float = 1.0 - float(impact[&"remaining"]) / lifetime
		var intensity: float = float(impact[&"intensity"])
		var radius: float = (
			float(profile.impact_radius) * intensity
			* float(impact.get(&"radius_multiplier", 1.0)) * (0.35 + ratio * 0.85)
		)
		var color: Color = impact[&"color"]
		color.a *= 1.0 - ratio
		var position: Vector2 = impact[&"position"]
		draw_arc(position, radius, 0.0, TAU, 20, color, 2.0)
		# Crisp contact flash, then a distinct expanding kill ring; no global hit-stop.
		if ratio < 0.28:
			draw_circle(position, 3.5 + intensity * 2.0, Color(1.0, 1.0, 1.0, 1.0 - ratio / 0.28))
		if bool(impact.get(&"lethal", false)):
			draw_arc(position, radius * 1.3, 0.0, TAU, 20, color, 3.0 * (1.0 - ratio))
		if bool(impact.get(&"electric_area_primary", false)):
			_draw_electric_area(
				position,
				float(impact.get(&"area_radius", radius)),
				ratio,
				color
			)
		var base_direction: Vector2 = impact[&"direction"]
		var ray_count := maxi(3, roundi(
			float(profile.impact_ray_count) * float(impact.get(&"ray_multiplier", 1.0))
		))
		for ray_index in ray_count:
			var direction: Vector2 = base_direction.rotated(
				TAU * float(ray_index) / float(ray_count)
			)
			var inner: Vector2 = position + direction * radius * 0.28
			var outer: Vector2 = position + direction * radius * (0.72 + 0.2 * (ray_index % 2))
			draw_line(inner, outer, color, 1.5)


func _on_actor_damaged(
	health_damage: float,
	armor_damage: float,
	world_position: Vector2,
	context: Dictionary,
	actor: Node
) -> void:
	if profile == null:
		return
	var total_damage: float = maxf(0.0, health_damage + armor_damage)
	if total_damage <= 0.0:
		return
	var is_player: bool = actor.is_in_group(&"player")
	var lethal: bool = bool(context.get(&"lethal", false))
	set_process(true)
	var intensity: float = clampf(total_damage / float(profile.reference_damage), 0.35, 1.6)
	var direction: Vector2 = context.get(&"impact_direction", Vector2.RIGHT)
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var color: Color = _impact_color(is_player, armor_damage, health_damage, context)
	if impacts.size() >= int(profile.maximum_active_impacts):
		impacts.pop_front()
	impacts.append({
		&"position": world_position,
		&"direction": direction.normalized(),
		&"remaining": float(profile.impact_lifetime_seconds),
		&"lifetime": float(profile.impact_lifetime_seconds),
		&"intensity": intensity,
		&"lethal": lethal,
			&"color": color,
			&"radius_multiplier": float(context.get(&"impact_radius_multiplier", 1.0)),
			&"ray_multiplier": float(context.get(&"impact_ray_multiplier", 1.0)),
			&"electric_area_primary": (
				StringName(context.get(&"source_kind", &"")) == &"weapon_innate_electric_area"
				and bool(context.get(&"area_primary_target", false))
			),
			&"area_radius": float(context.get(&"area_radius", 0.0)),
		})
	total_hits += 1
	if is_player:
		total_player_hits += 1
	if lethal:
		total_lethal_hits += 1
	trauma = clampf(
		trauma
		+ float(profile.player_hit_trauma if is_player else profile.enemy_hit_trauma)
			* intensity * float(context.get(&"camera_trauma_multiplier", 1.0))
		+ float(profile.lethal_bonus_trauma if lethal else 0.0),
		0.0,
		1.0
	)
	peak_active_impacts = maxi(peak_active_impacts, impacts.size())
	var kick := direction.normalized() * float(profile.directional_kick_pixels) * (1.8 if lethal else 1.0) * maxf(0.0, float(context.get(&"camera_trauma_multiplier", 1.0)))
	if kick.length_squared() > directional_kick.length_squared(): directional_kick = kick
	queue_redraw()


func _draw_electric_area(
	position: Vector2, area_radius: float, lifetime_ratio: float, source_color: Color
) -> void:
	var pulse_radius := maxf(8.0, area_radius) * lerpf(0.72, 1.0, lifetime_ratio)
	var electric_color := source_color
	electric_color.a *= 0.72 * (1.0 - lifetime_ratio)
	draw_arc(position, pulse_radius, 0.0, TAU, 32, electric_color, 2.5)
	for arc_index in range(10):
		var direction := Vector2.from_angle(TAU * float(arc_index) / 10.0)
		var tangent := direction.orthogonal()
		var start := position + direction * pulse_radius * 0.12
		var middle := (
			position + direction * pulse_radius * 0.56
			+ tangent * (7.0 if arc_index % 2 == 0 else -7.0)
		)
		var end := position + direction * pulse_radius
		draw_line(start, middle, electric_color, 2.0)
		draw_line(middle, end, electric_color, 2.0)


func _impact_color(
	is_player: bool,
	armor_damage: float,
	health_damage: float,
	context: Dictionary
) -> Color:
	if is_player:
		return Color(1.0, 0.26, 0.22, 0.95)
	var source_kind: StringName = StringName(context.get(&"source_kind", &""))
	if context.has(&"impact_color"):
		var custom_color: Color = context[&"impact_color"]
		return custom_color
	if source_kind in [&"magnetic_field", &"blink_path"]:
		return Color(0.24, 0.9, 1.0, 0.95)
	if armor_damage > health_damage:
		return Color(0.32, 0.7, 1.0, 0.95)
	return Color(1.0, 0.78, 0.28, 0.95)


func _update_camera_offset() -> void:
	if not is_instance_valid(camera) or profile == null:
		return
	if trauma <= 0.001:
		camera.offset = directional_kick.limit_length(float(profile.maximum_camera_offset))
		return
	var amplitude: float = trauma * trauma * float(profile.maximum_camera_offset)
	var shake := Vector2(
		sin(elapsed * 71.0) + sin(elapsed * 43.0) * 0.45,
		cos(elapsed * 67.0) + cos(elapsed * 37.0) * 0.45
	).normalized() * amplitude
	camera.offset = (shake + directional_kick).limit_length(float(profile.maximum_camera_offset))


func _on_actor_tree_exited(actor_id: int) -> void:
	registered_actor_ids.erase(actor_id)


func _exit_tree() -> void:
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
