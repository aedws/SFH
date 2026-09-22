class_name GridInventoryWindow
extends PanelContainer

signal panel_visibility_changed(is_open: bool)
signal settings_saved
signal external_panel_requested(action: StringName)

const EDIT_SESSION = preload("res://game/features/inventory/inventory_edit_session.gd")
const GRID_VIEW = preload("res://game/features/inventory/inventory_grid_view.gd")
const SLOT_BUTTON = preload("res://game/features/presentation_theme/inventory_slot_button.gd")
const ITEM_PREVIEW = preload("res://game/features/presentation_theme/inventory_item_preview.gd")
const SCREEN_LAYOUT = preload("res://game/features/equipment/equipment_screen_layout.gd")
@export var loadout_column_width: float = 204.0
@export var inspection_column_width: float = 224.0
const SLOT_NAMES := {&"main": "메인 무기", &"secondary": "보조 무기", &"head": "머리", &"body": "신체", &"hands": "장갑", &"feet": "신발"}

var session: Node
var inventory_provider: Node
var equipment_provider: Node
var paused_before_open := false
var realtime := false
var session_ended := false
var live_health := ""
var grid_view: Control
var bag_scroll: ScrollContainer
var content_scroll: ScrollContainer
var columns: BoxContainer
var gear_column: VBoxContainer
var loadout_column: VBoxContainer
var stats_column: VBoxContainer
var detail_column: VBoxContainer
var module_column: VBoxContainer
var module_list: VBoxContainer
var weapon_rack: Control
var module_workspace: Control
var socket_actions: VBoxContainer
var selected_socket: StringName = &""
var tabs: Array[Button] = []
var slot_buttons: Dictionary = {}
var header_summary: Label
var stats_label: Label
var selected_name: Label
var selected_description: Label
var status_label: Label
var capacity_label: Label
var capacity_meter: ProgressBar
var selected_preview: Control
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
var runtime_item_actions: Array[Node] = []
var runtime_target_picker: InventoryActionTargetPicker


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
	get_viewport().size_changed.connect(_queue_stable_layout)


func configure(bag: Node, gear: Node = null) -> void:
	session_ended = false
	inventory_provider = bag
	equipment_provider = gear
	session.configure(bag, gear)
	session.begin()
	_bind_draft()


func register_runtime_item_actions(provider: Node) -> bool:
	if not is_instance_valid(provider) or not provider.has_method(&"supports_inventory_item") or not provider.has_method(&"perform_inventory_item_action"):
		return false
	if provider not in runtime_item_actions:
		runtime_item_actions.append(provider)
	return true


func _runtime_action_provider(entry: Dictionary) -> Node:
	for provider in runtime_item_actions:
		if is_instance_valid(provider) and provider.call(&"supports_inventory_item", StringName(entry.get(&"item_id", &""))):
			return provider
	return null


func _input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed(&"ui_cancel"):
		if runtime_target_picker.dismiss_popup():
			get_viewport().set_input_as_handled()
			return
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
				if current_tab != 0: request_tab(0)
				else: close_panel()
			elif action == &"toggle_modification":
				if current_tab == 2: close_panel()
				else: request_tab(2)
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
		request_tab(0)
		get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()


func open_panel() -> void:
	if visible or session_ended:
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
	if not realtime:
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
	session.end()
	if not realtime:
		get_tree().paused = paused_before_open
	panel_visibility_changed.emit(false)


func set_realtime_mode(enabled: bool) -> void:
	if not visible:
		realtime = enabled


func set_live_health(current: float, maximum: float) -> void:
	live_health = "HP %d/%d" % [ceili(current), ceili(maximum)]
	if visible: _refresh_header()


func end_runtime_session() -> void:
	session_ended = true
	pending_exit = Callable()
	confirmation_visible = false
	confirm_overlay.hide()
	session.end()
	if visible: _finish_close()


func _refresh_header() -> void:
	var count: int = session.inventory.get_snapshot()[&"items"].size()
	header_summary.text = "아이템 %d개 · %s" % [count, "미저장 변경 있음" if session.dirty else "저장된 세팅"]
	if realtime:
		header_summary.text += " · 전투 진행 중 · " + live_health
	header_summary.modulate = Color("ffc979") if realtime or session.dirty else Color("a0b9c3")


