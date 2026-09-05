---
title: 작업 폴더 정리와 Git 복구
description: 바탕화면 복제 폴더를 만들지 않고 작업 브랜치·PR·검증 커밋으로 안전하게 되돌리는 SFH 형상 관리 기준
tags:
  - Git
  - GitHub
  - worktree
  - 백업
  - 복구
  - 작업 폴더
---

# 작업 폴더 정리와 Git 복구

SFH의 원본은 바탕화면 복제 폴더가 아니라 **Private GitHub 저장소의 커밋**입니다. 평소에는 `C:\Users\uyess\Desktop\Newgame` 하나만 유지하고, `Newgame-*` worktree는 작업이 진행되는 동안에만 사용합니다.

## 한눈에 보는 운영 원칙

| 상황 | 사용할 것 | 사용하지 않을 것 |
|---|---|---|
| 기능 개발 | `codex/<작업명>` 브랜치와 작은 커밋 | `Newgame-복사본`, `최종`, `진짜최종` 폴더 |
| 검증·병합 | PR과 필수 `export-game`·`e2e`·`package-windows`·`build` 검사 | `main` 직접 푸시, 강제 푸시 |
| 진행 중 보존 | 원격 작업 브랜치의 WIP 커밋 | 로컬 폴더만 남기는 백업 |
| 배포 완료 보존 | `backup/pre-main/<SHA>`, `backup/verified-main/<SHA>` | 같은 이름의 ZIP을 여러 폴더에 복제 |
| 문제 복구 | 이전 트리를 복원하는 새 PR | `main` reset·이력 재작성 |

커밋은 되돌릴 수 있는 변경 단위이고, PR은 왜 바뀌었는지와 검사 결과를 남깁니다. 폴더 복사는 어느 것이 최신인지 판별할 수 없고 필수 검사를 우회하므로 백업으로 취급하지 않습니다.

## 표준 작업 순서

1. 기본 폴더에서 `git fetch origin main`으로 최신 원격 기준을 받습니다.
2. `origin/main`에서 `codex/<작업명>` 브랜치 또는 임시 worktree를 만듭니다.
3. 기능과 문서를 작은 단위로 커밋하고 같은 브랜치를 GitHub에 푸시합니다.
4. PR에서 필수 검사를 통과한 뒤 `main`에 병합합니다.
5. Cloudflare 배포와 실행 산출물이 같은 병합 커밋인지 확인합니다.
6. 작업 worktree가 깨끗하고 그 변경이 `origin/main`에 포함됐을 때만 제거합니다.
7. 기본 `Newgame`을 최신 `main`으로 맞추고 `git worktree prune`으로 끊어진 등록만 정리합니다.

새 목록이 필요한 기능은 기존 규칙대로 Google Sheet를 확장하고 확정 CSV를 같은 PR에 포함합니다. 작업 폴더 정리는 게임 데이터·배포 주소·Cloudflare 과금 설정을 변경하지 않습니다.

## 삭제 전에 반드시 확인할 네 가지

작업 폴더 하나를 지우려면 다음 조건을 모두 만족해야 합니다.

- `git status --short`가 비어 있거나, 남은 파일이 재생성 가능한 캐시임을 직접 확인했습니다.
- 해당 PR이 병합됐고 원격 `main`을 최신으로 가져왔습니다.
- 브랜치 HEAD가 `main`의 조상이거나 `git cherry origin/main HEAD`의 모든 행이 `-`입니다. `-`는 squash 병합 등으로 같은 패치가 이미 들어갔다는 뜻입니다.
- 고유 변경이 남았다면 삭제 전에 `codex/backup-<이유>-<날짜>`에 커밋하고 원격으로 푸시했습니다.

읽기 전용 감사는 다음 명령으로 실행합니다.

```powershell
.\scripts\audit-worktrees.ps1
```

결과가 `REMOVE-CANDIDATE`인 폴더만 제거 후보입니다. `HOLD-DIRTY`는 미커밋 파일이 있고, `HOLD-UNMERGED`는 `main`에 없는 패치가 있으므로 먼저 내용을 확인해야 합니다. 감사 스크립트는 폴더를 삭제하지 않습니다.

## 안전한 제거

등록된 worktree는 탐색기에서 먼저 지우지 말고 저장소 루트에서 정확한 절대 경로를 지정합니다.

```powershell
git worktree remove "C:\Users\uyess\Desktop\Newgame-작업명"
git worktree prune
```

