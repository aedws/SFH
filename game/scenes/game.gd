extends Node2D

## 최상위 조립 지점입니다. 기능은 활성화됐을 때만 경로로 불러옵니다.

const PLAYER_SCENE_PATH := "res://game/features/player/player.tscn"
const MAP_GENERATOR_SCENE_PATH := "res://game/features/map_generation/map_generator.tscn"
const MAP_CONFIG_PATH_PATTERN := "res://game/features/map_generation/configs/%s.tres"
const SPAWNER_SCENE_PATH := "res://game/features/spawning/enemy_spawner.tscn"
const WEAPON_SCENE_PATH := "res://game/features/weapons/auto_weapon.tscn"
const PROGRESSION_SCENE_PATH := "res://game/features/experience/progression_system.tscn"
const MAP_GENERATOR_METHODS := [
	&"generate",
	&"get_player_spawn_position",
	&"get_enemy_spawn_position",
	&"get_world_path",
]

@export var features: FeatureManifest

@onready var actors_container: Node2D = $World/Actors
@onready var enemies_container: Node2D = $World/Enemies
@onready var projectiles_container: Node2D = $World/Projectiles
@onready var pickups_container: Node2D = $World/Pickups
@onready var module_container: Node = $Modules
@onready var world_container: Node2D = $World
@onready var status_label: Label = %StatusLabel
@onready var time_label: Label = %TimeLabel
@onready var level_label: Label = %LevelLabel
@onready var kills_label: Label = %KillsLabel
@onready var map_label: Label = %MapLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var experience_bar: ProgressBar = %ExperienceBar
@onready var experience_label: Label = %ExperienceLabel
@onready var game_over_overlay: Control = %GameOverOverlay
@onready var game_over_summary: Label = %GameOverSummary
@onready var restart_button: Button = %RestartButton

var player
var map_generator
var enemy_spawner
var auto_weapon
var progression_system
var elapsed_time: float = 0.0
var defeated_enemies: int = 0
var run_ended: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_restart_run)

	if features == null:
		_report_configuration_error("FeatureManifest가 지정되지 않았습니다.")
		return
	map_label.visible = features.map_generation_enabled

	var configuration_errors := features.validation_errors()
	if not configuration_errors.is_empty():
		for message in configuration_errors:
			push_error(message)
		status_label.text = "설정 오류: %s" % " / ".join(configuration_errors)
		return

	var player_spawn_position := Vector2.ZERO
	if features.player_enabled:
		if features.map_generation_enabled:
			map_generator = _instantiate_feature(MAP_GENERATOR_SCENE_PATH, world_container, &"GeneratedMap")
			if map_generator != null:
				if not _supports_map_generator(map_generator):
					_report_configuration_error("맵 모듈이 필수 공개 계약을 구현하지 않았습니다.")
					map_generator.queue_free()
					map_generator = null
				else:
					map_generator.connect(&"map_generated", Callable(self, &"_on_map_generated"))
					var map_config_path := MAP_CONFIG_PATH_PATTERN % features.map_size
					if ResourceLoader.exists(map_config_path):
						var map_config := load(map_config_path)
						map_generator.call(&"generate", map_config, features.map_seed)
						player_spawn_position = map_generator.call(&"get_player_spawn_position")
					else:
						_report_configuration_error("맵 설정을 찾을 수 없습니다: %s" % map_config_path)

		player = _instantiate_feature(PLAYER_SCENE_PATH, actors_container, &"Player")
	if player == null:
		_report_configuration_error("플레이어 모듈을 설치하지 못했습니다.")
		return

	player.global_position = player_spawn_position
	player.call(&"configure_damage", features.damage_enabled)
	player.connect(&"health_changed", Callable(self, &"_on_player_health_changed"))
	player.connect(&"died", Callable(self, &"_on_player_died"))
	_on_player_health_changed(float(player.get("current_health")), float(player.get("max_health")))

	if features.experience_enabled:
		progression_system = _instantiate_feature(PROGRESSION_SCENE_PATH, module_container, &"ProgressionSystem")
		if progression_system != null:
			progression_system.connect(&"progress_changed", Callable(self, &"_on_progress_changed"))
			progression_system.connect(&"level_increased", Callable(self, &"_on_level_increased"))
			progression_system.call(&"configure", pickups_container, features.leveling_enabled)
			_on_progress_changed(1, 0, 5)

	if features.weapons_enabled:
		auto_weapon = _instantiate_feature(WEAPON_SCENE_PATH, player, &"AutoWeapon")
		if auto_weapon != null:
			auto_weapon.call(&"configure", projectiles_container)

	if features.enemies_enabled and features.spawning_enabled:
		enemy_spawner = _instantiate_feature(SPAWNER_SCENE_PATH, module_container, &"EnemySpawner")
		if enemy_spawner != null:
			enemy_spawner.connect(&"enemy_spawned", Callable(self, &"_on_enemy_spawned"))
			enemy_spawner.call(
				&"configure",
				player,
				enemies_container,
				features.damage_enabled,
				map_generator
			)

	var enabled_names := PackedStringArray()
	for module_id in features.enabled_module_ids():
		enabled_names.append(String(module_id))
	status_label.text = "활성 모듈: %s" % ", ".join(enabled_names)


