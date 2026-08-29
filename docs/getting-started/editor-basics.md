# 편집기 기초

## 반드시 알아야 할 다섯 영역

- **Scene**: 현재 장면의 Node 계층
- **2D**: 게임 장면을 시각적으로 배치하는 화면
- **Inspector**: 선택한 Node나 Resource의 설정
- **FileSystem**: 프로젝트 파일 목록
- **Script**: GDScript 코드를 보는 화면

## 핵심 용어

### Node

한 가지 역할을 담당하는 기본 단위입니다. 플레이어의 몸, 충돌 모양, 카메라도 각각 Node입니다.

### Scene

Node 트리를 재사용할 수 있도록 저장한 파일입니다. SFH의 플레이어는 `player.tscn`이라는 독립 Scene입니다.

### Resource

수치와 설정을 담는 데이터입니다. `feature_manifest.tres`에는 어떤 기능을 사용할지 기록합니다.

### Signal

Node가 다른 Node의 내부 구현을 몰라도 사건을 알릴 수 있는 통신 방식입니다.

## 첫 확인

`game/scenes/game.tscn`을 열고 Scene 트리에서 `Game`, `Modules`, `UI`를 차례로 선택해 Inspector가 어떻게 바뀌는지 확인합니다.
