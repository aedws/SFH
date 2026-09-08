class_name InventoryItemPreview
extends Control
const ART = preload("res://game/features/inventory/inventory_item_art.gd")
var entry: Dictionary = {}

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func present(value: Dictionary) -> void:
	entry = value.duplicate()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("091b26"))
	var tint: Color = entry.get(&"panel_color", ART.ACCENT)
	draw_line(Vector2(0, size.y-1), Vector2(size.x,size.y-1), Color(tint,0.7),2)
	if entry.is_empty():
		draw_circle(size*0.5, minf(size.x,size.y)*0.23,Color("47616c"),false,1)
		draw_line(size*0.5-Vector2(12,0),size*0.5+Vector2(12,0),Color("47616c"),2)
	else:
		ART.draw_item(self, Rect2(Vector2(12,8), size-Vector2(24,16)), entry)
