---
title: 현장 스킬 즉시 교체
description: 현장 스킬을 무기와 분리한 계약으로 비교·교체하고 거점 복귀 전 복원하는 P4-04B
tags: [P4-04B, 현장 전리품, 스킬, 키 바인딩, Google Sheets]
---

# 현장 스킬 즉시 교체

## 무엇이 변했나

연구 단지·산업 지구 방 보상에서 `아크 질주` 스킬이 나올 수 있습니다. 비교 패널은 기존→후보 스킬, 대상 슬롯, 현재 키, ENERGY, CD, 충전 수를 한 번에 보여 줍니다.

`R 스킬 교체`를 누르면 기동 가속이 아크 질주로 바뀌고 3번 키는 그대로 유지됩니다. 아크 질주는 입력 방향으로 즉시 이동하며 경로의 적에게 전기 피해를 줍니다. 전기 태그가 없는 활성 무기라면 교체를 거부하고 이유를 표시합니다.

## Sheet·CSV 계약

| 위치 | 내용 |
|---|---|
| `Skill` 1행 | 변수명 14개 |
| `Skill` 2행 | 기획자용 열 설명 |
| `Skill` 3~6행 | 점멸·원형 자기장·기동 가속·아크 질주 |
| `LootTable` 31행 | `rx_room_arc_dash` 방 보상 후보 |
| 확정 CSV | `skill_catalog.csv` 4행·`loot_table.csv` 29행 |

실시간 시트와 확정 CSV는 동일 14열 스키마를 사용합니다. 동기화 스크립트가 ID 중복, 슬롯 0~9, 타겟 방식, 자원 수치, 등급, 획득 방식을 검증한 뒤 Web PCK·Windows 빌드 메타데이터에 포함합니다.

## 모듈 경계

`FieldLootSkillEntry → FieldLootSkillEquipService → CombatSkillSystem + SkillBindingService`의 단방향 조립입니다. 무기 장착 서비스는 스킬 슬롯·쿨다운·충전·키를 모르며, 스킬 교체 서비스는 인벤토리·영구 프로필을 직접 수정하지 않습니다.

Manifest의 `field_loot_skill_equip_enabled`를 끄면 F 런 보관·ESC 보류·무기 교체는 그대로 유지됩니다.

## 안전 복구와 검증

- 스킬 정의·쿨다운·충전 상태와 기존 Action을 런 내 스택에만 보관합니다.
- 런 전용 키 교체는 사용자 JSON에 저장하지 않습니다.
- 거점 복귀 전 무기·스킬 교체 스택을 역순으로 복원합니다.
- 계약 테스트와 실제 R 입력 E2E가 후보 표시→교체→키 유지→복원을 검증합니다.

기존 항목의 최종 보관·소실 정책은 [DEC-P4-04](../decisions/DEC-P4-04-field-replacement-policy.md)의 `provisional`을 따르며 기획 확정 후 교체합니다.
