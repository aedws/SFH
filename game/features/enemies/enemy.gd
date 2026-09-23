class_name EnemyCharacter
extends CharacterBody2D

signal defeated(reward: int, world_position: Vector2)
signal damaged(
	health_damage: float,
	armor_damage: float,
	world_position: Vector2,
	context: Dictionary
)

@export_range(0.0, 1000.0, 5.0) var move_speed: float = 90.0
@export_range(1.0, 10000.0, 1.0) var max_health: float = 3.0
@export_range(0.0, 10000.0, 1.0) var max_armor: float = 2.0
@export_range(0.0, 1000.0, 1.0) var contact_damage: float = 10.0
@export_range(0.1, 10.0, 0.1) var contact_interval: float = 0.75
@export_range(0, 1000, 1) var experience_reward: int = 1
@export_range(0.2, 2.0, 0.05) var repath_interval: float = 0.7
@export_range(16.0, 320.0, 8.0) var repath_target_distance: float = 96.0
@export_range(1, 5, 1) var priority_rank: int = 1
@export var attack_policy: EnemyAttackPolicy = preload("res://game/features/enemies/configs/default_enemy_attack.tres")

@onready var contact_area: Area2D = $ContactArea
@onready var body_visual: Polygon2D = $Body
@onready var heading: Polygon2D = $Heading
@onready var health_component: HealthComponent = $HealthComponent
@onready var armor_component: ArmorComponent = $ArmorComponent
@onready var status_bars: EnemyStatusBars = $StatusBars
@onready var hit_reaction: Node = get_node_or_null("HitReaction")

var target: Node2D
var navigation_provider: Node
var crowd_provider: Node
var crowd_config: Resource
var current_health: float
var damage_enabled: bool = true
var contact_cooldown: float = 0.0
var repath_cooldown: float = 0.0
var current_path := PackedVector2Array()
var path_index: int = 0
var last_path_target_position := Vector2.INF
var crowd_steering_cooldown: float = 0.0
var cached_crowd_steering := Vector2.ZERO
var active_statuses: Dictionary = {}
var elite_pursuer: bool = false
var boss: bool = false
var ignore_room_barriers: bool = false
var attack_telegraph: EnemyAttackTelegraph


func _ready() -> void:
	add_to_group(&"enemies")
	health_component.depleted.connect(_on_health_depleted)
	health_component.value_changed.connect(_on_health_value_changed)
	health_component.configure(max_health)
	armor_component.configure(max_armor)
	status_bars.configure(health_component, armor_component)
	if hit_reaction != null:
		hit_reaction.configure(self, [body_visual, heading])
	if attack_policy != null and attack_policy.enabled:
		attack_telegraph = EnemyAttackTelegraph.new()
		add_child(attack_telegraph)
		if not attack_telegraph.configure(attack_policy):
			push_error("Invalid enemy attack policy")
			damage_enabled = false


func configure(
	new_target: Node2D,
	contact_damage_enabled: bool,
	new_navigation_provider: Node = null,
	armor_enabled: bool = true,
	status_ui_enabled: bool = true,
	stat_multipliers: Dictionary = {},
	new_crowd_provider: Node = null,
	new_crowd_config: Resource = null
) -> void:
	target = new_target
	damage_enabled = contact_damage_enabled
	navigation_provider = (
		new_navigation_provider
		if is_instance_valid(new_navigation_provider)
		and new_navigation_provider.has_method(&"get_world_path")
		else null
	)
	crowd_provider = (
		new_crowd_provider
		if is_instance_valid(new_crowd_provider)
		and new_crowd_provider.has_method(&"get_separation_vector")
		else null
	)
	crowd_config = new_crowd_config
	move_speed *= float(stat_multipliers.get(&"speed_multiplier", 1.0))
	contact_damage *= float(stat_multipliers.get(&"damage_multiplier", 1.0))
	health_component.configure(
		max_health * float(stat_multipliers.get(&"health_multiplier", 1.0))
	)
	armor_component.configure(
		max_armor * float(stat_multipliers.get(&"armor_multiplier", 1.0))
		if armor_enabled else 0.0
	)
	status_bars.visible = status_ui_enabled
	repath_cooldown = fmod(float(get_instance_id()) * 0.017, repath_interval)
	if _crowd_separation_enabled():
		crowd_steering_cooldown = fmod(
			float(get_instance_id()) * 0.013,
			float(crowd_config.get("steering_update_interval"))
		)


