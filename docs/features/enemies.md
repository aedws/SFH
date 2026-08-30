---
title: 적과 증원형 생성 시스템
description: 맵 등급별 목표 개체 수와 총 생성 한계를 적용하는 핵앤슬래시 증원 구조
tags:
  - 적
  - 추적
  - 스폰
  - 증원
  - 핵앤슬래시
  - 난이도
  - 재생성 한계
---

# 적과 증원형 생성 시스템

## 플레이 흐름

기본 작전에서는 일반 방 진입을 감지한 `RoomEncounterSystem`이 등급별 적 무리를 요청합니다. 적이 생성되면 문이 닫히고 해당 무리를 전멸할 때까지 교전이 유지됩니다. 모든 방의 누적 생성량은 작전별 **총 생성 한계**를 넘기지 않습니다.

같은 생성 지점이 요청되더라도 생성기는 기존 적과 **40px 이상** 떨어진 걸을 수 있는 후보를 먼저 찾습니다. 이동 중에는 적마다 주변 **44px·최대 8명**만 살펴 추적 방향에 부드러운 분리 조향을 합성합니다. 충돌 직경 안쪽에서는 분리를 우선하므로 같은 위치에 포개진 채 플레이어를 추적하지 않습니다.

`room_encounters`를 끈 폴백에서는 기존처럼 목표 동시 개체 수의 75% 이하에서 묶음 증원이 작동합니다. 따라서 방 잠금형 구조와 개방형 핵앤슬래시 증원 구조를 모듈 토글 하나로 비교할 수 있습니다. 두 방식 모두 최초 배치부터 총 생성량에 포함하며 예산을 모두 사용하면 더는 재생성하지 않습니다.

적 사망 Signal은 경험치와 별도로 [전투 에너지·충전·회복 드랍](combat-resources.md)에 전달됩니다. 처치 위치에 에너지·체력 결정을 생성하지만 적 스크립트 자체는 드랍률이나 회복량을 알지 않습니다.

## 등급별 수량

| 작전 | 목표 동시 개체 수 | 총 생성 한계 | 1회 증원 | 증원 간격 | 생성 반경 |
|---|---:|---:|---:|---:|---:|
| 소형 | 24~36 중 무작위 | 120 | 6~10 | 1.2초 | 620px |
| 중형 | 36~54 중 무작위 | 220 | 8~12 | 1.0초 | 700px |
| 대형 | 52~72 중 무작위 | 360 | 10~16 | 0.85초 | 780px |

위 표는 전역 증원 폴백 정책입니다. 기본 방 전투의 방당 수량은 [방 진입 전투와 봉쇄 보상](room-encounters.md)을 확인합니다.

수치는 `game/features/spawning/configs/`의 `EnemySpawnTierConfig` Resource에서 변경합니다. 적 체력·방어력·이동 속도 같은 개체 능력치는 `game/features/enemies/`에 남아 있으므로 생성 밀도와 적 밸런스를 따로 조정할 수 있습니다.

## 군중 분리 조정

`game/features/enemies/configs/default_enemy_crowd.tres`의 `EnemyCrowdConfig`에서 아래 값을 코드 변경 없이 조정합니다.

| 값 | 기본값 | 역할 |
|---|---:|---|
| `minimum_spawn_spacing` | 40px | 새 적이 기존 적과 확보해야 하는 생성 간격 |
| `spawn_search_attempts` | 20회 | 걸을 수 있는 대체 위치를 나선형으로 찾는 최대 횟수 |
| `separation_radius` | 44px | 이동 중 이웃을 감지하는 반경 |
| `separation_strength` | 1.25 | 추적 방향에 합성하는 분리 힘 |
| `maximum_neighbors` | 8명 | 적 하나가 한 번에 계산하는 가까운 이웃 상한 |
| `steering_update_interval` | 0.08초 | 적별 분리 조향 갱신 간격 |

`enabled`를 끄거나 Resource를 제거하면 생성 위치와 직선 추적 폴백을 유지합니다. 적끼리 물리 충돌을 직접 켜 좁은 통로를 막는 방식이 아니라 조향만 합성하므로, 문과 통로를 통과하는 핵앤슬래시 흐름도 보존합니다. 안전한 생성 후보를 찾지 못하면 해당 요청을 취소해 겹친 위치에 억지로 생성하지 않습니다.

## 모듈 경계

- 생성 정책: 최소·최대 개체 수, 총 생성 한계, 증원 묶음, 간격, 반경
- `EnemySpawner`: 이번 판 목표 선택, 자신이 생성한 적과 누적 생성량 추적, 유한 증원 실행
- `EnemyCrowdConfig`: 생성 간격, 분리 반경·강도·갱신 예산을 소유하는 교체 가능 정책
- `RoomEncounterSystem`: 전역 증원을 일시 정지하고 방 내부 위치에 적 무리를 요청
- 맵: 걸을 수 있고 플레이어에게서 충분히 떨어진 생성 위치 제공
- 적: 이동, 길찾기, 체력·방어력, 접촉 피해와 사망 Signal
- 자동 무기: `get_active_targets()`로 전달받은 후보만 조준
- `Game`: 정책과 제공자를 연결하지만 수량 계산은 수행하지 않음

생성기는 더 이상 SceneTree 전체의 `enemies` 그룹 개수를 세지 않습니다. 자신이 생성한 인스턴스만 추적하므로 다른 생성기, 보스, 훈련용 표적이 수량 계산에 섞이지 않습니다.

## 공개 계약

| 제공자 | 계약 | 소비자 |
|---|---|---|
| 적 생성기 | `configure(...)` | `Game` 조립부 |
| 적 생성기 | `get_snapshot()` | HUD·자동 테스트 |
| 적 생성기 | `get_active_targets()` | 자동 무기 |
| 적 생성기 | `spawn_enemy_at`, `get_remaining_spawn_budget` | 방 전투 |
| 적 생성기 | `get_separation_vector(requester, position, radius, maximum_neighbors)` | 적 이동 |
| 적 생성기 | `set_reinforcement_paused` | 방 전투·향후 보스전 |
| 적 생성기 | `enemy_spawned`, `reinforcement_dispatched`, `spawn_budget_exhausted` | 전투 흐름·향후 연출 |
| 맵 | `get_enemy_spawn_position(origin, distance)` | 적 생성기 |

## 활성화와 의존성

`FeatureManifest`의 `enemies_enabled`, `spawning_enabled`, `room_encounters_enabled`로 분리합니다. `room_encounters`는 맵과 생성기가 필요합니다. 방 전투를 끄면 같은 총 예산을 사용하는 전역 증원 정책으로 돌아갑니다.

## 검색 별칭

몬스터, 좀비, 적 생성, 스폰 속도, 웨이브, 리스폰, 재생성 한계, 총 스폰 수, 증원군, 동시 적 수, 적 겹침, 몹 겹침, 군중 분리, 스폰 간격, 핵앤슬래시, 워프레임, 퍼스트 디센던트
