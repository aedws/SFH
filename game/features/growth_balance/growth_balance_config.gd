class_name GrowthBalanceConfig
extends Resource

enum SourceMode {
	LOCKED_CSV,
	LIVE_GOOGLE_SHEET,
}

@export var source_mode: SourceMode = SourceMode.LOCKED_CSV
@export_file("*.csv") var locked_run_buff_csv_path := (
	"res://game/features/growth_balance/data/run_buff_balance.csv"
)
@export_file("*.csv") var locked_upgrade_csv_path := (
	"res://game/features/growth_balance/data/upgrade_balance.csv"
)
@export_multiline var live_run_buff_csv_url: String = ""
@export_multiline var live_upgrade_csv_url: String = ""
@export_range(1.0, 60.0, 0.5) var live_refresh_seconds: float = 3.0
@export var fallback_to_locked_csv: bool = true


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if locked_run_buff_csv_path.is_empty() or not FileAccess.file_exists(locked_run_buff_csv_path):
		errors.append("확정 내부 성장 CSV 경로가 유효하지 않습니다.")
	if locked_upgrade_csv_path.is_empty() or not FileAccess.file_exists(locked_upgrade_csv_path):
		errors.append("확정 장비 강화 CSV 경로가 유효하지 않습니다.")
	if source_mode == SourceMode.LIVE_GOOGLE_SHEET:
		if live_run_buff_csv_url.is_empty() or live_upgrade_csv_url.is_empty():
			errors.append("실시간 성장 테스트에는 RunBuff와 Upgrade 공개 CSV URL이 필요합니다.")
	if live_refresh_seconds < 1.0:
		errors.append("실시간 갱신 간격은 1초 이상이어야 합니다.")
	return errors
