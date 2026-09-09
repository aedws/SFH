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
| 검증·병합 | PR의 변경 분류와 `export-game`·`e2e`·`build` 판정, 게임 변경의 Windows 패키징은 병합 후 수행 | `main` 직접 푸시, 강제 푸시 |
| 진행 중 보존 | 원격 작업 브랜치의 WIP 커밋 | 로컬 폴더만 남기는 백업 |
| 배포 완료 보존 | `backup/pre-main/<SHA>`, `backup/verified-main/<SHA>` | 같은 이름의 ZIP을 여러 폴더에 복제 |
| 문제 복구 | 이전 트리를 복원하는 새 PR | `main` reset·이력 재작성 |

커밋은 되돌릴 수 있는 변경 단위이고, PR은 왜 바뀌었는지와 검사 결과를 남깁니다. 폴더 복사는 어느 것이 최신인지 판별할 수 없고 필수 검사를 우회하므로 백업으로 취급하지 않습니다.

## 표준 작업 순서

1. 기본 폴더에서 `git fetch origin main`으로 최신 원격 기준을 받습니다.
2. `origin/main`에서 `codex/<작업명>` 브랜치 또는 임시 worktree를 만듭니다.
3. 기능과 문서를 작은 단위로 커밋하고 같은 브랜치를 GitHub에 푸시합니다.
4. PR에서 필수 검사를 통과한 뒤 `main`에 병합합니다.
5. Cloudflare 배포와 실행 산출물의 근거를 확인합니다. 게임 변경은 병합 커밋의 트리·파일 해시를 검증하고, 문서 전용 배포는 기존 게임·Windows 빌드 커밋을 유지합니다.
6. 작업 worktree가 깨끗하고 그 변경이 `origin/main`에 포함됐을 때만 제거합니다.
7. 기본 `Newgame`을 최신 `main`으로 맞추고 `git worktree prune`으로 끊어진 등록만 정리합니다.

새 목록이 필요한 기능은 기존 규칙대로 Google Sheet를 확장하고 확정 CSV를 같은 PR에 포함합니다. 작업 폴더 정리는 게임 데이터·배포 주소·Cloudflare 과금 설정을 변경하지 않습니다.

## Actions 사용량 절감 {#actions-budget}

**현행(2026-09-09): GitHub는 소스·PR·검사 로그·복구 커밋을 보관합니다. 빌드 파일은 GitHub Artifact/Pages를 거치지 않고 자체 러너에서 Cloudflare로 직접 전달합니다.** 아래 9월 6일 사용량은 과거 표본이며 현재 저장량·요금으로 읽지 않습니다.

2026-09-06 점검에서 최근 배포 워크플로 19회는 작업별 분 올림으로 약 228분을 소비했습니다. 이는 청구 API의 계정 합계가 아닌 실행 이력의 추정치입니다. 아티팩트는 약 55MB로 정리되어 있었고, PR과 main의 동일 게임 검증·패키징 반복이 주된 개선 대상이었습니다.

| 변경 | 실행 방식 | 배포 결과 |
|---|---|---|
| 문서·위키 CSS·MkDocs 설정만 변경 | 명시적 문서 허용 목록에 한해 Godot 검사를 생략하고 위키 검증 실행 | 위키만 갱신, 현재 게임과 Windows 다운로드 유지 |
| 게임·CSV·내보내기·워크플로·알 수 없는 새 파일 변경 | PR에서 계약 검사·E2E·Web 내보내기 | 실패하면 병합 보류 |
| 게임 PR 병합 | main에서 게임 검사·E2E·Web·Windows를 다시 생성 | 같은 실행·커밋의 검증 파일만 전달 |
| 임시 전달 파일 없음·해시/실행 불일치 | 배포 실패, 전체 워크플로 재실행 | 오래된 산출물로 대체하거나 검사를 생략하지 않음 |
| 수동 실행 | 전체 게임 변경으로 취급 | 재빌드·복구 경로 유지 |

PR은 새 커밋이 오면 이전 실행을 취소합니다. main 배포는 실행 도중 취소하지 않습니다. 워크플로 전체를 경로로 생략하지 않으므로 필수 검사가 영구 대기 상태에 남지 않습니다. `build`는 필요한 선행 검사 실패를 확인하고 실패로 끝납니다. Godot 작업의 최대 실행 시간은 15분입니다.

