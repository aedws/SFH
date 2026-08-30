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


func is_valid() -> bool:
	return (
		base_blueprint_chance >= 0.0
		and base_blueprint_chance <= 1.0
		and kills_per_salvage > 0
		and minimum_salvage >= 0
		and not blueprint_by_region.is_empty()
	)


func blueprint_for(region_id: StringName) -> StringName:
	return StringName(blueprint_by_region.get(region_id, &"assault_rifle_blueprint"))
