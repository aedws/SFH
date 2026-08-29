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


func get_loot_spawn_positions(requested_count: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	if requested_count <= 0 or rooms.size() <= 1:
		return result

	var used_cells: Dictionary = {}
	var attempts := 0
	var maximum_attempts := requested_count * 80
	while result.size() < requested_count and attempts < maximum_attempts:
		attempts += 1
		var room_index := random.randi_range(1, rooms.size() - 1)
		var room := rooms[room_index]
		var cell := Vector2i(
			random.randi_range(room.position.x + 2, room.end.x - 3),
			random.randi_range(room.position.y + 2, room.end.y - 3)
		)
		if used_cells.has(cell) or not floor_cells.has(cell) or obstacle_cells.has(cell):
			continue
		var world_position := _cell_center(cell)
		if world_position.distance_to(start_position) < cell_size * 5.0:
			continue
		if world_position.distance_to(extraction_position) < cell_size * 3.0:
			continue

		used_cells[cell] = true
		result.append(world_position)

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


func _reset_generated_content() -> void:
	rooms.clear()
	floor_cells.clear()
	wall_cells.clear()
	obstacle_cells.clear()
	astar_grid = AStarGrid2D.new()

	if is_instance_valid(collision_body):
		collision_body.queue_free()
	collision_body = null


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
			if random.randf() < 0.62:
				var wall_cells_pattern := _random_interior_wall(room)
				if _try_place_obstacle_pattern(wall_cells_pattern, &"wall", room):
					placed_count += wall_cells_pattern.size()
			else:
				var pillar_cell := Vector2i(
					random.randi_range(room.position.x + 2, room.end.x - 3),
					random.randi_range(room.position.y + 2, room.end.y - 3)
				)
				var pillar_pattern: Array[Vector2i] = [pillar_cell]
				if _try_place_obstacle_pattern(pillar_pattern, &"pillar", room):
					placed_count += 1


func _random_interior_wall(room: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var horizontal := random.randi_range(0, 1) == 0
	var maximum_length := mini(5, (room.size.x if horizontal else room.size.y) - 5)
	var length := random.randi_range(2, maxi(2, maximum_length))
	if horizontal:
		var start_x := random.randi_range(room.position.x + 2, room.end.x - length - 2)
		var y := random.randi_range(room.position.y + 2, room.end.y - 3)
		for offset in range(length):
			result.append(Vector2i(start_x + offset, y))
	else:
		var x := random.randi_range(room.position.x + 2, room.end.x - 3)
		var start_y := random.randi_range(room.position.y + 2, room.end.y - length - 2)
		for offset in range(length):
			result.append(Vector2i(x, start_y + offset))
	return result


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

	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2.ONE * (cell_size - tile_visual_inset * 2.0)

	for cell in wall_cells:
		var collision := CollisionShape2D.new()
		collision.position = _cell_center(cell)
		collision.shape = wall_shape
		collision_body.add_child(collision)

	var interior_wall_shape := RectangleShape2D.new()
	interior_wall_shape.size = Vector2.ONE * (cell_size * 0.82)
	var pillar_shape := CircleShape2D.new()
	pillar_shape.radius = cell_size * 0.31
	for cell in obstacle_cells:
		var collision := CollisionShape2D.new()
		collision.position = _cell_center(cell)
		collision.shape = (
			pillar_shape
			if obstacle_cells[cell] == &"pillar"
			else interior_wall_shape
		)
		collision_body.add_child(collision)


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
		else:
			var obstacle_rect := Rect2(Vector2(cell) * cell_size, Vector2.ONE * cell_size)
			obstacle_rect = obstacle_rect.grow(-cell_size * 0.09)
			draw_rect(obstacle_rect, obstacle_edge_color)
			draw_rect(obstacle_rect.grow(-3.0), obstacle_color)

	var marker_radius := cell_size * 0.32
	draw_circle(start_position, marker_radius, start_color)
	draw_arc(start_position, marker_radius, 0.0, TAU, 32, Color.WHITE, 2.0)
