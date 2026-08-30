---
title: 모듈화 점검 기록
description: 기능을 끄거나 교체할 수 있는지 코드와 자동 테스트로 확인한 기록
tags:
  - 모듈
  - 감사
  - 의존성
  - 인터페이스
  - 비활성화
---

# 모듈화 점검 기록

## 2026-08-30 화면 크기 방·전장의 안개·자원 회수 점검

| 점검 대상 | 결과 | 근거 |
|---|---|---|
| 화면 한 장급 방 | 통과 | 세 등급의 최소 방이 모두 40×23셀을 넘고 32px 타일 기준 1280×720 이상 |
| 실내 장애물 구조 | 통과 | 문 있는 긴 칸막이, 넓은 설비 블록, 다중 기둥을 방별 패턴으로 생성 |
| 전장의 안개 분리 | 통과 | 별도 Scene·Manifest 토글이며 추적 `Node2D`와 시야 설정만 소비 |
| 전체 미니맵 유지 | 통과 | 안개는 월드 layer 0에만 렌더링하고 미니맵은 전체 지형 스냅샷 크기를 유지 |
| 자원 배치 다양성 | 통과 | 맵은 위치·방향·유형 힌트, 파밍은 외형·문구·보상과 1회성 회수를 담당 |
| 자동·시각 검증 | 통과 | 세 등급 구조·경로·회수 유형, 안개 추적·전체 지도와 1280×720 렌더를 확인 |

전장의 안개는 맵 배열과 미니맵 텍스처에 접근하지 않으며, 파밍 오브젝트는 맵의 방·A* 내부 상태를 읽지 않습니다. 넓어진 방과 실내 패턴은 기존 `MapTierConfig`·맵 생성기 경계 안에 남아 있어 각 기능을 독립적으로 비활성화하거나 교체할 수 있습니다.

## 2026-08-30 장비·모듈 UI 재설계 점검

| 점검 대상 | 결과 | 근거 |
|---|---|---|
| U 화면 교체 가능성 | 통과 | UI Scene과 스크립트가 `equipment`, `inventory`, `upgrade` 제공자의 공개 메서드만 소비 |
| 장비 직접 선택 | 통과 | 가방 스냅샷의 `instance_id`를 선택하고 장비 승인 뒤에만 `take_item()` 호출 |
| 모듈·파츠 규칙 위임 | 통과 | UI는 `can_install_module`, `can_install_part` 결과만 표현하고 규칙을 복제하지 않음 |
| 강화 경제 분리 | 통과 | 선택 카드의 견적·강화는 `EquipmentUpgradeService` 계약으로 위임 |
| 표시 순서 | 통과 | 패널이 열릴 때 UI 형제 중 앞으로 이동해 미니맵·HUD와 겹치지 않음 |
| 자동 검증 | 통과 | 전체 화면 크기, 장비 카드, 모듈 카드, 장착 슬롯과 U 패널 계약을 스모크 테스트에서 확인 |

카드 색상·배치·필터는 표현 계층에만 있고 장비 장착, 소켓, 모듈 코스트, 강화 비용의 진실은 기존 상태·서비스 모듈에 남아 있습니다. 따라서 U 화면을 제거해도 기본 로드아웃과 I 가방은 유지되며, 동일 공개 계약을 구현한 다른 UI로 교체할 수 있습니다.

## 2026-08-30 맵·페이싱·이동·회복 점검

