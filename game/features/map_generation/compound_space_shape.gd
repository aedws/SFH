class_name CompoundSpaceShape
extends RefCounted
## Pure cell geometry. Rectangles are broad-phase bounds, never room membership.
static func cells(rect: Rect2i, variant: int, polygonal: bool) -> Dictionary:
	var result := {}
	var size := Vector2(rect.size)
	var polygon := PackedVector2Array([Vector2(0, size.y*0.18), Vector2(size.x*0.23,0), Vector2(size.x*0.82,0), Vector2(size.x,size.y*0.24), Vector2(size.x*0.92,size.y), Vector2(size.x*0.17,size.y), Vector2(0,size.y*0.76)])
	for y in rect.size.y:
		for x in rect.size.x:
			var p := Vector2(x+0.5,y+0.5)
			var keep := true
			if polygonal:
				keep = Geometry2D.is_point_in_polygon(p,polygon)
			else:
				match posmod(variant,4):
					0: keep = not (p.x > size.x*0.65 and p.y < size.y*0.35) # L
					1: keep = not (p.y > size.y*0.66 and (p.x < size.x*0.25 or p.x > size.x*0.75)) # T
					2: keep = not (p.x > size.x*0.3 and p.x < size.x*0.7 and p.y < size.y*0.32) # U
					3: keep = not (p.x > size.x*0.62 and p.x < size.x*0.83 and p.y > size.y*0.15 and p.y < size.y*0.37) # courtyard
			# A continuous 5-cell cross guarantees existing portal axes and actor clearance.
			if absf(p.x-size.x*0.5)<2.5 or absf(p.y-size.y*0.5)<2.5: keep=true
			if keep: result[rect.position+Vector2i(x,y)]=true
	return result
