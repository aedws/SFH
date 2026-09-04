class_name ItemQualityCatalog
extends Resource
## Replaceable quality catalogue used by quote and physical-delivery adapters.

@export var definitions: Array[Resource] = []


func is_valid() -> bool:
	var ids := {}
	for definition in definitions:
		if definition == null or not definition.is_valid() or ids.has(definition.quality_id):
			return false
		ids[definition.quality_id] = true
	return not definitions.is_empty()


func get_definition(quality_id: StringName) -> Resource:
	for definition in definitions:
		if definition != null and definition.quality_id == quality_id:
			return definition
	return null


func get_quality_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in definitions:
		if definition != null:
			result.append(definition.quality_id)
	return result
