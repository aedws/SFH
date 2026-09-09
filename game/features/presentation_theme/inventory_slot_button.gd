class_name InventorySlotButton
extends Button

signal item_dropped(instance_id: StringName)
var accepts_item: Callable
const ART = preload("res://game/features/presentation_theme/inventory_item_art.gd")
var presentation: Dictionary = {}
var slot_label := ""
var item_label := "빈 슬롯"
var selected := false

func present(label: String, item: String, entry: Dictionary, is_selected: bool) -> void:
	slot_label = label
	item_label = item
	presentation = entry
	selected = is_selected
	text = label + " · " + item # Native accessibility retains an explicit button name.
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	queue_redraw()

func _draw() -> void:
	var ink := Color("edf6f8") if not disabled else Color("69818b")
	var rect := Rect2(Vector2(8,25), Vector2(size.x-16,size.y-48))
	if not presentation.is_empty(): ART.draw_item(self,rect,presentation)
	draw_string(get_theme_default_font(),Vector2(9,18),slot_label,HORIZONTAL_ALIGNMENT_LEFT,size.x-18,11,ART.ACCENT if selected else Color("a1b8c2"))
	draw_string(get_theme_default_font(),Vector2(9,size.y-9),item_label,HORIZONTAL_ALIGNMENT_LEFT,size.x-18,12,ink)
	if selected:
		draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),ART.ACCENT,false,2)
		draw_rect(Rect2(1,1,4,size.y-2),ART.ACCENT)


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return not disabled and data is Dictionary and data.get(&"kind") == &"inventory_item" and accepts_item.is_valid() and accepts_item.call(data.get(&"instance_id", &""))


func _drop_data(_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data[&"instance_id"])
