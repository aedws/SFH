extends RefCounted
## Replace only default player paths before Game._ready(). Explicit fixture paths stay intact.
var root_path := OS.get_cache_dir().path_join("sfh-contract-%d" % Time.get_ticks_usec())
var sequence := 0


func isolate(node: Node) -> void:
	if node.scene_file_path != "res://game/scenes/game.tscn": return
	var defaults: Resource = load("res://game/core/feature_manifest.tres")
	var features: Resource = node.get("features").duplicate(true)
	sequence += 1
	var directory := root_path.path_join(str(sequence))
	DirAccess.make_dir_recursive_absolute(directory)
	for field in ["persistent_profile", "conditional_ranking", "meta_progression", "key_mapping", "skill_binding", "presentation_settings", "desktop_progress"]:
		var property: String = field + "_storage_path"
		if features.get(property) == defaults.get(property):
			features.set(property, directory.path_join(field + ".json"))
	# Optional native save has its own two-process contract; smoke/perf stay unchanged.
	features.desktop_progress_enabled = false
	node.set("features", features)
