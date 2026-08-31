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
	set_process(true)
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
	queue_redraw()


func _draw() -> void:
	if profile == null:
		return
	for impact in impacts:
		var lifetime: float = maxf(0.001, float(impact[&"lifetime"]))
		var ratio: float = 1.0 - float(impact[&"remaining"]) / lifetime
		var intensity: float = float(impact[&"intensity"])
		var radius: float = float(profile.impact_radius) * intensity * (0.35 + ratio * 0.85)
		var color: Color = impact[&"color"]
		color.a *= 1.0 - ratio
		var position: Vector2 = impact[&"position"]
		draw_arc(position, radius, 0.0, TAU, 20, color, 2.0)
		var base_direction: Vector2 = impact[&"direction"]
		for ray_index in int(profile.impact_ray_count):
			var direction: Vector2 = base_direction.rotated(
				TAU * float(ray_index) / float(profile.impact_ray_count)
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
		&"color": color,
	})
	total_hits += 1
	if is_player:
		total_player_hits += 1
	if lethal:
		total_lethal_hits += 1
	trauma = clampf(
		trauma
		+ float(profile.player_hit_trauma if is_player else profile.enemy_hit_trauma) * intensity
		+ float(profile.lethal_bonus_trauma if lethal else 0.0),
		0.0,
		1.0
	)
	peak_active_impacts = maxi(peak_active_impacts, impacts.size())
	queue_redraw()


func _impact_color(
	is_player: bool,
	armor_damage: float,
	health_damage: float,
	context: Dictionary
) -> Color:
	if is_player:
		return Color(1.0, 0.26, 0.22, 0.95)
	var source_kind: StringName = StringName(context.get(&"source_kind", &""))
	if source_kind in [&"magnetic_field", &"blink_path"]:
		return Color(0.24, 0.9, 1.0, 0.95)
	if armor_damage > health_damage:
		return Color(0.32, 0.7, 1.0, 0.95)
	return Color(1.0, 0.78, 0.28, 0.95)


func _update_camera_offset() -> void:
	if not is_instance_valid(camera) or profile == null:
		return
	if trauma <= 0.001:
		camera.offset = camera.offset.lerp(Vector2.ZERO, 0.45)
		return
	var amplitude: float = trauma * trauma * float(profile.maximum_camera_offset)
	camera.offset = Vector2(
		sin(elapsed * 71.0) + sin(elapsed * 43.0) * 0.45,
		cos(elapsed * 67.0) + cos(elapsed * 37.0) * 0.45
	).normalized() * amplitude


func _on_actor_tree_exited(actor_id: int) -> void:
	registered_actor_ids.erase(actor_id)


func _exit_tree() -> void:
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
