---
title: 효과·스탯 명세 툴킷
description: Notion에서 스킬·무기·캐릭터·모듈을 지정하고 실제 코드 변수와 구현 검수로 연결하는 작성 도구
---

# 효과·스탯 명세 툴킷

**무엇이 언제, 누구에게, 얼마나, 언제까지 적용되는지 적으면 개발자가 같은 의미로 구현할 수 있게 만드는 도구입니다.** 기획자는 [기획 작업실의 수치·효과 도구](../access/planner.md#balance-workbench), 개발자는 [개발 작업실](../access/developer.md)에서 현재 값과 실제 수정 위치를 확인합니다.

!!! warning "작성·확정·게임 적용은 서로 다릅니다"
    Notion이나 시트에 문장을 적었다고 새 행동이 자동 실행되지는 않습니다. 지원 변수는 검증된 변경 계획으로, 새 행동은 `implementation_required` 요청으로 구분합니다. 기획 확정 이후에도 오너 판단 → 코드/데이터 동기화 → 테스트 → 배포가 필요합니다. 이 도구는 임의 코드를 실행하거나 게임 값을 덮어쓰지 않습니다.

## 1. 가장 빠른 사용법

1. 기획 작업실에서 **효과·스탯 명세 툴킷**을 펼칩니다.
2. 스킬 / 무기 / 캐릭터 / 모듈 → 변수 → 대상 ID를 고릅니다. 현행 값·단위·허용 범위·기존 동작이 표시됩니다.
3. 요청값, 기획 의도, 플레이 수락 조건을 적습니다. `confirmed`에는 Notion HTTPS 근거가 필요합니다.
4. **명세 검증·노션 작성문 생성**을 누르고 작성문을 Notion에 붙여 넣습니다. 실제 게시 링크를 넣어 다시 생성하세요.
5. 같은 입력을 [공유 밸런스 시트](https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/edit)의 `EffectSpec`에 기록합니다. 한 행은 **대상 하나의 변수 하나**입니다.
6. 개발자가 읽어 검증하고, 승인 근거와 구현 결과를 연결합니다. 원본 지문이 바뀌면 최신 값을 읽고 재검토해야 합니다.

## 2. 지금 연결할 수 있는 것

| 대상 | 지정 가능한 예 | 실제 구현 원본 |
| --- | --- | --- |
| 스킬 | 쿨타임·AP·충전, 점멸 거리/경로 피해, 자기장 반경/틱 피해/간격/지속, 이동 가속 | `combat_skills/definitions/*.tres`와 기존 효과 모듈. Skill 시트의 설명·카탈로그만 바꿔서는 런타임 효과가 바뀌지 않음 |
| 무기 | 기본 피해·발사 간격·치명·관통, 명중 횟수별 단일/전기 광역 고유 피해 | Weapon 확정 CSV, 고유 기능은 identity CSV **및 무기 Resource** 동시 수정 |
| 캐릭터 | 최대 체력·방어 가산·이동 배율 패시브 | Character 확정 CSV. 이름만으로 새로운 패시브 행동이 생성되지 않음 |
| 모듈 | 피해·체력·이속·방어 장착 가산 | 모듈 Resource. 강화 추가분은 기존 Upgrade 목록 유지 |

무기 고유 피해는 내·외부 레벨과 독립인 고정 기믹입니다. 모듈의 `*_candidate` 식별자는 특수 효과가 구현됐다는 뜻이 아닙니다. HP 회복처럼 오너가 결정한 정책에 영향을 주는 새 행동은 별도 충돌 판단이 필요합니다.

### 입력 예시 — 숫자는 제안이며 확정 아님

| 의도 | 대상 / 변수 | 값 | 플레이 수락 조건 예시 |
| --- | --- | --- | --- |
| 주변 적을 지속 견제 | magnetic_field / skill.MagneticFieldEffect.tick_damage | 8 | 범위 내 적에게 틱마다 적용하고 이탈한 적은 다음 틱부터 미피격. 기존 성장 보정은 유지 |
| 명중 시 전기 확산 | pulse_rifle / weapon.innate_fixed_damage | 2 | 명중 지점 주변의 허용 대상만 피해. 내·외부 레벨을 바꿔도 고유 기본 피해 동일 |
| 빠른 요원 | runner / character.movement_speed_multiplier | 1.15 | 같은 장비에서 기준 요원 대비 이동 배율 확인. 요원 교체 후 이전 효과 잔류 없음 |
| 장착으로 기본 화력 증가 | ballistic_core / module.DamageModifier.amount | 2 | 장착 시 기본 피해 가산, 해제 후 원복. 강화 추가분과 중복 계산하지 않음 |

## 3. 새로운 효과를 요청할 때

툴킷 선택지에 없는 행동을 비슷한 이름의 변수에 억지로 넣지 마세요. `field_id=custom_effect`로 요청하고 `value`에 발동·대상·종료·중첩 규칙을 적습니다. **이 경로는 시트/Notion 작성으로 접수하며 아직 자동 생성 UI는 제공하지 않습니다.** 새 대상 ID도 이 경로에서 제안할 수 있습니다.

```text
spec_id: chain-lightning-001
status: provisional
target_kind: weapon
target_id: pulse_rifle
field_id: custom_effect
value: 탄환 명중 시 120px 내 아직 맞지 않은 적에게 순차 전이, 최대 3명,
       대상당 4 고정 피해, 1초 내부 쿨타임, 같은 발동 중 재피격 금지
intent: 적이 모이면 눈에 보이는 전기 전이로 밀집 전투의 보상을 제공
acceptance: 고립 적은 추가 타격 없음, 4명 밀집 시 추가 대상 최대 3명,
            사망 대상 제외, 벽 통과 금지, 내외부 레벨과 독립
owner_status: pending
notion_url: 실제 원본 게시 링크
source_fingerprint: 현재 EffectGuide/툴킷에서 생성한 지문
```

이 예시는 **연쇄 번개가 현재 구현됐다는 뜻이 아닙니다.** 개발자는 새 정책 Resource·효과 실행 모듈·표현·성능 상한·E2E를 추가해야 합니다. 불명확한 벽/중첩/성장 규칙은 구현 완료로 처리하지 않습니다.

## 4. Google Sheets 작성 계약

기존 Weapon / Armor / Item / Skill / Character / Upgrade 탭은 그대로 유지합니다. 새 `EffectGuide`는 지원 대상·변수·현행 값·단위·동작·수정 경로를 보여주는 참조표입니다. `EffectSpec`은 구현 요청 목록이며 게임이 직접 읽는 밸런스 CSV가 아닙니다.

**1행 변수명 / 2행 한국어 설명 고정 / 3행부터 데이터.** EffectSpec의 예제는 현행 값을 그대로 적은 `draft/pending`이며 밸런스를 변경하지 않습니다.

| 열 | 입력 규칙 |
| --- | --- |
| spec_id | 소문자 영문·숫자·밑줄·하이픈 3~80자 |
| status | draft 초안 / provisional 임시 / confirmed 기획 확정 / hold 보류 |
| target_kind / target_id | skill·weapon·character·module / 실제 정의 ID |
| field_id / value | EffectGuide 변수와 허용값, 또는 custom_effect와 새 행동 설명 |
| notion_url | 확정·승인에는 실제 Notion HTTPS 근거 필수 |
| intent / acceptance | 기획 의도 / 사람이 확인할 성공·실패·종료 조건 |
| owner_status | pending / approved / rejected. 기획 상태와 별도이며 오너만 판단 |
| source_fingerprint | 명세를 작성한 코드 원본 지문. 최신 코드와 다르면 재검토 |

같은 대상·변수의 중복 행은 거절합니다. 기획의 과거 버전은 Notion 이력에 보존하고 활성 요청 목록은 충돌 없이 유지하세요. 빈 숫자는 0으로 취급하지 않습니다. `electric_area`를 새로 선택할 때 반경이 0이면 반경 행도 함께 필요합니다. 텍스트는 셀의 일반 텍스트로 붙여 넣고 수식으로 입력하지 마세요.

## 5. 개발자가 이어받는 방법

```sh
python scripts/build_effect_toolkit.py --check
node scripts/effect_toolkit.mjs --sheet --output outputs/effect-toolkit/plan.json
# 내려받은 파일도 동일하게 검증
node scripts/effect_toolkit.mjs --input EffectSpec.csv --output outputs/effect-toolkit/plan.json
```

검증기는 변수/범위/복합 조건/기획 상태/오너 상태/Notion 근거/코드 해시를 확인하고 **변경 계획만 출력**합니다. 실제 소스 파일·Resource 섹션·CSV 행 키·변수와 이전 값을 함께 제공합니다. 승인되지 않은 계획은 배포 지시가 아닙니다.

구현자는 변경 계획을 검토한 후 해당 모듈과 기존 Sheet/CSV를 동기화합니다. 새로운 행동에는 명시적 모듈 계약과 실행 경로를 추가하고 `build_effect_toolkit.py`의 허용 목록과 테스트를 확장합니다. 게임 데이터 변경 때는 기존 실시간 테스트 → CSV 확정 → Web payload → 릴리스 메타데이터 → 양 플랫폼 검증 절차를 유지합니다. 단순 명세 목록을 런타임 CSV로 오인해 Web payload에 포함하지 않습니다.

## 6. 모듈화·검수 기준

`build_effect_toolkit.py`는 코드 원본 추출, `effect-toolkit-engine.js`는 순수 명세 검증, `effect-toolkit.js`는 역할별 표시, `effect_toolkit.mjs`는 읽기 전용 시트/파일 입력과 계획 출력을 담당합니다. UI와 게임 실행을 결합하지 않습니다.

자동 검수는 전체 지원 변수의 현행 값, 0/빈값/범위, 원본 변경, 승인 분리, 잘못된 근거 URL, CSV 따옴표·줄바꿈, 중복, 광역 반경 조합, 신규 행동 분류를 확인합니다. 역할 UI는 모바일부터 데스크톱까지 범위 오류·명세 생성·수정 후 이전 결과 무효화·개발자 읽기 전용을 확인합니다. **이 검수 통과는 새 효과의 실제 플레이 검수를 대신하지 않습니다.**
