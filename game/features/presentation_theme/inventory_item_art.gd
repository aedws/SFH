class_name InventoryItemArt
extends RefCounted
## Shared read-only item silhouettes. No inventory/equipment ownership or decisions.

const ACCENT := Color("02e5e1")
const LABELS := {&"weapon":"무기", &"armor":"방어구", &"part":"고유 파츠", &"module":"모듈", &"consumable":"소모품"}

static func property(resource: Resource, key: StringName, fallback: Variant = null) -> Variant:
	if resource != null:
		for descriptor in resource.get_property_list():
			if descriptor.name == key: return resource.get(key)
	return fallback

static func key_for(entry: Dictionary) -> StringName:
	var kind: StringName = entry.get(&"item_type", &"")
	var definition: Resource = entry.get(&"linked_resource")
	if kind == &"weapon":
		var minor: StringName = property(property(definition, &"tags"), &"minor_tag", &"weapon")
		return minor if minor in [&"rifle",&"pistol",&"dagger",&"greatsword"] else &"weapon"
	if kind == &"armor": return property(definition, &"slot_id", &"armor")
	if kind == &"part": return property(definition, &"socket_id", &"part")
	return kind

static func draw_item(canvas: CanvasItem, rect: Rect2, entry: Dictionary) -> void:
	if rect.size.x < 4 or rect.size.y < 4: return
	var key := key_for(entry)
	var rotated: bool = entry.get(&"rotated", false)
	var available := Vector2(rect.size.y, rect.size.x) if rotated else rect.size
	var scale_factor := minf(available.x / 120.0, available.y / 70.0)
	canvas.draw_set_transform(rect.get_center(), PI * 0.5 if rotated else 0.0, Vector2.ONE * scale_factor)
	var steel := Color("a8bec8")
	var shade := Color("425e6b")
	var light := Color("e4f4f6")
	match key:
		&"rifle", &"weapon":
			canvas.draw_rect(Rect2(-36,-12,63,20), steel)
			canvas.draw_rect(Rect2(-57,-7,24,6), light)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(27,-10),Vector2(51,-4),Vector2(49,15),Vector2(26,6)]), shade)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-4,8),Vector2(12,8),Vector2(7,29),Vector2(-8,24)]), shade)
			canvas.draw_rect(Rect2(-22,-18,32,4), shade)
			for x in range(-31,-6,8): canvas.draw_rect(Rect2(x,-8,3,8), shade)
			canvas.draw_line(Vector2(-36,-11),Vector2(26,-11),ACCENT,2)
		&"pistol":
			canvas.draw_rect(Rect2(-39,-15,72,17), steel)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(10,1),Vector2(31,1),Vector2(21,30),Vector2(2,26)]), shade)
			canvas.draw_line(Vector2(-37,-12),Vector2(30,-12),light,3)
			canvas.draw_arc(Vector2(4,8),10,0,PI,12,steel,3)
		&"dagger", &"greatsword", &"blade":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-30,-9),Vector2(37,-6),Vector2(55,0),Vector2(37,6),Vector2(-30,9)]),steel)
			canvas.draw_line(Vector2(-30,0),Vector2(47,0),light,2)
			canvas.draw_line(Vector2(-33,-20),Vector2(-33,20),ACCENT,5)
			canvas.draw_rect(Rect2(-55,-5,21,10),shade)
		&"body", &"armor":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-25,-30),Vector2(-11,-30),Vector2(-8,-17),Vector2(8,-17),Vector2(11,-30),Vector2(25,-30),Vector2(34,24),Vector2(0,32),Vector2(-34,24)]),shade)
			canvas.draw_rect(Rect2(-23,-10,46,31),steel)
			canvas.draw_line(Vector2(0,-9),Vector2(0,22),shade,3)
			canvas.draw_line(Vector2(-22,4),Vector2(23,4),shade,3)
			canvas.draw_rect(Rect2(-7,-9,14,4),ACCENT)
		&"head":
			canvas.draw_circle(Vector2.ZERO, 29, shade)
			canvas.draw_rect(Rect2(-29,-10,58,24), steel)
			canvas.draw_rect(Rect2(-22,-5,44,9), ACCENT)
			canvas.draw_rect(Rect2(-15,18,30,10), steel)
		&"hands":
			for x in [-30,5]:
				canvas.draw_rect(Rect2(x,-7,25,32),steel)
				for finger in range(4): canvas.draw_rect(Rect2(x+finger*6,-24,5,24),shade)
				canvas.draw_rect(Rect2(x+3,2,19,5),ACCENT)
		&"feet":
			for x in [-28,6]:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x,-27),Vector2(x+22,-27),Vector2(x+22,12),Vector2(x+35,21),Vector2(x+35,30),Vector2(x,30)]),steel)
				canvas.draw_rect(Rect2(x,25,35,5),shade)
				for y in range(-19,6,7): canvas.draw_line(Vector2(x+3,y),Vector2(x+18,y),shade,3)
		&"optic":
			canvas.draw_rect(Rect2(-30,-14,53,28),shade)
			canvas.draw_circle(Vector2(25,0),21,steel)
			canvas.draw_circle(Vector2(25,0),15,Color("10323c"))
			canvas.draw_line(Vector2(15,0),Vector2(35,0),ACCENT,2)
			canvas.draw_line(Vector2(25,-10),Vector2(25,10),ACCENT,2)
			canvas.draw_rect(Rect2(-18,14,24,9),steel)
		&"magazine":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-18,-28),Vector2(13,-28),Vector2(20,10),Vector2(9,30),Vector2(-22,21)]),steel)
			for y in range(-20,22,9): canvas.draw_line(Vector2(-13,y),Vector2(9,y+2),shade,3)
		&"muzzle", &"part":
			canvas.draw_rect(Rect2(-40,-13,80,26),steel)
			for x in range(-31,34,12): canvas.draw_rect(Rect2(x,-10,5,20),shade)
			canvas.draw_rect(Rect2(-46,-9,6,18),ACCENT)
		&"module":
			canvas.draw_rect(Rect2(-26,-26,52,52),shade)
			canvas.draw_rect(Rect2(-19,-19,38,38),steel,false,2)
			for x in [-17,0,17]:
				canvas.draw_line(Vector2(x,-34),Vector2(x,-25),steel,3)
				canvas.draw_line(Vector2(x,25),Vector2(x,34),steel,3)
			var tags: Array = property(entry.get(&"linked_resource"), &"module_tags", [])
			if &"survival" in tags:
				canvas.draw_rect(Rect2(-5,-14,10,28),light)
				canvas.draw_rect(Rect2(-14,-5,28,10),light)
			elif &"defense" in tags:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(-13,-14),Vector2(13,-14),Vector2(11,7),Vector2(0,16),Vector2(-11,7)]),light)
			elif &"mobility" in tags:
				for x in [-12,0]: canvas.draw_polyline(PackedVector2Array([Vector2(x,-12),Vector2(x+11,0),Vector2(x,12)]),light,4)
			elif &"ballistic" in tags:
				canvas.draw_circle(Vector2.ZERO,12,light,false,3)
				canvas.draw_line(Vector2(-17,0),Vector2(17,0),light,2)
				canvas.draw_line(Vector2(0,-17),Vector2(0,17),light,2)
			else: canvas.draw_colored_polygon(PackedVector2Array([Vector2(3,-15),Vector2(-10,3),Vector2(0,3),Vector2(-3,16),Vector2(12,-3),Vector2(3,-3)]),ACCENT)
		&"consumable":
			canvas.draw_rect(Rect2(-30,-22,60,47),shade)
			canvas.draw_rect(Rect2(-15,-29,30,7),steel,false,3)
			canvas.draw_rect(Rect2(-7,-14,14,29),light)
			canvas.draw_rect(Rect2(-21,-6,42,13),light)
		_:
			canvas.draw_rect(Rect2(-30,-24,60,48),shade)
			canvas.draw_rect(Rect2(-30,-24,60,48),steel,false,3)
			canvas.draw_line(Vector2(-24,-18),Vector2(24,18),steel,3)
	canvas.draw_set_transform(Vector2.ZERO)
