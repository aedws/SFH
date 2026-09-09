extends SceneTree
const MAP := preload("res://game/features/map_generation/map_generator.tscn")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value: failures.append(message); push_error(message)
func run() -> void:
	var catalog := preload("res://game/features/operation_contract/difficulty_catalog.gd").new()
	check(catalog.rows.size()==10,"ten validated levels: "+catalog.error)
	var before := catalog.get_rows()
	check(not catalog.load_csv("broken") and catalog.get_rows()==before,"invalid live input retains last good rows")
	var profile := preload("res://game/features/persistent_profile/persistent_profile.gd").new()
	profile.persistence_enabled=false
	profile.banked_credits=1000000
	profile.unlock_ids.assign([&"region_ruined_city",&"region_industrial_district",&"region_research_complex"])
	root.add_child(profile)
	var service := preload("res://game/features/operation_contract/operation_contract_service.gd").new()
	root.add_child(service)
	check(service.configure(profile,load("res://game/features/operation_contract/configs/default_operation_contracts.tres")),"contract setup")
	var last := 0
	var small: Resource=load("res://game/features/map_generation/configs/small.tres")
	for row: Dictionary in before:
		check(service.select_difficulty(row.difficulty_id),"select each level")
		var quote: Dictionary=service.quote(small)
		check(quote.entry_cost>last and quote.difficulty_level==row.level,"entry cost grows with level")
		last=quote.entry_cost
		var equipped: Dictionary=service.quote(small,{}, {&"additional_entry_cost":350})
		check(equipped.difficulty_level==quote.difficulty_level and equipped.entry_cost==quote.entry_cost+350,"equipment does not secretly change difficulty")
		var band: StringName=preload("res://game/features/operation_contract/difficulty_catalog.gd").loot_band(row.difficulty_id)
		check(band==row.loot_band,"legacy drop band")
	check(not service.select_difficulty(&"level_11"),"unknown level rejected")
	check(service.invest(small).success,"invest level ten")
	var frozen: Dictionary=service.active_contract.duplicate(true)
	var changed := catalog.get_rows()
	changed[9].map_geometry.polygon_ratio=0.2
	service.set_difficulty_rows(changed)
	check(service.active_contract==frozen and service.quote(small).map_geometry.polygon_ratio==0.2,"next quote changes but active contract frozen")
	service.free()
	profile.free()
	var cases := 0
	for tier in ["small","medium","large"]:
		for region in ["ruined_city","industrial_district","research_complex"]:
			for difficulty: Dictionary in catalog.get_rows():
				var map: Node2D = MAP.instantiate()
				root.add_child(map)
				map.set_region_context(region)
				map.set_operation_context({&"map_geometry":difficulty.map_geometry})
				map.generate(load("res://game/features/map_generation/configs/%s.tres" % tier),902+int(difficulty.level))
				var label := "%s/%s/%d" % [tier,region,difficulty.level]
				check(map.district.has("room_cells"),label+" compound enabled")
				var deep := 0
				for index in map.rooms.size():
					var room: Rect2i=map.rooms[index]
					var center: Vector2=(Vector2(room.get_center())+Vector2.ONE*0.5)*map.cell_size
					check(not map.get_world_path(map.start_position,center).is_empty(),label+" room reachable "+str(index))
					check(map.room_contains_cell(index,room.get_center()),label+" center occupied")
					check(map.district.room_cells[index].size()<room.get_area(),label+" non rectangular")
					if int(map.district.depths.get(index,0))>0: deep+=1
					for position: Vector2 in map.get_room_spawn_positions(index,12):
						var cell := Vector2i((position/float(map.cell_size)).floor())
						check(map.room_contains_cell(index,cell) and not map.obstacle_cells.has(cell),label+" spawn inside")
				check(deep>=map.rooms.size()/3,label+" inner facilities not all road fronts")
				for point: Dictionary in map.get_loot_spawn_points(12):
					check(map.get_visibility_region(point.position).room_index>=0,label+" loot belongs to actual room")
				for exit: Dictionary in map.get_extraction_candidates():
					check(not map.get_world_path(map.start_position,exit.position).is_empty(),label+" exit reachable")
				if difficulty.level in [1,10]:
					var field := preload("res://game/features/fog_of_war/space_visibility_field.gd").new()
					field.configure(map.get_fog_geometry())
					field.configure_spaces(map.get_visibility_spaces())
					field.update(map.start_position,20,{})
					var first: Rect2i=map.rooms[0]
					for y in range(first.position.y,first.end.y):
						for x in range(first.position.x,first.end.x):
							var cell := Vector2i(x,y)
							if map.floor_cells.has(cell) and not map.room_contains_cell(0,cell): check(not field.visible_cells.has(cell),label+" cutout floor not revealed as room")
				cases+=1
				map.free()
				if not failures.is_empty(): quit(1); return
	print("COMPOUND_DIFFICULTY_OK ",cases," region/tier/level maps; geometry/spawn/loot/exits")
	quit(0 if failures.is_empty() else 1)
