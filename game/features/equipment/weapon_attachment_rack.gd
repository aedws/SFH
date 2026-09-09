class_name WeaponAttachmentRack
extends VBoxContainer
## Read-only weapon/part presentation. The inventory edit session owns mutations.
signal weapon_selected(slot_id: StringName)
signal socket_selected(slot_id: StringName, socket_id: StringName)

const BOARD = preload("res://game/features/equipment/weapon_parts_board.gd")
var boards: Dictionary = {}
var selectors: Dictionary = {}

func get_socket_label(socket: StringName) -> String:
	return String(BOARD.SOCKET_LABELS.get(socket, socket))

func configure(provider: Node, selected_slot: StringName, selected_socket: StringName) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	boards.clear()
	selectors.clear()
	add_theme_constant_override("separation", 10)
	for descriptor: Dictionary in provider.get_slot_descriptors():
		if descriptor.get(&"kind") != "weapon":
			continue
		var slot: StringName = descriptor[&"slot_id"]
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 0)
		add_child(card)
		var selector := Button.new()
		selector.text = "%d  %s%s" % [boards.size() + 1, "메인 무기" if slot == &"main" else "보조 무기" if slot == &"secondary" else String(slot), " · 선택됨" if slot == selected_slot else ""]
		selector.alignment = HORIZONTAL_ALIGNMENT_LEFT
		selector.custom_minimum_size.y = 44
		selector.toggle_mode = true
		selector.set_pressed_no_signal(slot == selected_slot)
		selector.add_theme_font_size_override("font_size", 14)
		selector.pressed.connect(func(): weapon_selected.emit(slot))
		card.add_child(selector)
		selectors[slot] = selector
		var board = BOARD.new()
		board.inventory_card_mode = true
		board.custom_minimum_size = Vector2(280, 208)
		card.add_child(board)
		board.configure(provider.get_equipment_state(slot), selected_socket if slot == selected_slot else &"")
		board.socket_selected.connect(func(socket: StringName): socket_selected.emit(slot, socket))
		boards[slot] = board

func get_snapshot() -> Dictionary:
	var cards: Array[Dictionary] = []
	for slot in boards:
		cards.append({&"slot": slot, &"rect": boards[slot].get_global_rect(), &"board": boards[slot].get_snapshot()})
	return {&"cards": cards, &"count": cards.size()}
