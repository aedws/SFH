class_name RankingProviderConfig
extends Resource

@export_enum("local", "auto", "online") var provider_mode := "auto"
@export var offline_fallback_enabled := true
@export var online_provider_label := "SFH 온라인 랭킹"
@export var submission_build_id := "prototype"
@export_range(1, 256, 1) var maximum_pending_submissions := 64
@export_range(1, 20, 1) var maximum_submission_attempts := 5
@export_range(1, 32, 1) var submissions_per_retry := 8


func is_valid() -> bool:
	return (
		provider_mode in ["local", "auto", "online"]
		and not online_provider_label.strip_edges().is_empty()
		and not submission_build_id.strip_edges().is_empty()
		and maximum_pending_submissions > 0
		and maximum_submission_attempts > 0
		and submissions_per_retry > 0
	)
