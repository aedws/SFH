extends SceneTree
## Same pure topology as the game; fixtures gate the browser implementation.
const OUTPUT := "res://docs/assets/map-catalog.json"
func _initialize() -> void:
	var catalog := {"schema":1,"version":FileAccess.get_file_as_string("res://game/features/balance_data/data_version.txt").strip_edges(),"regions":[],"tiers":{},"facilities":preload("res://game/features/map_generation/facility_catalog.gd").new().get_rows(),"fixtures":[],"sources":{}}
	var contracts: Resource = load("res://game/features/operation_contract/configs/default_operation_contracts.tres")
	for row: Dictionary in contracts.regions:
		catalog.regions.append({"id":row.region_id,"name":row.display_name})
	var files := ["game/features/map_generation/regional_district_plan.gd","game/features/map_generation/facility_catalog.gd","game/features/map_generation/data/facility.csv","game/features/operation_contract/configs/default_operation_contracts.tres","game/features/balance_data/data_version.txt","scripts/export_map_catalog.gd"]
	files.append("game/features/map_generation/urban_block_layout.gd")
	files.append("game/features/map_generation/district_map_generator.gd")
	files.append("game/features/map_generation/map_generator.tscn")
	var provider=load("res://game/features/map_generation/map_generator.tscn").instantiate()
	for tier in ["small","medium","large"]:
		var path := "game/features/map_generation/configs/%s.tres" % tier
		files.append(path)
		var config: Resource = load("res://"+path)
		catalog.tiers[tier]={"minimum_rooms":config.minimum_rooms,"maximum_rooms":config.maximum_rooms,"minimum_size":[config.minimum_room_size.x,config.minimum_room_size.y],"maximum_size":[config.maximum_room_size.x,config.maximum_room_size.y]}
		catalog.tiers[tier]["urban_enabled"]=provider.urban_city_enabled
		catalog.tiers[tier]["urban"]=provider.urban_layout.settings()
		for region: Dictionary in catalog.regions:
			for seed_value in [1,90808,2147483646]:
				catalog.fixtures.append({"tier":tier,"plan":preload("res://game/features/map_generation/regional_district_plan.gd").new().build(catalog.tiers[tier],region.id,seed_value,catalog.facilities)})
	provider.free()
	for path in files:
		catalog.sources[path]=FileAccess.get_file_as_string("res://"+path).replace("\r\n","\n").sha256_text()
	var fixtures: Array=catalog.fixtures
	catalog.erase("fixtures")
	# Test-only snapshots must not add half a megabyte to either role page.
	DirAccess.make_dir_recursive_absolute("res://scripts/fixtures")
	if not _write("res://scripts/fixtures/regional-map.json",fixtures) or not _write(OUTPUT,catalog): quit(1); return
	print("MAP_CATALOG_OK 27 Godot fixtures")
	quit()

func _write(path: String, value: Variant) -> bool:
	var result := JSON.stringify(value,"\t",true,true)+"\n"
	if path.contains("/fixtures/"):
		var plans := PackedStringArray()
		for plan in value: plans.append(JSON.stringify(plan,"",true,true))
		result = "[\n"+",\n".join(plans)+"\n]\n"
	if "--check" in OS.get_cmdline_user_args():
		if FileAccess.get_file_as_string(path).replace("\r\n","\n") != result: push_error("Stale map catalog: "+path); return false
	else: FileAccess.open(path,FileAccess.WRITE).store_string(result)
	return true
