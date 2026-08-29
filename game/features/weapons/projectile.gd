class_name WeaponProjectile
extends Area2D

@export_range(1.0, 3000.0, 10.0) var speed: float = 640.0
@export_range(0.1, 10.0, 0.1) var lifetime: float = 1.8

var direction := Vector2.RIGHT
var damage: float = 1.0
var remaining_lifetime: float


func _ready() -> void:
	remaining_lifetime = lifetime


func launch(new_direction: Vector2, new_damage: float) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method(&"take_damage"):
		body.call(&"take_damage", damage)
	queue_free()
