class_name GridInventoryWindow
extends PanelContainer

signal panel_visibility_changed(is_open: bool)
signal settings_saved
signal external_panel_requested(action: StringName)

const EDIT_SESSION = preload("res://game/features/inventory/inventory_edit_session.gd")
const GRID_VIEW = preload("res://game/features/inventory/inventory_grid_view.gd")
const SLOT_BUTTON = preload("res://game/features/inventory/inventory_slot_button.gd")
const SLOT_NAMES := {&"main": "메인 무기", &"secondary": "보조 무기", &"body": "신체", &"feet": "신발"}

var session: Node
var inventory_provider: Node
var equipment_provider: Node
var paused_before_open := false
var grid_view: Control
var bag_scroll: ScrollContainer
var content_scroll: ScrollContainer
var columns: BoxContainer
var gear_column: VBoxContainer
var stats_column: VBoxContainer
var detail_column: VBoxContainer
var module_column: VBoxContainer
var module_list: VBoxContainer
var tabs: Array[Button] = []
var slot_buttons: Dictionary = {}
var header_summary: Label
var stats_label: Label
var selected_name: Label
var selected_description: Label
var status_label: Label
var capacity_label: Label
var action_button: Button
var unequip_button: Button
var rotate_button: Button
var selected_entry: Dictionary = {}
var selected_slot: StringName = &"main"
var current_tab := 0
var confirm_overlay: Control
var pending_exit: Callable
var confirmation_visible := false
var confirm_buttons: Array[Button] = []
var layout_deferred_pending := false
var open_layout_ready := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	visible = false
	session = EDIT_SESSION.new()
	add_child(session)
	_build_ui()
	session.changed.connect(_refresh)
	session.committed.connect(func(): settings_saved.emit())
	resized.connect(_layout)
	bag_scroll.resized.connect(_queue_stable_layout)


func configure(bag: Node, gear: Node = null) -> void:
	inventory_provider = bag
	equipment_provider = gear
	session.configure(bag, gear)
	session.begin()
	_bind_draft()


