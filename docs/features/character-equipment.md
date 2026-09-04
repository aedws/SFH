---
title: 캐릭터 장비와 로드아웃
description: 메인·보조 무기 태그, 호환 스킬, 범용 방어구 스탯을 데이터로 조립하는 장비 모듈
tags:
  - 장비
  - 로드아웃
  - 무기 태그
  - 스킬
  - 방어구
  - 스탯
  - 메인 무기
  - 보조 무기
---

# 캐릭터 장비와 로드아웃

## 현재 구현 범위

장비 데이터와 장착 규칙을 `game/features/equipment/`에 분리했습니다. 기본 작전에는 다음 로드아웃이 적용됩니다.

| 구분 | 장비 | 분류 또는 효과 |
|---|---|---|
| 메인 무기 | 돌격소총 | 원거리 > 화기 > 소총 |
| 보조 무기 | 제식 권총 | 원거리 > 화기 > 권총 |
| 스킬 | 소총 점사 | 메인 소총과 완전 일치해 활성 |
| 스킬 | 권총 속사 | 보조 권총과 완전 일치해 활성 |
| 스킬 | 단검 쇄도 | 맞는 단검이 없어 비활성 |
| 몸 방어구 | 전술 방탄복 | 기본 최대 체력 +25·방어 +3, 고정 옵션 최대 체력 +10 |
| 발 방어구 | 기동 전투화 | 기본 이동 속도 +20, 고정 옵션 이동 속도 +12 |

HUD에는 메인·보조 무기의 세 단계 분류, 현재 활성 슬롯, 활성 스킬 수, 방어구 수와 방어력이 표시됩니다. 작전 중 `Q`로 활성 무기를 교체합니다.

거점의 U/E 화면에서는 무기·방어구를 직접 장착·교체·해제합니다. `EquipmentItemState`를 장비 정의와 함께 가방에 반환하므로 장비 레벨, 개조 태그, 장착 모듈·파츠가 교체 과정에서 사라지지 않습니다. 준비 상태는 전투 세션 진입과 거점 귀환 사이에 유지됩니다.

무기 고유 스킬과 무기·방어구 고정 옵션도 같은 상태에 보존됩니다. 이 값은 내부 런 레벨, 외부 영구 레벨, 품질, 모듈 강화와 분리되며 상세 규칙은 [무기 고유 스킬과 장비 고정 옵션](equipment-fixed-identity.md)에서 확인합니다.

가방 점유 크기와 I 화면은 [격자 가방 인벤토리](grid-inventory.md), U 화면의 슬롯 태그·고유 파츠·모듈 강화·최고 레벨 개조는 [장비 파츠·모듈 개조](equipment-customization.md)에서 이어서 설명합니다.

## 무기 분류 구조

`WeaponTagProfile`은 세 개의 `StringName` ID로 무기를 분류합니다.

1. 대분류: `melee`, `ranged`
2. 중분류: `cold_weapon`, `firearm`
3. 소분류: `dagger`, `greatsword`, `pistol`, `rifle` 등

분류를 enum으로 고정하지 않았기 때문에 활, 산탄총, 마법 도구처럼 새 분류가 생겨도 코드 수정 없이 Resource에 새 ID를 입력할 수 있습니다. 사용자에게 보이는 한국어 이름은 각 단계의 `label` 필드에 따로 둡니다.

예시 무기 Resource는 아래 경로에 있습니다.

```text
game/features/equipment/definitions/weapons/
├─ assault_rifle.tres
├─ service_pistol.tres
├─ combat_dagger.tres
└─ greatsword.tres
```

## 메인 무기와 보조 무기

`EquipmentLoadout`이 `main_weapon`과 `secondary_weapon` 슬롯을 소유합니다. 슬롯은 장비 배치만 정의하며 실제 공격 방식은 강제하지 않습니다.

`AutoWeapon`은 장비 시스템의 활성 슬롯 변경 Signal을 받고, 같은 `weapon_id`를 가진 [무기 밸런스](weapon-balance.md) 행으로 발사 패턴을 바꿉니다. 장비 Resource는 분류·장착 규칙, 밸런스 CSV는 전투 수치를 담당합니다.

## 스킬 활성 조건

스킬은 다음 조건을 모두 만족할 때만 활성 상태가 됩니다.

- 스킬이 요구하는 무기 슬롯이 맞음: 메인, 보조 또는 둘 중 하나
- 무기 대분류가 정확히 같음
- 무기 중분류가 정확히 같음
- 무기 소분류가 정확히 같음

한 단계라도 다르면 장착은 유지하지만 비활성 목록으로 이동합니다. 따라서 로비 UI에서 잘못된 조합을 보여주거나 무기 교체 후 자동으로 활성 상태를 다시 계산할 수 있습니다.

