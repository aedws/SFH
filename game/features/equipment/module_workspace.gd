class_name ModuleWorkspace
extends VBoxContainer
## Presentation and input intents only. InventoryEditSession owns every transaction.
signal target_changed(target: StringName)
signal advanced_requested
const CARD = preload("res://game/features/equipment/module_chip_card.gd")
const PRESENTER = preload("res://game/features/equipment/equipment_module_ui_presenter.gd")
var session: Node
var target := &"main"
var selected_socket := 0
var selected_item := &""
var targets: OptionButton
var body: BoxContainer
var left: VBoxContainer
var center: VBoxContainer
var right: VBoxContainer
var overview: Label
var effects: Label
var capacity: Label
var bar: ProgressBar
var installed: GridContainer
var owned: GridContainer
var search: LineEdit
var sort: OptionButton
var compatible_only: CheckBox
var detail: Label
var socket_tags: OptionButton
var assign: Button
var install: Button
var remove: Button
var presenter = PRESENTER.new()

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	targets = OptionButton.new()
	targets.custom_minimum_size.y = 42
	targets.item_selected.connect(func(index):
		target = targets.get_item_metadata(index)
		selected_socket = 0
		selected_item = &""
		refresh()
		target_changed.emit(target))
	add_child(targets)
	body = BoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	add_child(body)
	left = _column(body, 190)
	overview = _label(left, "", 19)
	effects = _label(left, "", 13)
	center = _column(body, 0)
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	_label(center, "장착 모듈  /  슬롯 선택", 16)
	installed = GridContainer.new()
	center.add_child(installed)
	var filters := HFlowContainer.new()
	center.add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = "모듈 이름·태그 검색"
	search.custom_minimum_size = Vector2(180, 38)
	search.text_changed.connect(func(_value): _refresh_owned())
	filters.add_child(search)
	sort = OptionButton.new()
	sort.add_item("비용 낮은 순")
	sort.add_item("이름 순")
	sort.item_selected.connect(func(_index): _refresh_owned())
	filters.add_child(sort)
	compatible_only = CheckBox.new()
	compatible_only.text = "장착 가능만"
	compatible_only.toggled.connect(func(_value): _refresh_owned())
	filters.add_child(compatible_only)
	_label(center, "보유 모듈  /  1개 = 가방 1칸", 14)
	owned = GridContainer.new()
	center.add_child(owned)
	right = _column(body, 205)
	_label(right, "모듈 추가 설정", 16)
	capacity = _label(right, "", 16)
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 10
	bar.show_percentage = false
	right.add_child(bar)
	detail = _label(right, "", 13)
	install = _button(right, "선택 모듈 장착", func():
		if selected_item != &"": session.install_module_in_socket(selected_item, target, selected_socket))
	remove = _button(right, "선택 슬롯 해제", func():
		var state = _state()
		var item = state.module_at_socket(selected_socket) if state != null else null
		if item != null: session.remove_modification(target, &"module", item.instance_id))
	_label(right, "소켓 타입 부여 · 최대 레벨 필요", 13)
	socket_tags = OptionButton.new()
	socket_tags.custom_minimum_size.y = 40
	socket_tags.item_selected.connect(func(_index): _refresh_detail())
	right.add_child(socket_tags)
	assign = _button(right, "선택 슬롯에 소켓 부여", func():
		if socket_tags.selected >= 0: session.assign_module_socket(target, selected_socket, socket_tags.get_item_metadata(socket_tags.selected)))
	_button(right, "장비 레벨 · 모듈 강화 작업대", func(): advanced_requested.emit())
	var rules := Label.new()
	rules.text = "타입 일치: 비용 50% (올림)\n불일치: 기본 비용 유지\n레벨 초기화·촉매 소모 없음\n변경은 이탈 시 저장 확인"
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ui = preload("res://game/features/presentation_theme/game_ui.gd")
	ui.fold(right, "소켓 개조 규칙", rules)
	ui.action(install, "skill", true)
	ui.action(assign, "craft")
	resized.connect(_layout)

func configure(editor: Node, initial_target: StringName = &"") -> void:
	session = editor
	if initial_target != &"": target = initial_target
	refresh()

func _state():
	return session.equipment.get_equipment_state(target) if session != null and session.equipment != null else null