func _input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed(&"ui_cancel"):
		if confirmation_visible:
			resolve_exit(&"cancel")
		else:
			close_panel()
		get_viewport().set_input_as_handled()
		return
	if confirmation_visible and event.is_pressed():
		var focus := get_viewport().gui_get_focus_owner()
		var index := confirm_buttons.find(focus)
		if event.is_action_pressed(&"ui_focus_next") or event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"ui_right"):
			confirm_buttons[(maxi(0, index) + 1) % confirm_buttons.size()].grab_focus()
		elif event.is_action_pressed(&"ui_focus_prev") or event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_left"):
			confirm_buttons[posmod(index - 1, confirm_buttons.size())].grab_focus()
		elif event.is_action_pressed(&"ui_accept"):
			if index >= 0:
				confirm_buttons[index].pressed.emit()
			else:
				%ContinueEditing.grab_focus()
		if event is InputEventKey or event is InputEventAction or event is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"equip_field_loot"):
		_rotate_selected_item()
		get_viewport().set_input_as_handled()
		return
	for action in [&"toggle_inventory", &"toggle_equipment", &"toggle_modification", &"toggle_key_mapping", &"toggle_map"]:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			if action == &"toggle_inventory":
				close_panel()
			else:
				request_leave(func():
					_finish_close()
					external_panel_requested.emit(action)
				)
			get_viewport().set_input_as_handled()
			return
	for action in [&"switch_weapon", &"interact"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(event: InputEvent) -> void:
	if not visible and event.is_action_pressed(&"toggle_inventory") and not event.is_echo():
		open_panel()
		get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()


func open_panel() -> void:
	if visible:
		return
	for panel in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if panel != self and panel.has_method(&"close_panel"):
			panel.call(&"close_panel")
	paused_before_open = get_tree().paused
	if not session.begin():
		return
	current_tab = 0
	selected_entry.clear()
	_bind_draft()
	move_to_front()
	visible = true
	get_tree().paused = true
	open_layout_ready = false
	_layout()
	_queue_stable_layout()
	panel_visibility_changed.emit(true)


func close_panel() -> void:
	if visible:
		request_leave(_finish_close)


func request_leave(continuation: Callable) -> void:
	if confirmation_visible:
		return # Keep the original intended destination; repeated ESC cannot bypass.
	if not session.dirty:
		continuation.call()
		return
	pending_exit = continuation
	confirmation_visible = true
	%ConfirmError.text = ""
	confirm_overlay.show()
	confirm_overlay.move_to_front()
	%ContinueEditing.grab_focus()


func resolve_exit(choice: StringName) -> void:
	if not confirmation_visible:
		return
	if choice == &"save" and not session.commit():
		%ConfirmError.text = session.error_message
		return
	if choice == &"discard":
		session.begin()
		_bind_draft()
	confirmation_visible = false
	confirm_overlay.hide()
	var next := pending_exit
	pending_exit = Callable()
	if choice != &"cancel" and next.is_valid():
		next.call()


func _finish_close() -> void:
	visible = false
	get_tree().paused = paused_before_open
	panel_visibility_changed.emit(false)


func request_tab(index: int) -> void:
	if index == current_tab:
		return
	request_leave(func():
		current_tab = index
		selected_entry.clear()
		_refresh()
	)


func _bind_draft() -> void:
	grid_view.configure(session.inventory)
	grid_view.move_handler = session.move_item
	grid_view.selected_instance_id = &""
	selected_entry.clear()
	selected_name.text = "아이템 선택"
	selected_description.text = "가방에서 아이템을 선택해 설명과 장착 대상을 확인하세요."
	_refresh_slots()
	_refresh()


func _build_ui() -> void:
	add_theme_stylebox_override("panel", _style(Color("02e5e1")))
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	add_child(margin)
	var root_box := VBoxContainer.new()
	margin.add_child(root_box)
	var header := HBoxContainer.new()
	root_box.add_child(header)
	var header_title := _label(header, "I  가방 인벤토리", 20)
	header_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	header_title.size_flags_horizontal = SIZE_EXPAND_FILL
	var close_button := _button(header, "닫기 / ESC", close_panel)
	close_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	close_button.custom_minimum_size.x = 104
	header_summary = _label(root_box, "", 12)
	header_summary.max_lines_visible = 1
	var tab_row := HBoxContainer.new()
	root_box.add_child(tab_row)
	for title in ["작전 가방", "무기 모듈", "방어구 모듈"]:
		var button := _button(tab_row, title, request_tab.bind(tabs.size()))
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
		button.clip_text = true
		button.toggle_mode = true
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		tabs.append(button)
	content_scroll = ScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	root_box.add_child(content_scroll)
	columns = BoxContainer.new()
	columns.size_flags_horizontal = SIZE_EXPAND_FILL
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	content_scroll.add_child(columns)
	gear_column = _column(columns, 190)
	stats_column = _column(columns, 126)
	_label(stats_column, "유저 스탯", 17)
	stats_label = _label(stats_column, "", 14)
	module_column = _column(columns, 190)
	_label(module_column, "장착 모듈 · 파츠", 16)
	module_list = VBoxContainer.new()
	module_column.add_child(module_list)
	var bag_column := _column(columns, 0)
	bag_column.size_flags_horizontal = SIZE_EXPAND_FILL
	_label(bag_column, "작전 가방 · 이동 가능", 17)
	_label(bag_column, "드래그 / 선택 후 빈 칸 클릭 / 선택 후 R 회전", 12)
	bag_scroll = ScrollContainer.new()
	bag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	bag_scroll.custom_minimum_size.y = 280
	bag_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	bag_column.add_child(bag_scroll)
	grid_view = GRID_VIEW.new()
	grid_view.cell_pixel_size = 30.0
	bag_scroll.add_child(grid_view)
	grid_view.item_selected.connect(_on_item_selected)
	capacity_label = _label(bag_column, "공간 사용", 12)
	detail_column = _column(columns, 192)
	_label(detail_column, "SELECTED ITEM", 12)
	selected_name = _label(detail_column, "아이템 선택", 18)
	selected_description = _label(detail_column, "아이템을 선택하면 상세 정보가 표시됩니다.", 13)
	rotate_button = _button(detail_column, "선택 아이템 회전 / R", _rotate_selected_item)
	action_button = _button(detail_column, "선택 슬롯에 장착", _apply_selection)
	unequip_button = _button(detail_column, "선택 장비 해제", _unequip_selection)
	_label(detail_column, "장비 관리\nU 장비 · E 모듈/파츠\nESC 닫기 · 변경 시 저장 확인", 12)
	status_label = _label(root_box, "", 12)
	status_label.max_lines_visible = 2
	_build_confirmation()


func _build_confirmation() -> void:
	confirm_overlay = Control.new()
	confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(confirm_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("02e5e1")))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 280
	panel.add_child(box)
	_label(box, "세팅을 저장하시겠습니까?", 18)
	_label(box, "저장하지 않은 이동·장착 변경이 있습니다.", 12)
	var error_label := _label(box, "", 12)
	error_label.name = "ConfirmError"
	error_label.owner = self
	error_label.unique_name_in_owner = true
	confirm_buttons.append(_button(box, "저장 후 이동", resolve_exit.bind(&"save")))
	confirm_buttons.append(_button(box, "변경 취소 후 이동", resolve_exit.bind(&"discard")))
	var cancel := _button(box, "계속 편집", resolve_exit.bind(&"cancel"))
	confirm_buttons.append(cancel)
	cancel.name = "ContinueEditing"
	cancel.owner = self
	cancel.unique_name_in_owner = true
	confirm_overlay.hide()


