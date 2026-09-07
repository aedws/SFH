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
var restore_pending := false
var runtime_providers: Dictionary = {}
var checkpoint_provider: Node


func register_runtime_provider(id: StringName, provider: Node) -> bool:
	if active or id in [&"inventory", &"equipment"] or id == &"" or runtime_providers.has(id):
		return false
	if not is_instance_valid(provider) or not provider.has_method(&"export_runtime_state") or not provider.has_method(&"restore_runtime_state"):
		return false
	runtime_providers[id] = provider
	return true


func configure_checkpoint_provider(provider: Node) -> bool:
	if active or not is_instance_valid(provider) or not provider.has_method(&"begin_temporary_loadout") or not provider.has_method(&"end_temporary_loadout"):
		return false
	checkpoint_provider = provider
	return true


func configure(new_equipment_provider: Node, new_inventory_provider: Node) -> bool:
	if not is_instance_valid(new_equipment_provider) or not is_instance_valid(new_inventory_provider):
		return false
	equipment_provider = new_equipment_provider
	inventory_provider = new_inventory_provider
	return true


func begin_session() -> bool:
	if active:
		return not restore_pending
	var candidate = SNAPSHOT.new()
	if not bool(candidate.call(&"capture", equipment_provider, inventory_provider, runtime_providers)):
		return false
	if is_instance_valid(checkpoint_provider) and not bool(checkpoint_provider.call(&"begin_temporary_loadout")):
		return false
	session_snapshot = candidate
	active = true
	last_restore_success = false
	restore_pending = false
	revision += 1
	state_changed.emit(get_snapshot())
	return true


func restore_and_finish() -> bool:
	if not active or session_snapshot == null:
		return false
	last_restore_success = bool(session_snapshot.call(
		&"restore", equipment_provider, inventory_provider, runtime_providers
	))
	# Failed restore retains both the original and the save barrier for retry.
	if last_restore_success:
		if is_instance_valid(checkpoint_provider):
			last_restore_success = bool(checkpoint_provider.call(&"end_temporary_loadout"))
	if last_restore_success:
		active = false
		session_snapshot = null
	restore_pending = not last_restore_success
	revision += 1
	state_changed.emit(get_snapshot())
	return last_restore_success


func get_snapshot() -> Dictionary:
	var captured: Dictionary = (
		session_snapshot.call(&"get_snapshot") if session_snapshot != null else {}
	)
	return {
		&"active": active,
		&"revision": revision,
		&"free_editing": active and not restore_pending,
		&"restore_pending": restore_pending,
		&"restore_on_exit": true,
		&"last_restore_success": last_restore_success,
		&"captured": captured,
	}
