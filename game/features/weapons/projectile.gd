class_name WeaponProjectile
extends Area2D

@export_range(1.0, 3000.0, 10.0) var speed: float = 640.0
@export_range(0.1, 10.0, 0.1) var lifetime: float = 1.8

var direction := Vector2.RIGHT
var damage: float = 1.0
var remaining_lifetime: float
var remaining_pierces: int = 0
var pierce_damage_retention: float = 1.0
var hit_body_ids: Dictionary = {}

@onready var body_shape: Polygon2D = $Body


func _ready() -> void:
	remaining_lifetime = lifetime


func launch(
	new_direction: Vector2,
	new_damage: float,
	new_speed: float = 640.0,
	new_lifetime: float = 1.8,
	new_pierce_count: int = 0,
	new_pierce_damage_retention: float = 1.0,
	new_color: Color = Color(1.0, 0.875, 0.302, 1.0)
) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	speed = new_speed
	lifetime = new_lifetime
	remaining_lifetime = new_lifetime
	remaining_pierces = new_pierce_count
	pierce_damage_retention = new_pierce_damage_retention
	body_shape.color = new_color
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	var body_id := body.get_instance_id()
	if hit_body_ids.has(body_id):
		return
	hit_body_ids[body_id] = true
	if not body.has_method(&"take_damage"):
		queue_free()
		return
	body.call(&"take_damage", damage, {
		&"source_kind": &"weapon_projectile",
		&"source_position": global_position - direction * 10.0,
		&"impact_direction": direction,
		&"impact_strength": clampf(damage / 10.0, 0.45, 1.5),
	})
	if remaining_pierces > 0:
		remaining_pierces -= 1
		damage *= pierce_damage_retention
		return
	queue_free()
