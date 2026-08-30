class_name RoomEncounterSystem
extends Node2D

signal encounter_started(room_index: int, enemy_count: int)
signal doors_locked(room_index: int, door_count: int)
signal encounter_cleared(room_index: int)
signal reward_spawned(room_index: int, experience_amount: int)
signal reward_collected(room_index: int, experience_amount: int)

const DOOR_BARRIER_SCRIPT := preload(
	"res://game/features/room_encounters/room_door_barrier.gd"
)
const REWARD_SCENE := preload(
	"res://game/features/room_encounters/room_reward_pickup.tscn"
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
	return {
		&"tier_id": tier_id,
		&"room_count": room_definitions.size(),
		&"completed_encounters": completed_rooms.size(),
		&"maximum_encounters": int(tier_values.get(&"maximum_encounters", 0)),
		&"active_room_index": active_room_index,
		&"active_enemy_count": active_enemies.size(),
		&"locked_door_count": active_doors.size(),
		&"reinforcement_mode": &"room_triggered",
	}


func try_start_room(room_index: int) -> bool:
	if active_room_index >= 0 or completed_rooms.has(room_index):
		return false
	if completed_rooms.size() >= int(tier_values.get(&"maximum_encounters", 0)):
		return false
	var room: Dictionary = room_definitions.get(room_index, {})
	if room.is_empty() or _room_is_excluded(room):
		return false
	var remaining_budget := int(enemy_spawner.call(&"get_remaining_spawn_budget"))
	var requested_count := random.randi_range(
		int(tier_values[&"minimum_enemies"]),
		int(tier_values[&"maximum_enemies"])
	)
	requested_count = mini(requested_count, remaining_budget)
	if requested_count <= 0:
		return false
	var positions: PackedVector2Array = map_provider.call(
		&"get_room_spawn_positions", room_index, requested_count
	)
	var encounter_id := StringName("room_%d" % room_index)
	for world_position in positions:
		var enemy: Node2D = enemy_spawner.call(&"spawn_enemy_at", world_position, encounter_id)
		if is_instance_valid(enemy):
			active_enemies.append(enemy)
			enemy.tree_exited.connect(_on_active_enemy_tree_exited.bind(enemy), CONNECT_ONE_SHOT)
	if active_enemies.is_empty():
		return false
	active_room_index = room_index
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
		try_start_room(room_index)


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
	active_room_index = -1
	_clear_doors()
	encounter_cleared.emit(cleared_room)
	_spawn_reward(cleared_room)


func _spawn_reward(room_index: int) -> void:
	var room: Dictionary = room_definitions.get(room_index, {})
	if room.is_empty() or not is_instance_valid(reward_parent):
		return
	var reward := REWARD_SCENE.instantiate()
	reward_parent.add_child(reward)
	reward.global_position = room[&"center"]
	var experience_amount := int(tier_values[&"reward_experience"])
	if not reward.call(&"configure", room_index, experience_amount):
		reward.queue_free()
		return
	reward.connect(&"collected", Callable(self, &"_on_reward_collected"))
	reward_spawned.emit(room_index, experience_amount)


func _on_reward_collected(room_index: int, experience_amount: int) -> void:
	reward_collected.emit(room_index, experience_amount)


func _on_active_enemy_tree_exited(enemy: Node) -> void:
	active_enemies.erase(enemy)
	if active_room_index >= 0 and active_enemies.is_empty():
		call_deferred(&"_complete_active_encounter")


func _prune_active_enemies() -> void:
	for index in range(active_enemies.size() - 1, -1, -1):
		if not is_instance_valid(active_enemies[index]):
			active_enemies.remove_at(index)


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
