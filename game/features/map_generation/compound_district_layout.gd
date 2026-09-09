class_name CompoundDistrictLayout
extends RefCounted
## B: roads connect compounds; A/C shape providers own only occupied cells.
## Seeded topology carries no combat state. Difficulty is an immutable input.
func build(plan: Dictionary, difficulty: Dictionary) -> Dictionary:
	var layout := preload("res://game/features/map_generation/district_layout.gd").new()
	# Remove odd interior streets: a 2x2 plot group is one closed compound.
	var xs: Array[int] = []
	var ys: Array[int] = []
	for axis: Dictionary in plan.street_axes:
		if axis.axis == "vertical": xs.append(int(axis.at))
		else: ys.append(int(axis.at))
	var roads: Array = []
	for road: Array in plan.streets:
		var vertical: bool = int(road[3]) > int(road[2])
		var axes: Array[int] = xs if vertical else ys
		var index := axes.find(int(road[0]) if vertical else int(road[1]))
		if index % 2 == 0 or index == axes.size()-1: roads.append(road)
	plan.streets = roads
	var retained_axes: Array = []
	for axis: Dictionary in plan.street_axes:
		var axis_list: Array[int] = xs if axis.axis=="vertical" else ys
		var axis_index := axis_list.find(int(axis.at))
		if axis_index%2==0 or axis_index==axis_list.size()-1: retained_axes.append(axis)
	plan.street_axes = retained_axes
	plan.yards = []
	plan.passages = []
	var result: Dictionary = layout.from_regional_plan(plan)
	var floors := {}
	var spaces: Array[Dictionary] = []
	var memberships: Array[Dictionary] = []
	var routes: Array[Dictionary] = []
	var depths := {}
	var ratio := clampf(float(difficulty.get("polygon_ratio",0)),0,1)
	# Keep the outer road network; plots are closed sites, not traversable spare yards.
	for road: Array in plan.streets:
		_add_space(Rect2i(road[0],road[1],road[2],road[3]),&"street",floors,spaces)
	var groups := {}
	for building: Dictionary in plan.buildings:
		var index := int(building.index)
		var key := Vector2i(int(building.plot[0])/2,int(building.plot[1])/2)
		if not groups.has(key): groups[key]=[]
		groups[key].append(index)
		var r: Array = building.rect
		var rect := Rect2i(r[0],r[1],r[2],r[3])
		var special: bool = index==0 or index in plan.exits
		var shape_seed := 0 if building.required else int(plan.seed)
		var roll := float(posmod(index*7919+shape_seed,1000))/1000.0
		var occupied: Dictionary = preload("res://game/features/map_generation/compound_space_shape.gd").cells(rect,index+shape_seed,not special and roll<ratio)
		building["shape_variant"]=posmod(index+shape_seed,4)
		building["polygonal"]=not special and roll<ratio
		memberships.append(occupied)
		for cell: Vector2i in occupied: floors[cell]=true
		spaces.append({&"space_id":spaces.size(),&"cell_rect":rect,&"kind":&"room",&"room_index":index,&"cells":occupied.duplicate()})
	for key: Vector2i in groups:
		var members: Array = groups[key]
		# Keep objective away from the external entrance. Stable order is role-aware.
		members.sort_custom(func(a,b):
			var av: bool = plan.buildings[a].facility_id=="vault"
			var bv: bool = plan.buildings[b].facility_id=="vault"
			return a<b if av==bv else not av)
		for order in members.size(): depths[members[order]]=order
		var front: int = members[0]
		var left := xs[key.x*2]+2
		_connect_street(front,left,plan,floors,spaces,routes)
		for order in range(1,members.size()):
			_connect_rooms(int(members[order-1]),int(members[order]),plan,floors,spaces,routes)
		# A second route to the same deep target has a different approach and length.
		if members.size()>2:
			_connect_rooms(front,int(members.back()),plan,floors,spaces,routes,true)
		for index: int in members:
			if (index==0 or index in plan.exits) and index!=front:
				_connect_street(index,xs[mini(key.x*2+2,xs.size()-1)]+2,plan,floors,spaces,routes)
	# Passage masks exclude rooms; irregular cutouts remain outside room disclosure.
	var all_rooms := {}
	for membership: Dictionary in memberships: all_rooms.merge(membership)
	for space: Dictionary in spaces:
		if space.kind == &"room": continue
		var mask := {}
		var rect: Rect2i = space.cell_rect
		for y in range(rect.position.y,rect.end.y):
			for x in range(rect.position.x,rect.end.x):
				var cell := Vector2i(x,y)
				if floors.has(cell) and not all_rooms.has(cell): mask[cell]=true
		space["cells"]=mask
	plan["compound_count"]=groups.size()
	plan["polygon_ratio"]=ratio
	plan["compound_routes"]=routes.duplicate(true)
	# Graph minimum depth, not the obsolete distance from a rectangular plot centre.
	depths.clear()
	var pending: Array[int] = []
	for route: Dictionary in routes:
		if route.from == -1: depths[route.to]=0; pending.append(route.to)
	var cursor := 0
	while cursor < pending.size():
		var at := pending[cursor]
		cursor+=1
		for route: Dictionary in routes:
			if route.from==-1: continue
			var neighbor: int = route.to if route.from==at else (route.from if route.to==at else -1)
			if neighbor>=0 and not depths.has(neighbor): depths[neighbor]=int(depths[at])+1; pending.append(neighbor)
	result.floor_cells=floors
	result.spaces=spaces
	result["room_cells"]=memberships
	result["routes"]=routes
	result["depths"]=depths
	result["compound_count"]=groups.size()
	return result

func _center(index: int, plan: Dictionary) -> Vector2i:
	var r: Array = plan.buildings[index].rect
	return Vector2i(int(r[0])+int(r[2])/2,int(r[1])+int(r[3])/2)

func _connect_street(index: int, road_x: int, plan: Dictionary, floors: Dictionary, spaces: Array[Dictionary], routes: Array[Dictionary]) -> void:
	var center := _center(index,plan)
	var target := Vector2i(road_x,center.y)
	_carve(center,target,5,plan,floors,spaces)
	routes.append({"from":-1,"to":index,"kind":"front","width":5})

func _connect_rooms(a: int,b: int,plan: Dictionary,floors: Dictionary,spaces: Array[Dictionary],routes: Array[Dictionary],alternate: bool=false) -> void:
	var start := _center(a,plan)
	var end := _center(b,plan)
	var elbow := Vector2i(start.x,end.y) if alternate else Vector2i(end.x,start.y)
	_carve(start,elbow,5,plan,floors,spaces)
	_carve(elbow,end,5,plan,floors,spaces)
	routes.append({"from":a,"to":b,"kind":"rear" if alternate else "interior","width":5})

func _carve(a: Vector2i,b: Vector2i,width: int,plan: Dictionary,floors: Dictionary,spaces: Array[Dictionary]) -> void:
	var rect := Rect2i(mini(a.x,b.x)-width/2,mini(a.y,b.y)-width/2,absi(a.x-b.x)+width,absi(a.y-b.y)+width)
	_add_space(rect,&"passage",floors,spaces)
	plan.passages.append([rect.position.x,rect.position.y,rect.size.x,rect.size.y])

func _add_space(rect: Rect2i,kind: StringName,floors: Dictionary,spaces: Array[Dictionary]) -> void:
	spaces.append({&"space_id":spaces.size(),&"cell_rect":rect,&"kind":kind,&"room_index":-1})
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x): floors[Vector2i(x,y)]=true
