class_name ValidatedCsvCatalogService
extends Node
## Live rows are validated atomically; generation consumes a frozen copy at launch.
signal catalog_changed(snapshot: Dictionary)
@export var live_csv_url := ""
var catalog_name := "CSV"
@export var refresh_seconds := 30.0
var catalog: RefCounted
var live := false
var source := "확정 CSV"
var last_error := ""
var pending := false
var remaining := 0.0
var http: HTTPRequest

func _ready() -> void:
	http = HTTPRequest.new()
	http.timeout = 12
	add_child(http)
	http.request_completed.connect(_received)

func set_source_mode(mode: int) -> void:
	live = mode == 1
	if pending:
		http.cancel_request()
		pending = false
	catalog = create_catalog()
	source = "확정 CSV · 실시간 대기" if live else "확정 CSV"
	last_error = ""
	remaining = 0
	catalog_changed.emit(get_snapshot())

func _process(delta: float) -> void:
	if not live or pending: return
	remaining -= delta
	if remaining > 0: return
	remaining = refresh_seconds
	pending = http.request(live_csv_url + "&sfh_cache=%d" % Time.get_unix_time_from_system()) == OK
	if not pending:
		last_error = "밸런스 시트 요청 실패 · 마지막 정상 데이터 유지"
		catalog_changed.emit(get_snapshot())

func _received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	pending = false
	if not live: return
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and catalog.load_csv(body.get_string_from_utf8()):
		source = "실시간 %s · 다음 작전부터 적용" % catalog_name
		last_error = ""
	else:
		last_error = "밸런스 시트 오류 · 마지막 정상 데이터 유지"
	catalog_changed.emit(get_snapshot())

func get_rows() -> Array[Dictionary]: return catalog.get_rows()
func get_snapshot() -> Dictionary:
	return {&"source":source, &"error":last_error, &"live":live, &"row_count":catalog.rows.size()}

func create_catalog() -> RefCounted:
	return null # Concrete providers supply a validated catalog; this base is not instantiated.
