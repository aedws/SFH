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

현재 맵 생성, 맵 방해물, 미니맵, 작전 선택, 탈출, 크레딧, 파밍, 플레이어, 캐릭터 장비·무기 슬롯·스킬·방어구, 적 체력·방어력 UI, 생성, 자동 무기, 피해, 경험치, 레벨, 게임오버 플래그가 실제 게임 조립에 연결되어 있습니다.

`Game`은 활성화된 기능만 문자열 경로로 불러옵니다. 기능을 끄면 해당 Scene을 로드하지 않으므로, 비활성화 확인 후 관련 기능 폴더를 제거하는 흐름을 시험할 수 있습니다.

구체적인 검사 결과와 허용된 결합은 [모듈화 점검 기록](module-audit.md)에서 확인합니다.

## 의존성 검사

`FeatureManifest.validation_errors()`가 잘못된 조합을 게임 시작 전에 검사합니다.

- `spawning`은 `enemies` 필요
- `weapons`는 `enemies` 필요
- `experience`는 `enemies` 필요
- `leveling`은 `experience` 필요
- `game_over`는 `damage` 필요
- `map_obstacles`는 `map_generation` 필요
- `minimap`은 `map_generation` 필요
- `run_setup`은 `map_generation` 필요
- `extraction`은 `map_generation` 필요
- `loot`는 `map_generation`, `credits` 필요
- `enemy_armor`, `enemy_status_ui`는 `enemies` 필요
- `equipment_weapons`, `equipment_armor`는 `equipment` 필요
- `equipment_skills`는 `equipment`, `equipment_weapons` 필요

맵 생성이 켜지면 플레이어와 적은 생성된 바닥 셀 안에서 생성됩니다. 맵 생성을 끄면 기존의 자유 이동 필드와 직선 추적 방식으로 돌아갑니다.

맵처럼 다른 기능에 서비스를 제공하는 모듈은 구체 클래스를 넘기지 않고 `Node`의 Signal과 공개 메서드로 계약합니다. 조립부는 계약을 확인한 뒤에만 소비자에게 전달합니다.

## 제거 절차

1. Manifest에서 기능을 끕니다.
2. 프로젝트를 실행해 다른 기능이 정상인지 확인합니다.
3. 기능 문서의 의존성 목록을 확인합니다.
4. 더 이상 참조가 없을 때 기능 폴더를 제거합니다.

단순히 폴더를 먼저 삭제하면 Godot Resource 경로가 깨질 수 있으므로 이 순서를 지킵니다.

## 검색 별칭

플러그인, 컴포넌트, 기능 토글, 기능 끄기, 모듈 제거, 의존성 분리
