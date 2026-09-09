class_name EquipmentWorkbench
extends PanelContainer

signal panel_visibility_changed(is_open: bool)

const SLOT_LABELS := {
	&"main": "01  메인 무기",
	&"secondary": "02  보조 무기",
	&"body": "03  신체 방어구",
	&"feet": "04  신발 방어구",
	&"head": "05  머리 방어구",
	&"hands": "06  장갑 방어구",
}
const WEAPON_SLOTS := [&"main", &"secondary"]
const MODULE_UI_PRESENTER_SCRIPT := preload(
	"res://game/features/equipment/equipment_module_ui_presenter.gd"
)

@onready var tabs: TabContainer = %Tabs
@onready var key_badge: Label = %KeyBadge
@onready var window_title: Label = %WindowTitle
@onready var header_summary: Label = %HeaderSummary
@onready var character_summary: Label = %CharacterSummary
@onready var selected_slot_caption: Label = %SelectedSlotCaption
@onready var selected_equipment_name: Label = %SelectedEquipmentName
@onready var selected_equipment_meta: Label = %SelectedEquipmentMeta
@onready var equipment_level_bar: ProgressBar = %EquipmentLevelBar
@onready var equipment_stats: Label = %EquipmentStats
@onready var equipment_inventory_count: Label = %EquipmentInventoryCount
@onready var equipment_inventory_grid: GridContainer = %EquipmentInventoryGrid
@onready var equipment_candidate_detail: Label = %EquipmentCandidateDetail
@onready var equip_selected_button: Button = %EquipSelectedButton
@onready var unequip_equipment_button: Button = %UnequipEquipmentButton
@onready var selected_module_equipment: Label = %SelectedModuleEquipment
@onready var module_capacity_label: Label = %ModuleCapacityLabel
@onready var module_cost_bar: ProgressBar = %ModuleCostBar
@onready var module_effect_summary: Label = %ModuleEffectSummary
@onready var installed_module_grid: GridContainer = %InstalledModuleGrid
@onready var installed_part_grid: GridContainer = %InstalledPartGrid
@onready var weapon_parts_board: Control = %WeaponPartsBoard
@onready var installed_selection_detail: Label = %InstalledSelectionDetail
@onready var modification_inventory_count: Label = %ModificationInventoryCount
@onready var modification_inventory_grid: GridContainer = %ModificationInventoryGrid
@onready var modification_candidate_detail: Label = %ModificationCandidateDetail
@onready var install_selected_modification_button: Button = %InstallSelectedModificationButton
@onready var uninstall_selected_button: Button = %UninstallSelectedButton
@onready var status_label: Label = %WorkbenchStatus

var equipment_provider: Node
var inventory_provider: Node
var upgrade_provider: Node
var paused_before_open: bool = false
var selected_slot_id: StringName = &"main"
var selected_inventory_entry: Dictionary = {}
var selected_installed_kind: StringName = &""
var selected_installed_id: StringName = &""
var modification_filter: StringName = &"all"
var modification_sort: StringName = &"compatibility"
var slot_buttons: Dictionary = {}
var read_only: bool = false
var module_ui_presenter = MODULE_UI_PRESENTER_SCRIPT.new()
var equipment_preview: Control
var screen_scroll: ScrollContainer
var screen_main: BoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	visible = false
	slot_buttons = {
		&"main": %MainSlotButton,
		&"secondary": %SecondarySlotButton,
		&"body": %BodySlotButton,
		&"feet": %FeetSlotButton,
	}
	for slot_id in slot_buttons:
		(slot_buttons[slot_id] as Button).pressed.connect(_select_slot.bind(slot_id))
		(slot_buttons[slot_id] as Button).add_theme_color_override(&"font_pressed_color", Color("f1f7fa"))
	# Insert after feet in reverse order so the visible rail stays 01..06.
	for slot: StringName in [&"hands", &"head"]:
		var button := Button.new()
		button.custom_minimum_size.y = 42
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size", 13)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		%BodySlotButton.get_parent().add_child(button)
		%BodySlotButton.get_parent().move_child(button, %FeetSlotButton.get_index() + 1)
		button.pressed.connect(_select_slot.bind(slot))
		slot_buttons[slot] = button
	tabs.set_tab_title(0, "장비 장착")
	tabs.set_tab_title(1, "모듈 · 파츠")
	tabs.tab_changed.connect(_on_tab_changed)
	%AllModificationFilter.pressed.connect(_set_modification_filter.bind(&"all"))
	%ModuleFilter.pressed.connect(_set_modification_filter.bind(&"module"))
	%PartFilter.pressed.connect(_set_modification_filter.bind(&"part"))
	%CompatibilitySort.pressed.connect(_set_modification_sort.bind(&"compatibility"))
	%CostSort.pressed.connect(_set_modification_sort.bind(&"cost"))
	weapon_parts_board.connect(&"socket_selected", _on_weapon_part_socket_selected)
	equip_selected_button.pressed.connect(_equip_selected_candidate)
	unequip_equipment_button.pressed.connect(_unequip_selected_equipment)
	install_selected_modification_button.pressed.connect(_install_selected_modification)
	uninstall_selected_button.pressed.connect(_uninstall_selected_modification)
	%LevelUpButton.pressed.connect(_level_up_selected)
	%ModifyButton.pressed.connect(_grant_selected_module_tag)
	%UpgradeInstalledButton.pressed.connect(_upgrade_selected_module)
	%UpgradeInstalledPartButton.pressed.connect(_upgrade_selected_part)
	%ModuleModifyButton.pressed.connect(_grant_selected_module_tag)
	_refresh_filter_buttons()
	var ui = preload("res://game/features/presentation_theme/game_ui.gd")
	ui.action(equip_selected_button, "gear", true)
	ui.action(install_selected_modification_button, "skill", true)
	ui.action(%LevelUpButton, "training")
	ui.action(%UpgradeInstalledButton, "craft")
	ui.action(%UpgradeInstalledPartButton, "craft")
	_build_game_layout()


