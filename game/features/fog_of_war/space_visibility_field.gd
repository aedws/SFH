class_name SpaceVisibilityField
extends "res://game/features/fog_of_war/visibility_field.gd"
## Space disclosure is independent of encounter completion. Memory remains terrain-only.
var spaces: Array[Dictionary] = []
var active_space := -1
var hysteresis_pixels := 14.0
var disclosure_revision := 0

func configure_spaces(definitions: Array) -> void:
	spaces.clear()
	for source: Dictionary in definitions:
		var rect: Rect2 = source.get(&"world_rect",Rect2())
		if rect.has_area(): spaces.append(source.duplicate(true))
	active_space=-1

func update(position: Vector2, radius_cells: int, dynamic_blockers: Dictionary) -> bool:
	if spaces.is_empty(): return super.update(position,radius_cells,dynamic_blockers)
	var selected := _select_space(position)
	if selected < 0:
		active_space=-1
		return super.update(position,radius_cells,dynamic_blockers)
	if selected == active_space and dynamic_blockers == blockers:
		var actor_cell := world_to_cell(position)
		if not visible_cells.has(actor_cell):
			_reveal(actor_cell)
			return true
		return false
	var started := Time.get_ticks_usec()
	for cell: Vector2i in visible_cells: image.set_pixelv(cell-bounds.position,Color(0,1,float(explored_cells[cell])/3.0,1))
	visible_cells.clear()
	origin=world_to_cell(position)
	blockers=dynamic_blockers.duplicate()
	active_space=selected
	disclosure_revision+=1
	var rect: Rect2 = spaces[selected].world_rect
	var begin := world_to_cell(rect.position)-Vector2i.ONE
	var end := world_to_cell(rect.end)+Vector2i.ONE
	for y in range(begin.y,end.y+1):
		for x in range(begin.x,end.x+1):
			var cell := Vector2i(x,y)
			var center := (Vector2(cell)+Vector2.ONE*0.5)*cell_size
			# One-cell wall faces around the disclosed room, never another room's floor.
			if terrain_at(cell)==1 and not rect.has_point(center): continue
			_reveal(cell)
	_reveal(origin)
	updates+=1
	last_compute_usec=Time.get_ticks_usec()-started
	return true

func _select_space(position: Vector2) -> int:
	# Room commitment only after actually entering; exit slack avoids threshold flicker.
	if active_space>=0:
		var previous: Rect2 = spaces[active_space].world_rect
		if previous.grow(hysteresis_pixels).has_point(position): return active_space
	for index in spaces.size():
		if spaces[index].kind == &"room" and spaces[index].world_rect.has_point(position): return index
	for index in spaces.size():
		if spaces[index].world_rect.has_point(position): return index
	return -1

func current_space() -> Dictionary:
	return spaces[active_space].duplicate() if active_space>=0 else {}
