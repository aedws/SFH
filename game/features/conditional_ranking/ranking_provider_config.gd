class_name RankingProviderConfig
extends Resource

@export_enum("local", "auto", "online") var provider_mode := "auto"
@export var offline_fallback_enabled := true
@export var online_provider_label := "SFH 온라인 랭킹"


func is_valid() -> bool:
	return (
		provider_mode in ["local", "auto", "online"]
		and not online_provider_label.strip_edges().is_empty()
	)
