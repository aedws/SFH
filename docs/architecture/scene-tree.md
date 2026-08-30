# 장면 트리

현재 최상위 구조는 다음과 같습니다.

```text
Game
├─ BattlefieldFogOfWar     # 방 전체/통로 정면 시야를 전환하고 HUD·미니맵은 유지
├─ World
│  ├─ ArenaGrid
│  ├─ StartHub              # 비전투 시 큰 단일 방과 작전 게이트
│  ├─ GeneratedMap          # 등급 Resource에 따라 실행 시 생성
│  ├─ RoomEncounters        # 방 진입·문 봉쇄·전멸·보상 상태 머신
│  ├─ ExtractionZone        # 최원거리 방에 실행 시 생성
│  ├─ Actors
│  │  └─ Player             # 실행 시 생성
│  │     └─ AutoWeapon      # 실행 시 생성
│  ├─ Enemies
│  ├─ Projectiles
│  └─ Pickups
│     ├─ CreditLootCache   # 금고·자재함·회수 단말기 유형으로 여러 개 생성
│     └─ RoomRewardPickup  # 방 전멸 뒤 생성되는 내부 경험치 보상
├─ Modules
│  ├─ EnemySpawner          # 등급별 목표 수량·총 생성 한계와 묶음 증원
│  ├─ ProgressionSystem     # 실행 시 생성
│  ├─ HealthRecovery        # 지연·상한이 있는 부분 체력 회복
│  ├─ CombatSkills          # 1·2·3 입력, 효과 실행과 쿨타임 상태
│  ├─ RunBuffSystem         # 한 판 임시 버프 선택·중첩
│  ├─ GrowthBalance         # RunBuff·Upgrade 실시간/확정 CSV와 수정자 제공
│  ├─ MetaProgression       # 캐릭터·무기·방어구 외부 성장과 저장
│  ├─ CharacterEquipment    # 무기·스킬·방어구 로드아웃 조립
│  ├─ CreditLedger          # 휴대·회수·분실 계산
│  ├─ EquipmentUpgrade      # 동일 아이템·크레딧 강화 비용 조정
│  └─ LootSpawner           # 1회성 회수 지점과 투입 코스트 2.5~5배 목표 배치
└─ UI
   ├─ StartHubHUD           # 거점 목표와 조작 안내
   ├─ HUDMargin
   ├─ CombatSkillHud        # 실행 시 설치되는 하단 3슬롯 쿨타임 HUD
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
- `game/features/start_hub/start_hub.tscn`: 시작 거점 방·경계·작전 게이트
- `game/scenes/game.gd`: 모듈 설치 코드
- `game/core/feature_manifest.tres`: 활성 기능 설정
- `game/features/player/player.tscn`: 플레이어 기능 장면
- `game/features/combat_skills/combat_skill_system.tscn`: 전투 스킬 입력·쿨타임 실행기
- `game/features/combat_skills/combat_skill_hud.tscn`: 전투 스킬 하단 HUD
- `game/features/movement_hud/dash_cooldown_hud.tscn`: 이동 스냅샷 기반 대시 준비·재사용 HUD
- `game/features/equipment/equipment_system.tscn`: 장비 로드아웃과 호환성·스탯 집계
- `game/features/map_generation/map_generator.tscn`: 방, 복도, 벽, 길찾기 생성
- `game/features/fog_of_war/fog_of_war.tscn`: 플레이어 중심 월드 시야 제한
- `game/features/minimap/minimap.tscn`: 지형 스냅샷 기반 우측 상단 전술 지도
- `game/features/extraction/extraction_zone.tscn`: F 상호작용 탈출 지점
- `game/features/credits/credit_ledger.tscn`: 작전 크레딧 원장
- `game/features/loot/loot_spawner.tscn`: 파밍 오브젝트 배치
- `game/features/spawning/enemy_spawner.tscn`: 적 생성 기능
- `game/features/room_encounters/room_encounter_system.tscn`: 방 진입·문 봉쇄·전멸·보상 조정
- `game/features/weapons/auto_weapon.tscn`: 자동 공격 기능
- `game/features/experience/progression_system.tscn`: 성장 기능
- `game/features/run_buffs/run_buff_system.tscn`: 한 판 임시 버프
- `game/features/growth_balance/growth_balance_service.tscn`: 내부 성장·장비 강화 밸런스 제공
- `game/features/meta_progression/meta_progression_system.tscn`: 외부 성장과 저장
- `game/features/equipment_upgrade/equipment_upgrade_service.tscn`: 파츠·모듈 강화 경제
