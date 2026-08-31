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

## 기본 규칙

1. 기능은 `game/features/<기능 이름>/` 아래에 둡니다.
2. 다른 기능의 내부 Node 경로를 직접 참조하지 않습니다.
3. 외부에 알릴 사건은 Signal로 공개합니다.
4. 조정 가능한 수치는 코드가 아닌 Resource 또는 export 속성으로 노출합니다.
5. 기능의 의존성, 활성화 방법, 제거 방법을 위키에 기록합니다.
6. 최상위 `Game`은 기능을 구현하지 않고 조립만 담당합니다.

## 기능 활성화

`game/core/feature_manifest.tres`를 Godot Inspector에서 열고 원하는 항목을 켜거나 끕니다.

현재 시작 거점과 전투 세션 전환, 맵 생성, 방 진입 봉쇄 전투, 맵 방해물, 미니맵, 작전 계약·투입비, 탈출 방어·결과 정산, 영구 프로필·상점·창고·소모품, 도면 제작·랜덤 옵션, 페널티·조건부 랭킹, 크레딧 파밍, 동적 이동·회피, 부분 회복, 타격 피드백, 지속 자기장·전투 스킬 HUD, 장비·인벤토리·강화, 적 체력·방어력·증원, 스마트 자동 무기, Sheets 밸런스, 내부·외부 성장이 실제 게임 조립에 연결되어 있습니다.

`Game`은 활성화된 기능만 문자열 경로로 불러옵니다. 기능을 끄면 해당 Scene을 로드하지 않으므로, 비활성화 확인 후 관련 기능 폴더를 제거하는 흐름을 시험할 수 있습니다.

구체적인 검사 결과와 허용된 결합은 [모듈화 점검 기록](module-audit.md)에서 확인합니다.

## 의존성 검사

`FeatureManifest.validation_errors()`가 잘못된 조합을 게임 시작 전에 검사합니다.

- `spawning`은 `enemies` 필요
- `room_encounters`는 `spawning`, `map_generation`과 유효한 방 전투 Resource 필요
- `start_hub`는 `player` 필요
- `weapons`는 `enemies` 필요
- `combat_skills`는 `player`와 유효한 전투 스킬 로드아웃 Resource 필요
- `weapon_balance`는 `weapons` 필요
- `growth_balance`는 `run_buffs`, `equipment` 필요
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
- `extraction_defense`는 `extraction` 필요
- `hub_economy`, `crafting`은 `persistent_profile` 필요
- `smart_targeting`은 `weapons` 필요
- `penalty_modifiers`, `conditional_ranking`은 `operation_contracts` 필요

맵 생성이 켜지면 플레이어와 적은 생성된 바닥 셀 안에서 생성됩니다. 맵 생성을 끄면 기존의 자유 이동 필드와 직선 추적 방식으로 돌아갑니다.

맵처럼 다른 기능에 서비스를 제공하는 모듈은 구체 클래스를 넘기지 않고 `Node`의 Signal과 공개 메서드로 계약합니다. 조립부는 계약을 확인한 뒤에만 소비자에게 전달합니다.

등급별 수치는 기능별 Resource가 소유합니다. 맵은 방 수, 생성은 동시 수량·총 생성 한계, 파밍은 최소·최대 회수 배수를 각각 관리하며 서로의 내부 배열이나 인스턴스를 직접 읽지 않습니다.

공간 가시성도 같은 규칙을 따릅니다. 맵은 `get_visibility_region()`과 `get_visibility_room_rects()`로 복사된 경계만 제공하고, 안개는 방 배열·바닥 셀·길찾기 내부 자료구조에 접근하지 않습니다. 플레이어의 방향도 `get_facing_direction()` 공개 메서드로만 읽습니다.

밸런스 데이터도 같은 규칙을 따릅니다. `growth_balance`는 CSV를 파싱해 카탈로그·수정자·견적만 공개하고 장비 상태나 내부 버프 선택을 직접 변경하지 않습니다. 소비 모듈은 제공자가 없으면 기존 Resource 값으로 폴백합니다.

전투 스킬도 입력·쿨타임을 실행기, 수치를 정의 Resource, 실제 행동을 효과 Resource, 지속 수명을 런타임 효과, 표현을 HUD Scene으로 나눕니다. 효과는 Player나 Enemy의 내부 필드를 읽지 않고 방향·수정자·피해 공개 계약만 사용합니다.

타격 피드백은 공격이 선택적으로 전달하는 `hit_context`와 액터의 `damaged` Signal만 사용합니다. 액터 내부 반응은 `HitReaction2D`, 월드 충격과 카메라는 `HitFeedbackDirector`, 표현 수치는 `HitFeedbackProfile`이 소유하며 어느 쪽도 피해량을 수정하지 않습니다.

방 전투는 맵 내부 배열을 직접 읽지 않습니다. 맵이 방 경계·중심·출입구 스냅샷과 방 내부 생성 위치를 제공하고, 적 생성기는 위치 지정 생성·남은 예산·증원 일시 정지 계약만 제공합니다. `RoomEncounterSystem`은 이 공개 계약을 조합해 진입→봉쇄→전멸→보상 상태만 소유합니다.

영구 상태는 런타임 Node에 보관하지 않습니다. `PersistentProfile`은 값과 저장만 담당하고 상점 가격, 제작식, 작전 배율, 점수식은 각 정책 모듈이 소유합니다. 출격 조립 실패에는 공개 보상 계약으로 트랜잭션을 되돌립니다.

지역·난이도·페널티·스마트 타게팅·제작 옵션처럼 자주 조정할 규칙은 Resource로 둡니다. 소비자는 최종 스냅샷 사본만 받고 다른 모듈의 설정 배열을 직접 수정하지 않습니다.

## 제거 절차

1. Manifest에서 기능을 끕니다.
2. 프로젝트를 실행해 다른 기능이 정상인지 확인합니다.
3. 기능 문서의 의존성 목록을 확인합니다.
4. 더 이상 참조가 없을 때 기능 폴더를 제거합니다.

단순히 폴더를 먼저 삭제하면 Godot Resource 경로가 깨질 수 있으므로 이 순서를 지킵니다.

## 검색 별칭

플러그인, 컴포넌트, 기능 토글, 기능 끄기, 모듈 제거, 의존성 분리, 인벤토리 토글, 장비 개조 토글