func request_tab(index: int) -> void:
	if index == current_tab:
		return
	request_leave(func():
		current_tab = index
		selected_socket = &""
		selected_entry.clear()
		selected_preview.present({})
		selected_name.text = "아이템 선택"
		selected_description.text = "아이템을 선택해 장착 대상을 확인하세요."
		_refresh()
	)


func open_modules(target: StringName = &"main") -> void:
	open_panel()
	request_tab(2)
	if module_workspace != null: module_workspace.configure(session, target)


func _bind_draft() -> void:
	grid_view.configure(session.inventory)
	grid_view.move_handler = session.move_item
	grid_view.selected_instance_id = &""
	selected_entry.clear()
	selected_name.text = "아이템 선택"
	selected_preview.present({})
	selected_socket = &""
	selected_description.text = "가방에서 아이템을 선택해 설명과 장착 대상을 확인하세요."
	_refresh_slots()
	_refresh()


func _build_ui() -> void:
	var ui = preload("res://game/features/presentation_theme/game_ui.gd")
	add_theme_stylebox_override("panel", _style(Color("02e5e1")))
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	add_child(margin)
	var root_box := VBoxContainer.new()
	margin.add_child(root_box)
	var header := HBoxContainer.new()
	root_box.add_child(header)
	var header_title := _label(header, "가방 인벤토리 / LOADOUT", 20)
	header_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	header_title.clip_text = true
	header_title.size_flags_horizontal = SIZE_EXPAND_FILL
	var close_button := _button(header, "닫기 / ESC", close_panel)
	close_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	close_button.custom_minimum_size.x = 104
	header_summary = _label(root_box, "", 12)
	header_summary.max_lines_visible = 1
	var tab_row := HBoxContainer.new()
	root_box.add_child(tab_row)
	for title in ["작전 가방", "무기 · 파츠", "모듈 설정"]:
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
	loadout_column = _column(columns, loadout_column_width)
	gear_column = _column(loadout_column, 0)
	stats_column = _column(loadout_column, 0)
	_label(stats_column, "장비 능력치", 13)
	stats_label = _label(stats_column, "", 14)
	module_column = _column(columns, 190)
	_label(module_column, "무기 거치대 / ARMORY", 16)
	module_list = VBoxContainer.new()
	module_column.add_child(module_list)
	var bag_column := _column(columns, 0)
	bag_column.size_flags_horizontal = SIZE_EXPAND_FILL
	_label(bag_column, "회수품 / BACKPACK", 17)
	_label(bag_column, "드래그 이동 · 선택 후 R 회전", 12)
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
	capacity_meter = ProgressBar.new()
	capacity_meter.custom_minimum_size.y = 5
	capacity_meter.show_percentage = false
	bag_column.add_child(capacity_meter)
	detail_column = _column(columns, inspection_column_width)
	_label(detail_column, "아이템 검사 / INSPECT", 12)
	selected_preview = ITEM_PREVIEW.new()
	selected_preview.custom_minimum_size.y = 156
	detail_column.add_child(selected_preview)
	selected_name = _label(detail_column, "아이템 선택", 18)
	selected_description = _label(detail_column, "아이템을 선택하면 상세 정보가 표시됩니다.", 13)
	runtime_target_picker = InventoryActionTargetPicker.new()
	detail_column.add_child(runtime_target_picker)
	runtime_target_picker.hide()
	runtime_target_picker.selection_changed.connect(func():
		action_button.disabled = not runtime_target_picker.is_complete()
		status_label.text = "선택 대상 확인 후 장착하세요." if runtime_target_picker.is_complete() else "적용할 대상을 먼저 선택하세요.")
	rotate_button = _button(detail_column, "선택 아이템 회전 / R", _rotate_selected_item)
	action_button = _button(detail_column, "선택 슬롯에 장착", _apply_selection)
	ui.action(action_button, "gear", true)
	unequip_button = _button(detail_column, "선택 장비 해제", _unequip_selection)
	socket_actions = VBoxContainer.new()
	detail_column.add_child(socket_actions)
	_label(detail_column, "장비 관리 · 변경은 저장 후 적용됩니다.", 12)
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
	_label(gear_column, "장착 중 / EQUIPPED", 13)
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
			button.custom_minimum_size = Vector2(88, 88)
			button.size_flags_horizontal = SIZE_EXPAND_FILL
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.add_theme_font_size_override("font_size", 13)
			button.add_theme_stylebox_override("normal", _style(Color("324e60")))
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