func _build_game_layout() -> void:
	# Keep the existing commands; only reparent the visual containers.
	screen_main = %SlotRail.get_parent()
	var parent := screen_main.get_parent()
	var index := screen_main.get_index()
	screen_scroll = ScrollContainer.new()
	screen_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	parent.add_child(screen_scroll)
	parent.move_child(screen_scroll, index)
	screen_main.reparent(screen_scroll)
	screen_main.size_flags_horizontal = SIZE_EXPAND_FILL
	equipment_preview = preload("res://game/features/presentation_theme/inventory_item_preview.gd").new()
	equipment_preview.custom_minimum_size.y = 154
	var detail := selected_equipment_meta.get_parent()
	detail.add_child(equipment_preview)
	detail.move_child(equipment_preview, selected_equipment_meta.get_index() + 1)
	for button in slot_buttons.values():
		button.set_script(preload("res://game/features/presentation_theme/inventory_slot_button.gd"))
		button.custom_minimum_size = Vector2(0, 70)
		button.clip_text = true
	for node in find_children("*", "Label", true, false):
		node.custom_minimum_size.x = 0
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if node.get_parent() is HBoxContainer:
			node.autowrap_mode = TextServer.AUTOWRAP_OFF
		node.add_theme_font_size_override("font_size", mini(16, node.get_theme_font_size("font_size")))
	selected_equipment_name.add_theme_font_size_override("font_size", 22)
	var title_block := window_title.get_parent()
	title_block.size_flags_horizontal = SIZE_EXPAND_FILL
	for label in title_block.get_children():
		if label is Label:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.clip_text = true
	for label in status_label.get_parent().get_children():
		if label is Label:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.clip_text = true
	status_label.tooltip_text = status_label.text
	header_summary.hide()
	for grid in [%LevelUpButton.get_parent(), %ModuleModifyButton.get_parent()]:
		if grid is GridContainer: grid.columns = 1
	for button in find_children("*", "Button", true, false):
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.x = 0
		button.size_flags_horizontal = SIZE_EXPAND_FILL
	# Primary commands sit above optional stats and upgrade controls, not below
	# a variable-height description. Long descriptions may scroll independently.
	unequip_equipment_button.reparent(detail)
	detail.move_child(unequip_equipment_button, equipment_preview.get_index() + 1)
	var installed_content := installed_selection_detail.get_parent()
	uninstall_selected_button.reparent(installed_content)
	installed_content.move_child(uninstall_selected_button, module_cost_bar.get_index() + 1)
	for action in [equip_selected_button, install_selected_modification_button]:
		var content: Node = action.get_parent()
		content.move_child(action, 1)
	var close := Button.new()
	close.text = "닫기 / ESC"
	close.custom_minimum_size = Vector2(104, 44)
	close.pressed.connect(close_panel)
	header_summary.get_parent().add_child(close)
	resized.connect(_layout_game_screen)
	screen_scroll.resized.connect(_layout_game_screen)
	get_viewport().size_changed.connect(_layout_game_screen)
	_layout_game_screen()


func _layout_game_screen() -> void:
	if screen_main == null: return
	var width := minf(size.x, get_viewport_rect().size.x - 56)
	var narrow := width < 1000
	screen_main.vertical = narrow
	%SlotRail.custom_minimum_size.x = 0 if narrow else 182
	for tab in tabs.get_children():
		if tab is BoxContainer:
			tab.vertical = narrow
			for panel in tab.get_children():
				panel.custom_minimum_size.x = 0 if narrow else 286 if panel.get_index() == 0 else 0
	var available := maxf(180, width - (88 if narrow else 550))
	equipment_inventory_grid.columns = clampi(floori(available / 174), 1, 4)
	modification_inventory_grid.columns = clampi(floori(available / 146), 1, 5)
	installed_module_grid.columns = 2
	installed_part_grid.columns = 1


func configure(
	new_equipment_provider: Node,
	new_inventory_provider: Node,
	new_upgrade_provider: Node = null,
	new_read_only: bool = false
) -> bool:
	if new_equipment_provider == null or new_inventory_provider == null:
		return false
	equipment_provider = new_equipment_provider
	inventory_provider = new_inventory_provider
	upgrade_provider = new_upgrade_provider
	read_only = new_read_only
	if equipment_provider.has_signal(&"customization_changed"):
		var customization_callback := Callable(self, &"_on_data_changed")
		if not equipment_provider.is_connected(&"customization_changed", customization_callback):
			equipment_provider.connect(&"customization_changed", customization_callback)
	if inventory_provider.has_signal(&"inventory_changed"):
		var inventory_callback := Callable(self, &"_on_data_changed")
		if not inventory_provider.is_connected(&"inventory_changed", inventory_callback):
			inventory_provider.connect(&"inventory_changed", inventory_callback)
	_refresh()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
		return
	var requested_tab := -1
	if event.is_action_pressed(&"toggle_equipment") and not event.is_echo():
		requested_tab = 0
	elif event.is_action_pressed(&"toggle_modification") and not event.is_echo():
		requested_tab = 1
	if requested_tab < 0:
		return
	if requested_tab == 1 and _open_module_workspace():
		get_viewport().set_input_as_handled()
		return
	if visible and tabs.current_tab != requested_tab:
		tabs.current_tab = requested_tab
		get_viewport().set_input_as_handled()
		return
	tabs.current_tab = requested_tab
	toggle_panel()
	get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()


func open_panel() -> void:
	if visible:
		# Re-selecting U/E or opening a tab programmatically must not replace
		# the original pause state with the modal's own paused state.
		_refresh()
		return
	for panel in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if panel != self and panel.visible and panel.has_method(&"request_leave"):
			panel.call(&"request_leave", func():
				panel.call(&"close_panel")
				open_panel()
			)
			return
		if panel != self and panel.has_method(&"close_panel"):
			panel.call(&"close_panel")
	paused_before_open = get_tree().paused
	move_to_front()
	visible = true
	get_tree().paused = true
	_refresh()
	panel_visibility_changed.emit(true)


func close_panel() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = paused_before_open
	panel_visibility_changed.emit(false)


func show_weapon_tab() -> void:
	selected_slot_id = &"main"
	tabs.current_tab = 0
	open_panel()


func show_armor_tab() -> void:
	selected_slot_id = &"body"
	tabs.current_tab = 0
	open_panel()


func show_modification_tab() -> void:
	if _open_module_workspace(): return
	tabs.current_tab = 1
	open_panel()


func _open_module_workspace() -> bool:
	for panel in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if panel != self and panel.has_method(&"open_modules"):
			close_panel()
			panel.call(&"open_modules", selected_slot_id)
			return true
	return false