| 점검 대상 | 결과 | 근거 |
|---|---|---|
| 맵 규모 데이터 | 통과 | 세 등급의 방 수·면적·목표 시간·탈출 개방 시간을 `MapTierConfig` Resource로 관리 |
| 약 10분 런 페이싱 | 통과 | 9/10/11분 목표와 같은 시각의 탈출 잠금 해제를 데이터로 검증 |
| 탈출 시간 잠금 | 통과 | 탈출 Scene은 `set_locked()` 계약만 받고 등급 Resource나 Game 타이머를 모름 |
| 반응형 이동 | 통과 | `PlayerMovement.step_velocity()`가 가속·제동·역선회·회피 상태를 독립 계산 |
| 부분 체력 회복 | 통과 | 별도 Scene·설정 Resource·Manifest 토글, 체력 Signal과 공개 메서드만 소비 |
| 자동 검증 | 통과 | 세 맵 상향 기준, 이동 응답, 회피 속도, 회복 지연·65% 상한, 조기 탈출 거부를 확인 |

이동은 플레이어의 물리 충돌을 구현하지 않고 결과 속도만 반환합니다. 회복 모듈은 플레이어의 `current_health` 내부 필드나 장비를 직접 참조하지 않습니다. 따라서 이동 계산이나 회복 정책을 교체해도 맵·전투·장비 모듈은 유지됩니다.

## 2026-08-30 전체 기능 재점검

현재 개발된 기능은 **FeatureManifest로 선택 가능하고 공개 메서드·Signal·Resource 경계가 드러난 모듈 구조**입니다. 이번 점검에서 내부 경험치, 임시 버프, 외부 성장, 장비 강화 경제를 각각 별도 폴더와 토글로 추가했으며, 강화 서비스가 크레딧 내부 변수를 직접 읽던 지점도 `get_snapshot()` 공개 계약으로 교체했습니다.

| 점검 대상 | 결과 | 독립 비활성화·교체 근거 |
|---|---|---|
| 기존 맵·전투·장비·인벤토리·경제 | 통과 | 기존 토글·폴백 스모크 테스트 유지 |
| 내부 XP와 레벨 | 통과 | `experience`, `leveling` 토글과 `ProgressionSystem`으로 분리 |
| 한 판 임시 버프 | 통과 | `run_buffs` 토글, 카탈로그 Resource, 플레이어·무기 수정자 출처 계약 사용 |
| 외부 성장·저장 | 통과 | `meta_progression` 토글, 세 계열 스냅샷과 JSON 저장을 독립 담당 |
| 모듈·고유 파츠 강화 경제 | 통과 | 비용 정책, 인벤토리 소비, 크레딧 소비, 장비 상태 변경을 네 계약으로 분리 |
| 선택 모듈 조합 | 통과 | 성장 3개 모듈과 강화 경제를 끈 상태에서도 기본 경험치·장비 루프 유지 |
| 자동 검증 | 통과 | 버프 선택·중첩·외부 정산·세 계열 효과·재료/크레딧 소비를 스모크 테스트로 확인 |

`Game`은 여전히 모든 설치 순서를 아는 중앙 조립 지점입니다. 이는 의도된 결합이며 기능 구현은 포함하지 않습니다. 다만 설치 대상이 늘어 조립 코드가 커졌으므로 다음 대규모 기능 묶음을 추가하기 전에는 기능별 `install(context)` 설치 객체로 나누는 것이 권장됩니다. 현재 기능을 끄거나 교체하는 데 막히는 숨은 Node 경로 의존성은 발견되지 않았습니다.

## 2026-08-29 랜덤 맵 모듈

결론은 **MVP 단계에서 교체 가능한 선택 모듈로 분리되어 있음**입니다. 맵의 생성 알고리즘과 등급 데이터는 한 기능 폴더 안에 있고, 플레이어·적·무기 모듈은 `MapTierConfig`나 방 배열을 직접 알지 않습니다.

다만 현재 구조는 Godot 애드온 수준의 완전한 플러그인 시스템은 아닙니다. 최상위 `Game`이 기능 경로와 공개 계약을 알고 조립하는 경량 모듈 구조입니다.

## 점검표

