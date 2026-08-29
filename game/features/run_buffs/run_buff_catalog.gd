class_name RunBuffCatalog
extends Resource

@export var buffs: Array[Resource] = []


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var buff_ids: Dictionary = {}
	for buff in buffs:
		if buff == null or not buff.has_method(&"is_valid") or not buff.call(&"is_valid"):
			errors.append("유효하지 않은 런 버프 정의가 있습니다.")
			continue
		var current_buff_id: StringName = buff.get("buff_id")
		if buff_ids.has(current_buff_id):
			errors.append("중복 런 버프 ID입니다: %s" % current_buff_id)
		buff_ids[current_buff_id] = true
	if buffs.is_empty():
		errors.append("런 버프가 하나 이상 필요합니다.")
	return errors


func get_buff(buff_id: StringName) -> Resource:
	for buff in buffs:
		if buff != null and buff.get("buff_id") == buff_id:
			return buff
	return null
