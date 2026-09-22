---
title: 모듈 작성 규칙
tags:
  - 모듈
  - 블록화
  - 의존성
---

# 모듈 작성 규칙

## 목표

기능 폴더 하나를 비활성화하거나 교체했을 때 관계없는 기능이 함께 깨지지 않게 합니다.

SFH의 완료 기준은 **기능과 확장성을 동시에 만족하는 것**입니다. 현재 요구가 동작해도 다음 설정을 추가할 때 중앙 조립부의 분기문을 계속 수정해야 한다면 완료로 보지 않습니다. 변경 지점은 독립 제공자·정책·검증기로 열고, 조립부는 등록과 순서만 담당합니다.

## 기본 규칙

1. 기능은 `game/features/<기능 이름>/` 아래에 둡니다.
2. 다른 기능의 내부 Node 경로를 직접 참조하지 않습니다.
3. 외부에 알릴 사건은 Signal로 공개합니다.
4. 조정 가능한 수치는 코드가 아닌 Resource 또는 export 속성으로 노출합니다.
5. 기능의 의존성, 활성화 방법, 제거 방법을 위키에 기록합니다.
6. 최상위 `Game`은 기능을 구현하지 않고 조립만 담당합니다.
7. 새 설정은 기존 설정의 조건문에 끼워 넣지 않고 공개 기여자 또는 정책 계약으로 등록합니다.
8. 결제·저장·Scene 교체 전에 모든 전제 조건을 검증하며, 실패를 사후 롤백에만 의존하지 않습니다.
9. 검증된 입력은 불변 스냅샷으로 고정하고 실행 단계에서 다시 계산하지 않습니다.
10. 기능별 E2E는 정상 경로뿐 아니라 조합 변경·실패·복원·미래 제공자 추가를 함께 검증합니다.
11. 장착한 실물 장비는 장비 제공자의 상태가 유일한 원본입니다. 작전 설정·카탈로그가 무기 정의나 모듈·파츠를 덮어쓰지 않으며 로비 UI 제거·데이터 갱신 후에도 이 원칙을 유지합니다.

## 기능 활성화

`game/core/feature_manifest.tres`를 Godot Inspector에서 열고 원하는 항목을 켜거나 끕니다.

현재 시작 거점과 전투 세션 전환, 맵 생성, 방 진입 봉쇄 전투, 맵 방해물, 미니맵, 작전 계약·투입비, 탈출 방어·결과 정산, 영구 프로필·상점·창고·소모품, 도면 제작·랜덤 옵션, 페널티·조건부 랭킹, 크레딧 파밍, 동적 이동·회피, 부분 회복, 타격 피드백, 지속 자기장·전투 스킬 HUD, 장비·인벤토리·강화, 적 체력·방어력·증원, 스마트 자동 무기, Sheets 밸런스, 내부·외부 성장이 실제 게임 조립에 연결되어 있습니다.

`Game`은 활성화된 기능만 문자열 경로로 불러옵니다. 기능을 끄면 해당 Scene을 로드하지 않으므로, 비활성화 확인 후 관련 기능 폴더를 제거하는 흐름을 시험할 수 있습니다.

구체적인 검사 결과와 허용된 결합은 [모듈화 점검 기록](module-audit.md)에서 확인합니다.
실제 코드에서 산출한 모듈·클래스·상속·참조 관계는 [현재 코드 모듈 노드맵](code-module-map.md)에서 노드 단위로 확인합니다.

## 의존성 검사

`FeatureManifest.validation_errors()`가 잘못된 조합을 게임 시작 전에 검사합니다.

