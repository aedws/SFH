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

## 손상 매물 가격·성능 · 2026-09-07

손상품은 성능70~90%, 가격은 **같은 아이템 표준 단가의20~30%**입니다. 표준 구급품이 2개45C라면 단가는22.5C이고 손상품1개6C는26.67%입니다. 손상 탄도 코어는 표준90C 대비23C(25.56%)입니다. Sheet `ShopOffer!G3/G6`, 확정 CSV, Web payload를 함께 변경했습니다. 새 탭이나 목록을 만들지 않았습니다.

`ItemQualityDefinition`의 범위 값은 교체 가능하며 견적/구매가 동일 정책을 사용합니다. 표준 가격이 없거나 여러 단가가 충돌하거나 범위를 벗어나면 크레딧을 쓰기 전에 이유를 표시합니다. 개별6C/23C는 임시 밸런스이며 향후 표준 가격 변경 때 손상품 가격도 함께 조정해야 합니다.

P5-03~10을 완료해 작전 전 준비와 작전 후 영구 성장이 하나의 거점 흐름으로 이어집니다. 목록은 Google Sheet의 `Utility`, `OperationPreset`, `ShopOffer`, `Recipe`, `TrainingScenario`, `Codex` 탭에서 실시간 시험하고, 게임은 같은 1·2행 설명/3행 이후 데이터 구조의 확정 CSV를 읽습니다. 현재 수치는 모두 `provisional`이라 기획 확정 때 데이터만 교체합니다.

## 플레이어에게 달라진 점

| 구간 | 화면에서 확인하는 정보 | 실제 결과 |
|---|---|---|
| 유틸리티 | 가방·구급키트·공격 전지·비상 신호기의 가격·수량·사용 조건 | 총 투입액에 합산되고 런에서만 사용, 사망·종료 시 잔량 소실 |
| 작전 확정 | 캐릭터·무기·스킬·유틸리티·지역·난이도·페널티·총비용 | 편집 중 무과금, 불변 초안을 한 번 확정할 때만 원자적 차감 |
| 파산 보호 | 재화 0일 때 무료 생존 프리셋 | 무료 캐릭터·무기·소형 기본 지역으로 반복 출격 가능 |
| 회전 상점 | 3품질 설정, 가격·수량·견적·명시 구매·리롤 비용 | P7-01A/B·P7-02 완료. 품질 실물의 I/U/E 실제 수치와 런 복귀 1회 회전·유료 리롤 결과 반영 |
| 제작소 | 영구 등록 수·잠금/재제작 후보·재료·비용·옵션/소켓 범위 | P7-03 등록과 P7-04 단일 거래→실제 옵션·소켓 완제품→재접속 유지 |
| 훈련장 | 단일 보스·밀집 8기 실제 더미와 기존 타격 기록 | 거점 F 전환·실제 좌클릭·자동 초기화·일반 스폰/보상 비간섭. P8-02 전용 계측 HUD 예정 |
| 도감 | 완료 수·누적 수량·미해금 지역 힌트 | 탈출 성공 때만 누적하고 재접속 후 유지 |

## 모듈 경계 {#quality-module-contract}

`P5HubProgressionService`는 공개 façade와 조립만 담당합니다. 실제 정책은 `UtilityInvestmentService`, `OperationDraftService`, `BankruptcyProtectionPolicy`, `RotatingShopService`, `ShopItemQualityPolicy`, `ShopInventoryDeliveryService`, `WorkshopService`, `TrainingService`, `CodexService`가 각각 소유하고, 버튼 행동·표시 문구는 `P5HubActionPresenter`가 소유합니다. 각 하위 서비스는 설정의 `*_enabled`로 독립 제거할 수 있고 월드 Scene 내부 Node를 참조하지 않습니다. 품질 표시명·옵션·소켓은 `ItemQualityCatalog` Resource에 있으며 다른 카탈로그를 주입해 코드 수정 없이 교체합니다. 인스턴스 payload 키와 수치 배율은 공용 `ItemQualityDescriptor`만 해석합니다. 회전 상점 내부에서도 매물 계산은 `ShopRotationPolicy`, 런/회전 상태는 `ShopRotationState`, 리롤 견적·차감·거래 기록은 `ShopRerollTransactionService`로 분리합니다. 제작소 내부는 `BlueprintRegistry`(영구 ID), `WorkshopRecipeProvider`(CSV 조회), `WorkshopUnlockService`(반출 등록·후보 상태), `WorkshopRollPolicy`(옵션·소켓 결정), `WorkshopCraftTransactionService`(검증·단일 저장)로 다시 나눕니다.

하위 스크립트는 집계기에서 정적 `preload`하지 않습니다. 활성 플래그일 때만 문자열 경로로 지연 로드하므로 상점이나 훈련장을 끈 빌드는 해당 스크립트와 CSV가 물리적으로 없어도 구성됩니다. 비활성 경로를 존재 검사하지 않는 계약과 `res://removed/` 경로 회귀 테스트가 이 제거성을 고정합니다.

