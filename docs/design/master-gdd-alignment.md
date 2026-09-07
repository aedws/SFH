---
title: Master GDD 구현 대조
description: 최신 GDD와 66개 Notion 작업의 코드 근거·충돌·미구현·오너 판단을 분리한 2026-09-07 대조
tags:
  - 기획
  - Master GDD
  - 진행률
  - 확정 사항
  - 로드맵
---

# Master GDD 구현 대조

## 최신 원본과 판정 범위

- [최신 Master GDD](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed): v128, 본문 62블록. 2026-09-06 18:09:49 KST 편집, 2026-09-07 재수집.
- [기능 구현·상태 트래커](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2): 66행 전체 수집, hasMore=false. 결정(미구현) 52 / 미정(검토필요) 14.
- 스냅샷: `docs/assets/notion-source-snapshot.json`, `docs/assets/notion-tracker-snapshot.json`. 수동 판단표: `docs/assets/notion-code-audit.json`.
- 코드 기준: `c16bd24827c596f419d224365b9724f6455b7b22`. 코드와 기존 테스트 소스를 읽은 정적 검토이며 새로운 66항목 실제 플레이 완료 선언이 아닙니다.
- 이전 2026-09-02 GDD v153은 백업본입니다. **이전 96%를 최신 진행률로 사용하지 않습니다.** 완료 이력은 Git과 일별 업데이트에 보존합니다.
- GDD 본문과 트래커는 독립 해시로 관리하며 상위 페이지 수정은 본문 변경으로 세지 않습니다. 체크박스·미구현 태그는 실제 코드 부재나 오너 승인을 대신하지 않습니다.

확정도 가중 코드 대응도는 N26-03A/B 후 **73.2%**입니다. 최초 대조 72.4%에서 타게팅 1행의 부분 대응을 코드 근거 있음으로 변경했습니다. 나머지 65행과 기획 원문 상태는 유지하며, 최초 하락은 기능 삭제가 아니라 새 요구 확대와 과대 판정 정정입니다.

## 충돌 판단과 오너 결정 {#owner-conflicts}

| ID | 충돌·공백 | 개발 검토 결론 / 권장안 | 확정할 부분 |
|---|---|---|---|
| DEC-N26-HEALTH | 키트만 회복 vs 자연 회복·HP 드랍·레벨업 회복 | 원인별 회복 게이트와 표준 생존 프로필로 분리. 승인 전 현행 유지 | 자연 회복·드랍·레벨업·버프·거점/훈련 허용표. 이전 사용자 레벨업 회복 복구 지시 대체 범위 |
| DEC-N26-AP | 미사용 AP 자연 회복 vs 드랍 복원·충전 시간 복구 | AP와 충전은 별도 정책 | 지연·초당량·최대치·기존 에너지 드랍 공존 |
| DEC-N26-POUCH | 사망 전부 소실 vs 파우치 보존, 룬 자동 환전 vs 원형 보존 | 별도 컨테이너 소유권·정산 예외, 중복 소유 금지 | 허용 종류/크기, 1~2·3~4칸 정확한 값, 입출금·중단·재접속, 해금/환전 우선순위 |
| DEC-N26-DEPTH | 장비 착용자 통과 vs 오염 피해 면역 | 접근 자격과 환경 피해 분리. 수문장은 기존 추격 보스와 별도 역할 | 입장 차단인지 피해 면제인지, 키카드 소비·재입장, 보장 드랍 시 가방 부족 |
| DEC-N26-BLOOD | HP 비용·흡혈·키트 반감 신규 결합 | HP/AP 지불과 회복 효과 정책 조합 | 자해 사망/최소 HP, DOT·다중 타격 흡혈 상한, AP 병행/대체 조건 |
| DEC-N26-SOCKETS | 공용 세션 슬롯 vs 무기/스킬 소켓 | 개별 귀속 요구는 부분 대응으로 판정 | 장비별 귀속·교체·해제·환전·중복 효과 |
| DEC-N26-TECH | TileMapLayer 맵·Area2D 타게팅 지정 vs 자체 맵/거리 판정 | 탈출 구역은 실제 Area2D로 충족. 맵·타게팅의 대체 구현 수락 여부를 별도 판단 | 엔진 노드 지정이 필수인지, 대체 구현 성능 기준 |
| DEC-N26-STATUS | 구현된 이동·Q·탈출도 트래커 미구현 | 노션 요구 상태와 코드 검증 상태를 분리, 진행률 0% 초기화 금지 | 오너 근거 수락 후 기획자가 트래커 갱신 |

