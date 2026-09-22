---
title: 첫 출격 선택과 액티브 40종
description: 요원 고정 패시브·초기 무장·공유 액티브 카탈로그와 SkillPattern 조정 계약
tags: [스킬, 패시브, 캐릭터, 무기, 시작, SkillPattern, 밸런스]
---

# 첫 출격 선택과 액티브 40종

## 플레이어에게 달라진 것

앱 시작에서 **PC/모바일 → 요원·무기 → 로비**로 이동합니다. 작전 게이트로 걸어가 F로 준비하는 경로는 유지합니다. 새 플레이의 기본 무장은 총기·근접 8종 중 선택합니다. Windows 저장 장비가 있으면 그것을 보존하고 로비 장비창에서 교체합니다. 재출격이 초기 장비를 다시 지급하거나 로비 세팅을 덮어쓰지 않습니다.

액티브는 기존 4종 + 신규 36종 = **40종**입니다. 기본 장착은 점멸·자기장·가속, 동시 장착은 3개이며 준비실/훈련장에서 바꿉니다. 각 정의의 기본 슬롯은 유지합니다. 신규 36종은 임시 무료 공용 풀이고 기존 아크 질주의 해금/획득 규칙은 유지합니다. “40종”은 동시에 40개를 쓰거나 40개의 전용 캐릭터가 있다는 뜻이 아닙니다.

이번 오너 요청으로 적용한 범위이며 Notion의 모든 수치가 확정되었다는 의미는 아닙니다. **액티브 공유·캐릭터 특화 수치는 임시**이고 캐릭터 전용 목록 제한은 아직 적용하지 않습니다. 기존 키트 전용 HP 회복과 수동 조준 없는 조작 원칙을 유지합니다.

## 요원 고정 패시브

