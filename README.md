<div align="center">

# SFH

### SURVIVE · FIGHT · HAUL

**조준은 자동으로. 판단은 끝까지.**<br>
거점에서 투자하고, 밀려드는 적을 뚫고, 살아서 전리품을 회수하는<br>
Godot 4 기반 모듈형 탑다운 익스트랙션 액션입니다.

[![브라우저에서 바로 플레이](https://img.shields.io/badge/PLAY-브라우저에서_바로_플레이-20d9b0?style=for-the-badge&logo=godotengine&logoColor=white)](https://sfh-game.vstock-market.workers.dev/)
[![Windows x64 빌드](https://img.shields.io/badge/WINDOWS-x64_%EB%B9%8C%EB%93%9C-02e5e1?style=for-the-badge&logo=windows&logoColor=061314)](https://sfh-game.vstock-market.workers.dev/downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip)
[![개발 위키](https://img.shields.io/badge/WIKI-개발_현황과_기획-253b4b?style=for-the-badge)](https://sfh-dev-wiki.pages.dev/)
[![Web deployment](https://github.com/aedws/SFH/actions/workflows/deploy-wiki.yml/badge.svg)](https://github.com/aedws/SFH/actions/workflows/deploy-wiki.yml)

`PLAYABLE PROTOTYPE` · `DESKTOP WEB` · `1280 × 720`

</div>

## 게임 정체성

| 핵심 노선 | SFH의 선택 |
|---|---|
| **No-Aim Action** | 수동 조준을 없애고 스마트 자동 타게팅, 스킬 쿨타임, 이동과 회피 판단에 집중합니다. |
| **Invest & Extract** | 진입 비용으로 지역·난이도·맵 크기를 선택하고, 위험을 감수한 만큼 더 큰 회수를 노립니다. |
| **Room Hacking** | 방 진입과 동시에 문이 닫히고 적 무리가 생성됩니다. 전멸시키면 보상을 확보하고 다음 동선을 선택합니다. |
| **Build Your Gear** | 무기 태그, 방어구, 고유 파츠와 코스트 기반 모듈을 조합해 출격 로드아웃을 구성합니다. |
| **Modular by Default** | 맵·전투·장비·성장·경제를 독립 기능으로 나눠 켜고 끄거나 교체할 수 있게 만듭니다. |

```text
거점 준비 → 진입 투자 → 탐험·방 전투 → 파밍·런 성장 → 탈출 방어 → 정산·영구 성장
     ↑                                                               │
     └──────────────────── 다음 작전 준비 ←───────────────────────────┘
```

## 지금 바로 플레이

별도 설치 없이 [SFH Web 빌드](https://sfh-game.vstock-market.workers.dev/)를 열면 현재 `main` 기준 프로토타입을 실행할 수 있습니다.

- 데스크톱 Chrome, Edge, Whale 등 최신 Chromium 브라우저와 키보드를 권장합니다.
- 첫 로딩에는 Godot WebAssembly와 게임 데이터 다운로드 시간이 필요합니다.
- Windows 빌드는 [SFH-Windows-x64-v0.1.0.zip](https://sfh-game.vstock-market.workers.dev/downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip)으로 바로 받고 [SHA-256 체크섬](https://sfh-game.vstock-market.workers.dev/downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip.sha256)으로 무결성을 확인합니다.
- 개발 중인 프로토타입이므로 세이브 호환성과 밸런스는 변경될 수 있습니다.
- Web 빌드는 `main` 변경 시 자동 생성되며, 내보내기나 E2E에 실패하면 Cloudflare 운영 배포도 중단됩니다.

### 기본 조작

| 입력 | 기능 |
|---|---|
| `WASD` | 이동 |
| `Space` | 회피 이동 |
| `1` · `2` · `3` | 점멸 · 지속 자기장 · 기동 가속 |
| `Q` | 메인·보조 무기 교체 |
| `F` | 작전 게이트·자원 지점·탈출 상호작용 |
| `I` | 가변 격자 가방 |
| `U` / `E` | 장비·모듈·파츠 관리 |
| `M` | 전체 전술 지도·조건부 방 워프 |
| `K` | 전체 키 설정·영구 저장 |
| `ESC` | 현재 창 닫기 |

K 화면에서 이동·전투·스킬·I/U/E/M 메뉴까지 22개 Action을 키보드나 마우스 버튼으로 자유롭게 바꿀 수 있습니다. 외부 VFX는 상업 이용이 확인된 CC0 파일만 반입하며 원문과 출처는 [라이선스 원장](https://sfh-dev-wiki.pages.dev/architecture/third-party-assets/)에 공개합니다.

## 현재 플레이 가능한 범위

- 하나의 큰 시작 거점에서 작전 지역·난이도·맵 크기·페널티·소모품 설정
- 소형·중형·대형 절차 생성 맵과 방·통로 기반 전장의 안개, M 확장 지도·조건부 방 워프
- 방 진입 봉쇄 전투, 1~5개 F 크레딧 보상 박스, 전투 방 완주 조기 탈출
- 점멸, 플레이어 추적형 지속 자기장, 이동속도 증가 전기 스킬
- 크레딧·장비·모듈·고유 파츠 파밍과 2.5~5배 목표 회수 가치
- 탈출 카운트다운 방어전, 성공·사망 정산과 거점 복귀
- 한 판 임시 성장과 캐릭터·무기·방어구 영구 성장
- Google Sheets 실시간 밸런스 테스트와 검증된 CSV 확정 모드

세부 진행률과 최신 변경은 [개발 현황 위키](https://sfh-dev-wiki.pages.dev/development-status/)에서 확인합니다.

## 로컬 실행

1. [Godot 4.7.2](https://godotengine.org/download/windows/) 이상을 설치합니다.
2. Godot Project Manager에서 저장소의 `project.godot`을 가져옵니다.
3. 프로젝트 실행 버튼 또는 `F5`를 누릅니다.

```powershell
git clone https://github.com/aedws/SFH.git
cd SFH
.\scripts\test-game.cmd
```

`SMOKE_TEST_OK`가 표시되면 현재 게임 루프와 모듈 계약이 정상입니다. 대형 작전 CPU 예산은 `scripts\test-performance.ps1`, 위키와 검색은 `scripts\wiki.cmd build`로 검사합니다.

## Private 저장소 복구 안전장치

`main`에 변경이 들어오기 직전 커밋은 `backup/pre-main/<전체 SHA>`, Cloudflare 배포 E2E까지 통과한 커밋은 `backup/verified-main/<전체 SHA>`에 자동 보관합니다. 문제가 생기면 `Prepare main recovery PR` Actions를 실행해 선택한 백업의 트리를 새 `recovery/main/...` 브랜치에 복원하고, 필수 검사를 다시 통과한 PR로만 되돌립니다. `main` 강제 푸시나 이력 재작성은 사용하지 않습니다.

저장소는 Private 상태를 유지합니다. GitHub Free의 Private 저장소에서는 서버 측 Ruleset 강제가 제한되므로, 현재 안전장치는 PR 작업 관례와 두 종류의 불변 백업 브랜치로 보완합니다. Cloudflare 프로젝트·버킷·과금 플랜·결제 설정은 이 백업 절차의 범위 밖입니다.

## 저장소 구조

```text
game/core/       공통 계약과 기능 활성화 설정
game/features/   독립 설치·교체 가능한 게임 기능
game/scenes/     기능을 조립하는 거점·작전 Scene
game/tests/      게임 루프·모듈·성능 자동 검증
docs/            검색 가능한 한국어 개발 위키 원문
```

설계 원칙은 [모듈 규칙](https://sfh-dev-wiki.pages.dev/architecture/module-rules/), 처음 참여하는 작업자를 위한 실행·문서 절차는 [개발 위키](https://sfh-dev-wiki.pages.dev/)에서 확인할 수 있습니다.
