---
title: 작전 투입 사전검증과 불변 계획
description: 모든 작전 세팅을 결제 전에 집계·검증하고 동일한 계획만 런타임에 적용하는 확장 계약
tags:
  - 작전
  - 사전검증
  - 모듈
  - E2E
---

# 작전 투입 사전검증과 불변 계획

## 무엇이 바뀌었나

기존에는 요원·무기·스킬·유틸리티를 결제한 뒤 전투 Scene을 조립했습니다. 파츠·모듈·가방 또는 전리품 설정이 조립 단계에서 거부되면 결제를 되돌리고 거점으로 복귀했기 때문에, 플레이어에게는 특정 조합에서 작전 진입이 무시되는 것처럼 보였습니다.

이제 `OperationLaunchPreflightService`가 **설정 집계 → 런타임 검증 → 견적 확정 → 결제 → 동일 계획 조립** 순서를 강제합니다. 검증 실패는 브리핑 화면에서 이유를 표시하며 크레딧과 소모품을 차감하지 않습니다.

```text
Character ─┐
Loadout ───┼─ Setting Contributor ─┐
Utility ───┘                       │
                                  ├─ Preflight → Immutable Plan → Invest → Assemble
Equipment ─┐                       │
Inventory ─┼─ Launch Validator ───┘
Loot ──────┘
```

## 확장 계약

새 작전 설정은 `Game.start_run()`에 조건문을 추가하지 않습니다. 독립 Node가 아래 공개 메서드 하나를 제공하고 사전검증 서비스에 등록합니다.

```gdscript
func get_operation_setting_contribution() -> Dictionary:
    return {
        &"contributor_id": &"new_setting",
        &"context_key": &"new_setting",
        &"additional_entry_cost": 0,
        &"context": {&"selected_id": &"example"},
        &"validation_errors": PackedStringArray(),
        &"revision": &"catalog_v1",
    }
```

- `contributor_id`는 등록 ID와 같아야 합니다.
- 독립 설정은 고유 `context_key` 아래에 둬 다른 모듈과 키 충돌을 막습니다.
- 추가 비용은 0 이상이며 사전검증 서비스가 한 번만 합산합니다.
- `context`는 Resource 인스턴스가 아니라 복사 가능한 ID·숫자·문자·배열·Dictionary 스냅샷으로 전달합니다.
- 기여자 순서와 무관하도록 등록 ID를 정렬한 뒤 집계합니다.

런타임 상태를 확인해야 하는 기능은 다음 검증 계약을 구현합니다.

```gdscript
func validate_operation_launch(request: Dictionary) -> PackedStringArray:
    # 빈 배열이면 통과, 메시지가 있으면 결제 전 차단
    return PackedStringArray()
```

검증기는 현재 장비 슬롯·파츠·모듈 코스트, 가방 배치, 선택 무기 경로, 규모별 전리품 가치 배분처럼 실제 조립에 필요한 전제만 확인합니다. 상태를 변경하거나 재화를 차감하지 않습니다.

## 장비 변경 정책

| 변경 | 작전 중 | 거점 복귀 |
|---|---|---|
| 준비한 무기와 같은 무기 선택 | 장착한 파츠·모듈·강화 상태 유지 | 같은 상태 유지 |
| 다른 작전 무기 선택 | 선택 슬롯만 새 무기의 초기 상태로 교체 | 준비했던 무기·파츠·모듈 복원 |
| 방어구·가방 변경 | 검증을 통과한 준비 상태 적용 | 준비 상태 복원 |
| 유효하지 않은 파츠·모듈·가방 | 결제 전에 진입 차단 | 크레딧·소모품 불변 |

작전 전용 무기가 거점 장비를 암묵적으로 덮어쓰지 않도록 `replace_selected_slot_restore_hub_state` 정책 ID도 계획에 기록합니다.

## 불변 계획

사전검증이 성공하면 규모, 페널티, 모든 설정 기여, 최종 견적을 서명한 계획 스냅샷이 생성됩니다. 결제 결과의 규모·비용·설정 문맥이 이 계획과 다르면 즉시 롤백합니다. 조립부는 별도로 설정을 다시 계산하지 않고 확정된 계약만 소비합니다.

이 구조의 핵심은 “현재 기능이 동작한다”와 “다음 세팅을 기존 분기 수정 없이 추가할 수 있다”를 동시에 완료 조건으로 삼는 것입니다.

## E2E 게이트

- 3규모 × 3지역 × 3난이도 × 3요원 = 81개 실제 작전 조립·복귀
- 3규모 × 4변경 프로필 = 12개 장비·파츠·모듈·유틸리티·페널티 변경
- 동일 무기 커스터마이징 유지와 다른 무기 작전 임시 교체·거점 복원
- 잘못된 파츠 소켓과 겹친 가방 배치의 결제 전 거부
- 미래 설정 기여자를 기존 집계 코드 수정 없이 등록
- 변조된 계획 거부, 실패 시 크레딧 무차감, 0원 작전 전리품 계약

관련 근거는 [실제 플레이 세션 E2E](../quality/e2e-play-session.md)와 [모듈화 점검 기록](../architecture/module-audit.md)에서 확인합니다.

## 데이터·비용 영향

새 아이템 목록이 필요한 작업이 아니므로 Google Sheet는 확장하지 않았습니다. Cloudflare·GitHub·게임 과금 모델과 유료 플랜도 변경하지 않습니다.

## 검색 별칭

작전 진입 실패, 원점 복귀, 세팅 변경, 요원 변경, 총기 변경, 모듈 변경, 파츠 변경, 사전검증, 불변 작전 계획
