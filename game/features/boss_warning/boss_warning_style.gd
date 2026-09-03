class_name BossWarningStyle
extends Resource

@export_range(0.5, 8.0, 0.1) var warning_seconds := 3.5
@export_range(18.0, 64.0, 1.0) var edge_inset := 24.0
@export_range(8.0, 18.0, 1.0) var arrow_radius := 12.0
@export var warning_color := Color("ffb45c")
@export var background_color := Color("07131bee")


func is_valid() -> bool:
	return is_finite(warning_seconds) and warning_seconds > 0.0 \
		and is_finite(edge_inset) and is_finite(arrow_radius) \
		and arrow_radius >= 8.0 and edge_inset >= arrow_radius + 4.0
