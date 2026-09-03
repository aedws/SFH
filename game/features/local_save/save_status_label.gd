extends Label
## Hub-only, compact status. Details remain in a tooltip, not over the battlefield.
func configure(service: Node) -> void:
	add_theme_font_size_override("font_size", 12)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	service.connect(&"storage_changed", present)
	present(service.call(&"get_snapshot"))


func present(snapshot: Dictionary) -> void:
	text = "%s · 작전 %d회 / 탈출 %d회" % [snapshot.status, snapshot.total_runs, snapshot.extractions]
	add_theme_color_override("font_color", Color("ffb45c") if snapshot.blocked else Color("89bec0"))
	tooltip_text = "%s\n%s\n전투 중 종료 시 미반출 전리품은 저장되지 않습니다." % [snapshot.path, snapshot.message]
	for entry in snapshot.history.slice(0, 5):
		tooltip_text += "\n%s · %s · 처치 %d" % [
			Time.get_datetime_string_from_unix_time(int(entry.get("finished_at", 0))),
			"탈출" if entry.get("extracted", false) else "중단" if entry.get("outcome") == "interrupted" else "실패",
			int(entry.get("kills", 0))]
