class_name ArmorSetResolver
extends RefCounted
## Counts distinct armor slots, then activates each threshold exactly once.

static func resolve(states: Array) -> Dictionary:
	var result := {"player": {}, "weapon": {}, "skill": {}, "sets": [], "errors": []}
	var groups := {}
	var occupied := []
	for state in states:
		if not state is EquipmentItemState or not state.is_armor(): continue
		var armor := state.definition as EquipmentArmorDefinition
		if armor.slot_id in occupied:
			result.errors.append("duplicate_armor_slot")
			continue
		occupied.append(armor.slot_id)
		var definition := armor.armor_set
		if definition == null: continue
		if not definition.is_valid():
			result.errors.append("invalid_armor_set")
			continue
		var id := String(definition.set_id)
		var source := definition.snapshot()
		if groups.has(id) and groups[id].source != source:
			result.errors.append("conflicting_armor_set:" + id)
			continue
		if not groups.has(id): groups[id] = {"source": source, "count": 0}
		groups[id].count += 1
	# Fail closed: malformed saved data must never partially grant bonuses.
	if not result.errors.is_empty(): return result
	for id in groups:
		var group: Dictionary = groups[id]
		var status: Dictionary = group.source.duplicate(true)
		status["count"] = group.count
		for bonus in status.bonuses:
			bonus["active"] = group.count >= int(bonus.required_pieces)
			if not bonus.active: continue
			for stat in bonus.get("player", {}):
				var entry: Dictionary = result.player.get(stat, {"add": 0.0, "multiply": 1.0})
				entry.add += float(bonus.player[stat].get("add", 0))
				entry.multiply *= float(bonus.player[stat].get("multiply", 1))
				result.player[stat] = entry
			for target in ["weapon", "skill"]:
				for modifier in bonus.get(target, {}):
					result[target][modifier] = float(result[target].get(modifier, 1)) * float(bonus[target][modifier])
		result.sets.append(status)
	return result


static func describe(snapshot: Dictionary) -> String:
	var lines := PackedStringArray()
	for item in snapshot.get("sets", []):
		lines.append("%s · %d/4" % [item.name, item.count])
		for bonus in item.bonuses:
			lines.append("%s %d세트 · %s" % ["활성" if bonus.active else "미충족", bonus.required_pieces, bonus.get("description", "")])
	return "\n".join(lines)
