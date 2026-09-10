class_name HitFeedbackProfile
extends Resource

## 피해량과 무관한 화면 피드백 강도를 데이터로 조정합니다.

@export_range(0.05, 1.0, 0.01) var impact_lifetime_seconds: float = 0.18
@export_range(4.0, 96.0, 1.0) var impact_radius: float = 26.0
@export_range(3, 16, 1) var impact_ray_count: int = 8
@export_range(1, 128, 1) var maximum_active_impacts: int = 32
@export_range(0.1, 100.0, 0.1) var reference_damage: float = 10.0
@export_range(0.0, 1.0, 0.01) var enemy_hit_trauma: float = 0.13
@export_range(0.0, 1.0, 0.01) var player_hit_trauma: float = 0.34
@export_range(0.0, 1.0, 0.01) var lethal_bonus_trauma: float = 0.16
@export_range(0.0, 24.0, 0.1) var maximum_camera_offset: float = 6.0
@export_range(0.1, 30.0, 0.1) var camera_decay_per_second: float = 3.8
@export_range(0.0, 8.0, 0.1) var directional_kick_pixels: float = 1.8
@export_range(1.0, 40.0, 1.0) var directional_kick_decay: float = 20.0
@export var audio_profile: CombatAudioProfile
@export var contact_texture: Texture2D
@export var visual_style: CombatVfxStyle = preload("res://game/features/combat_vfx/default_style.tres")
@export_range(0.04, 0.2, 0.01) var contact_hold_seconds: float = 0.10
@export_range(8.0, 64.0, 1.0) var minimum_contact_radius: float = 22.0


func is_valid() -> bool:
	return (
		impact_lifetime_seconds > 0.0
		and impact_radius > 0.0
		and impact_ray_count >= 3
		and maximum_active_impacts > 0
		and reference_damage > 0.0
		and maximum_camera_offset >= 0.0
		and camera_decay_per_second > 0.0
		and directional_kick_pixels >= 0.0
		and directional_kick_decay > 0.0
		and visual_style != null and contact_hold_seconds > 0 and minimum_contact_radius > 0
		and (audio_profile == null or audio_profile.is_valid())
	)


func get_snapshot() -> Dictionary:
	return {
		&"impact_lifetime_seconds": impact_lifetime_seconds,
		&"impact_radius": impact_radius,
		&"impact_ray_count": impact_ray_count,
		&"maximum_active_impacts": maximum_active_impacts,
		&"reference_damage": reference_damage,
		&"enemy_hit_trauma": enemy_hit_trauma,
		&"player_hit_trauma": player_hit_trauma,
		&"lethal_bonus_trauma": lethal_bonus_trauma,
		&"maximum_camera_offset": maximum_camera_offset,
		&"camera_decay_per_second": camera_decay_per_second,
		&"directional_kick_pixels": directional_kick_pixels,
		&"directional_kick_decay": directional_kick_decay,
	}
