class_name RoguelikeMapGenerator
extends Node2D

signal map_generated(
	display_name: String,
	entry_cost: int,
	room_count: int,
	maximum_rooms: int,
	used_seed: int
)

const CARDINAL_DIRECTIONS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const WALL_COLLISION_LAYER := 16

@export_range(16.0, 128.0, 4.0) var cell_size: float = 32.0
@export_range(1, 8, 1) var corridor_width: int = 3
@export_range(1, 12, 1) var minimum_room_gap: int = 5
@export_range(1, 16, 1) var maximum_room_gap: int = 9
@export var obstacles_enabled: bool = true
@export_range(0.0, 8.0, 0.5) var tile_visual_inset: float = 1.5
@export var floor_color := Color(0.075, 0.105, 0.14, 1)
@export var alternate_floor_color := Color(0.088, 0.122, 0.158, 1)
@export var wall_color := Color(0.17, 0.25, 0.3, 1)
@export var wall_edge_color := Color(0.29, 0.4, 0.45, 1)
@export var obstacle_color := Color(0.25, 0.2, 0.18, 1)
@export var obstacle_edge_color := Color(0.48, 0.37, 0.26, 1)
@export var start_color := Color(0.25, 0.88, 0.68, 0.9)

var tier_config: MapTierConfig
var rooms: Array[Rect2i] = []
var floor_cells: Dictionary = {}
var wall_cells: Dictionary = {}
var obstacle_cells: Dictionary = {}
var used_seed: int = 0
var start_position := Vector2.ZERO
var extraction_position := Vector2.ZERO
var extraction_room_index: int = 0
var astar_grid := AStarGrid2D.new()
var random := RandomNumberGenerator.new()
var collision_body: StaticBody2D
var collision_shape_count: int = 0


func configure_obstacles(is_enabled: bool) -> void:
	obstacles_enabled = is_enabled


func generate(config: MapTierConfig, requested_seed: int = 0) -> void:
	if config == null or not config.is_valid():
		push_error("유효한 MapTierConfig가 필요합니다.")
		return

	tier_config = config
	_reset_generated_content()

	if requested_seed == 0:
		random.randomize()
		used_seed = random.seed
	else:
		used_seed = requested_seed
		random.seed = used_seed

	var target_room_count := random.randi_range(config.minimum_rooms, config.maximum_rooms)
	_add_start_room()
	_generate_connected_rooms(target_room_count)
	_assign_landmarks()
	if obstacles_enabled:
		_generate_obstacles()
	_build_wall_cells()
	_build_pathfinding_grid()
	if get_world_path(start_position, extraction_position).is_empty():
		obstacle_cells.clear()
		_build_pathfinding_grid()
	_build_collision_bodies()
	queue_redraw()

	map_generated.emit(
		config.display_name,
		config.entry_cost,
		rooms.size(),
		config.maximum_rooms,
		used_seed
	)


func get_player_spawn_position() -> Vector2:
	return start_position


func get_extraction_position() -> Vector2:
	return extraction_position


func is_walkable_world_position(world_position: Vector2) -> bool:
	var cell := _world_to_cell(world_position)
	return floor_cells.has(cell) and not obstacle_cells.has(cell)


func get_enemy_spawn_position(origin: Vector2, minimum_distance: float) -> Vector2:
	var candidates: Array[Rect2i] = []
	for room in rooms:
		var center := _cell_center(_room_center_cell(room))
		if center.distance_to(origin) >= minimum_distance:
			candidates.append(room)

	if candidates.is_empty():
		return extraction_position

	for attempt in range(24):
		var room := candidates[random.randi_range(0, candidates.size() - 1)]
		var minimum_cell := room.position + Vector2i.ONE
		var maximum_cell := room.end - Vector2i(2, 2)
		var cell := Vector2i(
			random.randi_range(minimum_cell.x, maxi(minimum_cell.x, maximum_cell.x)),
			random.randi_range(minimum_cell.y, maxi(minimum_cell.y, maximum_cell.y))
		)
		if floor_cells.has(cell) and not obstacle_cells.has(cell):
			return _cell_center(cell)

	return extraction_position


