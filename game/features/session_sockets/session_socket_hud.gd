class_name SessionSocketHUD
extends PanelContainer

signal unsocket_requested(socket_type: StringName, slot_index: int)

const TYPE_LABELS := {&"rune": "RUNE", &"core": "CORE", &"artifact": "ARTIFACT"}

@onready var slots_row: HBoxContainer = %SlotsRow
@onready var source_label: Label = %SourceLabel

var service: Node


func _ready() -> void:
	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()


func configure(new_service: Node) -> bool:
	if (
		not is_instance_valid(new_service)
		or not new_service.has_method(&"get_snapshot")
		or not new_service.has_method(&"unsocket")
		or not new_service.has_signal(&"sockets_changed")
	):
		return false
	service = new_service
	service.connect(&"sockets_changed", Callable(self, &"_on_sockets_changed"))
	refresh(service.call(&"get_snapshot"))
	return true


func refresh(snapshot: Dictionary) -> void:
	for child in slots_row.get_children():
		child.queue_free()
	var slots_by_type: Dictionary = snapshot.get(&"slots", {})
	for socket_type in [&"rune", &"core", &"artifact"]:
		for slot: Dictionary in slots_by_type.get(socket_type, []):
			var button := Button.new()
			var occupied := bool(slot.get(&"occupied", false))
			button.custom_minimum_size = Vector2(64.0, 30.0)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.text = (
				"%s · %s" % [TYPE_LABELS[socket_type], slot.get(&"display_name", "")]
				if occupied else "%s · EMPTY" % TYPE_LABELS[socket_type]
			)
			button.tooltip_text = (
				"%s\n클릭하여 런 소켓에서 해제" % slot.get(&"description", "작전 한정 효과")
				if occupied else "%s 소켓 · 작전 중 전리품을 F로 장착" % TYPE_LABELS[socket_type]
			)
			button.disabled = not occupied
			if occupied:
				button.pressed.connect(_request_unsocket.bind(socket_type, int(slot[&"slot_index"])))
			slots_row.add_child(button)
	source_label.text = "RUN ONLY · %s" % snapshot.get(&"source_label", "확정 CSV")
	visible = int(snapshot.get(&"rule_item_count", 0)) > 0


func get_snapshot() -> Dictionary:
	return {
		&"visible": visible,
		&"button_count": slots_row.get_child_count(),
		&"occupied_count": _occupied_button_count(),
		&"source_text": source_label.text,
		&"runtime_only_visible": "RUN ONLY" in source_label.text,
	}


func _request_unsocket(socket_type: StringName, slot_index: int) -> void:
	unsocket_requested.emit(socket_type, slot_index)
	service.call(&"unsocket", socket_type, slot_index)


func _on_sockets_changed(snapshot: Dictionary) -> void:
	refresh(snapshot)


func _occupied_button_count() -> int:
	var result := 0
	for child in slots_row.get_children():
		if child is Button and not (child as Button).disabled:
			result += 1
	return result


func _update_responsive_layout() -> void:
	var viewport_width := get_viewport_rect().size.x
	var panel_width := clampf(viewport_width - 24.0, 340.0, 680.0)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -panel_width * 0.5
	offset_right = panel_width * 0.5
