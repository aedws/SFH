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
│     └─ CreditLootCache   # 등급에 따라 여러 개 생성
├─ Modules
│  ├─ EnemySpawner          # 실행 시 생성
│  ├─ ProgressionSystem     # 실행 시 생성
│  ├─ HealthRecovery        # 지연·상한이 있는 부분 체력 회복
│  ├─ RunBuffSystem         # 한 판 임시 버프 선택·중첩
│  ├─ MetaProgression       # 캐릭터·무기·방어구 외부 성장과 저장
│  ├─ CharacterEquipment    # 무기·스킬·방어구 로드아웃 조립
│  ├─ CreditLedger          # 휴대·회수·분실 계산
│  ├─ EquipmentUpgrade      # 동일 아이템·크레딧 강화 비용 조정
│  └─ LootSpawner           # 1회성 보급 상자 배치
└─ UI
   ├─ HUDMargin
   ├─ TacticalMinimap      # 실행 시 설치되는 우측 상단 전술 지도
   ├─ InteractionLabel      # 탈출 범위의 F 안내
   ├─ RunSetupOverlay       # 소·중·대형 선택
   ├─ RunBuffSelector       # 내부 레벨업 때 3개 버프 선택
   ├─ InventoryWindow       # I 가방
   ├─ EquipmentWorkbench    # U 장비·파츠·모듈 편집
   └─ GameOverOverlay
```

`Game` Scene은 각 기능의 세부 동작을 구현하지 않습니다. `FeatureManifest`를 검사한 뒤 활성화된 Scene을 적절한 컨테이너에 설치하고 Signal을 연결합니다.

## 관련 파일

- `game/scenes/game.tscn`: 최상위 장면
- `game/scenes/game.gd`: 모듈 설치 코드
- `game/core/feature_manifest.tres`: 활성 기능 설정
- `game/features/player/player.tscn`: 플레이어 기능 장면
- `game/features/equipment/equipment_system.tscn`: 장비 로드아웃과 호환성·스탯 집계
- `game/features/map_generation/map_generator.tscn`: 방, 복도, 벽, 길찾기 생성
- `game/features/minimap/minimap.tscn`: 지형 스냅샷 기반 우측 상단 전술 지도
- `game/features/extraction/extraction_zone.tscn`: F 상호작용 탈출 지점
- `game/features/credits/credit_ledger.tscn`: 작전 크레딧 원장
- `game/features/loot/loot_spawner.tscn`: 파밍 오브젝트 배치
- `game/features/spawning/enemy_spawner.tscn`: 적 생성 기능
- `game/features/weapons/auto_weapon.tscn`: 자동 공격 기능
- `game/features/experience/progression_system.tscn`: 성장 기능
- `game/features/run_buffs/run_buff_system.tscn`: 한 판 임시 버프
- `game/features/meta_progression/meta_progression_system.tscn`: 외부 성장과 저장
- `game/features/equipment_upgrade/equipment_upgrade_service.tscn`: 파츠·모듈 강화 경제
