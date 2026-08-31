class_name RoomEncounterSystem
extends Node2D

signal encounter_started(room_index: int, enemy_count: int)
signal doors_locked(room_index: int, door_count: int)
signal encounter_cleared(room_index: int)
signal all_encounters_completed(completed_count: int, required_count: int)
signal reward_spawned(room_index: int, box_count: int, total_credits: int)
signal reward_collected(room_index: int, credit_amount: int)
signal interaction_availability_changed(available: bool, prompt: String)

const DOOR_BARRIER_SCRIPT := preload(
	"res://game/features/room_encounters/room_door_barrier.gd"
)
const REWARD_SCENE := preload(
	"res://game/features/room_encounters/room_credit_reward_box.tscn"
)
const MAP_METHODS := [
	&"get_visibility_region", &"get_room_encounter_snapshot", &"get_room_spawn_positions",
]
const SPAWNER_METHODS := [
	&"spawn_enemy_at", &"set_reinforcement_paused", &"get_remaining_spawn_budget",
]

var player: Node2D
var map_provider: Node
var enemy_spawner: Node
var reward_parent: Node2D
var config: Resource
var tier_id: StringName = &"small"
var tier_values: Dictionary = {}
var room_definitions: Dictionary = {}
var completed_rooms: Dictionary = {}
var active_room_index: int = -1
var active_enemies: Array[Node] = []
var active_doors: Array[Node] = []
var active_rewards: Array[Node] = []
var rewards_spawned: int = 0
var rewards_collected: int = 0
var last_cleared_room_index: int = -1
var last_requested_enemy_count: int = 0
var last_spawned_enemy_count: int = 0
var last_trigger_source: StringName = &"none"
var completion_announced: bool = false
var last_reward_box_count: int = 0
var last_reward_total_credits: int = 0
var last_reward_size_ratio: float = 0.0
var random := RandomNumberGenerator.new()


func configure(
	new_player: Node2D,
	new_map_provider: Node,
	new_enemy_spawner: Node,
	new_reward_parent: Node2D,
	new_config: Resource,
	new_tier_id: StringName
) -> bool:
	if (
		not is_instance_valid(new_player)
		or not _supports_methods(new_map_provider, MAP_METHODS)
		or not _supports_methods(new_enemy_spawner, SPAWNER_METHODS)
		or not is_instance_valid(new_reward_parent)
		or new_config == null
		or not new_config.has_method(&"is_valid")
		or not bool(new_config.call(&"is_valid"))
	):
		return false
	player = new_player
	map_provider = new_map_provider
	enemy_spawner = new_enemy_spawner
	reward_parent = new_reward_parent
	config = new_config
	tier_id = new_tier_id
	tier_values = config.call(&"values_for", tier_id)
	room_definitions.clear()
	for room: Dictionary in map_provider.call(&"get_room_encounter_snapshot"):
		room_definitions[int(room[&"room_index"])] = room
	completed_rooms.clear()
	active_room_index = -1
	active_enemies.clear()
	active_rewards.clear()
	rewards_spawned = 0
	rewards_collected = 0
	last_cleared_room_index = -1
	last_requested_enemy_count = 0
	last_spawned_enemy_count = 0
	last_trigger_source = &"none"
	completion_announced = false
	last_reward_box_count = 0
	last_reward_total_credits = 0
	last_reward_size_ratio = 0.0
	_clear_doors()
	random.randomize()
	enemy_spawner.call(&"set_reinforcement_paused", &"room_encounters", true)
	return not room_definitions.is_empty()


func _process(_delta: float) -> void:
	if active_room_index >= 0:
		_prune_active_enemies()
		if active_enemies.is_empty():
			_complete_active_encounter()
		return
	_try_start_current_room()


func get_snapshot() -> Dictionary:
	_prune_active_rewards()
	var required_count := _required_encounter_count()
	return {
		&"tier_id": tier_id,
		&"room_count": room_definitions.size(),
		&"completed_encounters": completed_rooms.size(),
		&"maximum_encounters": int(tier_values.get(&"maximum_encounters", 0)),
		&"required_encounters": required_count,
		&"all_encounters_completed": _all_encounters_completed(),
		&"active_room_index": active_room_index,
		&"active_enemy_count": active_enemies.size(),
		&"locked_door_count": active_doors.size(),
		&"active_reward_count": active_rewards.size(),
		&"rewards_spawned": rewards_spawned,
		&"rewards_collected": rewards_collected,
		&"last_reward_box_count": last_reward_box_count,
		&"last_reward_total_credits": last_reward_total_credits,
		&"last_reward_size_ratio": last_reward_size_ratio,
		&"reward_box_minimum": int(config.get("minimum_reward_boxes")),
		&"reward_box_maximum": int(config.get("maximum_reward_boxes")),
		&"last_cleared_room_index": last_cleared_room_index,
		&"minimum_horde_size": int(tier_values.get(&"minimum_enemies", 0)),
		&"maximum_horde_size": int(tier_values.get(&"maximum_enemies", 0)),
		&"last_requested_enemy_count": last_requested_enemy_count,
		&"last_spawned_enemy_count": last_spawned_enemy_count,
		&"last_trigger_source": last_trigger_source,
		&"minimum_horde_met": (
			active_room_index < 0
			or active_enemies.size() >= int(tier_values.get(&"minimum_enemies", 0))
		),
		&"reinforcement_mode": &"room_triggered",
	}