| 항목 | 결과 | 근거 |
|---|---|---|
| 기능 폴더 응집도 | 통과 | 생성기, Scene, 등급 Resource가 `game/features/map_generation/`에 모여 있음 |
| 정적 의존성 격리 | 통과 | 다른 기능은 `MapTierConfig`와 맵 내부 Node 경로를 참조하지 않음 |
| 런타임 선택 로딩 | 통과 | `map_generation_enabled`가 켜진 경우에만 문자열 경로로 Scene을 로드함 |
| 비활성화 폴백 | 통과 | 맵을 끄면 원점 스폰, 원형 적 스폰, 직선 추적으로 복귀함 |
| 대체 구현 계약 검사 | 통과 | `Game`과 `EnemySpawner`가 필요한 Signal·메서드 존재 여부를 검사함 |
| 데이터 분리 | 통과 | 비용, 방 수, 방 크기는 소·중·대형 `.tres` Resource에서 변경 가능 |
| 자동 검증 | 통과 | 세 등급 연결성 및 맵 비활성화 조립을 스모크 테스트로 확인함 |
| 하위 기능 토글 | 통과 | 방해물, 작전 선택, 탈출을 각각 Manifest에서 비활성화할 수 있음 |
| 전투 상태 분리 | 통과 | 적 이동 코드와 체력·방어력·상태바 컴포넌트를 분리함 |
| 파밍 데이터 분리 | 통과 | 맵 Resource가 아닌 LootTierConfig가 상자 수와 보상을 소유함 |
| 1회성·회수 검증 | 통과 | 같은 상자의 중복 획득 차단과 탈출 회수까지 자동 테스트함 |
| 미니맵 경계 | 통과 | 미니맵은 맵 내부 객체 대신 복사된 지형 스냅샷만 소비함 |
| 전체 티어 진입 | 통과 | 소·중·대형 버튼 입력부터 플레이어·맵·탈출·미니맵 설치까지 자동 검증함 |
| 장비 데이터 분리 | 통과 | 무기·스킬·방어구·로드아웃을 독립 Resource로 정의함 |
| 무기 태그 확장성 | 통과 | enum 대신 3단계 StringName ID를 사용해 새 분류를 데이터로 추가함 |
| 스킬 호환성 | 통과 | 슬롯과 대·중·소분류가 모두 맞는 경우만 활성화하며 0~10개 제한을 검증함 |
| 방어구 스탯 확장성 | 통과 | 범용 stat_id와 더하기·곱하기 수정자를 집계함 |
| 장비 비활성화 | 통과 | 장비를 끄면 시스템·HUD·스탯 적용 없이 플레이어 기본값을 유지함 |
| 격자 인벤토리 경계 | 통과 | 가변 크기 아이템의 경계·겹침·이동과 모듈 1×1 규칙을 독립 테스트함 |
| 장비 슬롯 규칙 | 통과 | 메인·보조·신체·신발 슬롯이 태그와 방어구 위치를 검사함 |
| 고유 파츠 격리 | 통과 | 무기 소분류와 소켓이 모두 맞는 경우만 파츠를 허용하고 방어구는 거부함 |
| 모듈 코스트·강화 | 통과 | 슬롯·코스트 초과 거부와 강화 단계별 코스트 감소를 검증함 |
| 최고 레벨 개조 | 통과 | 최고 레벨에서만 태그를 부여하고 일치 모듈 코스트를 50%로 계산함 |
| 장비 개조 의존성 | 통과 | `equipment_customization`이 `equipment`, `inventory`를 요구함 |
| 활성 무기 상태 분리 | 통과 | 장비는 main/secondary 슬롯과 `weapon_id`만 공개하고 발사 로직을 모름 |
| 밸런스 데이터 분리 | 통과 | `weapon_balance/`가 2행 설명을 포함한 Google Sheets·확정 CSV 로드와 검증만 담당함 |
| 실시간 실패 폴백 | 통과 | 잘못된 외부 CSV가 마지막 정상값을 덮지 않으며 확정 CSV로 복구 가능 |
| 무기 특색 실행 | 통과 | `AutoWeapon`이 버스트·다중 투사체를, Projectile이 관통·유지율을 담당함 |
| Q 교체 자동 검증 | 통과 | 장비 슬롯, 자동 공격 런타임, HUD가 같은 보조 권총 상태로 전환됨 |

