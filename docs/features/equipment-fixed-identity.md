---
title: 무기 고유 스킬과 장비 고정 옵션
description: 성장·모듈과 분리되어 같은 장비 정체성을 유지하는 무기 고유 효과와 무기·방어구 옵션 계약
tags: [무기 고유 스킬, 장비 옵션, 고정 정체성, Google Sheets, CSV]
---

# 무기 고유 스킬과 장비 고정 옵션

장비에는 레벨이나 모듈과 별개인 **고정 정체성**이 있습니다. 같은 `weapon_id`의 무기는 언제 얻거나 어느 레벨에서 사용해도 같은 고유 스킬을 발동합니다. 무기·방어구의 기본 고정 옵션과 획득 시 부여된 옵션도 내부 런 레벨, 외부 영구 레벨, 품질 배율, 모듈 강화에 의해 수치가 변하지 않습니다.

## 플레이어가 느끼는 변화

| 장비 | 고유 스킬 | 발동 | 고정 옵션 |
|---|---|---|---|
| 돌격소총 | 축전 반향 | 3회 명중마다 고정 전기 피해 | 피해 ×1.06 |
| 서비스 권총 | 브레이커 에코 | 2회 명중마다 고정 전기 피해 | 사거리 ×1.08 |
| 전투 단검 | 잔상 절단 | 2회 명중마다 고정 전기 피해 | 피해 ×1.04 |
| 대검 | 지진파 | 매 명중마다 강한 고정 피해 | 피해 ×1.10 |
| 펄스 소총 | 펄스 오버플로 | 4회 명중마다 고정 전기 피해 | 발사 간격 ×0.92 |
| 전술 조끼 | 없음 | — | 최대 체력 +10 |
| 러너 부츠 | 없음 | — | 이동 속도 +12 |

고유 효과 발동 피해는 방어 계산을 거치지만 공격력·장비 레벨·런 버프·모듈 배율을 곱하지 않습니다. 따라서 성장으로 기본 공격이 강해져도 무기 고유 스킬 자체의 수치는 그대로입니다.

## 세 가지 계산 원천

```text
장비 고정 정체성 ─┐  definition 옵션 + 획득 시 옵션 + 무기 고유 스킬
장비 영구 성장 ───┼→ AutoWeapon / PlayerStats
런 내부 성장·모듈 ┘
```

- `equipment_fixed_identity`: 무기·방어구 고정 옵션. 성장 배율을 적용하지 않습니다.
- `equipment_upgrade`: 장비 레벨과 모듈 강화. 기존 성장 정책을 따릅니다.
- `run_buff`: 한 판에서만 유지되는 내부 증강입니다.

각 원천은 별도 Dictionary와 Signal로 전달됩니다. 새 옵션을 추가해도 성장 공식이나 모듈 코드를 수정하지 않습니다.

## 획득 옵션 부여

제작·드랍 payload의 `affixes`는 `EquipmentFixedOptionFactory`가 장비 대상에 맞는 `EquipmentFixedOption`으로 변환합니다. 무기는 피해·발사 주기 계열, 방어구는 체력·방어·이동 계열을 허용합니다. 지원하지 않는 조합은 제외하고 장비 검증 단계에서 잘못된 대상 옵션을 거부합니다.

옵션은 `EquipmentItemState.assigned_fixed_options`에 귀속되므로 가방 이동, 장착·해제, 저장·복원 뒤에도 유지됩니다. 옵션이 달라도 `weapon_id`가 같다면 고유 스킬은 동일합니다.

## 타격 인지 개선

투사체는 발사 순간의 무기 정체성 스냅샷을 보관합니다. 발사 뒤 `Q`로 무기를 바꿔도 이미 날아간 탄환의 이펙트와 고유 스킬이 새 무기로 뒤바뀌지 않습니다.

- 총구 섬광을 짧게 표시합니다.
- 투사체 바깥쪽에 반투명 광원을 겹쳐 이동 궤적을 읽기 쉽게 했습니다.
- 무기별 충격 색, 링 반경, 방사선 수, 카메라 반응 강도를 다르게 합니다.
- 명중 확인 뒤에만 고유 스킬 카운트를 올립니다.

## 데이터 편집과 확정

[SFH_item_Balance Google Sheet](https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/edit)에서 다음 열을 편집합니다.

- Weapon: `innate_skill_*`, `fixed_option_*`
- Armor: `fixed_option_*`
- 1행 변수명, 2행 한국어 설명, 3행부터 장비 데이터

검토가 끝나면 `sync_equipment_identity.py`로 `equipment_identity.csv`를 갱신합니다. CI는 7개 행, ID 중복, 숫자 범위, 연산 방식과 `fixed_identity` 정책을 검사합니다. 현재 수치는 기획 확정 전 `provisional`입니다.

## 모듈 경계

| 모듈 | 책임 |
|---|---|
| `EquipmentFixedOption` | 한 옵션의 대상·연산·값과 불변 스냅샷 |
| `WeaponInnateSkillDefinition` | 같은 무기에 고정되는 발동 횟수·피해·표현 |
| `EquipmentFixedOptionFactory` | 제작·드랍 payload를 장비 옵션으로 변환 |
| `EquipmentIdentityTable` | 확정 CSV 열·행 계약과 조회 |
| `EquipmentItemState` | 인스턴스 옵션 저장·복원·검증 |
| `CharacterEquipmentSystem` | 고정 옵션 집계와 활성 무기 정체성 Signal |
| `WeaponInnateSkillSystem` | 명중 카운트와 고정 효과 발동 |
| `AutoWeapon` | 발사 시점 정체성 스냅샷과 표현 조립 |

## 검증

`equipment_fixed_identity_contract_test.gd`가 같은 무기의 고유 스킬 동일성, 정의/획득 옵션, 성장 불변성, 런타임 source 분리, 발동 횟수·고정 피해, 안전 저장 코덱 왕복과 잠금 CSV 계약을 자동 판정합니다. 다운로드판은 `EquipmentFixedOption`과 `WeaponInnateSkillDefinition`만 명시 허용 타입으로 복원하므로 임의 Resource 경로는 계속 거부합니다.

## 검색 별칭

무기 고유 스킬, 무기 옵션, 방어구 옵션, 고정 옵션, 랜덤 옵션, 장비 정체성, 같은 무기 같은 스킬, 성장 비적용, 모듈과 별개