func _select_slot(slot_id: StringName) -> void:
	selected_slot_id = slot_id
	selected_inventory_entry.clear()
	selected_installed_kind = &""
	selected_installed_id = &""
	_refresh()


func _set_modification_filter(filter_id: StringName) -> void:
	modification_filter = filter_id
	selected_inventory_entry.clear()
	_refresh_filter_buttons()
	_refresh_modification_inventory()


func _set_modification_sort(sort_id: StringName) -> void:
	modification_sort = sort_id
	_refresh_filter_buttons()
	_refresh_modification_inventory()


func _on_tab_changed(tab: int) -> void:
	selected_inventory_entry.clear()
	key_badge.text = "U" if tab == 0 else "E"
	window_title.text = "캐릭터 장비 관리" if tab == 0 else "모듈 세팅 · 효과 관리"
	_refresh()


func _on_data_changed(_snapshot: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	if not _providers_are_ready():
		return
	_refresh_slot_rail()
	_refresh_equipment_detail()
	_refresh_equipment_inventory()
	_refresh_installed_customization()
	_refresh_modification_inventory()
	_apply_read_only_state()
	_layout_game_screen()


func _apply_read_only_state() -> void:
	if not read_only:
		return
	for button in [
		equip_selected_button,
		unequip_equipment_button,
		install_selected_modification_button,
		uninstall_selected_button,
		%LevelUpButton,
		%ModifyButton,
		%UpgradeInstalledButton,
		%UpgradeInstalledPartButton,
		%ModuleModifyButton,
	]:
		(button as Button).disabled = true
	status_label.text = "현재 환경은 장비 조회 전용입니다. 장착·강화 기능이 연결되지 않았습니다."


func _refresh_slot_rail() -> void:
	var equipped_count := 0
	var installed_module_count := 0
	var active_weapon_slot: StringName = equipment_provider.call(&"get_active_weapon_slot")
	for slot_id in SLOT_LABELS:
		var state := _get_state(slot_id)
		var button := slot_buttons[slot_id] as Button
		button.button_pressed = slot_id == selected_slot_id
		button.text = "%s%s\n%s" % [
			"▶ " if slot_id == active_weapon_slot else "  ",
			SLOT_LABELS[slot_id],
			state.display_name() if state != null else "비어 있음",
		]
		button.present(SLOT_LABELS[slot_id], state.display_name() if state != null else "빈 슬롯",
			{&"item_type": &"weapon" if state.is_weapon() else &"armor", &"linked_resource": state.definition} if state != null else {},
			slot_id == selected_slot_id)
		if state != null:
			equipped_count += 1
			installed_module_count += state.installed_modules.size()
	var summary: Dictionary = equipment_provider.call(&"get_summary")
	character_summary.text = "장비 태그 호환 %d/%d\n작전 장비 %d슬롯 · 외부 방어 Lv.%d" % [
		int(summary.get(&"active_skill_count", 0)),
		int(summary.get(&"equipped_skill_count", 0)),
		equipped_count,
		int(summary.get(&"external_armor_level", 1)),
	]
	header_summary.text = "장비 %d/6 · 장착 모듈 %d · 선택 슬롯 %s" % [
		equipped_count,
		installed_module_count,
		_slot_display_name(selected_slot_id),
	]


func _refresh_equipment_detail() -> void:
	var state := _get_state(selected_slot_id)
	if equipment_preview != null:
		equipment_preview.present({&"item_type": &"weapon" if state.is_weapon() else &"armor", &"linked_resource": state.definition} if state != null else {})
	selected_slot_caption.text = "%s / EQUIPPED" % String(SLOT_LABELS[selected_slot_id]).to_upper()
	if state == null:
		selected_equipment_name.text = "장착 장비 없음"
		selected_equipment_meta.text = "오른쪽 인벤토리에서 호환 장비를 선택하세요."
		equipment_level_bar.max_value = 1
		equipment_level_bar.value = 0
		equipment_stats.text = "이 슬롯에 장비를 장착하면 레벨, 태그, 모듈 용량과 장비 효과를 확인할 수 있습니다."
		%LevelUpButton.disabled = true
		%ModifyButton.disabled = true
		unequip_equipment_button.disabled = true
		return
	var snapshot := state.snapshot()
	selected_equipment_name.text = state.display_name()
	selected_equipment_meta.text = "장비 Lv.%d/%d · %s" % [
		int(snapshot[&"level"]),
		int(snapshot[&"maximum_level"]),
		_definition_meta(state.definition),
	]
	equipment_level_bar.max_value = maxi(1, int(snapshot[&"maximum_level"]))
	equipment_level_bar.value = int(snapshot[&"level"])
	equipment_stats.text = _equipment_stats_text(state)
	if state.is_armor(): equipment_stats.text += "\n" + ArmorSetResolver.describe(equipment_provider.get_armor_set_snapshot())
	%LevelUpButton.disabled = read_only or int(snapshot[&"level"]) >= int(snapshot[&"maximum_level"])
	%ModifyButton.disabled = (
		read_only
		or int(snapshot[&"level"]) < int(snapshot[&"maximum_level"])
		or state.installed_modules.is_empty()
	)
	unequip_equipment_button.disabled = read_only


func _refresh_equipment_inventory() -> void:
	_clear_cards(equipment_inventory_grid)
	var matching_type: StringName = &"weapon" if selected_slot_id in WEAPON_SLOTS else &"armor"
	var candidates: Array[Dictionary] = inventory_provider.call(&"get_items_by_type", matching_type)
	equipment_inventory_count.text = "%d개" % candidates.size()
	for entry in candidates:
		var definition: Resource = entry.get(&"linked_resource")
		var compatible := bool(equipment_provider.call(
			&"can_equip_definition", selected_slot_id, definition
		))
		var selected: bool = (
			not selected_inventory_entry.is_empty()
			and selected_inventory_entry.get(&"instance_id") == entry.get(&"instance_id")
		)
		var card := _make_card(
			"%s\n%s\n%s" % [
				entry.get(&"display_name", "이름 없음"),
				_definition_meta(definition),
				"장착 가능" if compatible else "태그 불일치",
			],
			entry.get(&"panel_color", Color(0.2, 0.8, 0.7)),
			selected,
			compatible,
			Vector2(190, 78)
		)
		card.tooltip_text = String(entry.get(&"description", ""))
		card.set_script(preload("res://game/features/presentation_theme/inventory_slot_button.gd"))
		card.custom_minimum_size = Vector2(160, 116)
		card.present("장착 가능" if compatible else "호환 불가", String(entry.get(&"display_name", "")), entry, selected)
		card.pressed.connect(_select_inventory_candidate.bind(entry, &"equipment"))
		equipment_inventory_grid.add_child(card)
	if candidates.is_empty():
		_add_empty_card(equipment_inventory_grid, "보유 중인 장비 없음")
	_refresh_inventory_candidate_detail()


func _refresh_installed_customization() -> void:
	_clear_cards(installed_module_grid)
	_clear_cards(installed_part_grid)
	var state := _get_state(selected_slot_id)
	if state == null:
		selected_module_equipment.text = "장착 장비 없음 / 모듈 설정"
		module_capacity_label.text = "모듈 0/0 · 코스트 0/0"
		module_cost_bar.max_value = 1
		module_cost_bar.value = 0
		module_cost_bar.self_modulate = Color(0.45, 0.52, 0.56)
		module_effect_summary.text = module_ui_presenter.call(&"applied_effects_text", null)
		weapon_parts_board.call(&"configure", null)
		_add_empty_card(installed_module_grid, "장비 필요")
		_add_empty_card(installed_part_grid, "장비 필요")
		_refresh_installed_selection_detail()
		return
	selected_module_equipment.text = "%s / 모듈 설정" % state.display_name()
	module_capacity_label.text = "모듈 %d/%d · 코스트 %d/%d" % [
		state.installed_modules.size(),
		state.module_slot_limit(),
		state.used_module_cost(),
		state.module_cost_limit(),
	]
	module_cost_bar.max_value = maxi(1, state.module_cost_limit())
	module_cost_bar.value = state.used_module_cost()
	var cost_ratio := float(state.used_module_cost()) / float(maxi(1, state.module_cost_limit()))
	module_cost_bar.self_modulate = (
		Color(1.0, 0.42, 0.24)
		if cost_ratio >= 0.9
		else Color(1.0, 0.78, 0.28) if cost_ratio >= 0.65
		else Color(0.42, 1.0, 0.78)
	)
	module_effect_summary.text = module_ui_presenter.call(&"applied_effects_text", state)
	var selected_socket_id: StringName = &""
	if selected_installed_kind == &"part" and selected_installed_id != &"":
		var selected_part = state.get_part(selected_installed_id)
		if selected_part != null:
			selected_socket_id = selected_part.socket_id
	weapon_parts_board.call(&"configure", state, selected_socket_id)
	for module_instance in state.installed_modules:
		var selected: bool = (
			selected_installed_kind == &"module"
			and selected_installed_id == module_instance.instance_id
		)
		var card := _make_card(
			module_ui_presenter.call(&"installed_card_text", state, module_instance),
			Color(0.35, 0.88, 0.76),
			selected,
			true,
			Vector2(96, 78)
		)
		card.pressed.connect(_select_installed.bind(&"module", module_instance.instance_id))
		installed_module_grid.add_child(card)
	for index in range(state.installed_modules.size(), state.module_slot_limit()):
		_add_empty_card(installed_module_grid, "+ 모듈 슬롯")
	if state.module_slot_limit() == 0:
		_add_empty_card(installed_module_grid, "모듈 슬롯 없음")
	if state.is_weapon():
		for part in state.installed_parts:
			var selected := selected_installed_kind == &"part" and selected_installed_id == part.part_id
			var level := int(state.part_upgrade_levels.get(part.part_id, 1))
			var card := _make_card(
				"%s\n%s · Lv.%d" % [part.display_name, part.socket_id, level],
				Color(0.86, 0.58, 0.22),
				selected,
				true,
				Vector2(165, 60)
			)
			card.pressed.connect(_select_installed.bind(&"part", part.part_id))
			installed_part_grid.add_child(card)
		if state.installed_parts.is_empty():
			_add_empty_card(installed_part_grid, "+ 고유 파츠 슬롯")
	else:
		_add_empty_card(installed_part_grid, "방어구는 모듈만 장착")
	_refresh_installed_selection_detail()


func _refresh_modification_inventory() -> void:
	if not _providers_are_ready():
		return
	_clear_cards(modification_inventory_grid)
	var entries: Array[Dictionary] = []
	for entry in inventory_provider.call(&"get_snapshot").get(&"items", []):
		var item_type: StringName = entry.get(&"item_type", &"")
		if item_type not in [&"module", &"part"]:
			continue
		if modification_filter != &"all" and item_type != modification_filter:
			continue
		var display_entry: Dictionary = entry.duplicate(true)
		display_entry[&"ui_compatible"] = _can_install_entry(
			_get_state(selected_slot_id), display_entry
		)
		entries.append(display_entry)
	entries.sort_custom(_sort_modification_entries)
	modification_inventory_count.text = "%d개" % entries.size()
	var state := _get_state(selected_slot_id)
	for entry in entries:
		var compatible := bool(entry.get(&"ui_compatible", false))
		var selected: bool = (
			not selected_inventory_entry.is_empty()
			and selected_inventory_entry.get(&"instance_id") == entry.get(&"instance_id")
		)
		var card := _make_card(
			module_ui_presenter.call(&"inventory_card_text", entry, compatible),
			entry.get(&"panel_color", Color(0.2, 0.8, 0.7)),
			selected,
			compatible,
			Vector2(138, 92)
		)
		card.tooltip_text = String(entry.get(&"description", ""))
		card.set_meta(&"item_type", entry.get(&"item_type", &""))
		card.pressed.connect(_select_inventory_candidate.bind(entry, &"modification"))
		modification_inventory_grid.add_child(card)
	if entries.is_empty():
		_add_empty_card(modification_inventory_grid, "조건에 맞는 아이템 없음")
	_refresh_inventory_candidate_detail()


func _select_inventory_candidate(entry: Dictionary, candidate_kind: StringName) -> void:
	selected_inventory_entry = entry.duplicate(true)
	tabs.current_tab = 0 if candidate_kind == &"equipment" else 1
	_refresh()


func _select_installed(kind: StringName, target_id: StringName) -> void:
	selected_installed_kind = kind
	selected_installed_id = target_id
	_refresh()


func _on_weapon_part_socket_selected(socket_id: StringName) -> void:
	var state := _get_state(selected_slot_id)
	if state == null or not state.is_weapon():
		return
	modification_filter = &"part"
	selected_inventory_entry.clear()
	for part in state.installed_parts:
		if part.socket_id == socket_id:
			selected_installed_kind = &"part"
			selected_installed_id = part.part_id
			_set_status("%s 소켓의 %s 선택 · 강화·교체·해제 가능" % [
				socket_id, part.display_name,
			])
			return
	selected_installed_kind = &""
	selected_installed_id = &""
	_set_status("%s 소켓 비어 있음 · 오른쪽 호환 파츠를 선택하세요." % socket_id)


func _refresh_inventory_candidate_detail() -> void:
	if selected_inventory_entry.is_empty():
		equipment_candidate_detail.text = "장비 카드를 선택하면 상세 정보가 표시됩니다."
		modification_candidate_detail.text = "모듈 또는 파츠 카드를 선택하세요."
		equip_selected_button.disabled = true
		install_selected_modification_button.disabled = true
		return
	var item_type: StringName = selected_inventory_entry.get(&"item_type", &"")
	var definition: Resource = selected_inventory_entry.get(&"linked_resource")
	if item_type in [&"weapon", &"armor"]:
		var compatible := bool(equipment_provider.call(
			&"can_equip_definition", selected_slot_id, definition
		))
		equipment_candidate_detail.text = "%s\n%s\n%s" % [
			selected_inventory_entry.get(&"display_name", "이름 없음"),
			selected_inventory_entry.get(&"description", "설명 없음"),
			"현재 슬롯에 장착할 수 있습니다." if compatible else "현재 슬롯 태그와 맞지 않습니다.",
		]
		equip_selected_button.disabled = read_only or not compatible
		install_selected_modification_button.disabled = true
	else:
		var compatible := _can_install_entry(_get_state(selected_slot_id), selected_inventory_entry)
		modification_candidate_detail.text = "%s\n%s\n%s" % [
			selected_inventory_entry.get(&"display_name", "이름 없음"),
			_modification_detail(definition),
			"현재 장비에 장착할 수 있습니다." if compatible else "슬롯, 중복 또는 코스트 조건을 확인하세요.",
		]
		install_selected_modification_button.disabled = read_only or not compatible
		equip_selected_button.disabled = true


func _refresh_installed_selection_detail() -> void:
	var state := _get_state(selected_slot_id)
	%UpgradeInstalledButton.disabled = true
	%UpgradeInstalledPartButton.disabled = true
	%ModuleModifyButton.disabled = true
	uninstall_selected_button.disabled = true
	if state == null or selected_installed_kind == &"" or selected_installed_id == &"":
		installed_selection_detail.text = "장착된 모듈 또는 파츠를 선택하면 강화 비용을 확인합니다."
		return
	var quote: Dictionary = {}
	if upgrade_provider != null:
		quote = upgrade_provider.call(
			&"quote_upgrade", selected_installed_kind, selected_slot_id, selected_installed_id
		)
	if selected_installed_kind == &"module":
		var module_instance := state.get_module_instance(selected_installed_id)
		if module_instance == null:
			selected_installed_kind = &""
			selected_installed_id = &""
			installed_selection_detail.text = "선택한 모듈이 더 이상 장착되어 있지 않습니다."
			return
		installed_selection_detail.text = _upgrade_detail_text(
			module_instance.definition.display_name,
			module_instance.upgrade_level,
			module_instance.definition.maximum_upgrade_level(),
			quote
		)
		%UpgradeInstalledButton.disabled = (
			read_only
			or module_instance.upgrade_level >= module_instance.definition.maximum_upgrade_level()
			or (not quote.is_empty() and not bool(quote.get(&"can_upgrade", false)))
		)
		%ModuleModifyButton.disabled = read_only or state.level < state.maximum_level()
		uninstall_selected_button.disabled = read_only
	else:
		var part := state.get_part(selected_installed_id)
		if part == null:
			selected_installed_kind = &""
			selected_installed_id = &""
			installed_selection_detail.text = "선택한 파츠가 더 이상 장착되어 있지 않습니다."
			return
		var current_level := int(state.part_upgrade_levels.get(part.part_id, 1))
		installed_selection_detail.text = _upgrade_detail_text(
			part.display_name,
			current_level,
			part.maximum_upgrade_level,
			quote
		)
		%UpgradeInstalledPartButton.disabled = (
			read_only
			or current_level >= part.maximum_upgrade_level
			or (not quote.is_empty() and not bool(quote.get(&"can_upgrade", false)))
		)
		uninstall_selected_button.disabled = read_only


func _equip_selected_candidate() -> void:
	if read_only:
		_apply_read_only_state()
		return
	if selected_inventory_entry.is_empty() or not _providers_are_ready():
		return
	var definition: Resource = selected_inventory_entry.get(&"linked_resource")
	var candidate_id: StringName = selected_inventory_entry.get(&"instance_id", &"")
	var old_state := _get_state(selected_slot_id)
	var active_slot_before: StringName = equipment_provider.call(&"get_active_weapon_slot")
	if (
		old_state != null
		and not inventory_provider.call(
			&"can_add_linked_resource", old_state.definition, candidate_id
		)
	):
		_set_status("교체 실패 · 기존 장비를 돌려놓을 가방 공간이 필요합니다.")
		return
	var candidate_entry: Dictionary = inventory_provider.call(&"take_item_entry", candidate_id)
	if candidate_entry.is_empty():
		_set_status("선택한 장비가 가방에 없습니다.")
		return
	var removed_state: EquipmentItemState = equipment_provider.call(
		&"take_equipment_state", selected_slot_id
	)
	var payload: Dictionary = candidate_entry.get(&"runtime_payload", {})
	var saved_state := payload.get(&"equipment_state") as EquipmentItemState
	var equipped := bool(
		equipment_provider.call(&"equip_state", selected_slot_id, saved_state)
		if saved_state != null
		else equipment_provider.call(
			&"equip_definition", selected_slot_id, definition, payload
		)
	)
	if not equipped:
		inventory_provider.call(
			&"add_linked_resource", definition, payload
		)
		if removed_state != null:
			equipment_provider.call(&"equip_state", selected_slot_id, removed_state)
		_set_status("선택 장비가 이 슬롯의 태그 규칙과 맞지 않습니다.")
		return
	var item_name: String = selected_inventory_entry.get(&"display_name", "장비")
	if removed_state != null:
		inventory_provider.call(&"add_linked_resource", removed_state.definition, {
			&"equipment_state": removed_state,
		})
	if selected_slot_id == active_slot_before:
		equipment_provider.call(&"set_active_weapon_slot", selected_slot_id)
	selected_inventory_entry.clear()
	_set_status("%s에 %s %s 완료" % [
		_slot_display_name(selected_slot_id),
		item_name,
		"교체" if removed_state != null else "장착",
	])


func _unequip_selected_equipment() -> void:
	if read_only:
		_apply_read_only_state()
		return
	var state := _get_state(selected_slot_id)
	if state == null:
		_set_status("해제할 장비가 없습니다.")
		return
	if not inventory_provider.call(&"can_add_linked_resource", state.definition):
		_set_status("해제 실패 · 가방 공간이 부족합니다.")
		return
	var removed: EquipmentItemState = equipment_provider.call(
		&"take_equipment_state", selected_slot_id
	)
	if removed == null or inventory_provider.call(&"add_linked_resource", removed.definition, {
		&"equipment_state": removed,
	}) == &"":
		if removed != null:
			equipment_provider.call(&"equip_state", selected_slot_id, removed)
		_set_status("장비 해제에 실패했습니다.")
		return
	selected_inventory_entry.clear()
	_set_status("%s 장비 해제 · 가방으로 이동" % _slot_display_name(selected_slot_id))


func _install_selected_modification() -> void:
	if read_only:
		_apply_read_only_state()
		return
	if selected_inventory_entry.is_empty() or not _providers_are_ready():
		return
	var item_type: StringName = selected_inventory_entry.get(&"item_type", &"")
	var definition: Resource = selected_inventory_entry.get(&"linked_resource")
	var candidate_id: StringName = selected_inventory_entry.get(&"instance_id", &"")
	var replacing := (
		(selected_installed_kind == &"module" and item_type == &"module")
		or (selected_installed_kind == &"part" and item_type == &"part")
	)
	var state := _get_state(selected_slot_id)
	var removed_preview: Resource
	if replacing and selected_installed_kind == &"module":
		var old_module := state.get_module_instance(selected_installed_id) if state != null else null
		removed_preview = old_module.definition if old_module != null else null
	elif replacing and selected_installed_kind == &"part":
		removed_preview = state.get_part(selected_installed_id) if state != null else null
	if (
		removed_preview != null
		and not inventory_provider.call(
			&"can_add_linked_resource", removed_preview, candidate_id
		)
	):
		_set_status("교체 실패 · 해제될 모듈/파츠를 돌려놓을 공간이 없습니다.")
		return
	var candidate_entry: Dictionary = inventory_provider.call(&"take_item_entry", candidate_id)
	if candidate_entry.is_empty():
		_set_status("선택한 모듈/파츠가 가방에 없습니다.")
		return
	var payload: Dictionary = candidate_entry.get(&"runtime_payload", {})
	var removed: Dictionary = {}
	var removed_target_id := selected_installed_id
	if replacing:
		removed = equipment_provider.call(
			&"uninstall_module" if item_type == &"module" else &"uninstall_part",
			selected_slot_id,
			selected_installed_id
		)
	var installed := false
	if item_type == &"module":
		installed = bool(equipment_provider.call(
			&"install_module",
			selected_slot_id,
			candidate_id,
			definition,
			int(payload.get(&"upgrade_level", 1)),
			payload
		))
	elif item_type == &"part":
		installed = bool(equipment_provider.call(
			&"install_part", selected_slot_id, definition,
			int(payload.get(&"upgrade_level", 1))
		))
	if not installed:
		inventory_provider.call(&"add_linked_resource", definition, payload)
		_restore_removed_modification(item_type, removed, removed_target_id)
		_set_status("장착 실패 · 호환 태그, 중복, 슬롯과 코스트를 확인하세요.")
		return
	var item_name: String = selected_inventory_entry.get(&"display_name", "아이템")
	if not removed.is_empty():
		var removed_payload: Dictionary = (
			removed.get(&"item_quality_payload", {}) as Dictionary
		).duplicate(true)
		removed_payload[&"upgrade_level"] = int(removed.get(&"upgrade_level", 1))
		inventory_provider.call(
			&"add_linked_resource", removed.get(&"definition"), removed_payload
		)
	selected_inventory_entry.clear()
	selected_installed_kind = &""
	selected_installed_id = &""
	_set_status("%s에 %s %s 완료" % [
		_slot_display_name(selected_slot_id), item_name,
		"교체" if not removed.is_empty() else "장착",
	])


func _uninstall_selected_modification() -> void:
	if read_only:
		_apply_read_only_state()
		return
	var state := _get_state(selected_slot_id)
	if state == null or selected_installed_kind == &"" or selected_installed_id == &"":
		_set_status("해제할 모듈 또는 파츠를 먼저 선택하세요.")
		return
	var selected_kind := selected_installed_kind
	var selected_id := selected_installed_id
	var definition: Resource
	if selected_kind == &"module":
		var module_instance := state.get_module_instance(selected_id)
		definition = module_instance.definition if module_instance != null else null
	else:
		definition = state.get_part(selected_id)
	if definition == null or not inventory_provider.call(&"can_add_linked_resource", definition):
		_set_status("해제 실패 · 가방 공간이 부족합니다.")
		return
	var removed: Dictionary = equipment_provider.call(
		&"uninstall_module" if selected_kind == &"module" else &"uninstall_part",
		selected_slot_id,
		selected_id
	)
	var removed_payload: Dictionary = (
		removed.get(&"item_quality_payload", {}) as Dictionary
	).duplicate(true)
	removed_payload[&"upgrade_level"] = int(removed.get(&"upgrade_level", 1))
	if removed.is_empty() or inventory_provider.call(
		&"add_linked_resource", removed.get(&"definition"), removed_payload
	) == &"":
		_restore_removed_modification(selected_kind, removed, selected_id)
		_set_status("모듈/파츠 해제에 실패했습니다.")
		return
	var kind_label := "모듈" if selected_kind == &"module" else "고유 파츠"
	selected_installed_kind = &""
	selected_installed_id = &""
	_set_status("%s 해제 · 가방으로 이동" % kind_label)


func _restore_removed_modification(
	kind: StringName,
	removed: Dictionary,
	target_id: StringName
) -> void:
	if removed.is_empty():
		return
	if kind == &"module":
		equipment_provider.call(
			&"install_module", selected_slot_id, target_id,
			removed.get(&"definition"), int(removed.get(&"upgrade_level", 1)),
			removed.get(&"item_quality_payload", {})
		)
	else:
		equipment_provider.call(
			&"install_part", selected_slot_id, removed.get(&"definition"),
			int(removed.get(&"upgrade_level", 1))
		)


func _level_up_selected() -> void:
	if read_only:
		_apply_read_only_state()
		return
	if equipment_provider.call(&"level_up_equipment", selected_slot_id):
		_set_status("%s 장비 레벨 상승" % _slot_display_name(selected_slot_id))
	else:
		_set_status("이미 최고 레벨입니다. 장착 모듈 태그로 개조할 수 있습니다.")


func _upgrade_selected_module() -> void:
	_upgrade_selected(&"module")


func _upgrade_selected_part() -> void:
	_upgrade_selected(&"part")


func _upgrade_selected(kind: StringName) -> void:
	if read_only:
		_apply_read_only_state()
		return
	if selected_installed_kind != kind or selected_installed_id == &"":
		_set_status("강화할 %s 카드를 먼저 선택하세요." % ("모듈" if kind == &"module" else "파츠"))
		return
	var upgraded := false
	var quote: Dictionary = {}
	if upgrade_provider != null:
		quote = upgrade_provider.call(&"quote_upgrade", kind, selected_slot_id, selected_installed_id)
		upgraded = bool(upgrade_provider.call(
			&"upgrade", kind, selected_slot_id, selected_installed_id
		))
	else:
		var method_name := &"upgrade_module" if kind == &"module" else &"upgrade_part"
		upgraded = bool(equipment_provider.call(method_name, selected_slot_id, selected_installed_id))
	if upgraded:
		if quote.is_empty():
			_set_status("%s 강화 완료" % ("모듈" if kind == &"module" else "고유 파츠"))
		else:
			_set_status("강화 완료 · 동일 아이템 %d개 · 크레딧 %d 소모" % [
				int(quote.get(&"material_quantity", 0)),
				int(quote.get(&"credit_cost", 0)),
			])
	else:
		_set_status("강화 실패 · 동일 아이템 재료와 크레딧을 확인하세요.")


func _grant_selected_module_tag() -> void:
	if read_only:
		_apply_read_only_state()
		return
	var state := _get_state(selected_slot_id)
	if state == null:
		return
	var module_instance: EquipmentModuleInstance
	if selected_installed_kind == &"module":
		module_instance = state.get_module_instance(selected_installed_id)
	elif not state.installed_modules.is_empty():
		module_instance = state.installed_modules[0]
	if module_instance != null:
		for module_tag in module_instance.definition.module_tags:
			if equipment_provider.call(&"grant_module_tag", selected_slot_id, module_tag):
				_set_status("개조 태그 [%s] 부여 · 일치 모듈 코스트 50%%" % module_tag)
				return
	_set_status("최고 레벨, 선택 모듈과 미부여 태그를 확인하세요.")


func _can_install_entry(state: EquipmentItemState, entry: Dictionary) -> bool:
	if state == null:
		return false
	var item_type: StringName = entry.get(&"item_type", &"")
	var definition: Resource = entry.get(&"linked_resource")
	if item_type == &"module" and definition is EquipmentModuleDefinition:
		if state.can_install_module(definition):
			return true
		if selected_installed_kind == &"module" and selected_installed_id != &"":
			var preview := state.duplicate(true) as EquipmentItemState
			preview.remove_module(selected_installed_id)
			return preview.can_install_module(definition)
	if item_type == &"part" and definition is EquipmentPartDefinition:
		if state.can_install_part(definition):
			return true
		if selected_installed_kind == &"part" and selected_installed_id != &"":
			var preview := state.duplicate(true) as EquipmentItemState
			preview.remove_part(selected_installed_id)
			return preview.can_install_part(definition)
	return false


func _get_state(slot_id: StringName) -> EquipmentItemState:
	if equipment_provider == null:
		return null
	return equipment_provider.call(&"get_equipment_state", slot_id) as EquipmentItemState


func _equipment_stats_text(state: EquipmentItemState) -> String:
	var snapshot := state.snapshot()
	var lines := PackedStringArray()
	lines.append("모듈 슬롯    %d / %d" % [snapshot[&"module_count"], snapshot[&"module_slot_limit"]])
	lines.append("모듈 코스트  %d / %d" % [snapshot[&"used_module_cost"], snapshot[&"module_cost_limit"]])
	if state.is_weapon():
		var weapon := state.definition as EquipmentWeaponDefinition
		var sockets := PackedStringArray()
		for socket in weapon.part_socket_ids:
			sockets.append(String(WeaponPartsBoard.SOCKET_LABELS.get(socket, socket)))
		lines.append("전용 파츠  %s" % (" · ".join(sockets) if not sockets.is_empty() else "없음"))
		lines.append("무기 태그       %s" % weapon.tags.display_text())
		if weapon.innate_skill != null:
			lines.append("고유 스킬       %s · %s" % [
				weapon.innate_skill.display_name,
				weapon.innate_skill.effect_summary(),
			])
	else:
		var armor := state.definition as EquipmentArmorDefinition
		lines.append("스탯 효과       %d개" % armor.stat_modifiers.size())
		if not armor.description.is_empty():
			lines.append("\n%s" % armor.description)
	var fixed_option_lines := PackedStringArray()
	for option in state.get_fixed_options():
		fixed_option_lines.append("%s %s%s" % [
			option.display_name,
			"+" if option.operation == EquipmentFixedOption.Operation.ADD else "×",
			"%.2f" % option.amount,
		])
	lines.append("\n고정 옵션  %s" % (
		", ".join(fixed_option_lines) if not fixed_option_lines.is_empty() else "없음"
	))
	equipment_stats.tooltip_text = "고정 옵션·고유 스킬은 내부·외부 레벨 및 모듈 배율의 영향을 받지 않습니다."
	var tags: PackedStringArray = snapshot[&"granted_module_tags"]
	lines.append("\n개조 태그  %s" % (", ".join(tags) if not tags.is_empty() else "없음"))
	return "\n".join(lines)


func _definition_meta(definition: Resource) -> String:
	if definition is EquipmentWeaponDefinition:
		return (definition as EquipmentWeaponDefinition).tags.display_text()
	if definition is EquipmentArmorDefinition:
		return "%s 방어구" % (definition as EquipmentArmorDefinition).slot_id
	return "분류 정보 없음"


func _modification_meta(definition: Resource) -> String:
	if definition is EquipmentModuleDefinition:
		var module_definition := definition as EquipmentModuleDefinition
		return "COST %d · 최대 Lv.%d" % [
			module_definition.cost_at_level(1),
			module_definition.maximum_upgrade_level(),
		]
	if definition is EquipmentPartDefinition:
		var part := definition as EquipmentPartDefinition
		return "%s · 최대 Lv.%d" % [part.socket_id, part.maximum_upgrade_level]
	return "정보 없음"


func _modification_detail(definition: Resource) -> String:
	if definition is EquipmentModuleDefinition:
		var module_definition := definition as EquipmentModuleDefinition
		return "태그 %s · 초기 코스트 %d · 강화 시 코스트 감소" % [
			", ".join(module_definition.module_tags),
			module_definition.cost_at_level(1),
		]
	if definition is EquipmentPartDefinition:
		var part := definition as EquipmentPartDefinition
		return "전용 소켓 %s · 호환 소분류 %s" % [
			part.socket_id,
			", ".join(part.compatible_minor_tags),
		]
	return "상세 정보 없음"


func _upgrade_detail_text(
	display_name: String,
	current_level: int,
	maximum_level: int,
	quote: Dictionary
) -> String:
	var base := "%s · Lv.%d/%d" % [display_name, current_level, maximum_level]
	if current_level >= maximum_level:
		return "%s\n최고 강화 단계입니다." % base
	if quote.is_empty():
		return "%s\n강화하면 다음 단계 효과가 적용됩니다." % base
	return "%s\n필요: 동일 아이템 %d개 · 크레딧 %d\n보유: 동일 아이템 %d개 · 크레딧 %d" % [
		base,
		int(quote.get(&"material_quantity", 0)),
		int(quote.get(&"credit_cost", 0)),
		int(quote.get(&"available_materials", 0)),
		int(quote.get(&"available_credits", 0)),
	]


func _make_card(
	card_text: String,
	accent: Color,
	selected: bool,
	compatible: bool,
	minimum_size: Vector2
) -> Button:
	var card := Button.new()
	card.custom_minimum_size = minimum_size
	card.text = card_text
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_theme_font_size_override(&"font_size", 13)
	card.add_theme_color_override(&"font_color", Color(0.86, 0.92, 0.94) if compatible else Color(0.45, 0.5, 0.53))
	card.add_theme_color_override(&"font_pressed_color", Color("f1f7fa"))
	card.add_theme_color_override(&"font_hover_color", Color("f1f7fa"))
	card.add_theme_stylebox_override(&"normal", _card_style(accent, selected, compatible))
	card.add_theme_stylebox_override(&"hover", _card_style(accent, true, compatible))
	card.add_theme_stylebox_override(&"pressed", _card_style(accent, true, compatible))
	return card


func _add_empty_card(parent: Control, card_text: String) -> void:
	var card := _make_card(card_text, Color(0.18, 0.24, 0.28), false, false, Vector2(110, 60))
	card.disabled = true
	parent.add_child(card)


func _card_style(accent: Color, selected: bool, compatible: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.09, 1) if compatible else Color(0.035, 0.043, 0.05, 0.9)
	style.border_width_left = 4 if selected else 2
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = accent if compatible else Color(0.16, 0.19, 0.21)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 8
	return style


func _clear_cards(parent: Control) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _refresh_filter_buttons() -> void:
	%AllModificationFilter.button_pressed = modification_filter == &"all"
	%ModuleFilter.button_pressed = modification_filter == &"module"
	%PartFilter.button_pressed = modification_filter == &"part"
	%CompatibilitySort.button_pressed = modification_sort == &"compatibility"
	%CostSort.button_pressed = modification_sort == &"cost"


func _sort_modification_entries(first: Dictionary, second: Dictionary) -> bool:
	var first_value: Array = module_ui_presenter.call(
		&"sort_value", first, bool(first.get(&"ui_compatible", false)), modification_sort
	)
	var second_value: Array = module_ui_presenter.call(
		&"sort_value", second, bool(second.get(&"ui_compatible", false)), modification_sort
	)
	for index in mini(first_value.size(), second_value.size()):
		if first_value[index] == second_value[index]:
			continue
		return first_value[index] < second_value[index]
	return false


func get_density_snapshot() -> Dictionary:
	var metadata_card_count := 0
	for child in modification_inventory_grid.get_children():
		# Presentation/localization must not change the semantic audit result.
		if child is Button and child.get_meta(&"item_type", &"") in [&"module", &"part"]:
			metadata_card_count += 1
	var parts_board_snapshot: Dictionary = weapon_parts_board.call(&"get_snapshot")
	return {
		&"window_size": size,
		&"slot_rail_width": %SlotRail.custom_minimum_size.x,
		&"slot_button_height": %MainSlotButton.custom_minimum_size.y,
		&"equipment_columns": equipment_inventory_grid.columns,
		&"modification_columns": modification_inventory_grid.columns,
		&"equipment_card_size": Vector2(160, 116),
		&"modification_card_size": Vector2(138, 92),
		&"module_effect_summary_visible": module_effect_summary.visible,
		&"module_effect_line_count": module_effect_summary.text.count("\n") + 1,
		&"module_inventory_metadata_card_count": metadata_card_count,
		&"module_sort_control_count": 2,
		&"modification_sort": modification_sort,
		&"weapon_parts_board_visible": weapon_parts_board.visible,
		&"weapon_parts_board_size": parts_board_snapshot.get(&"board_size", Vector2.ZERO),
		&"weapon_parts_socket_count": parts_board_snapshot.get(&"socket_count", 0),
		&"weapon_parts_installed_count": parts_board_snapshot.get(&"installed_socket_count", 0),
		&"weapon_parts_minor_tag": parts_board_snapshot.get(&"minor_tag", &""),
		&"active_tab": tabs.current_tab,
	}


func _slot_display_name(slot_id: StringName) -> String:
	return String(SLOT_LABELS.get(slot_id, slot_id))


func _providers_are_ready() -> bool:
	return equipment_provider != null and inventory_provider != null


func _set_status(message: String) -> void:
	status_label.text = message
	_refresh()
