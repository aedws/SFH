---
title: P5-02 주·보조무기·스킬 런 투자
description: 소유·미해금·이번 런 구매를 구분하고 무기 태그까지 검증하는 출격 준비 계약
tags: [P5, 무기, 스킬, 투자, 해금, 태그, Google Sheets, E2E, 모듈화]
---

# P5-02 주·보조무기·스킬 런 투자

## 플레이어에게 보이는 변화

작전 브리핑에서 `MAIN`, `SUB`, `S1~S3` 버튼으로 지참할 무기와 스킬을 바꿉니다. 각 버튼은 다음 상태를 섞지 않고 표시합니다.

| 상태 | 의미 | 투입 가능 여부 |
|---|---|---|
| 소유 | 무료 기본 장비·스킬 | 가능 |
| 미해금 | 요구 지역·영구 해금이 없음 | 불가, 크레딧 무차감 |
| 이번 런 구매 | 해금됐지만 출격할 때마다 가격을 냄 | 가능 |
| 구매 완료 | 현재 전투 세션에 비용이 확정됨 | 현재 런 동안만 유지 |

현재 임시 비교값은 전격 펄스 소총 80 C, 아크 질주 60 C입니다. 소형 맵의 최소 회수 배치 예산을 넘지 않도록 E2E로 검증한 값이며 기획 확정값이 아닙니다.

## 데이터 계약

기존 Google Sheet의 `Weapon`, `Skill` 탭을 확장했습니다. 1행 변수명·2행 설명·3행 이후 항목 규칙은 그대로입니다.

- Weapon: `run_investment_price`, `default_owned`, `required_unlock_id`, `allowed_slots`, `investment_source_status`
- Skill: `run_investment_price`, `default_owned`, `required_unlock_id`, `investment_source_status`
- `temporary`는 구현 진행용 임시값, `confirmed`는 Notion 근거가 연결된 기획 확정값입니다.
- 배포는 `weapon_investment.csv`, `skill_investment.csv`와 Web 내장 payload를 사용합니다. 실시간 모드는 같은 열을 읽습니다.

## 모듈 경계

```text
Weapon·Skill Sheet / locked CSV
              ↓
LoadoutInvestmentTable → LoadoutInvestmentService
              ↓ snapshot / investment_context
OperationSetupPresenter → OperationContractService
              ↓ 성공한 런에서만
EquipmentSystem + CombatSkillSystem
```

서비스는 가격·해금·선택·태그 적합성과 런 구매 상태만 소유합니다. 장비 내부 상태, 스킬 효과, 프로필 잔액을 직접 수정하지 않습니다. [작전 투입 사전검증](operation-launch-preflight.md)이 비용과 선택을 불변 계획에 넣고 장비·가방·전리품 전제를 먼저 검사한 뒤, 총비용은 작전 계약이 한 번만 차감합니다. 예측할 수 없는 조립 실패만 기존 원자 롤백이 전액 복원합니다.

거점 장비는 런 시작 전에 사본으로 보존합니다. 같은 무기를 선택하면 장착 파츠·모듈을 유지하고, 다른 펄스 소총처럼 슬롯 정의가 바뀌면 작전 중에만 초기 상태로 교체합니다. 탈출·사망·조립 실패 뒤에는 거점의 원래 장비·파츠·모듈과 스킬 배치로 돌아갑니다.

## 플레이어 인식 E2E

`돌격소총 소유 확인 → 펄스 소총·아크 질주 선택 → 미해금 표시·출격 거절·무차감 → 지역 해금 → 추가 140 C 견적 → 1회 차감 → 펄스 소총 장착 → electric 태그 적합 → 3번 아크 질주 발동 → 거점 원장비 복원`을 한 자동 흐름으로 검증합니다.

소·중·대형×표준·숙련·악몽 9조합, 3규모×4세팅 변경 프로필, 같은 무기 커스터마이징 유지, 다른 무기 임시 교체·복원, 기본 루프, 캐릭터 비용 1회 합산, 대형 60 FPS CPU 예산도 함께 회귀 검사합니다.

## 기획 교체 지점

기획자는 위키 홈의 `DATA-P5-02-01` 요청에 Notion 결정 근거를 남기고 Sheet의 가격·기본 소유·요구 해금 열을 바꿉니다. 코드는 동일한 CSV 스키마를 사용하므로 가격과 목록 변경만으로 교체할 수 있습니다. 다음 작업은 P5-03 유틸리티 투자입니다.

## 검색 별칭

P5-02, 런 장비 구매, 주무기 투자, 보조무기 투자, 스킬 투자, 소유 미해금, 태그 불일치, 펄스 소총, 아크 질주
