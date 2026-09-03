class_name AtomicJsonStore
extends RefCounted
## Data only. A verified temporary write and previous-generation backup protect saves.
const FORMAT := "SFH_JSON_1"
const MAX_BYTES := 8 * 1024 * 1024
var last_error := ""


func read(path: String, allow_legacy: bool = false) -> Dictionary:
	last_error = ""
	var current := _read_file(path, allow_legacy)
	if current.get("ok", false):
		return current
	# Never downgrade a save written by a newer format.
	if current.get("status") == "newer":
		return current
	var backup := _read_file(path + ".bak", allow_legacy)
	if backup.get("ok", false):
		backup["status"] = "recovered"
		return backup
	if current.get("status") == "missing" and backup.get("status") == "missing":
		return {"ok": true, "status": "new", "data": {}}
	last_error = "저장 파일을 읽을 수 없습니다. 원본은 보존했습니다."
	return {"ok": false, "status": "invalid", "data": {}}


func write(path: String, data: Dictionary, allow_legacy: bool = false) -> bool:
	last_error = ""
	if path.is_empty():
		return _fail("저장 경로가 없습니다.")
	var previous := read(path, allow_legacy)
	if not previous.get("ok", false):
		return _fail("손상되었거나 새 버전인 저장 파일을 덮어쓰지 않았습니다.")
	var payload := JSON.stringify(data)
	if payload.to_utf8_buffer().size() > MAX_BYTES:
		return _fail("저장 데이터 용량 제한을 초과했습니다.")
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		return _fail("저장 폴더를 만들 수 없습니다.")
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("저장 파일 쓰기 권한 또는 디스크 공간을 확인하세요.")
	file.store_string(JSON.stringify({"format": FORMAT, "payload": payload, "sha256": payload.sha256_text()}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or not _read_file(temporary, false).get("ok", false):
		return _fail("임시 저장 검증에 실패했습니다. 이전 저장을 유지합니다.")
	if FileAccess.file_exists(path):
		# Keep a corrupt primary for diagnosis; do not replace the good backup with it.
		var destination := path + ".bak"
		if previous.get("status") == "recovered":
			destination = path + ".corrupt-%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
		if DirAccess.rename_absolute(absolute, ProjectSettings.globalize_path(destination)) != OK:
			return _fail("이전 저장 백업에 실패했습니다.")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute) != OK:
		return _fail("저장 교체에 실패했습니다. 다음 실행에서 백업으로 복구합니다.")
	return true


func _read_file(path: String, allow_legacy: bool) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "status": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES * 2:
		return {"ok": false, "status": "invalid"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {"ok": false, "status": "invalid"}
	var envelope: Dictionary = parser.data
	if not envelope.has("format") and allow_legacy:
		return {"ok": true, "status": "legacy", "data": envelope}
	if envelope.get("format") != FORMAT:
		return {"ok": false, "status": "newer"}
	if not envelope.get("payload") is String or not envelope.get("sha256") is String:
		return {"ok": false, "status": "invalid"}
	var payload: String = envelope["payload"]
	if payload.sha256_text() != envelope["sha256"] or parser.parse(payload) != OK or not parser.data is Dictionary:
		return {"ok": false, "status": "invalid"}
	return {"ok": true, "status": "loaded", "data": parser.data}


func _fail(message: String) -> bool:
	last_error = message
	return false
