class_name TrainingScenarioDefinition
extends Resource

@export var scenario_id: StringName = &""
@export var display_name := ""
@export_enum("single", "dense") var dummy_mode := "single"
@export_range(1, 32, 1) var dummy_count := 1
@export_range(1.0, 100000.0, 1.0) var dummy_health := 1000.0
@export_range(0.0, 100000.0, 1.0) var dummy_armor := 0.0
@export_range(1.0, 300.0, 1.0) var measurement_seconds := 15.0
@export var allow_free_loadout := true
@export var restore_on_exit := true
@export var source_status: StringName = &"provisional"


func configure(row: Dictionary) -> bool:
	scenario_id = StringName(row.get(&"scenario_id", &""))
	display_name = String(row.get(&"display_name", ""))
	dummy_mode = String(row.get(&"dummy_mode", ""))
	dummy_count = int(row.get(&"dummy_count", 0))
	dummy_health = float(row.get(&"dummy_health", 0.0))
	dummy_armor = float(row.get(&"dummy_armor", 0.0))
	measurement_seconds = float(row.get(&"measurement_seconds", 0.0))
	allow_free_loadout = _as_bool(row.get(&"allow_free_loadout", false))
	restore_on_exit = _as_bool(row.get(&"restore_on_exit", true))
	source_status = StringName(row.get(&"source_status", &"provisional"))
	return is_valid()


func is_valid() -> bool:
	return (
		scenario_id != &""
		and not display_name.is_empty()
		and dummy_mode in ["single", "dense"]
		and dummy_count > 0
		and dummy_health > 0.0
		and dummy_armor >= 0.0
		and measurement_seconds > 0.0
		and (dummy_mode != "single" or dummy_count == 1)
	)


func get_snapshot() -> Dictionary:
	return {
		&"scenario_id": scenario_id,
		&"display_name": display_name,
		&"dummy_mode": StringName(dummy_mode),
		&"dummy_count": dummy_count,
		&"dummy_health": dummy_health,
		&"dummy_armor": dummy_armor,
		&"measurement_seconds": measurement_seconds,
		&"allow_free_loadout": allow_free_loadout,
		&"restore_on_exit": restore_on_exit,
		&"source_status": source_status,
	}


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	return String(value).strip_edges().to_lower() in ["true", "1", "yes", "y"]
