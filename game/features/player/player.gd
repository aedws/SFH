class_name PlayerCharacter
extends CharacterBody2D

@onready var movement: PlayerMovement = $Movement


func _physics_process(_delta: float) -> void:
	velocity = movement.get_velocity()
	move_and_slide()