- `spawning`은 `enemies` 필요
- `room_encounters`는 `spawning`, `map_generation`, `credits`와 유효한 방 전투 Resource 필요
- `room_warp`는 `room_encounters`, `minimap` 필요
- `start_hub`는 `player` 필요
- `weapons`는 `enemies` 필요
- `combat_skills`는 `player`와 유효한 전투 스킬 로드아웃 Resource 필요
- `weapon_balance`는 `weapons` 필요
- `growth_balance`는 `run_buffs`, `equipment` 필요
- `loot_lifecycle`는 `inventory`와 유효한 Item 생명 주기 Config 필요
- `experience`는 `enemies` 필요
- `leveling`은 `experience` 필요
- `run_buffs`는 `leveling` 필요
- `meta_progression`은 `run_buffs` 필요
- `game_over`는 `damage` 필요
- `hit_feedback`은 `damage`와 유효한 피드백 프로필 Resource 필요
- `map_obstacles`는 `map_generation` 필요
- `fog_of_war`는 `player` 필요
- `minimap`은 `map_generation` 필요
- `run_setup`은 `map_generation` 필요
- `extraction`은 `map_generation` 필요
- `loot`는 `map_generation`, `credits` 필요
- `enemy_armor`, `enemy_status_ui`는 `enemies` 필요
- `equipment_weapons`, `equipment_armor`는 `equipment` 필요
- `equipment_skills`는 `equipment`, `equipment_weapons` 필요
- `equipment_customization`은 `equipment`, `inventory` 필요
- `equipment_upgrade_economy`는 `equipment_customization`, `credits` 필요
- `operation_contracts`는 `persistent_profile` 필요
- `operation_launch_preflight`는 `operation_contracts` 필요
- `loadout_investment`는 `operation_contracts`, `equipment`, `combat_skills` 필요
- `extraction_defense`는 `extraction` 필요
- `hub_economy`, `crafting`은 `persistent_profile` 필요
- `smart_targeting`은 `weapons` 필요
- `penalty_modifiers`, `conditional_ranking`은 `operation_contracts` 필요

맵 생성이 켜지면 플레이어와 적은 생성된 바닥 셀 안에서 생성됩니다. 맵 생성을 끄면 기존의 자유 이동 필드와 직선 추적 방식으로 돌아갑니다.

맵처럼 다른 기능에 서비스를 제공하는 모듈은 구체 클래스를 넘기지 않고 `Node`의 Signal과 공개 메서드로 계약합니다. 조립부는 계약을 확인한 뒤에만 소비자에게 전달합니다.

등급별 수치는 기능별 Resource가 소유합니다. 맵은 방 수, 생성은 동시 수량·총 생성 한계, 파밍은 최소·최대 회수 배수를 각각 관리하며 서로의 내부 배열이나 인스턴스를 직접 읽지 않습니다.

공간 가시성도 같은 규칙을 따릅니다. 기본 로그라이크 시야에서 맵은 `get_fog_geometry()`로 경계·셀 크기·지형 복사본만 제공하고, 문은 `get_visibility_bounds()`로 차폐 경계만 제공합니다. 순수 `RoguelikeVisibilityField`가 현재/탐색 기억을 계산하고, `RoguelikeFogRuntime`이 카메라·문 변경을 연결하며, Shader가 불투명한 지형 기억을 합성합니다. 안개는 방 배열·길찾기 내부 자료구조나 적/전리품 상태에 접근하지 않습니다. 기존 `get_visibility_region()`·`get_visibility_room_rects()`·`get_facing_direction()`은 명시적 레거시/지형 제공자 없는 폴백에만 사용합니다. 시야와 적 활성화·보상·미니맵 정책을 결합하지 않습니다.

밸런스 데이터도 같은 규칙을 따릅니다. `growth_balance`는 CSV를 파싱해 카탈로그·수정자·견적만 공개하고 장비 상태나 내부 버프 선택을 직접 변경하지 않습니다. 소비 모듈은 제공자가 없으면 기존 Resource 값으로 폴백합니다.

전리품 생명 주기도 데이터와 적용을 분리합니다. `LootLifecycleService`는 Item Sheet/확정 CSV를 검증하고 탈출·사망 결과 사본만 반환합니다. 인벤토리·영구 프로필·크레딧 저장소를 직접 수정하지 않으며, 실제 획득과 정산은 후속 명령 모듈이 결과를 소비합니다.

전투 스킬도 입력·쿨타임을 실행기, 수치를 정의 Resource, 실제 행동을 효과 Resource, 지속 수명을 런타임 효과, 표현을 HUD Scene으로 나눕니다. 효과는 Player나 Enemy의 내부 필드를 읽지 않고 방향·수정자·피해 공개 계약만 사용합니다.

임시 스킬 교체 시 `SkillBindingService`가 현재 스킬→원래 슬롯 소유자→Action 관계를 소유합니다. 출격/현장 제공자는 현재 키와 정의를 공개 계약으로 전달하며 기본 키를 다시 강제하지 않습니다. 설정 UI는 현재 엔트리만 읽고, 저장은 원래 슬롯의 배치로 정규화합니다. 중첩 교체·재배치·복귀·저장 실패를 함께 검사하며 효과 Resource는 실행·표시 계약을 검증한 뒤 장착합니다.

