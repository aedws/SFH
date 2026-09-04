extends SceneTree

const GAME_SCENE := preload("res://game/scenes/game.tscn")

var failures := PackedStringArray()


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var game = GAME_SCENE.instantiate()
	root.add_child(game)
	for _frame in 6:
		await process_frame
	_check(is_instance_valid(game.start_hub), "기본 거점 진입")
	_check(is_instance_valid(game.training_ground_service), "거점 훈련장 설치")
	_check(is_instance_valid(game.auto_weapon), "거점 훈련용 무기 설치")
	_check(game.enemy_spawner == null, "일반 적 생성기 미설치")

	var station: Node2D
	for candidate in get_nodes_in_group(&"hub_service_station"):
		if candidate.get("service_id") == &"training":
			station = candidate as Node2D
			break
	_check(is_instance_valid(station), "훈련 단말 표시")
	if is_instance_valid(station):
		game.player.global_position = station.global_position
		_check(bool(station.call(&"request_service", game.player)), "F 상호작용 경로")
		await process_frame

	var first: Dictionary = game.training_ground_service.call(&"get_snapshot")
	_check(first.get(&"active_scenario_id", &"") == &"single_target", "첫 상호작용 단일 시나리오")
	_check(int(first.get(&"active_count", 0)) == 1, "단일 더미 1기")
	var targets: Array = game.training_ground_service.call(&"get_active_targets")
	var target: Node2D = targets[0] if not targets.is_empty() else null
	var before_vitality := 0.0
	if is_instance_valid(target):
		game.player.global_position = target.global_position + Vector2(-150.0, 0.0)
		before_vitality = (
			float(target.get_node("HealthComponent").get("current_value"))
			+ float(target.get_node("ArmorComponent").get("current_value"))
		)
		Input.action_press(&"primary_attack")
		await create_timer(0.45).timeout
		Input.action_release(&"primary_attack")
		await process_frame
		_check(
			(
				float(target.get_node("HealthComponent").get("current_value"))
				+ float(target.get_node("ArmorComponent").get("current_value"))
			) < before_vitality,
			"실제 좌클릭 투사체 피해"
		)
		_check(
			int(game.p5_hub_progression_service.call(&"get_snapshot").get(&"training", {}).get(&"hit_count", 0)) > 0,
			"실제 피해 텔레메트리 전달"
		)
		_check("훈련 타격" in game.status_label.text and "피해" in game.status_label.text, "타격 즉시 화면 피드백")

	if is_instance_valid(station):
		game.player.global_position = station.global_position + Vector2(float(station.get("interaction_radius")) + 12.0, 0.0)
		station.set("actor", game.player)
		_check(bool(station.call(&"request_service", game.player)), "두 번째 F 전환")
		await process_frame
	var second: Dictionary = game.training_ground_service.call(&"get_snapshot")
	_check(second.get(&"active_scenario_id", &"") == &"dense_pack", "밀집 시나리오 즉시 전환")
	_check(int(second.get(&"active_count", 0)) == 8, "밀집 더미 8기")
	_check(int(second.get(&"general_spawn_budget_impact", -1)) == 0, "일반 스폰 비간섭 표시")
	_check(int(game.defeated_enemies) == 0, "훈련 피해가 작전 처치에 미반영")

	game.call(&"_clear_start_hub")
	await process_frame
	_check(game.training_ground_service == null and game.auto_weapon == null, "거점 이탈 훈련 런타임 제거")

	if failures.is_empty():
		print("E2E_P8_TRAINING_GROUND_OK hub_station interaction single_attack_telemetry dense_switch spawn_isolation hub_exit_cleanup")
		quit(0)
	else:
		print("E2E_P8_TRAINING_GROUND_FAILED: %s" % " / ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