func _refresh() -> void:
	if session.inventory == null:
		return
	var snapshot: Dictionary = session.inventory.get_snapshot()
	var used := 0
	for item: Dictionary in snapshot[&"items"]:
		var footprint: Vector2i = item[&"grid_size"]
		used += footprint.x * footprint.y
	var dimensions: Vector2i = snapshot[&"grid_size"]
	_refresh_header()
	capacity_label.text = "공간 사용 %d / %d칸 · 세로 스크롤" % [used, dimensions.x * dimensions.y]
	capacity_meter.value = 100.0 * used / maxi(1, dimensions.x * dimensions.y)
	for i in tabs.size():
		tabs[i].set_pressed_no_signal(i == current_tab)
	module_column.visible = current_tab != 0
	gear_column.visible = current_tab != 1
	loadout_column.visible = current_tab == 0
	stats_column.visible = current_tab == 0
	_refresh_modules()
	_refresh_socket_actions()
	for slot in slot_buttons:
		var state: Resource = session.equipment.get_equipment_state(slot)
		var label: String = SLOT_NAMES.get(slot, String(slot))
		var item_name: String = state.definition.display_name if state != null else "빈 슬롯"
		var card_entry := {&"item_type": &"weapon" if slot in [&"main",&"secondary"] else &"armor", &"linked_resource": state.definition} if state != null else {}
		slot_buttons[slot].present(label,item_name,card_entry,slot == selected_slot)
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
	if current_tab == 2 and session.error_message.is_empty():
		status_label.text = "대상 → 슬롯 → 모듈 선택 · 최대 레벨에서 소켓 개조 · 저장 시 적용"
	rotate_button.text = "선택 아이템 회전 / %s" % _action_binding_label(&"equip_field_loot", "R")
	rotate_button.disabled = selected_entry.is_empty() or not bool(selected_entry.get(&"can_rotate", false))
	action_button.disabled = selected_entry.is_empty() or (_runtime_action_provider(selected_entry) == null and (session.equipment == null or selected_entry.get(&"item_type") not in [&"weapon", &"armor", &"module", &"part"]))
	if selected_entry.is_empty(): runtime_target_picker.present([], &"")
	elif runtime_target_picker.visible: action_button.disabled = not runtime_target_picker.is_complete()
	unequip_button.disabled = session.equipment == null
	_layout()
	if current_tab == 2 and session.equipment != null:
		if module_workspace == null:
			module_workspace = load("res://game/features/equipment/module_workspace.gd").new()
			module_workspace.size_flags_horizontal = SIZE_EXPAND_FILL
			columns.add_child(module_workspace)
			module_workspace.advanced_requested.connect(func(): request_leave(func():
				_finish_close()
				external_panel_requested.emit(&"toggle_equipment")))
		for column in columns.get_children(): column.visible = column == module_workspace
		module_workspace.configure(session)
	else:
		bag_scroll.get_parent().show()
		detail_column.show()
		if module_workspace != null: module_workspace.hide()


func _refresh_stats() -> void:
	if session.equipment == null:
		stats_label.text = "장비 기능 비활성"
		return
	var modifiers: Dictionary = session.equipment.get_stat_modifiers()
	var summary: Dictionary = session.equipment.get_summary()
	stats_label.text = "활성 스킬  %d / %d\n" % [summary[&"active_skill_count"], summary[&"equipped_skill_count"]]
	var names := {&"max_health": "최대 체력", &"defense": "방어력", &"movement_speed": "이동속도", &"damage": "공격력"}
	var preview: Dictionary = equipment_provider.get_player_stat_preview(modifiers)
	for stat in preview:
		stats_label.text += "%s  %.1f\n" % [names.get(stat, String(stat)), float(preview[stat])]
	if preview.is_empty():
		for stat in modifiers:
			stats_label.text += "%s  %+.1f / ×%.2f\n" % [names.get(stat, String(stat)), modifiers[stat].get(&"add", 0.0), modifiers[stat].get(&"multiply", 1.0)]
	stats_label.text += ArmorSetResolver.describe(session.equipment.get_armor_set_snapshot())


