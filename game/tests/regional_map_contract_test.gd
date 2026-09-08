extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func _run() -> void:
	var catalog := preload("res://game/features/map_generation/facility_catalog.gd").new()
	var csv := preload("res://game/features/map_generation/data/facility_payload.tres").csv_text
	var initial := catalog.get_rows()
	for invalid in [csv.replace("*,center","none,center"),csv.replace(",horizontal,1",",horizontal,-1"),csv.replace(",east,",",invalid,")]:
		check(not catalog.load_csv(invalid) and catalog.get_rows()==initial,"invalid rows atomic last-good preservation")
	for tier in ["small","medium","large"]:
		for region in ["ruined_city","industrial_district","research_complex"]:
			var map=load("res://game/features/map_generation/map_generator.tscn").instantiate()
			root.add_child(map)
			map.set_region_context(region)
			map.set_facility_rows(catalog.get_rows())
			map.generate(load("res://game/features/map_generation/configs/%s.tres"%tier),90808)
			var plan: Dictionary=map.get_regional_plan()
			check(plan.region==region,"region propagated")
			var expected := {"ruined_city":"transit_square","industrial_district":"warehouse","research_complex":"medical"}
			check(plan.buildings.any(func(b): return b.required and b.facility_id==expected[region]),"regional anchor required")
			check(plan.buildings.any(func(b): return b.required and b.facility_id=="workshop"),"safe relay type present")
			var objectives := 0
			for room: Dictionary in map.get_room_encounter_snapshot():
				check(room.open_directions.size()>=2,"two doors")
				check(not map.get_world_path(map.start_position,room.center).is_empty(),"all actual facilities reachable")
				objectives += int(room.encounter=="objective")
			check(objectives==1 and map.get_extraction_candidates().size()==2,"one vault two exits")
			var returned: Dictionary=map.get_regional_plan()
			returned.buildings.clear()
			check(not map.get_regional_plan().buildings.is_empty(),"public snapshot detached")
			map.regional_landmarks_enabled=false
			map.generate(load("res://game/features/map_generation/configs/%s.tres"%tier),90808)
			check(map.get_regional_plan().is_empty() and not map.rooms.is_empty(),"legacy random provider switch")
			map.free()
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("REGIONAL_MAP_OK 9 regional_tiers actual_paths doors vault exits last_good snapshot_isolation legacy_switch")
	quit(0 if failures.is_empty() else 1)