func is_room_completed(room_index: int) -> bool:
	return completed_rooms.has(room_index)


func get_active_rewards() -> Array[Node]:
	_prune_active_rewards()
	return active_rewards.duplicate()


func try_start_room(room_index: int, trigger_source: StringName = &"external") -> bool:
	if active_room_index >= 0 or completed_rooms.has(room_index):
		return false
	if completed_rooms.size() >= int(tier_values.get(&"maximum_encounters", 0)):
		return false
	var room: Dictionary = room_definitions.get(room_index, {})
	if room.is_empty() or _room_is_excluded(room):
		return false
	var minimum_horde_size := int(tier_values[&"minimum_enemies"])
	var remaining_budget := int(enemy_spawner.call(&"get_remaining_spawn_budget"))
	if remaining_budget < minimum_horde_size:
		return false
	var requested_count := random.randi_range(
		minimum_horde_size,
		int(tier_values[&"maximum_enemies"])
	)
	requested_count = mini(requested_count, remaining_budget)
	var positions: PackedVector2Array = map_provider.call(
		&"get_room_spawn_positions", room_index, requested_count
	)
	if positions.size() < minimum_horde_size:
		return false
	var encounter_id := StringName("room_%d" % room_index)
	for world_position in positions:
		var enemy: Node2D = enemy_spawner.call(&"spawn_enemy_at", world_position, encounter_id)
		if is_instance_valid(enemy):
			active_enemies.append(enemy)
			enemy.tree_exited.connect(_on_active_enemy_tree_exited.bind(enemy), CONNECT_ONE_SHOT)
	if active_enemies.size() < minimum_horde_size:
		for enemy in active_enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()
		active_enemies.clear()
		return false
	active_room_index = room_index
	last_requested_enemy_count = requested_count
	last_spawned_enemy_count = active_enemies.size()
	last_trigger_source = trigger_source
	_lock_doors(room)
	encounter_started.emit(room_index, active_enemies.size())
	return true


func _try_start_current_room() -> void:
	if not is_instance_valid(player) or not is_instance_valid(map_provider):
		return
	var region: Dictionary = map_provider.call(&"get_visibility_region", player.global_position)
	if region.get(&"mode", &"corridor") != &"room":
		return
	var room_index := int(region.get(&"room_index", -1))
	var room: Dictionary = room_definitions.get(room_index, {})
	if room.is_empty():
		return
	var entry_rect: Rect2 = room[&"world_rect"]
	entry_rect = entry_rect.grow(-float(config.get("room_entry_inset")))
	if entry_rect.has_point(player.global_position):
		try_start_room(room_index, &"room_entry")


func _lock_doors(room: Dictionary) -> void:
	_clear_doors()
	for doorway: Dictionary in room.get(&"doorways", []):
		var barrier := DOOR_BARRIER_SCRIPT.new()
		add_child(barrier)
		if barrier.configure(doorway[&"position"], doorway[&"size"]):
			active_doors.append(barrier)
		else:
			barrier.queue_free()
	doors_locked.emit(active_room_index, active_doors.size())


func _complete_active_encounter() -> void:
	if active_room_index < 0:
		return
	var cleared_room := active_room_index
	completed_rooms[cleared_room] = true
	last_cleared_room_index = cleared_room
	active_room_index = -1
	_clear_doors()
	encounter_cleared.emit(cleared_room)
	_spawn_reward(cleared_room)
	_check_all_encounters_completed()