프로필은 재화·창고·영구 도면·도감 진행·처리 완료 거래 ID만 저장합니다. 상점·제작·도감 서비스가 저장 형식이나 UI를 직접 소유하지 않으므로 공급자를 바꿔도 기존 플레이 데이터 계약은 유지됩니다. 지급 또는 거래 ID 기록이 실패하면 정상 보상 가능한 경우 지급품·크레딧을 함께 원복합니다. 교체 공급자의 지급 원복까지 실패하면 크레딧을 환불하지 않고 `consistency_error`를 반환해 아이템과 환불액이 동시에 생기는 중복 보상을 차단합니다.

훈련은 테스트가 내부 `TrainingService`를 직접 호출하지 않습니다. Game 조립부가 [P8 훈련 연습장](training-ground.md)의 실제 더미 `damaged` 신호를 공개 `record_training_hit` façade에 전달합니다. 더미는 별도 소유·초기화되며 일반 적 스폰, 경험치, 전리품, 처치 통계를 건드리지 않습니다. 타격 피드백 표현을 꺼도 계측은 유지되고 실제 공격이 적용된 경우에만 타격 기록이 증가합니다. DPS·AP/s·쿨타임을 읽는 전용 HUD 분리는 P8-02 범위입니다.

## 자동 검증

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-p5.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\check-p5-modularity.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\test-e2e.ps1
```

`P5_HUB_PROGRESSION_OK`는 유틸 사용·단일 확정·무료 반복 출격·3품질 회전·런 복귀 1회 갱신·취소 보존·구매/재굴림 중복 차감 방지·도면/도감 재접속·실제 훈련 façade·하위 모듈 제거·잘못된 CSV 거부·원자적 제작 거래를 판정합니다. `P8_TRAINING_GROUND_OK`와 `E2E_P8_TRAINING_GROUND_OK`는 실제 단일/밀집 생성·간격·타게팅·좌클릭 피해·자동/수동 초기화·스폰 예산 격리·거점 이탈 정리를 판정합니다. `P7_BLUEPRINT_REGISTRY_OK`는 반출→영구 등록→중복 방지→재접속→제작 후보 유지와 모르는 도면 차단을 판정합니다. `P7_WORKSHOP_TRANSACTION_OK`는 비용·재료·Roll 범위 선공개, 원자적 단일 저장, 실제 옵션·소켓과 재접속을 판정합니다. `P7_SHOP_BROWSER_OK`는 실제 로비 단말에서 리롤 견적→1회 차감→교체 수 영수증과 4화면 배치를 판정합니다. `P7_SHOP_QUALITY_OK`는 고성능 모듈 구매→가방 실물→U 장착→실제 1.25배 수치→해제 후 품질 보존, 카탈로그 교체와 롤백 실패 중복 보상 차단을 판정합니다. `P7_SHOP_DELIVERY_MODULE_OK`는 P5·상점을 켠 채 실물 지급만 제거했을 때 가방 불변·레거시 창고 지급을 판정합니다. `P5_MODULARITY_OK`는 훈련 전체 스키마와 P5 경계를, `SYSTEM_MODULARITY_OK`는 전체 57개 기능 경계·226개 클래스·26개 의존의 순환 참조·Scene 침범·Manifest 누락을 정적으로 차단합니다.

## 데이터·과금 경계

- Sheet 수치는 게임 내 크레딧 밸런스이며 결제 상품이나 유료 재화가 아닙니다.
- Cloudflare 플랜·결제·유료 설정은 변경하지 않았습니다.
- 이번 P7-03~04는 기존 `Recipe` 3행과 임시 옵션 4종을 재사용해 Sheet를 확장하지 않았고 CSV 고정본을 항상 폴백으로 유지합니다.
- 2026-09-04 전체 대조에서 `Item!A18:P21`의 Utility 중복 4행이 Item 스키마 검증에 실패했습니다. 해당 행은 자동 반영하지 않았으며 `Utility` 탭을 단일 원본으로 유지해야 합니다.
- Recipe·Codex·OperationPreset의 도면·지역·무기·스킬 ID는 기존 Item·작전·무기·스킬 카탈로그 ID를 재사용합니다.
- 기획자는 `source_status=provisional` 행의 가격·성능·수량·지역 힌트 후보와 근거를 제출하고, 프로젝트 오너가 확정합니다.

## 검색 별칭

후속 진행: [P7-01A/B·P7-02 상점 비교·품질·회전](hub-economy.md#shop-browser), [위변조·백업 구현 예정](../design/p7-plus-preimplementation.md#economy-integrity-plan). 실제 운영 수치 확정과 로컬 구현 완료 범위를 구분합니다.

P5 완료, 거점 서비스, 유틸리티 투자, 작전 초안, BEP, 파산 보호, 회전 상점, 리롤, 제작소, 훈련장, 작전 도감
