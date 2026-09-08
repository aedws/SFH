extends SceneTree

const Policy = preload("res://game/features/weapon_balance/weapon_distance_policy.gd")
class Target extends Node2D:
	var hits: Array[Dictionary] = []
	func take_damage(amount: float, context: Dictionary = {}) -> void:
		hits.append({"damage": amount, "context": context})

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for invalid in ["", "0:1", "0:1;0:2;1:1", "0:1;1:4", "0:nan;1:1", "0:1;0.9:1", "0:1;;1:1"]:
		assert(Policy.parse(invalid).is_empty(), invalid)
	var points := Policy.parse("0:1;0.5:1.25;1:0.6")
	assert(is_equal_approx(Policy.multiplier(points, 500.0, 1000.0), 1.25))
	assert(is_equal_approx(Policy.multiplier(points, 125.0, 1000.0), 1.0625))
	assert(is_equal_approx(Policy.multiplier(points, 2000.0, 1000.0), 0.6))
	var projectile: Area2D = load("res://game/features/weapons/projectile.tscn").instantiate()
	root.add_child(projectile)
	projectile.set_physics_process(false)
	projectile.global_position = Vector2(5000, 5000)
	var launch := {"distance_damage_curve": "0:1;1:0.5", "launch_range_px": 1000.0}
	projectile.launch(Vector2.RIGHT, 10.0, 640.0, 2.0, 2, 0.5, Color.WHITE, launch)
	launch.distance_damage_curve = "0:3;1:3"
	launch.launch_range_px = 50.0
	var first := Target.new()
	var second := Target.new()
	root.add_child(first)
	root.add_child(second)
	projectile.global_position += Vector2(500, 0)
	projectile._on_body_entered(first)
	projectile._on_body_entered(first)
	assert(first.hits.size() == 1)
	assert(is_equal_approx(first.hits[0].damage, 7.5))
	assert(is_equal_approx(first.hits[0].context.distance_px, 500.0))
	projectile.global_position += Vector2(500, 0)
	projectile._on_body_entered(second)
	assert(is_equal_approx(second.hits[0].damage, 2.5), "Pierce must not compound first distance factor")
	projectile.free()
	first.free()
	second.free()
	var csv := FileAccess.get_file_as_string("res://game/features/weapon_balance/data/weapon_balance.csv")
	var table = load("res://game/features/weapon_balance/weapon_balance_table.gd")
	assert(table.parse(csv).errors.is_empty())
	assert(not table.parse(csv.replace("0:1;0.6:1;1:0.7", "0:1;0:1;1:1")).errors.is_empty())
	print("WEAPON_DISTANCE_OK curve bounds / launch snapshot / hits / pierce / live rejection")
	quit()