`--force`는 미커밋 파일도 삭제하므로 기본 절차에서는 사용하지 않습니다. Godot의 `.godot/`, 내보내기 결과, 테스트 임시 파일처럼 재생성 가능한 항목이라도 경로와 내용을 확인한 경우에만 별도로 정리합니다. 반면 GDScript 옆의 `.gd.uid`는 Scene·Resource 참조를 안정화하는 소스 식별자이므로 `.gd`와 함께 커밋합니다. 사용자 저장 데이터, 비밀값, Google Sheet 원본, 현재 `Newgame` 폴더는 일괄 삭제 대상이 아닙니다.

## 복구 수준

### 1. 아직 병합하지 않은 작업

작업 브랜치의 마지막 정상 커밋에서 새 브랜치를 만들거나, 필요한 파일만 새 커밋으로 되돌립니다. 미커밋 변경을 보존해야 하면 먼저 WIP 커밋을 원격에 푸시합니다. stash는 다른 PC에서 보이지 않으므로 장기 백업으로 사용하지 않습니다.

### 2. 이미 병합된 변경

문제가 된 PR의 변경을 되돌리는 새 PR을 만듭니다. 수정된 복구 결과도 동일한 필수 검사를 거쳐야 하며 `main`을 과거 커밋으로 강제 이동하지 않습니다.

### 3. 배포까지 끝난 기준점

모든 `main` 변경 직전은 `backup/pre-main/<전체 SHA>`, Cloudflare E2E까지 성공한 상태는 `backup/verified-main/<전체 SHA>`에 자동 보존됩니다. GitHub Actions의 `Prepare main recovery PR`에서 검증된 백업 브랜치를 선택하면 현재 `main` 위에 복구 커밋과 PR을 만듭니다.

### 4. 로컬 에디터 상태만 남은 경우

필요 여부를 확신할 수 없으면 `codex/backup-desktop-<날짜>` 같은 명확한 브랜치에 커밋·푸시한 뒤 기본 폴더를 최신 `main`으로 되돌립니다. 이 브랜치는 병합 대상이 아니며, 복구가 필요할 때 파일 단위로 비교하는 증거입니다.

## 유지할 로컬 구조

```text
Desktop/
└─ Newgame/              # 유일한 상시 작업 폴더 · 최신 main
   ├─ game/
   ├─ docs/
   ├─ scripts/
   └─ .git/
```

동시 작업이 꼭 필요할 때만 `Newgame-<짧은 작업명>`을 추가하고, PR 병합·배포 확인 직후 위 검사로 제거합니다. Windows 다운로드는 로컬과 R2 모두 최신 검증본 한 세트만 유지하며, 이전 버전은 Git 커밋에서 다시 빌드합니다.

## 이번 정리 기록 · 2026-09-05

- 완료된 임시 worktree 10개를 등록 해제했고 실제 변경은 모두 병합 커밋 또는 patch-equivalent 커밋으로 `main`에서 확인했습니다.
- 기본 폴더에 남아 있던 Godot 에디터 재저장 상태는 `codex/backup-desktop-pre-cleanup-20260905`의 `5e57fde`로 원격 보존한 뒤 기본 폴더를 최신 `main`으로 맞췄습니다.
- 최신 기능에서 빠져 있던 GDScript UID를 재수집·추적해 새 clone의 첫 headless 스모크도 전역 클래스를 바로 찾도록 복구했습니다.
- 기존 `backup/pre-main/*`, `backup/verified-main/*`, Release·Actions·R2 최신 산출물 정책은 유지했습니다.
- 게임 기능, Sheet/CSV, 사용자 저장, Cloudflare 배포·과금 설정은 변경하지 않았습니다.

## Actions 런타임 공급망 기준 · 2026-09-05

Web·Windows·위키 산출물 전달은 공식 `actions/upload-artifact` v7.0.1과 `actions/download-artifact` v8.0.1을 사용합니다. 두 액션 모두 Node.js 24 런타임이며 이동 태그가 아니라 각 정식 릴리스의 40자리 커밋 SHA로 고정합니다.

배포 경계 검사는 다음을 병합 전에 강제합니다.

- 모든 `uses:` 참조가 40자리 SHA임
- upload 3곳과 download 3곳이 승인된 Node 24 SHA와 정확히 일치함
- 기존 Node 20 artifact SHA가 다시 들어오지 않음
- 산출물 이름, 1일 보존, 최신 검증 런 한 세트만 유지하는 정책이 그대로임

GitHub Pages 관련 공식 액션은 현재 배포 경로에서 건너뛰며, 최신 정식 릴리스가 아직 Node 20인 액션을 미출시 브랜치 커밋으로 임의 교체하지 않습니다. 게임·위키 산출물 내용, Cloudflare/R2 권한과 과금 모델은 이 갱신으로 바뀌지 않습니다.