func get_visibility_region(world_position: Vector2) -> Dictionary:
	var cell := _world_to_cell(world_position)
	for room_index in range(rooms.size()):
		var room := rooms[room_index]
		if room.has_point(cell):
			return {
				&"mode": &"room",
				&"room_index": room_index,
				&"world_rect": _room_world_rect(room),
			}
	return {
		&"mode": &"corridor",
		&"room_index": -1,
		&"world_rect": Rect2(),
	}


func get_visibility_room_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for room in rooms:
		result.append(_room_world_rect(room, false))
	return result


func get_room_encounter_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for room_index in range(rooms.size()):
		var room := rooms[room_index]
		result.append({
			&"room_index": room_index,
			&"world_rect": _room_world_rect(room, false),
			&"center": _cell_center(_room_center_cell(room)),
			&"doorways": _get_room_doorways(room),
			&"is_start_room": room_index == 0,
			&"is_extraction_room": room_index == extraction_room_index,
		})
	return result


func get_room_spawn_positions(room_index: int, requested_count: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	if room_index < 0 or room_index >= rooms.size() or requested_count <= 0:
		return result
	var room := rooms[room_index]
	var used_cells: Dictionary = {}
	var attempts := 0
	var maximum_attempts := requested_count * 80
	while result.size() < requested_count and attempts < maximum_attempts:
		attempts += 1
		var cell := Vector2i(
			random.randi_range(room.position.x + 3, room.end.x - 4),
			random.randi_range(room.position.y + 3, room.end.y - 4)
		)
		if used_cells.has(cell) or obstacle_cells.has(cell) or not floor_cells.has(cell):
			continue
		if cell.distance_squared_to(_room_center_cell(room)) < 16:
			continue
		used_cells[cell] = true
		result.append(_cell_center(cell))
	return result


func get_loot_spawn_positions(requested_count: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in get_loot_spawn_points(requested_count):
		result.append(point[&"position"])
	return result


func get_loot_spawn_points(requested_count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if requested_count <= 0 or rooms.size() <= 1:
		return result

	var used_cells: Dictionary = {}
	var attempts := 0
	var maximum_attempts := requested_count * 120
	while result.size() < requested_count and attempts < maximum_attempts:
		attempts += 1
		var room_index := random.randi_range(1, rooms.size() - 1)
		if room_index == extraction_room_index:
			continue
		var room := rooms[room_index]
		var placement_index := result.size() % 3
		var point := (
			_random_wall_loot_point(room, placement_index, used_cells)
			if placement_index < 2
			else _random_floor_loot_point(room, used_cells)
		)
		if point.is_empty():
			continue
		var world_position: Vector2 = point[&"position"]
		if world_position.distance_to(start_position) < cell_size * 6.0:
			continue
		if world_position.distance_to(extraction_position) < cell_size * 4.0:
			continue
		used_cells[point[&"cell"]] = true
		point.erase(&"cell")
		result.append(point)

	return result


func get_world_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	if astar_grid.region.size == Vector2i.ZERO:
		return result

	var from_cell := _world_to_cell(from_world)
	var to_cell := _world_to_cell(to_world)
	if not astar_grid.region.has_point(from_cell) or not astar_grid.region.has_point(to_cell):
		return result
	if astar_grid.is_point_solid(from_cell) or astar_grid.is_point_solid(to_cell):
		return result

	for cell in astar_grid.get_id_path(from_cell, to_cell):
		result.append(_cell_center(cell))
	return result


func get_minimap_snapshot() -> Dictionary:
	var floor_snapshot := PackedVector2Array()
	var obstacle_snapshot := PackedVector2Array()
	for cell in floor_cells:
		floor_snapshot.append(Vector2(cell))
	for cell in obstacle_cells:
		obstacle_snapshot.append(Vector2(cell))

	return {
		&"cell_bounds": astar_grid.region,
		&"cell_size": cell_size,
		&"floor_cells": floor_snapshot,
		&"obstacle_cells": obstacle_snapshot,
		&"start_position": start_position,
		&"extraction_position": extraction_position,
	}


func get_performance_snapshot() -> Dictionary:
	return {
		&"floor_cell_count": floor_cells.size(),
		&"wall_cell_count": wall_cells.size(),
		&"obstacle_cell_count": obstacle_cells.size(),
		&"collision_shape_count": collision_shape_count,
		&"collision_compression_ratio": (
			float(collision_shape_count) / float(wall_cells.size() + obstacle_cells.size())
			if wall_cells.size() + obstacle_cells.size() > 0 else 0.0
		),
	}


func _reset_generated_content() -> void:
	rooms.clear()
	floor_cells.clear()
	wall_cells.clear()
	obstacle_cells.clear()
	astar_grid = AStarGrid2D.new()

	if is_instance_valid(collision_body):
		collision_body.queue_free()
	collision_body = null
	collision_shape_count = 0


func _add_start_room() -> void:
	var size := _random_room_size()
	var position := Vector2i(-size.x / 2, -size.y / 2)
	_add_room(Rect2i(position, size))


func _generate_connected_rooms(target_room_count: int) -> void:
	var attempts := 0
	var maximum_attempts := target_room_count * 120

	while rooms.size() < target_room_count and attempts < maximum_attempts:
		attempts += 1
		var parent := rooms[random.randi_range(0, rooms.size() - 1)]
		var direction: Vector2i = CARDINAL_DIRECTIONS[
			random.randi_range(0, CARDINAL_DIRECTIONS.size() - 1)
		]
		var candidate := _adjacent_room(parent, direction)

		if _overlaps_existing_room(candidate):
			continue

		_add_room(candidate)
		_carve_corridor(_room_center_cell(parent), _room_center_cell(candidate))


func _adjacent_room(parent: Rect2i, direction: Vector2i) -> Rect2i:
	var size := _random_room_size()
	var gap := random.randi_range(minimum_room_gap, maximum_room_gap)
	var parent_center := _room_center_cell(parent)
	var jitter := random.randi_range(-2, 2)
	var position := Vector2i.ZERO

	if direction == Vector2i.RIGHT:
		position = Vector2i(parent.end.x + gap, parent_center.y - size.y / 2 + jitter)
	elif direction == Vector2i.LEFT:
		position = Vector2i(parent.position.x - gap - size.x, parent_center.y - size.y / 2 + jitter)
	elif direction == Vector2i.DOWN:
		position = Vector2i(parent_center.x - size.x / 2 + jitter, parent.end.y + gap)
	else:
		position = Vector2i(parent_center.x - size.x / 2 + jitter, parent.position.y - gap - size.y)

	return Rect2i(position, size)


func _random_room_size() -> Vector2i:
	return Vector2i(
		random.randi_range(tier_config.minimum_room_size.x, tier_config.maximum_room_size.x),
		random.randi_range(tier_config.minimum_room_size.y, tier_config.maximum_room_size.y)
	)


func _overlaps_existing_room(candidate: Rect2i) -> bool:
	var padded_candidate := candidate.grow(1)
	for room in rooms:
		if padded_candidate.intersects(room.grow(1)):
			return true
	return false


func _add_room(room: Rect2i) -> void:
	rooms.append(room)
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			floor_cells[Vector2i(x, y)] = true


func _carve_corridor(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if random.randi_range(0, 1) == 0:
		_carve_horizontal(from_cell.x, to_cell.x, from_cell.y)
		_carve_vertical(from_cell.y, to_cell.y, to_cell.x)
	else:
		_carve_vertical(from_cell.y, to_cell.y, from_cell.x)
		_carve_horizontal(from_cell.x, to_cell.x, to_cell.y)


func _carve_horizontal(from_x: int, to_x: int, y: int) -> void:
	for x in range(mini(from_x, to_x), maxi(from_x, to_x) + 1):
		for width_offset in range(corridor_width):
			floor_cells[Vector2i(x, y + width_offset)] = true


func _carve_vertical(from_y: int, to_y: int, x: int) -> void:
	for y in range(mini(from_y, to_y), maxi(from_y, to_y) + 1):
		for width_offset in range(corridor_width):
			floor_cells[Vector2i(x + width_offset, y)] = true


func _build_wall_cells() -> void:
	wall_cells.clear()
	for cell in floor_cells:
		for direction in CARDINAL_DIRECTIONS:
			var neighbor: Vector2i = cell + direction
			if not floor_cells.has(neighbor):
				wall_cells[neighbor] = true


func _generate_obstacles() -> void:
	obstacle_cells.clear()
	for room_index in range(rooms.size()):
		if room_index == 0 or room_index == extraction_room_index:
			continue

		var room := rooms[room_index]
		var desired_count := maxi(1, roundi(room.get_area() * tier_config.obstacle_density))
		var attempts := 0
		var placed_count := 0
		while placed_count < desired_count and attempts < room.get_area() * 3:
			attempts += 1
			var structure_kind := room_index % 3 if placed_count == 0 else random.randi_range(0, 9)
			if structure_kind <= 5:
				var wall_cells_pattern := _random_interior_wall(room)
				if _try_place_obstacle_pattern(wall_cells_pattern, &"wall", room):
					placed_count += wall_cells_pattern.size()
			elif structure_kind <= 7:
				var utility_pattern := _random_utility_block(room)
				if _try_place_obstacle_pattern(utility_pattern, &"utility", room):
					placed_count += utility_pattern.size()
			else:
				var pillar_pattern := _random_pillar_cluster(room)
				if _try_place_obstacle_pattern(pillar_pattern, &"pillar", room):
					placed_count += pillar_pattern.size()


func _random_interior_wall(room: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var horizontal := random.randi_range(0, 1) == 0
	var available_length := (room.size.x if horizontal else room.size.y) - 8
	var maximum_length := mini(18, available_length)
	var minimum_length := mini(8, maximum_length)
	var length := random.randi_range(minimum_length, maxi(minimum_length, maximum_length))
	var doorway_start := random.randi_range(3, maxi(3, length - 4))
	var doorway_width := 2
	if horizontal:
		var start_x := random.randi_range(room.position.x + 3, room.end.x - length - 3)
		var y := random.randi_range(room.position.y + 3, room.end.y - 4)
		for offset in range(length):
			if offset >= doorway_start and offset < doorway_start + doorway_width:
				continue
			result.append(Vector2i(start_x + offset, y))
	else:
		var x := random.randi_range(room.position.x + 3, room.end.x - 4)
		var start_y := random.randi_range(room.position.y + 3, room.end.y - length - 3)
		for offset in range(length):
			if offset >= doorway_start and offset < doorway_start + doorway_width:
				continue
			result.append(Vector2i(x, start_y + offset))
	return result


func _random_utility_block(room: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var block_size := Vector2i(
		random.randi_range(3, 5),
		random.randi_range(2, 3)
	)
	if random.randi_range(0, 1) == 1:
		block_size = Vector2i(block_size.y, block_size.x)
	var start := Vector2i(
		random.randi_range(room.position.x + 3, room.end.x - block_size.x - 3),
		random.randi_range(room.position.y + 3, room.end.y - block_size.y - 3)
	)
	for x in range(block_size.x):
		for y in range(block_size.y):
			result.append(start + Vector2i(x, y))
	return result


func _random_pillar_cluster(room: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var horizontal := random.randi_range(0, 1) == 0
	var count := random.randi_range(2, 3)
	var spacing := random.randi_range(2, 3)
	var extent := (count - 1) * spacing
	var start := Vector2i(
		random.randi_range(room.position.x + 4, room.end.x - extent - 4),
		random.randi_range(room.position.y + 4, room.end.y - extent - 4)
	)
	for index in range(count):
		result.append(start + (Vector2i(index * spacing, 0) if horizontal else Vector2i(0, index * spacing)))
	return result


func _random_wall_loot_point(
	room: Rect2i,
	placement_index: int,
	used_cells: Dictionary
) -> Dictionary:
	var side := random.randi_range(0, 3)
	var cell := Vector2i.ZERO
	var inward := Vector2.ZERO
	match side:
		0:
			cell = Vector2i(random.randi_range(room.position.x + 3, room.end.x - 4), room.position.y)
			inward = Vector2.DOWN
		1:
			cell = Vector2i(random.randi_range(room.position.x + 3, room.end.x - 4), room.end.y - 1)
			inward = Vector2.UP
		2:
			cell = Vector2i(room.position.x, random.randi_range(room.position.y + 3, room.end.y - 4))
			inward = Vector2.RIGHT
		_:
			cell = Vector2i(room.end.x - 1, random.randi_range(room.position.y + 3, room.end.y - 4))
			inward = Vector2.LEFT
	if used_cells.has(cell) or obstacle_cells.has(cell) or not floor_cells.has(cell):
		return {}
	return {
		&"cell": cell,
		&"position": _cell_center(cell) - inward * cell_size * 0.34,
		&"facing": inward,
		&"placement_kind": &"wall_safe" if placement_index == 0 else &"material_locker",
	}


func _random_floor_loot_point(room: Rect2i, used_cells: Dictionary) -> Dictionary:
	var cell := Vector2i(
		random.randi_range(room.position.x + 4, room.end.x - 5),
		random.randi_range(room.position.y + 4, room.end.y - 5)
	)
	if used_cells.has(cell) or obstacle_cells.has(cell) or not floor_cells.has(cell):
		return {}
	return {
		&"cell": cell,
		&"position": _cell_center(cell),
		&"facing": Vector2.DOWN,
		&"placement_kind": &"recovery_terminal",
	}


func _try_place_obstacle_pattern(
	pattern: Array[Vector2i],
	kind: StringName,
	room: Rect2i
) -> bool:
	var pattern_cells: Dictionary = {}
	for cell in pattern:
		pattern_cells[cell] = true
	for cell in pattern:
		if not _cell_is_clear_for_obstacle(cell, room, pattern_cells):
			return false
	for cell in pattern:
		obstacle_cells[cell] = kind
	return true


func _cell_is_clear_for_obstacle(
	cell: Vector2i,
	room: Rect2i,
	pattern_cells: Dictionary
) -> bool:
	var room_center := _room_center_cell(room)
	if cell.x == room_center.x or cell.y == room_center.y:
		return false
	if cell.distance_squared_to(_world_to_cell(start_position)) <= 9:
		return false
	if cell.distance_squared_to(_world_to_cell(extraction_position)) <= 9:
		return false
	if obstacle_cells.has(cell):
		return false
	for direction in CARDINAL_DIRECTIONS:
		var neighbor: Vector2i = cell + direction
		if obstacle_cells.has(neighbor) and not pattern_cells.has(neighbor):
			return false
	return floor_cells.has(cell)


func _build_collision_bodies() -> void:
	collision_body = StaticBody2D.new()
	collision_body.name = "GeneratedCollision"
	collision_body.collision_layer = WALL_COLLISION_LAYER
	collision_body.collision_mask = 0
	add_child(collision_body)

	collision_shape_count = 0
	for cell_rect in _merge_collision_cells(wall_cells):
		_add_rectangle_collision(cell_rect, tile_visual_inset * 2.0)
	for obstacle_kind in [&"wall", &"utility"]:
		for cell_rect in _merge_collision_cells(obstacle_cells, obstacle_kind):
			_add_rectangle_collision(cell_rect, cell_size * 0.18)
	var pillar_shape := CircleShape2D.new()
	pillar_shape.radius = cell_size * 0.31
	for cell in obstacle_cells:
		if obstacle_cells[cell] != &"pillar":
			continue
		var pillar_collision := CollisionShape2D.new()
		pillar_collision.position = _cell_center(cell)
		pillar_collision.shape = pillar_shape
		collision_body.add_child(pillar_collision)
		collision_shape_count += 1


func _add_rectangle_collision(cell_rect: Rect2i, outer_inset: float) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(cell_rect.size) * cell_size - Vector2.ONE * outer_inset
	var collision := CollisionShape2D.new()
	collision.position = (
		Vector2(cell_rect.position) + Vector2(cell_rect.size) * 0.5
	) * cell_size
	collision.shape = shape
	collision_body.add_child(collision)
	collision_shape_count += 1


func _merge_collision_cells(
	source_cells: Dictionary,
	required_kind: Variant = null
) -> Array[Rect2i]:
	var remaining := {}
	for cell in source_cells:
		if required_kind == null or source_cells[cell] == required_kind:
			remaining[cell] = source_cells[cell]
	var result: Array[Rect2i] = []
	while not remaining.is_empty():
		var start: Vector2i = remaining.keys()[0]
		var kind: Variant = remaining[start]
		var width := 1
		while remaining.get(start + Vector2i(width, 0), null) == kind:
			width += 1
		var height := 1
		while true:
			var row_is_complete := true
			for x_offset in width:
				if remaining.get(start + Vector2i(x_offset, height), null) != kind:
					row_is_complete = false
					break
			if not row_is_complete:
				break
			height += 1
		for x_offset in width:
			for y_offset in height:
				remaining.erase(start + Vector2i(x_offset, y_offset))
		result.append(Rect2i(start, Vector2i(width, height)))
	return result


func _build_pathfinding_grid() -> void:
	if floor_cells.is_empty():
		return

	var first_cell: Vector2i = floor_cells.keys()[0]
	var minimum_cell := first_cell
	var maximum_cell := first_cell
	for cell in floor_cells:
		minimum_cell.x = mini(minimum_cell.x, cell.x)
		minimum_cell.y = mini(minimum_cell.y, cell.y)
		maximum_cell.x = maxi(maximum_cell.x, cell.x)
		maximum_cell.y = maxi(maximum_cell.y, cell.y)

	minimum_cell -= Vector2i.ONE
	maximum_cell += Vector2i.ONE
	astar_grid.region = Rect2i(minimum_cell, maximum_cell - minimum_cell + Vector2i.ONE)
	astar_grid.cell_size = Vector2.ONE * cell_size
	astar_grid.offset = Vector2.ONE * cell_size * 0.5
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

	for x in range(astar_grid.region.position.x, astar_grid.region.end.x):
		for y in range(astar_grid.region.position.y, astar_grid.region.end.y):
			var cell := Vector2i(x, y)
			astar_grid.set_point_solid(
				cell,
				not floor_cells.has(cell) or obstacle_cells.has(cell)
			)


func _assign_landmarks() -> void:
	start_position = _cell_center(_room_center_cell(rooms[0]))
	var farthest_room := rooms[0]
	var farthest_distance := -1.0

	for room in rooms:
		var center := _cell_center(_room_center_cell(room))
		var distance := center.distance_squared_to(start_position)
		if distance > farthest_distance:
			farthest_distance = distance
			farthest_room = room
			extraction_room_index = rooms.find(room)

	extraction_position = _cell_center(_room_center_cell(farthest_room))


func _room_center_cell(room: Rect2i) -> Vector2i:
	return room.position + Vector2i(room.size.x / 2, room.size.y / 2)


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2.ONE * 0.5) * cell_size


func _room_world_rect(room: Rect2i, include_boundary_walls: bool = true) -> Rect2:
	var result := Rect2(
		Vector2(room.position) * cell_size,
		Vector2(room.size) * cell_size
	)
	return result.grow(cell_size) if include_boundary_walls else result


func _get_room_doorways(room: Rect2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for y in range(room.position.y, room.end.y):
		_append_doorway_if_open(result, room, Vector2i(room.position.x, y), Vector2i.LEFT)
		_append_doorway_if_open(result, room, Vector2i(room.end.x - 1, y), Vector2i.RIGHT)
	for x in range(room.position.x, room.end.x):
		_append_doorway_if_open(result, room, Vector2i(x, room.position.y), Vector2i.UP)
		_append_doorway_if_open(result, room, Vector2i(x, room.end.y - 1), Vector2i.DOWN)
	return result


func _append_doorway_if_open(
	result: Array[Dictionary],
	room: Rect2i,
	inside_cell: Vector2i,
	outward: Vector2i
) -> void:
	var outside_cell := inside_cell + outward
	if room.has_point(outside_cell) or not floor_cells.has(outside_cell):
		return
	var position := _cell_center(inside_cell)
	var size := Vector2.ONE * cell_size
	if outward == Vector2i.LEFT:
		position.x = float(room.position.x) * cell_size
		size.x = 14.0
	elif outward == Vector2i.RIGHT:
		position.x = float(room.end.x) * cell_size
		size.x = 14.0
	elif outward == Vector2i.UP:
		position.y = float(room.position.y) * cell_size
		size.y = 14.0
	else:
		position.y = float(room.end.y) * cell_size
		size.y = 14.0
	result.append({
		&"position": position,
		&"size": size,
		&"outward": Vector2(outward),
	})


func _world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / cell_size), floori(world_position.y / cell_size))


func _draw() -> void:
	for cell in floor_cells:
		var color := floor_color if (cell.x + cell.y) % 2 == 0 else alternate_floor_color
		draw_rect(Rect2(Vector2(cell) * cell_size, Vector2.ONE * cell_size), color)

	for cell in wall_cells:
		var wall_rect := Rect2(Vector2(cell) * cell_size, Vector2.ONE * cell_size)
		wall_rect = wall_rect.grow(-tile_visual_inset)
		draw_rect(wall_rect, wall_edge_color)
		draw_rect(wall_rect.grow(-2.0), wall_color)

	for cell in obstacle_cells:
		if obstacle_cells[cell] == &"pillar":
			var center := _cell_center(cell)
			draw_circle(center, cell_size * 0.34, obstacle_edge_color)
			draw_circle(center, cell_size * 0.25, obstacle_color)
			draw_circle(center - Vector2(3.0, 3.0), 2.0, Color(0.78, 0.63, 0.42, 0.8))
		elif obstacle_cells[cell] == &"utility":
			var utility_rect := Rect2(Vector2(cell) * cell_size, Vector2.ONE * cell_size)
			utility_rect = utility_rect.grow(-cell_size * 0.06)
			draw_rect(utility_rect, Color(0.42, 0.35, 0.24, 1.0))
			draw_rect(utility_rect.grow(-4.0), Color(0.2, 0.24, 0.25, 1.0))
			draw_line(utility_rect.position + Vector2(4, 6), utility_rect.end - Vector2(4, 6), Color(0.8, 0.62, 0.22, 0.7), 2.0)
		else:
			var obstacle_rect := Rect2(Vector2(cell) * cell_size, Vector2.ONE * cell_size)
			obstacle_rect = obstacle_rect.grow(-cell_size * 0.09)
			draw_rect(obstacle_rect, obstacle_edge_color)
			draw_rect(obstacle_rect.grow(-3.0), obstacle_color)

	var marker_radius := cell_size * 0.32
	draw_circle(start_position, marker_radius, start_color)
	draw_arc(start_position, marker_radius, 0.0, TAU, 32, Color.WHITE, 2.0)
