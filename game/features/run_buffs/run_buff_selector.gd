class_name RunBuffSelector
extends Control

signal buff_selected(buff_id: StringName)
signal panel_visibility_changed(is_open: bool)

var choices: Array[Dictionary] = []
var cards: Array[Button] = []
var paused_before_open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	cards = [%Choice1, %Choice2, %Choice3]
	for index in range(cards.size()):
		cards[index].pressed.connect(_select_choice.bind(index))
	visible = false


func open_choices(run_level: int, new_choices: Array[Dictionary]) -> bool:
	if new_choices.is_empty():
		return false
	choices = new_choices.duplicate(true)
	%RunLevel.text = "RUN LEVEL // %02d" % run_level
	%Title.text = "내부 증강 선택"
	for index in range(cards.size()):
		var card: Button = cards[index]
		card.visible = index < choices.size()
		if not card.visible:
			continue
		card.call(&"configure", index, run_level, choices[index])
	paused_before_open = get_tree().paused
	move_to_front()
	visible = true
	get_tree().paused = true
	cards[0].grab_focus()
	panel_visibility_changed.emit(true)
	return true


func close_panel() -> void:
	if not visible:
		return
	visible = false
	choices.clear()
	get_tree().paused = paused_before_open
	panel_visibility_changed.emit(false)


func _select_choice(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	var buff_id: StringName = choices[index][&"buff_id"]
	visible = false
	choices.clear()
	get_tree().paused = paused_before_open
	panel_visibility_changed.emit(false)
	buff_selected.emit(buff_id)


func get_snapshot() -> Dictionary:
	var card_snapshots: Array[Dictionary] = []
	var focused_index := -1
	for index in range(cards.size()):
		if not cards[index].visible:
			continue
		var snapshot: Dictionary = cards[index].call(&"get_snapshot")
		card_snapshots.append(snapshot)
		if bool(snapshot.get(&"focused", false)):
			focused_index = index
	var viewport_rect := get_viewport_rect()
	var cards_inside_viewport := true
	for snapshot in card_snapshots:
		var rect: Rect2 = snapshot.get(&"rect", Rect2())
		if not viewport_rect.encloses(rect):
			cards_inside_viewport = false
	return {
		&"visible": visible,
		&"choice_count": choices.size(),
		&"visible_card_count": card_snapshots.size(),
		&"focused_index": focused_index,
		&"cards_inside_viewport": cards_inside_viewport,
		&"card_snapshots": card_snapshots,
	}


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	var key_event := event as InputEventKey
	if key_event == null:
		return
	match key_event.keycode:
		KEY_1, KEY_KP_1:
			_select_choice(0)
		KEY_2, KEY_KP_2:
			_select_choice(1)
		KEY_3, KEY_KP_3:
			_select_choice(2)
		KEY_LEFT, KEY_A:
			_move_focus(-1)
		KEY_RIGHT, KEY_D:
			_move_focus(1)
		_:
			return
	get_viewport().set_input_as_handled()


func _move_focus(direction: int) -> void:
	var visible_cards: Array[Button] = []
	for card in cards:
		if card.visible:
			visible_cards.append(card)
	if visible_cards.is_empty():
		return
	var current_index := 0
	for index in range(visible_cards.size()):
		if visible_cards[index].has_focus():
			current_index = index
			break
	visible_cards[posmod(current_index + direction, visible_cards.size())].grab_focus()