func refresh() -> void:
	if not is_node_ready() or session == null or session.equipment == null: return
	targets.clear()
	for descriptor in session.equipment.get_module_target_descriptors():
		var id: StringName = descriptor[&"slot_id"]
		var state = session.equipment.get_equipment_state(id)
		var category: String = {"weapon":"무기", "armor":"방어구", "character":"캐릭터"}.get(descriptor[&"kind"], descriptor[&"kind"])
		targets.add_item("%s  /  %s" % [category, state.display_name() if state != null else "미장착"])
		targets.set_item_metadata(targets.item_count - 1, id)
		if id == target: targets.select(targets.item_count - 1)
	var state = _state()
	_clear(installed)
	socket_tags.clear()
	if state == null:
		overview.text = "장비를 먼저 장착하세요."
		effects.text = ""
		capacity.text = "코스트 0 / 0"
		bar.value = 0
		install.disabled = true
		remove.disabled = true
		assign.disabled = true
		_clear(owned)
		return
	selected_socket = clampi(selected_socket, 0, maxi(0, state.module_slot_limit() - 1))
	overview.text = "%s\n\nLv.%d / %d\n%s" % [state.display_name(), state.level, state.maximum_level(), "소켓 개조 가능" if state.level >= state.maximum_level() else "최대 레벨에서 소켓 해금"]
	effects.text = presenter.applied_effects_text(state)
	capacity.text = "사용 코스트  %d / %d\n장착  %d / %d" % [state.used_module_cost(), state.module_cost_limit(), state.installed_modules.size(), state.module_slot_limit()]
	bar.max_value = maxi(1, state.module_cost_limit())
	bar.value = state.used_module_cost()
	var tags: Array[StringName] = []
	for index in state.module_slot_limit():
		var instance = state.module_at_socket(index)
		var socket: StringName = state.module_socket_tags.get(index, &"")
		var card = CARD.new()
		card.toggle_mode = true
		card.set_pressed_no_signal(index == selected_socket)
		card.empty = instance == null
		card.caption = instance.definition.display_name if instance != null else "빈 슬롯 %d" % (index + 1)
		if instance != null and not instance.definition.module_tags.is_empty(): card.glyph = instance.definition.module_tags[0]
		card.cost = "C %d  /  Lv.%d" % [state.effective_module_cost(instance), instance.upgrade_level] if instance != null else "+"
		card.detail = "소켓: %s" % (PRESENTER.tag_label(socket) if socket != &"" else "미지정")
		card.pressed.connect(func(): selected_socket = index; refresh())
		installed.add_child(card)
		if instance != null:
			for tag in instance.definition.module_tags:
				if tag not in tags: tags.append(tag)
	for entry in session.inventory.get_snapshot()[&"items"]:
		if entry.get(&"linked_resource") is EquipmentModuleDefinition:
			for tag in entry[&"linked_resource"].module_tags:
				if tag not in tags: tags.append(tag)
	for tag in tags:
		socket_tags.add_item(PRESENTER.tag_label(tag))
		socket_tags.set_item_metadata(socket_tags.item_count - 1, tag)
	assign.disabled = state.level < state.maximum_level() or tags.is_empty()
	_refresh_owned()
	_layout()

func _refresh_owned() -> void:
	_clear(owned)
	var state = _state()
	if state == null: return
	var entries: Array = []
	for entry in session.inventory.get_snapshot()[&"items"]:
		var definition: Resource = entry.get(&"linked_resource")
		if not definition is EquipmentModuleDefinition: continue
		if not search.text.is_empty() and not (definition.display_name + str(definition.module_tags) + PRESENTER.tags_text(definition.module_tags)).to_lower().contains(search.text.to_lower()): continue
		var level := int(entry.get(&"runtime_payload", {}).get(&"upgrade_level", 1))
		var compatible: bool = state.can_install_module(definition, level, selected_socket)
		if compatible_only.button_pressed and not compatible: continue
		var candidate := EquipmentModuleInstance.new()
		candidate.configure(entry[&"instance_id"], definition)
		candidate.upgrade_level = level
		candidate.socket_index = selected_socket
		entries.append({&"entry": entry, &"level": level, &"compatible": compatible, &"cost": state.effective_module_cost(candidate), &"base": candidate.base_cost(state.upgrade_balance_provider)})
	entries.sort_custom(func(a, b): return String(a.entry.display_name) < String(b.entry.display_name) if sort.selected == 1 else int(a.cost) < int(b.cost))
	for data in entries:
		var entry: Dictionary = data.entry
		var card = CARD.new()
		card.toggle_mode = true
		card.set_pressed_no_signal(selected_item == entry[&"instance_id"])
		card.caption = entry[&"display_name"]
		if not entry[&"linked_resource"].module_tags.is_empty(): card.glyph = entry[&"linked_resource"].module_tags[0]
		card.cost = "C %d  /  Lv.%d" % [data.cost, data.level]
		if data.cost != data.base: card.cost = "C %d → %d / Lv.%d" % [data.base, data.cost, data.level]
		card.detail = PRESENTER.tags_text(entry[&"linked_resource"].module_tags)
		card.tint = Color("02e5e1") if data.compatible else Color("718187")
		card.pressed.connect(func(): selected_item = entry[&"instance_id"]; _refresh_owned())
		owned.add_child(card)
	if entries.is_empty(): _label(owned, "조건에 맞는 보유 모듈 없음", 13)
	_refresh_detail()

func _refresh_detail() -> void:
	var state = _state()
	if state == null: return
	var entry: Dictionary = session.get_item_entry(selected_item)
	var instance = state.module_at_socket(selected_socket)
	remove.disabled = instance == null
	install.disabled = entry.is_empty() or not state.can_install_module(entry.get(&"linked_resource"), int(entry.get(&"runtime_payload", {}).get(&"upgrade_level", 1)), selected_socket)
	detail.text = "선택 슬롯 %d\n%s" % [selected_socket + 1, instance.definition.display_name if instance != null else "빈 슬롯 · 보유 모듈을 선택하세요."]
	if not entry.is_empty(): detail.text += "\n선택: " + String(entry[&"display_name"])
	if instance != null and socket_tags.selected >= 0:
		var tag: StringName = socket_tags.get_item_metadata(socket_tags.selected)
		detail.text += "\n소켓 부여 시: %d → %d C" % [state.effective_module_cost(instance), state.socket_policy.cost(instance.base_cost(state.upgrade_balance_provider), tag, instance.definition.module_tags)]

func _layout() -> void:
	if body == null: return
	var narrow := size.x < 900
	body.vertical = narrow
	left.custom_minimum_size.x = 0 if narrow else 190
	right.custom_minimum_size.x = 0 if narrow else 205
	var available := size.x if narrow else maxf(104, size.x - 425)
	installed.columns = clampi(int(available / 112), 1, 5)
	owned.columns = installed.columns

func _column(parent: Node, width: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = width
	box.add_theme_constant_override("separation", 10)
	parent.add_child(box)
	return box

func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 42
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
