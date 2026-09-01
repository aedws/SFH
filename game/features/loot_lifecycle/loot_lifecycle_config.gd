class_name LootLifecycleConfig
extends Resource

enum SourceMode { LOCKED_CSV, LIVE_GOOGLE_SHEET }

@export var source_mode: SourceMode = SourceMode.LOCKED_CSV
@export_file("*.csv") var locked_csv_path := "res://game/features/loot_lifecycle/data/item_lifecycle.csv"
@export var locked_csv_payload: Resource
@export_multiline var live_csv_url := "https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=Item"
@export_range(1.0, 60.0, 0.5) var live_refresh_seconds := 3.0
@export var fallback_to_locked_csv := true


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if locked_csv_path.is_empty():
		errors.append("확정 Item CSV 경로가 비어 있습니다.")
	if (
		locked_csv_payload == null
		or not locked_csv_payload.has_method(&"is_valid_for")
		or not locked_csv_payload.call(&"is_valid_for", locked_csv_path)
	):
		errors.append("확정 Item CSV의 Web 내장 데이터가 유효하지 않습니다.")
	if source_mode == SourceMode.LIVE_GOOGLE_SHEET and live_csv_url.is_empty():
		errors.append("실시간 테스트 모드에는 Item Sheet 공개 CSV URL이 필요합니다.")
	if live_refresh_seconds < 1.0:
		errors.append("실시간 갱신 간격은 1초 이상이어야 합니다.")
	return errors
