extends SceneTree

class Victim:
	extends Node2D
	var hits := 0
	var total := 0.0
	func take_damage(amount: float, _context: Dictionary = {}) -> void:
		hits += 1
		total += amount

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("ENEMY_TELEGRAPH_FAILED " + message)

func _init() -> void:
	call_deferred(&"run")

func run() -> void:
	var enemy: EnemyCharacter = load("res://game/features/enemies/enemy.tscn").instantiate()
	root.add_child(enemy)
	enemy.set_physics_process(false)
	var actor := Victim.new()
	root.add_child(actor)
	actor.position = Vector2(30, 0)
	enemy.configure(actor, true)
	var attack := enemy.attack_telegraph
	check(attack != null, "actual enemy wires component")
	enemy._advance_contact_attack(1.0)
	check(actor.hits == 0 and attack.active and attack.elapsed == 0.0, "acquisition frame cannot damage")
	enemy._advance_contact_attack(0.39)
	check(actor.hits == 0 and attack.active, "warning before strike")
	enemy._advance_contact_attack(0.02)
	check(actor.hits == 1 and actor.total == enemy.contact_damage and not attack.active, "one delayed strike")
	enemy._advance_contact_attack(1.0)
	check(actor.hits == 1 and not attack.active, "recovery blocks instant repeat")
	enemy.contact_cooldown = 0.0
	enemy._advance_contact_attack(0.01)
	actor.position.y = 20.0
	enemy._physics_process(0.01)
	check(enemy.velocity.is_zero_approx() and is_zero_approx(enemy.heading.rotation), "windup stops pursuit and facing stays on warning")
	enemy._advance_contact_attack(0.41)
	check(actor.hits == 1 and enemy.contact_cooldown > 0.0, "sidestep dodges locked direction and consumes recovery")
	actor.position = Vector2(30, 0)
	enemy.contact_cooldown = 0.0
	enemy._advance_contact_attack(0.01)
	enemy.active_statuses[&"stun"] = {&"remaining": 1.0}
	enemy._advance_contact_attack(1.0)
	check(not attack.active and actor.hits == 1, "stun cancels windup")
	enemy.active_statuses.clear()
	enemy._advance_contact_attack(0.01)
	enemy.damage_enabled = false
	enemy._advance_contact_attack(1.0)
	check(not attack.active and actor.hits == 1, "spawn grace / disable cancels")
	enemy.damage_enabled = true
	enemy._advance_contact_attack(0.01)
	enemy.position.x = 9.0
	enemy._advance_contact_attack(1.0)
	check(not attack.active and actor.hits == 1, "knockback invalidates warning location")
	enemy.position = Vector2.ZERO
	enemy._advance_contact_attack(0.01)
	actor.position.x = 100.0
	enemy._advance_contact_attack(0.41)
	check(actor.hits == 1, "leaving reach dodges")
	var policy := EnemyAttackPolicy.new()
	check(policy.contains(Vector2(48, 10), Vector2.RIGHT), "hit boundary")
	check(not policy.contains(Vector2(48, 10.1), Vector2.RIGHT), "slim side boundary")
	check(not policy.contains(Vector2(-1, 0), Vector2.RIGHT), "no rear hit")
	check(not policy.contains(Vector2(49, 0), Vector2.RIGHT), "reach boundary")
	for seconds in [0.3, 0.5]:
		policy.windup_seconds = seconds
		check(attack.configure(policy), "replaceable policy")
		policy.windup_seconds = 9.0
		check(attack.policy.windup_seconds == seconds, "deep copied policy")
		actor.position = Vector2(30, 0)
		attack.advance(0.01, Vector2.ZERO, actor, 1.0)
		check(not attack.configure(policy), "no policy change mid warning")
		check(not attack.advance(seconds - 0.01, Vector2.ZERO, actor, 1.0), "configurable warning duration")
		check(attack.advance(0.02, Vector2.ZERO, actor, 1.0), "configurable strike duration")
	policy.windup_seconds = NAN
	check(not attack.configure(policy), "invalid policy rejected")
	var hits := actor.hits
	attack.advance(0.01, Vector2.ZERO, actor, 1.0)
	for delta in [-1.0, NAN, INF]:
		check(not attack.advance(delta, Vector2.ZERO, actor, 1.0), "invalid delta ignored")
	check(attack.elapsed == 0.0 and actor.hits == hits, "invalid time does not advance")
	actor.free()
	attack.advance(1.0, Vector2.ZERO, null, 1.0)
	check(not attack.active, "removed target cancels")
	actor = Victim.new()
	root.add_child(actor)
	actor.position = Vector2(30, 0)
	var wall := StaticBody2D.new()
	wall.collision_layer = 16
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(4, 80)
	shape.shape = rectangle
	wall.add_child(shape)
	root.add_child(wall)
	wall.position = Vector2(15, 0)
	await physics_frame
	await physics_frame
	attack.advance(0.01, Vector2.ZERO, actor, 1.0)
	check(not attack.active, "ordinary enemy cannot acquire through wall")
	attack.advance(0.01, Vector2.ZERO, actor, 1.0, 0)
	check(attack.active, "pursuit boss retains barrier bypass")
	check(attack.advance(0.51, Vector2.ZERO, actor, 1.0, 0) and actor.hits == 1, "boss strike through barrier")
	wall.free()
	enemy.target = actor
	enemy.contact_cooldown = 0.0
	enemy._advance_contact_attack(0.01)
	enemy._on_health_depleted()
	check(not attack.active, "death cancels ghost strike")
	await process_frame
	actor.free()
	var legacy: EnemyCharacter = load("res://game/features/enemies/enemy.tscn").instantiate()
	legacy.attack_policy = null
	root.add_child(legacy)
	legacy.set_physics_process(false)
	check(legacy.get_attack_snapshot().get(&"legacy_contact", false), "legacy feature-off adapter retained")
	legacy.free()
	if "--render" in OS.get_cmdline_user_args():
		await verify_render()
	if failures == 0: print("ENEMY_TELEGRAPH_OK warning locked_dodge cooldown stun knockback death wall boss policy")
	quit(1 if failures else 0)

func verify_render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(160, 100)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var attack := EnemyAttackTelegraph.new()
	viewport.add_child(attack)
	attack.configure(EnemyAttackPolicy.new())
	attack.origin = Vector2(40, 50)
	attack.direction = Vector2.RIGHT
	attack.active = true
	attack.elapsed = 0.2
	attack.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	var red := 0
	for y in range(100):
		for x in range(160):
			var pixel := picture.get_pixel(x, y)
			if pixel.r > 0.5 and pixel.r > pixel.g * 2.0:
				red += 1
				check(x >= 38 and x <= 90 and y >= 38 and y <= 62, "warning remains bounded by strike geometry")
	check(red > 100, "visible red warning pixels")
	picture.save_png("res://build/enemy-telegraph-render.png")
	print("ENEMY_TELEGRAPH_RENDER pixels=", red)
	viewport.free()
