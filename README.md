# SFH

Godot 4 기반의 모듈형 탑다운 뱀서라이크 프로젝트입니다.

현재 목표는 화려한 콘텐츠보다 다음 세 가지를 먼저 검증하는 것입니다.

1. 처음부터 끝까지 실행 가능한 최소 게임 루프
2. 기능을 독립적으로 켜고 끌 수 있는 모듈 구조
3. 초보자도 검색해서 따라갈 수 있는 한국어 개발 위키

## 현재 구현 상태

- Godot 4 프로젝트 골격
- `FeatureManifest` 기반 기능 활성화 설정
- 플레이어 이동 모듈
- 카메라 추적과 임시 도형 그래픽
- Material for MkDocs 기반 개발 위키 소스

## 게임 실행

1. [Godot 공식 다운로드 페이지](https://godotengine.org/download/windows/)에서 Godot 4 안정 버전을 설치합니다.
2. Godot Project Manager에서 이 폴더의 `project.godot`을 가져옵니다.
3. 우측 상단의 프로젝트 실행 버튼 또는 `F6`가 아닌 `F5`를 누릅니다.
4. `WASD` 또는 방향키로 이동합니다.

자세한 설명은 `docs/getting-started/`에서 확인할 수 있습니다.

## 위키 실행

Python 3가 설치된 PowerShell에서 다음 명령을 실행합니다. 스크립트가 프로젝트 전용 가상환경과 필요한 패키지를 자동으로 준비합니다.

```powershell
.\scripts\wiki.cmd serve
```

브라우저에서 `http://127.0.0.1:8000`을 열면 검색 가능한 개발 위키가 표시됩니다.

## 온라인 위키

배포된 위키는 [https://aedws.github.io/SFH/](https://aedws.github.io/SFH/)에서 확인합니다.

문서 우측 상단의 연필 아이콘을 누르면 GitHub 웹 편집기로 이동합니다. 수정 사항이 `main` 브랜치에 반영되면 GitHub Actions가 위키를 자동으로 다시 배포합니다.

## 주요 경로

```text
game/core/       공통 계약과 모듈 활성화 설정
game/features/   독립적으로 설치 가능한 게임 기능
game/scenes/     여러 기능을 조립하는 최상위 장면
docs/            개발 위키 원문
```

문서의 링크와 검색 인덱스만 검증하려면 `.\scripts\wiki.cmd build`를 실행합니다.
