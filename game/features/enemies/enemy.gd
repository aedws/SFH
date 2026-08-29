class_name EnemyCharacter
extends CharacterBody2D

signal defeated(reward: int, world_position: Vector2)

@export_range(0.0, 1000.0, 5.0) var move_speed: float = 90.0
@export_range(1.0, 10000.0, 1.0) var max_health: float = 3.0
@export_range(0.0, 1000.0, 1.0) var contact_damage: float = 10.0
@export_range(0.1, 10.0, 0.1) var contact_interval: float = 0.75
@export_range(0, 1000, 1) var experience_reward: int = 1

@onready var contact_area: Area2D = $ContactArea
@onready var heading: Polygon2D = $Heading

var target: Node2D
var navigation_provider: Node
var current_health: float
var damage_enabled: bool = true
var contact_cooldown: float = 0.0
var repath_cooldown: float = 0.0
var current_path := PackedVector2Array()
var path_index: int = 0


func _ready() -> void:
	add_to_group(&"enemies")
	current_health = max_health


func configure(
	new_target: Node2D,
	contact_damage_enabled: bool,
	new_navigation_provider: Node = null
) -> void:
	target = new_target
	damage_enabled = contact_damage_enabled
	navigation_provider = (
		new_navigation_provider
		if is_instance_valid(new_navigation_provider)
		and new_navigation_provider.has_method(&"get_world_path")
		else null
	)


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
	if repath_cooldown > 0.0 and path_index < current_path.size():
		return

	current_path = navigation_provider.call(&"get_world_path", global_position, target.global_position)
	path_index = 1 if current_path.size() > 1 else 0
	repath_cooldown = 0.45


func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return

	current_health = maxf(0.0, current_health - amount)
	if is_zero_approx(current_health):
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
