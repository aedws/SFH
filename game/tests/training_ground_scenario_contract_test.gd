extends SceneTree

const SERVICE_SCENE := preload("res://game/features/training_ground/training_ground_service.tscn")

var failures := PackedStringArray()


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var sandbox := Node2D.new()
	root.add_child(sandbox)
	var target := Node2D.new()
	target.add_to_group(&"player")
	sandbox.add_child(target)
	target.global_position = Vector2(-560.0, 0.0)
	var dummy_parent := Node2D.new()
	sandbox.add_child(dummy_parent)
	var service := SERVICE_SCENE.instantiate()
	sandbox.add_child(service)
	var rows: Array[Dictionary] = [
		{
			&"scenario_id": &"single_target", &"display_name": "단일 중장 더미",
			&"dummy_mode": "single", &"dummy_count": 1, &"dummy_health": 1000,
			&"dummy_armor": 25, &"measurement_seconds": 15,
			&"allow_free_loadout": true, &"restore_on_exit": true,
			&"source_status": &"provisional",
		},
		{
			&"scenario_id": &"dense_pack", &"display_name": "밀집 경량 더미",
			&"dummy_mode": "dense", &"dummy_count": 8, &"dummy_health": 240,
			&"dummy_armor": 8, &"measurement_seconds": 15,
			&"allow_free_loadout": true, &"restore_on_exit": true,
			&"source_status": &"provisional",
		},
	]
	_check(service.call(&"configure", target, dummy_parent, rows,
		load("res://game/features/training_ground/configs/default_training_ground.tres")), "서비스 구성")
	var single: Dictionary = service.call(&"activate_scenario", &"single_target")
	_check(bool(single.get(&"success", false)) and int(single.get(&"dummy_count", 0)) == 1, "단일 보스 더미 생성")
	var single_targets: Array = service.call(&"get_active_targets")
	_check(single_targets.size() == 1 and bool(single_targets[0].get_meta(&"training_dummy", false)), "훈련 대상 태그")
	_check(single_targets[0].call(&"get_combat_identity").get(&"is_boss", false), "단일 보스 역할")
	var health: Node = single_targets[0].get_node("HealthComponent")
	var armor: Node = single_targets[0].get_node("ArmorComponent")
	_check(is_equal_approx(float(health.get("maximum_value")), 1000.0), "단일 체력 반영")
	_check(is_equal_approx(float(armor.get("maximum_value")), 25.0), "단일 방어 반영")

	var dense: Dictionary = service.call(&"activate_scenario", &"dense_pack")
	var dense_targets: Array = service.call(&"get_active_targets")
	_check(bool(dense.get(&"success", false)) and dense_targets.size() == 8, "밀집 8기 즉시 전환")
	_check(_minimum_spacing(dense_targets) >= 75.0, "밀집 더미 비겹침")
	var policy: Resource = load("res://game/features/smart_targeting/configs/default_smart_targeting.tres")
	var densest: Dictionary = policy.call(&"resolve", &"densest", target.global_position, dense_targets, 1200.0)
	_check(is_instance_valid(densest.get(&"target")) and densest.get(&"target_point") != target.global_position, "광역 밀집 타게팅")
	_check(int(service.call(&"get_snapshot").get(&"general_spawn_budget_impact", -1)) == 0, "일반 스폰 예산 비간섭")

	var reset_before := int(service.call(&"get_snapshot").get(&"reset_revision", 0))
	for dummy in dense_targets:
		if is_instance_valid(dummy):
			dummy.call(&"take_damage", 99999.0)
	await create_timer(0.55).timeout
	var reset_snapshot: Dictionary = service.call(&"get_snapshot")
	_check(int(reset_snapshot.get(&"active_count", 0)) == 8, "전멸 후 자동 초기화")
	_check(int(reset_snapshot.get(&"reset_revision", 0)) == reset_before + 1, "초기화 리비전")

	var manual_reset: Dictionary = service.call(&"reset_active_scenario")
	_check(bool(manual_reset.get(&"success", false)) and int(manual_reset.get(&"dummy_count", 0)) == 8, "수동 초기화")
	var stopped: Dictionary = service.call(&"stop")
	_check(bool(stopped.get(&"success", false)) and service.call(&"get_active_targets").is_empty(), "종료 시 제거")

	var disabled_manifest: Resource = load("res://game/core/feature_manifest.tres").duplicate(true)
	disabled_manifest.set("training_ground_enabled", false)
	disabled_manifest.set("training_ground_config_path", "res://removed/training_ground.tres")
	_check((disabled_manifest.call(&"validation_errors") as PackedStringArray).is_empty(), "훈련장 물리 제거 가능")

	if failures.is_empty():
		print("P8_TRAINING_GROUND_OK scenario_resource single_boss dense_8 no_overlap smart_targeting reset_service auto_reset spawn_budget_isolated optional_module")
		quit(0)
	else:
		print("P8_TRAINING_GROUND_FAILED: %s" % " / ".join(failures))
		quit(1)


func _minimum_spacing(targets: Array) -> float:
	var minimum := INF
	for first in targets.size():
		for second in range(first + 1, targets.size()):
			minimum = minf(minimum, (targets[first] as Node2D).global_position.distance_to(
				(targets[second] as Node2D).global_position))
	return minimum


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
