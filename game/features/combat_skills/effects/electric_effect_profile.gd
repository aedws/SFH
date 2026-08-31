class_name ElectricEffectProfile
extends Resource

## 전기 이펙트의 모양과 연산 예산을 데이터로 제한합니다.

@export_enum("trail", "ring", "burst") var pattern: String = "ring"
@export_range(0.05, 8.0, 0.05) var lifetime_seconds: float = 0.6
@export_range(1.0, 30.0, 1.0) var geometry_refresh_hz: float = 15.0
@export_range(1, 16, 1) var arc_count: int = 6
@export_range(3, 12, 1) var points_per_arc: int = 6
@export_range(0.0, 80.0, 1.0) var jitter_pixels: float = 18.0
@export_range(0.5, 12.0, 0.5) var glow_width: float = 6.0
@export_range(0.5, 8.0, 0.5) var core_width: float = 2.0
@export_range(0.0, 0.5, 0.01) var field_fill_alpha: float = 0.08
@export var glow_color: Color = Color(0.16, 0.55, 1.0, 0.48)
@export var core_color: Color = Color(0.76, 0.94, 1.0, 1.0)
@export var accent_texture: Texture2D
@export_range(0, 16, 1) var accent_count: int = 0
@export_range(8.0, 96.0, 1.0) var accent_size: float = 36.0
@export_range(0.0, 1.0, 0.05) var accent_alpha: float = 0.65


func is_valid() -> bool:
	return (
		pattern in ["trail", "ring", "burst"]
		and lifetime_seconds > 0.0
		and geometry_refresh_hz > 0.0
		and arc_count > 0
		and points_per_arc >= 3
		and estimated_line_segments() <= 128
		and accent_count <= 16
		and core_width <= glow_width
	)


func estimated_line_segments() -> int:
	return arc_count * (points_per_arc - 1)


func get_snapshot() -> Dictionary:
	return {
		&"pattern": pattern,
		&"lifetime_seconds": lifetime_seconds,
		&"geometry_refresh_hz": geometry_refresh_hz,
		&"arc_count": arc_count,
		&"points_per_arc": points_per_arc,
		&"estimated_line_segments": estimated_line_segments(),
		&"accent_count": accent_count,
		&"accent_texture_path": accent_texture.resource_path if accent_texture != null else "",
	}
