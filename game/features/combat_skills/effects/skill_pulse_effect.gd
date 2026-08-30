class_name SkillPulseEffect
extends Node2D

var maximum_radius: float = 180.0
var lifetime: float = 0.5
var elapsed: float = 0.0
var accent_color := Color(0.3, 0.9, 1.0, 1.0)
var fill_enabled: bool = false


func configure(
	new_radius: float,
	new_color: Color,
	new_lifetime: float = 0.5,
	new_fill_enabled: bool = false
) -> void:
	maximum_radius = maxf(1.0, new_radius)
	accent_color = new_color
	lifetime = maxf(0.05, new_lifetime)
	fill_enabled = new_fill_enabled
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += maxf(0.0, delta)
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()


func _draw() -> void:
	var progress := clampf(elapsed / lifetime, 0.0, 1.0)
	var radius := maximum_radius * lerpf(0.22, 1.0, progress)
	var color := accent_color
	color.a *= 1.0 - progress
	if fill_enabled:
		var fill := color
		fill.a *= 0.16
		draw_circle(Vector2.ZERO, radius, fill, true)
	draw_circle(Vector2.ZERO, radius, color, false, 7.0, true)
	draw_circle(Vector2.ZERO, maxf(4.0, radius * 0.7), color * Color(1, 1, 1, 0.55), false, 2.0, true)