func _refresh_slots() -> void:
	for child in gear_column.get_children():
		gear_column.remove_child(child)
		child.queue_free()
	slot_buttons.clear()
	_label(gear_column, "장비 장착", 17)
	var descriptors: Array = session.equipment.get_slot_descriptors() if session.equipment != null else []
	for kind in ["weapon", "armor"]:
		var slot_parent: Control = gear_column
		if kind == "armor":
			var armor_grid := GridContainer.new()
			armor_grid.columns = 2
			gear_column.add_child(armor_grid)
			slot_parent = armor_grid
		var count := 0
		for descriptor: Dictionary in descriptors:
			if descriptor[&"kind"] != kind:
				continue
			var slot: StringName = descriptor[&"slot_id"]
			var button = SLOT_BUTTON.new()
			button.custom_minimum_size = Vector2(88, 92 if kind == "weapon" else 76)
			button.size_flags_horizontal = SIZE_EXPAND_FILL
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.add_theme_font_size_override("font_size", 13)
			button.add_theme_stylebox_override("normal", _style(Color("248caf") if kind == "weapon" else Color("a75b68")))
			button.pressed.connect(_select_slot.bind(slot))
			button.accepts_item = func(id: StringName):
				return session.equipment.can_equip_definition(slot, session.get_item_entry(id).get(&"linked_resource"))
			button.item_dropped.connect(func(id: StringName):
				selected_slot = slot
				session.equip_item(id, slot)
			)
			slot_parent.add_child(button)
			slot_buttons[slot] = button
			count += 1
		if kind == "armor":
			for index in range(maxi(0, 4 - count)):
				var placeholder := _button(slot_parent, "확장 예정", Callable())
				placeholder.disabled = true
				placeholder.custom_minimum_size = Vector2(88, 76)
				placeholder.tooltip_text = "현재 방어구 데이터는 신체·신발 2종입니다. 새 슬롯 규칙 등록 시 자동 표시됩니다."


