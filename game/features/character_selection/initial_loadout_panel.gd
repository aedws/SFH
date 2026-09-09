class_name InitialLoadoutPanel
extends VBoxContainer
## Presentation only. Carries IDs; application revalidates against the live providers.
signal confirmed(selection: Dictionary)
var characters: Array = []
var weapons: Array[Resource] = []
var character_choice: OptionButton
var weapon_choice: OptionButton
var passive: Label
var confirm_button: Button
var keep_equipment := false

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "첫 출격 준비 · 요원과 기본 무장"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 20)
	add_child(title)
	var config: Resource = load("res://game/features/character_selection/configs/default_character_selection.tres")
	var text: String = config.locked_csv_payload.call(&"get_csv_text")
	characters = CharacterTable.parse(text).definitions
	character_choice = OptionButton.new()
	character_choice.fit_to_longest_item = false
	character_choice.custom_minimum_size.y = 48
	for entry in characters: character_choice.add_item(entry.display_name)
	add_child(character_choice)
	passive = Label.new()
	passive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive.custom_minimum_size.y = 72
	add_child(passive)
	character_choice.item_selected.connect(func(_index): _refresh_passive())
	weapon_choice = OptionButton.new()
	weapon_choice.fit_to_longest_item = false
	weapon_choice.custom_minimum_size.y = 48
	# Existing desktop equipment always wins; initial choices do not mint replacement gear.
	keep_equipment = not OS.has_feature("web") and FileAccess.file_exists("user://sfh_desktop_progress.json")
	if keep_equipment:
		weapon_choice.add_item("저장된 장비 유지")
		weapon_choice.disabled = true
	else:
		var equipment_loadout: Resource = load("res://game/features/equipment/loadouts/default_loadout.tres")
		var main_rule: Resource
		for rule in equipment_loadout.slot_rules:
			if rule.slot_id == &"main": main_rule = rule
		for file in DirAccess.get_files_at("res://game/features/equipment/definitions/weapons"):
			if not file.ends_with(".tres"): continue
			var weapon: Resource = load("res://game/features/equipment/definitions/weapons/" + file)
			if weapon != null and weapon.is_valid() and main_rule != null and main_rule.accepts(weapon):
				weapons.append(weapon)
				weapon_choice.add_item(weapon.display_name)
	add_child(weapon_choice)
	var help := Label.new()
	help.text = "패시브는 요원 고정입니다. 로비에서 장비·스킬을 준비한 뒤 작전 게이트로 이동하세요."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)
	confirm_button = Button.new()
	confirm_button.text = "선택 확정 · 로비 진입"
	confirm_button.custom_minimum_size.y = 52
	confirm_button.disabled = characters.is_empty() or (not keep_equipment and weapons.is_empty())
	confirm_button.pressed.connect(func():
		confirmed.emit({&"character_id": characters[character_choice.selected].character_id,
			&"weapon_path": "" if keep_equipment else weapons[weapon_choice.selected].resource_path}))
	add_child(confirm_button)
	_refresh_passive()

func _refresh_passive() -> void:
	if characters.is_empty(): return
	var entry: Resource = characters[character_choice.selected]
	passive.text = "%s · 고정 패시브\n%s\n작전 추가 비용 %d C" % [entry.passive_name, entry.passive_description, entry.entry_cost]

static func apply_selection(selection: Dictionary, character_service: Node, equipment: Node) -> bool:
	if not is_instance_valid(character_service) or not is_instance_valid(equipment): return false
	var path := String(selection.get(&"weapon_path", ""))
	var definition: Resource
	if not path.is_empty():
		if not path.begins_with("res://game/features/equipment/definitions/weapons/") or not ResourceLoader.exists(path): return false
		definition = load(path)
		if not equipment.call(&"can_equip_definition", &"main", definition): return false
	var previous: Dictionary = character_service.call(&"get_snapshot")
	if not character_service.call(&"select_character", StringName(selection.get(&"character_id", &""))): return false
	if definition != null and not equipment.call(&"equip_definition", &"main", definition):
		character_service.call(&"select_character", previous.character_id)
		return false
	return true
