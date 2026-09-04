extends SceneTree

const LOADOUT_PATH := "res://game/features/equipment/loadouts/default_loadout.tres"
const EQUIPMENT_SCENE_PATH := "res://game/features/equipment/equipment_system.tscn"
const AUTO_WEAPON_SCENE_PATH := "res://game/features/weapons/auto_weapon.tscn"
const IDENTITY_CSV_PATH := "res://game/features/equipment/data/equipment_identity.csv"
const IDENTITY_TABLE_SCRIPT := preload("res://game/features/equipment/equipment_identity_table.gd")
const LOADOUT_CODEC_SCRIPT := preload("res://game/features/local_save/loadout_value_codec.gd")


class DummyStats extends Node:
	var equipment_modifiers: Dictionary = {}
	var runtime_sources: Dictionary = {}

	func apply_equipment_modifiers(modifiers: Dictionary) -> void:
		equipment_modifiers = modifiers.duplicate(true)

	func set_runtime_modifier_source(source_id: StringName, modifiers: Dictionary) -> void:
		runtime_sources[source_id] = modifiers.duplicate(true)


class DummyTarget extends Node:
	var received_damage: float = 0.0
	var contexts: Array[Dictionary] = []

	func take_damage(amount: float, context: Dictionary = {}) -> void:
		received_damage += amount
		contexts.append(context.duplicate(true))


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var stats := DummyStats.new()
	root.add_child(stats)
	var equipment: Node = load(EQUIPMENT_SCENE_PATH).instantiate()
	root.add_child(equipment)
	var loadout := load(LOADOUT_PATH) as EquipmentLoadout
	_assert(equipment.configure(loadout, stats), "장비 시스템을 구성하지 못했습니다.")

	var initial_identity: Dictionary = equipment.get_active_weapon_identity_snapshot()
	var identity_table = IDENTITY_TABLE_SCRIPT.new()
	_assert(identity_table.load_locked(IDENTITY_CSV_PATH), "장비 정체성 확정 CSV를 읽지 못했습니다.")
	for weapon_path in [
		"res://game/features/equipment/definitions/weapons/assault_rifle.tres",
		"res://game/features/equipment/definitions/weapons/service_pistol.tres",
		"res://game/features/equipment/definitions/weapons/combat_dagger.tres",
		"res://game/features/equipment/definitions/weapons/greatsword.tres",
		"res://game/features/equipment/definitions/weapons/pulse_rifle.tres",
	]:
		var weapon := load(weapon_path) as EquipmentWeaponDefinition
		var locked_weapon: Dictionary = identity_table.get_record(&"weapon", weapon.weapon_id)
		_assert(locked_weapon.get(&"innate_skill_id") == String(weapon.innate_skill.skill_id), "CSV와 무기 고유 스킬 정의가 다릅니다: %s" % weapon.weapon_id)
		_assert(locked_weapon.get(&"fixed_option_id") == String(weapon.fixed_options[0].option_id), "CSV와 무기 고정 옵션 ID가 다릅니다: %s" % weapon.weapon_id)
		_assert(is_equal_approx(float(locked_weapon.get(&"fixed_option_value", 0.0)), weapon.fixed_options[0].amount), "CSV와 무기 고정 옵션 값이 다릅니다: %s" % weapon.weapon_id)
	for armor_path in [
		"res://game/features/equipment/definitions/armor/tactical_vest.tres",
		"res://game/features/equipment/definitions/armor/runner_boots.tres",
	]:
		var armor := load(armor_path) as EquipmentArmorDefinition
		var locked_armor: Dictionary = identity_table.get_record(&"armor", armor.armor_id)
		_assert(locked_armor.get(&"fixed_option_id") == String(armor.fixed_options[0].option_id), "CSV와 방어구 고정 옵션 ID가 다릅니다: %s" % armor.armor_id)
		_assert(is_equal_approx(float(locked_armor.get(&"fixed_option_value", 0.0)), armor.fixed_options[0].amount), "CSV와 방어구 고정 옵션 값이 다릅니다: %s" % armor.armor_id)
	_assert(initial_identity.get(&"weapon_id") == &"assault_rifle", "기본 무기 정체성이 다릅니다.")
	_assert(initial_identity.get(&"scaling_policy") == &"fixed_identity", "고정 스케일 계약이 없습니다.")
	_assert(not (initial_identity.get(&"innate_skill", {}) as Dictionary).is_empty(), "무기 고유 스킬이 없습니다.")
	_assert(is_equal_approx(
		float((initial_identity.get(&"fixed_modifiers", {}) as Dictionary).get(&"damage_multiply", 0.0)),
		1.06
	), "돌격소총 고정 옵션이 적용되지 않았습니다.")

	var main_state := equipment.get_equipment_state(&"main") as EquipmentItemState
	var second_state := EquipmentItemState.new()
	second_state.configure(&"copy", loadout.main_weapon)
	_assert(
		main_state.get_fixed_identity_snapshot() == second_state.get_fixed_identity_snapshot(),
		"같은 무기의 두 인스턴스가 서로 다른 고유 스킬을 가집니다."
	)
	_assert(equipment.level_up_equipment(&"main"), "무기 외부 레벨을 올리지 못했습니다.")
	_assert(
		equipment.get_active_weapon_identity_snapshot() == initial_identity,
		"무기 레벨이 고유 스킬 또는 고정 옵션을 변형했습니다."
	)
	_assert(equipment.set_external_armor_level(8), "외부 방어구 레벨 설정이 실패했습니다.")
	_assert(
		equipment.get_active_weapon_identity_snapshot() == initial_identity,
		"외부 성장 상태가 무기 정체성을 변형했습니다."
	)
	_assert(is_equal_approx(
		float((stats.equipment_modifiers.get(&"max_health", {}) as Dictionary).get(&"add", 0.0)),
		35.0
	), "방어구 기본 25와 고정 옵션 10이 독립 합산되지 않았습니다.")

	var rolled_payload := {
		&"affixes": [{
			&"affix_id": &"damage_percent",
			&"display_name": "화력",
			&"stat_id": &"damage_multiply",
			&"rolled_value": 0.12,
		}],
	}
	_assert(
		equipment.equip_definition(&"main", loadout.main_weapon, rolled_payload),
		"제작·드랍 payload를 장비 옵션으로 부여하지 못했습니다."
	)
	var rolled_identity: Dictionary = equipment.get_active_weapon_identity_snapshot()
	var rolled_modifiers: Dictionary = rolled_identity.get(&"fixed_modifiers", {})
	_assert(is_equal_approx(float(rolled_modifiers.get(&"damage_multiply", 0.0)), 1.1872), "정의 옵션과 인스턴스 옵션이 독립 곱연산되지 않았습니다.")
	var rolled_skill: Dictionary = rolled_identity.get(&"innate_skill", {})
	_assert(rolled_skill == initial_identity.get(&"innate_skill", {}), "옵션 부여가 같은 무기의 고유 스킬을 바꿨습니다.")
	_assert(equipment.level_up_equipment(&"main"), "옵션 장비 레벨을 올리지 못했습니다.")
	_assert(
		(equipment.get_active_weapon_identity_snapshot().get(&"fixed_options", []) as Array)
		== (rolled_identity.get(&"fixed_options", []) as Array),
		"내부·외부 레벨이 인스턴스 고정 옵션을 변형했습니다."
	)
	var restored_stats := DummyStats.new()
	root.add_child(restored_stats)
	var restored_equipment: Node = load(EQUIPMENT_SCENE_PATH).instantiate()
	root.add_child(restored_equipment)
	_assert(restored_equipment.configure(loadout, restored_stats), "복원 대상 장비 시스템 구성이 실패했습니다.")
	_assert(restored_equipment.restore_runtime_state(equipment.export_runtime_state()), "장비 고정 옵션 저장 상태를 복원하지 못했습니다.")
	_assert(
		(restored_equipment.get_active_weapon_identity_snapshot().get(&"fixed_options", []) as Array)
		== (rolled_identity.get(&"fixed_options", []) as Array),
		"장비 저장·복원에서 획득 고정 옵션이 달라졌습니다."
	)
	var codec = LOADOUT_CODEC_SCRIPT.new()
	var encoded_state: Variant = codec.encode(equipment.export_runtime_state())
	_assert(codec.error.is_empty() and encoded_state != null, "고정 옵션·고유 스킬을 안전 저장 형식으로 인코딩하지 못했습니다.")
	var decoded_state: Variant = codec.decode(encoded_state)
	_assert(codec.error.is_empty() and decoded_state is Dictionary, "고정 옵션·고유 스킬을 안전 저장 형식에서 복원하지 못했습니다.")
	_assert(restored_equipment.restore_runtime_state(decoded_state), "직렬화된 장비 고정 정체성을 적용하지 못했습니다.")
	_assert(
		(restored_equipment.get_active_weapon_identity_snapshot().get(&"fixed_options", []) as Array)
		== (rolled_identity.get(&"fixed_options", []) as Array),
		"프로세스 저장 형식을 거치며 획득 고정 옵션이 달라졌습니다."
	)
	equipment.equip_state(&"main", main_state)

	var projectile_parent := Node2D.new()
	root.add_child(projectile_parent)
	var auto_weapon := load(AUTO_WEAPON_SCENE_PATH).instantiate() as AutoWeapon
	root.add_child(auto_weapon)
	auto_weapon.configure(projectile_parent, equipment, null)
	var before_growth: Dictionary = auto_weapon.get_runtime_snapshot()
	var fixed_skill: Dictionary = (before_growth.get(&"fixed_identity", {}) as Dictionary).get(&"innate_skill", {})
	_assert(is_equal_approx(float(before_growth.get(&"damage", 0.0)), 1.696), "고정 무기 옵션이 런타임 소스로 분리되지 않았습니다.")
	auto_weapon.apply_level(10)
	auto_weapon.set_runtime_modifiers(&"run_buff", {&"damage_multiply": 4.0})
	var after_growth: Dictionary = auto_weapon.get_runtime_snapshot()
	_assert(
		(after_growth.get(&"fixed_identity", {}) as Dictionary).get(&"innate_skill", {}) == fixed_skill,
		"내부 레벨 또는 런 버프가 고유 스킬 수치를 변형했습니다."
	)

	var innate := WeaponInnateSkillSystem.new()
	root.add_child(innate)
	var target := DummyTarget.new()
	root.add_child(target)
	_assert(not innate.resolve_confirmed_hit(target, Vector2.ZERO, initial_identity), "첫 명중에 고유 효과가 너무 일찍 발동했습니다.")
	_assert(not innate.resolve_confirmed_hit(target, Vector2.ZERO, initial_identity), "두 번째 명중에 고유 효과가 너무 일찍 발동했습니다.")
	_assert(innate.resolve_confirmed_hit(target, Vector2.ZERO, initial_identity), "세 번째 명중에 고유 효과가 발동하지 않았습니다.")
	_assert(is_equal_approx(target.received_damage, 1.5), "고유 스킬의 고정 피해가 정의값과 다릅니다.")
	_assert(target.contexts[0].get(&"fixed_identity_effect", false), "고유 스킬 피해 출처가 구분되지 않습니다.")

	print("EQUIPMENT_FIXED_IDENTITY_OK locked_csv weapon_options armor_options assigned_affix persistence same_weapon_same_skill run_level_invariant meta_level_invariant module_source_separate fixed_skill_damage impact_profile")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
	await process_frame
