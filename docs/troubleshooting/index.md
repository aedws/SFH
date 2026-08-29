---
title: 문제 해결
tags:
  - 오류
  - FAQ
---

# 문제 해결

## 프로젝트가 실행되지 않음

1. Godot 4 안정 버전을 사용 중인지 확인합니다.
2. 파일 하나가 아니라 저장소 루트의 `project.godot`을 가져왔는지 확인합니다.
3. `game/scenes/game.tscn` 파일이 존재하는지 확인합니다.
4. Godot 하단의 `Output`과 `Debugger`에 표시된 첫 번째 오류를 확인합니다.

## 플레이어가 보이지 않음

`game/core/feature_manifest.tres`의 `Player Enabled`가 켜져 있는지 확인합니다.

좌측 상단에 `활성 모듈: player`가 보이지 않는다면 Manifest가 연결되지 않았을 가능성이 있습니다.

## WASD가 동작하지 않음

현재 WASD는 키보드의 물리 키 위치를 읽습니다. Godot 게임 창을 한 번 클릭한 뒤 다시 입력합니다. 방향키도 함께 시험합니다.

## 위키 명령을 찾을 수 없음

`python` 또는 `mkdocs` 명령을 찾지 못하면 Python 3 설치와 가상 환경 활성화 여부를 확인합니다.

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
```

## PowerShell에서 스크립트를 실행할 수 없음

`PSSecurityException` 또는 `이 시스템에서 스크립트를 실행할 수 없습니다`라는 메시지가 나타나면 `.ps1`을 직접 실행하지 말고 다음 명령을 사용합니다.

```powershell
.\scripts\wiki.cmd serve
```

`wiki.cmd`는 저장소에 포함된 `wiki.ps1`만 별도 PowerShell 프로세스에서 실행합니다. Windows의 사용자 또는 시스템 실행 정책은 변경하지 않습니다.

## 해결되지 않을 때 기록할 정보

- 실행한 단계
- 예상한 결과
- 실제 결과
- Godot Output의 첫 번째 오류 전문
- Godot 버전
- 마지막으로 정상 작동한 Git 커밋
