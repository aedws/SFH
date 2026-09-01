---
title: 런 전용 룬·코어·유물 소켓
description: 기획 수치가 없는 P4-05를 교체 가능한 RunAsset 데이터와 작전 한정 소켓으로 구현한 모듈
tags: [P4-05, 전리품, 룬, 코어, 유물, Google Sheets, 세션 소켓]
---

# 런 전용 룬·코어·유물 소켓

## 무엇이 변했나

작전에서 룬·코어·유물을 발견하면 비교 패널에 `F 런 소켓 장착`이 표시됩니다. F를 누르면 장비 영구 모듈과 분리된 작전 한정 슬롯에 들어가고 전투 수치가 즉시 변합니다. 화면 상단의 작은 `SESSION SOCKETS / RUN ONLY` 패널에서 점유 상태를 확인하고, 점유 버튼을 누르면 효과를 해제할 수 있습니다.

기획 데이터가 아직 없으므로 아래 값은 **임시 기본값**입니다. 최종값은 코드가 아니라 Google Sheet `RunAsset` 탭이나 확정 CSV만 바꾸면 교체됩니다.

| 종류 | 임시 슬롯 | 중복 | 임시 효과 |
|---|---:|---:|---|
| 룬 | 2 | 같은 아이템 1개 | 전도 룬: 무기 피해 ×1.15 |
| 코어 | 1 | 같은 아이템 1개 | 축전 코어: 스킬 쿨타임 ×0.85 |
| 유물 | 1 | 같은 아이템 1개 | 위상 유물: 이동 속도 ×1.12 |

슬롯이 가득 찬 상태의 기본 정책은 `오래된 항목부터 교체`입니다. 환전 가격과 탈출·사망 결과는 기존 Item 생명 주기 데이터가 소유하며, P4-06 정산이 실제 프로필·재화 반영을 담당합니다.

## 데이터 계약

`RunAsset`은 1행 변수명, 2행 기획자 설명, 3행 이후 개별 규칙 형식입니다. `rule_id`, `item_id`, `socket_type`, `slot_capacity`, `duplicate_limit`, `replacement_policy`, `effect_target`, `modifier_id`, `modifier_operation`, `modifier_value` 등을 독립 열로 둡니다.

- 실시간 테스트: Google Sheet `RunAsset`
- 확정 모드: `session_socket_rules.csv`
- Web 폴백: 같은 CSV로 생성한 `EmbeddedCsvPayload`
- 배포 추적: Web PCK와 Windows 빌드 데이터 목록에 같은 CSV 포함

동기화 검사는 ID 중복, 허용 소켓·효과 대상·연산, 용량, 중복 수, 아이템 생명 주기 연결을 확인합니다. 잘못된 실시간 응답은 현재 유효한 확정 데이터를 덮어쓰지 않습니다.

## 모듈 경계

| 모듈 | 책임 | 하지 않는 일 |
|---|---|---|
| `SessionSocketRule/Table` | CSV 파싱·행 검증 | 전투 수치 직접 변경 |
| `SessionSocketConfig` | 확정/실시간 공급자 선택 | 소켓 장착 판단 |
| `SessionSocketService` | 용량·중복·교체·효과 집계 | 영구 장비 개조·프로필 정산 |
| `FieldLootAcquisitionService` | F 획득을 소켓 명령으로 전달 | 효과 계산 |
| `SessionSocketHUD` | 읽기 전용 점유 표시·해제 명령 | 규칙 보관 |

Manifest의 `session_sockets_enabled`만 끄면 현장 전리품 비교·획득과 영구 장비 모듈은 유지된 채 서비스와 HUD만 제거됩니다. 런 종료 시 서비스가 제거되면서 모든 소켓과 런타임 modifier source가 함께 초기화됩니다.

## 플레이어 인식 E2E

자동 E2E는 `드랍 생성 → 접근 → F 런 소켓 → HUD 점유 → 실제 무기 피해 증가 → HUD 버튼 해제 → 피해 원복`을 실제 입력과 화면 문구로 판정합니다. 별도 계약 테스트는 룬 2·코어 1·유물 1 용량, 동일 아이템 1개 제한, 무기·스킬·이동 효과, 전체 런 초기화와 선택적 모듈 제거를 검증합니다.

다음 단계는 [P4-06 탈출 정산](../design/current-milestone-workline.md)입니다. 기획자는 `DATA-P4-05-01`로 최종 슬롯·중복·효과·환전 값을 남기면 되고, 개발자는 `RunAsset`과 Item 값을 교체한 뒤 같은 E2E를 재실행합니다.

## 검색 별칭

세션 소켓, 런 소켓, 룬, 코어, 유물, RunAsset, P4-05, 전도 룬, 축전 코어, 위상 유물, 작전 한정 효과
