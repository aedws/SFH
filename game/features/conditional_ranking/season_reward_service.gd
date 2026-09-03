class_name SeasonRewardService
extends RefCounted
## Consumes closed immutable local archives. A server reward provider can replace this.


func synchronize(snapshot: Dictionary, profile: Node, player_id: String) -> int:
	if not String(snapshot.get(&"storage_error", "")).is_empty():
		return 0
	var granted := 0
	for archive in snapshot.get(&"archives", []):
		if not bool(archive.get(&"read_only", false)):
			continue
		var season: Dictionary = archive.get(&"season", {})
		if int(archive.get(&"closed_at", 0)) < int(season.get(&"ends_at", 1)):
			continue
		var conditions: Dictionary = archive.get(&"ladder", {}).get(&"entries_by_condition", {})
		for reward in season.get(&"reward_catalog", []):
			for condition in conditions:
				var entries: Array = conditions[condition].get(String(reward[&"ranking_id"]), [])
				var rank := 0
				var seen: Dictionary = {}
				for entry in entries:
					var identity := String(entry.get(&"player_id", ""))
					if identity.is_empty() or seen.has(identity):
						continue
					seen[identity] = true
					rank += 1
					if identity == player_id and rank <= int(reward[&"max_rank"]):
						var evidence := {"season_id": season[&"season_id"], "condition": condition, "ranking_id": reward[&"ranking_id"], "rank": rank, "closed_at": archive[&"closed_at"], "local_only": true}
						var receipt := "%s|%s|%s" % [season[&"season_id"], condition, reward[&"reward_id"]]
						if profile.call(&"grant", receipt, reward, evidence):
							granted += 1
	return granted
