---
title: 지역·난이도 전리품 테이블
description: 지역·난이도·맵 규모·획득 출처로 전리품 후보를 고르고 작전 브리핑과 확정 CSV에 연결하는 타겟 파밍 모듈
tags:
  - 전리품
  - 드랍 테이블
  - 타겟 파밍
  - Google Sheets
  - CSV
  - 지역
  - 난이도
---

# 지역·난이도 전리품 테이블

## 플레이어에게 달라진 점

작전 지역과 난이도를 바꾸면 진입 화면의 `TARGET LOOT`가 즉시 달라집니다. 최대 3개의 대표 전리품, 후보 수, 최고 등급을 투입 전에 볼 수 있어 원하는 장비·도면을 노리고 지역을 선택할 수 있습니다.

현재 확정 데이터는 세 지역 27행입니다.

| 지역 | 목적 |
|---|---|
| `ruined_city` | 소총·도시 회수품 중심 |
| `industrial_district` | 방어구·산업 재료 중심 |
| `research_complex` | 모듈·연구 자산 중심 |

`standard`, `veteran`, `nightmare` 난이도와 `small`, `medium`, `large` 규모, `enemy`, `room_reward`, `vault`, `boss` 획득 출처를 조합합니다. 난이도 투자의 고등급 배율은 등급이 높을수록 가중치에 더 크게 반영됩니다.

## 기획 데이터 계약

공용 밸런스 문서의 `LootTable` 탭을 사용합니다. 다른 탭과 동일하게 1행은 변수명, 2행은 한국어 설명, 3행부터 개별 데이터입니다.

| 열 | 의미 |
|---|---|
| `entry_id` | 중복될 수 없는 드랍 행 ID |
| `region_id` / `difficulty_id` / `map_size` | 작전 조건 |
| `source_type` | 적·방 보상·금고·보스 구분 |
| `item_id` | `Item` 탭 생명 주기 정의와 연결되는 ID |
| `grade` / `base_weight` | 등급과 기본 추첨 가중치 |
| `minimum_quantity` / `maximum_quantity` | 획득 수량 범위 |
| `boss_only` | 보스가 보장된 작전에서만 허용 |
| `runtime_enabled` | 확정 CSV에 포함할지 여부 |
| `planner_note` | 기획 의도와 밸런스 메모 |

행을 추가할 때는 먼저 `Item` 탭에 같은 `item_id`와 해당 지역 태그가 있어야 합니다. 이 교차 검증에 실패하면 기존 정상 테이블을 유지하고 새 데이터를 거부합니다.

## 실시간 테스트와 확정 CSV

```powershell
.\scripts\loot-table.ps1 sync
.\scripts\loot-table.ps1 check
```

- 실시간 테스트: `LootTable` 공개 CSV를 3초 주기로 읽으며 오류 시 마지막 정상 데이터 또는 확정 CSV로 복구
- 확정 모드: `game/features/loot_tables/data/loot_table.csv`와 Web 내장 payload 사용
- 빌드 계약: Web·Windows 내보내기와 Windows 배포 메타데이터에 같은 CSV 포함
- 재현성: 같은 작전 seed·지역·난이도·규모·출처·추첨 순번은 같은 결과를 생성

## 모듈 경계

| 모듈 | 책임 |
|---|---|
| `LootDropEntry` | 한 행의 검증·조건 일치·유효 가중치 |
| `LootTable` | CSV 파싱과 중복·형식 검증 |
| `LootTableProvider` | 실시간/확정 소스, 후보 조회, 결정적 추첨, 브리핑 |
| `LootLifecycleService` | 아이템 정의와 탈출·사망 결과; 드랍 가중치를 모름 |
| `OperationSetupPresenter` | 제공된 브리핑만 표시; 추첨 규칙을 모름 |
| `Game` | 선택 기능 설치·Signal 연결·작전 context 전달만 담당 |

`FeatureManifest.loot_tables_enabled`로 독립 제거할 수 있습니다. 꺼지면 작전 선택과 기존 전리품 생명 주기는 유지되고 타겟 전리품 브리핑만 사라집니다.

## E2E 완료 기준

- 지역·난이도 변경이 다른 대표 전리품으로 보인다.
- 같은 입력 seed는 같은 아이템과 수량을 만든다.
- 고난이도 배율이 고등급 후보 가중치를 올린다.
- 모든 드랍 행이 `Item` 탭 정의와 지역 태그에 연결된다.
- Web 내보내기 CSV와 내장 payload가 동일하다.

현장 드랍 생성·가방 수용·탈출 반출까지 잇는 `P4-03`은 다음 작업입니다. 이 문서는 완료된 데이터 선택과 브리핑 계약만 완료로 표시합니다.

## 검색 별칭

지역 드랍, 난이도 드랍, LootTable, 타겟 파밍, 드랍 가중치, 보스 전리품, 확정 CSV, 실시간 시트, 전리품 후보
