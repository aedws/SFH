extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func _run() -> void:
	var catalog := preload("res://game/features/map_generation/facility_catalog.gd").new()
	var csv := preload("res://game/features/map_generation/data/facility_payload.tres").csv_text
	var initial := catalog.get_rows()
	var custom=preload("res://game/features/map_generation/regional_district_plan.gd").new().build({"minimum_rooms":18,"maximum_rooms":24,"minimum_size":[42,25],"maximum_size":[54,34],"urban":{"avenue_width":999,"entrance_width":1}},"ruined_city",1,initial)
	check(custom.urban_settings=={"avenue_width":20,"local_width":10,"sidewalk_width":3,"entrance_width":3},"partial city options default and clamp")
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
			check(plan.version==2 and plan.yards.is_empty() and plan.compound_count>0,"B closed compounds replace all-around yards")
			check(plan.street_axes.any(func(a): return a.width==14) and plan.street_axes.any(func(a): return a.width==10),"avenues and local streets")
			var view=preload("res://game/features/minimap/minimap_view.gd").new()
			root.add_child(view)
			view.configure(map.get_minimap_snapshot(),null)
			var mini_image: Image=view.map_texture.get_image()
			var street_pixel: Vector2i=Vector2i(int(plan.streets[0][0])+3,int(plan.streets[0][1])+3)-view.cell_bounds.position
			var room_pixel: Vector2i=map.rooms[0].get_center()-view.cell_bounds.position
			check(mini_image.get_pixelv(street_pixel).is_equal_approx(view.street_color),"minimap streets readable")
			var actual_color:=mini_image.get_pixelv(room_pixel)
			check(absf(actual_color.r-view.floor_color.r)<=1.0/255 and absf(actual_color.g-view.floor_color.g)<=1.0/255 and absf(actual_color.b-view.floor_color.b)<=1.0/255,"minimap buildings distinct from streets %s expected %s"%[actual_color,view.floor_color])
			view.free()
			for building: Dictionary in plan.buildings:
				var lot: Array=building.lot
				var exterior := Vector2i(int(lot[0])+1,int(lot[1])+1)
				check(not map.floor_cells.has(exterior),"unused lot is closed rather than a universal bypass")
			# A former rectangle corner can now be an intentional connecting passage.
			# Validate actual generated boundary strips, not obsolete AABB corner assumptions.
			check(not map.wall_cells.is_empty(),"actual irregular walls exist")
			for wall: Vector2i in map.wall_cells.keys().slice(0,100):
				check(not map.is_walkable_world_position((Vector2(wall)+Vector2.ONE*0.5)*map.cell_size),"actual boundary blocks traversal")
			var expected := {"ruined_city":"transit_square","industrial_district":"warehouse","research_complex":"medical"}
			check(plan.buildings.any(func(b): return b.required and b.facility_id==expected[region]),"regional anchor required")
			check(plan.buildings.any(func(b): return b.required and b.facility_id=="workshop"),"safe relay type present")
			var objectives := 0
			for room: Dictionary in map.get_room_encounter_snapshot():
				check(room.doorways.size()>0,"actual irregular portal boundary exists")
				check(not map.get_world_path(map.start_position,room.center).is_empty(),"all actual facilities reachable")
				objectives += int(room.encounter=="objective")
			check(objectives==1 and map.get_extraction_candidates().size()==2,"one vault two exits")
			var returned: Dictionary=map.get_regional_plan()
			returned.buildings.clear()
			check(not map.get_regional_plan().buildings.is_empty(),"public snapshot detached")
			map.urban_city_enabled=false
			map.generate(load("res://game/features/map_generation/configs/%s.tres"%tier),90808)
			check(map.get_regional_plan().version==1 and not map.urban_visual.visible,"city presentation removable")
			map.urban_city_enabled=true
			map.regional_landmarks_enabled=false
			map.generate(load("res://game/features/map_generation/configs/%s.tres"%tier),90808)
			check(map.get_regional_plan().is_empty() and not map.rooms.is_empty(),"legacy random provider switch")
			map.free()
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("REGIONAL_MAP_OK 9 regional_tiers actual_paths doors vault exits last_good snapshot_isolation legacy_switch")
	quit(0 if failures.is_empty() else 1)