변경 전 백업은 `plan`, 배포 검증 후 백업은 Cloudflare 작업에 둡니다. 기존 `backup/pre-main/<SHA>`와 `backup/verified-main/<SHA>`는 유지합니다. 신규 Actions 아티팩트 업로드·다운로드와 GitHub Pages 경로는 제거했습니다. GitHub의 기존 저장량 집계가 늦게 갱신되어도 신규 배포는 그 저장소를 사용하지 않습니다. 자체 러너 전력·디스크와 Cloudflare의 기존 사용량은 발생하므로 무제한·무료 보장을 뜻하지 않습니다. 요금제·결제·예산 설정은 변경하지 않습니다.

### 소스와 배포 파일의 책임 분리 {#source-only-delivery}

| 책임 | 보관 위치 | 보존·실패 규칙 |
|---|---|---|
| 소스·기획 확정 CSV·빌드 스크립트 | Private Git 커밋/PR | 이력 재작성 없이 복구 PR |
| 테스트 판정·배포 근거 | Actions 로그와 SHA-256 manifest | 필수 `export-game`·`e2e`·`build` 유지 |
| 작업 간 파일 전달 | 전용 러너의 checkout 옆 `.sfh-build-store` | 저장소/실행/시도/표면별 격리, 종료 후 해당 임시본만 삭제 |
| 위키 | 기존 Cloudflare Pages | 직접 업로드, 인증 R2와 계정·비밀번호 유지 |
| Web | Private R2 `game/releases/<commit>/` | 검증 후 Worker 활성 커밋 전환, 이전 Web 경로 보존 |
| Windows | Private R2 `downloads/releases/<commit>/<version>/` | 새 다운로드 검수 뒤 현재+직전 정상본 보존, 그 외 정확한 Windows ZIP/체크섬만 정리 |

`ci_budget.py`는 실행할 검사를 결정하고, `ci_transfer.py`는 파일 전달만 맡습니다. 전달 manifest에는 저장소·커밋·Git tree·실행 ID·시도 번호·표면·모든 파일의 크기/SHA-256을 기록합니다. 숨김 파일도 포함하며 누락·추가·변조·링크·대상 덮어쓰기는 실패합니다. 이 manifest는 서명이 아니며 악성 코드가 실행되는 러너를 방어하지 않습니다. 신뢰한 소유자 코드만 실행하는 경계가 필요합니다.

**현재 계약은 동일한 전용 러너 1대입니다.** 다른 러너로 작업을 분산하면 전달 파일을 찾지 못해 실패해야 합니다. 확장 시 별도 전송 저장소 어댑터와 접근권한·해시·실행 격리 검사를 추가합니다. 루트는 checkout 내부나 정리되는 `RUNNER_TEMP`가 아니라 컨테이너에도 공유되는 checkout의 부모입니다.

**재시도:** 실패 작업만 재실행하면 선행 파일의 시도 번호가 달라집니다. `Re-run all jobs`로 처음부터 검증합니다. 정상·실패 종료의 `clean-transfer`는 해당 실행/시도만 제거합니다. 강제 전원 종료로 정리가 실행되지 않았다면 실행 종료를 확인한 후 해당 숫자 ID 디렉터리만 정리합니다. 다른 실행·사용자 파일·Git·R2 인증 데이터를 일괄 삭제하지 않습니다. 장기 빌드 백업 대신 Git에서 다시 빌드하므로 타임스탬프까지 바이트 동일함을 보장하지 않습니다.

배포는 임시 전달본 검증 → Web/Windows 커밋·ZIP 체크섬 검증 → R2 후보 전체 읽기/해시 재검증 → Worker 전환 → Pages 직접 업로드 → 공개 HTTP/Range/ZIP·역할 접근 검증 순서입니다. R2 후보 검증은 사람의 브라우저 플레이 검수가 아닙니다. 전환 뒤 검증 실패 시 캡처한 직전 게임 커밋/다운로드 경로로 복구를 시도하고 실패 상태를 유지합니다. 네트워크·권한 장애로 복구 자체가 실패하면 기존 manifest와 Git 복구 PR로 수동 대응합니다. 위키와 게임은 서로 다른 배포이므로 전역 원자적 전환을 주장하지 않습니다.

