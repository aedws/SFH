class_name DistrictEncounterSystem
extends "res://game/features/room_encounters/room_encounter_system.gd"
## Ordinary groups remain alive across spaces. Only deliberate objectives own barriers.
@export var terminal_radius := 110.0
var district_enabled := false
var patrol_groups: Dictionary = {}
var visited_patrols: Dictionary = {}
var patrol_grace: Dictionary = {}
var terminal_room := -1
var last_terminal_prompt := ""

func configure(p: Node2D, m: Node, s: Node, rewards: Node2D, c: Resource, tier: StringName) -> bool:
	if not super.configure(p,m,s,rewards,c,tier): return false
	district_enabled = m.has_method(&"get_district_snapshot") and bool(m.get_district_snapshot().enabled)
	if district_enabled and not s.has_method(&"get_snapshot"):
		return false
	patrol_groups.clear()
	visited_patrols.clear()
	patrol_grace.clear()
	queue_redraw()
	return true

func _process(delta: float) -> void:
	if not district_enabled:
		super._process(delta)
		return
	_update_contact_grace(delta)
	_update_patrols(delta)
	if active_room_index >= 0:
		_prune_active_enemies()
		if active_enemies.is_empty(): _complete_active_encounter()
	else:
		_try_start_current_room()
	_update_terminal()

func _try_start_current_room() -> void:
	if not district_enabled:
		super._try_start_current_room()
		return
	var region: Dictionary = map_provider.get_visibility_region(player.global_position)
	var index := int(region.get(&"room_index",-1))
	var room: Dictionary = room_definitions.get(index,{})
	if room.is_empty() or _room_is_excluded(room) or visited_patrols.has(index) or room.get(&"encounter","")=="objective": return
	if not (room.world_rect as Rect2).grow(-float(config.room_entry_inset)).has_point(player.global_position): return
	_spawn_patrol(index,room)

func _spawn_patrol(index: int, room: Dictionary) -> void:
	var minimum := int(tier_values.minimum_enemies)
	var population: Dictionary = enemy_spawner.get_snapshot()
	var capacity := maxi(0, int(population.maximum_active_enemies) - int(population.active_enemies))
	if capacity < minimum: return
	var reserve := 0
	for site: Dictionary in room_definitions.values():
		if site.get(&"encounter", "") == "objective" and not completed_rooms.has(site.room_index): reserve += minimum
	var amount := mini(maxi(0,int(enemy_spawner.get_remaining_spawn_budget())-reserve),roundi(random.randi_range(minimum,int(tier_values.maximum_enemies))*float(room.get(&"risk",1))))
	amount = mini(amount, capacity)
	if amount<minimum: return
	var safety := _spawn_safety_snapshot()
	var positions: PackedVector2Array = map_provider.get_room_spawn_positions(index,amount,player.global_position,float(safety.get(&"minimum_player_distance",0)))
	if positions.size()<minimum: return
	var members: Array[Node] = []
	for position in positions:
		var enemy: Node = enemy_spawner.spawn_enemy_at(position,StringName("district_%d"%index))
		if is_instance_valid(enemy):
			_apply_contact_grace(enemy,safety)
			members.append(enemy)
	if members.size() < minimum:
		for enemy in members: enemy.queue_free()
		return
	visited_patrols[index]=true
	patrol_groups[index]=members
	patrol_grace[index]=float(safety.get(&"contact_damage_grace_seconds",0))
	contact_grace_remaining = patrol_grace[index]
	encounter_started.emit(index,members.size())

func _update_patrols(delta: float) -> void:
	for index: int in patrol_groups.keys():
		var members: Array = patrol_groups[index]
		for i in range(members.size()-1,-1,-1):
			if not is_instance_valid(members[i]): members.remove_at(i)
		patrol_grace[index]=maxf(0,float(patrol_grace[index])-delta)
		if float(patrol_grace[index])<=0:
			for enemy: Node in members:
				if enemy.has_meta(&"room_contact_damage_enabled"):
					enemy.set("damage_enabled",enemy.get_meta(&"room_contact_damage_enabled"))
					enemy.remove_meta(&"room_contact_damage_enabled")
					if enemy is CanvasItem: enemy.modulate.a=1
		if members.is_empty():
			completed_rooms[index]=true
			patrol_groups.erase(index)
			patrol_grace.erase(index)
			encounter_cleared.emit(index)

func try_start_room(index: int, source: StringName = &"external") -> bool:
	if not district_enabled: return super.try_start_room(index,source)
	var room: Dictionary=room_definitions.get(index,{})
	if room.is_empty() or room.get(&"encounter","")!="objective" or source!=&"terminal": return false
	if player.global_position.distance_to(room.center)>terminal_radius: return false
	var population: Dictionary = enemy_spawner.get_snapshot()
	if int(population.maximum_active_enemies)-int(population.active_enemies)<int(tier_values.minimum_enemies): return false
	var previous_limit: int = tier_values.maximum_encounters
	var previous_maximum: int = tier_values.maximum_enemies
	tier_values.maximum_encounters = room_definitions.size()
	tier_values.maximum_enemies = mini(int(population.maximum_active_enemies)-int(population.active_enemies),roundi(previous_maximum*float(room.get(&"risk",1))))
	var accepted := super.try_start_room(index,source)
	tier_values.maximum_encounters = previous_limit
	tier_values.maximum_enemies = previous_maximum
	_update_terminal()
	return accepted

func is_patrol_room(index: int) -> bool:
	return district_enabled and room_definitions.get(index,{}).get(&"encounter","")=="patrol"

func _update_terminal() -> void:
	terminal_room=-1
	for index: int in room_definitions:
		var room: Dictionary=room_definitions[index]
		if room.get(&"encounter","")!="objective" or completed_rooms.has(index): continue
		if player.global_position.distance_to(room.center)<=terminal_radius:
			terminal_room=index
			break
	var prompt := "F · 금고 개방: 문 봉쇄·방어전·추가 보상" if terminal_room>=0 and active_room_index<0 else ""
	if prompt != last_terminal_prompt:
		last_terminal_prompt=prompt
		interaction_availability_changed.emit(not prompt.is_empty(),prompt)

func _unhandled_input(event: InputEvent) -> void:
	if district_enabled and active_room_index<0 and terminal_room>=0 and event.is_action_pressed(&"interact"):
		if not try_start_room(terminal_room,&"terminal"):
			interaction_availability_changed.emit(true,"금고 대기 · 주변 적을 줄이거나 남은 생성 예산을 확인하세요")
		get_viewport().set_input_as_handled()

func get_snapshot() -> Dictionary:
	var result := super.get_snapshot()
	if district_enabled:
		var count := 0
		for members: Array in patrol_groups.values(): count+=members.filter(func(enemy):return is_instance_valid(enemy)).size()
		result[&"policy"]=&"district_optional_lockdown"
		result[&"patrol_enemy_count"]=count
		result[&"patrol_group_count"]=patrol_groups.size()
		result[&"terminal_room"]=terminal_room
		result[&"all_encounters_completed"]=false
	return result

func _check_all_encounters_completed() -> void:
	if not district_enabled: super._check_all_encounters_completed()

func _draw() -> void:
	if not district_enabled: return
	for room: Dictionary in room_definitions.values():
		if room.get(&"encounter","")!="objective": continue
		var point: Vector2=room.center
		draw_rect(Rect2(point-Vector2(36,28),Vector2(72,56)),Color("f3bd67"),false,3)
		draw_circle(point+Vector2(0,-42),6,Color("f3bd67"))
