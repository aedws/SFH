class_name InventoryCatalog
extends Resource

@export var grid_size := Vector2i(12, 8)
## Zero preserves saved capacity. Enable explicitly when a capacity rollout is approved.
@export var restore_capacity := Vector2i.ZERO
@export var items: Array[InventoryItemDefinition] = []


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if grid_size.x <= 0 or grid_size.y <= 0:
		errors.append("인벤토리 격자 크기는 양수여야 합니다.")
	if restore_capacity != Vector2i.ZERO and (restore_capacity.x <= 0 or restore_capacity.y <= 0):
		errors.append("저장 가방 이관 규격이 유효하지 않습니다.")
	var item_ids: Dictionary = {}
	for item in items:
		if item == null or not item.is_valid():
			errors.append("유효하지 않은 인벤토리 아이템 정의가 있습니다.")
			continue
		if item.grid_size.x > grid_size.x or item.grid_size.y > grid_size.y:
			errors.append("아이템이 가방보다 큽니다: %s" % item.display_name)
		if item_ids.has(item.item_id):
			errors.append("중복 인벤토리 아이템 ID입니다: %s" % item.item_id)
		item_ids[item.item_id] = true
	return errors