`EquipmentLoadout`은 스킬 **0개부터 10개까지** 허용합니다. 11개 이상, 중복 스킬 ID, 유효하지 않은 태그 정의는 검증 오류입니다.

현재 스킬 모듈은 호환성과 활성 상태만 판정합니다. 쿨다운, 자원 소모, 실제 효과는 확정되지 않았으므로 `activation_payload`에 효과 ID 같은 확장 데이터만 보관하고 실행하지 않습니다.

## 방어구와 범용 스탯

방어구는 고정된 체력 전용 필드 대신 `EquipmentStatModifier` 배열을 가집니다.

| 필드 | 의미 |
|---|---|
| `stat_id` | 수정할 스탯 ID |
| `operation` | 더하기 또는 곱하기 |
| `amount` | 적용 값 |

현재 플레이어 기본 스탯은 `max_health`, `defense`, `movement_speed`입니다. 알려지지 않은 새 `stat_id`도 플레이어의 런타임 스탯 Dictionary에 보존되므로 치명타율, 회피율, 재장전 속도 등을 추가할 때 장비 시스템을 수정할 필요가 없습니다.

방어력은 현재 받은 피해에서 고정 수치만큼 차감하며 최소 피해는 1입니다. 이 공식은 임시 규칙이므로 이후 별도 피해 계산 모듈로 교체할 수 있습니다.

## 투입 경제와 분리

장비 시스템은 크레딧을 직접 차감하지 않습니다. 작전 계약 서비스가 지역·난이도·맵 비용을 계산하고 승인된 로드아웃만 전투 세션에 전달합니다. 사망 시에는 세션 조립부가 장비의 준비 상태 공개 계약을 비우며, 파산 방지 기본 무장은 장비 기본값으로 다시 설치됩니다. 따라서 장비 호환성과 경제·손실 정책을 독립적으로 교체할 수 있습니다.

## 기능 토글

`FeatureManifest`에서 다음 항목을 독립적으로 관리합니다.

- `equipment_enabled`: 전체 장비 시스템
- `equipment_weapons_enabled`: 메인·보조 무기 슬롯
- `equipment_skills_enabled`: 스킬 호환성 판정
- `equipment_armor_enabled`: 방어구 스탯 적용
- `inventory_enabled`: I 키 격자 가방
- `equipment_customization_enabled`: U 키 파츠·모듈 개조 화면
- `equipment_loadout_path`: 사용할 로드아웃 `.tres`

스킬은 장착 무기가 필요하므로 `equipment_skills → equipment_weapons → equipment` 의존성을 가집니다. 방어구는 `equipment`에만 의존하며, 장비 개조 화면은 `equipment_customization → equipment + inventory` 의존성을 가집니다.

## 공개 계약

`CharacterEquipmentSystem`은 다음 메서드와 Signal만 조립부에 공개합니다.

- `configure(loadout, stats_target, weapons_enabled, skills_enabled, armor_enabled)`
- `get_active_skill_ids()`
- `get_inactive_skill_ids()`
- `get_stat_modifiers()`
- `get_summary()`
- `get_equipment_state(slot_id)`
- `can_equip_definition(slot_id, definition)`, `equip_definition(...)`, `equip_state(...)`
- `take_equipment_state(slot_id)`
- `install/uninstall_part(...)`, `install/uninstall_module(...)`, `upgrade_module(...)`
- `export_runtime_state()`, `restore_runtime_state(...)`
- `level_up_equipment(...)`, `grant_module_tag(...)`
- `get_active_weapon_slot()`, `get_active_weapon()`
- `get_active_weapon_fixed_modifiers()`, `get_active_weapon_identity_snapshot()`
- `switch_active_weapon()`, `set_active_weapon_slot(slot_id)`
- `equipment_changed(summary)` Signal
- `customization_changed(snapshot)` Signal
- `active_weapon_changed(slot_id, weapon_definition)` Signal
- `weapon_fixed_identity_changed(snapshot)` Signal

방어구 적용 대상은 구체 플레이어 클래스를 요구하지 않고 `apply_equipment_modifiers(modifiers)` 메서드만 제공하면 됩니다.

## 새 장비 추가 순서

1. 대응하는 `definitions/` 하위 폴더에서 기존 `.tres`를 복제합니다.
2. 고유 ID, 표시 이름, 태그 또는 스탯 수정자를 변경합니다.
3. 사용할 `EquipmentLoadout` Resource에 추가합니다.
4. `./scripts/test-game.cmd`로 태그와 제한 검사를 실행합니다.

## 검색 별칭

캐릭터 장비, 인벤토리, 로드아웃, 주무기, 부무기, 메인 무기, 보조 무기, 근접, 원거리, 냉병기, 화기, 단검, 대검, 권총, 소총, 스킬 슬롯, 방어구 스탯, 장비 모듈, 파츠, 강화, 개조
