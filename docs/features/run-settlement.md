---
title: 런 전리품 정산
description: P4-06 탈출 자동 환전·영구 해금·창고 보관·사망 소실과 run_id 중복 방지 계약
tags:
  - 전리품
  - 정산
  - 자동 환전
  - 영구 해금
  - P4-06
  - E2E
---

# 런 전리품 정산

**9/23 강제 마감:** 30분 붕괴는 기존 사망과 같은 실패 손실 경로를 사용합니다. Game의 공통 실패 조립에서 한 번 정산하고 종료 후 늦은 탈출/사망 신호로 결과를 바꿀 수 없습니다. 아래 파우치와 실물 보존 변경은 승인 후속 작업이며 아직 이 정산에 구현된 것으로 보지 않습니다. [시간 정책](extraction-defense-results.md#pressure-20260923) · [현재 실행 순서](../design/current-milestone-workline.md#next-20260923).

P4-06은 작전 중 `FieldLootAcquisitionService`가 임시 보관한 전리품을 작전 결말에 맞춰 영구 프로필로 옮기는 마지막 Phase 4 단계입니다. 정산 정책은 화면이나 작전 결과 서비스에 넣지 않고 `RunSettlementService` 한 모듈에서 처리합니다.

## 플레이어가 보는 결과

| 결말 | 생명 주기 결과 | 정산 화면 |
|---|---|---|
| 탈출 성공 | `auto_convert` | 자동 환전 크레딧 합계 |
| 탈출 성공 | `warehouse` | 창고 보관 종류 수 |
| 탈출 성공 | `permanent_unlock` | 영구 해금과 연결 상점 등록 |
| 탈출 성공 | 런 전용·미등록 후보 | `expired_items`로 분리해 이번 런 종료와 함께 정리 |
| 사망 | `lost` | 사망 소실 종류·수량 |

기존 휴대 크레딧·고철·랭킹을 계산하는 `OperationResultService`와 전리품 정산은 독립입니다. 결과 화면은 두 서비스의 결과를 한 번에 보여주지만 서로의 정책을 수정하지 않습니다.

## 모듈 계약

```text
FieldLootAcquisitionService --acquired_items--> RunSettlementService
LootLifecycleService --------resolve_outcome----^        |
OperationResultConfig -------shop_offer_for-----^        v
                                              PersistentProfile
```

- `LootLifecycleService`: Item 확정 CSV에 기록된 탈출·사망 결과만 해석합니다.
- `RunSettlementService`: 결과를 합산하고 프로필 명령을 호출합니다.
- `PersistentProfile`: 크레딧·창고·도면·상점 등록을 저장합니다.
- `run_id`: 앱 세션 안에서 한 번 처리된 ID를 기억해 같은 정산을 다시 호출해도 자산을 중복 지급하지 않습니다.
- `FeatureManifest.run_settlement_enabled`: 정산 모듈만 제거해도 생명 주기와 프로필은 유지됩니다.

## 작전 조합 회귀 수정

소형·표준 외 조합이 생성 직후 거점으로 돌아오던 원인은 전리품 배치 목표였습니다. 투자 비용에 2.5~5배를 곱한 목표 가치가 `최대 박스 수 × 박스 최대 크레딧`보다 커지면 `LootSpawner` 조립이 실패했습니다.

수정 후에는 다음 두 범위를 교차해 실제 배치 가능한 가치 안에서만 배율을 선택합니다.

```text
최소 가능 가치 = max(설정 최소 총액, 최소 박스 수 × 박스 최소액)
최대 가능 가치 = min(설정 최대 총액, 최대 박스 수 × 박스 최대액)
선택 배율 = [2.5, 5.0] ∩ [최소 가능 가치/투입비, 최대 가능 가치/투입비]
```

조립에 실패하면 거점 문구가 원인을 덮지 않고 실제 실패 메시지를 보존합니다.

## 자동 검증

- 계약: 소·중·대형 × 표준·숙련·악몽 **9개 조합**의 생성·전투 조립·명시적 거점 복귀
- 실제 UI E2E: 작전 설정 열기 → 난이도 버튼 순환 → 맵 카드 선택 → 작전 투입
- 성공 정산: 자동 환전 450 C, 영구 해금, 상점 등록, 창고 보관, 런 전용 후보 종료 분리
- 중복 방지: 같은 `run_id` 두 번째 호출 뒤 프로필 불변
- 사망 정산: 획득물 전량 소실, 크레딧·창고·해금 추가 없음
- 플레이어 인식: 성공 화면의 `자동 환전·영구 해금·창고 보관`, 실패 화면의 `사망 소실` 문구
- 선택 모듈: `run_settlement_enabled=false`에서 생명 주기·프로필은 계속 동작

## 데이터 확장 규칙

이번 작업은 기존 Item 생명 주기 15종으로 충분해 Google Sheet 목록을 늘리지 않았습니다. 이후 새로운 전리품이 정산 대상이 되면 먼저 Item 시트의 1행 변수명·2행 설명·3행 이후 데이터 규칙으로 항목을 추가하고, 실시간 시험 뒤 같은 스키마의 확정 CSV를 갱신합니다.

## 관련 문서

- [전리품 생명 주기](loot-lifecycle.md)
- [현장 전리품 비교·획득](field-loot-acquisition.md)
- [런 전용 룬·코어·유물 소켓](session-sockets.md)
- [탈출 방어전과 결과 정산](extraction-defense-results.md)
- [P5·P6 사전 구현 설계](../design/p5-p6-preimplementation.md)