func _refresh() -> void:
	if session.inventory == null:
		return
	var snapshot: Dictionary = session.inventory.get_snapshot()
	var used := 0
	for item: Dictionary in snapshot[&"items"]:
		var footprint: Vector2i = item[&"grid_size"]
		used += footprint.x * footprint.y
	var dimensions: Vector2i = snapshot[&"grid_size"]
	header_summary.text = "아이템 %d개 · %s" % [snapshot[&"items"].size(), "미저장 변경 있음" if session.dirty else "저장된 세팅"]
	capacity_label.text = "공간 사용 %d / %d칸 · 세로 스크롤" % [used, dimensions.x * dimensions.y]
	for i in tabs.size():
		tabs[i].set_pressed_no_signal(i == current_tab)
	module_column.visible = current_tab != 0
	stats_column.visible = current_tab == 0
	_refresh_modules()
	for slot in slot_buttons:
		var state: Resource = session.equipment.get_equipment_state(slot)
		var label: String = SLOT_NAMES.get(slot, String(slot))
		var item_name: String = state.definition.display_name if state != null else "빈 슬롯"
		slot_buttons[slot].text = "%s%s\n%s" % ["> " if slot == selected_slot else "", label, item_name]
		var weapon_slot: bool = slot in [&"main", &"secondary"]
		slot_buttons[slot].disabled = (current_tab == 1 and not weapon_slot) or (current_tab == 2 and weapon_slot)
		slot_buttons[slot].tooltip_text = "%s · %s\n선택 후 장착 / 아이템을 여기로 드래그" % [label, item_name]
	_refresh_stats()
	if not selected_entry.is_empty():
		var current_entry: Dictionary = session.get_item_entry(selected_entry.get(&"instance_id", &""))
		if current_entry.is_empty():
			selected_entry.clear()
		else:
			selected_entry = current_entry
			_show_selected_entry(current_entry)
	status_label.text = session.error_message if not session.error_message.is_empty() else "선택 후 R 회전 · 세팅은 저장 시 적용 · 장비는 태그에 맞춰 장착"
	rotate_button.text = "선택 아이템 회전 / %s" % _action_binding_label(&"equip_field_loot", "R")
	rotate_button.disabled = selected_entry.is_empty() or not bool(selected_entry.get(&"can_rotate", false))
	action_button.disabled = selected_entry.is_empty() or session.equipment == null or selected_entry.get(&"item_type") not in [&"weapon", &"armor", &"module", &"part"]
	unequip_button.disabled = session.equipment == null
	_layout()


func _refresh_stats() -> void:
	if session.equipment == null:
		stats_label.text = "장비 기능 비활성"
		return
	var modifiers: Dictionary = session.equipment.get_stat_modifiers()
	var summary: Dictionary = session.equipment.get_summary()
	stats_label.text = "장비 보정 미리보기\n\n활성 스킬 %d/%d\n" % [summary[&"active_skill_count"], summary[&"equipped_skill_count"]]
	var names := {&"max_health": "최대 체력", &"defense": "방어력", &"movement_speed": "이동속도", &"damage": "공격력"}
	var preview: Dictionary = equipment_provider.get_player_stat_preview(modifiers)
	for stat in preview:
		stats_label.text += "\n%s\n%.1f\n" % [names.get(stat, String(stat)), float(preview[stat])]
	if preview.is_empty():
		for stat in modifiers:
			stats_label.text += "\n%s\n%+.1f / ×%.2f\n" % [names.get(stat, String(stat)), modifiers[stat].get(&"add", 0.0), modifiers[stat].get(&"multiply", 1.0)]


func _refresh_modules() -> void:
	for child in module_list.get_children():
		module_list.remove_child(child)
		child.queue_free()
	if current_tab == 0 or session.equipment == null:
		return
	var wanted_kind := "weapon" if current_tab == 1 else "armor"
	var state: Resource = session.equipment.get_equipment_state(selected_slot)
	if state == null or (state.is_weapon() != (wanted_kind == "weapon")):
		for descriptor: Dictionary in session.equipment.get_slot_descriptors():
			if descriptor[&"kind"] == wanted_kind:
				selected_slot = descriptor[&"slot_id"]
				state = session.equipment.get_equipment_state(selected_slot)
				break
	if state == null:
		_label(module_list, "장비를 먼저 장착하세요.", 13)
		return
	_label(module_list, "%s\n코스트 %d / %d\n모듈 %d / %d" % [state.definition.display_name, state.used_module_cost(), state.module_cost_limit(), state.installed_modules.size(), state.module_slot_limit()], 13)
	for module in state.installed_modules:
		_button(module_list, "%s · %d C\n해제" % [module.definition.display_name, state.effective_module_cost(module)], _remove_modification.bind(&"module", module.instance_id))
	for part in state.installed_parts:
		_button(module_list, "%s\n파츠 해제" % part.display_name, _remove_modification.bind(&"part", part.part_id))
	_label(module_list, "가방의 모듈을 선택한 뒤\n장착 버튼을 누르세요.\n코스트·중복·소켓 규칙 적용", 12)


func _select_slot(slot: StringName) -> void:
	selected_slot = slot
	_refresh()


func _on_item_selected(entry: Dictionary) -> void:
	selected_entry = entry
	_show_selected_entry(entry)


