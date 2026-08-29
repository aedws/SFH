# 장면 트리

현재 최상위 구조는 다음과 같습니다.

```text
Game
├─ Modules
│  └─ Player       # 실행 시 FeatureManifest에 따라 생성
└─ UI
   └─ HelpPanel
```

`Game` Scene은 플레이어의 이동 방식을 알지 않습니다. 플레이어 기능이 활성화됐을 때 `player.tscn`을 인스턴스화해 `Modules` 아래에 추가할 뿐입니다.

## 관련 파일

- `game/scenes/game.tscn`: 최상위 장면
- `game/scenes/game.gd`: 모듈 설치 코드
- `game/core/feature_manifest.tres`: 활성 기능 설정
- `game/features/player/player.tscn`: 플레이어 기능 장면
