class_name CombatSkillEffect
extends Resource

## 전투 스킬의 실제 효과가 구현해야 하는 최소 계약입니다.


func activate(_player: Node2D, _context: Dictionary) -> Dictionary:
	return {
		&"success": false,
		&"status": "효과가 구현되지 않았습니다.",
	}


func get_parameters() -> Dictionary:
	return {}