func _refresh_modules() -> void:
	if current_tab == 2: return
	if weapon_rack == null and session.equipment != null:
		weapon_rack = load("res://game/features/equipment/weapon_attachment_rack.gd").new()
		module_column.add_child(weapon_rack)
		module_column.move_child(weapon_rack, 1)
		weapon_rack.weapon_selected.connect(_select_slot)
		weapon_rack.socket_selected.connect(_on_weapon_socket_selected)
	if weapon_rack != null:
		weapon_rack.visible = current_tab == 1
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
	if current_tab == 1 and weapon_rack != null:
		weapon_rack.configure(session.equipment, selected_slot, selected_socket)
	if state == null:
		_label(module_list, "장비를 먼저 장착하세요.", 13)
		return
	_label(module_list, "%s\n코스트 %d / %d\n모듈 %d / %d" % [state.definition.display_name, state.used_module_cost(), state.module_cost_limit(), state.installed_modules.size(), state.module_slot_limit()], 13)
	for module in state.installed_modules:
		_button(module_list, "%s · %d C\n해제" % [module.definition.display_name, state.effective_module_cost(module)], _remove_modification.bind(&"module", module.instance_id))
	for part in state.installed_parts:
		if current_tab != 1:
			_button(module_list, "%s\n파츠 해제" % part.display_name, _remove_modification.bind(&"part", part.part_id))
	if current_tab != 1:
		_label(module_list, "가방에서 선택 후 장착 · 소켓 규칙 적용", 12)


func _select_slot(slot: StringName) -> void:
	selected_slot = slot
	selected_socket = &""
	_refresh()


func _on_weapon_socket_selected(slot: StringName, socket: StringName) -> void:
	selected_slot = slot
	selected_socket = socket
	_refresh()
	selected_name.text = "파츠 슬롯 · %s" % weapon_rack.get_socket_label(socket)
	selected_description.text = "호환 파츠를 선택하면 초안에 장착합니다. 변경은 저장 시 적용됩니다."


func _refresh_socket_actions() -> void:
	for child in socket_actions.get_children():
		socket_actions.remove_child(child)
		child.queue_free()
	socket_actions.visible = current_tab == 1 and selected_socket != &""
	if not socket_actions.visible or session.equipment == null:
		return
	var state: Resource = session.equipment.get_equipment_state(selected_slot)
	if state == null or not state.is_weapon() or selected_socket not in state.definition.part_socket_ids:
		selected_socket = &""
		return
	for part in state.installed_parts:
		if part.socket_id == selected_socket:
			_button(socket_actions, "%s\n파츠 해제 → 가방" % part.display_name, _remove_modification.bind(&"part", part.part_id))
	_label(socket_actions, "호환 파츠 · 보유 목록", 13)
	var count := 0
	for entry: Dictionary in session.inventory.get_snapshot()[&"items"]:
		if entry.get(&"item_type") != &"part":
			continue
		var part: Resource = entry.get(&"linked_resource")
		if part != null and part.socket_id == selected_socket and part.supports_weapon(state.definition):
			_button(socket_actions, entry[&"display_name"] + "\n장착 / 교체", _install_socket_item.bind(entry[&"instance_id"]))
			count += 1
	if count == 0:
		_label(socket_actions, "보유한 호환 파츠가 없습니다.\n다른 무기 전용 파츠는 장착할 수 없습니다.", 12)


func _install_socket_item(id: StringName) -> void:
	session.replace_part(id, selected_slot)


func _on_item_selected(entry: Dictionary) -> void:
	selected_entry = entry.duplicate()
	_show_selected_entry(entry)