## 맵 모듈 공개 계약

대체 맵 Scene도 아래 계약만 제공하면 소비자 코드를 유지할 수 있습니다.

| 종류 | 이름 | 소비자 |
|---|---|---|
| Signal | `map_generated(display_name, entry_cost, room_count, maximum_rooms, used_seed)` | HUD |
| Method | `configure_obstacles(is_enabled)` | 방해물 기능 토글 전달 |
| Method | `generate(config, requested_seed)` | `Game` 조립부 |
| Method | `get_player_spawn_position()` | 플레이어 배치 |
| Method | `get_extraction_position()` | 탈출 모듈 배치 |
| Method | `get_enemy_spawn_position(origin, minimum_distance)` | 적 생성기 |
| Method | `get_loot_spawn_points(count)` | 파밍 위치·벽 방향·배치 유형 제공 |
| Method | `get_world_path(from_world, to_world)` | 적 이동 |
| Method | `get_minimap_snapshot()` | 전술 미니맵 조립부 |

소비자는 구체 클래스 대신 `Node`와 위 메서드의 존재 여부를 사용합니다. 따라서 다른 알고리즘으로 맵 생성기를 교체할 때도 계약만 유지하면 됩니다.

## 탈출 모듈 공개 계약

| 종류 | 이름 | 소비자 |
|---|---|---|
| Signal | `extraction_completed(actor)` | 작전 결과 처리 |
| Signal | `interaction_availability_changed(available, prompt)` | HUD F 안내 |
| Method | `configure(world_position)` | 탈출 위치 배치 |
| Method | `request_extraction(actor)` | 범위와 플레이어 검사 |
| Method | `set_locked(is_locked, prompt)` | 조립부에서 시간 잠금 상태 전달 |

탈출 모듈은 맵의 내부 자료구조 대신 월드 좌표 하나만 전달받습니다.

## 플레이어 이동·회복 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 이동 | `step_velocity(current, input, delta, dash_pressed)` | 플레이어 물리 이동·자동 테스트 |
| 이동 | `get_movement_snapshot()` | 플레이어·향후 이동 HUD |
| 플레이어 | `health_changed`, `get_health_snapshot()`, `heal()` | 부분 회복 모듈 |
| 부분 회복 | `configure`, `advance`, `get_snapshot` | `Game` 조립부·자동 테스트 |

## 파밍과 크레딧 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 맵 | `get_loot_spawn_points(count)` | `LootSpawner` |
| 회수 지점 | `configure(amount, kind, facing)`, `credits_collected` | `LootSpawner` |
| 파밍 | `credits_looted(amount, world_position)` | `Game` 조립부 |
| 원장 | `add_carried`, `secure_carried`, `lose_carried` | `Game` 조립부 |

맵은 파밍 보상 수치를 알지 않고, 파밍 모듈은 맵의 방 배열과 A* 자료구조를 알지 않습니다.

## 전장의 안개 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 안개 | `configure(tracked_actor)` | `Game` 조립부 |
| 안개 | `get_snapshot()` | 자동 테스트·향후 옵션 UI |
| 플레이어 | `Node2D` 화면 좌표 | 안개 Shader 초점 |

안개는 CanvasLayer 0, HUD·미니맵은 별도 UI CanvasLayer에 있어 월드 시야 제한이 전체 미니맵 데이터나 모달 UI를 가리지 않습니다.

## 미니맵 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 맵 | `get_minimap_snapshot()` | `Game` 조립부 |
| 미니맵 | `configure(snapshot, tracked_actor, display_name)` | `Game` 조립부 |

