class_name WeaponShotFX
extends Node2D

## Successful projectile spawn signal only. Fixed budget, no damage/aim/camera ownership.
@export var spark_texture: Texture2D = preload("res://game/assets/vfx/kenney_particle_pack/spark_04.png")
@export_range(1, 32, 1) var maximum_flashes: int = 16
@export_range(0.04, 0.25, 0.01) var flash_lifetime: float = 0.12
@export_range(8.0, 80.0, 1.0) var flash_length: float = 48.0
var flashes: Array[Dictionary] = []
var total_events: int = 0

func _ready() -> void:
	z_index = 8
	set_process(false)

func play(world_position: Vector2, direction: Vector2, color: Color) -> void:
	if direction.is_zero_approx(): return
	while flashes.size() >= maxi(1, maximum_flashes): flashes.pop_front()
	flashes.append({&"position":world_position, &"direction":direction.normalized(), &"color":color, &"age":0.0})
	total_events += 1
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	for i in range(flashes.size() - 1, -1, -1):
		flashes[i][&"age"] += maxf(0.0, delta)
		if float(flashes[i][&"age"]) >= flash_lifetime: flashes.remove_at(i)
	queue_redraw()
	if flashes.is_empty(): set_process(false)

func _draw() -> void:
	for flash in flashes:
		var phase := clampf(float(flash[&"age"]) / maxf(0.001, flash_lifetime), 0.0, 1.0)
		var direction: Vector2 = flash[&"direction"]
		var side := direction.orthogonal()
		var origin := to_local(flash[&"position"]) + direction * 20.0
		var color: Color = flash[&"color"]
		color.a = (1.0 - phase) * 0.85
		var tip := origin + direction * flash_length * (1.0 - phase * 0.45)
		if phase < 0.55:
			draw_colored_polygon(PackedVector2Array([origin-direction*6.0, origin+side*9.0, tip, origin-side*9.0]), color)
			draw_line(origin, tip, Color(0.9, 1.0, 1.0, 1.0-phase), 2.5)
		if spark_texture != null:
			var size := 34.0 * (1.0 + phase * 0.6)
			draw_texture_rect(spark_texture, Rect2(origin-Vector2.ONE*size*0.5, Vector2.ONE*size), false, color)
		for sign_value in [-1.0, 1.0]:
			var start: Vector2 = origin + side * float(sign_value) * (6.0 + phase * 18.0)
			draw_line(start, start + direction * (9.0 + phase * 12.0), color, 1.5)
