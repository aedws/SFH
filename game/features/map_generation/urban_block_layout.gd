class_name UrbanBlockLayout
extends Resource
## Street-first, JSON-safe geometry adapter. No actors, rewards or save state.
@export_range(8, 20) var avenue_width := 14
@export_range(6, 14) var local_width := 10
@export_range(2, 5) var sidewalk_width := 3
@export_range(3, 7) var entrance_width := 5

func settings() -> Dictionary:
	return {"avenue_width":avenue_width,"local_width":local_width,"sidewalk_width":sidewalk_width,"entrance_width":entrance_width}

func apply(source: Dictionary, config: Dictionary) -> Dictionary:
	var plan := source.duplicate(true)
	var options: Dictionary = config.get("urban",settings())
	var main := clampi(int(options.get("avenue_width",avenue_width)),8,20)
	var local := clampi(int(options.get("local_width",local_width)),6,14)
	var sidewalk := clampi(int(options.get("sidewalk_width",sidewalk_width)),2,5)
	var door := clampi(int(options.get("entrance_width",entrance_width)),3,7)
	# Street hierarchy and unequal blocks are stable landmarks, filler footprints vary by seed.
	var phase := 1 if plan.region == "industrial_district" else (2 if plan.region == "research_complex" else 0)
	var xs: Array = [0]
	var ys: Array = [0]
	var x_widths: Array = []
	var y_widths: Array = []
	for x in int(plan.columns)+1:
		x_widths.append(main if x % 3 == 0 else local)
		if x < int(plan.columns): xs.append(int(xs.back())+int(config.maximum_size[0])+int(x_widths.back())+sidewalk*2+8+((x+phase)%3)*6)
	for y in int(plan.rows)+1:
		y_widths.append(main if y % 3 == 0 else local)
		if y < int(plan.rows): ys.append(int(ys.back())+int(config.maximum_size[1])+int(y_widths.back())+sidewalk*2+8+((y+phase+1)%3)*5)
	plan.streets=[]
	plan.passages=[]
	plan.yards=[]
	plan.street_axes=[]
	for y in int(plan.rows)+1:
		for x in int(plan.columns):
			plan.streets.append([xs[x],ys[y],int(xs[x+1])-int(xs[x])+int(x_widths[x+1]),y_widths[y]])
		plan.street_axes.append({"axis":"horizontal","at":ys[y],"width":y_widths[y]})
	for x in int(plan.columns)+1:
		for y in int(plan.rows):
			plan.streets.append([xs[x],ys[y],x_widths[x],int(ys[y+1])-int(ys[y])+int(y_widths[y+1])])
		plan.street_axes.append({"axis":"vertical","at":xs[x],"width":x_widths[x]})
	for building: Dictionary in plan.buildings:
		var px := int(building.plot[0]); var py := int(building.plot[1])
		var lot := [int(xs[px])+int(x_widths[px]),int(ys[py])+int(y_widths[py]),int(xs[px+1]),int(ys[py+1])]
		var size := Vector2i(building.rect[2],building.rect[3])
		var horizontal: bool = building.axis == "horizontal"
		var x := int(lot[0])+sidewalk+2 if horizontal else int(lot[0])+int(floor((int(lot[2])-int(lot[0])-size.x)/2.0))
		var y := int(lot[1])+int(floor((int(lot[3])-int(lot[1])-size.y)/2.0)) if horizontal else int(lot[1])+sidewalk+2
		# Rear service courts are the leftover lot, never a black, inaccessible moat.
		building.rect=[x,y,size.x,size.y]
		building.lot=[lot[0],lot[1],int(lot[2])-int(lot[0]),int(lot[3])-int(lot[1])]
		var bands := [[lot[0],lot[1],int(lot[2])-int(lot[0]),y-int(lot[1])-1],
			[lot[0],y+size.y+1,int(lot[2])-int(lot[0]),int(lot[3])-y-size.y-1],
			[lot[0],y-1,x-int(lot[0])-1,size.y+2],
			[x+size.x+1,y-1,int(lot[2])-x-size.x-1,size.y+2]]
		for band: Array in bands:
			if int(band[2])>0 and int(band[3])>0: plan.yards.append(band)
		var cx := x+size.x/2; var cy := y+size.y/2
		var half := door/2
		if horizontal:
			plan.passages.append([lot[0],cy-half,x-int(lot[0]),door])
			plan.passages.append([x+size.x,cy-half,int(lot[2])-x-size.x,door])
		else:
			plan.passages.append([cx-half,lot[1],door,y-int(lot[1])])
			plan.passages.append([cx-half,y+size.y,door,int(lot[3])-y-size.y])
	plan.version=2
	plan.urban_settings={"avenue_width":main,"local_width":local,"sidewalk_width":sidewalk,"entrance_width":door}
	plan.extent=[int(xs.back())+int(x_widths.back()),int(ys.back())+int(y_widths.back())]
	return plan
