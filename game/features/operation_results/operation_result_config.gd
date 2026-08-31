class_name OperationResultConfig
extends Resource

@export_range(0.0, 1.0, 0.01) var base_blueprint_chance := 0.12
@export_range(1, 1000, 1) var kills_per_salvage := 12
@export_range(0, 100, 1) var minimum_salvage := 1
@export var blueprint_by_region: Dictionary = {
	&"ruined_city": &"assault_rifle_blueprint",
	&"industrial_district": &"assault_rifle_blueprint",
	&"research_complex": &"tactical_vest_blueprint",
}
@export var shop_offer_by_blueprint: Dictionary = {
	&"assault_rifle_blueprint": &"buy_assault_rifle",
	&"tactical_vest_blueprint": &"buy_tactical_vest",
	&"magnetic_field_blueprint": &"unlock_magnetic_field",
}


func is_valid() -> bool:
	return (
		base_blueprint_chance >= 0.0
		and base_blueprint_chance <= 1.0
		and kills_per_salvage > 0
		and minimum_salvage >= 0
		and not blueprint_by_region.is_empty()
		and not shop_offer_by_blueprint.is_empty()
	)


func blueprint_for(region_id: StringName) -> StringName:
	return StringName(blueprint_by_region.get(region_id, &"assault_rifle_blueprint"))


func shop_offer_for(blueprint_id: StringName) -> StringName:
	return StringName(shop_offer_by_blueprint.get(blueprint_id, &""))