func _spawn_reward(room_index: int) -> void:
	var room: Dictionary = room_definitions.get(room_index, {})
	if room.is_empty() or not is_instance_valid(reward_parent):
		return
	var box_count := _reward_box_count(room)
	var positions: PackedVector2Array = map_provider.call(
		&"get_room_spawn_positions", room_index, box_count
	)
	if positions.is_empty():
		positions.append(room[&"center"])
	var total_credits := 0
	var kinds := [&"field_cache", &"material_locker", &"recovery_terminal"]
	for index in mini(box_count, positions.size()):
		var reward := REWARD_SCENE.instantiate()
		reward_parent.add_child(reward)
		reward.global_position = positions[index]
		var credit_amount := random.randi_range(
			int(tier_values[&"reward_credit_minimum"]),
			int(tier_values[&"reward_credit_maximum"])
		)
		reward.call(&"configure", credit_amount, kinds[index % kinds.size()])
		reward.set_meta(&"room_index", room_index)
		active_rewards.append(reward)
		rewards_spawned += 1
		total_credits += credit_amount
		reward.tree_exited.connect(_on_reward_tree_exited.bind(reward), CONNECT_ONE_SHOT)
		reward.connect(
			&"credits_collected", Callable(self, &"_on_reward_collected").bind(room_index)
		)
		reward.connect(
			&"interaction_availability_changed",
			Callable(self, &"_on_reward_interaction_availability_changed")
		)
	last_reward_box_count = mini(box_count, positions.size())
	last_reward_total_credits = total_credits
	reward_spawned.emit(room_index, last_reward_box_count, total_credits)


func _reward_box_count(room: Dictionary) -> int:
	var minimum_area := INF
	var maximum_area := 0.0
	for candidate: Dictionary in room_definitions.values():
		if _room_is_excluded(candidate):
			continue
		var rect: Rect2 = candidate.get(&"world_rect", Rect2())
		var area := rect.size.x * rect.size.y
		minimum_area = minf(minimum_area, area)
		maximum_area = maxf(maximum_area, area)
	var room_rect: Rect2 = room.get(&"world_rect", Rect2())
	var room_area := room_rect.size.x * room_rect.size.y
	var area_ratio := (
		clampf((room_area - minimum_area) / (maximum_area - minimum_area), 0.0, 1.0)
		if maximum_area > minimum_area else 0.5
	)
	last_reward_size_ratio = area_ratio
	var minimum_boxes := int(config.get("minimum_reward_boxes"))
	var maximum_boxes := int(config.get("maximum_reward_boxes"))
	var size_adjusted := roundi(lerpf(float(minimum_boxes), float(maximum_boxes), area_ratio))
	var variance := int(config.get("random_box_variance"))
	return clampi(size_adjusted + random.randi_range(-variance, variance), minimum_boxes, maximum_boxes)


func _required_encounter_count() -> int:
	var eligible_count := 0
	for room: Dictionary in room_definitions.values():
		if not _room_is_excluded(room):
			eligible_count += 1
	return mini(eligible_count, int(tier_values.get(&"maximum_encounters", 0)))


func _all_encounters_completed() -> bool:
	if active_room_index >= 0:
		return false
	var required_count := _required_encounter_count()
	return (
		required_count > 0 and completed_rooms.size() >= required_count
	) or (
		completed_rooms.size() > 0
		and int(enemy_spawner.call(&"get_remaining_spawn_budget"))
		< int(tier_values.get(&"minimum_enemies", 1))
	)


func _check_all_encounters_completed() -> void:
	if completion_announced or not _all_encounters_completed():
		return
	completion_announced = true
	all_encounters_completed.emit(completed_rooms.size(), _required_encounter_count())


func _on_reward_collected(
	credit_amount: int, _world_position: Vector2, room_index: int
) -> void:
	rewards_collected += 1
	reward_collected.emit(room_index, credit_amount)


func _on_reward_interaction_availability_changed(available: bool, prompt: String) -> void:
	interaction_availability_changed.emit(available, prompt)


func _on_reward_tree_exited(reward: Node) -> void:
	active_rewards.erase(reward)


func _on_active_enemy_tree_exited(enemy: Node) -> void:
	active_enemies.erase(enemy)
	if active_room_index >= 0 and active_enemies.is_empty():
		call_deferred(&"_complete_active_encounter")


func _prune_active_enemies() -> void:
	for index in range(active_enemies.size() - 1, -1, -1):
		if not is_instance_valid(active_enemies[index]):
			active_enemies.remove_at(index)


func _prune_active_rewards() -> void:
	for index in range(active_rewards.size() - 1, -1, -1):
		if not is_instance_valid(active_rewards[index]):
			active_rewards.remove_at(index)


func _clear_doors() -> void:
	for door in active_doors:
		if is_instance_valid(door):
			door.queue_free()
	active_doors.clear()


func _room_is_excluded(room: Dictionary) -> bool:
	return (
		bool(config.get("exclude_start_room")) and bool(room.get(&"is_start_room", false))
	) or (
		bool(config.get("exclude_extraction_room"))
		and bool(room.get(&"is_extraction_room", false))
	)


func _supports_methods(candidate: Node, methods: Array) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
