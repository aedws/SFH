---
title: 플레이어 이동
tags:
  - 플레이어
  - 이동
  - WASD
  - 대시
  - 가속
---

# 플레이어 이동

## 목적

키보드 입력을 받아 탑다운 8방향으로 이동합니다. 일반 뱀서라이크의 단순 정속 이동 대신 FPS의 역방향 제동과 플랫포머의 짧은 입력 버퍼·회피 감각을 탑다운 이동에 맞게 적용했습니다.

## 조작

- 이동: `WASD` 또는 방향키
- 회피 이동: `Shift` 또는 `Space`
- 대각선 이동 속도는 정규화되어 직선 이동과 같습니다.
- 입력 시 가속하고 손을 떼면 빠르게 감속합니다.
- 진행 반대 방향을 누르면 일반 가속보다 강한 역선회 제동이 적용됩니다.
- 회피는 이동 방향으로 0.16초간 약 2.15배 속도를 내며 기본 재사용 대기시간은 1.15초입니다.

## 구성

```text
Player (CharacterBody2D)
├─ Movement (Node)
├─ Body (Polygon2D)
├─ Heading (Polygon2D)
├─ CollisionShape2D
└─ Camera2D
```

`PlayerCharacter`는 물리 이동과 런타임 스탯 적용을 담당하고, `PlayerMovement`는 입력, 가속·제동, 선회, 회피 상태만 담당합니다. `step_velocity()`가 입력 방향과 현재 속도를 받아 결과 속도를 반환하므로 이동 수치를 독립 테스트하거나 다른 캐릭터에 재사용할 수 있습니다.

## 설정

`Player/Movement` Node를 선택하면 `Speed`, `Acceleration`, `Braking`, `Counter Steer Acceleration`, `Dash Speed Multiplier`, `Dash Duration`, `Dash Cooldown`을 각각 조절할 수 있습니다. 기본 이동 속도는 초당 260픽셀입니다.

기본 스탯은 최대 체력 100, 방어 0, 이동 속도 260입니다. [캐릭터 장비와 로드아웃](character-equipment.md)이 `apply_equipment_modifiers` 계약을 통해 작전 시작 시 수정합니다. 현재 기본 장비 적용 후 값은 최대 체력 125, 방어 3, 이동 속도 280입니다.

## 의존성

- Godot 기본 `ui_left`, `ui_right`, `ui_up`, `ui_down` 입력
- `game/scenes/game.gd`의 플레이어 설치 지점
- `FeatureManifest.player_enabled`
- 장비가 켜진 경우 `apply_equipment_modifiers(modifiers)` 공개 계약

## 비활성화

`game/core/feature_manifest.tres`를 열고 `Player Enabled`를 끕니다. 그러면 실행 시 플레이어 Scene을 생성하지 않습니다.

## 검색 별칭

캐릭터 이동, WASD, 방향키, 속도 변경, 가속, 감속, 제동, 역선회, 대시, 회피, Shift, Space, 쫄깃한 조작감, 카메라 추적
