class_name SessionSocketHUD
extends PanelContainer

signal unsocket_requested(socket_type: StringName, slot_index: int)

const TYPE_LABELS := {&"rune": "룬", &"core": "코어", &"artifact": "유물"}

@onready var slots_row: HBoxContainer = %SlotsRow
@onready var source_label: Label = %SourceLabel

var service: Node
var managed_layout := false
var latest_occupied_count := 0


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
	latest_occupied_count = 0
	for socket_type in [&"rune", &"core", &"artifact"]:
		for slot: Dictionary in slots_by_type.get(socket_type, []):
			var button := Button.new()
			var occupied := bool(slot.get(&"occupied", false))
			if occupied:
				latest_occupied_count += 1
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
			if occupied:
				var names := PackedStringArray()
				for binding: Dictionary in slot.get(&"bindings", {}).values():
					names.append(String(binding.get(&"display_name", "")))
				button.tooltip_text += "\n귀속: %s · 다른 무기/스킬에는 미적용\n해제 시 가방 반환 · 공간 부족 시 장착 유지" % ", ".join(names)
			button.disabled = not occupied
			if occupied:
				button.pressed.connect(_request_unsocket.bind(socket_type, int(slot[&"slot_index"])))
			slots_row.add_child(button)
	source_label.text = "RUN ONLY · %s" % snapshot.get(&"source_label", "확정 CSV")
	source_label.tooltip_text = source_label.text
	source_label.text = "RUN ONLY · 작전 한정"
	# 빈 슬롯 안내는 전리품 상호작용 문구가 담당합니다. 전투 중에는 실제로
	# 장착된 런 자산이 있을 때만 가장자리 HUD를 노출해 시야를 보존합니다.
	visible = latest_occupied_count > 0


func set_managed_layout(enabled: bool) -> void:
	managed_layout = enabled
	_update_responsive_layout()


func get_snapshot() -> Dictionary:
	return {
		&"visible": visible,
		&"button_count": slots_row.get_child_count(),
		&"occupied_count": latest_occupied_count,
		&"source_text": source_label.text,
		&"runtime_only_visible": "RUN ONLY" in source_label.text,
		&"managed_layout": managed_layout,
		&"hidden_when_empty": latest_occupied_count == 0 and not visible,
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
	if managed_layout:
		return
	var viewport_width := get_viewport_rect().size.x
	var panel_width := clampf(viewport_width - 24.0, 340.0, 680.0)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -panel_width * 0.5
	offset_right = panel_width * 0.5