var pressure_damage_multiplier := 1.0
var pressure_speed_multiplier := 1.0


func set_run_pressure(damage_multiplier: float, speed_multiplier: float) -> bool:
	if not is_finite(damage_multiplier) or not is_finite(speed_multiplier) or damage_multiplier < 1.0 or speed_multiplier < 1.0:
		return false
	contact_damage = contact_damage / pressure_damage_multiplier * damage_multiplier
	move_speed = move_speed / pressure_speed_multiplier * speed_multiplier
	pressure_damage_multiplier = damage_multiplier
	pressure_speed_multiplier = speed_multiplier
	return true


func configure_elite_pursuer(profile: Dictionary) -> void:
	elite_pursuer = true
	ignore_room_barriers = bool(profile.get(&"ignore_room_barriers", true))
	priority_rank = int(profile.get(&"priority_rank", priority_rank))
	if ignore_room_barriers:
		collision_mask &= ~16
		navigation_provider = null
	body_visual.color = Color("e83e8c")
	heading.color = Color("02e5e1")
	scale = Vector2.ONE * 1.18
	set_meta(&"elite_pursuer", true)


func set_boss_role(enabled: bool) -> void:
	boss = enabled


func get_combat_identity() -> Dictionary:
	return {&"is_boss": boss, &"is_elite_pursuer": elite_pursuer}


func _physics_process(delta: float) -> void:
	_advance_statuses(delta)
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	repath_cooldown = maxf(0.0, repath_cooldown - delta)
	crowd_steering_cooldown = maxf(0.0, crowd_steering_cooldown - delta)

	if is_instance_valid(target):
		var destination := target.global_position
		if is_instance_valid(navigation_provider):
			_update_navigation_path()
			if path_index < current_path.size():
				destination = current_path[path_index]
				if global_position.distance_to(destination) <= 12.0:
					path_index += 1
					if path_index < current_path.size():
						destination = current_path[path_index]

		var pursuit_direction := global_position.direction_to(destination)
		_update_crowd_steering()
		var direction := pursuit_direction
		if _crowd_separation_enabled():
			direction = (
				cached_crowd_steering.normalized()
				if cached_crowd_steering.length() >= 0.95
				else (
					pursuit_direction
					+ cached_crowd_steering * float(crowd_config.get("separation_strength"))
				).normalized()
			)
		var desired_velocity := direction * move_speed * EnemyStatusPolicy.movement_multiplier(active_statuses, boss)
		if attack_telegraph != null and attack_telegraph.active:
			desired_velocity = Vector2.ZERO
		velocity = (
			hit_reaction.advance(delta, desired_velocity)
			if hit_reaction != null else desired_velocity
		)
		heading.rotation = attack_telegraph.direction.angle() if attack_telegraph != null and attack_telegraph.active else direction.angle()
		move_and_slide()

	_advance_contact_attack(delta)


func get_attack_snapshot() -> Dictionary:
	return attack_telegraph.get_snapshot() if attack_telegraph != null else {&"active": false, &"legacy_contact": true}


func _advance_contact_attack(delta: float) -> void:
	if attack_telegraph == null:
		_try_contact_damage()
		return
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not damage_enabled or contact_cooldown > 0.0 or health_component.current_value <= 0.0 or not EnemyStatusPolicy.can_attack(active_statuses, boss):
		attack_telegraph.cancel()
		return
	if attack_telegraph.advance(delta, global_position, target, contact_damage, 0 if ignore_room_barriers else 16):
		contact_cooldown = contact_interval


func _update_crowd_steering() -> void:
	if not _crowd_separation_enabled():
		cached_crowd_steering = Vector2.ZERO
		return
	if crowd_steering_cooldown > 0.0:
		return
	cached_crowd_steering = crowd_provider.call(
		&"get_separation_vector",
		self,
		global_position,
		float(crowd_config.get("separation_radius")),
		int(crowd_config.get("maximum_neighbors"))
	)
	crowd_steering_cooldown = float(crowd_config.get("steering_update_interval"))


