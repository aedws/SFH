class_name EquipmentWorkbench
extends PanelContainer

@onready var tabs: TabContainer = %Tabs
@onready var weapon_slot_option: OptionButton = %WeaponSlotOption
@onready var armor_slot_option: OptionButton = %ArmorSlotOption
@onready var weapon_summary: Label = %WeaponSummary
@onready var armor_summary: Label = %ArmorSummary
@onready var status_label: Label = %WorkbenchStatus

var equipment_provider: Node
var inventory_provider: Node
var upgrade_provider: Node
var paused_before_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	visible = false
	weapon_slot_option.clear()
	weapon_slot_option.add_item("메인 무기 · 소총")
	weapon_slot_option.add_item("보조 무기 · 권총")
	weapon_slot_option.select(0)
	armor_slot_option.clear()
	armor_slot_option.add_item("신체 방어구")
	armor_slot_option.add_item("신발 방어구")
	armor_slot_option.select(0)
	weapon_slot_option.item_selected.connect(_on_selection_changed)
	armor_slot_option.item_selected.connect(_on_selection_changed)
	%WeaponEquipButton.pressed.connect(_equip_candidate.bind(&"weapon"))
	%ArmorEquipButton.pressed.connect(_equip_candidate.bind(&"armor"))
	%InstallPartButton.pressed.connect(_install_part)
	%UpgradePartButton.pressed.connect(_upgrade_part)
	%WeaponModuleButton.pressed.connect(_install_module.bind(true))
	%ArmorModuleButton.pressed.connect(_install_module.bind(false))
	%WeaponUpgradeButton.pressed.connect(_upgrade_module.bind(true))
	%ArmorUpgradeButton.pressed.connect(_upgrade_module.bind(false))
	%WeaponLevelButton.pressed.connect(_level_up.bind(true))
	%ArmorLevelButton.pressed.connect(_level_up.bind(false))
	%WeaponModifyButton.pressed.connect(_grant_matching_tag.bind(true))
	%ArmorModifyButton.pressed.connect(_grant_matching_tag.bind(false))


func configure(
	new_equipment_provider: Node,
	new_inventory_provider: Node,
	new_upgrade_provider: Node = null
) -> bool:
	if new_equipment_provider == null or new_inventory_provider == null:
		return false
	equipment_provider = new_equipment_provider
	inventory_provider = new_inventory_provider
	upgrade_provider = new_upgrade_provider
	if equipment_provider.has_signal(&"customization_changed"):
		equipment_provider.connect(&"customization_changed", Callable(self, &"_on_data_changed"))
	if inventory_provider.has_signal(&"inventory_changed"):
		inventory_provider.connect(&"inventory_changed", Callable(self, &"_on_data_changed"))
	_refresh()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_equipment") and not event.is_echo():
		toggle_panel()
		get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()


func open_panel() -> void:
	for panel in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if panel != self and panel.has_method(&"close_panel"):
			panel.call(&"close_panel")
	paused_before_open = get_tree().paused
	visible = true
	get_tree().paused = true
	_refresh()


func close_panel() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = paused_before_open


func show_weapon_tab() -> void:
	tabs.current_tab = 0
	open_panel()


func show_armor_tab() -> void:
	tabs.current_tab = 1
	open_panel()


func _selected_slot(for_weapon: bool) -> StringName:
	if for_weapon:
		return &"main" if weapon_slot_option.selected == 0 else &"secondary"
	return &"body" if armor_slot_option.selected == 0 else &"feet"


func _equip_candidate(item_type: StringName) -> void:
	if not _providers_are_ready():
		return
	var slot_id := _selected_slot(item_type == &"weapon")
	for entry in inventory_provider.call(&"get_items_by_type", item_type):
		var definition: Resource = entry[&"linked_resource"]
		if equipment_provider.call(&"can_equip_definition", slot_id, definition):
			if equipment_provider.call(&"equip_definition", slot_id, definition):
				inventory_provider.call(&"take_item", entry[&"instance_id"])
				_set_status("%s 슬롯에 %s 장착" % [slot_id, entry[&"display_name"]])
				return
	_set_status("선택 슬롯의 태그 규칙에 맞는 예비 장비가 없습니다.")


func _install_part() -> void:
	if not _providers_are_ready():
		return
	var slot_id := _selected_slot(true)
	for entry in inventory_provider.call(&"get_items_by_type", &"part"):
		var part := entry[&"linked_resource"] as EquipmentPartDefinition
		if equipment_provider.call(&"install_part", slot_id, part):
			inventory_provider.call(&"take_item", entry[&"instance_id"])
			_set_status("%s에 전용 파츠 %s 장착" % [slot_id, entry[&"display_name"]])
			return
	_set_status("이 무기 소분류·소켓에 맞는 고유 파츠가 없습니다.")


func _install_module(for_weapon: bool) -> void:
	if not _providers_are_ready():
		return
	var slot_id := _selected_slot(for_weapon)
	for entry in inventory_provider.call(&"get_items_by_type", &"module"):
		var module_definition := entry[&"linked_resource"] as EquipmentModuleDefinition
		if equipment_provider.call(
			&"install_module", slot_id, entry[&"instance_id"], module_definition
		):
			inventory_provider.call(&"take_item", entry[&"instance_id"])
			_set_status("%s에 %s 장착" % [slot_id, entry[&"display_name"]])
			return
	_set_status("모듈 슬롯 또는 코스트 한도를 확인하세요.")


