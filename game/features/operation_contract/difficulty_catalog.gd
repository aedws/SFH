class_name OperationDifficultyCatalog
extends RefCounted
## Ten ordered, atomic policy rows. Numeric balance is provisional and data-owned.
const PATH := "res://game/features/operation_contract/data/difficulty.csv"
const PAYLOAD := preload("res://game/features/operation_contract/data/difficulty_payload.tres")
const COLUMNS := "level,difficulty_id,display_name,entry_cost_multiplier,health_multiplier,damage_multiplier,armor_multiplier,speed_multiplier,reward_multiplier,high_grade_drop_multiplier,polygon_ratio,loot_band,planner_note"
var rows: Array[Dictionary] = []
var error := ""

func _init() -> void:
	load_csv(FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else PAYLOAD.csv_text)

func load_csv(csv: String) -> bool:
	var matrix := preload("res://game/features/balance_data/csv_rows.gd").parse(csv)
	if matrix.size()!=12 or ",".join(matrix[0])!=COLUMNS: error="난이도는 설명행 + 1~10단계가 필요합니다"; return false
	var next: Array[Dictionary] = []
	var ids := {}
	var previous: Array[float] = []
	for index in range(2,12):
		var cells := matrix[index]
		if cells.size()!=13 or not cells[0].is_valid_int() or int(cells[0])!=index-1 or cells[1].is_empty() or ids.has(cells[1]) or cells[2].is_empty() or cells[11] not in ["standard","veteran","nightmare"]: error="난이도 행/순서/ID 오류"; return false
		var expected_id := "standard" if index==2 else ("veteran" if index==6 else ("nightmare" if index==11 else "level_%02d" % (index-1)))
		if cells[1]!=expected_id: error="난이도 ID는 저장/랭킹 호환을 위해 고정합니다"; return false
		if String(loot_band(StringName(cells[1])))!=cells[11]: error="드랍 호환 밴드는 단계 ID에 고정됩니다"; return false
		var values: Array[float] = []
		for column in range(3,11):
			if not cells[column].is_valid_float(): error="난이도 숫자 오류"; return false
			var value := float(cells[column])
			var maximum := 0.6 if column==10 else (1.5 if column==7 else 10.0)
			if not is_finite(value) or value<(0.0 if column==10 else 1.0) or value>maximum: error="난이도 안전 범위 초과"; return false
			if not previous.is_empty() and (value<previous[column-3] or (column==3 and value==previous[0])): error="투입비는 증가해야 하며 위험도는 감소할 수 없습니다"; return false
			values.append(value)
		previous=values
		ids[cells[1]]=true
		next.append({&"level":index-1,&"difficulty_id":StringName(cells[1]),&"display_name":cells[2],&"entry_cost_multiplier":values[0],&"enemy_modifiers":{&"health_multiplier":values[1],&"damage_multiplier":values[2],&"armor_multiplier":values[3],&"speed_multiplier":values[4]},&"reward_multiplier":values[5],&"high_grade_drop_multiplier":values[6],&"map_geometry":{&"polygon_ratio":values[7]},&"loot_band":StringName(cells[11]),&"boss_guaranteed":index==11,&"planner_note":cells[12]})
	rows=next
	error=""
	return true

func get_rows() -> Array[Dictionary]: return rows.duplicate(true)

static func loot_band(id: StringName) -> StringName:
	if String(id).begins_with("level_"):
		var level := int(String(id).trim_prefix("level_"))
		return &"standard" if level<5 else (&"veteran" if level<10 else &"nightmare")
	return id
