---
title: P5 거점 진행 통합
description: 유틸리티 투자부터 작전 확정·파산 보호·회전 상점·제작·훈련·도감까지의 모듈 계약
tags:
  - P5
  - 거점
  - 상점
  - 제작
  - 훈련장
  - 도감
  - Google Sheet
---

# P5 거점 진행 통합

P5-03~10을 완료해 작전 전 준비와 작전 후 영구 성장이 하나의 거점 흐름으로 이어집니다. 목록은 Google Sheet의 `Utility`, `OperationPreset`, `ShopOffer`, `Recipe`, `TrainingScenario`, `Codex` 탭에서 실시간 시험하고, 게임은 같은 1·2행 설명/3행 이후 데이터 구조의 확정 CSV를 읽습니다. 현재 수치는 모두 `provisional`이라 기획 확정 때 데이터만 교체합니다.

## 플레이어에게 달라진 점

| 구간 | 화면에서 확인하는 정보 | 실제 결과 |
|---|---|---|
| 유틸리티 | 가방·구급키트·공격 전지·비상 신호기의 가격·수량·사용 조건 | 총 투입액에 합산되고 런에서만 사용, 사망·종료 시 잔량 소실 |
| 작전 확정 | 캐릭터·무기·스킬·유틸리티·지역·난이도·페널티·총비용 | 편집 중 무과금, 불변 초안을 한 번 확정할 때만 원자적 차감 |
| 파산 보호 | 재화 0일 때 무료 생존 프리셋 | 무료 캐릭터·무기·소형 기본 지역으로 반복 출격 가능 |
| 회전 상점 | 손상·표준·고성능 3품질, 가격·성능·재굴림 비용 | 복귀 시 회전, 유료 재굴림과 구매 모두 거래 ID로 중복 차감 차단 |
| 제작소 | 영구 등록 도면·재료·비용·옵션/소켓 범위 | 탈출 도면 등록→재접속 유지→맞춤 제작→보관함 추가 |
| 훈련장 | 단일·밀집 더미, DPS·최대 타격·AP·쿨타임 | 비용 없는 측정 세션, 종료 시 준비 로드아웃 원복 |
| 도감 | 완료 수·누적 수량·미해금 지역 힌트 | 탈출 성공 때만 누적하고 재접속 후 유지 |

## 모듈 경계

`P5HubProgressionService`는 조립만 담당합니다. 실제 정책은 `UtilityInvestmentService`, `OperationDraftService`, `BankruptcyProtectionPolicy`, `RotatingShopService`, `WorkshopService`, `TrainingService`, `CodexService`가 각각 소유합니다. 각 하위 서비스는 설정의 `*_enabled`로 독립 제거할 수 있고 월드 Scene 내부 Node를 참조하지 않습니다.

프로필은 재화·창고·영구 도면·도감 진행·처리 완료 거래 ID만 저장합니다. 상점·제작·도감 서비스가 저장 형식이나 UI를 직접 소유하지 않으므로 공급자를 바꿔도 기존 플레이 데이터 계약은 유지됩니다.

## 자동 검증

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-p5.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\check-p5-modularity.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\test-e2e.ps1
```

`P5_HUB_PROGRESSION_OK`는 유틸 사용·단일 확정·무료 반복 출격·3품질 회전·구매/재굴림 중복 차감 방지·도면/도감 재접속·훈련 복원·하위 모듈 제거를 판정합니다. 평균 PC 성능 예산에서는 대형 작전 평균 6.880ms, 피크 8.204ms, Node 최대 1,912개로 60 FPS CPU 예산을 통과했습니다.

## 데이터·과금 경계

- Sheet 수치는 게임 내 크레딧 밸런스이며 결제 상품이나 유료 재화가 아닙니다.
- Cloudflare 플랜·결제·유료 설정은 변경하지 않았습니다.
- 신규 목록은 사용자 지시대로 Sheet를 확장했으며 CSV 고정본을 항상 폴백으로 유지합니다.
- 기획자는 `source_status=provisional` 행의 가격·성능·수량·지역 힌트만 확정하면 됩니다.

## 검색 별칭

P5 완료, 거점 서비스, 유틸리티 투자, 작전 초안, BEP, 파산 보호, 회전 상점, 리롤, 제작소, 훈련장, 작전 도감
