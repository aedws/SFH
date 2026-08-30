class_name WeaponBalanceConfig
extends Resource

enum SourceMode {
	LOCKED_CSV,
	LIVE_GOOGLE_SHEET,
}

@export var source_mode: SourceMode = SourceMode.LOCKED_CSV
@export_file("*.csv") var locked_csv_path := (
	"res://game/features/weapon_balance/data/weapon_balance.csv"
)
@export_multiline var live_csv_url: String = ""
@export_range(1.0, 60.0, 0.5) var live_refresh_seconds: float = 3.0
@export var fallback_to_locked_csv: bool = true


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if locked_csv_path.is_empty():
		errors.append("확정 무기 밸런스 CSV 경로가 비어 있습니다.")
	if source_mode == SourceMode.LIVE_GOOGLE_SHEET and live_csv_url.is_empty():
		errors.append("실시간 테스트 모드에는 Google Sheets 공개 CSV URL이 필요합니다.")
	if live_refresh_seconds < 1.0:
		errors.append("실시간 갱신 간격은 1초 이상이어야 합니다.")
	return errors
