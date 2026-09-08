class_name ExtractionDistrictMapGenerator
extends "res://game/features/map_generation/map_generator.gd"
## Alternate provider; all legacy map consumers retain their public contracts.
@export var district_layout_enabled := true
@export var warp_facility_ids := PackedStringArray(["workshop"])
@export var district_layout: Resource = preload("res://game/features/map_generation/district_layout.gd").new()
var district: Dictionary = {}
var facility_rows: Array[Dictionary] = []
var facility_metadata: Dictionary = {}
var exit_rooms: Array[int] = []
@export var regional_landmarks_enabled := true
var region_id := "ruined_city"
var regional_plan: Dictionary = {}

func set_region_context(region: StringName) -> void:
	region_id = String(region)

func get_regional_plan() -> Dictionary:
	return regional_plan.duplicate(true)

func _generate_connected_rooms(count: int) -> void:
	regional_plan.clear()
	if not district_layout_enabled:
		super._generate_connected_rooms(count)
		return
	if regional_landmarks_enabled:
		var source := facility_rows
		if source.is_empty(): source = preload("res://game/features/map_generation/facility_catalog.gd").new().get_rows()
		var config := {"minimum_rooms":tier_config.minimum_rooms,"maximum_rooms":tier_config.maximum_rooms,"minimum_size":[tier_config.minimum_room_size.x,tier_config.minimum_room_size.y],"maximum_size":[tier_config.maximum_room_size.x,tier_config.maximum_room_size.y]}
		regional_plan = preload("res://game/features/map_generation/regional_district_plan.gd").new().build(config,region_id,used_seed,source)
		# Invalid future tier capacity must not strand the player during operation entry.
		district = district_layout.from_regional_plan(regional_plan) if not regional_plan.is_empty() else district_layout.build(tier_config,random,count)
	else:
		district = district_layout.build(tier_config,random,count)
	rooms.assign(district.rooms)
	floor_cells = district.floor_cells.duplicate()

func _assign_landmarks() -> void:
	if not district_layout_enabled:
		super._assign_landmarks()
		return
	start_position = _cell_center(_room_center_cell(rooms[0]))
	extraction_room_index = rooms.size()-1
	extraction_position = _cell_center(_room_center_cell(rooms[extraction_room_index]))
	exit_rooms.assign([extraction_room_index,mini(int(district.columns)-1,rooms.size()-2)])
	facility_metadata.clear()
	var center := Vector2(float(district.columns-1)*0.5,float(district.rows-1)*0.5)
	var vault_index := -1
	var nearest := INF
	for index in rooms.size():
		if index == 0 or index in exit_rooms: continue
		var distance := Vector2(district.plots[index]).distance_to(center)
		if distance < nearest:
			nearest=distance
			vault_index=index
	var source := facility_rows
	if source.is_empty(): source = preload("res://game/features/map_generation/facility_catalog.gd").new().get_rows()
	var ordinary: Array[Dictionary] = []
	var vault: Dictionary = {}
	for row in source:
		if row.encounter == "objective": vault=row
		else: ordinary.append(row)
	for index in rooms.size():
		var row: Dictionary = vault if index == vault_index else ordinary[random.randi_range(0,ordinary.size()-1)]
		if not regional_plan.is_empty():
			for candidate: Dictionary in source:
				if candidate.facility_id == regional_plan.buildings[index].facility_id: row = candidate; break
		var inner := 1.0-clampf(Vector2(district.plots[index]).distance_to(center)/maxf(1,center.length()),0,1)
		facility_metadata[index] = row.duplicate(true)
		facility_metadata[index][&"risk"] = 1.0 + inner * float(row.risk_bonus)
		facility_metadata[index][&"room_index"] = index
		facility_metadata[index][&"required_landmark"] = not regional_plan.is_empty() and bool(regional_plan.buildings[index].required)

func get_district_snapshot() -> Dictionary:
	return {&"enabled":district_layout_enabled,&"facilities":facility_metadata.duplicate(true),&"exit_rooms":exit_rooms.duplicate(),&"street_cycles":int(district.get(&"columns",0))*int(district.get(&"rows",0)),&"early_extraction":district_layout_enabled,&"warp_policy":&"terminal_only"}

func set_facility_rows(rows_data: Array[Dictionary]) -> void:
	facility_rows = rows_data.duplicate(true)

func _select_loot_room() -> int:
	if not district_layout_enabled: return super._select_loot_room()
	var total := 0.0
	for index: int in facility_metadata:
		if index != 0 and index not in exit_rooms: total += float(facility_metadata[index].cache_weight)
	var choice := random.randf() * total
	for index: int in facility_metadata:
		if index == 0 or index in exit_rooms: continue
		choice -= float(facility_metadata[index].cache_weight)
		if choice <= 0: return index
	return 1

func get_minimap_snapshot() -> Dictionary:
	var result := super.get_minimap_snapshot()
	result[&"extraction_candidates"] = get_extraction_candidates()
	return result

func get_room_encounter_snapshot() -> Array[Dictionary]:
	var result := super.get_room_encounter_snapshot()
	if not district_layout_enabled: return result
	for room in result:
		var index: int = room.room_index
		room.merge(facility_metadata.get(index,{}),true)
		room[&"is_extraction_room"] = index in exit_rooms
		room[&"district"] = true
		room[&"warp_terminal"] = index == 0 or (index not in exit_rooms and room.get(&"facility_id", "") in warp_facility_ids)
	return result

func get_warp_policy() -> Dictionary:
	return {&"terminal_only": district_layout_enabled}

func get_extraction_candidates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not district_layout_enabled: return result
	for index in exit_rooms:
		result.append({&"position":_cell_center(_room_center_cell(rooms[index])),&"room_index":index,&"label":"외곽 탈출 %d" % (result.size()+1)})
	return result

func get_visibility_spaces() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if district_layout_enabled:
		for source: Dictionary in district.spaces:
			var row := source.duplicate()
			row[&"world_rect"] = Rect2(Vector2(source.cell_rect.position)*cell_size,Vector2(source.cell_rect.size)*cell_size)
			result.append(row)
	else:
		for index in rooms.size(): result.append({&"space_id":index,&"world_rect":_room_world_rect(rooms[index],false),&"kind":&"room",&"room_index":index})
	return result

func _draw() -> void:
	super._draw()
	if not district_layout_enabled: return
	for index: int in facility_metadata:
		var room := _room_world_rect(rooms[index],false)
		var data: Dictionary = facility_metadata[index]
		var tint := Color("f0b961") if data.encounter == "objective" else Color("3d8b94")
		draw_rect(room.grow(-24),Color(tint,0.035))
		draw_line(room.position+Vector2(64,36),room.position+Vector2(minf(360,room.size.x-64),36),tint,6)
		draw_string(ThemeDB.fallback_font,room.position+Vector2(64,72),String(data.get("display_name", "시설")),HORIZONTAL_ALIGNMENT_LEFT,400,26,tint)
		if index == 0 or (index not in exit_rooms and data.facility_id in warp_facility_ids):
			var point := _cell_center(_room_center_cell(rooms[index]))
			draw_arc(point,48,0,TAU,24,Color("02e5e1"),3)
			draw_string(ThemeDB.fallback_font,point+Vector2(-40,-64),"RELAY / M",HORIZONTAL_ALIGNMENT_LEFT,180,20,Color("02e5e1"))