스냅샷에는 셀 경계, 셀 크기, 바닥·방해물 좌표, 시작·탈출 위치만 들어갑니다. 미니맵은 맵의 방 배열, 길찾기 객체, 구체 클래스에 접근하지 않습니다.

## 캐릭터 장비 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 장비 | `configure(loadout, stats_target, weapons, skills, armor)` | `Game` 조립부 |
| 장비 | `get_active_skill_ids`, `get_inactive_skill_ids` | HUD와 향후 스킬 실행기 |
| 장비 | `get_stat_modifiers`, `get_summary` | HUD와 테스트 |
| 장비 | `can_equip_definition`, `equip_definition` | U 장비 화면 |
| 장비 | `install_part`, `install_module`, `upgrade_module` | U 파츠·모듈 화면 |
| 장비 | `level_up_equipment`, `grant_module_tag` | 성장·개조 UI와 향후 경제 모듈 |
| 장비 | `equipment_changed(summary)` | HUD |
| 장비 | `customization_changed(snapshot)` | U 장비 상태 표시 |
| 장비 | `get_active_weapon`, `switch_active_weapon` | Q 입력과 자동 무기 |
| 장비 | `active_weapon_changed(slot, definition)` | 자동 무기와 HUD |
| 플레이어 | `apply_equipment_modifiers(modifiers)` | 장비 모듈 |

장비 모듈은 플레이어의 내부 Node 경로나 구체 클래스를 참조하지 않습니다. 스탯 적용 대상이 공개 메서드 하나를 구현하면 플레이어 이외의 캐릭터에도 같은 방어구 집계를 사용할 수 있습니다.

## 무기 밸런스 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 밸런스 | `configure(config)`, `get_weapon_balance(weapon_id)` | `Game`, `AutoWeapon` |
| 밸런스 | `balance_updated(snapshot, source_label)` | 자동 무기 런타임 갱신 |
| 밸런스 | `balance_error(message)` | 경고와 확정 CSV 폴백 |
| 자동 무기 | `configure(projectiles, equipment, balance)` | `Game` 조립부 |
| 자동 무기 | `weapon_runtime_changed(snapshot)` | HUD |

밸런스 서비스는 장비 Resource나 투사체 Scene을 참조하지 않습니다. 자동 무기는 `weapon_id`로 행을 조회할 뿐 Google Sheets URL·CSV 파일 경로를 알지 않으며, 투사체는 발사 순간 전달된 속도·피해·관통 값만 사용합니다.

무기 태그와 스킬 요구 태그는 `WeaponTagProfile` 값 비교만 수행합니다. 스킬 효과는 `activation_payload`에 보관하되 현재 장비 시스템이 실행하지 않으므로, 향후 스킬 실행기와 작전 투입 비용 정책을 별도 모듈로 붙일 수 있습니다.

## 격자 인벤토리 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 가방 | `configure(catalog)` | `Game` 조립부 |
| 가방 | `can_place`, `move_item`, `find_first_space` | 격자 UI와 향후 드래그 조작 |
| 가방 | `add_item`, `take_item`, `get_items_by_type` | 파밍·장비·소비 시스템 |
| 가방 | `get_snapshot`, `inventory_changed(snapshot)` | I 가방 UI와 U 장비 UI |
| I/U 패널 | `configure`, `open_panel`, `close_panel` | `Game`과 모달 전환 |

가방은 장비 클래스나 태그를 모르며 `InventoryItemDefinition.linked_resource`를 보존하기만 합니다. 장착 성공 여부와 아이템 제거 순서는 U 화면이 공개 계약을 통해 조정합니다.

