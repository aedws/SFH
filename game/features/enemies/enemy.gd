class_name EnemyCharacter
extends CharacterBody2D

signal defeated(reward: int, world_position: Vector2)

@export_range(0.0, 1000.0, 5.0) var move_speed: float = 90.0
@export_range(1.0, 10000.0, 1.0) var max_health: float = 3.0
@export_range(0.0, 10000.0, 1.0) var max_armor: float = 2.0
@export_range(0.0, 1000.0, 1.0) var contact_damage: float = 10.0
@export_range(0.1, 10.0, 0.1) var contact_interval: float = 0.75
@export_range(0, 1000, 1) var experience_reward: int = 1
@export_range(0.2, 2.0, 0.05) var repath_interval: float = 0.7
@export_range(16.0, 320.0, 8.0) var repath_target_distance: float = 96.0
@export_range(1, 5, 1) var priority_rank: int = 1

@onready var contact_area: Area2D = $ContactArea
@onready var heading: Polygon2D = $Heading
@onready var health_component: HealthComponent = $HealthComponent
@onready var armor_component: ArmorComponent = $ArmorComponent
@onready var status_bars: EnemyStatusBars = $StatusBars

var target: Node2D
var navigation_provider: Node
var current_health: float
var damage_enabled: bool = true
var contact_cooldown: float = 0.0
var repath_cooldown: float = 0.0
var current_path := PackedVector2Array()
var path_index: int = 0
var last_path_target_position := Vector2.INF


func _ready() -> void:
	add_to_group(&"enemies")
	health_component.depleted.connect(_on_health_depleted)
	health_component.value_changed.connect(_on_health_value_changed)
	health_component.configure(max_health)
	armor_component.configure(max_armor)
	status_bars.configure(health_component, armor_component)


func configure(
	new_target: Node2D,
	contact_damage_enabled: bool,
	new_navigation_provider: Node = null,
	armor_enabled: bool = true,
	status_ui_enabled: bool = true,
	stat_multipliers: Dictionary = {}
) -> void:
	target = new_target
	damage_enabled = contact_damage_enabled
	navigation_provider = (
		new_navigation_provider
		if is_instance_valid(new_navigation_provider)
		and new_navigation_provider.has_method(&"get_world_path")
		else null
	)
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


func _physics_process(delta: float) -> void:
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	repath_cooldown = maxf(0.0, repath_cooldown - delta)

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

		var direction := global_position.direction_to(destination)
		velocity = direction * move_speed
		heading.rotation = direction.angle()
		move_and_slide()

	_try_contact_damage()


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


func take_damage(amount: float) -> void:
	if health_component.current_value <= 0.0:
		return

	var remaining_damage := armor_component.absorb_damage(amount)
	health_component.apply_damage(remaining_damage)


func get_targeting_snapshot() -> Dictionary:
	return {
		&"current_health": health_component.current_value,
		&"maximum_health": health_component.maximum_value,
		&"current_armor": armor_component.current_value,
		&"maximum_armor": armor_component.maximum_value,
		&"priority_rank": priority_rank,
	}


func _on_health_value_changed(current: float, _maximum: float) -> void:
	current_health = current


func _on_health_depleted() -> void:
	defeated.emit(experience_reward, global_position)
	queue_free()


func _try_contact_damage() -> void:
	if not damage_enabled or contact_cooldown > 0.0:
		return

	for body in contact_area.get_overlapping_bodies():
		if body.has_method(&"take_damage"):
			body.call(&"take_damage", contact_damage)
			contact_cooldown = contact_interval
			return
