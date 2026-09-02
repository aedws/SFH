class_name LoadoutInvestmentEntry
extends Resource

@export var item_kind: StringName
@export var item_id: StringName
@export var display_name: String
@export var slot_id: StringName
@export_file("*.tres") var definition_path: String
@export_range(0, 1000000, 1) var run_investment_price: int = 0
@export var default_owned: bool = false
@export var required_unlock_id: StringName
@export var source_status: StringName = &"temporary"


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_kind not in [&"weapon", &"skill"]:
		errors.append("item_kind는 weapon 또는 skill이어야 합니다.")
	if item_id == &"" or display_name.strip_edges().is_empty() or slot_id == &"":
		errors.append("아이템 ID·표시 이름·슬롯이 필요합니다.")
	if definition_path.is_empty() or not ResourceLoader.exists(definition_path):
		errors.append("런타임 Resource 경로가 유효하지 않습니다: %s" % definition_path)
	if run_investment_price < 0:
		errors.append("런 투자 가격은 0 이상이어야 합니다.")
	if not default_owned and required_unlock_id == &"":
		errors.append("기본 소유가 아닌 항목에는 해금 ID가 필요합니다.")
	if source_status not in [&"temporary", &"confirmed"]:
		errors.append("source_status는 temporary 또는 confirmed여야 합니다.")
	return errors


func to_snapshot(profile: Node, active_run: bool = false) -> Dictionary:
	var unlocked := default_owned or (
		required_unlock_id != &""
		and is_instance_valid(profile)
		and profile.has_method(&"is_unlocked")
		and bool(profile.call(&"is_unlocked", required_unlock_id))
	)
	var state := &"owned" if default_owned else &"locked" if not unlocked else &"run_purchased" if active_run else &"run_purchase"
	return {
		&"item_kind": item_kind, &"item_id": item_id, &"display_name": display_name,
		&"slot_id": slot_id, &"resource_path": definition_path,
		&"run_investment_price": run_investment_price, &"default_owned": default_owned,
		&"required_unlock_id": required_unlock_id, &"unlocked": unlocked,
		&"state": state, &"state_label": {
			&"owned": "소유", &"locked": "미해금", &"run_purchase": "이번 런 구매",
			&"run_purchased": "구매 완료",
		}.get(state, "상태 확인"),
		&"source_status": source_status,
	}