타격 피드백은 공격이 선택적으로 전달하는 `hit_context`와 액터의 `damaged` Signal만 사용합니다. 액터 내부 반응은 `HitReaction2D`, 월드 충격과 카메라는 `HitFeedbackDirector`, 표현 수치는 `HitFeedbackProfile`이 소유하며 어느 쪽도 피해량을 수정하지 않습니다.

방 전투는 맵 내부 배열을 직접 읽지 않습니다. 맵이 시설·공간·출입구·탈출 후보 스냅샷과 안전 생성 위치를 제공하고, 적 생성기는 위치 지정 생성·남은 예산·동시 개체·증원 정지 계약을 제공합니다. 현행 `DistrictEncounterSystem`은 후퇴 가능한 일반 무리와 단말 선택형 목표를 분리하고 `RoomEncounterSystem`의 안전·봉쇄·전멸·보상 계약을 재사용합니다. `RoomWarpSystem`은 안전 단말 근접·주변 적·봉쇄 상태를 검증하고, 미니맵은 플레이어 위치를 직접 수정하지 않습니다. [현행 경계](module-audit.md#extraction-district).

영구 상태는 런타임 Node에 보관하지 않습니다. `PersistentProfile`은 값과 저장만 담당하고 상점 가격, 제작식, 작전 배율, 점수식은 각 정책 모듈이 소유합니다. 출격 조립 실패에는 공개 보상 계약으로 트랜잭션을 되돌립니다.

런 로드아웃 투자도 같은 경계를 지킵니다. `LoadoutInvestmentTable`은 Weapon·Skill Sheet/확정 CSV를 파싱합니다. 기본 Game은 `preserve_equipped_weapons` 정책으로 무기 선택·재청구를 막고 스킬 투자만 전달합니다. 크레딧 차감은 `OperationContractService`가 한 번 합산합니다. 장비는 로비 상태를 복원하고 스킬 태그 불일치는 개별 비활성화합니다. 로비 단말은 서비스 ID 신호만 내보내며 장비·프로필 내부에 접근하지 않습니다.

작전 투입은 [작전 투입 사전검증과 불변 계획](../features/operation-launch-preflight.md)을 공통 관문으로 사용합니다. 요원·로드아웃·유틸리티와 이후 추가될 설정은 `get_operation_setting_contribution()`으로 비용과 스냅샷을 제공하고, 장비·인벤토리·전리품은 `validate_operation_launch()`로 결제 전 전제를 검사합니다. `Game`은 설정 종류를 해석하지 않고 등록된 결과만 작전 계약과 조립부에 전달합니다.

지역·난이도·페널티·스마트 타게팅·제작 옵션처럼 자주 조정할 규칙은 Resource로 둡니다. 소비자는 최종 스냅샷 사본만 받고 다른 모듈의 설정 배열을 직접 수정하지 않습니다.

## 게임 UI 표현 계약 · 2026-09-08

`presentation_theme/GameUI`는 표면·캐시 아이콘·액션 표현만 제공하며 프로필/결제/장비를 소유하지 않습니다. `GameDossier`는 스크롤·고정 복귀·부모 일시정지/초점 보존을 담당합니다. 제작·도감 `HubArchivePanel`은 기존 P5 공개 catalog→quote→command 계약만 소비합니다. 목록 선택 시 결제 금지, 명시 확정의 성공 영수증 후에만 완료 표시, 실패 시 성공 연출 금지입니다. 새 enum은 없고 Sheet/CSV 정책을 변경하지 않습니다.

훈련 HUD의 모달 차폐는 `TrainingHudLayout`의 상위 표면이 담당하여 계측/무료 세팅 복원 상태를 건드리지 않습니다. UI 신규 파일은 전수 검토 레지스트리와 [화면 판정표](../quality/game-ui-rematch.md)를 갱신해야 합니다. 색 변경만으로 UI 완료를 판정하지 않습니다.

## 장비 화면 표현 경계

장비 화면의 열 비율은 `EquipmentScreenLayout` 순수 정책이 소유합니다. `inventory_window`·`module_workspace`는 이 비율을 소비하고, 작업대는 자체 내부 레이아웃/스크롤만 재배치합니다. 공용 아이템 그림·미리보기·슬롯 버튼은 `presentation_theme`에 두어 equipment→inventory→equipment 순환을 만들지 않습니다. 기존 클래스명·Resource UID는 유지합니다. 렌더러는 종횡비를 보존하며 편집 세션·장비 상태·성장 계산을 변경하지 않습니다. 화면 축소→확대 회귀와 데이터 불변 검사를 함께 유지합니다.

무기 공격 모드는 잠금/실시간 데이터에서 검증한 뒤 실행합니다. 같은 모드의 새 무기는 Game 조건문으로 추가하지 않습니다. 근접 기하·월드 타격·표현을 분리하고 고유 효과는 기존 명중 계약을 소비합니다. 장착 가능성, 실제 입력·명중, 드랍 정의, 출격 보존, 위키 계산기까지 연결해야 무기 추가를 완료로 판단합니다.

## 제거 절차

1. Manifest에서 기능을 끕니다.
2. 프로젝트를 실행해 다른 기능이 정상인지 확인합니다.
3. 기능 문서의 의존성 목록을 확인합니다.
4. 더 이상 참조가 없을 때 기능 폴더를 제거합니다.

단순히 폴더를 먼저 삭제하면 Godot Resource 경로가 깨질 수 있으므로 이 순서를 지킵니다.

## 검색 별칭

### 플레이 흐름 계측 경계 · 2026-09-22

`run_flow`의 `RunFlowCollector`는 순수 사건/시각→복사본 보고서만 담당합니다. `RunFlowTelemetry`는 지도 공개 위치 계약·방 전투 신호·전리품 `decision_observed(drop_id, stage, action)` 신호와 런 경계를 연결합니다. Game은 생성/시작/정산/거점 복귀만 조립하며 방 배열, 적, 가방, 프로필을 계측기에서 변경하지 않습니다. 임시 drop 인스턴스 ID는 해당 런에서 같은 아이템 여러 개를 구분할 용도이며 영구 아이템 식별자가 아닙니다.

`FeatureManifest.run_flow_enabled=false`로 끌 수 있고 선택 공급자가 없으면 보고서 `sources`에 미연결을 표시합니다. 기록 파일 실패도 정산을 막지 않습니다. 512건 상한·실제 시계·종료 불변·신호 해제·새 런 초기화 계약을 유지하며 게임 밸런스나 Sheet에 QA 임계값을 복제하지 않습니다. [검사/해석](../quality/e2e-play-session.md#run-flow-20260922).

### 바닥 렌더러 대체 계약

2026-09-09 오너 승인으로 `DungeonFloorLayer`의 Node2D 청크 텍스처를 TileMapLayer 대신 사용합니다. 첫 GPU 업로드 지연 감소가 변경 이유이며 [측정 근거](../performance/minimum-requirements.md#first-frame-20260908)를 보존합니다. `rebuild`, `get_used_cells`, `map_to_local` 계약은 유지하고 충돌/길찾기 데이터는 렌더러에 넣지 않습니다. 교체 시 `floor_render_contract_test`와 첫 렌더 검수를 다시 수행합니다. 기술 대체 승인은 일반 플레이 QA 완료와 분리합니다.

### 단일 대상 성장 표시 계약

[성장 그래프](../tools/balance-workbench.md#growth)는 `growth-engine.js`가 동일 entity ID의 레벨/강화 단계만 순회하여 기존 DPS·장착 계산기를 호출하고, `growth-lab.js`는 선택·표시·시험 입력을 담당합니다. 캐릭터·무기·방어구 목록을 가로축으로 연결하지 않습니다. 현재 보정이 없거나 하락하는 단계도 그대로 표시하며 값을 보간하지 않습니다. 서버는 동일 순수 모델로 확정안을 재계산하고 게임 반영과 분리합니다.

### 거리 피해 실행 경계

[무기 거리 피해](../features/weapon-distance.md)는 순수 `WeaponDistancePolicy` → CSV 검증 → 발사 스냅샷 → 탄환 충돌로 분리합니다. 발사 뒤 현재 무기·플레이어 위치·시트 값을 역참조하지 않습니다. 관통 유지율과 거리 배율을 분리하고 고유 고정 피해·스킬은 이 정책에서 변경하지 않습니다. 위키는 같은 제어점 규격과 Godot 비교값을 검증합니다. 기획 확정 입력은 런타임 전역 설정이 아니며 오너 검토·명시적 CSV 적용·배포를 거칩니다.

### 효과 명세와 게임 실행의 분리

[효과·스탯 툴킷](../tools/effect-toolkit.md)은 코드 추출기 → 순수 검증기 → 역할 UI / CLI 입력으로 분리합니다. EffectSpec은 요청 데이터이고 게임 런타임이 아닙니다. 지원 변수 추가 시 원본 경로·Resource 섹션·값 범위·단위·실행 규칙·테스트를 함께 등록합니다. 새로운 동작은 명시적인 효과 모듈과 게임 검수를 추가해야 하며 설명이나 `candidate` ID만으로 완료 판정하지 않습니다. Resource와 CSV 이중 정의는 함께 갱신하고 계약 테스트로 일치를 확인합니다.

### 소스·검사·산출물 전달 경계

Git은 소스·변경 이유·검사/복구 기록을 소유하며 빌드 바이너리를 전달하지 않습니다. `ci_budget`는 보수적 검사 분류, `ci_transfer`는 동일 러너 실행/시도별 해시 전달, `deploy_cloudflare_assets`는 커밋/ZIP 대조와 R2 후보 업로드·읽기 검증, Worker는 활성 경로 읽기만 담당합니다. 워크플로가 전환·사후 검증·복구·보존 순서를 조립합니다. 문서 변경은 현재 게임 커밋을 유지하며 토큰·로그인·사용자 저장을 전달 payload에 넣지 않습니다. [재시도·확장 계약](../getting-started/source-control-and-cleanup.md#source-only-delivery).

### 초기 선택·데이터형 액티브 계약

[40종 스킬](../features/tactical-skill-catalog.md)은 초기 선택 ID → 실제 장비 규칙 재검증 → 로비 장착 보존으로 연결합니다. 캐릭터 고정 특화는 순수 계열 정책, 액티브는 검증된 효과 Resource, 지속 상태는 취소 가능한 Runtime이 소유합니다. CombatResourceSystem은 공개된 스킬별 충전 배율만 받으며 캐릭터 ID를 알지 않습니다. 라이브 Skill/SkillPattern은 한 번에 검증하고 출격 계획과 효과는 값 복사본을 사용합니다. 새 목록이 생겼다고 공통 실행기·Game에 ID 분기문을 추가하지 않습니다.

### 방어구 세트 실행 경계

[방어구 세트](../features/armor-sets.md)는 `ArmorSetDefinition`(지원 수치/임계 검증) → `ArmorSetResolver`(서로 다른 장착 부위 집계) → `EquipmentSystem`(player/weapon/skill 전달)로 분리합니다. Game에 개별 세트 ID 분기를 추가하지 않습니다. 2/4세트는 각각 한 번 적용하고 품질/레벨 배율을 다시 곱하지 않습니다. 같은 ID의 상충된 정의·중복 슬롯은 실패 처리하며 장착 실패 전 원본 상태를 보존합니다. 실제 스킬 효과는 발동 시 스냅샷을 사용합니다.

Armor/ArmorSet 잠금 CSV와 `sync_armor_catalog.py`가 런타임 Resource 및 Web 미러를 함께 생성합니다. 데이터 수정은 컴파일러 검증, 새 행동은 명시적인 허용 키·실행기·회귀 검증을 거칩니다. UI는 미리보기/저장 경계를 지키고, 그래프는 동일 Resource 추출값과 Godot 결과를 대조합니다. 구형 기본 슬롯만 머리·손을 추가하며 사용자 정의 슬롯과 기존 장비는 유지합니다.

### 실시간 인벤토리와 입력 경계 · 2026-09-22

`GridInventoryWindow.set_realtime_mode`로 거점 정지/작전 비정지를 조립하며, 비정지 화면은 다른 주체의 pause를 변경하지 않습니다. `PlayerMovement`·`AutoWeapon`·`CombatSkillSystem.set_ui_input_blocked`는 UI 조작 유출만 차단합니다. 적/피해/쿨타임/이미 생성된 효과를 멈추는 방식으로 구현하지 않습니다. 자동 무기는 UI 닫기 클릭의 버튼 해제를 기다립니다.

정산은 `end_runtime_session`으로 창·예약된 이탈을 무효화하고 `InventoryEditSession.end` 뒤의 저장을 거부합니다. 원본 변경 충돌은 저장 거부+재열기로 해결하며 장부·아이템을 UI 사본으로 덮어쓰지 않습니다. 장착 룬 정산은 기존 획득 장부만 소비하고 가방과 소켓을 별도로 합산해 이중 지급하지 않습니다. 공개 계약의 시간·입력·피격·저장·사망·정산 회귀는 두 전용 계약 테스트로 유지합니다.

플러그인, 컴포넌트, 기능 토글, 기능 끄기, 모듈 제거, 의존성 분리, 인벤토리 토글, 장비 개조 토글
