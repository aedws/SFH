class_name UrbanInteriorLayout
extends RefCounted
## Fixture islands aligned to a building's use; all central door-to-door lanes stay clear.
func patterns(room: Rect2i, facility: String, density: float, rng: RandomNumberGenerator) -> Array:
	var result: Array = []
	var budget := maxi(1,roundi(room.get_area()*density))
	var horizontal := facility in ["warehouse","workshop"]
	var size := Vector2i(5,2) if horizontal else Vector2i(2,3)
	var center := room.position+room.size/2
	var candidates: Array = []
	for y in range(room.position.y+4,room.end.y-size.y-4,7):
		for x in range(room.position.x+4,room.end.x-size.x-4,9):
			var rect := Rect2i(Vector2i(x,y),size)
			if rect.grow(2).has_point(Vector2i(center.x,y)) or rect.grow(2).has_point(Vector2i(x,center.y)): continue
			candidates.append(rect)
	# Keep a common alignment while varying which shelving/work islands are occupied.
	while budget>0 and not candidates.is_empty():
		var slot := rng.randi_range(0,candidates.size()-1)
		var rect: Rect2i = candidates[slot]
		candidates.remove_at(slot)
		var cells: Array[Vector2i] = []
		for y in range(rect.position.y,rect.end.y):
			for x in range(rect.position.x,rect.end.x): cells.append(Vector2i(x,y))
		if cells.size()>budget: continue
		result.append(cells)
		budget-=cells.size()
	return result
