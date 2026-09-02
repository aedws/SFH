class_name LoadoutInvestmentConfig
extends Resource

enum SourceMode { LOCKED_CSV, LIVE_GOOGLE_SHEET }

@export var source_mode: SourceMode = SourceMode.LOCKED_CSV
@export_file("*.csv") var weapon_csv_path := "res://game/features/loadout_investment/data/weapon_investment.csv"
@export_file("*.csv") var skill_csv_path := "res://game/features/loadout_investment/data/skill_investment.csv"
@export var weapon_csv_payload: Resource
@export var skill_csv_payload: Resource
@export_multiline var live_weapon_csv_url := "https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=Weapon"
@export_multiline var live_skill_csv_url := "https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=Skill"
@export_range(1.0, 60.0, 0.5) var live_refresh_seconds := 3.0


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for contract in [
		[weapon_csv_path, weapon_csv_payload, "Weapon"],
		[skill_csv_path, skill_csv_payload, "Skill"],
	]:
		if String(contract[0]).is_empty():
			errors.append("%s 확정 CSV 경로가 비어 있습니다." % contract[2])
		if contract[1] == null or not contract[1].has_method(&"is_valid_for") or not contract[1].call(&"is_valid_for", contract[0]):
			errors.append("%s Web 내장 CSV 미러가 유효하지 않습니다." % contract[2])
	if source_mode == SourceMode.LIVE_GOOGLE_SHEET and (live_weapon_csv_url.is_empty() or live_skill_csv_url.is_empty()):
		errors.append("실시간 모드에는 Weapon·Skill CSV URL이 모두 필요합니다.")
	return errors
