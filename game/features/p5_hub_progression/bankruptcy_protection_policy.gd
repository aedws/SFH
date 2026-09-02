class_name BankruptcyProtectionPolicy
extends RefCounted

var presets: Array[Dictionary] = []


func configure(rows: Array[Dictionary]) -> bool:
	presets = rows.duplicate(true)
	return not presets.is_empty()


func get_recommended_preset(credits: int) -> Dictionary:
	for preset in presets:
		if credits <= int(preset.get(&"required_max_credits", 0)) and int(preset.get(&"entry_cost", 1)) == 0:
			return preset.duplicate(true)
	return {}


func get_snapshot(credits: int) -> Dictionary:
	var preset := get_recommended_preset(credits)
	return {&"available": not preset.is_empty(), &"preset": preset,
		&"repeatable_free_sortie": not preset.is_empty()}
