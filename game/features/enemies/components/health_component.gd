class_name HealthComponent
extends Node

signal value_changed(current: float, maximum: float)
signal depleted

@export_range(1.0, 10000.0, 1.0) var maximum_value: float = 3.0

var current_value: float


func _ready() -> void:
	reset()


func configure(new_maximum: float) -> void:
	maximum_value = maxf(1.0, new_maximum)
	reset()


func reset() -> void:
	current_value = maximum_value
	value_changed.emit(current_value, maximum_value)


func apply_damage(amount: float) -> float:
	if amount <= 0.0 or current_value <= 0.0:
		return 0.0

	var previous := current_value
	current_value = maxf(0.0, current_value - amount)
	value_changed.emit(current_value, maximum_value)
	if is_zero_approx(current_value):
		depleted.emit()
	return previous - current_value


func heal(amount: float) -> float:
	if amount <= 0.0 or current_value <= 0.0:
		return 0.0

	var previous := current_value
	current_value = minf(maximum_value, current_value + amount)
	value_changed.emit(current_value, maximum_value)
	return current_value - previous
