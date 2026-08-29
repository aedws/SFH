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

@export_range(16.0, 128.0, 4.0) var cell_size: float = 48.0
@export_range(1, 8, 1) var corridor_width: int = 2
@export_range(1, 12, 1) var minimum_room_gap: int = 3
@export_range(1, 16, 1) var maximum_room_gap: int = 6
@export var floor_color := Color(0.075, 0.105, 0.14, 1)
@export var alternate_floor_color := Color(0.088, 0.122, 0.158, 1)
@export var wall_color := Color(0.2, 0.29, 0.35, 1)
@export var start_color := Color(0.25, 0.88, 0.68, 0.9)
@export var extraction_color := Color(1.0, 0.61, 0.2, 0.95)

var tier_config: MapTierConfig
var rooms: Array[Rect2i] = []
var floor_cells: Dictionary = {}
var wall_cells: Dictionary = {}
var used_seed: int = 0
var start_position := Vector2.ZERO
var extraction_position := Vector2.ZERO
var astar_grid := AStarGrid2D.new()
var random := RandomNumberGenerator.new()
var wall_body: StaticBody2D


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
	_build_wall_cells()
	_build_wall_collisions()
	_build_pathfinding_grid()
	_assign_landmarks()
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
	return floor_cells.has(_world_to_cell(world_position))


func get_enemy_spawn_position(origin: Vector2, minimum_distance: float) -> Vector2:
	var candidates: Array[Rect2i] = []
	for room in rooms:
		var center := _cell_center(_room_center_cell(room))
		if center.distance_to(origin) >= minimum_distance:
			candidates.append(room)

	if candidates.is_empty():
		return extraction_position

	var room := candidates[random.randi_range(0, candidates.size() - 1)]
	var minimum_cell := room.position + Vector2i.ONE
	var maximum_cell := room.end - Vector2i(2, 2)
	var cell := Vector2i(
		random.randi_range(minimum_cell.x, maxi(minimum_cell.x, maximum_cell.x)),
		random.randi_range(minimum_cell.y, maxi(minimum_cell.y, maximum_cell.y))
	)
	return _cell_center(cell)


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
	astar_grid = AStarGrid2D.new()

	if is_instance_valid(wall_body):
		wall_body.queue_free()
	wall_body = null


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


func _build_wall_collisions() -> void:
	wall_body = StaticBody2D.new()
	wall_body.name = "GeneratedWalls"
	wall_body.collision_layer = WALL_COLLISION_LAYER
	wall_body.collision_mask = 0
	add_child(wall_body)

	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2.ONE * cell_size

	for cell in wall_cells:
		var collision := CollisionShape2D.new()
		collision.position = _cell_center(cell)
		collision.shape = wall_shape
		wall_body.add_child(collision)


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
			astar_grid.set_point_solid(cell, not floor_cells.has(cell))


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
		draw_rect(Rect2(Vector2(cell) * cell_size, Vector2.ONE * cell_size), wall_color)

	var marker_radius := cell_size * 0.32
	draw_circle(start_position, marker_radius, start_color)
	draw_arc(start_position, marker_radius, 0.0, TAU, 32, Color.WHITE, 2.0)
	draw_circle(extraction_position, marker_radius, extraction_color)
	draw_arc(extraction_position, marker_radius, 0.0, TAU, 32, Color.WHITE, 2.0)