func _show_selected_entry(entry: Dictionary) -> void:
	selected_name.text = entry[&"display_name"]
	selected_preview.present(entry)
	var footprint: Vector2i = entry[&"grid_size"]
	var kind_label: String = {&"weapon": "무기", &"armor": "방어구", &"module": "모듈", &"part": "고유 파츠", &"consumable": "소모품"}.get(entry[&"item_type"], "아이템")
	var orientation := "회전됨" if bool(entry.get(&"rotated", false)) else "기본 방향"
	selected_description.text = "%d×%d칸 · %s · %s\n\n%s" % [footprint.x, footprint.y, kind_label, orientation, entry[&"description"]]
	action_button.text = "모듈 / 파츠 장착" if entry[&"item_type"] in [&"module", &"part"] else "선택 슬롯에 장착"
	action_button.tooltip_text = ""
	action_button.disabled = session.equipment == null or entry[&"item_type"] not in [&"weapon", &"armor", &"module", &"part"]
	var runtime_provider := _runtime_action_provider(entry)
	var groups: Array = []
	if runtime_provider != null:
		action_button.text = "런 소켓에 즉시 장착"
		action_button.disabled = false
		action_button.tooltip_text = "선택한 대상에만 적용합니다. 미저장 편집은 먼저 저장/버리기/계속 편집을 확인합니다."
		if runtime_provider.has_method(&"get_inventory_action_targets") and runtime_provider.has_method(&"perform_targeted_inventory_item_action"):
			groups = runtime_provider.call(&"get_inventory_action_targets", StringName(entry.item_id))
	runtime_target_picker.present(groups, StringName(entry.instance_id))
	if not groups.is_empty(): action_button.disabled = not runtime_target_picker.is_complete()
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
	var provider := _runtime_action_provider(selected_entry)
	if provider != null:
		var item_id := StringName(selected_entry.get(&"item_id", &""))
		var instance_id := StringName(selected_entry.get(&"instance_id", &""))
		var targeted := provider.has_method(&"get_inventory_action_targets") and provider.has_method(&"perform_targeted_inventory_item_action")
		if targeted and not runtime_target_picker.is_complete():
			status_label.text = "적용할 대상을 먼저 선택하세요."
			return
		var targets := runtime_target_picker.get_selection()
		request_leave(func():
			if not is_instance_valid(provider):
				status_label.text = "사용 가능한 런 소켓이 없습니다."
				return
			var result: Dictionary = provider.call(&"perform_targeted_inventory_item_action", item_id, targets, instance_id) if targeted else provider.call(&"perform_inventory_item_action", item_id)
			session.begin()
			_bind_draft()
			var reason := StringName(result.get(&"reason", &""))
			var explanation: String = {&"invalid_target": "대상이 변경되었습니다. 아이템과 대상을 다시 선택하세요.", &"not_owned": "선택한 아이템이 없어 장착하지 않았습니다.", &"duplicate_limit": "이미 같은 자산이 장착되어 있습니다.", &"bag_full": "교체품을 돌려받을 가방 공간이 부족합니다."}.get(reason, String(reason))
			status_label.text = "선택 대상에 런 소켓 장착 완료" if result.get(&"success", false) else "장착 불가 · " + explanation
		)
		return
	var id: StringName = selected_entry[&"instance_id"]
	var ok := bool(session.install_item(id, selected_slot) if selected_entry[&"item_type"] in [&"module", &"part"] else session.equip_item(id, selected_slot))
	if ok:
		selected_entry.clear()
		selected_preview.present({})
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
	var layout_width := minf(size.x, get_viewport_rect().size.x - 40)
	var proportions := SCREEN_LAYOUT.inventory(layout_width, current_tab == 1)
	var narrow: bool = proportions.narrow
	columns.vertical = narrow
	var bag_column: Control = bag_scroll.get_parent()
	if narrow and bag_column.get_index() != 0: columns.move_child(bag_column,0)
	elif not narrow:
		for index in 4:
			var column: Control = [loadout_column,module_column,bag_column,detail_column][index]
			if column.get_index() != index: columns.move_child(column,index)
	loadout_column.custom_minimum_size.x = proportions.loadout
	gear_column.custom_minimum_size.x = 0
	stats_column.custom_minimum_size.x = 0
	detail_column.custom_minimum_size.x = proportions.inspect
	module_column.custom_minimum_size.x = proportions.parts
	if session.inventory != null:
		var dimensions: Vector2i = session.inventory.grid_size
		var budget := layout_width - 64
		if not narrow:
			budget -= float(proportions.inspect) + (float(proportions.parts) if current_tab == 1 else float(proportions.loadout)) + 24
		var available := maxf(240, minf(budget, bag_scroll.size.x - 18))
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