기존 웹·다운로드 링크와 위키 도메인은 그대로입니다. Windows 공개 URL은 최신 릴리스 별칭이므로 장기 immutable 캐시를 제거했습니다. 기존 브라우저에 이미 저장된 이전 캐시는 캐시를 우회하는 새 다운로드로 확인해야 할 수 있습니다. 첫 전환에는 직전의 구형 `downloads/<version>/` ZIP도 롤백용으로 보존하고 다음 정상 전환에서 새 정책으로 정리합니다.

검사: `test_ci_budget.py`, `test_ci_transfer.py`, `test_cloudflare_release.py`, `test_windows_release_retention.py`, `test_cloudflare_worker.mjs`, 배포/백업 경계 검사. 로컬 통과와 실제 PR·main 배포 통과는 분리해 실행 로그에서 확인합니다.

### 현재 PC의 전용 Linux 러너

운영 전환은 `main`에서만 실행합니다. 이미 활성화된 같은 커밋을 수동 재배포하면 실행 파일 덮어쓰기를 막기 위해 중단합니다. 정상 배포 이후 수정·복구는 새 PR 커밋으로 진행합니다.

WSL2의 `Ubuntu-24.04`와 `sfh-wsl-build` 러너(`sfh-build` 라벨)가 분류·게임 검사·E2E·Web/Windows 내보내기·위키 빌드·Cloudflare 배포·복구 PR을 모두 담당합니다. **2026-09-07부터 GitHub-hosted 자동 대체를 제거했습니다.** PC를 켜지 않으면 작업은 대기하며 과금 설정을 올리지 않습니다. 등록 토큰은 저장소에 기록하지 않습니다.