func _crowd_separation_enabled() -> bool:
	return (
		is_instance_valid(crowd_provider)
		and crowd_config != null
		and bool(crowd_config.get("enabled"))
		and crowd_config.has_method(&"is_valid")
		and bool(crowd_config.call(&"is_valid"))
	)


func _update_navigation_path() -> void:
	if repath_cooldown > 0.0:
		return
	if (
		path_index < current_path.size()
		and last_path_target_position.distance_to(target.global_position) < repath_target_distance
	):
		repath_cooldown = repath_interval
		return

	current_path = navigation_provider.call(&"get_world_path", global_position, target.global_position)
	path_index = 1 if current_path.size() > 1 else 0
	last_path_target_position = target.global_position
	repath_cooldown = repath_interval


func take_damage(amount: float, hit_context: Dictionary = {}) -> void:
	if health_component.current_value <= 0.0:
		return

	var armor_before := armor_component.current_value
	var remaining_damage := armor_component.absorb_damage(amount * EnemyStatusPolicy.damage_multiplier(active_statuses))
	var armor_damage := maxf(0.0, armor_before - armor_component.current_value)
	var health_damage := health_component.apply_damage(remaining_damage)
	var context := hit_context.duplicate(true)
	context[&"lethal"] = health_component.current_value <= 0.0
	if hit_reaction != null:
		hit_reaction.react(context, armor_damage + health_damage)
	damaged.emit(health_damage, armor_damage, global_position, context)


func apply_status(status_id: StringName, duration_seconds: float, stacks: int = 1) -> bool:
	if status_id == &"" or duration_seconds <= 0.0 or stacks <= 0:
		return false
	var current: Dictionary = active_statuses.get(status_id, {&"remaining": 0.0, &"stacks": 0})
	current[&"remaining"] = maxf(float(current.get(&"remaining", 0.0)), duration_seconds)
	current[&"stacks"] = mini(99, int(current.get(&"stacks", 0)) + stacks)
	active_statuses[status_id] = current
	return true


func has_status(status_id: StringName) -> bool:
	return active_statuses.has(status_id) and float(active_statuses[status_id].get(&"remaining", 0.0)) > 0.0


func consume_status(status_id: StringName, stacks: int = 1) -> bool:
	if not has_status(status_id):
		return false
	var current: Dictionary = active_statuses[status_id]
	current[&"stacks"] = int(current.get(&"stacks", 1)) - maxi(1, stacks)
	if int(current[&"stacks"]) <= 0:
		active_statuses.erase(status_id)
	else:
		active_statuses[status_id] = current
	return true


func get_targeting_snapshot() -> Dictionary:
	return {
		&"current_health": health_component.current_value,
		&"maximum_health": health_component.maximum_value,
		&"current_armor": armor_component.current_value,
		&"maximum_armor": armor_component.maximum_value,
		&"priority_rank": priority_rank,
		&"elite_pursuer": elite_pursuer,
		&"ignore_room_barriers": ignore_room_barriers,
		&"active_statuses": active_statuses.duplicate(true),
	}


func _advance_statuses(delta: float) -> void:
	for status_id in active_statuses.keys():
		var current: Dictionary = active_statuses[status_id]
		current[&"remaining"] = maxf(0.0, float(current.get(&"remaining", 0.0)) - maxf(0.0, delta))
		if float(current[&"remaining"]) <= 0.0:
			active_statuses.erase(status_id)
		else:
			active_statuses[status_id] = current


func _on_health_value_changed(current: float, _maximum: float) -> void:
	current_health = current


func _on_health_depleted() -> void:
	if attack_telegraph != null:
		attack_telegraph.cancel()
	defeated.emit(experience_reward, global_position)
	queue_free()


func _try_contact_damage() -> void:
	if not damage_enabled or contact_cooldown > 0.0 or not EnemyStatusPolicy.can_attack(active_statuses, boss):
		return

	for body in contact_area.get_overlapping_bodies():
		if body.has_method(&"take_damage"):
			body.call(&"take_damage", contact_damage, {
				&"source_kind": &"enemy_contact",
				&"source_position": global_position,
				&"impact_direction": global_position.direction_to(body.global_position),
				&"impact_strength": 0.65,
			})
			contact_cooldown = contact_interval
			return