| 요원 | 고정 역할 | 실제 특화 |
|---|---|---|
| 선봉대(뱅가드) | 전술 적응 | 기본 AP ×1.15 · 이동 중 자연 AP 회복 ×1.20 ([확정 계약](character-selection.md#tactical-adaptation-20260922)) |
| 질주자 | 이동·재배치 | 이동 ×1.10, 기동·자기 강화 액티브 쿨타임과 충전 회복 시간 ×0.80 |
| 방벽병 | 구역 유지 | HP +35, 방어 +2, 이동 ×0.92, 원형·고리 반경 ×1.15 |

패시브는 교체 가능한 액티브 슬롯이 아닙니다. 선택 요원의 정의가 소유하며 다른 계열 스킬에는 배율을 적용하지 않습니다. 신규 요원은 계열/배율 데이터로 확장하고 새로운 동작이 필요할 때만 별도 효과 계약을 추가합니다.

## 40종 구성

기존: **점멸, 원형 자기장, 기동 가속, 아크 질주**. [기본 효과와 자원](combat-skills.md).

신규 36종의 아래 값은 보정 전 임시 원본입니다. 피해는 한 대상 기준이며 실제 총 피해는 범위 안 체류·벽·생존·상태 연계에 따라 달라집니다.

| ID·이름 | 형태 | 행동 차이 | 피해 × 횟수 | 쿨타임 / AP |
|---|---|---|---:|---:|
| `arc_link` 연쇄 전격 | chain | 가까운 적 다섯에게 차례로 전격 연결 | 18 × 1 | 7s / 25 AP |
| `relay_stun` 정지 릴레이 | chain | 네 대상을 연결하여 공격과 이동 정지 | 5 × 1 | 10s / 25 AP |
| `overload_link` 과부하 연결 | chain | 감전 표식을 소모하면 연결 피해 세 배 | 16 × 1 | 11s / 35 AP |
| `relay_barrage` 반복 릴레이 | chain | 이동하며 세 대상에게 다섯 번 전격 연결 | 7 × 5 | 12s / 35 AP |
| `plasma_lance` 플라스마 창 | line | 정면의 좁고 긴 경로를 관통 | 32 × 1 | 8s / 25 AP |
| `cryo_ray` 냉각 광선 | line | 발동 방향 고정 광선으로 반복 둔화 | 5 × 6 | 10s / 25 AP |
| `breach_ray` 균열 광선 | line | 직선의 적에게 받는 피해 증가 표식 | 14 × 1 | 9s / 25 AP |
| `rotating_ray` 회전 절단광 | line | 플레이어를 중심으로 광선이 한 바퀴 회전 | 9 × 8 | 14s / 35 AP |
| `crossfire` 십자 섬광 | line | 발동 위치에서 네 방향으로 차례 발사 | 24 × 4 | 12s / 30 AP |
| `charged_rail` 축전 레일 | line | 경로 예고 뒤 좁은 고위력 관통 사격 | 85 × 1 | 16s / 40 AP |
| `fan_cut` 부채꼴 참격 | cone | 정면 부채꼴 근접 절단 | 35 × 1 | 6s / 20 AP |
| `suppression_fan` 제압 부채 | cone | 정면 넓은 구역의 적을 제압 | 8 × 1 | 11s / 30 AP |
| `frost_fan` 서리 분사 | cone | 움직이며 발동 방향에 냉각 분사 | 6 × 7 | 12s / 30 AP |
| `execution_fan` 처형 절단 | cone | 취약 표식을 소모하여 근접 피해 세 배 | 28 × 1 | 12s / 30 AP |
| `spiral_cut` 나선 검무 | cone | 가속과 함께 여섯 방향 회전 참격 | 13 × 6 | 12s / 35 AP |
| `seismic_pulse` 지진 파동 | circle | 주변 적에게 충격과 짧은 기절 | 20 × 1 | 12s / 30 AP |
| `thermal_bloom` 열화 개화 | circle | 밀집 지점 예고 뒤 폭발 | 70 × 1 | 15s / 40 AP |
| `static_trap` 정전 덫 | circle | 발동 위치에 남는 반복 제압 장판 | 10 × 6 | 16s / 35 AP |
| `frost_zone` 동결 구역 | circle | 밀집 지점에 고정 냉각 장판 | 4 × 8 | 15s / 30 AP |
| `corrosion_zone` 부식 구역 | circle | 밀집 지점의 적에게 반복 취약 부여 | 5 × 6 | 14s / 35 AP |
| `storm_mantle` 폭풍 외투 | circle | 짧은 사거리의 이동 전격과 방어 증가 | 9 × 10 | 18s / 40 AP |
| `orbit_guard` 궤도 방호 | ring | 방어를 높이고 주변 궤도 안의 적 타격 | 12 × 6 | 18s / 35 AP |
| `perimeter_mine` 외곽 지뢰 | ring | 안쪽은 안전하고 외곽 고리만 지연 폭발 | 60 × 1 | 15s / 35 AP |
| `containment_ring` 격리 고리 | ring | 고리를 지나오는 적을 반복 둔화 | 3 × 8 | 14s / 30 AP |
| `resonance_ring` 공명 고리 | ring | 감전 표식과 연계하는 세 번의 이동 고리 | 16 × 3 | 14s / 35 AP |
| `mark_target` 집중 표식 | single | 우선 대상 하나의 받는 피해 증가 | 5 × 1 | 7s / 15 AP |
| `ion_strike` 이온 저격 | single | 우선 대상 하나에 지연 고위력 타격 | 80 × 1 | 14s / 35 AP |
| `stasis_lock` 정지 구속 | single | 우선 대상 한 명을 장시간 제압 | 6 × 1 | 16s / 30 AP |
| `focused_barrage` 집중 포격 | single | 지정한 적이 살아 있는 동안 여섯 발 타격 | 13 × 6 | 12s / 30 AP |
| `shatter` 빙결 분쇄 | circle | 주변 둔화 표식을 소모해 폭발 피해 세 배 | 20 × 1 | 10s / 25 AP |
| `reactive_shell` 반응 장갑 | self | 이동을 조금 늦추고 방어력 대폭 증가 | 0 × 1 | 18s / 30 AP |
| `evasive_drive` 회피 구동 | self | 짧은 가속과 방어 보정으로 탈출 동선 확보 | 0 × 1 | 10s / 25 AP |
| `fortress_pulse` 요새 진동 | circle | 단단한 방호 중 주변 적을 주기적으로 둔화 | 8 × 5 | 20s / 40 AP |
| `assault_drive` 돌격 구동 | cone | 가속 중 발동 방향으로 근거리 연속 타격 | 10 × 8 | 16s / 35 AP |
| `null_wave` 무력화 파동 | circle | 주변을 취약하게 만들고 잠시 방어 확보 | 0 × 1 | 18s / 30 AP |
| `thunder_finale` 뇌전 종막 | circle | 밀집 지점에 예고 후 세 번의 대형 전격 | 22 × 3 | 24s / 55 AP |

## 기획자가 조정하는 곳

공용 [Google Sheet](https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/edit):

- **Skill**: 표시명, 기본 슬롯, AP·쿨타임·충전, 활성·획득/투자 정책. 기존 4행을 보존하고 36개 행 추가.
- **SkillPattern**: 신규 효과의 모양, 반경·폭·각도, 지연/간격/횟수, 대상 상한, 상태·연계, 자기 강화. 1행 변수 / 2행 한국어 설명 / 3행부터 데이터.
- **Character**: 고정 패시브 이름/설명과 계열·피해·쿨타임·범위 배율.

SkillPattern의 `cooldown/energy/slot/display_name`은 참고 미러입니다. 잠금 시 **Skill 값이 우선**합니다. 실시간 시험도 AP·충전·쿨타임은 Skill, 효과는 SkillPattern에서 읽습니다. 전체 요청이 성공하고 정의가 검증돼야 목록을 교체합니다. 잘못된 숫자·중복 ID·필수 효과 행 누락은 이전 유효 상태를 유지한 채 거부합니다.

실시간 시험 → Notion에 상태(임시/확정), 변경 ID·이유·기대 결과 기록 → 오너 확인 → 명시적 CSV 잠금 → 테스트 → 배포입니다. Sheet 편집만으로 공개 게임을 자동 변경하지 않습니다.

개발자 잠금 순서:

```powershell
python scripts/compile_tactical_skills.py --from-sheet
python scripts/sync_character_catalog.py
python scripts/compile_tactical_skills.py --check
pwsh -NoProfile -File scripts/test-game.ps1
```

신규 SkillPattern ID는 CSV 컴파일로 Resource를 생성한 뒤 배포해야 합니다. 실시간 모드는 아직 배포하지 않은 ID의 코드를 만들어 실행하지 않습니다. 투자/획득 정책 변경은 기존 투자 CSV 동기화와 함께 검토합니다.

[밸런스 계산기](../tools/balance-workbench.md)는 40개 정의를 읽고 선택 요원의 피해·쿨타임 특화를 반영합니다. 패턴 피해 곡선은 지정 적중률의 직접 피해 기준이며 벽·실제 이동·다른 스킬의 상태 연계·약화 중첩은 전투 시뮬레이션과 동일하다고 보증하지 않습니다. 제어/방어형은 피해 0도 정상입니다.

## 개발 계약과 검사

- `InitialLoadoutPanel`: 선택 ID 전달, 적용 전 실제 장착 규칙 재검증. 로비 장비가 작전 장비의 원본.
- `SkillSpecializationPolicy`: 캐릭터 계열에 맞는 배율만 반환.
- `SkillBalanceSnapshot`: 라이브 숫자를 검증한 독립 Resource로 복제. 출격 뒤 원본 Sheet/Resource 변경이 이미 발동한 효과를 변경하지 않음.
- `TacticalPatternEffect/Runtime`: 모양·스케줄·대상·상태·수명. Game에 36개 ID별 분기 없음.
- `EnemyStatusPolicy`: 일반 적 정지/둔화/약화, 보스 제어 저항. 상태 데이터와 전투 실행 분리.
- 최대 40펄스·대상64명·최소 간격0.1초. 효과 제거/훈련 종료 시 자기 강화 원복. 전장의 안개/방 문 상태는 바꾸지 않음.

검증: 40개 실제 CombatSkillSystem 발동/AP 차감/쿨타임 재발동 차단, 신규36개 효과 펄스/타격/원복, 3요원×8무기 초기 선택→로비→작전→정상 중단/재준비 24조합, 라이브 스냅샷과 잘못된 값 거부. 이는 자동 계약 검증이며 **일반 10분 플레이/F 간헐 탈출의 완료 근거가 아닙니다**.

## 참고한 역할 설계

[Warframe Volt](https://www.warframe.com/en/game/warframes/volt)의 전기 연쇄·기동/보호, [Mag](https://www.warframe.com/en/game/warframes/mag)의 구역 제어, [Rhino](https://www.warframe.com/en/game/warframes/rhino)의 돌파·방어·광역 제어를 탑다운 이동/자동 타게팅에 맞춰 재구성했습니다. [퍼스트 디센던트 개발 노트](https://tfd.nexon.com/en/news/3499658)의 캐릭터 강점 유지 방향도 참고했습니다. 명칭·그래픽·설명·수치를 복사하거나 원작 스킬 전체를 재현한 것은 아닙니다. 이펙트는 프로젝트 코드 도형을 사용합니다.
