---
title: 플레이어 이동
tags:
  - 플레이어
  - 이동
  - WASD
---

# 플레이어 이동

## 목적

키보드 입력을 받아 탑다운 8방향으로 이동하고 카메라가 플레이어를 따라갑니다.

## 조작

- 이동: `WASD` 또는 방향키
- 대각선 이동 속도는 정규화되어 직선 이동과 같습니다.

## 구성

```text
Player (CharacterBody2D)
├─ Movement (Node)
├─ Body (Polygon2D)
├─ Heading (Polygon2D)
├─ CollisionShape2D
└─ Camera2D
```

`PlayerCharacter`는 물리 이동을 담당하고, `PlayerMovement`는 입력을 속도 벡터로 바꾸는 역할만 담당합니다.

## 설정

`Player/Movement` Node를 선택하고 Inspector의 `Speed` 값을 변경합니다. 기본값은 초당 260픽셀입니다.

## 의존성

- Godot 기본 `ui_left`, `ui_right`, `ui_up`, `ui_down` 입력
- `game/scenes/game.gd`의 플레이어 설치 지점
- `FeatureManifest.player_enabled`

## 비활성화

`game/core/feature_manifest.tres`를 열고 `Player Enabled`를 끕니다. 그러면 실행 시 플레이어 Scene을 생성하지 않습니다.

## 검색 별칭

캐릭터 이동, WASD, 방향키, 속도 변경, 플레이어가 움직이지 않음, 카메라 추적
