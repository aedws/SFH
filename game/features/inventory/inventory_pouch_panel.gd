class_name InventoryPouchPanel
extends VBoxContainer
signal store_requested
signal retrieve_requested(id: StringName)
signal rotate_requested(id: StringName)
signal upgrade_requested(kind: StringName, quote: Dictionary)
var toggle: Button
var body: HBoxContainer
var grid: PouchGrid
var controls: VBoxContainer
var store_button: Button
var take_button: Button
var rotate_button: Button
var description: Label
var upgrades: HBoxContainer
var capacity_provider: Node
var selected: StringName = &""
var snapshot := {}

func _ready() -> void:
	toggle = Button.new()
	toggle.text = "보호 주머니"
	toggle.custom_minimum_size.y = 36
	add_child(toggle)
	body = HBoxContainer.new()
	add_child(body)
	body.hide()
	toggle.pressed.connect(func():
		body.visible = not body.visible
		toggle.text = toggle.text.replace("열기", "접기") if body.visible else toggle.text.replace("접기", "열기"))
	grid = PouchGrid.new()
	body.add_child(grid)
	grid.chosen.connect(func(id): selected = id; _present_selection())
	controls = VBoxContainer.new()
	controls.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(controls)
	description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_child(description)
	store_button = _button("선택품 보호", func(): store_requested.emit())
	take_button = _button("가방으로 꺼내기", func(): retrieve_requested.emit(selected))
	rotate_button = _button("회전 / R", func(): rotate_requested.emit(selected))
	upgrades = HBoxContainer.new()
	controls.add_child(upgrades)

func present(value: Dictionary, selected_bag: Dictionary, hub: bool) -> void:
	snapshot = value
	var used := 0
	for entry in value.entries:
		var footprint := InventoryReservePolicy.size_of(entry)
		used += footprint.x * footprint.y
	toggle.text = "보호 주머니 · %d / %d칸  %s" % [used, value.grid_size.x * value.grid_size.y, "접기" if body.visible else "열기"]
	toggle.tooltip_text = "설계도·룬·코어·유물 전용 · 사망 시 거점 실물 보관 · 생환 시 기존 정산"
	grid.present(value, selected)
	store_button.disabled = selected_bag.is_empty() or selected_bag.get(&"item_type") not in InventoryPouchPolicy.ALLOWED
	for child in upgrades.get_children(): upgrades.remove_child(child); child.queue_free()
	if hub and is_instance_valid(capacity_provider):
		for kind in [&"backpack", &"pouch"]:
			var quote: Dictionary = capacity_provider.call(&"get_quote", kind)
			if quote.is_empty(): continue
			var button := Button.new()
			button.text = "%s %d칸\n%s" % ["가방" if kind == &"backpack" else "주머니", quote.columns * quote.rows, "%d C" % quote.credit_cost if quote.upgrade_enabled else "가격 미정"]
			button.custom_minimum_size.y = 44
			button.size_flags_horizontal = SIZE_EXPAND_FILL
			button.disabled = not quote.available
			button.tooltip_text = quote.planner_note
			button.pressed.connect(func(): upgrade_requested.emit(kind, quote))
			upgrades.add_child(button)
	_present_selection()

func _present_selection() -> void:
	var found := false
	for entry in snapshot.get(&"entries", []):
		if entry.instance_id == selected:
			found = true
			description.text = entry.definition.display_name + " · 보호 중"
			break
	if not found:
		selected = &""
		description.text = "사망 시 원형 회수\n생환 시 기존 정산"
	take_button.disabled = not found
	rotate_button.disabled = not found
	grid.selected = selected
	grid.queue_redraw()

func _button(title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 36
	button.pressed.connect(callback)
	controls.add_child(button)
	return button

class PouchGrid extends Control:
	signal chosen(id: StringName)
	var snapshot := {}
	var selected: StringName = &""
	const CELL := 48.0
	func present(value: Dictionary, id: StringName) -> void:
		snapshot = value
		selected = id
		custom_minimum_size = Vector2(value.grid_size) * CELL
		queue_redraw()
	func _draw() -> void:
		if snapshot.is_empty(): return
		for y in snapshot.grid_size.y:
			for x in snapshot.grid_size.x:
				draw_rect(Rect2(Vector2(x, y) * CELL, Vector2.ONE * CELL), Color("16444b"), false, 1)
		for entry in snapshot.entries:
			var rect := Rect2(Vector2(entry.position) * CELL + Vector2(2,2), Vector2(InventoryReservePolicy.size_of(entry)) * CELL - Vector2(4,4))
			draw_rect(rect, Color("075b62"))
			draw_rect(rect, Color("02e5e1") if entry.instance_id == selected else Color("6b949c"), false, 2)
			var mark: String = {&"blueprint":"BP", &"rune":"R", &"core":"C", &"artifact":"A"}.get(entry.definition.item_type, "?")
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 26), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("c9fcff"))
	func _gui_input(event: InputEvent) -> void:
		if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: return
		for entry in snapshot.get(&"entries", []):
			if Rect2(Vector2(entry.position) * CELL, Vector2(InventoryReservePolicy.size_of(entry)) * CELL).has_point(event.position):
				chosen.emit(entry.instance_id)
				accept_event()
				return
