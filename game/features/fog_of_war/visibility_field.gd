class_name RoguelikeVisibilityField
extends RefCounted
## Pure grid visibility and remembered terrain. No actors, UI, physics or rewards.
var bounds := Rect2i()
var cell_size := 32.0
var terrain := PackedByteArray()
var visible_cells: Dictionary = {}
var explored_cells: Dictionary = {}
var blockers: Dictionary = {}
var image: Image
var origin := Vector2i(2147483647, 2147483647)
var radius := -1
var updates := 0
var last_compute_usec := 0


func configure(geometry: Dictionary) -> bool:
	bounds = geometry.get(&"bounds", Rect2i())
	cell_size = float(geometry.get(&"cell_size", 0))
	terrain = (geometry.get(&"terrain", PackedByteArray()) as PackedByteArray).duplicate()
	if not is_finite(cell_size) or cell_size <= 0 or bounds.size.x <= 0 or bounds.size.y <= 0 or bounds.size.x > 2048 or bounds.size.y > 2048:
		return false
	if terrain.size() != bounds.size.x * bounds.size.y: return false
	visible_cells.clear()
	explored_cells.clear()
	blockers.clear()
	image = Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 1))
	origin = Vector2i(2147483647, 2147483647)
	radius = -1
	updates = 0
	return true


func update(position: Vector2, radius_cells: int, dynamic_blockers: Dictionary) -> bool:
	var next_origin := world_to_cell(position)
	var next_radius := clampi(radius_cells, 2, 40)
	if next_origin == origin and next_radius == radius and dynamic_blockers == blockers: return false
	var started := Time.get_ticks_usec()
	for cell: Vector2i in visible_cells:
		image.set_pixelv(cell - bounds.position, Color(0, 1, float(explored_cells[cell]) / 3.0, 1))
	visible_cells.clear()
	origin = next_origin
	radius = next_radius
	blockers = dynamic_blockers.duplicate()
	_reveal(origin)
	# Eight octants, with merged angular shadows from previous rows. This avoids
	# tracing a separate full ray for every cell (quadratic instead of cubic scan).
	for axis in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var side := Vector2i(-axis.y, axis.x)
		_scan_octant(axis, side)
		_scan_octant(axis, -side)
	updates += 1
	last_compute_usec = Time.get_ticks_usec() - started
	return true


func _scan_octant(forward: Vector2i, lateral: Vector2i) -> void:
	var shadows: Array[Vector2] = []
	for depth in range(1, radius + 1):
		var pending: Array[Vector2] = []
		for column in range(depth + 1):
			var cell := origin + forward * depth + lateral * column
			var span := Vector2(maxf(0, (column - 0.5) / (depth + 0.5)), minf(1, (column + 0.5) / (depth - 0.5)))
			var center := float(column) / depth
			var blocked := opaque(cell)
			var hidden := false
			for shadow in shadows:
				if (span.x >= shadow.x and span.y <= shadow.y) if blocked else (center >= shadow.x and center <= shadow.y):
					hidden = true
					break
			# Octant boundaries share a row with both side walls. Seal the exact
			# diagonal with the supercover test instead of revealing through a corner.
			if column == depth and not has_line_of_sight(origin, cell): hidden = true
			if not hidden and depth * depth + column * column <= radius * radius: _reveal(cell)
			if blocked: pending.append(span)
		for span in pending:
			var merged := span
			for index in range(shadows.size() - 1, -1, -1):
				if shadows[index].y < merged.x or shadows[index].x > merged.y: continue
				merged = Vector2(minf(merged.x, shadows[index].x), maxf(merged.y, shadows[index].y))
				shadows.remove_at(index)
			shadows.append(merged)
		if shadows.size() == 1 and shadows[0].x <= 0 and shadows[0].y >= 1: break


func _reveal(cell: Vector2i) -> void:
	if not bounds.has_point(cell) or visible_cells.has(cell): return
	var kind := 3 if blockers.has(cell) else terrain_at(cell)
	if kind == 0: return
	visible_cells[cell] = true
	explored_cells[cell] = kind
	image.set_pixelv(cell - bounds.position, Color(1, 1, float(kind) / 3.0, 1))


func has_line_of_sight(start: Vector2i, destination: Vector2i) -> bool:
	# Symmetric cell-centre traversal. A closed diagonal corner never leaks vision.
	var difference := destination - start
	var distance := difference.abs()
	var direction := Vector2i(signi(difference.x), signi(difference.y))
	var cell := start
	var ix := 0
	var iy := 0
	while cell != destination:
		var decision := (1 + 2 * ix) * distance.y - (1 + 2 * iy) * distance.x
		if decision == 0:
			if opaque(cell + Vector2i(direction.x, 0)) and opaque(cell + Vector2i(0, direction.y)): return false
			cell += direction
			ix += 1
			iy += 1
		elif decision < 0:
			cell.x += direction.x
			ix += 1
		else:
			cell.y += direction.y
			iy += 1
		if cell == destination: return true # The wall itself is visible, not its far side.
		if opaque(cell): return false
	return true


func world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.y / cell_size))


func terrain_at(cell: Vector2i) -> int:
	if not bounds.has_point(cell): return 0
	var local := cell - bounds.position
	return terrain[local.y * bounds.size.x + local.x]


func opaque(cell: Vector2i) -> bool:
	return blockers.has(cell) or terrain_at(cell) != 1


func state_at(position: Vector2) -> StringName:
	var cell := world_to_cell(position)
	if visible_cells.has(cell): return &"visible"
	return &"explored" if explored_cells.has(cell) else &"unexplored"
