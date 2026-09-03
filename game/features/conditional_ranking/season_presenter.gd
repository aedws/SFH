class_name SeasonPresenter
extends RefCounted


static func briefing(state: Dictionary) -> String:
	if state.is_empty():
		return ""
	var season: Dictionary = state.get(&"season", {})
	if season.is_empty():
		return "시즌 비활성 · 일반 작전 가능"
	return "%s · 로컬 테스트\n종료 %s UTC · %s · 최소 페널티 %d점\n%s" % [
		season.get(&"display_name", "시즌"),
		Time.get_datetime_string_from_unix_time(int(season.get(&"ends_at", 0)), true),
		_tier_labels(season.get(&"allowed_map_sizes", [])),
		int(season.get(&"minimum_penalty_score", 0)), state.get(&"reason", ""),
	]


static func result_text(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	return "\n시즌 · %s%s" % [result.get(&"reason", ""), " · 학살자 #%d" % int(result.get(&"ranks", {}).get(&"kills", 0)) if bool(result.get(&"accepted", false)) else ""]


static func _tier_labels(tiers: Array) -> String:
	var labels := PackedStringArray()
	for tier in tiers:
		labels.append({"small": "소형", "medium": "중형", "large": "대형"}.get(String(tier), String(tier)))
	return " / ".join(labels)


static func history(snapshot: Dictionary) -> String:
	var lines := PackedStringArray(["로컬 시즌 기록 · 읽기 전용", "온라인 경쟁 순위·보상 지급이 아닙니다.", "학살자: 총 처치 우선, 동점이면 보스 격파 우선 (임시 정책)", ""])
	var active: Dictionary = snapshot.get(&"active", {})
	if not active.is_empty():
		lines.append_array(_ladder_lines(active, snapshot.get(&"ladder", {}), "진행 중"))
	var archives: Array = snapshot.get(&"archives", []).duplicate()
	archives.reverse()
	for archive in archives:
		lines.append_array(_ladder_lines(archive.get(&"season", {}), archive.get(&"ladder", {}), "마감 · 수정 불가"))
	if archives.is_empty():
		lines.append("마감된 시즌 기록 없음")
	return "\n".join(lines)


static func _ladder_lines(season: Dictionary, ladder: Dictionary, status: String) -> PackedStringArray:
	var lines := PackedStringArray(["%s — %s" % [season.get(&"display_name", "시즌"), status]])
	var conditions: Dictionary = ladder.get(&"entries_by_condition", {})
	if conditions.is_empty():
		lines.append("  참가 기록 없음")
	for condition in conditions:
		lines.append("  %s" % condition)
		for category in [&"recovered_value", &"elapsed_seconds", &"kills"]:
			var entries: Array = conditions[condition].get(category, [])
			var label := "가치" if category == &"recovered_value" else "시간" if category == &"elapsed_seconds" else "학살자"
			for index in mini(3, entries.size()):
				var entry: Dictionary = entries[index]
				lines.append("    %s #%d · %d C / %.1f초 / 처치 %d · 보스 %d" % [label, index + 1, int(entry.get(&"recovered_value", 0)), float(entry.get(&"elapsed_seconds", 0.0)), int(entry.get(&"kills", 0)), int(entry.get(&"boss_kills", 0))])
	lines.append("")
	return lines
