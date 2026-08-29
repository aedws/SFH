---
title: 모듈화 점검 기록
description: 기능을 끄거나 교체할 수 있는지 코드와 자동 테스트로 확인한 기록
tags:
  - 모듈
  - 감사
  - 의존성
  - 인터페이스
  - 비활성화
---

# 모듈화 점검 기록

## 2026-08-29 랜덤 맵 모듈

결론은 **MVP 단계에서 교체 가능한 선택 모듈로 분리되어 있음**입니다. 맵의 생성 알고리즘과 등급 데이터는 한 기능 폴더 안에 있고, 플레이어·적·무기 모듈은 `MapTierConfig`나 방 배열을 직접 알지 않습니다.

다만 현재 구조는 Godot 애드온 수준의 완전한 플러그인 시스템은 아닙니다. 최상위 `Game`이 기능 경로와 공개 계약을 알고 조립하는 경량 모듈 구조입니다.

## 점검표

| 항목 | 결과 | 근거 |
|---|---|---|
| 기능 폴더 응집도 | 통과 | 생성기, Scene, 등급 Resource가 `game/features/map_generation/`에 모여 있음 |
| 정적 의존성 격리 | 통과 | 다른 기능은 `MapTierConfig`와 맵 내부 Node 경로를 참조하지 않음 |
| 런타임 선택 로딩 | 통과 | `map_generation_enabled`가 켜진 경우에만 문자열 경로로 Scene을 로드함 |
| 비활성화 폴백 | 통과 | 맵을 끄면 원점 스폰, 원형 적 스폰, 직선 추적으로 복귀함 |
| 대체 구현 계약 검사 | 통과 | `Game`과 `EnemySpawner`가 필요한 Signal·메서드 존재 여부를 검사함 |
| 데이터 분리 | 통과 | 비용, 방 수, 방 크기는 소·중·대형 `.tres` Resource에서 변경 가능 |
| 자동 검증 | 통과 | 세 등급 연결성 및 맵 비활성화 조립을 스모크 테스트로 확인함 |

## 맵 모듈 공개 계약

대체 맵 Scene도 아래 계약만 제공하면 소비자 코드를 유지할 수 있습니다.

| 종류 | 이름 | 소비자 |
|---|---|---|
| Signal | `map_generated(display_name, entry_cost, room_count, maximum_rooms, used_seed)` | HUD |
| Method | `generate(config, requested_seed)` | `Game` 조립부 |
| Method | `get_player_spawn_position()` | 플레이어 배치 |
| Method | `get_enemy_spawn_position(origin, minimum_distance)` | 적 생성기 |
| Method | `get_world_path(from_world, to_world)` | 적 이동 |

소비자는 구체 클래스 대신 `Node`와 위 메서드의 존재 여부를 사용합니다. 따라서 다른 알고리즘으로 맵 생성기를 교체할 때도 계약만 유지하면 됩니다.

## 의도된 결합

- `Game`은 모듈 Scene의 문자열 경로와 조립 순서를 압니다.
- `EnemySpawner`는 기본 적 Scene을 참조합니다. 이는 `spawning → enemies` 선언 의존성입니다.
- 플레이어, 적, 투사체는 생성 벽용 충돌 레이어 `16`을 공유합니다.
- 맵 전용 스모크 테스트는 맵 기능 경로를 참조합니다. 맵 기능을 완전히 삭제하면 해당 테스트도 함께 제거하거나 교체해야 합니다.

이 결합은 숨겨진 의존성이 아니라 조립부, Manifest 검사, 문서에 드러난 계약으로 관리합니다.

## 다시 점검하는 방법

```powershell
.\scripts\test-game.cmd
.\scripts\wiki.cmd build
```

성공하면 출력에 `map_optional`이 포함됩니다. 이는 맵 기능이 켜진 구성뿐 아니라 꺼진 구성도 정상 조립됐다는 뜻입니다.

## 다음 개선 시점

모듈이 더 늘어나 `Game`의 조립 코드가 커지면 기능마다 설치 객체를 두고 공통 `install(context)` 계약으로 옮깁니다. 현재 규모에서는 문자열 지연 로딩과 명시적 계약 검사가 더 단순하고 추적하기 쉽습니다.

## 검색 별칭

모듈 감사, 의존성 검사, 플러그인 구조, 기능 제거, 기능 교체, 맵 인터페이스, 선택 모듈, 결합도
