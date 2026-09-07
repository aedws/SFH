extends SceneTree

const POLICY = preload("res://game/features/smart_targeting/smart_targeting_policy.gd")
const DEFINITION = preload("res://game/features/combat_skills/combat_skill_definition.gd")
const LOADOUT = preload("res://game/features/combat_skills/combat_skill_loadout.gd")
const SYSTEM = preload("res://game/features/combat_skills/combat_skill_system.gd")

class ProbeEffect extends Resource:
	var radius := 30.0
	var received := {}
	var last_hits := 0
	func get_parameters() -> Dictionary:
		return {&"radius": radius}
	func activate(_player: Node2D, context: Dictionary) -> Dictionary:
		received = context.duplicate()
		var hit_count := 0
		for target in context[&"target_container"].get_children():
			if target.global_position.distance_to(context[&"target_point"]) <= radius:
				hit_count += 1
		last_hits = hit_count
		return {&"success": true, &"hit_count": hit_count}

class LegacyPolicy extends Resource:
	func resolve(_mode: StringName, _origin: Vector2, _candidates: Array, _range: float, direction: Vector2) -> Dictionary:
		return {&"target_point": Vector2(7, 9), &"direction": direction}

var failures := PackedStringArray()
var sandbox: Node2D

func _init() -> void:
	call_deferred(&"_run")

func _run() -> void:
	sandbox = Node2D.new()
	root.add_child(sandbox)
	var policy := POLICY.new()
	var enemies := Node2D.new()
	sandbox.add_child(enemies)
	var a := _enemy(Vector2(100, 0), enemies)
	var b := _enemy(Vector2(110, 0), enemies)
	var c := _enemy(Vector2(100, 10), enemies)
	var candidates: Array = [a, b, c]
	var center := (a.position + b.position + c.position) / 3.0
	var result := policy.resolve_for_skill(&"densest", Vector2.ZERO, candidates, 200, Vector2.RIGHT, 30)
	_check(result.target_point.is_equal_approx(center), "cluster center survives representative target")
	_check(not result.target_point.is_equal_approx(result.target.position), "center is not an enemy coordinate")
	candidates.reverse()
	_check(policy.resolve_for_skill(&"densest", Vector2.ZERO, candidates, 200, Vector2.RIGHT, 30).target_point.is_equal_approx(center), "order independent")
	candidates.append(a)
	_check(policy.resolve(&"densest", Vector2.ZERO, candidates, 200).target_point.is_equal_approx(center), "duplicate candidates do not bias density")
	var removed := _enemy(Vector2.ZERO, sandbox)
	removed.queue_free()
	var invalid := Node2D.new()
	invalid.free()
	var empty := policy.resolve(&"densest", Vector2.ZERO, [removed, invalid, null], 100)
	_check(empty.target == null and empty.target_point == Vector2.ZERO, "invalid and queued candidates ignored")
	var edge_a := _enemy(Vector2(90, -40), sandbox)
	var edge_b := _enemy(Vector2(90, 40), sandbox)
	var outside := _enemy(Vector2(101, 0), sandbox)
	var edge := policy.resolve_for_skill(&"densest", Vector2.ZERO, [edge_a, edge_b, outside], 100, Vector2.RIGHT, 100)
	_check(edge.target != outside and edge.target_point.is_equal_approx(Vector2(90, 0)), "range eligibility applies to representative too")
	var near := _enemy(Vector2(10, 0), sandbox)
	var far := _enemy(Vector2(140, 0), sandbox)
	var spread: Array = [near, a, far]
	_check(policy.resolve_for_skill(&"densest", Vector2.ZERO, spread, 200, Vector2.RIGHT, 10).target_point == near.position, "small radius chooses nearest singleton")
	_check(policy.resolve_for_skill(&"densest", Vector2.ZERO, spread, 200, Vector2.RIGHT, 50).target_point == Vector2(120, 0), "effect radius changes chosen cluster")
	var left := _enemy(Vector2(-10, 0), sandbox)
	_check(policy.resolve_for_skill(&"densest", Vector2.ZERO, [near, left], 100, Vector2.RIGHT, 1).target_point == left.position, "equal-density equal-distance coordinate tie break")
	_check(policy.resolve(&"direction", Vector2.ZERO, [], 100, Vector2.DOWN).target_point == Vector2(0, 100), "direction contract preserved")
	_check(policy.resolve(&"self", Vector2.ZERO, candidates, 100).target_point == Vector2.ZERO, "self field remains player centered")
	_check(policy.resolve(&"nearest", Vector2.ZERO, spread, 200).target == near, "single target contract preserved")

	var actor := Node2D.new()
	sandbox.add_child(actor)
	var effect := ProbeEffect.new()
	var skill := DEFINITION.new()
	skill.skill_id = &"test_density"
	skill.input_action = &"test_density"
	skill.effect = effect
	skill.targeting_mode = "densest"
	var loadout := LOADOUT.new()
	loadout.skills.assign([skill])
	var system := SYSTEM.new()
	sandbox.add_child(system)
	_check(system.configure(actor, enemies, sandbox, loadout, true, null, policy), "runtime configured")
	_check(is_equal_approx(skill.get_targeting_radius({&"radius_multiplier": 2.0}), 60), "definition reads actual radius multiplier")
	_check(system.try_activate(0), "actual activation")
	_check(effect.received.target_point.is_equal_approx(center), "runtime effect receives density point")
	_check(effect.last_hits == 3, "activated area effect hits three cluster targets")
	effect.radius = 1.0
	system.cooldowns[0] = 0
	_check(system.try_activate(0) and effect.received.target_point == a.position, "runtime updated effect radius changes point without cached settings")
	system.set_runtime_modifiers(&"test", {&"radius_multiplier": 30.0})
	system.cooldowns[0] = 0
	_check(system.try_activate(0) and effect.received.target_point.is_equal_approx(center), "runtime modifier radius is forwarded")
	system.remove_runtime_modifiers(&"test")
	effect.radius = 30.0
	_check(effect.received.target_point.distance_to(a.position) <= effect.radius, "effect can hit cluster at received point")
	system.cooldowns[0] = 0
	system.targeting_policy = LegacyPolicy.new()
	_check(system.try_activate(0) and effect.received.target_point == Vector2(7, 9), "legacy five-argument provider works")
	system.cooldowns[0] = 0
	system.targeting_policy = null
	_check(system.try_activate(0) and effect.received.target_point == actor.position, "optional targeting fallback")
	sandbox.queue_free()
	await process_frame
	if failures.is_empty():
		print("SMART_TARGETING_CENTER_OK centroid effect_radius stable_ties range_guard invalid_candidates runtime_effect legacy_policy optional_self")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _enemy(at: Vector2, parent: Node) -> Node2D:
	var enemy := Node2D.new()
	parent.add_child(enemy)
	enemy.position = at
	return enemy

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
