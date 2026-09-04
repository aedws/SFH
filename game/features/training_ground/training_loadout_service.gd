class_name TrainingLoadoutService
extends RefCounted

signal state_changed(snapshot: Dictionary)

const SNAPSHOT := preload("res://game/features/training_ground/training_loadout_snapshot.gd")

var equipment_provider: Node
var inventory_provider: Node
var session_snapshot: Resource
var active := false
var revision := 0
var last_restore_success := false


func configure(new_equipment_provider: Node, new_inventory_provider: Node) -> bool:
	if not is_instance_valid(new_equipment_provider) or not is_instance_valid(new_inventory_provider):
		return false
	equipment_provider = new_equipment_provider
	inventory_provider = new_inventory_provider
	return true


func begin_session() -> bool:
	if active:
		return true
	var candidate = SNAPSHOT.new()
	if not bool(candidate.call(&"capture", equipment_provider, inventory_provider)):
		return false
	session_snapshot = candidate
	active = true
	last_restore_success = false
	revision += 1
	state_changed.emit(get_snapshot())
	return true


func restore_and_finish() -> bool:
	if not active or session_snapshot == null:
		return false
	last_restore_success = bool(session_snapshot.call(
		&"restore", equipment_provider, inventory_provider
	))
	active = false
	revision += 1
	state_changed.emit(get_snapshot())
	session_snapshot = null
	return last_restore_success


func get_snapshot() -> Dictionary:
	var captured: Dictionary = (
		session_snapshot.call(&"get_snapshot") if session_snapshot != null else {}
	)
	return {
		&"active": active,
		&"revision": revision,
		&"free_editing": active,
		&"restore_on_exit": true,
		&"last_restore_success": last_restore_success,
		&"captured": captured,
	}
