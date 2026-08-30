---
title: 내부 성장·장비 강화 Google Sheets 연동
description: RunBuff와 Upgrade 탭으로 내부 레벨업 선택지와 무기·방어구·모듈 성장 스펙을 실시간 시험하고 CSV로 확정하는 방법
tags:
  - 구글 시트
  - 내부 레벨업
  - 무기 강화
  - 방어구 강화
  - 모듈 강화
  - CSV
---

# 내부 성장·장비 강화 Google Sheets 연동

공용 [SFH_item_Balance Google Sheet](https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/edit?usp=sharing)에 `RunBuff`와 `Upgrade` 탭을 추가했습니다. 두 탭 모두 **1행 변수명, 2행 설명, 3행부터 데이터** 규칙을 사용하며 `runtime_enabled`가 체크된 행만 게임에 반영됩니다.

## 탭 역할

| 탭 | 키 | 담당 데이터 |
|---|---|---|
| `RunBuff` | `buff_id` | 내부 레벨업 선택지, 최대 중첩, 캐릭터·무기·방어구 효과, 즉시 회복 |
| `Upgrade` | `target_kind + target_id + level` | 무기·방어구·모듈의 레벨별 누적 효과, 최대 레벨, 모듈 장착 코스트와 강화 비용 |

`target_kind`는 `weapon`, `armor`, `module`만 허용합니다. `target_id`는 장비 Resource의 `weapon_id`, `armor_id`, `module_id`와 정확히 같아야 합니다.

## 레벨 행 해석

- 능력치와 모듈 장착 코스트는 해당 `level`에서 사용할 **누적 최종값**입니다.
- `credit_cost`와 `material_quantity`는 해당 `level`에서 다음 레벨로 올릴 때 드는 비용입니다.
- 최고 레벨 행의 강화 비용은 `0`으로 둡니다.
- 무기·방어구 레벨업은 현재 U 화면의 기존 흐름을 유지하며, 시트는 최대 레벨과 효과를 제공합니다.
- 모듈은 시트의 비용·동일 모듈 재료·크레딧 검사를 거쳐 강화합니다.
- 고유 파츠는 아직 `default_upgrade_costs.tres` 정책을 폴백으로 사용합니다.

예를 들어 `module / ballistic_core / 2` 행의 `module_capacity_cost = 3`은 Lv.2 장착 코스트이고, `credit_cost = 240`은 Lv.2→3 비용입니다.

## 게임 적용 경로

```text
RunBuff CSV → GrowthBalanceService → RunBuffCatalog → RunBuffSystem
Upgrade CSV → GrowthBalanceService → EquipmentSystem → Player / AutoWeapon
                                      └→ EquipmentUpgradeService
```

- 내부 성장: 최대 체력·방어력·이동 속도와 무기 피해·주기·거리 수정자를 생성합니다.
- 무기: 현재 무기 레벨의 시트 수정자를 `AutoWeapon`의 별도 `equipment_upgrade` 출처로 적용합니다.
- 방어구: 장비 스탯 집계에 현재 레벨의 플레이어 수정자를 더합니다.
- 모듈: 현재 강화 레벨의 장착 코스트, 플레이어·무기 수정자와 다음 강화 견적을 제공합니다.

## 실시간 테스트와 확정 CSV

작전 선택 화면의 `실시간 테스트`는 `Weapon`, `RunBuff`, `Upgrade` 공개 CSV를 기본 3초마다 갱신합니다. 행 오류나 네트워크 실패가 생기면 마지막 정상값을 유지하고, 시작부터 실패하면 저장소의 확정 CSV로 폴백합니다. 일반 실행과 배포의 기본값은 `확정 CSV`입니다.

시트 수정이 끝나면 저장소 루트에서 다음 명령으로 두 탭을 함께 확정합니다.

```powershell
.\scripts\growth-balance.cmd sync "1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM"
.\scripts\growth-balance.cmd check
.\scripts\test-game.cmd
```

동기화기는 필수 열, 중복 키, 허용 대상 종류, 레벨 범위와 음수 비용을 검사한 뒤 활성 행만 `game/features/growth_balance/data/`에 기록합니다.

## 모듈 경계와 제거

`growth_balance_enabled`를 끄면 내부 버프는 기존 `.tres` 카탈로그를, 파츠·모듈 강화는 기존 비용 Resource를 사용합니다. `GrowthBalanceService`는 장비·버프 내부 Node를 모르며 공개 메서드와 갱신 Signal만 제공합니다. 따라서 시트 로더를 다른 백엔드로 교체하거나 기능을 제거해도 각 시스템의 기본 동작은 유지됩니다.

## 검색 별칭

RunBuff 시트, Upgrade 시트, 성장 밸런스, 내부 버프 수치, 장비 레벨 수치, 무기 업그레이드, 방어구 업그레이드, 모듈 코스트, 실시간 성장 테스트, 확정 성장 CSV