위 결정은 **제안/판단 대기**입니다. 이번 작업은 회복 삭제, 파우치 지급, 화폐 변경, 실서버 구축을 실행하지 않습니다. 수치 범위·예시도 임의 확정하지 않습니다.

## 명확한 코드 차이

1. **N26-03A/B 구현·자동 회귀 완료:** 중심점·효과 반경 전달(`d50fdb6`) 후 원형 최대 포함 각도 스윕·안전한 평균(`add3a33`)을 연결했습니다. 실제 효과 적중·240개 독립 대조·72명 성능을 검증했습니다. 사람 재미 수락·타게팅 갱신 주기·Area2D 기술 결정은 별도입니다.
2. `CombatResourceSystem.advance`는 충전 횟수만 복구하며 AP 초당 재생은 없습니다. 충전을 에너지 회복으로 오판하지 않습니다.
3. 기본 자연 회복은 4초 후 초당 3 HP, 최대 65% 상한입니다. HP 드랍과 `ProgressionSystem.level_up_heal_amount=12`도 별도 존재해 자연 회복만 꺼서는 ‘키트만’ 규칙이 되지 않습니다.
4. `RunSettlementService`에 성공/사망 생명 주기는 있지만 파우치 컨테이너/보존 원장은 없습니다. 일반 창고와 파우치 보호는 다릅니다.

## 작업 편성

