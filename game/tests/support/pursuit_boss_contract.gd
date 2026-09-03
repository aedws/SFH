extends RefCounted

const POLICY = preload("res://game/features/elite_pursuit/configs/default_elite_pursuit.tres")
const SERVICE = preload("res://game/features/elite_pursuit/elite_pursuit_service.gd")
const LEDGER = preload("res://game/features/credits/credit_ledger.gd")
const DOOR = preload("res://game/features/room_encounters/room_door_barrier.gd")

class RetrySpawner extends Node:
	var real_spawner: Node
	var failures := 0
	var calls := 0
	func spawn_elite_pursuer_at(position: Vector2, profile: Dictionary) -> Node2D:
		calls += 1
		if calls <= failures:
			return null
		return real_spawner.spawn_elite_pursuer_at(position, profile)
	func get_active_targets() -> Array:
		return real_spawner.get_active_targets()


func verify(tree: SceneTree) -> String:
	for cost in [100, 101, 0]:
		var error := await _verify_cost(tree, cost)
		if not error.is_empty():
			return error
	return ""


func _verify_cost(tree: SceneTree, cost: int) -> String:
	var fixture := Node2D.new()
	tree.root.add_child(fixture)
	var player = preload("res://game/features/player/player.tscn").instantiate()
	fixture.add_child(player)
	player.global_position = Vector2(8000, 8000)
	var spawner = preload("res://game/features/spawning/enemy_spawner.tscn").instantiate()
	fixture.add_child(spawner)
	spawner.configure(player, fixture, true, null, true, true,
		load("res://game/features/spawning/configs/small.tres"), {}, {})
	spawner.set_reinforcement_paused(&"contract", true)
	var retry := RetrySpawner.new()
	retry.real_spawner = spawner
	retry.failures = 1 if cost == 100 else 0
	fixture.add_child(retry)
	var ledger := LEDGER.new()
	fixture.add_child(ledger)
	var service := SERVICE.new()
	fixture.add_child(service)
	var config: Resource = POLICY.duplicate(true)
	service.configure(player, ledger, retry, null, config, cost, 10.0, 77003)
	config.carried_credit_threshold_multiplier = 9.0 # Launch owns a frozen policy.
	var threshold := maxi(1, ceili(cost * 0.5))
	var metrics := preload("res://game/core/run_combat_metrics.gd").new()
	spawner.enemy_spawned.connect(metrics.register_enemy)
	ledger.add_carried(threshold - 1)
	if service.triggered or retry.calls != 0 or service.threshold_credits != threshold:
		return "추격 보스: 50% 이전 생성 또는 소수점·무료 작전 임계 오류"
	ledger.add_carried(1)
	if cost == 100:
		if service.triggered or not retry.get_active_targets().is_empty():
			return "생성 실패가 보스 1회 트리거를 소비함"
		ledger.spend_carried(1)
		ledger.add_carried(1)
		if retry.calls != 1 or not service.is_processing():
			return "임계 재도달이 재시도를 정지시키거나 주기를 우회함"
		service._process(1.1) # Retry without earning another credit.
	var targets: Array = spawner.get_active_targets()
	if targets.size() != 1 or not service.triggered or not targets[0].get_combat_identity()[&"is_boss"]:
		return "50% 회수 보스 역할·1회 생성 실패"
	var boss: Node2D = targets[0]
	if cost == 100:
		# Actual door collider, actual physics and contact damage, repeated after reopening.
		for cycle in 2:
			var door := DOOR.new()
			fixture.add_child(door)
			door.configure(player.global_position + Vector2(-80, 0), Vector2(16, 256))
			boss.global_position = player.global_position + Vector2(-180, 0)
			var hp_before := float(player.get_health_snapshot()[&"current"])
			for _frame in 105:
				await tree.physics_frame
			if boss.global_position.x < door.global_position.x or float(player.get_health_snapshot()[&"current"]) >= hp_before:
				return "문 봉쇄/재봉쇄 후 보스의 실제 이동·접촉 피해가 중단됨: %d" % cycle
			door.queue_free()
			await tree.process_frame
		if spawner.get_snapshot()[&"total_spawned"] != 0:
			return "추격 보스가 일반 방 생성 예산을 소비함"
	boss.take_damage(100000.0)
	await tree.process_frame
	await tree.process_frame
	ledger.add_carried(10000)
	service.force_evaluate(100000)
	var snapshot: Dictionary = service.get_snapshot()
	if metrics.boss_kills != 1 or snapshot[&"active_elite_count"] != 0 or snapshot[&"spawned_elite_count"] != 1:
		return "보스 처치 계측/누적 생성 수/추가 회수 후 재생성 방지 실패"
	if cost == 101:
		var next_ledger := LEDGER.new()
		fixture.add_child(next_ledger)
		var next_policy: Resource = POLICY.duplicate(true)
		next_policy.spawn_as_boss = false
		service.configure(player, next_ledger, retry, null, next_policy, 100, 10.0, 80003)
		ledger.add_carried(1000)
		if service.triggered:
			return "재구성한 추격 서비스가 이전 원장 신호를 소비함"
		next_ledger.add_carried(50)
		if not service.triggered or spawner.get_active_targets()[0].get_combat_identity()[&"is_boss"]:
			return "교체한 원장·일반 엘리트 정책이 적용되지 않음"
	fixture.queue_free()
	await tree.process_frame
	return ""
