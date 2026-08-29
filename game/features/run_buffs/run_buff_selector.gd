class_name RunBuffSelector
extends Control

signal buff_selected(buff_id: StringName)

var choices: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%Choice1.pressed.connect(_select_choice.bind(0))
	%Choice2.pressed.connect(_select_choice.bind(1))
	%Choice3.pressed.connect(_select_choice.bind(2))
	visible = false


func open_choices(run_level: int, new_choices: Array[Dictionary]) -> bool:
	if new_choices.is_empty():
		return false
	choices = new_choices.duplicate(true)
	%Title.text = "런 레벨 %d · 임시 버프 선택" % run_level
	var buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]
	for index in range(buttons.size()):
		var button := buttons[index]
		button.visible = index < choices.size()
		if not button.visible:
			continue
		var choice: Dictionary = choices[index]
		button.text = "%s  %d/%d\n%s" % [
			choice[&"display_name"],
			int(choice[&"current_stacks"]),
			int(choice[&"maximum_stacks"]),
			choice[&"description"],
		]
	visible = true
	get_tree().paused = true
	return true


func close_panel() -> void:
	visible = false
	choices.clear()
	get_tree().paused = false


func _select_choice(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	var buff_id: StringName = choices[index][&"buff_id"]
	visible = false
	choices.clear()
	get_tree().paused = false
	buff_selected.emit(buff_id)