[현행 N26 작업선](current-milestone-workline.md#notion-20260907)에서 선행 결정·모듈·플레이어 수락 기준을 확인합니다. 기존 P7/P8 이력을 보존하고 P9/P10 착수 판단 전에 생존·파우치·심층과 기존 기능 차이를 정렬합니다. N26은 Notion 공식 Phase가 아닌 내부 변경 묶음입니다.

새 목록이 필요한 **실제 구현 단계**에서 Google Sheet를 확장합니다. 회복/비용 프로필, 파우치 허용 목록, 저항·키카드 목록은 계획일 뿐 아직 Sheet/CSV를 변경하지 않았습니다. 1행 변수명·2행 설명·3행 데이터, 실시간 테스트→확정 CSV를 유지합니다.

## 독립 구현 후속

2026-09-07 사용자 지시에 따라 판단이 필요 없는 N26-03A/B를 구현했습니다. 최초 코드 기준 이후 근거를 해당 행에 추가했습니다. 37개 구현 근거·8개 부분에서 **38개 구현 근거·7개 부분**으로 변경해 `(38×3 + 7×0.5×3) / 170 = 124.5/170 = 73.2%`입니다. 회복·소유권·수치 정책 및 14개 미정의 확정 여부는 변경하지 않았습니다. 다음은 N26-08A 훈련 세팅·복원이며 [독립 작업 순서](current-milestone-workline.md#notion-20260907)와 [모듈 계약](../features/smart-targeting.md)을 확인합니다.

## 최초 대조 작업의 검증

2026-09-07: 원본·트래커 라이브 해시 일치, 수집 범위·페이지 나눔·미정 판독·66행 대응 회귀 22개 통과. 위키 strict 빌드, 96문서 링크·계층 검사, 역할 권한 테스트와 신규 스냅샷 비로그인 차단 검사를 통과했습니다. 오너 콘솔의 8결정·8작업 선행 관계도 검증했습니다. 게임 실행 코드는 변경하지 않았으며 신규 요구의 플레이 E2E는 N26-08에 남깁니다.

<!-- notion-audit:start -->

## 66개 항목 코드 대조

정적 코드·기존 테스트 소스 대조: **124.5/170 = 73.2%**. 출시 준비율이나 이번 턴의 실제 플레이 통과율이 아닙니다.

구현 근거 있음 38 / 부분 대응 7 / 규칙 충돌 1 / 신규 미구현 6 / 기획 판단 대기 14

확정 요구 ×3, 미정 ×1. 구현 근거 1점, 부분 0.5점, 충돌·신규 미구현·판단 대기 0점. 테스트 파일은 검증해야 할 기존 근거이며, 파일 존재만으로 최신 요구 전체의 E2E 통과를 선언하지 않습니다.

<details markdown="1"><summary>DATA-01-LOOT · 7개 항목</summary>

### [룬 1개당 골드 환전 가치 산정 공식 및 배율](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040818698d7e0ee28c35434)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 룬 티어별 환전 기본 골드(예: 100/300/1000G) 확정 필요

수락 기준: 룬 티어별 환전 기본 골드(예: 100/300/1000G) 확정 필요

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [사망 실패 시 런 획득물 및 지참 로드아웃 소실](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081f19fd2cad6784a8d28)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

성공 시 환전·영구 등록·창고 / 사망 시 소실을 생명 주기별 처리. 보안 파우치 예외는 없음.

수락 기준: 던전 내 사망 시 인벤토리 및 장착 템 증발

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [세션 증폭 룬/코어 인게임 실시간 소켓 장착](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040812e8dcfd3df7845372a)

노션: **결정 (미구현)** · 코드: **부분 대응** · 작업: **N26-01**

세션 공용 룬2·코어1·유물1 슬롯은 있음. 요구한 무기/스킬 개별 소켓 귀속과 동일한지는 미확정.

수락 기준: 획득한 룬을 장비/스킬 소켓에 꽂아 세션 내 화력 폭발

코드 경계: `game/features/session_sockets/session_socket_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [세션 증폭 룬/코어 탈출 시 대량 골드 자동 환전](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040815ab0aeef36ba2b2e92)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

성공 시 환전·영구 등록·창고 / 사망 시 소실을 생명 주기별 처리. 보안 파우치 예외는 없음.

수락 기준: 탈출 결과창에서 룬이 골드로 일괄 정산 환전

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [영구 자산형 장비 R키 현장 즉시 장착/스왑](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040810999edd6fb80fbe7f5)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

현장 장비 교체 경로가 있음. 인벤토리 R 회전과 컨텍스트 분리 회귀를 유지.

수락 기준: 장비 비교창에서 R키 누르면 현장에서 즉시 장착

코드 경계: `game/features/field_loot/field_loot_equip_service.gd`

기존 검사 근거: `game/tests/field_loot_acquisition_contract_test.gd`

### [영구 자산형 장비 탈출 성공 시 로비 상점 영구 해금](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040812281c4e91a314d0451)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

성공 시 환전·영구 등록·창고 / 사망 시 소실을 생명 주기별 처리. 보안 파우치 예외는 없음.

수락 기준: 탈출 성공 시 획득 아이템이 로비 상점에 영구 등록

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [영구 자산형 장비(무기/스킬/도면) F키 가방 획득](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081cdbb32c02a13bc9624)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

현장 획득 요청과 가방 수납·실패 피드백 경로의 기존 근거.

수락 기준: 전리품 근처에서 F키 누르면 가방으로 습득

코드 경계: `game/features/field_loot/field_loot_inventory_service.gd`

기존 검사 근거: `game/tests/field_loot_acquisition_contract_test.gd`

</details>

<details markdown="1"><summary>DATA-02-POUCH · 2개 항목</summary>

### [보안 파우치 (사망 시 100% 보존되는 안전 금고 기본 1~2칸)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408180a869d144728e8907)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-04**

파우치와 확장·사망 보존 정책 미구현. 일반 가방 크기 확장만으로 대체 불가.

수락 기준: 파우치 내 설계도/유물 수납 후 사망 시 로비 창고로 안전 회수 확인

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [보안 파우치 거점 성장 업그레이드 (최대 3~4칸 확장)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408145bf92e84e1e0a0f01)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-04**

파우치와 확장·사망 보존 정책 미구현. 일반 가방 크기 확장만으로 대체 불가.

수락 기준: 거점 업그레이드 완료 시 파우치 슬롯이 3~4칸으로 확장되는지 확인

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-00-ENV · 6개 항목</summary>

### [Area2D 기반 타겟팅 및 탈출 구역 콜리전 구조 셋업](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081fa8aa8ee14acbebda3)

노션: **결정 (미구현)** · 코드: **부분 대응** · 작업: **N26-01**

ExtractionZone은 실제 Area2D이며 body_entered/body_exited와 원형 충돌을 사용. 타게팅은 Area2D 후보 수집이 아닌 거리·스냅샷 정책이므로 지정 구조 전체는 부분 대응.

수락 기준: 반경 콜리전 진입/이탈 시그널 정상 감지

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [CharacterBody2D 기반 플레이어 이동 물리 셋업](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408188aaf0cf37578f63be)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

플레이어가 CharacterBody2D이며 이동 컴포넌트와 충돌을 분리.

수락 기준: 충돌체를 가진 캐릭터가 2D 평면에서 정상 이동

코드 경계: `game/features/player/player.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [Custom Resource 기반 데이터 관리 아키텍처 셋업](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040817bbd84efe3ea8a93e7)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

기존 Godot 프로젝트·선택 모듈과 기본 루프 검사 근거. 지정 기술/성능의 완전 일치는 별도 확인.

수락 기준: 무기/스킬/룬 데이터가 리소스 파일로 관리 및 로딩

코드 경계: `game/core/feature_manifest.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [Godot 4.x 2D 탑다운 엔진 기본 프로젝트 및 씬 구축](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081fd8f66dbb618b30881)

노션: **결정 (미구현)** · 코드: **부분 대응** · 작업: **N26-08**

Godot 프로젝트 존재. 60FPS는 기기·해상도·부하 실측 수락이 필요하며 파일 존재만으로 달성 판정하지 않음.

수락 기준: 2D 뷰포트에서 기본 씬이 60FPS로 구동 확인

코드 경계: `project.godot`

기존 검사 근거: `game/tests/performance_budget_test.gd`

### [TileMapLayer 기반 2D 던전 맵 렌더링 파이프라인](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040813893c2fc6eddfae751)

노션: **결정 (미구현)** · 코드: **부분 대응** · 작업: **N26-01**

맵 기능은 있으나 game 코드에서 TileMapLayer 사용 근거 없음. 동일 결과의 현재 방식 유지 vs 지정 기술 이행을 오너 판단.

수락 기준: 타일맵 레이어로 벽/바닥 충돌 및 렌더링 확인

코드 경계: `game/features/map_generation/map_generator.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [타일셋 그래픽 스타일 및 픽셀 뷰포트 해상도 규격](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408128b071df1c2bf344ce)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 해상도(예: 640x360 픽셀아트 vs 1920x1080) 확정 필요

수락 기준: 해상도(예: 640x360 픽셀아트 vs 1920x1080) 확정 필요

코드 경계: `game/core/feature_manifest.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

</details>

<details markdown="1"><summary>PLAN-01-CTRL · 10개 항목</summary>

### [F 키 입력 시 맵 내 오브젝트 상호작용](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040816bb578f9cc78ce74a2)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

물리 Action·스킬 배치·쿨타임·상호작용 구현 근거. 실제 키는 K 설정 값을 사용.

수락 기준: 상자/신호기 근처에서 F키 누를 때 상호작용 트리거

코드 경계: `game/features/skill_binding/skill_binding_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [Q 키 입력 시 주무기 ↔ 보조무기 실시간 스왑](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408183a83eff9dc784a5ef)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

주·보조 무기 전환과 태그 적합성 갱신의 기존 구현 근거.

수락 기준: 무기 교체 시 들고 있는 스프라이트/태그 즉각 변경

코드 경계: `game/features/equipment/equipment_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [Space 키 입력 시 이동 방향 회피(대쉬) 발동](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040817ca4e2f02aff23ace5)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

Input.get_vector 및 현재 dash Action 기반 가속·대시. 실제 기본 키/재매핑은 KeyMapping과 연동.

수락 기준: 대쉬 시 순간 가속 및 회피 동작 수행

코드 경계: `game/features/player/player_movement.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [WASD 키보드 8방향/360도 평면 이동 벡터 제어](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081ef93aced46ee9dcd7e)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

Input.get_vector 및 현재 dash Action 기반 가속·대시. 실제 기본 키/재매핑은 KeyMapping과 연동.

수락 기준: 조준점 무관하게 입력 방향으로 즉각 이동 확인

코드 경계: `game/features/player/player_movement.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [공용 자원(AP/스태미나) 소모 및 회복 사이클](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081f9b4ebcbb242aa37ab)

노션: **결정 (미구현)** · 코드: **부분 대응** · 작업: **N26-02**

AP 차감과 드랍 복원은 있음. advance는 충전 횟수만 복구하며 미사용 초당 AP 자연 회복은 없음. 충전=에너지로 오판하지 않음.

수락 기준: 스킬 사용 시 AP 차감, 미사용 시 초당 자연 회복

코드 경계: `game/features/combat_resources/combat_resource_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [기본 AP 최대치 및 초당 자연 회복량 기본 수치](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081c69ad2d96b2d2305c1)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 기본 AP(예: 100) 및 초당 회복량(예: 20) 확정 필요

수락 기준: 기본 AP(예: 100) 및 초당 회복량(예: 20) 확정 필요

코드 경계: `game/features/skill_binding/skill_binding_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [마우스 좌클릭 등 기본 스킬 홀드(Hold) 연속 시전](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081e589a4dca71f46ec3f)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

기본 공격 홀드 연사 경로 구현. 모든 액티브 스킬의 자동 반복을 확정한 것으로 확대하지 않음.

수락 기준: 버튼 누르고 있을 때 공속/쿨타임 주기로 자동 연사

코드 경계: `game/features/weapons/auto_weapon.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [스킬별 개별 쿨타임(Cooldown) 카운트다운](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408102b0c9db415bca981e)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

스킬별 쿨타임과 자원 가드 존재.

수락 기준: 스킬 사용 후 쿨타임 완료 전까지 재사용 불가

코드 경계: `game/features/combat_skills/combat_skill_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [완전 자유 스킬 바인딩 (Any Skill to Any Key)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408127b2fee3b3ce1920c1)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

스킬→Action 매핑과 물리 키→Action 매핑은 별도 서비스. 충돌 교환·저장 계약 유지.

수락 기준: 인풋 슬롯(좌/우클릭, Space, 1~9)에 임의 스킬 1:1 자유 매핑

코드 경계: `game/features/skill_binding/skill_binding_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [인게임 최대 동시 장착 스킬 슬롯 수 확정](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040816daecbdc8652d0d8de)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. UI 상 4개, 5개, 6개 중 최종 규격 확정 필요

수락 기준: UI 상 4개, 5개, 6개 중 최종 규격 확정 필요

코드 경계: `game/features/skill_binding/skill_binding_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

</details>

<details markdown="1"><summary>PLAN-02-TARGET · 6개 항목</summary>

### [광역기 클러스터 탐색 반경 기본값 수치](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081768debc7f5a868a5ff)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 클러스터링 밀집도 판정 반경(px) 확정 필요

수락 기준: 클러스터링 밀집도 판정 반경(px) 확정 필요

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [광역기: 스킬 반경 내 최대 적 밀집 클러스터 중심점 자동 투하](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408147a809d56ce5ef98cc)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

N26-03A/B(d50fdb6, add3a33): 중심 보존·효과 반경/배율 전달, 원형 최대 포함 각도 스윕과 안전한 평균, 사거리·대표 적·기존 정책 호환. 240개 독립 교차점 대조, 36개 회전 배치, 실제 효과 2명/5명 적중·72명 요청 성능·입력 E2E 통과. 사거리 안 적 중심 기준 구현 근거이며 신규 기본 스킬/사람 재미 수락/Area2D 방식 결정은 아님.

수락 기준: 몹이 가장 뭉쳐 있는 위치의 중심 좌표에 스킬 투하

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`, `game/features/smart_targeting/circular_coverage_solver.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`, `game/tests/smart_targeting_center_contract_test.gd`, `game/tests/circular_coverage_contract_test.gd`

### [단일기: 사거리 내 최단거리(Closest) 적 기본 록온](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081dca9bcd63057e33c1b)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

대상 선택 정책의 nearest/highest_health/elite/direction 분기와 기존 검사 근거.

수락 기준: 플레이어와 가장 가까운 적을 우선 추적 발사

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [단일기: 특정 옵션 시 최고체력/엘리트(Highest HP) 동적 전환](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040813c8525fceeaed2654f)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

대상 선택 정책의 nearest/highest_health/elite/direction 분기와 기존 검사 근거.

수락 기준: 옵션 활성화 시 사거리 내 최고 HP 적으로 타겟 변경

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [이동기: 현재 입력된 이동 방향 벡터로 즉시 발동](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081a9b8c9f6677ca3970c)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

대상 선택 정책의 nearest/highest_health/elite/direction 분기와 기존 검사 근거.

수락 기준: 이동 방향 벡터로 즉시 대쉬/돌진 발동

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [타겟 록온 갱신 주기 (초당 30회 vs 60회)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081008288f8c33727429f)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 성능 및 타겟 전환 반응속도 튜닝 필요

수락 기준: 성능 및 타겟 전환 반응속도 튜닝 필요

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

</details>

<details markdown="1"><summary>PLAN-03-FLOW · 5개 항목</summary>

### [1단계 로비 허브 상시 공간 인터페이스 구축](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408169834bc9955f1af304)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

거점→준비→확정 투입→정산 복귀 연결과 조합별 기존 계약 검사. 새로운 UI 정책 수락은 별도.

수락 기준: 창고, 상점, 제작소, 연습장, 도감, 랭킹 모듈 접근 가능

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [2단계 출격 준비 세션 (로드아웃 + 맵 계약 + 페널티)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081e6b05ff5697a9bfd26)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

거점→준비→확정 투입→정산 복귀 연결과 조합별 기존 계약 검사. 새로운 UI 정책 수락은 별도.

수락 기준: 출격 클릭 시 작전 브리핑 세션 진입 및 총비용 차감

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [3단계 인게임 던전 세션 로딩 및 결과 복귀](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040818d8fa2cedb610d6633)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

거점→준비→확정 투입→정산 복귀 연결과 조합별 기존 계약 검사. 새로운 UI 정책 수락은 별도.

수락 기준: 계약 완료 시 던전 로딩, 탈출/사망 시 로비 복귀

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [인게임 진입/복귀 시 씬 전환 로딩 연출](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d4a174d2cb05748c11)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 페이드 인/아웃 또는 암전 연출 규격

수락 기준: 페이드 인/아웃 또는 암전 연출 규격

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [출격 준비 세션 UI 상세 레이아웃 및 UX](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040818883aecd19e9ee4a43)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 단일 화면 모달 vs 탭 분할 화면 UI 확정 필요

수락 기준: 단일 화면 모달 vs 탭 분할 화면 UI 확정 필요

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-04-SHOP · 8개 항목</summary>

### [상점 리롤 1회당 비용 증가 곡선 (점진 증가 vs 고정)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408128baafd108e1f9602f)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 리롤 비용(예: 100G ➔ 200G ➔ 400G 등) 확정 필요

수락 기준: 리롤 비용(예: 100G ➔ 200G ➔ 400G 등) 확정 필요

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [상점: 골드 소모 수동 리롤(Reroll) 기능](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d8bd12f016a1a7a63e)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

회전 상점·리롤·품질 매물 경로 구현. 운영 수치는 임시이며 확정 승인과 구분.

수락 기준: 리롤 버튼 클릭 시 골드 차감 후 매물 즉시 갱신

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [상점: 기본 순정품 및 고성능 꿀매물 무작위 스폰](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081a2bd08e8bcb4537422)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

회전 상점·리롤·품질 매물 경로 구현. 운영 수치는 임시이며 확정 승인과 구분.

수락 기준: 표준품 및 추가옵션 꿀매물이 무작위 확률로 등장

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [상점: 성능 -10%~-30% 손상된 하자품 헐값(20~30%) 판매](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040811db001d577cf80a660)

노션: **결정 (미구현)** · 코드: **부분 대응** · 작업: **N26-01**

손상 품질 실물·성능 적용은 있음. -10~-30% 성능 및 정가20~30% 가격 전체 범위 보장은 운영 데이터 재대조 필요.

수락 기준: 초특가 손상 장비가 상점 매물로 스폰

코드 경계: `game/features/p5_hub_progression/shop_quote_policy.gd`

기존 검사 근거: `game/tests/shop_quality_inventory_contract_test.gd`

### [상점: 인게임 세션 복귀 시 자동 품목 갱신(로테이션)](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040810fb02cfd14fa4b714c)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

회전 상점·리롤·품질 매물 경로 구현. 운영 수치는 임시이며 확정 승인과 구분.

수락 기준: 런을 다녀올 때마다 상점 매물 자동 새로고침

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [손상 장비에 붙는 세부 페널티 목록 풀](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081e4bfade202866c131b)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 공격력 저하, 공속 저하, AP 소모 증가 등 풀 확정 필요

수락 기준: 공격력 저하, 공속 저하, AP 소모 증가 등 풀 확정 필요

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [제작소: 추가 재화 소모를 통한 추가 옵션/소켓 고점 부여](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040810f83b7fb7f6ebb80a9)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

비용·재료·옵션/소켓·실물·거래 ID 원자 적용. 옵션 범위 임시 승인은 별도.

수락 기준: 제작 시 랜덤 추가 옵션/소켓이 붙어 빌드 고점 돌파

코드 경계: `game/features/p5_hub_progression/workshop_craft_transaction_service.gd`

기존 검사 근거: `game/tests/workshop_craft_transaction_contract_test.gd`

### [제작소: 파밍한 설계도 영구 등록 기반 확정 타겟 제작](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040814c99d0c971098fd15c)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

도면 영구 등록 기반 제작 자격과 중복 등록/재접속 보존 구현.

수락 기준: 보유 설계도로 원하는 장비 골드 소모 확정 제작

코드 경계: `game/features/p5_hub_progression/workshop_unlock_service.gd`

기존 검사 근거: `game/tests/workshop_blueprint_registry_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-05-TRAIN · 5개 항목</summary>

### [단일 고체력 보스 허수아비 더미 배치](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040811eba68f8adf646f3ac)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

단일 1기·밀집 8기 더미, 실제 공격·계측·무비용 장비 편집·퇴장 원복의 기존 E2E 근거.

수락 기준: 단일 록온 및 단일 DPS 측정 더미 피격 동작

코드 경계: `game/features/training_ground/training_ground_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

### [밀집 잡몹 허수아비 더미군 배치](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d3b102c4b1eda1ef98)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

단일 1기·밀집 8기 더미, 실제 공격·계측·무비용 장비 편집·퇴장 원복의 기존 E2E 근거.

수락 기준: 광역 클러스터링 및 연쇄 폭발 범위 타격 테스트

코드 경계: `game/features/training_ground/training_ground_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

### [보유 장비/스킬/룬 무상 자유 세팅 콘솔](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040810bb4e6fd07961bb518)

노션: **결정 (미구현)** · 코드: **부분 대응** · 작업: **N26-08**

N26-08A: 보유 장비·스킬·기존 공용 RunAsset 시험, 종료/전환/실패 복원·저장 격리 자동 계약 추가. 장비별 소켓 귀속과 보유 룬 영구 목록의 최신 기획 동등성은 미수락이므로 partial 유지. 근거: game/tests/training_loadout_restore_contract_test.gd

수락 기준: 연습장 내에서 비용 없이 자유롭게 빌드 스왑

코드 경계: `game/features/training_ground/training_loadout_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

### [실시간 DPS, 단일 타격 수치, AP 소모율 모니터링 UI](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408134bf81d6d748487eb2)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

타격·DPS·AP 소모율·쿨타임 계측과 HUD 연결의 기존 검사 근거.

수락 기준: 허수아비 공격 시 화면 상단/측면에 실시간 수치 표기

코드 경계: `game/features/training_ground/training_telemetry_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

### [허수아비 속성 저항 및 방어력 설정 옵션 지원](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408103a93cd48292d9f86b)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 연습장 옵션 패널에서 더미 방어력 조절 기능 여부

수락 기준: 연습장 옵션 패널에서 더미 방어력 조절 기능 여부

코드 경계: `game/features/training_ground/training_ground_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

</details>

<details markdown="1"><summary>PLAN-06-EXTRACT · 7개 항목</summary>

### [구역 이탈 시 타이머 일시정지(Pause) 및 재진입 재개(Resume)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081aa8a0fd4dac4b38604)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

신호기 활성·체류 카운트다운·이탈 일시정지·재개·성공 정산 구현. 방어 시간/배율 승인 별도.

수락 기준: 원 밖으로 나가면 타이머 일시정지, 재진입 시 재개

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [기본 탈출 방어 카운트다운 시간 기본값 (15초 vs 20초)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081cab26af5ed495e7156)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 맵 크기별 탈출 방어 시간 확정 필요

수락 기준: 맵 크기별 탈출 방어 시간 확정 필요

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [맵 내 탈출 신호기(Beacon) 접근 후 F키 상호작용 가동](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081739ff3e8871dc690f7)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

신호기 활성·체류 카운트다운·이탈 일시정지·재개·성공 정산 구현. 방어 시간/배율 승인 별도.

수락 기준: F키 입력 시 탈출 방어 시퀀스 활성화

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [원형 탈출 구역(Area2D) 내 N초 생존 카운트다운](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081c6b32efda2ccb10389)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

ExtractionZone은 Area2D를 상속하고 원형 CollisionShape2D를 구성. 반경 내 방어 카운트다운·이탈 일시정지·재진입 재개·완료 신호 연결. N초 운영값 확정은 별도.

수락 기준: 구역 내 체류 시 타이머 작동 및 웨이브 스폰

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [타이머 0초 도달 시 탈출 성공 및 정산창 진입](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408106ad61d91cfe0c6f1b)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

신호기 활성·체류 카운트다운·이탈 일시정지·재개·성공 정산 구현. 방어 시간/배율 승인 별도.

수락 기준: 생환 성공 처리 및 획득물 영구 정산

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [탈출 활성화 시 몰려오는 몬스터 웨이브 스폰 배율](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081378239cf2fd6b253e8)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 일반 대비 스폰 밀도 가중치 수치

수락 기준: 일반 대비 스폰 밀도 가중치 수치

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [파산 방지: 무료 기본 무장 및 기본 맵 상시 제공](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081189deee5b4e70508fb)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

BankruptcyProtectionPolicy가 잔액 조건과 entry_cost=0인 반복 무료 출격 프리셋을 제공. 기본 무장·무료 진입은 P5 계약 검사로 확인하며 탈출 타이머와 별개.

수락 기준: 잔고 0원 시 언제든 기본 무장 무료 지급 (Zero-Risk)

코드 경계: `game/features/p5_hub_progression/bankruptcy_protection_policy.gd`, `game/features/p5_hub_progression/p5_hub_progression_service.gd`

기존 검사 근거: `game/tests/p5_hub_progression_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-07-LEADER · 5개 항목</summary>

### [동일 규격(대형 맵+페널티) 내 비동기 3대 래더 집계](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081c88a80fd7b8c71b99d)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

대형/페널티 규격의 로컬 3대 보드·시즌 경로. 실제 계정/서버 검증과 로컬 기록은 별도.

수락 기준: 최다 루팅, 스피드런, 최다 킬 3대 기록 등록 (P6 로컬)

코드 경계: `game/features/conditional_ranking/conditional_ranking_system.gd`

기존 검사 근거: `game/tests/ranking_season_contract_test.gd`

### [시즌 명예 보상(칭호, 오라 이펙트) 지급](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081159b5cc24724367086)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

로컬 지급·칭호/오라 장착 구현. 실서버 보상 지급으로 간주하지 않음.

수락 기준: 상위 랭커 전용 칭호 및 캐릭터 오라 이펙트 장착

코드 경계: `game/features/conditional_ranking/season_reward_service.gd`

기존 검사 근거: `game/tests/season_reward_contract_test.gd`

### [실서비스 계정 서버 및 무결성 검증 연동](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408185ae76d5cd6a8c0355)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 실서버 랭킹 API 연동 (현재 P6 로컬 마일스톤 상태)

수락 기준: 실서버 랭킹 API 연동 (현재 P6 로컬 마일스톤 상태)

코드 경계: `game/features/conditional_ranking/conditional_ranking_system.gd`

기존 검사 근거: `game/tests/ranking_season_contract_test.gd`

### [원정 맵 크기(소/중/대) 및 Biome 계약 선택](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040815fb78de820fa8127de)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

규모·지역 계약 및 조합 검증 구현.

수락 기준: 맵 크기 및 지역별 드랍 테이블 선택 기능

코드 경계: `game/features/operation_contract/operation_contract_service.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [자발적 페널티 모디파이어 선택 시 보상 배율(Multiplier) 증가](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408113b892e6ce524b1f43)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

원정 계약·페널티 보상 배율 견적·확정 연결.

수락 기준: 페널티 토글 시 최종 보상 배율 실시간 산출

코드 경계: `game/features/operation_contract/operation_contract_service.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-08-SURVIVAL · 2개 항목</summary>

### [표준 자원 마모형 체력 모델 (자연회복 불가, 소모품 한정 관리)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408159819af0dc9eb951b5)

노션: **결정 (미구현)** · 코드: **규칙 충돌** · 작업: **N26-02**

기본 자연 회복 true(4초 후 초당3,65%상한), HP 드랍과 레벨업12회복이 소모품 한정 요구와 충돌. 승인 전 유지.

수락 기준: 피격 시 체력이 영구 누적 차감되고 자연 회복되지 않는지 확인

코드 경계: `game/features/health_recovery/health_recovery_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [혈전/버서커 특화 빌드 (HP 소모 스킬 + 흡혈 + 회복약 효과 반감)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081658cffcd45118d9084)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-07**

AP 비용 계약만 있음. HP 지불·타격/처치 흡혈·물약50%를 결합한 별도 빌드 정책은 미구현.

수락 기준: 스킬 시전 시 HP가 차감되고 타격 시 흡혈 및 물약 효과 50% 반감 확인

코드 경계: `game/features/combat_resources/combat_resource_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

</details>

<details markdown="1"><summary>PLAN-09-DEPTH · 3개 항목</summary>

### [심층 코어 우회 돌파로 (수문장 처치 시 저항 장비 100% 드랍)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081c1a28dfe60b47f8cf9)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-06**

저항 자격/오염 피해·수문장 보장 드랍·키카드 금고 정책은 미구현. 기존 추격 보스와 수문장은 별도 역할.

수락 기준: 수문장 엘리트 몹 처치 시 저항 장비 완제품 100% 현장 드랍 확인

코드 경계: `game/features/map_generation/map_generator.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [심층 코어 정규 진입로 (환경 저항 장비 착용자 통과)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081a69988e39812a2e2f6)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-06**

저항 자격/오염 피해·수문장 보장 드랍·키카드 금고 정책은 미구현. 기존 추격 보스와 수문장은 별도 역할.

수락 기준: 환경 저항 장비 착용 시 심층부 오염 지속 피해 면역 확인

코드 경계: `game/features/map_generation/map_generator.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [심층 코어 최상위 보안 금고 (특수 키카드 소지자 전용 개방)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081e584ffd1cd87160366)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-06**

저항 자격/오염 피해·수문장 보장 드랍·키카드 금고 정책은 미구현. 기존 추격 보스와 수문장은 별도 역할.

수락 기준: 특수 키카드 소지 시에만 심층부 보안 금고 문이 열리는지 확인

코드 경계: `game/features/map_generation/map_generator.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

</details>

<!-- notion-audit:end -->

## 검색 별칭

최신 기획, GDD v128, 66개 작업, 원본 이관, 코드 대조, 73.2%, 회복 충돌, 혈전, 버서커, 보안 파우치, 심층 진입, 수문장, 키카드, N26, 오너 판단
