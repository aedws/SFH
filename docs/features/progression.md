---
title: 내부·외부 로그라이크 성장
description: 한 판 안의 임시 버프 선택과 종료 후 캐릭터·무기·방어구 영구 성장
tags:
  - 경험치
  - 로그라이크
  - 내부 성장
  - 외부 성장
  - 임시 버프
---

# 내부·외부 로그라이크 성장

## 전체 흐름

```text
적 사망 → 경험치 결정 획득 → 내부 레벨업 → 3개 임시 버프 중 1개 선택
                                              ↓
작전 종료 → 선택한 버프 수를 계열별 외부 경험치로 정산 → 영구 레벨 적용·저장
```

내부 경험치와 버프는 현재 한 판에서만 유효합니다. 외부 경험치와 레벨은 작전 종료 시 정산하며 `user://sfh_meta_progression.json`에 저장합니다. 탈출과 사망 모두 정산 대상이며, 테스트 실행은 실제 저장 파일을 건드리지 않습니다.

## 내부 성장

`ProgressionSystem`이 경험치·내부 레벨을 관리하고, 레벨이 오르면 `RunBuffSystem`이 선택 가능한 버프를 준비합니다. `RunBuffSelector`는 게임을 일시정지하고 최대 3개 선택지를 표시합니다.

내부 레벨이 오를 때마다 플레이어는 **HP 12를 즉시 회복**합니다. 이 기본 회복은 임시 버프 선택과 별도이므로 `run_buffs`를 꺼도 유지되고, 이후 선택한 `생존 본능`의 즉시 회복과는 각각 적용됩니다.

| 버프 | 한 판 효과 | 외부 경험치 계열 | 최대 중첩 |
|---|---|---|---:|
| 생존 본능 | 최대 체력 +15, 즉시 15 회복 | 캐릭터 | 5 |
| 기동 전술 | 이동 속도 +8% | 캐릭터 | 5 |
| 화력 과부하 | 무기 피해 +15% | 무기 | 5 |
| 고속 순환 | 공격 간격 -10% | 무기 | 5 |
| 임시 장갑 | 방어력 +1 | 방어구 | 5 |

버프의 확정값은 저장소 CSV에 있고, 실시간 테스트에서는 Google Sheets `RunBuff` 탭을 읽습니다. 새 효과, 표시 문구, 최대 중첩, 외부 성장 계열을 코드 수정 없이 추가할 수 있습니다. 장비·외부 레벨과 충돌하지 않도록 플레이어와 무기는 `equipment`, `run_buffs`, `meta_*` 같은 출처별 수정자를 합산합니다. 열 계약과 확정 절차는 [내부 성장·장비 강화 Google Sheets 연동](growth-balance.md)을 참고합니다.

## 외부 성장

한 판에서 고른 임시 버프 하나가 대응 계열 외부 경험치 1이 됩니다. 각 계열은 독립적으로 레벨업합니다.

```text
다음 레벨 요구 경험치 = 3 + (현재 레벨 - 1) × 2
```

| 계열 | 영구 레벨 효과 |
|---|---|
| 캐릭터 | 레벨당 최대 체력 +5, 이동 속도 +2% |
| 무기 | 레벨당 기본 피해 +0.5 |
| 방어구 | 레벨당 방어력 +0.5 |

현재 수치는 최소 구현용 기본값입니다. 내부 버프와 장비 강화 수치는 Google Sheets로 연결됐고, 외부 경험치 요구량과 영구 계열 효과는 계속 `MetaProgressionSystem`의 독립 정책으로 남아 있습니다.

## 모듈 구성과 계약

| 모듈 | 책임 | 주요 공개 계약 |
|---|---|---|
| `experience` | 결정 생성과 획득 | `experience_collected` |
| `leveling` | 한 판 XP·레벨 | `level_gained`, `get_run_snapshot` |
| `run_buffs` | 선택지·중첩·임시 효과·정산 분류 | `prepare_choices`, `select_buff`, `get_meta_experience_breakdown` |
| `growth_balance` | RunBuff·Upgrade CSV 검증, 실시간 갱신, 확정값 폴백 | `get_run_buff_catalog`, `get_*_modifiers`, `quote_upgrade` |
| `meta_progression` | 세 계열 외부 XP·레벨·저장 | `settle_run`, `apply_to_targets`, `get_snapshot` |

`run_buffs`를 끄면 기존 자동 무기 강화 폴백으로 동작하며 레벨업 HP 12 회복은 그대로 유지됩니다. `meta_progression`만 끄면 한 판 버프는 유지되지만 종료 후 영구 성장은 정산하지 않습니다.

## 기능 토글과 의존성

- `experience_enabled`: `enemies` 필요
- `leveling_enabled`: `experience` 필요
- `run_buffs_enabled`: `leveling`과 유효한 버프 카탈로그 필요
- `meta_progression_enabled`: `run_buffs`와 저장 경로 필요

## 검색 별칭

XP, 내부 경험치, 외부 경험치, 런 경험치, 메타 성장, 영구 성장, 임시 버프, 버프 선택, 캐릭터 레벨, 무기 레벨, 방어구 레벨, 레벨업 체력 회복, 레벨업 힐
