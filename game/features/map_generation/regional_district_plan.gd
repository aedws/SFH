class_name RegionalDistrictPlan
extends RefCounted
## JSON-safe pure topology. Mirrored web model is gated by exported Godot fixtures.
const VERSION := 1
var state := 1
func _next() -> float:
	state = (state * 16807) % 2147483647
	return float(state - 1) / 2147483646.0
func _integer(low: int, high: int) -> int:
	return low + int(floor(_next() * (high - low + 1)))

func build(config: Dictionary, region: String, seed_value: int, facilities: Array) -> Dictionary:
	state = posmod(seed_value, 2147483646) + 1
	var count := int(floor((config.minimum_rooms + config.maximum_rooms) / 2.0))
	var columns := maxi(3, ceili(sqrt(float(count))))
	var rows := ceili(float(count) / columns)
	var stride: Array = [int(config.maximum_size[0]) + 28, int(config.maximum_size[1]) + 28]
	var exits: Array = [count - 1, columns - 1]
	var assigned := {}
	var required: Array = []
	var filler: Array = []
	for row: Dictionary in facilities:
		if row.encounter != "objective" and float(row.random_weight) > 0: filler.append(row)
		var regions := String(row.required_regions).split("|")
		if "*" in regions or region in regions: required.append(row)
	# Sheet row reordering cannot move landmarks or alter seeded filler choices.
	required.sort_custom(func(a,b): return String(a.facility_id) < String(b.facility_id))
	filler.sort_custom(func(a,b): return String(a.facility_id) < String(b.facility_id))
	var anchors := {"west":[0.0,0.5],"east":[1.0,0.5],"north":[0.5,0.0],"south":[0.5,1.0],"center":[0.5,0.5]}
	if filler.is_empty() or required.size() > count - 3: return {}
	for row: Dictionary in required:
		var target: Array = anchors[row.anchor_zone]
		var chosen := -1
		var distance := INF
		for index in count:
			if index == 0 or index in exits or assigned.has(index): continue
			var dx := float(index % columns) - float(target[0]) * (columns - 1)
			var dy := float(index / columns) - float(target[1]) * (rows - 1)
			var score := dx * dx + dy * dy
			if score < distance: chosen = index; distance = score
		if chosen >= 0: assigned[chosen] = row
	var buildings: Array = []
	var streets: Array = []
	var passages: Array = []
	for y in rows + 1:
		for x in columns: streets.append([x*stride[0],y*stride[1],stride[0]+8,8])
	for x in columns + 1:
		for y in rows: streets.append([x*stride[0],y*stride[1],8,stride[1]+8])
	for index in count:
		var is_required := assigned.has(index)
		var row: Dictionary
		if is_required: row = assigned[index]
		else:
			var total := 0.0
			for candidate: Dictionary in filler: total += float(candidate.random_weight)
			var choice := _next() * total
			row = filler.back()
			for candidate: Dictionary in filler:
				choice -= float(candidate.random_weight)
				if choice < 0: row = candidate; break
		var size: Array = []
		for axis in 2:
			var minimum := int(config.minimum_size[axis])
			var maximum := int(config.maximum_size[axis])
			var ratio := float(row.shape_x if axis == 0 else row.shape_y)
			size.append(minimum + int(floor((maximum-minimum)*ratio)) if is_required else _integer(minimum,maximum))
		var plot: Array = [index % columns, int(index / columns)]
		var x := int(plot[0]*stride[0]+floor((stride[0]-size[0])/2.0))
		var y := int(plot[1]*stride[1]+floor((stride[1]-size[1])/2.0))
		if not is_required: x += _integer(-3,3); y += _integer(-3,3)
		var axis := String(row.entrance_axis) if is_required else ("horizontal" if _integer(0,1)==0 else "vertical")
		var cx := x + int(size[0]/2)
		var cy := y + int(size[1]/2)
		if axis == "horizontal":
			passages.append([plot[0]*stride[0],cy-1,x-plot[0]*stride[0],3])
			passages.append([x+size[0],cy-1,(plot[0]+1)*stride[0]+8-x-size[0],3])
		else:
			passages.append([cx-1,plot[1]*stride[1],3,y-plot[1]*stride[1]])
			passages.append([cx-1,y+size[1],3,(plot[1]+1)*stride[1]+8-y-size[1]])
		buildings.append({"index":index,"plot":plot,"rect":[x,y,size[0],size[1]],"axis":axis,"facility_id":row.facility_id,"required":is_required})
	var result := {"version":VERSION,"region":region,"seed":seed_value,"count":count,"columns":columns,"rows":rows,"stride":stride,"buildings":buildings,"streets":streets,"passages":passages,"start":0,"exits":exits}
	return preload("res://game/features/map_generation/urban_block_layout.gd").new().apply(result,config) if config.get("urban_enabled",true) else result