func _process(delta: float) -> void:
	if run_ended:
		return

	elapsed_time += delta
	time_label.text = "시간 %s" % _format_time(elapsed_time)


func _unhandled_input(event: InputEvent) -> void:
	if not run_ended or not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
			_restart_run()


func _instantiate_feature(path: String, parent: Node, display_name: StringName) -> Node:
	if not ResourceLoader.exists(path):
		_report_configuration_error("기능 장면을 찾을 수 없습니다: %s" % path)
		return null

	var resource := load(path)
	if not resource is PackedScene:
		_report_configuration_error("PackedScene이 아닙니다: %s" % path)
		return null

	var instance := (resource as PackedScene).instantiate()
	instance.name = String(display_name)
	parent.add_child(instance)
	return instance


func _supports_map_generator(candidate: Node) -> bool:
	if not is_instance_valid(candidate) or not candidate.has_signal(&"map_generated"):
		return false

	for method_name in MAP_GENERATOR_METHODS:
		if not candidate.has_method(method_name):
			return false

	return true


func _on_enemy_spawned(enemy: Node) -> void:
	if enemy.has_signal(&"defeated"):
		enemy.connect(&"defeated", Callable(self, &"_on_enemy_defeated"))


func _on_map_generated(
	display_name: String,
	entry_cost: int,
	room_count: int,
	maximum_rooms: int,
	used_seed: int
) -> void:
	map_label.text = "%s 맵 · 투자 %d · 방 %d/%d · 시드 %d" % [
		display_name,
		entry_cost,
		room_count,
		maximum_rooms,
		used_seed
	]


func _on_enemy_defeated(reward: int, world_position: Vector2) -> void:
	defeated_enemies += 1
	kills_label.text = "처치 %d" % defeated_enemies

	if progression_system != null:
		progression_system.call(&"spawn_pickup", world_position, reward)


func _on_player_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [ceili(current), ceili(maximum)]


func _on_progress_changed(level: int, current: int, required: int) -> void:
	level_label.text = "레벨 %d" % level
	experience_bar.max_value = required
	experience_bar.value = current
	experience_label.text = "%d / %d" % [current, required]


func _on_level_increased(new_level: int) -> void:
	if auto_weapon != null:
		auto_weapon.call(&"apply_level", new_level)
	if player != null:
		player.call(&"heal", 12.0)


func _on_player_died() -> void:
	if not features.game_over_enabled:
		return

	run_ended = true
	game_over_summary.text = "생존 %s · 처치 %d" % [_format_time(elapsed_time), defeated_enemies]
	game_over_overlay.visible = true
	get_tree().paused = true


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _report_configuration_error(message: String) -> void:
	push_error(message)
	status_label.text = "설정 오류: %s" % message


func _format_time(seconds: float) -> String:
	var total_seconds := floori(seconds)
	var minutes := floori(float(total_seconds) / 60.0)
	return "%02d:%02d" % [minutes, total_seconds % 60]
