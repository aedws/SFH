class_name SeasonRewardCatalog
extends Node
signal changed
const TABLE := preload("res://game/features/p5_hub_progression/p5_catalog_table.gd")
var rows: Array[Dictionary] = []
var request: HTTPRequest
var live_url := ""
var live_enabled := false
var remaining := 0.0
var source_label := "확정 CSV"
var last_error := ""
var locked_path := ""
var locked_payload: Resource


func configure(path: String, payload: Resource, url: String) -> bool:
	live_url = url
	locked_path = path
	locked_payload = payload
	request = HTTPRequest.new()
	request.timeout = 15
	add_child(request)
	request.request_completed.connect(func(_result, code, _headers, body):
		if code >= 200 and code < 300:
			load_csv_text(body.get_string_from_utf8(), "Google Sheets 실시간 · 다음 시즌 적용")
		else:
			last_error = "시즌 보상 요청 실패 · 마지막 검증 데이터 유지"
	)
	var table: Dictionary = TABLE.load_table(path, [], &"reward_id", payload)
	return _accept(table, "확정 CSV")


func set_source_mode(mode: int) -> void:
	request.cancel_request()
	live_enabled = mode == 1
	remaining = 0
	if not live_enabled:
		_accept(TABLE.load_table(locked_path, [], &"reward_id", locked_payload), "확정 CSV")


func load_csv_text(text: String, label: String) -> bool:
	return _accept(TABLE.parse_table(text, ["reward_id", "ranking_id", "max_rank", "kind", "display_name", "color", "runtime_enabled"], &"reward_id"), label)


func _accept(table: Dictionary, label: String) -> bool:
	if not bool(table.get(&"success", false)):
		last_error = "시즌 보상 CSV 형식 오류"
		return false
	for row in table[&"rows"]:
		if String(row.get(&"kind", "")) not in ["title", "aura"] or String(row.get(&"ranking_id", "")) not in ["recovered_value", "elapsed_seconds", "kills"] or int(row.get(&"max_rank", 0)) < 1 or String(row.get(&"display_name", "")).is_empty() or not Color.html_is_valid(String(row.get(&"color", ""))):
			last_error = "시즌 보상 종류·순위·이름·색상 검증 실패"
			return false
	rows.assign(table[&"rows"].duplicate(true))
	source_label = label
	last_error = ""
	changed.emit()
	return true


func _process(delta: float) -> void:
	if not live_enabled or live_url.is_empty():
		return
	remaining -= delta
	if remaining <= 0 and request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		remaining = 3.0
		request.request(live_url + "&sfh_cache=%d" % int(Time.get_unix_time_from_system()))
