class_name RunFlowCollector
extends RefCounted
## Read-only evidence. A measured interval is never a FUN QA acceptance verdict.

const LIMIT := 512
var run_id := ""
var ended := false
var outcome := ""
var visits: Array[Dictionary] = []
var decisions: Array[Dictionary] = []
var encounters: Dictionary = {}
var pending: Dictionary = {}
var overflow := 0
var missing := 0
var last_time := 0.0
var current_room := -1


func begin(id: String) -> void:
	run_id = id
	ended = false
	outcome = ""
	visits.clear()
	decisions.clear()
	encounters.clear()
	pending.clear()
	overflow = 0
	missing = 0
	last_time = 0.0
	current_room = -1


func _accept(time: float) -> bool:
	if ended or run_id.is_empty(): return false
	if not is_finite(time) or time < last_time:
		missing += 1
		return false
	last_time = time
	return true


func enter(room: int, time: float) -> void:
	if not _accept(time) or room < 0 or room == current_room: return
	if not visits.is_empty():
		var previous: Dictionary = visits.back()
		if float(previous.next_entry_s) < 0:
			previous["next_entry_s"] = time
			previous["next_room"] = room
	current_room = room
	if visits.size() >= LIMIT:
		overflow += 1
		return
	visits.append({"room": room, "entry_s": time, "next_entry_s": -1.0, "next_room": -1})


func encounter(room: int, time: float) -> void:
	if not _accept(time) or encounters.has(room): return
	if encounters.size() >= LIMIT:
		overflow += 1
		return
	encounters[room] = {"start_s": time, "clear_s": -1.0, "credit_boxes": 0}


func clear(room: int, time: float) -> void:
	if not _accept(time): return
	if not encounters.has(room):
		missing += 1
		return
	if float(encounters[room].clear_s) < 0: encounters[room].clear_s = time


func credit(room: int, time: float) -> void:
	if not _accept(time): return
	if encounters.has(room): encounters[room].credit_boxes += 1


func decision(id: int, stage: StringName, action: StringName, time: float) -> void:
	if not _accept(time): return
	if stage == &"open":
		if pending.has(id): return
		if decisions.size() + pending.size() >= LIMIT:
			overflow += 1
			return
		pending[id] = {"drop_id": id, "room": current_room, "open_s": time}
	elif pending.has(id):
		var sample: Dictionary = pending[id]
		pending.erase(id)
		sample["end_s"] = time
		sample["duration_s"] = time - float(sample.open_s)
		sample["action"] = String(action)
		# Walking away is an unresolved observation, not a fast decision.
		sample["resolved"] = stage == &"resolve"
		decisions.append(sample)
	else:
		missing += 1


func finish(reason: String, time: float) -> void:
	if not _accept(time): return
	for id: int in pending.keys(): decision(id, &"interrupt", &"run_ended", time)
	outcome = reason
	ended = true


func snapshot() -> Dictionary:
	var rows: Array[Dictionary] = []
	var complete := 0
	for visit in visits:
		var row := visit.duplicate(true)
		var fight: Dictionary = encounters.get(int(row.room), {})
		row["encounter"] = fight.duplicate(true)
		var clear_time := float(fight.get("clear_s", -1.0))
		var next_time := float(row.next_entry_s)
		var start := float(fight.get("start_s", -1.0))
		row["status"] = "no_encounter"
		if start >= float(row.entry_s) and (next_time < 0 or start <= next_time):
			row["status"] = "awaiting_next_entry" if clear_time >= 0 else "uncleared"
			if next_time >= 0:
				row["status"] = "complete" if clear_time >= start and clear_time <= next_time else "left_before_clear"
				if row.status == "complete":
					complete += 1
					row["loop_s"] = next_time - float(row.entry_s)
					row["combat_s"] = clear_time - start
					row["after_clear_s"] = next_time - clear_time
		rows.append(row)
	return {"schema": 1, "run_id": run_id, "ended": ended, "outcome": outcome,
		"clock": "monotonic_wall_seconds_including_pause", "duration_s": last_time,
		"visits": rows, "decisions": decisions.duplicate(true), "pending_decisions": pending.size(),
		"complete_loops": complete, "missing_events": missing, "overflow": overflow,
		"human_acceptance": "not_evaluated"}
