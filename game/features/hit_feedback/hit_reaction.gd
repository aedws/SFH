class_name HitReaction2D
extends Node

## 한 액터의 짧은 경직·넉백·피격 섬광만 담당하는 선택형 구성 요소입니다.

@export var enabled: bool = true
@export_range(0.0, 0.25, 0.005) var stagger_seconds: float = 0.055
@export_range(0.0, 600.0, 1.0) var knockback_impulse: float = 72.0
@export_range(1.0, 80.0, 1.0) var knockback_decay: float = 24.0
@export_range(0.0, 0.25, 0.005) var flash_seconds: float = 0.07
@export_range(0.25, 3.0, 0.05) var maximum_intensity: float = 1.6

var actor: CharacterBody2D
var visual_nodes: Array[CanvasItem] = []
var base_modulates: Array[Color] = []
var stagger_remaining: float = 0.0
var flash_remaining: float = 0.0
var knockback_velocity := Vector2.ZERO
var reaction_count: int = 0
var flash_active: bool = false


func configure(new_actor: CharacterBody2D, new_visual_nodes: Array) -> bool:
	if not is_instance_valid(new_actor):
		return false
	actor = new_actor
	visual_nodes.clear()
	base_modulates.clear()
	for visual in new_visual_nodes:
		if is_instance_valid(visual):
			visual_nodes.append(visual)
			base_modulates.append(visual.modulate)
	return true


func react(context: Dictionary, damage_amount: float) -> void:
	if not enabled or not is_instance_valid(actor) or damage_amount <= 0.0:
		return
	var direction: Vector2 = context.get(&"impact_direction", Vector2.ZERO)
	if direction.is_zero_approx() and context.has(&"source_position"):
		direction = Vector2(context[&"source_position"]).direction_to(actor.global_position)
	if direction.is_zero_approx():
		direction = -actor.velocity.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var intensity := clampf(
		float(context.get(&"impact_strength", damage_amount / 10.0)),
		0.25,
		maximum_intensity
	)
	stagger_remaining = maxf(stagger_remaining, stagger_seconds * minf(1.25, intensity))
	flash_remaining = maxf(flash_remaining, flash_seconds)
	knockback_velocity += direction.normalized() * knockback_impulse * intensity
	reaction_count += 1
	_set_flash(true)


func advance(delta: float, desired_velocity: Vector2) -> Vector2:
	var safe_delta := maxf(0.0, delta)
	stagger_remaining = maxf(0.0, stagger_remaining - safe_delta)
	flash_remaining = maxf(0.0, flash_remaining - safe_delta)
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * knockback_impulse * safe_delta
	)
	_set_flash(flash_remaining > 0.0)
	if not enabled:
		return desired_velocity
	if stagger_remaining > 0.0:
		return knockback_velocity
	return desired_velocity + knockback_velocity


func get_snapshot() -> Dictionary:
	return {
		&"enabled": enabled,
		&"reaction_count": reaction_count,
		&"stagger_remaining": stagger_remaining,
		&"flash_remaining": flash_remaining,
		&"knockback_speed": knockback_velocity.length(),
		&"visual_count": visual_nodes.size(),
	}


func _set_flash(active: bool) -> void:
	if active == flash_active:
		return
	flash_active = active
	for index in visual_nodes.size():
		visual_nodes[index].modulate = (
			Color(1.8, 1.8, 1.8, base_modulates[index].a)
			if active else base_modulates[index]
		)
