class_name ExtractionDistrictLayout
extends Resource
## Pure seeded street/plot topology. No actors, combat, rewards or visibility state.
@export_range(6, 16) var street_width := 8
@export_range(6, 24) var plot_margin := 10
@export_range(0, 4) var plot_jitter := 3

func build(config: Resource, rng: RandomNumberGenerator, count: int) -> Dictionary:
	var columns := maxi(3, ceili(sqrt(float(count))) + rng.randi_range(-1, 1))
	var rows := ceili(float(count) / columns)
	var stride: Vector2i = config.maximum_room_size + Vector2i.ONE * (plot_margin * 2 + street_width)
	var floors: Dictionary = {}
	var rooms: Array[Rect2i] = []
	var spaces: Array[Dictionary] = []
	var plots: Array[Vector2i] = []
	# Roads form cycles independently of buildings: no mandatory room crossing.
	for y in rows + 1:
		for x in columns:
			_add_space(Rect2i(x*stride.x, y*stride.y, stride.x+street_width, street_width), &"street", floors, spaces)
	for x in columns + 1:
		for y in rows:
			_add_space(Rect2i(x*stride.x, y*stride.y, street_width, stride.y+street_width), &"street", floors, spaces)
	for index in count:
		var plot := Vector2i(index % columns, index / columns)
		plots.append(plot)
		var size := Vector2i(rng.randi_range(config.minimum_room_size.x, config.maximum_room_size.x), rng.randi_range(config.minimum_room_size.y, config.maximum_room_size.y))
		var origin := plot * stride + (stride - size) / 2 + Vector2i(rng.randi_range(-plot_jitter,plot_jitter),rng.randi_range(-plot_jitter,plot_jitter))
		var room := Rect2i(origin,size)
		rooms.append(room)
		_add_space(room, &"room", floors, spaces, index)
		var center := origin + size / 2
		# Every facility has two separate exits to the surrounding street loop.
		if rng.randi_range(0,1) == 0:
			_add_space(Rect2i(plot.x*stride.x,center.y-1,origin.x-plot.x*stride.x,3),&"passage",floors,spaces)
			_add_space(Rect2i(room.end.x,center.y-1,(plot.x+1)*stride.x+street_width-room.end.x,3),&"passage",floors,spaces)
		else:
			_add_space(Rect2i(center.x-1,plot.y*stride.y,3,origin.y-plot.y*stride.y),&"passage",floors,spaces)
			_add_space(Rect2i(center.x-1,room.end.y,3,(plot.y+1)*stride.y+street_width-room.end.y),&"passage",floors,spaces)
	return {&"rooms":rooms,&"floor_cells":floors,&"spaces":spaces,&"plots":plots,&"columns":columns,&"rows":rows,&"stride":stride}

func _add_space(rect: Rect2i, kind: StringName, floors: Dictionary, spaces: Array[Dictionary], room_index: int = -1) -> void:
	spaces.append({&"space_id":spaces.size(),&"cell_rect":rect,&"kind":kind,&"room_index":room_index})
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x): floors[Vector2i(x,y)] = true

func from_regional_plan(plan: Dictionary) -> Dictionary:
	var floors := {}
	var spaces: Array[Dictionary] = []
	var rooms: Array[Rect2i] = []
	var plots: Array[Vector2i] = []
	for rect: Array in plan.streets: _add_space(Rect2i(rect[0],rect[1],rect[2],rect[3]), &"street", floors, spaces)
	for building: Dictionary in plan.buildings:
		var r: Array = building.rect
		var room := Rect2i(r[0],r[1],r[2],r[3])
		rooms.append(room)
		plots.append(Vector2i(building.plot[0],building.plot[1]))
		_add_space(room,&"room",floors,spaces,int(building.index))
	for rect: Array in plan.passages: _add_space(Rect2i(rect[0],rect[1],rect[2],rect[3]), &"passage", floors, spaces)
	return {&"rooms":rooms,&"floor_cells":floors,&"spaces":spaces,&"plots":plots,&"columns":plan.columns,&"rows":plan.rows,&"stride":Vector2i(plan.stride[0],plan.stride[1])}
