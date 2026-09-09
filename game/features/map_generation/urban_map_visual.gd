class_name UrbanMapVisual
extends Node2D
## Original procedural city art. Static geometry is cached, never rebuilt per frame.
@export var asphalt := Color("252c31")
@export var paving := Color("4d575b")
@export var concrete := Color("3d484c")
@export var curb := Color("a1aaa6")
@export var lane := Color("c8b67a")
var plan: Dictionary = {}
var cell_size := 32.0
var wall_rects: Array = []
var props: Array = []

func surface_colors(geometry: Dictionary, cells: Dictionary) -> Dictionary:
	var colors := {}
	_paint(colors,geometry.get("yards",[]),paving)
	_paint(colors,geometry.streets,asphalt)
	_paint(colors,geometry.passages,paving.lightened(0.06))
	for building: Dictionary in geometry.buildings:
		var tint := concrete
		match building.facility_id:
			"warehouse": tint=Color("49463f")
			"medical": tint=Color("3d5352")
			"vault": tint=Color("323e4b")
			"transit_square": tint=Color("51544b")
		_paint(colors,[building.rect],tint)
	# A cell's shade is stable across chunks; no giant checkerboard or random frame noise.
	for cell: Vector2i in colors:
		if not cells.has(cell): colors.erase(cell); continue
		var grain := float(posmod(cell.x*73+cell.y*151,7)-3)*0.002
		colors[cell]=Color(colors[cell])+Color(grain,grain,grain,0)
	return colors

func _paint(colors: Dictionary, rectangles: Array, color: Color) -> void:
	for r: Array in rectangles:
		for y in range(int(r[1]),int(r[1])+int(r[3])):
			for x in range(int(r[0]),int(r[0])+int(r[2])): colors[Vector2i(x,y)]=color

func configure(geometry: Dictionary, size: float, walls: Array, obstacles: Array) -> void:
	plan=geometry.duplicate(true)
	cell_size=size
	wall_rects=walls.duplicate()
	props=obstacles.duplicate()
	queue_redraw()

func _rect(values: Array) -> Rect2:
	return Rect2(values[0]*cell_size,values[1]*cell_size,values[2]*cell_size,values[3]*cell_size)

