class_name MultiExtractionZone
extends "res://game/features/extraction/extraction_zone.gd"
## Alternate physical exits forward into the existing single settlement authority.
var alternatives: Array[Node] = []
var active_site: Node
var completed := false

func _ready() -> void:
	super._ready()
	extraction_completed.connect(func(_actor):
		completed=true
		set_locked(true,"탈출 완료"))

func configure_candidates(provider: Node) -> void:
	if not provider.has_method(&"get_extraction_candidates"): return
	var candidates: Array = provider.get_extraction_candidates()
	for row: Dictionary in candidates:
		if (row.position as Vector2).is_equal_approx(global_position): continue
		var site := preload("res://game/features/extraction/extraction_zone.gd").new()
		site.collision_layer=0
		site.collision_mask=1
		var collider := CollisionShape2D.new()
		collider.name="CollisionShape2D"
		site.add_child(collider)
		add_child(site)
		site.set_process(false)
		site.configure(row.position,defense_duration_seconds)
		alternatives.append(site)
		site.interaction_availability_changed.connect(func(available,prompt):interaction_availability_changed.emit(available,prompt))
		site.extraction_completed.connect(func(actor):extraction_completed.emit(actor))
		site.extraction_defense_started.connect(func(actor,duration):
			active_site=site
			for other in alternatives:
				if other!=site: other.set_locked(true,"다른 탈출 지점에서 방어 중")
			super.set_locked(true,"다른 탈출 지점에서 방어 중")
			extraction_defense_started.emit(actor,duration))
		site.extraction_defense_paused.connect(func(remaining):extraction_defense_paused.emit(remaining))
		site.extraction_defense_resumed.connect(func(remaining):extraction_defense_resumed.emit(remaining))
		site.extraction_defense_cancelled.connect(func():extraction_defense_cancelled.emit())

func request_extraction(actor: Node2D) -> bool:
	if completed: return false
	if is_instance_valid(active_site) and active_site!=self: return active_site.request_extraction(actor)
	if not _inside_zone(actor):
		for site in alternatives:
			if site._inside_zone(actor): return site.request_extraction(actor)
		return false
	var accepted := super.request_extraction(actor)
	if accepted:
		active_site=self
		for site in alternatives: site.set_locked(true,"다른 탈출 지점에서 방어 중")
	return accepted

func set_locked(value: bool, prompt: String = "탈출 신호 대기 중") -> void:
	super.set_locked(value,prompt)
	for site in alternatives: site.set_locked(value,prompt)

func get_snapshot() -> Dictionary:
	var result: Dictionary = active_site.get_snapshot() if is_instance_valid(active_site) and active_site!=self else super.get_snapshot()
	result[&"exit_count"]=1+alternatives.size()
	return result

func advance(delta: float) -> void:
	super.advance(delta)
	for site in alternatives: site.advance(delta)
