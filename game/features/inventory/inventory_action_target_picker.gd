class_name InventoryActionTargetPicker
extends VBoxContainer
## Generic inventory action view: candidates and validation belong to the provider.
signal selection_changed

var choices: Dictionary = {}
var selection_key: StringName = &""


func present(groups: Array, instance_id: StringName) -> void:
	var previous := get_selection() if selection_key == instance_id else {}
	selection_key = instance_id
	choices.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	visible = not groups.is_empty()
	for group: Dictionary in groups:
		var key := StringName(group.target_kind)
		var label := Label.new()
		label.text = String(group.display_name)
		label.add_theme_font_size_override("font_size", 13)
		add_child(label)
		var choice := OptionButton.new()
		choice.custom_minimum_size.y = 44
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.fit_to_longest_item = false
		choice.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		choice.add_item("적용 대상 선택")
		choice.set_item_metadata(0, &"")
		var candidates: Array = group.candidates
		for candidate: Dictionary in candidates:
			choice.add_item(String(candidate.display_name))
			choice.set_item_metadata(choice.item_count - 1, StringName(candidate.target_id))
			if previous.get(key, &"") == StringName(candidate.target_id):
				choice.select(choice.item_count - 1)
		# One unambiguous target is shown explicitly; multiple skills require a choice.
		if candidates.size() == 1 and not previous.has(key):
			choice.select(1)
		choice.disabled = candidates.is_empty()
		choice.tooltip_text = "장착할 대상만 선택합니다. 취소하면 아이템과 효과는 바뀌지 않습니다."
		choice.item_selected.connect(func(_index): selection_changed.emit())
		add_child(choice)
		choices[key] = choice


func get_selection() -> Dictionary:
	var result := {}
	for key in choices:
		var choice: OptionButton = choices[key]
		if choice.selected > 0:
			result[key] = choice.get_item_metadata(choice.selected)
	return result


func is_complete() -> bool:
	return get_selection().size() == choices.size()


func dismiss_popup() -> bool:
	for choice: OptionButton in choices.values():
		if choice.get_popup().visible:
			choice.get_popup().hide()
			return true
	return false