- PC 자원: WSL 메모리 4GB, CPU 4개, swap 2GB. 다른 WSL 배포판을 추가하면 이 제한을 함께 사용합니다.
- 접근 범위: 별도 `sfh-runner` 계정, Windows 드라이브 자동 연결·Windows 프로그램 호출 해제. Docker 권한은 Linux 관리자 수준이므로 완전한 보안 격리는 아닙니다. 동일 저장소의 소유자 PR과 main만 실행하며 다른 기여자의 PR은 자동 실행하지 않습니다. 소유자가 코드를 검토한 후 실행해야 합니다. 배포 비밀키는 배포 작업에만 전달되지만 영구 러너는 비밀을 다루는 신뢰 경계이므로 미검토 코드를 실행하면 안 됩니다.
- 수동 실행: `SFH Linux Runner Host`와 `SFH Linux Runner Heartbeat`에는 시간·부팅·로그인 트리거가 없습니다. 사용자가 `start`를 실행한 세션에서만 WSL을 유지하고 1분마다 온라인 상태를 확인해 3분짜리 준비 유효기간을 갱신합니다. 재부팅·로그아웃 뒤 자동 재시작하지 않습니다. 단순 화면 잠금·절전은 개발 종료가 아니므로 종료할 때는 `stop`을 사용합니다.
- 선택 조건: 모든 작업은 `self-hosted / Linux / X64 / sfh-build`로 고정합니다. 기존 준비 변수는 진단용이며 만료돼도 hosted로 넘어가지 않습니다. 라벨 변경은 워크플로와 `ci_budget.py`를 함께 수정하고 회귀 검사합니다.
- 예외: PC가 꺼지면 대기 작업은 다음 수동 시작을 기다립니다. 실행 중 PC 장애가 발생하면 실패 원인을 확인한 뒤 재실행합니다. 사용량 부족을 해결하려고 필수 검사를 생략하지 않습니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\SFHRunner\sfh-runner.ps1" start
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\SFHRunner\sfh-runner.ps1" stop
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\SFHRunner\sfh-runner.ps1" status
```

**쉬운 실행:** 사용자 폴더의 `SFHRunner`에서 `SFH Runner start`, `SFH Runner stop`, `SFH Runner status` 바로가기를 더블클릭합니다. 설치 파일과 게임은 WSL을 끈 상태에서도 사용할 수 있습니다. 러너는 GitHub 빌드가 필요할 때만 켭니다.

`stop`은 실행 중 빌드가 없는지 확인한 후 유지 작업과 `Ubuntu-24.04`만 종료합니다. Linux 파일·Docker 이미지·러너 등록은 삭제하지 않습니다. 다른 WSL 배포판은 종료하지 않으므로 다른 배포판이 실행 중이면 `vmmemWSL`이 남을 수 있습니다. `status`는 Linux 명령을 실행하지 않아 WSL을 깨우지 않습니다. GitHub 변수를 false로 바꾸는 것만으로는 PC 메모리가 반환되지 않습니다.

빌드가 실행 중이거나 GitHub 인증·네트워크 오류로 상태를 확인할 수 없으면 안전을 위해 종료를 거부합니다. 워크플로 전체 종료 또는 연결 복구 후 `stop`을 다시 실행합니다. 대기 작업은 다음 수동 시작 때 이어집니다. WSL을 다른 프로그램에서 직접 시작하는 동작까지 차단하지는 않습니다.

위키/배포 도구는 전용 WSL에서 `scripts/setup-sfh-runner-web.sh`로 준비합니다. Ubuntu Python/venv·공식 Microsoft PowerShell·체크섬을 검증한 Node 바이너리를 사용하며 CI마다 별도 venv와 Wrangler 작업 폴더를 만듭니다. Windows의 Node/Python이나 요금제는 변경하지 않습니다.

설치 재현 시 `scripts/setup-sfh-runner.sh`는 전용 Ubuntu에서 root로 실행하며, 공식 러너 압축파일의 SHA-256을 검증합니다. PowerShell 파이프로 전달한다면 CR 문자를 제거해 실행합니다. Windows 소유자 계정에서 러너를 정지한 뒤 `scripts/install-sfh-runner-heartbeat.ps1`을 실행하면 안정 복사본과 바로가기를 `%USERPROFILE%\SFHRunner`에 두고 **트리거 없는 수동 예약 작업만 등록**합니다. 설치 자체는 WSL을 켜지 않습니다. 작업 브랜치 변경에 영향받지 않으며, 원본 수정 후에는 검토하고 다시 설치합니다.

회귀 검사는 `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-sfh-runner-controls.ps1`입니다. 실제 서비스 대신 대역을 사용해 상태 조회의 비기동, 수동 시작·종료 순서, 빌드 중·API 오류 시 종료 거부, 구형 자동 트리거 거부와 설치 시 자동 실행 부재를 검사합니다.

GitHub 요금제·예산·Private 설정은 변경하지 않습니다. 서버 측 Ruleset 사용 가능 여부는 계정 요금제와 별개로 확인해야 하며, 워크플로의 검사 성공이 Ruleset 강제 적용을 뜻하지 않습니다.

### 2026-09-06 실제 검증 기록

PR 153과 병합 커밋 `e4ca548`에서 전용 러너·재사용·배포 경로를 확인했습니다. 회귀 단위 검사 9개, 게임 계약 검사, 실제 입력 E2E, 위키 검증이 통과했습니다. Web 전체 파일의 해시를 배포 직전 다시 확인했고, Windows ZIP 체크섬·게임 상태·위키 권한 경로·HTTP Range 검사와 두 백업 브랜치 생성도 통과했습니다.

| 정상 PR 1회 + 병합 배포 1회 | 이전 실행 표본 | 개선 후 실행 표본 |
|---|---:|---:|
| GitHub-hosted 사용 분 추정 | 24분 | 6분 |
| PR 구간 | 10분 | 2분 |
| 병합·배포 구간 | 14분 | 4분 |

직전 PR 152의 실행 `33975947990`, main 실행 `33976300564`와 별도 백업 `33976300697`을 새 PR 실행 `34024497953`, main 실행 `34024717246`과 비교했습니다. **당시 작업별 시간을 분 단위로 올림한 추정으로 약 75% 감소**이며 청구 API 합계는 아닙니다. 이는 9월 6일 혼합 러너 정책의 기록이며, 9월 7일 이후에는 hosted 대체 실행을 하지 않습니다. 자체 러너는 PC 전력·자원을 사용하고 아티팩트 저장 비용까지 없어지는 것은 아닙니다.

설치 검수 중 WSL 유휴 종료, 영구 HOME의 템플릿 중복 이동, 빈 job output 생략, 컨테이너 Git 소유자 차이를 발견해 보완했습니다. 검사 실패 상태에서는 `build`가 실패하고 배포가 생략되는 것도 실제 확인했습니다. 전용 러너의 작업 토큰은 `contents: read`로 제한합니다.

문서 전용 회귀 기준: 이 검증 기록처럼 문서만 추가한 PR은 게임 검사·Web/Windows 생성이 생략되어도 위키 검증은 실행해야 합니다. 병합 뒤 위키만 갱신하고 게임 `/healthz`의 빌드 커밋과 Windows ZIP SHA-256은 그대로 유지해야 합니다. 산출물 정리는 성공한 배포 이후에만 실행합니다.

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

동시 작업이 꼭 필요할 때만 `Newgame-<짧은 작업명>`을 추가하고, PR 병합·배포 확인 직후 위 검사로 제거합니다. 로컬 Windows 다운로드는 최신본만, R2는 현재와 직전 정상본만 유지합니다. 더 오래된 버전은 Git 커밋에서 다시 빌드합니다.

## 이번 정리 기록 · 2026-09-05

- 완료된 임시 worktree 10개를 등록 해제했고 실제 변경은 모두 병합 커밋 또는 patch-equivalent 커밋으로 `main`에서 확인했습니다.
- 기본 폴더에 남아 있던 Godot 에디터 재저장 상태는 `codex/backup-desktop-pre-cleanup-20260905`의 `5e57fde`로 원격 보존한 뒤 기본 폴더를 최신 `main`으로 맞췄습니다.
- 최신 기능에서 빠져 있던 GDScript UID를 재수집·추적해 새 clone의 첫 headless 스모크도 전역 클래스를 바로 찾도록 복구했습니다.
- 기존 `backup/pre-main/*`, `backup/verified-main/*`, Release·Actions·R2 최신 산출물 정책은 유지했습니다.
- 게임 기능, Sheet/CSV, 사용자 저장, Cloudflare 배포·과금 설정은 변경하지 않았습니다.

## Actions 런타임 공급망 기준 · 2026-09-05

> 과거 전환 기록입니다. 2026-09-09부터 위의 [소스/배포 분리](#source-only-delivery)가 우선하며 artifact 액션과 Pages 호환 경로를 사용하지 않습니다. 현재 남은 액션의 SHA 고정과 허용 목록 제한은 계속 적용합니다.

Web·Windows·위키 산출물 전달은 공식 `actions/upload-artifact` v7.0.1과 `actions/download-artifact` v8.0.1을 사용합니다. 비활성 GitHub Pages 호환 경로도 `upload-pages-artifact` v5.0.0으로 맞췄습니다. artifact 실행부는 Node.js 24 런타임이며 이동 태그가 아니라 각 정식 릴리스의 40자리 커밋 SHA로 고정합니다.

저장소의 **선택된 Actions 허용 목록**도 같은 SHA와 Pages 합성 액션이 내부에서 호출하는 `upload-artifact` v7.0.0 SHA로 갱신했습니다. `github_owned_allowed=false`, `verified_allowed=false`, `sha_pinning_required=true` 경계는 유지되어 목록 밖 액션이나 이동 태그는 작업이 시작되기 전에 차단됩니다.

배포 경계 검사는 다음을 병합 전에 강제합니다.

- 모든 `uses:` 참조가 40자리 SHA임
- upload 3곳, download 3곳, Pages 호환 업로드 1곳이 승인된 SHA와 정확히 일치함
- 기존 Node 20 artifact SHA가 다시 들어오지 않음
- 산출물 이름, 1일 보존, 최신 검증 런 한 세트만 유지하는 정책이 그대로임

GitHub Pages 관련 공식 액션은 현재 배포 경로에서 건너뛰며, 최신 정식 릴리스가 아직 Node 20인 액션을 미출시 브랜치 커밋으로 임의 교체하지 않습니다. 게임·위키 산출물 내용, Cloudflare/R2 권한과 과금 모델은 이 갱신으로 바뀌지 않습니다.