func _draw() -> void:
	if plan.is_empty(): return
	for r: Array in plan.streets:
		var rect := _rect(r)
		var horizontal: bool = int(r[2])>int(r[3])
		var length := rect.size.x if horizontal else rect.size.y
		var width := rect.size.y if horizontal else rect.size.x
		# Painted shoulders, not raised obstacles: intersection turns remain walkable.
		for offset in [0.0,width-cell_size*1.5]:
			var shoulder := Rect2(rect.position+(Vector2(0,offset) if horizontal else Vector2(offset,0)),Vector2(length,cell_size*1.5) if horizontal else Vector2(cell_size*1.5,length))
			draw_rect(shoulder,Color("384247"))
		# Sidewalk seams and lane dashes; roads remain unobstructed playable space.
		for offset in [cell_size*2.0,width-cell_size*2.0]:
			var p := rect.position+(Vector2(0,offset) if horizontal else Vector2(offset,0))
			draw_line(p,p+(Vector2(length,0) if horizontal else Vector2(0,length)),curb.darkened(0.3),3)
		for step in range(3,int(length/cell_size)-2,6):
			var p := rect.position+(Vector2(step*cell_size,width*0.5) if horizontal else Vector2(width*0.5,step*cell_size))
			draw_line(p,p+(Vector2(cell_size*2,0) if horizontal else Vector2(0,cell_size*2)),lane,3)
		# Direction arrows are road paint, with a paired opposite lane.
		for sign in [-1.0,1.0]:
			var direction := Vector2(sign,0) if horizontal else Vector2(0,sign)
			var p := rect.get_center()+(Vector2(0,sign*width*0.23) if horizontal else Vector2(-sign*width*0.23,0))
			draw_line(p-direction*22,p+direction*22,Color(curb,0.55),5)
			draw_line(p+direction*22,p+direction*5+direction.orthogonal()*12,Color(curb,0.55),5)
			draw_line(p+direction*22,p+direction*5-direction.orthogonal()*12,Color(curb,0.55),5)
	# Crosswalks announce intersections before a player chooses a turn.
	var horizontal_axes: Array = plan.street_axes.filter(func(a): return a.axis=="horizontal")
	var vertical_axes: Array = plan.street_axes.filter(func(a): return a.axis=="vertical")
	for h: Dictionary in horizontal_axes:
		for v: Dictionary in vertical_axes:
			for stripe in range(2,int(v.width)-2,2):
				draw_rect(Rect2((float(v.at)+stripe)*cell_size,(float(h.at)+2)*cell_size,cell_size,cell_size*2),Color(curb,0.6))
	for b: Dictionary in plan.buildings:
		if plan.has("compound_count"): continue # Irregular outlines are rendered from collision strips below.
		var room := _rect(b.rect)
		# Wall-base wear and a painted service perimeter give interiors a readable scale.
		draw_rect(room.grow(-10),Color(0.04,0.08,0.09,0.22),false,20)
		draw_rect(room.grow(-cell_size*2),Color(0.7,0.79,0.77,0.12),false,2)
		# Large slab joints replace the tiny debug grid.
		for x in range(int(b.rect[0])+4,int(b.rect[0])+int(b.rect[2]),4):
			draw_line(Vector2(x*cell_size,room.position.y),Vector2(x*cell_size,room.end.y),Color(0,0,0,0.09),1)
		for y in range(int(b.rect[1])+4,int(b.rect[1])+int(b.rect[3]),4):
			draw_line(Vector2(room.position.x,y*cell_size),Vector2(room.end.x,y*cell_size),Color(0,0,0,0.09),1)
		# Ground-painted loading bays in rear courts, not fake non-colliding props.
		var lot := _rect(b.lot)
		# Paved lot boundaries are subtle enough not to resemble collision walls.
		draw_rect(lot.grow(-6),Color(curb,0.18),false,2)
		if b.axis=="horizontal":
			for y in range(int(room.position.y/cell_size)+3,int(room.end.y/cell_size)-3,5):
				var bay := Rect2(room.end.x+cell_size*2,y*cell_size,maxf(cell_size,lot.end.x-room.end.x-cell_size*3),cell_size*3)
				draw_rect(bay,Color(curb,0.4),false,2)
		else:
			for x in range(int(room.position.x/cell_size)+3,int(room.end.x/cell_size)-3,6):
				var bay := Rect2(x*cell_size,room.end.y+cell_size*2,cell_size*3,maxf(cell_size,lot.end.y-room.end.y-cell_size*3))
				draw_rect(bay,Color(curb,0.4),false,2)
	# Joined wall strips communicate building facades rather than individual obstacle tiles.
	for r: Rect2i in wall_rects:
		var rect := Rect2(Vector2(r.position)*cell_size,Vector2(r.size)*cell_size)
		draw_rect(rect,Color("1b242b"))
		draw_rect(rect.grow(-4),Color("637370"))
		draw_line(rect.position+Vector2(3,3),rect.position+Vector2(rect.size.x-3,3),Color("c0ccc4"),3)
		var horizontal := rect.size.x>=rect.size.y
		var length := rect.size.x if horizontal else rect.size.y
		for step in range(2,int(length/cell_size)-1,5):
			var panel := Rect2(rect.position+(Vector2(step*cell_size,8) if horizontal else Vector2(8,step*cell_size)),Vector2(cell_size*1.5,14) if horizontal else Vector2(14,cell_size*1.5))
			draw_rect(panel,Color("152d35"))
			draw_rect(panel.grow(-3),Color("507e87"))
	for r: Rect2i in props:
		var rect := Rect2(Vector2(r.position)*cell_size,Vector2(r.size)*cell_size).grow(-2)
		draw_rect(rect,Color("252d30"))
		draw_rect(rect.grow(-4),Color("7b7765"))
		draw_line(rect.position+Vector2(5,5),rect.position+Vector2(rect.size.x-5,5),Color("c0ac70"),2)
		# Shelving / service stations occupy exactly their existing collision footprint.
		var medical := false
		for b: Dictionary in plan.buildings:
			if _rect(b.rect).has_point(rect.get_center()):
				medical=b.facility_id=="medical"
				break
		if medical:
			draw_rect(rect.grow(-10),Color("92aca8"))
			draw_rect(Rect2(rect.position+Vector2(13,13),Vector2(rect.size.x-26,18)),Color("d4ded2"))
			draw_line(rect.get_center()-Vector2(9,0),rect.get_center()+Vector2(9,0),Color("3e6d62"),5)
			draw_line(rect.get_center()-Vector2(0,9),rect.get_center()+Vector2(0,9),Color("3e6d62"),5)
		else:
			for x in range(10,int(rect.size.x)-20,28):
				for y in range(10,int(rect.size.y)-20,28):
					var box := Rect2(rect.position+Vector2(x,y),Vector2(22,22))
					draw_rect(box,Color("414f56"))
					draw_line(box.position+Vector2(3,4),box.position+Vector2(19,4),Color("849596"),3)
			draw_rect(rect.grow(-5),Color("adb59e"),false,2)
	for r: Array in plan.passages:
		var rect := _rect(r)
		var horizontal: bool = int(r[2])>int(r[3])
		var p := rect.get_center()
		var direction := Vector2.RIGHT if horizontal else Vector2.DOWN
		draw_line(p-direction*14,p+direction*14,Color("02e5e1"),3)
		draw_circle(p,4,Color("02e5e1"))
