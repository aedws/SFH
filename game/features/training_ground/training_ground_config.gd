class_name TrainingGroundConfig
extends Resource

@export var dummy_scene: PackedScene
@export var formation_anchor := Vector2(420.0, -300.0)
@export_range(48.0, 160.0, 4.0) var formation_spacing := 76.0
@export_range(1, 8, 1) var dense_columns := 4
@export var auto_reset_after_clear := true
@export_range(0.05, 3.0, 0.05) var reset_delay_seconds := 0.35
@export_range(0.05, 0.5, 0.05) var telemetry_refresh_seconds := 0.1


func is_valid() -> bool:
	return (
		dummy_scene != null
		and formation_spacing >= 48.0
		and dense_columns > 0
		and reset_delay_seconds > 0.0
		and telemetry_refresh_seconds > 0.0
	)
