# 장면 트리

현재 최상위 구조는 다음과 같습니다.

```text
Game
├─ World
│  ├─ ArenaGrid
│  ├─ GeneratedMap          # 등급 Resource에 따라 실행 시 생성
│  ├─ ExtractionZone        # 최원거리 방에 실행 시 생성
│  ├─ Actors
│  │  └─ Player             # 실행 시 생성
│  │     └─ AutoWeapon      # 실행 시 생성
│  ├─ Enemies
│  ├─ Projectiles
│  └─ Pickups
├─ Modules
│  ├─ EnemySpawner          # 실행 시 생성
│  └─ ProgressionSystem     # 실행 시 생성
└─ UI
   ├─ HUDMargin
   ├─ InteractionLabel      # 탈출 범위의 F 안내
   ├─ RunSetupOverlay       # 소·중·대형 선택
   └─ GameOverOverlay
```

`Game` Scene은 각 기능의 세부 동작을 구현하지 않습니다. `FeatureManifest`를 검사한 뒤 활성화된 Scene을 적절한 컨테이너에 설치하고 Signal을 연결합니다.

## 관련 파일

- `game/scenes/game.tscn`: 최상위 장면
- `game/scenes/game.gd`: 모듈 설치 코드
- `game/core/feature_manifest.tres`: 활성 기능 설정
- `game/features/player/player.tscn`: 플레이어 기능 장면
- `game/features/map_generation/map_generator.tscn`: 방, 복도, 벽, 길찾기 생성
- `game/features/extraction/extraction_zone.tscn`: F 상호작용 탈출 지점
- `game/features/spawning/enemy_spawner.tscn`: 적 생성 기능
- `game/features/weapons/auto_weapon.tscn`: 자동 공격 기능
- `game/features/experience/progression_system.tscn`: 성장 기능