func _upgrade_module(for_weapon: bool) -> void:
	if not _providers_are_ready():
		return
	var slot_id := _selected_slot(for_weapon)
	var state := equipment_provider.call(&"get_equipment_state", slot_id) as EquipmentItemState
	if state != null:
		for module_instance in state.installed_modules:
			var upgraded := false
			if upgrade_provider != null:
				var quote: Dictionary = upgrade_provider.call(
					&"quote_upgrade", &"module", slot_id, module_instance.instance_id
				)
				if quote.is_empty():
					continue
				upgraded = bool(upgrade_provider.call(
					&"upgrade", &"module", slot_id, module_instance.instance_id
				))
				if upgraded:
					_set_status("모듈 강화 완료 · 동일 아이템 %d개 · 크레딧 %d 소모" % [
						int(quote[&"material_quantity"]),
						int(quote[&"credit_cost"]),
					])
			else:
				upgraded = bool(equipment_provider.call(
					&"upgrade_module", slot_id, module_instance.instance_id
				))
				if upgraded:
					_set_status("모듈 강화 완료 · 장착 코스트 감소")
			if upgraded:
				return
	_set_status("강화 가능한 모듈, 동일 아이템 재료와 크레딧을 확인하세요.")


func _upgrade_part() -> void:
	if not _providers_are_ready():
		return
	var slot_id := _selected_slot(true)
	var state := equipment_provider.call(&"get_equipment_state", slot_id) as EquipmentItemState
	if state != null:
		for part in state.installed_parts:
			var upgraded := false
			if upgrade_provider != null:
				var quote: Dictionary = upgrade_provider.call(
					&"quote_upgrade", &"part", slot_id, part.part_id
				)
				if quote.is_empty():
					continue
				upgraded = bool(upgrade_provider.call(
					&"upgrade", &"part", slot_id, part.part_id
				))
				if upgraded:
					_set_status("고유 파츠 강화 완료 · 동일 아이템 %d개 · 크레딧 %d 소모" % [
						int(quote[&"material_quantity"]),
						int(quote[&"credit_cost"]),
					])
			else:
				upgraded = bool(equipment_provider.call(&"upgrade_part", slot_id, part.part_id))
				if upgraded:
					_set_status("고유 파츠 강화 완료")
			if upgraded:
				return
	_set_status("강화 가능한 고유 파츠, 동일 아이템 재료와 크레딧을 확인하세요.")


func _level_up(for_weapon: bool) -> void:
	if not _providers_are_ready():
		return
	var slot_id := _selected_slot(for_weapon)
	if equipment_provider.call(&"level_up_equipment", slot_id):
		_set_status("%s 장비 레벨 상승" % slot_id)
	else:
		_set_status("이미 최고 레벨입니다. 개조 태그를 부여할 수 있습니다.")


func _grant_matching_tag(for_weapon: bool) -> void:
	if not _providers_are_ready():
		return
	var slot_id := _selected_slot(for_weapon)
	var state := equipment_provider.call(&"get_equipment_state", slot_id) as EquipmentItemState
	if state != null:
		for module_instance in state.installed_modules:
			for module_tag in module_instance.definition.module_tags:
				if equipment_provider.call(&"grant_module_tag", slot_id, module_tag):
					_set_status("개조 태그 [%s] 부여 · 일치 모듈 코스트 50%%" % module_tag)
					return
	_set_status("최고 레벨과 장착 모듈을 확인하세요.")


func _on_selection_changed(_index: int) -> void:
	_refresh()


func _on_data_changed(_snapshot: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	if not _providers_are_ready():
		return
	weapon_summary.text = _state_text(_selected_slot(true))
	armor_summary.text = _state_text(_selected_slot(false))


func _state_text(slot_id: StringName) -> String:
	var state := equipment_provider.call(&"get_equipment_state", slot_id) as EquipmentItemState
	if state == null:
		return "장착 장비 없음"
	var snapshot := state.snapshot()
	var parts := ", ".join(snapshot[&"parts"])
	var modules := "\n  · ".join(snapshot[&"modules"])
	var tags := ", ".join(snapshot[&"granted_module_tags"])
	return "%s · 장비 Lv.%d/%d\n파츠: %s\n모듈 %d/%d · 코스트 %d/%d\n  · %s\n개조 태그: %s" % [
		snapshot[&"display_name"],
		snapshot[&"level"],
		snapshot[&"maximum_level"],
		parts if not parts.is_empty() else "없음",
		snapshot[&"module_count"],
		snapshot[&"module_slot_limit"],
		snapshot[&"used_module_cost"],
		snapshot[&"module_cost_limit"],
		modules if not modules.is_empty() else "없음",
		tags if not tags.is_empty() else "없음",
	]


func _providers_are_ready() -> bool:
	return equipment_provider != null and inventory_provider != null


func _set_status(message: String) -> void:
	status_label.text = message
	_refresh()
