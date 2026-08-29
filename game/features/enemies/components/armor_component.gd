class_name ArmorComponent
extends Node

signal value_changed(current: float, maximum: float)

@export_range(0.0, 10000.0, 1.0) var maximum_value: float = 2.0

var current_value: float


func _ready() -> void:
	reset()


func configure(new_maximum: float) -> void:
	maximum_value = maxf(0.0, new_maximum)
	reset()


func reset() -> void:
	current_value = maximum_value
	value_changed.emit(current_value, maximum_value)


func absorb_damage(incoming_damage: float) -> float:
	if incoming_damage <= 0.0 or current_value <= 0.0:
		return maxf(0.0, incoming_damage)

	var absorbed := minf(current_value, incoming_damage)
	current_value -= absorbed
	value_changed.emit(current_value, maximum_value)
	return incoming_damage - absorbed
