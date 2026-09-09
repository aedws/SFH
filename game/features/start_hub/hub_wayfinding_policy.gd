class_name HubWayfindingPolicy
extends RefCounted

## 거점 좌표를 플레이어가 읽을 수 있는 목표·거리 정보로만 변환합니다.
## 월드, 입력, UI 노드를 소유하지 않아 거점 배치나 HUD를 독립적으로 교체할 수 있습니다.

func snapshot(player_position: Vector2, gate_position: Vector2, interaction_available: bool = false) -> Dictionary:
	var offset := gate_position - player_position
	var distance := offset.length()
	var direction := _cardinal(offset)
	return {
		&"direction": direction,
		&"distance_pixels": distance,
		&"nearby": interaction_available,
		&"text": (
			"작전 게이트 도착 · F로 작전 브리핑 열기"
			if interaction_available
			else "%s 작전 게이트 · %dm · 로드아웃 단말과 별도" % [direction, roundi(distance / 10.0)]
		),
	}


func _cardinal(offset: Vector2) -> String:
	if absf(offset.x) >= absf(offset.y):
		return "E →" if offset.x >= 0.0 else "← W"
	return "S ↓" if offset.y >= 0.0 else "↑ N"
