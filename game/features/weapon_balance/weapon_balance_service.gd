class_name WeaponBalanceService
extends Node

signal balance_updated(balance_by_weapon: Dictionary, source_label: String)
signal balance_error(message: String)

@onready var http_request: HTTPRequest = $HTTPRequest

var config: WeaponBalanceConfig
var balance_by_weapon: Dictionary = {}
var current_source_label: String = ""
var refresh_remaining: float = 0.0
var request_in_flight: bool = false


func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)


func configure(new_config: WeaponBalanceConfig) -> bool:
	if new_config == null:
		return false
	config = new_config.duplicate(true) as WeaponBalanceConfig
	var validation_errors := config.validation_errors()
	if not validation_errors.is_empty():
		balance_error.emit(" / ".join(validation_errors))
		return false
	var locked_loaded := _load_locked_csv()
	if config.source_mode == WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET:
		if config.live_csv_url.is_empty():
			balance_error.emit("Google Sheets 공개 CSV URL이 비어 있어 확정 CSV를 사용합니다.")
			return locked_loaded
		request_live_balance()
	return locked_loaded


func _process(delta: float) -> void:
	if config == null or config.source_mode != WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET:
		return
	refresh_remaining -= delta
	if refresh_remaining <= 0.0 and not request_in_flight:
		request_live_balance()


func request_live_balance() -> bool:
	if config == null or config.live_csv_url.is_empty() or request_in_flight:
		return false
	var separator := "&" if "?" in config.live_csv_url else "?"
	var cache_busted_url := "%s%ssfh_cache=%d" % [
		config.live_csv_url,
		separator,
		int(Time.get_unix_time_from_system()),
	]
	request_in_flight = http_request.request(cache_busted_url) == OK
	refresh_remaining = config.live_refresh_seconds
	return request_in_flight


func load_csv_text(csv_text: String, source_label: String) -> bool:
	var parsed := WeaponBalanceTable.parse(csv_text)
	var errors: PackedStringArray = parsed[&"errors"]
	if not errors.is_empty():
		balance_error.emit(" / ".join(errors))
		return false
	var parsed_data: Dictionary = parsed[&"data"]
	if parsed_data.is_empty():
		balance_error.emit("유효한 무기 밸런스 행이 없습니다.")
		return false
	balance_by_weapon = parsed_data
	current_source_label = source_label
	balance_updated.emit(get_snapshot(), current_source_label)
	return true


func get_weapon_balance(weapon_id: StringName) -> Dictionary:
	return balance_by_weapon.get(weapon_id, {}).duplicate(true)


func get_snapshot() -> Dictionary:
	return balance_by_weapon.duplicate(true)


func _load_locked_csv() -> bool:
	if config == null or not FileAccess.file_exists(config.locked_csv_path):
		balance_error.emit("확정 무기 밸런스 CSV를 찾을 수 없습니다.")
		return false
	var file := FileAccess.open(config.locked_csv_path, FileAccess.READ)
	if file == null:
		return false
	return load_csv_text(file.get_as_text(), "확정 CSV")


func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	request_in_flight = false
	if response_code < 200 or response_code >= 300:
		balance_error.emit("Google Sheets CSV 요청 실패: HTTP %d" % response_code)
		if balance_by_weapon.is_empty() and config.fallback_to_locked_csv:
			_load_locked_csv()
		return
	if not load_csv_text(body.get_string_from_utf8(), "Google Sheets 실시간"):
		if balance_by_weapon.is_empty() and config.fallback_to_locked_csv:
			_load_locked_csv()