## 로그라이크 성장 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 내부 레벨 | `level_gained`, `get_run_snapshot` | `Game`, 버프 선택 흐름 |
| 임시 버프 | `prepare_choices`, `select_buff`, `get_snapshot` | 선택 UI와 조립부 |
| 임시 버프 | `get_meta_experience_breakdown` | 외부 성장 |
| 플레이어 | `set_runtime_modifier_source(source, modifiers)` | 장비·임시 버프·외부 캐릭터 성장 |
| 자동 무기 | `set_runtime_modifiers(source, modifiers)` | 임시 버프·외부 무기 성장 |
| 외부 성장 | `settle_run`, `apply_to_targets`, `get_snapshot` | 작전 종료 조립부 |
| 장비 | `set_external_armor_level(level)` | 외부 방어구 성장 |

버프와 외부 성장은 서로의 구체 클래스를 참조하지 않습니다. 선택 수량을 `{ character, weapon, armor }` 스냅샷으로 넘기며, 효과는 출처 ID별 수정자로 합산됩니다.

## 장비 강화 경제 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 장비 | `get_upgrade_context`, `upgrade_module`, `upgrade_part` | 강화 서비스 |
| 인벤토리 | `find_instance_ids_by_resource`, `consume_linked_resource` | 강화 서비스 |
| 크레딧 | `get_snapshot`, `can_spend_carried`, `spend_carried` | 강화 서비스 |
| 비용 정책 | `quote`, `validation_errors` | 강화 서비스 |
| 강화 서비스 | `quote_upgrade`, `upgrade` | U 장비 화면 |

장비는 가격이나 가방을 모르고, 가방은 강화 단계나 장비 슬롯을 모릅니다. 따라서 비용표·재화 종류·재료 정책을 교체해도 장비 상태 모델을 유지할 수 있습니다.

## 의도된 결합

- `Game`은 모듈 Scene의 문자열 경로와 조립 순서를 압니다.
- `EnemySpawner`는 기본 적 Scene을 참조합니다. 이는 `spawning → enemies` 선언 의존성입니다.
- `Game`은 기본 장비 Scene과 선택된 로드아웃 Resource 경로를 알고, 장비는 플레이어의 스탯 적용 공개 메서드만 압니다.
- `Game`은 인벤토리 카탈로그와 I/U 패널 Scene 경로를 알고, 가방과 장비 시스템은 서로의 내부 Node 경로를 참조하지 않습니다.
- `Game`은 장비, 밸런스, 자동 무기의 조립 순서를 알지만 각 모듈은 서로의 내부 Node 경로를 참조하지 않습니다.
- `Game`은 내부 레벨 → 버프 선택 → 외부 정산 순서와 장비 → 가방·원장 → 강화 서비스 순서를 압니다.
- 플레이어, 적, 투사체는 생성 벽용 충돌 레이어 `16`을 공유합니다.
- 맵 전용 스모크 테스트는 맵 기능 경로를 참조합니다. 맵 기능을 완전히 삭제하면 해당 테스트도 함께 제거하거나 교체해야 합니다.

이 결합은 숨겨진 의존성이 아니라 조립부, Manifest 검사, 문서에 드러난 계약으로 관리합니다.

## 다시 점검하는 방법

```powershell
.\scripts\test-game.cmd
.\scripts\wiki.cmd build
```

성공하면 출력에 `screen_sized_rooms`, `indoor_structures`, `fog_of_war`, `minimap_full_map`, `resource_recovery`, `run_experience`, `run_buffs`, `meta_experience`, `part_upgrade`, `upgrade_credits`, `modular_progression`이 기존 검증 항목과 함께 포함됩니다.

## 다음 개선 시점

다음 대규모 기능 묶음을 추가하기 전 `Game`의 설치 코드를 기능별 설치 객체로 옮기고 공통 `install(context)` 계약을 도입합니다. 문자열 지연 로딩과 명시적 메서드 검사는 유지합니다.

## 검색 별칭

모듈 감사, 의존성 검사, 플러그인 구조, 기능 제거, 기능 교체, 맵 인터페이스, 선택 모듈, 결합도, 인벤토리 계약, 장비 개조 계약
