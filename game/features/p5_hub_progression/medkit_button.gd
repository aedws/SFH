extends Button

var patient: Node
var provider: Node
var recovery_multiplier := 1.0

func configure(target: Node, utility_provider: Node, multiplier: float = 1.0) -> void:
	patient = target
	provider = utility_provider
	recovery_multiplier = multiplier
	text = "KIT"
	tooltip_text = "지참 구급키트 사용 · HP는 소모품으로만 회복"
	custom_minimum_size = Vector2(64, 44)
	pressed.connect(_use)
	patient.connect(&"health_changed", _health_changed)
	provider.connect(&"snapshot_changed", _provider_changed)
	_refresh()

func _health_changed(_current: float, _maximum: float) -> void: _refresh()
func _provider_changed(_snapshot: Dictionary) -> void: _refresh()

func _refresh() -> void:
	if not is_instance_valid(patient) or not is_instance_valid(provider):
		disabled = true
		return
	var snapshot: Dictionary = provider.call(&"get_snapshot")
	visible = not String(snapshot.get(&"utility", {}).get(&"active_run_id", "")).is_empty()
	var quantity := int(snapshot.get(&"utility", {}).get(&"active", {}).get(&"field_medkit", 0))
	var health: Dictionary = patient.call(&"get_health_snapshot")
	text = "KIT %d" % quantity
	disabled = quantity <= 0 or float(health.get(&"current", 0)) <= 0 or float(health.get(&"current", 0)) >= float(health.get(&"maximum", 0))

func _use() -> void:
	if not is_instance_valid(patient) or not is_instance_valid(provider): return
	provider.call(&"use_healing_utility", &"field_medkit", patient, recovery_multiplier)
	_refresh()
