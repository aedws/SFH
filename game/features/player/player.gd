class_name PlayerCharacter
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal died

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0

@onready var movement: PlayerMovement = $Movement
@onready var heading: Polygon2D = $Heading

var current_health: float
var damage_enabled: bool = true


func _ready() -> void:
	add_to_group(&"player")
	current_health = max_health


func _physics_process(_delta: float) -> void:
	velocity = movement.get_velocity()
	move_and_slide()

	if velocity != Vector2.ZERO:
		heading.rotation = velocity.angle()


func configure_damage(is_enabled: bool) -> void:
	damage_enabled = is_enabled


func take_damage(amount: float) -> void:
	if not damage_enabled or current_health <= 0.0:
		return

	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)

	if is_zero_approx(current_health):
		died.emit()


func heal(amount: float) -> void:
	if current_health <= 0.0:
		return

	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
