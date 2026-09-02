---
title: P6 랭킹 제공자와 오프라인 보존
description: 로컬 3종 랭킹을 보존하면서 온라인 공급자를 교체 가능한 어댑터로 연결하는 P6-01 계약
tags:
  - Phase 6
  - 랭킹
  - 온라인
  - 오프라인
  - 모듈
---

# P6 랭킹 제공자와 오프라인 보존

P6-01은 기존 가치·시간·처치 3종 로컬 랭킹을 없애지 않습니다. `ConditionalRankingSystem`이 공통 창구가 되고, `LocalRankingProvider`와 `OnlineRankingProviderAdapter`를 설정으로 교체합니다.

## 플레이어가 보는 상태

| 상태 | 결과 화면 | 기록 처리 |
|---|---|---|
| 로컬 모드 | `로컬 랭킹 · 기기에 보존` | 로컬 JSON에만 확정 |
| 온라인 준비 | `온라인 랭킹 · 연결됨 · 로컬 보존` | 다음 제출 가능, 로컬 유지 |
| 동기화 성공 | `동기화 완료 · 로컬 보존` | 온라인 응답과 로컬 순위를 함께 보존 |
| 공급자 없음·장애 | `오프라인 · 로컬 보존 · 동기화 대기` | 런 결과는 로컬에 먼저 확정 |

온라인 장애가 작전 정산 자체를 실패시키지 않습니다. 영구 재시도 큐·신원·서명·멱등 키는 P6-02 영역이므로 P6-01에서는 구현된 것처럼 표시하지 않습니다.

## 모듈 경계

```text
OperationResultService
  → ConditionalRankingSystem (façade)
      → LocalRankingProvider (항상 보존)
      → OnlineRankingProviderAdapter (주입된 gateway만 사용)
      → RankingProviderConfig (local / auto / online)
```

- 공통 계약: `submit_run`, `get_entries`, `get_snapshot`, `get_provider_status`
- 로컬 구현: 점수·정렬·마이그레이션·JSON 저장을 소유합니다.
- 온라인 어댑터: 특정 서버 URL이나 SDK를 소유하지 않고 `gateway` 공개 메서드만 호출합니다.
- 조립부: 설정 Resource와 공급자 주입만 담당합니다.
- 서버·계정·보안 제공자가 확정되기 전에는 실제 외부 제출을 활성화하지 않습니다.

## 설정과 제거

`default_ranking_provider.tres`의 `provider_mode`를 `local`, `auto`, `online` 중 하나로 선택합니다. 온라인 어댑터 파일을 제거해도 로컬 구현 계약은 독립적으로 유지되며, 실제 빌드에서는 공급자를 주입하지 않은 `auto`가 안전한 로컬 폴백으로 동작합니다.

## 자동 검증

```powershell
.\scripts\test-p6.ps1
```

검사는 로컬 기록, 공급자 교체, 온라인 조회, 네트워크 단절, 로컬 기록 보존, 플레이어에게 노출할 동기화 상태를 한 번에 판정합니다. Google Sheet 목록 확장은 필요하지 않았고 결제·과금·Cloudflare 유료 설정은 변경하지 않았습니다.

## 검색 별칭

P6, 랭킹 제공자, 온라인 랭킹, 로컬 랭킹, 오프라인 폴백, 동기화 대기, RankingProvider, 조건부 랭킹
