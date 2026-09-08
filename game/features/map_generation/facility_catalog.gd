class_name ExtractionFacilityCatalog
extends RefCounted
## Seedable, validated balance rows. Unsupported input preserves last valid catalog.
const PATH := "res://game/features/map_generation/data/facility.csv"
const PAYLOAD := preload("res://game/features/map_generation/data/facility_payload.tres")
var rows: Array[Dictionary] = []
var error := ""

func _init() -> void:
	load_csv(FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else PAYLOAD.csv_text)

func load_csv(csv: String) -> bool:
	var lines := preload("res://game/features/balance_data/csv_rows.gd").parse(csv)
	var next: Array[Dictionary] = []
	var seen := {}
	var objectives := 0
	if lines.size()<4: error="시설 CSV에 설명행과 데이터가 필요합니다"; return false
	if ",".join(lines[0]) != "facility_id,display_name,encounter,risk_bonus,cache_weight,planner_note": error="시설 CSV 열 불일치"; return false
	for index in range(2,lines.size()):
		var cells := lines[index]
		if cells.size()!=6 or cells[0].is_empty() or cells[1].strip_edges().is_empty() or seen.has(cells[0]) or cells[2] not in ["patrol","objective"] or not cells[3].is_valid_float() or not cells[4].is_valid_float(): error="시설 CSV 행 오류 %d" % (index+1); return false
		var risk := float(cells[3])
		var weight := float(cells[4])
		if not is_finite(risk) or not is_finite(weight) or risk<0 or risk>2 or weight<=0 or weight>10: error="시설 수치 범위 오류"; return false
		seen[cells[0]]=true
		objectives += int(cells[2]=="objective")
		next.append({&"facility_id":cells[0],&"display_name":cells[1],&"encounter":cells[2],&"risk_bonus":risk,&"cache_weight":weight})
	if objectives != 1 or next.size()<2: error="선택형 목표 1종과 일반 시설이 필요합니다"; return false
	rows=next
	error=""
	return true

func get_rows() -> Array[Dictionary]: return rows.duplicate(true)
