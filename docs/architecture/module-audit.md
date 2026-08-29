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

탈출 모듈은 맵의 내부 자료구조 대신 월드 좌표 하나만 전달받습니다.

## 파밍과 크레딧 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 맵 | `get_loot_spawn_positions(count)` | `LootSpawner` |
| 상자 | `credits_collected(amount, world_position)` | `LootSpawner` |
| 파밍 | `credits_looted(amount, world_position)` | `Game` 조립부 |
| 원장 | `add_carried`, `secure_carried`, `lose_carried` | `Game` 조립부 |

맵은 파밍 보상 수치를 알지 않고, 파밍 모듈은 맵의 방 배열과 A* 자료구조를 알지 않습니다.

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
| 장비 | `equipment_changed(summary)` | HUD |
| 플레이어 | `apply_equipment_modifiers(modifiers)` | 장비 모듈 |

장비 모듈은 플레이어의 내부 Node 경로나 구체 클래스를 참조하지 않습니다. 스탯 적용 대상이 공개 메서드 하나를 구현하면 플레이어 이외의 캐릭터에도 같은 방어구 집계를 사용할 수 있습니다.

무기 태그와 스킬 요구 태그는 `WeaponTagProfile` 값 비교만 수행합니다. 스킬 효과는 `activation_payload`에 보관하되 현재 장비 시스템이 실행하지 않으므로, 향후 스킬 실행기와 작전 투입 비용 정책을 별도 모듈로 붙일 수 있습니다.

## 의도된 결합

- `Game`은 모듈 Scene의 문자열 경로와 조립 순서를 압니다.
- `EnemySpawner`는 기본 적 Scene을 참조합니다. 이는 `spawning → enemies` 선언 의존성입니다.
- `Game`은 기본 장비 Scene과 선택된 로드아웃 Resource 경로를 알고, 장비는 플레이어의 스탯 적용 공개 메서드만 압니다.
- 기존 `AutoWeapon`은 아직 장비 무기 정의의 공격 프로필을 소비하지 않습니다. 태그·장착 상태와 발사 동작을 분리한 과도기 구조입니다.
- 플레이어, 적, 투사체는 생성 벽용 충돌 레이어 `16`을 공유합니다.
- 맵 전용 스모크 테스트는 맵 기능 경로를 참조합니다. 맵 기능을 완전히 삭제하면 해당 테스트도 함께 제거하거나 교체해야 합니다.

이 결합은 숨겨진 의존성이 아니라 조립부, Manifest 검사, 문서에 드러난 계약으로 관리합니다.

## 다시 점검하는 방법

```powershell
.\scripts\test-game.cmd
.\scripts\wiki.cmd build
```

성공하면 출력에 `tier_entry`, `minimap`, `equipment`, `weapon_tags`, `skills_0_10`, `armor_stats`, `equipment_optional`, `realistic_obstacles`, `loot`, `credits`, `health_ui`, `status_bars`, `extraction_f`가 포함됩니다. 이는 세 등급 진입, 미니맵, 장비 태그·제한·방어구 스탯·비활성화, 실내 장애물, 1회성 파밍·회수, 양측 체력 UI와 F 탈출 계약이 함께 검증됐다는 뜻입니다.

## 다음 개선 시점

모듈이 더 늘어나 `Game`의 조립 코드가 커지면 기능마다 설치 객체를 두고 공통 `install(context)` 계약으로 옮깁니다. 현재 규모에서는 문자열 지연 로딩과 명시적 계약 검사가 더 단순하고 추적하기 쉽습니다.

## 검색 별칭

모듈 감사, 의존성 검사, 플러그인 구조, 기능 제거, 기능 교체, 맵 인터페이스, 선택 모듈, 결합도