func _show_selected_entry(entry: Dictionary) -> void:
	selected_name.text = entry[&"display_name"]
	var footprint: Vector2i = entry[&"grid_size"]
	var kind_label: String = {&"weapon": "무기", &"armor": "방어구", &"module": "모듈", &"part": "고유 파츠", &"consumable": "소모품"}.get(entry[&"item_type"], "아이템")
	var orientation := "회전됨" if bool(entry.get(&"rotated", false)) else "기본 방향"
	selected_description.text = "%d×%d칸 · %s · %s\n\n%s" % [footprint.x, footprint.y, kind_label, orientation, entry[&"description"]]
	action_button.text = "모듈 / 파츠 장착" if entry[&"item_type"] in [&"module", &"part"] else "선택 슬롯에 장착"
	action_button.disabled = session.equipment == null or entry[&"item_type"] not in [&"weapon", &"armor", &"module", &"part"]
	rotate_button.disabled = not bool(entry.get(&"can_rotate", false))


func _rotate_selected_item() -> void:
	if selected_entry.is_empty():
		status_label.text = "회전할 아이템을 먼저 한 번 선택하세요."
		return
	var instance_id: StringName = selected_entry.get(&"instance_id", &"")
	if session.rotate_item(instance_id):
		var current_entry: Dictionary = session.get_item_entry(instance_id)
		if not current_entry.is_empty():
			selected_entry = current_entry
			grid_view.selected_instance_id = instance_id
			_show_selected_entry(current_entry)
			grid_view.queue_redraw()


func _apply_selection() -> void:
	if selected_entry.is_empty():
		return
	var id: StringName = selected_entry[&"instance_id"]
	var ok := bool(session.install_item(id, selected_slot) if selected_entry[&"item_type"] in [&"module", &"part"] else session.equip_item(id, selected_slot))
	if ok:
		selected_entry.clear()
		selected_name.text = "장착 완료 · 미저장"
		selected_description.text = "탭 이동 또는 닫기에서 저장 여부를 선택하세요."
		_refresh()


func _unequip_selection() -> void:
	session.unequip_item(selected_slot)


func _remove_modification(kind: StringName, id: StringName) -> void:
	session.remove_modification(selected_slot, kind, id)


func _layout() -> void:
	if columns == null:
		return
	var narrow := size.x < 1000
	columns.vertical = narrow
	gear_column.custom_minimum_size.x = 0 if narrow else 190
	stats_column.custom_minimum_size.x = 0 if narrow else 126
	detail_column.custom_minimum_size.x = 0 if narrow else 192
	module_column.custom_minimum_size.x = 0 if narrow else 190
	if session.inventory != null:
		var dimensions: Vector2i = session.inventory.grid_size
		var available := maxf(240, bag_scroll.size.x - 18)
		grid_view.cell_pixel_size = clampf(floorf(available / maxf(1, dimensions.x)), 20, 52)
		grid_view.custom_minimum_size = Vector2(dimensions) * grid_view.cell_pixel_size
		grid_view.queue_redraw()


func _queue_stable_layout() -> void:
	if layout_deferred_pending:
		return
	layout_deferred_pending = true
	call_deferred(&"_apply_stable_layout")


func _apply_stable_layout() -> void:
	layout_deferred_pending = false
	if not visible:
		return
	_layout()
	open_layout_ready = bag_scroll.size.x > 240.0


func get_density_snapshot() -> Dictionary:
	return {&"window_size": size, &"grid_minimum_size": grid_view.custom_minimum_size,
		&"detail_minimum_width": detail_column.custom_minimum_size.x,
		&"cell_pixel_size": grid_view.cell_pixel_size, &"scrollable_bag": true,
		&"responsive_columns": columns.vertical, &"dirty": session.dirty,
		&"confirmation_visible": confirmation_visible, &"current_tab": current_tab,
		&"slot_count": slot_buttons.size(), &"bag_rect": bag_scroll.get_global_rect(),
		&"bag_viewport_width": bag_scroll.size.x, &"open_layout_ready": open_layout_ready}


func _column(parent: Node, width: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = width
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)
	return box


func _label(parent: Node, text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Node, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 44
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 13)
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.035, 0.045, 0.985)
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	return style


func _action_binding_label(action_id: StringName, fallback: String) -> String:
	for event: InputEvent in InputMap.action_get_events(action_id):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
			if keycode != KEY_NONE:
				return OS.get_keycode_string(keycode)
	return fallback
