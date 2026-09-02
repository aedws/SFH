class_name RankingIdentity
extends RefCounted

var storage_path := "user://sfh_ranking_identity.json"
var persistence_enabled := true
var player_id := ""


func configure(new_storage_path: String, enable_persistence: bool = true) -> bool:
	storage_path = new_storage_path
	persistence_enabled = enable_persistence and not storage_path.is_empty()
	player_id = ""
	if persistence_enabled:
		_load()
	if player_id.is_empty():
		player_id = _generate_anonymous_id()
		_save()
	return not player_id.is_empty()


func get_player_id() -> String:
	return player_id


func get_snapshot() -> Dictionary:
	return {
		&"player_id": player_id,
		&"identity_kind": &"anonymous_device",
		&"persistent": persistence_enabled,
	}


func _generate_anonymous_id() -> String:
	var seed := "%d|%d|%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), randi()]
	return "anon_%s" % seed.sha256_text().left(24)


func _save() -> void:
	if not persistence_enabled:
		return
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"player_id": player_id, "schema_version": 1}))


func _load() -> void:
	if not FileAccess.file_exists(storage_path):
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if parsed is Dictionary:
		player_id = String(parsed.get("player_id", "")).strip_edges()
