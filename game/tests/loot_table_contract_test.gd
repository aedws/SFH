extends SceneTree


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var file := FileAccess.open("res://game/features/loot_tables/data/loot_table.csv", FileAccess.READ)
	var parsed := LootTable.parse(file.get_as_text() if file != null else "")
	var errors: PackedStringArray = parsed.get(&"errors", PackedStringArray())
	var entries: Array = parsed.get(&"data", [])
	if not errors.is_empty() or entries.size() != 77:
		_fail("rows=%d errors=%s" % [entries.size(), " / ".join(errors)])
		return
	var lifecycle_scene := load("res://game/features/loot_lifecycle/loot_lifecycle_service.tscn") as PackedScene
	var lifecycle := lifecycle_scene.instantiate()
	root.add_child(lifecycle)
	await process_frame
	if not lifecycle.call(&"configure", load("res://game/features/loot_lifecycle/configs/default_loot_lifecycle.tres")):
		_fail("생명 주기 제공자 구성 실패")
		return
	var provider_scene := load("res://game/features/loot_tables/loot_table_provider.tscn") as PackedScene
	var provider := provider_scene.instantiate()
	root.add_child(provider)
	await process_frame
	var equip_catalog := load(
		"res://game/features/field_loot/configs/default_field_loot_equipment.tres"
	)
	if not provider.call(
		&"configure",
		load("res://game/features/loot_tables/configs/default_loot_table.tres"),
		lifecycle,
		equip_catalog
	):
		_fail("드랍 제공자 구성 실패")
		return
	var standard := {
		&"region_id": &"research_complex", &"difficulty_id": &"standard",
		&"map_size": &"small", &"source_type": &"any",
		&"high_grade_drop_multiplier": 1.0, &"boss_available": true,
	}
	var nightmare := standard.duplicate(true)
	nightmare[&"difficulty_id"] = &"nightmare"
	nightmare[&"map_size"] = &"large"
	nightmare[&"high_grade_drop_multiplier"] = 1.5
	var standard_candidates: Array = provider.call(&"get_candidates", standard)
	var nightmare_candidates: Array = provider.call(&"get_candidates", nightmare)
	if standard_candidates.is_empty() or nightmare_candidates.size() <= standard_candidates.size():
		_fail("난이도·맵 조건 후보 확장 실패")
		return
	for candidate: Dictionary in nightmare_candidates:
		if candidate[&"region_id"] != &"research_complex":
			_fail("지역 격리 실패")
			return
	var first: Dictionary = provider.call(&"roll_drop", nightmare, 8675309, 12)
	var repeated: Dictionary = provider.call(&"roll_drop", nightmare, 8675309, 12)
	if first != repeated or first.is_empty():
		_fail("동일 시드 결정성 실패")
		return
	var standard_grade_total := 0
	var nightmare_grade_total := 0
	for index in range(400):
		standard_grade_total += int(provider.call(&"roll_drop", standard, 4200, index).get(&"grade", 0))
		nightmare_grade_total += int(provider.call(&"roll_drop", nightmare, 4200, index).get(&"grade", 0))
	if nightmare_grade_total <= standard_grade_total:
		_fail("고난도 고등급 가중치 인지 실패")
		return
	var briefing: Dictionary = provider.call(&"get_briefing", nightmare)
	if (
		int(briefing.get(&"candidate_count", 0)) != nightmare_candidates.size()
		or (briefing.get(&"target_item_labels", PackedStringArray()) as PackedStringArray).size() != 3
		or int(briefing.get(&"highest_grade", 0)) < 5
	):
		_fail("작전 브리핑 요약 실패")
		return
	var industrial := standard.duplicate(true)
	industrial[&"region_id"] = &"industrial_district"
	industrial[&"difficulty_id"] = &"veteran"
	industrial[&"map_size"] = &"medium"
	industrial[&"source_type"] = &"room_reward"
	var industrial_ids: Array = provider.call(&"get_candidates", industrial).map(func(row): return row[&"item_id"])
	if "pulse_rifle" not in industrial_ids:
		_fail("Weapon 탭 기반 현장 장비가 산업 지구 드랍 후보에 연결되지 않았습니다.")
		return
	var skill_region := industrial.duplicate(true)
	skill_region[&"region_id"] = &"research_complex"
	var skill_ids: Array = provider.call(&"get_candidates", skill_region).map(func(row): return row[&"item_id"])
	if "arc_dash" not in skill_ids:
		_fail("Skill 탭 기반 현장 스킬이 연구 단지 드랍 후보에 연결되지 않았습니다.")
		return
	print("LOOT_TABLE_TEST_OK rows_77 regions_3 deterministic_rolls difficulty_grade_bias player_briefing lifecycle_link weapon_definition_link skill_definition_link")
	quit(0)


func _fail(message: String) -> void:
	push_error("LOOT_TABLE_TEST_FAILED %s" % message)
	quit(1)
