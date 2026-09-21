---
title: Master GDD 구현 대조
description: 2026-09-09 전체 재검사 80.3% · 기획 미정 제외87.5% · 훈련 라이브 오류와 일반 플레이 잔여
tags:
  - 기획
  - Master GDD
  - 진행률
  - 확정 사항
  - 로드맵
---

# Master GDD 구현 대조

## 공개 원본 재확인 · 2026-09-21 {#source-recheck-20260921}

**원본이 변경됐습니다. 기존 80.3%는 9/9의 66행 기준 이력이며 최신 82행 완료율이 아닙니다.** 연결 앱은 접근 404였으나, 공개 페이지 API를 사용한 저장소의 `snapshot_notion_source.py`·`snapshot_notion_tracker.py` 조회는 성공했습니다. Notion 원문은 수정하지 않았습니다.

| 조회 근거 | 이전 기준 | 이번 라이브 조회 |
|---|---|---|
| Master GDD | v128 / 62블록 | v206 / 101블록, 신규39블록 |
| 작업표 | 66행 | 82행, 신규16행; 기존66행 내용 변경 없음 |
| GDD SHA-256 | `5702a448dd07…` | `f957ba4aa02e438cc16d6e826ad02763e78e18deade64b153ab961889be27459` |
| 작업표 SHA-256 | `b1eb9834f867…` | `02c4f32d2f5d543be4ae7879d3f9ca3f7b454a400a158cbbb8b544abae507ed7` |

신규16행은 모두 기획상 `결정 (미구현)`입니다. 이는 코드 부재의 증거가 아닙니다. 1~2분 루프 행이 `->`/`➔` 표기만 다르게 두 번 등록됐으므로 중복 해소 전 두 기능으로 가산하지 않습니다. 기존 정량 감사 JSON은 66행 기준 이력으로 보존하며, 신규16행의 세부 코드 증거·충돌 판정 전 새 퍼센트를 만들지 않습니다.

### 무엇이 추가됐고 무엇을 확인해야 하나

| 신규 요구 묶음 | 코드 대조 및 다음 판단 |
|---|---|
| 1~2분 탐색→전투→파밍→결단, 공격 전조0.3~0.5초 | 기존 방 전투·보상·F 획득 기반은 있음. 3초 내 보상 판단·전조별 회피 수락은 별도 측정 필요 |
| 15~20분 권장 탈출, 20분 이후 오염/추격자, 30분 즉사 | 현행 규모 설정은 소형540초·중/대형600초 목표. 기존 10분 내외 요청과 상충하므로 세션 길이·강제 종료를 이번 표현 수정에 섞지 않음 |
| 탈출 반경 이탈2초 유예 후 초당1초 역행 | `extraction_zone.gd`는 현재 구역 밖 일시정지/재진입 재개. 감쇠 상태·상한·HUD 안내 회귀를 별도 구현해야 함 |
| 상점/제작 최대희귀·기본스탯·1~2소켓, 심층 전용 종결3소켓 | 일반 장비/고정 옵션과 구분할 드랍·판매 원천 정책 및 심층 선행 작업 필요 |
| 가방12×3/4/5/6, 표준 아이템 크기·스택, 파우치2×2→2×4 | 현행 `default_inventory.tres`는12×8. 회전/빈칸 배치 기반은 있으나 용량 축소 시 기존 저장품 보존·이동 정책부터 필요. ‘4대 크기’ 본문은 실제5종을 열거함 |
| 가방을 열어도 실시간, F 빠른 획득 | F 획득 기반은 있음. `inventory_window.gd`는 현재 열 때 일시정지하므로 입력 격리·피격·저장 확인·이탈 동작 재설계 필요 |
| 스킬당1~3 룬 소켓, 형태/원소/트리거/유틸 변형, 장착 룬 탈출 환전 | 현재 런 소켓 모듈을 스킬별 계약과 구분해 확장해야 함. 자동 환전과 파우치 보존의 우선순위 확인 필요 |
| 뱅가드 AP+15%·이동 AP 회복+20%, 특화5요원·업적 해금 | 1요원1패시브·자유 액티브 기반은 있음. 현행3요원의 수치형 카탈로그만으로 조건부 이벤트 패시브 전체 구현을 주장할 수 없음 |

신규 요원은 고스트(대시 후2초 확정 치명/이속), 타이탄(동일 대상 연타 공속 최대45%), 블러드하운드(HP 소모/흡혈/물약 반감), 데드아이(5m 밖 피해+35%), 스캐빈저(가방+6/금고+1)입니다. 픽셀↔m 환산, 공속 누적/해제 조건, HP 비용·흡혈량, 업적↔요원 대응표는 추가 명세가 필요합니다.

### 다음 작업 순서

1. 현재 공격/명중/40스킬 표현과 전리품 비교 수정의 필수 검사·병합·배포를 마감합니다.
2. 개발자 오너 판단 콘솔의 `DEC-N26-0921`에서 세션 길이·가방 마이그레이션·파우치/룬 정산·요원 조건부 수치의 적용 범위를 확인합니다.
3. 승인 전에도 가능한 작업: 신규16행을 고유 Notion 행 ID 기준으로 코드/시험 근거에 연결하고 중복1쌍을 분리 표시합니다. 기존82행 전체 대조 및 가중치 재산정은 후속 작업입니다.
4. 신규 목록이 실제 구현에 필요할 때만 Sheet를 확장하고 라이브→잠금 CSV→Web payload→계산기/배포 메타데이터 동등성을 유지합니다.

출처: [Master GDD](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed) · [공개 작업표](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2). 공개 원본 읽기 결과와 코드 대조를 구분하며, 아래 과거 기록은 당시 기준입니다.

## 노션 대조·전체 검사 기록 · 2026-09-09 20:12 {#full-20260909}

마감 시점 게임은 `a423dad`·CSV `2026-09-09.3`으로 갱신됐습니다. [오늘 코드/위키 충돌 정리](../quality/full-system-audit-20260909.md#day-close-20260909)와 [9/10 첫 작업 패킷](current-milestone-workline.md#start-packet-20260910)을 우선합니다. 아래는 당시 노션 재조회 근거이며 이번 문서 마감에서 노션을 재조회하거나 점수를 올리지 않았습니다.

**아직100%가 아닙니다.** 코드/공개 게임 `a41f424`를 기준으로 전체 게임·E2E·모듈 검사를 다시 실행했고, 공개 GDD62블록·트래커66행의 라이브 해시가 동일함을 확인했습니다. 노션 판정은 **구현45·부분1·미구현6·미정14, 80.3%**를 유지합니다. [검사 결과·재현 오류·내일 순서](../quality/full-system-audit-20260909.md).

기획 미정14행만 제외하면 **87.5% = 136.5/156**입니다. 상세 정책 선택 대기인 파우치2·심층3·혈전1까지 범위에서 제외한 참고값은 **98.9% = 136.5/138**이나, 이 제외는 구현 완료 승격이 아닙니다. 46행의 부분1(양 플랫폼 일반10분 수락)이 남으며, 별도 훈련 라이브 수치 불일치까지 재현되어 제품100%를 선언할 수 없습니다.

신규40스킬/고정 패시브/초기 선택, 무기8종·방어구14종/3세트, 도시 구역·현재 공간 공개를 노션 외 구현10묶음에 현행화했습니다. 이 묶음과 위키 도구를66행 분자에 가산하지 않습니다. QA-LIVE-TRAINING의 피해32/쿨타임8 대 작전 라이브123/3 불일치는9/10 공통 스냅샷으로 수정·자동 회귀했습니다. [후속 근거](../quality/full-system-audit-20260909.md#followup-20260910). 노션 재조회·점수 재계산이나 일반10분 수락은 아니며, 아래 날짜별 과거 수치는 당시 이력입니다.

## 2026-09-09 · 바닥 렌더러 대체 승인 · 80.3% {#day-close}

오너가 **“현재 사용하지 않는 타일맵 레이어도 근거가 변경된 이유를 적고 완료 처리”**를 지시했습니다. DEC-N26-TECH는 **승인된 대체 구현 완료**입니다. Notion 원문은 TileMapLayer를 지정한 채 보존하며 실제 코드는 `DungeonFloorLayer extends Node2D`의 청크 텍스처입니다. 원문의 체크박스나 기술명을 임의 수정하지 않습니다.

**변경 이유:** TileMapLayer의 대량 셀 첫 GPU 업로드가 첫 화면 지연에 집중됐습니다. 128×128 셀 단위 텍스처로 바꿔 동일 PC·각3회 중앙값 중형197→23ms, 대형304→27ms로 줄였습니다. 셀/좌표 공개 계약은 유지하고 충돌·길찾기·안개는 별도 모듈입니다. CPU 조립 시간 개선이나 모든 GPU 인증을 뜻하지 않습니다. [측정 조건](../performance/minimum-requirements.md#first-frame-20260908).

공개 GDD62블록·트래커66행을 오늘 다시 읽었으며 두 해시는 아래 원본과 동일합니다. 기준 코드 `353aa72`. **구현45·부분1·미구현6·충돌0·미정14**, `(45×3 + 1×0.5×3) / (52×3 + 14×1) = 136.5/170 = 80.3%`. 확정 요구만의 참고값은 **87.5% (136.5/156)**입니다. 어제의 정정을 취소한 것이 아니라 오늘의 명시적 대체 승인으로 1행을 승격했습니다.

남은 부분1행은 **배포 Web/독립 Windows 각각10분 일반 입력·간헐 진입/탈출 검수**이며 [배정 순서](current-milestone-workline.md#next-20260909)대로 착수합니다. 파우치·심층·혈전 정책은 이번 기술 승인에 포함하지 않습니다. 진행률은 출시율이나 재미 수락률이 아닙니다.

## 2026-09-08 최종 마감 이력 · 79.4% {#day-close-20260908}

**대표 진행률은 79.4%입니다.** 공개 원본 GDD v128·62블록과 트래커 66행을 2026-09-08(KST) 마감 시 라이브 확인했습니다. 두 해시는 기존과 같습니다. 노션 상태를 바꾸지 않고 코드 `b3239a90f7d9be9fd62a806c0ab626ce28f948fb` 및 `21851a1` 이후 변경을 대조했습니다.

| 현재 판정 | 행 수 | 계산 |
|---|---:|---|
| 구현 근거 있음 | 44 | 44 × 3 |
| 부분 대응 | 2 | 2 × 0.5 × 3 |
| 신규 미구현 | 6 | 0 |
| 규칙 충돌 | 0 | 0 |
| 기획 판단 대기 | 14 | 0 |

`(44×3 + 2×0.5×3) / (52×3 + 14×1) = 135/170 = 79.4%`. **확정 요구만의 참고값은 86.5% = 135/156**입니다. 이는 코드 대응도이며 출시 준비율·재미 점수·실제 플레이 통과율이 아닙니다.

### 80.3%에서 정정한 이유

`DungeonFloorLayer`는 첫 렌더 최적화 이후 `Node2D` 청크 텍스처 방식입니다. **노션은 TileMapLayer를 지정하지만 대조표는 과거 구현 완료 상태로 남아 있었습니다.** 해당 1행을 부분 대응으로 낮춰 1.5점을 차감했습니다. 맵이 사라지거나 성능이 나빠진 것이 아니라, 기술 요구와 코드의 불일치를 숨기지 않는 정정입니다. [측정 근거](../performance/minimum-requirements.md#first-frame-20260908): 중형197→23ms·대형304→27ms. 대체 기술 수락은 DEC-N26-TECH에서 오너가 결정하며 이번에 게임 코드는 되돌리지 않습니다.

부분 2행은 **지정 바닥 기술**과 **배포 양 플랫폼 10분 일반 플레이·간헐 탈출/진입 실패 검수**입니다. 미구현 6행은 **파우치 2·심층 3·혈전 1**이며 일반 창고·추격 보스·금고 단말·AP 비용을 대체 구현으로 세지 않았습니다. 미정 14행은 자동 확정하지 않았습니다.

### 오늘 완료한 범위와 내일 시작점

오늘의 첫 렌더 개선, 키트 전용 HP, 공간 공개·시설 맵, 게임 UI/전투 FX, 효과 명세 툴킷, 장착·거리 DPS 및 단일 대상 성장 그래프를 일별 업데이트에 보존했습니다. 위키 도구·노션 외 세부 기능은 66행 점수에 중복 가산하지 않습니다. PR191의 게임 계약·E2E·위키 빌드와 main 실행34234262244의 Cloudflare/다운로드 검증이 통과했습니다. **이번 마감 검토에서 새 10분 플레이나 재미 수락을 수행한 것은 아닙니다.**

내일 첫 작업은 [2026-09-09 실행 순서](current-milestone-workline.md#next-20260909)의 N26-08B입니다. 그 뒤 **기술/소유권 정책 결정 → 파우치 → 사망 보존·정산 → 심층 3경로 → 혈전** 순서로 진행합니다. 이는 의존성 순서이며 모두 내일 완료한다는 일정 약속은 아닙니다. 승인 공백이 있으면 독립 QA·재현·정책 제안까지 진행하고 저장/보상/HP 규칙을 임의로 정하지 않습니다.

**별도 수치 검토:** 전술 방탄복 4단계 방어 보정 누락은 성장 그래프에서 확인한 밸런스 안건입니다. 정상 하락인지 누락인지 오너 판단 전 임의 보정하지 않으며 66행 신규 미구현 수에는 포함하지 않습니다.

### 근거 원본

- [최신 Master GDD](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed) · SHA-256 `5702a448dd07e5a463c4c50742975fff0e3954230c9fb6c243ad0a0ca00f2648`.
- [전체 기능 트래커](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2) · 66행 완전 조회 · SHA-256 `b1eb9834f8677be6f76d20dea45be8773a76f2a16839f2ed33275e19d623e39c`.
- `docs/assets/notion-code-audit.json`: 행별 코드·기존 검사·판정. 연결 Notion 앱 404 후 공개 원문 수집기로 라이브 일치 확인. 원문 저장 시각과 이번 재확인 시각은 구분합니다.

<details markdown="1">
<summary>이전 대조·승인 이력 — 아래 78.5%·80.3%는 당시 값이며 현행이 아닙니다</summary>

## 2026-09-08 · HP 충돌 승인 반영 {#health-20260908}

오너가 **“부분대응 시작, 충돌은 노션에 맞추고”**로 승인했습니다. 코드 `21851a1`에서 표준 HP를 소모품 전용 정책으로 변경하고 지참 KIT 버튼을 연결했습니다. 자연·드랍·레벨업·버프 회복을 차단하며 AP는 유지합니다. [원인별 허용표·사용법](../features/health-recovery.md).

현재 코드 대응도는 **80.3% = 136.5/170**입니다. 구현45·부분1·미구현6·충돌0·미정14. 확정 요구만의 참고값은 **87.5% = 136.5/156**입니다. HP 한 행만 승격했으며 Notion 트래커 상태는 변경하지 않았습니다. 노션 외 추가 구현은 중복 가산하지 않습니다.

`N26-08B` 부분 대응을 재개했습니다. 키트 게이트·소/중/대 실제 조립/버튼·스모크·플레이 E2E 통과. CPU 조립 단회 소404/중252/대548ms는 헤드리스이며 첫 GPU 프레임 개선의 증거가 아닙니다. 탈출 F의 물리 입력·경계·일시정지/복귀 계약은 통과했지만 간헐 실패 원인 확정, 배포 Web/Windows 각각10분 일반 플레이 수락은 미완료입니다. 아래 9월7일 마감과 수치 설명은 이전 이력이며 현재 판정은 이 단락과 자동 생성 66행 표를 우선합니다.

## 2026-09-07 이전 마감 이력 {#day-close-20260907}

**기획 대비 코드 대응도 78.5% 유지 · 확정 요구만 85.6%.** 노션 조사 과정에서 최신 GDD62블록과 전체 트래커66행을 공개 읽기로 재수집했습니다. 연결된 Notion 도구에는 해당 문서 접근권이 없어 저장소의 공개 원문 수집기를 사용했고, GDD/트래커 해시가 기존과 같은 것을 확인했습니다. 이전 주소의 문서 제목은 `[백업본] Master GDD`이므로 v153 백업으로 진행률을 되돌리지 않았습니다.

| 마감 판단 | 근거 |
|---|---|
| 기준 코드 | 배포된 `48c12bf1045b990fc11345b280ac4f2fb01d2390`; 이전 `cd25dfe` 이후 변경과 66행 대조 |
| 대표 진행률 | `(44×3 + 1×0.5×3) / (52×3 + 14×1) = 133.5/170 = 78.5%` |
| 오늘 추가 구현 | 파츠 카드·무기/방어구/캐릭터 모듈 UI·슬롯 소켓은 EXT-CUSTOMIZATION 근거 갱신. 새 노션 완료 행이 아니므로 비가산 |
| 품질 근거 | PR173 전체 게임/플레이 E2E·새 모듈 계약, main 실행34122699735의 Web/Windows/위키·다운로드 체크섬 검증 통과 |
| 미완료 범위 | 부분1(첫 출격/배포 양쪽10분 일반 플레이 수락), 미구현6(파우치2·심층3·혈전1), 충돌1(HP 회복), 미정14 |

부분 항목의 60FPS/첫 프레임·사람 플레이 수락은 모듈 UI 테스트나 다운로드 성공으로 대체하지 않습니다. 이번 마감에서는 게임 규칙·기획 상태를 변경하거나 새 플레이 세션을 수행하지 않았습니다. 다음 작업은 기존 N26-08B 품질 검증이며, 판단 대기 게임 규칙은 오늘 착수하지 않습니다.

원본: [최신 Master GDD](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed) · [전체 기능 트래커](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2). 수집 시각과 원문 해시는 아래 스냅샷에 보존합니다. 출시 준비율·사람 재미 점수와 구분한 마감 보고입니다.

## 최신 원본과 판정 범위

- [최신 Master GDD](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed): v128, 본문 62블록. 2026-09-06 18:09:49 KST 편집, 2026-09-07 재수집.
- [기능 구현·상태 트래커](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2): 66행 전체 수집, hasMore=false. 결정(미구현) 52 / 미정(검토필요) 14.
- 스냅샷: `docs/assets/notion-source-snapshot.json`, `docs/assets/notion-tracker-snapshot.json`. 수동 판단표: `docs/assets/notion-code-audit.json`.
- 재대조 코드 기준: `a41f424`(2026-09-09 전체 검사). 최신 스킬/장비/공간 확장과 전체 자동 회귀를 반영했습니다. 66항목 사람 플레이 완료 선언은 아닙니다.
- 이전 2026-09-02 GDD v153은 백업본입니다. **이전 96%를 최신 진행률로 사용하지 않습니다.** 완료 이력은 Git과 일별 업데이트에 보존합니다.
- GDD 본문과 트래커는 독립 해시로 관리하며 상위 페이지 수정은 본문 변경으로 세지 않습니다. 체크박스·미구현 태그는 실제 코드 부재나 오너 승인을 대신하지 않습니다.

**이번 라이브 확인에서 GDD·트래커 내용 변경은 없었습니다.** GDD `5702a448dd07…`, 트래커 `b1eb9834f867…`가 동일합니다. 저장된 스냅샷 시각과 이번20:12 KST 재확인을 구분합니다. 확정도 가중 코드 대응도는 **136.5/170 = 80.3%**입니다. 청크 렌더러는 승인된 TileMapLayer 대체이며 원문 기술명이나 노션 상태를 고치지 않습니다. 임시 수치 역시 최종 기획 확정이 아닙니다.

## 세 가지 질문으로 읽기 {#current-classification}

| 질문 | 현재 구분 | 의미와 다음 행동 |
|---|---|---|
| 노션에 있고 구현됐나? | 구현 근거45행 | HP 키트 전용과 승인된 청크 렌더러 대체 포함. 임시 정책·실행 검사·사람 수락을 분리 |
| 노션에 있지만 덜 됐거나 없나? | 부분1 / 신규 미구현6 / 충돌0 / 미정14행 | 일반 플레이와 선행 정책 대기. 별도 품질 오류는 전체 감사에 등록 |
| 노션에 없지만 구현됐나? | [세부 규격 미명시10개 기능 묶음](#implemented-outside-notion) | 초기 선택/40스킬·장비 세트·도시/공간 공개까지 현행화. 66행 진행률에 가산하지 않음 |

트래커의 **결정(미구현)52행**은 현재 코드가 모두 없다는 뜻이 아닙니다. 코드 판정은 `45 + 1 + 6 = 52`, 미정14행은 별도입니다. 확정 요구만 보면 `136.5/156 = 87.5%`, 미정 포함 **80.3%**입니다. 어느 쪽도 출시 준비율이나 재미 평가 점수가 아닙니다.

### 기존 부분 대응 7행 · 6행 구현, 1행 검수 잔여

2026-09-07의 **부분 구현 전체 마무리 요청**은 아래 일곱 항목을 대상으로 접수했습니다. 홈·종합·주제 문서 탐색 개편과 게임 기능 구현은 별도 산출물입니다. 문서 개편만으로 이 일곱 행의 판정을 승격하지 않습니다.

| 항목 | 구현된 경계 | 아직 남은 경계 |
|---|---|---|
| 훈련 자유 세팅 | **임시 정책 구현·검증**: 현재 보유 룬만 무료 시험, 귀속·가방/AP/효과 원복 | 영구 룬 목록은 신규 생성하지 않음. 사람 수락·최종 밸런스 별도 |
| 손상 매물 | 성능0.7~0.9·표준 단가20~30% 견적 검증, Sheet/CSV 6C·23C | 임시 개별 가격의 최종 밸런스 수락 |
| 룬/코어 소켓 | **임시 정책 구현·검증**: 대상별 효과·교체·가방 반환·재장착·환전 | 무기 슬롯/정의 ID 귀속. 인스턴스 귀속·대상 선택 UI는 후속 확장 |
| AP 사이클 | **임시 정책 구현·검증**: 1초 미사용 후 초당10, 드랍/충전 독립 | 수치 최종 확정·사람 생존 난이도 수락 별도 |
| TileMapLayer | 실제 바닥 타일 레이어·좌표/초기화 계약·기존 병합 충돌 유지 | 새 아트 타일 확장은 별도 |
| Area2D 구조 | 탈출 Area2D + 공통 타겟 후보 Area2D, 초기 감지 지연 보완 | 배포판 실제 플레이 회귀 |
| 기본 씬 60FPS | 소스 렌더링 중·대형 각 600초, 평균 약 59.9FPS 근거 | 첫 출격 순간 지연·배포 Web/Windows 일반 플레이 동등성. 현재 PC 자동 검사만으로 보장하지 않음 |

#### 마무리 순서와 승인 경계

1. **2026-09-07 오너 승인 임시 정책 구현:** AP 마지막 소모 후 1초·초당10, 기존 드랍/충전 유지, 총 슬롯 유지·대상별 효과·해제 가방 반환·탈출 환전, 현재 보유 훈련·종료 원복. `PROVISIONAL_POLICY_OK`와 전체 게임/플레이 회귀를 통과했습니다. 최종 기획 수치와 구분합니다.
2. 손상 매물의 성능·가격 범위를 실제 운영 목록과 대조하고 견적/지급/장착/저장 회귀를 수행합니다. 데이터가 바뀌면 Sheet·확정 CSV·Web payload를 함께 갱신합니다.
3. TileMapLayer 렌더링/벽 충돌과 Area2D 후보 수집은 독립 어댑터로 이행하고 기존 맵·자동 타게팅 공개 계약을 유지합니다. 기존 구현을 삭제한 뒤 다른 기능이 깨지는 방식으로 전환하지 않습니다.
4. AP·소켓·훈련의 정책 Resource와 공개 어댑터를 유지하며 이후 변경 때 중복 효과·소유권·정산 회귀를 재실행합니다. 새 목록이 없어서 Sheet는 확장하지 않았습니다.
5. 소·중·대 진입 조합, 첫 프레임, 배포 Web/Windows 실제 세션을 확인한 뒤에만 각 항목의 코드 대응 판정을 갱신합니다. 사람 플레이 수락은 자동 검사와 별도로 기록합니다.

신규 미구현 6행·HP 회복 충돌 1행·기획 미정 14행은 이번 ‘부분 구현 7행’에 섞지 않습니다. 손상 매물의 범위 외 세부 값, 룬 보유와 탈출 자동 환전의 충돌 등 추가 선택이 드러나면 오너에게 확인합니다.

### 신규 미구현 6행 · 기존 기능으로 대체 불가

- **파우치 2행:** 기본 안전 수납·사망 100% 보존, 거점 슬롯 확장. 일반 창고/가방 저장은 파우치가 아닙니다.
- **심층 3행:** 저항 장비 정규 진입, 수문장 처치 시 저항 장비 보장 드랍, 키카드 전용 최상위 금고. 기존 추격 보스·벽 금고로 충족 처리하지 않습니다.
- **혈전 1행:** HP 지불 + 타격/처치 흡혈 + 회복 키트 50% 결합 프로필. 일반 스킬/AP 비용과 별개입니다.

회복 충돌 1행과 미정 14행은 아래 원문별 표에 모두 보존합니다. HP 자연 회복·드랍·레벨업 회복을 임의로 제거하지 않았습니다.

### 검증 수준과 열린 위험

N26-03A/B, N26-08A와 선택 제거/출격 조합 회귀의 기존 통과 근거는 유효하지만 이번 대조에서 사람 플레이를 다시 수행한 것은 아닙니다. 중·대형 600초 결과는 **시험용 HP·자동 입력을 사용한 소스 검사**입니다. 최신 120초 비교에서 평균 FPS 향상은 입증되지 않았습니다. 탈출 지점 F 단발 실패는 후속 재실행에서 재현되지 않았으며 **원인 수정 완료로 표시하지 않습니다**. [성능 조건](../performance/minimum-requirements.md#frame-feedback)과 [플레이 E2E](../quality/e2e-play-session.md)를 함께 확인합니다.

### 게임 요구와 분리하는 개발 기반

Sheet 실시간 시험→확정 CSV, Windows 저장/배포, 위키 역할 로그인·검색·문서 노드, PR/백업·CI 비용 관리도 이미 구축한 개발 기반입니다. 이들은 최신 노션의 66개 게임 요구 완료 점수에 합산하지 않습니다. [밸런스 작성 가이드](../getting-started/planner-item-balance-tutorial.md), [개발자 작업실](../access/developer.md)에서 각각 관리합니다. 새 게임 목록이 필요 없는 이번 대조에서는 Sheet·CSV를 변경하지 않았습니다.

## 충돌 판단과 오너 결정 {#owner-conflicts}

| ID | 충돌·공백 | 개발 검토 결론 / 권장안 | 확정할 부분 |
|---|---|---|---|
| DEC-N26-HEALTH | 키트만 회복 vs 자연 회복·HP 드랍·레벨업 회복 | 원인별 회복 게이트와 표준 생존 프로필로 분리. 승인 전 현행 유지 | 자연 회복·드랍·레벨업·버프·거점/훈련 허용표. 이전 사용자 레벨업 회복 복구 지시 대체 범위 |
| DEC-N26-AP | AP 자연 회복·드랍·충전 공존 | **임시 승인·구현**: 1초 지연·초당10·최대치 제한, 충전 독립 | 최종 수치·생존 난이도 수락 |
| DEC-N26-POUCH | 사망 전부 소실 vs 파우치 보존, 룬 자동 환전 vs 원형 보존 | 별도 컨테이너 소유권·정산 예외, 중복 소유 금지 | 허용 종류/크기, 1~2·3~4칸 정확한 값, 입출금·중단·재접속, 해금/환전 우선순위 |
| DEC-N26-DEPTH | 장비 착용자 통과 vs 오염 피해 면역 | 접근 자격과 환경 피해 분리. 수문장은 기존 추격 보스와 별도 역할 | 입장 차단인지 피해 면제인지, 키카드 소비·재입장, 보장 드랍 시 가방 부족 |
| DEC-N26-BLOOD | HP 비용·흡혈·키트 반감 신규 결합 | HP/AP 지불과 회복 효과 정책 조합 | 자해 사망/최소 HP, DOT·다중 타격 흡혈 상한, AP 병행/대체 조건 |
| DEC-N26-SOCKETS | 공용 총 용량·대상별 효과 | **임시 승인·구현**: 무기 슬롯/정의 및 스킬 ID 귀속, 해제 가방 반환·환전 유지 | 인스턴스 귀속·대상 선택 UI 확장 및 최종 수치 |
| DEC-N26-TECH | TileMapLayer 맵·Area2D 타게팅 지정 vs 자체 맵/거리 판정 | 탈출 구역은 실제 Area2D로 충족. 맵·타게팅의 대체 구현 수락 여부를 별도 판단 | 엔진 노드 지정이 필수인지, 대체 구현 성능 기준 |
| DEC-N26-STATUS | 구현된 이동·Q·탈출도 트래커 미구현 | 노션 요구 상태와 코드 검증 상태를 분리, 진행률 0% 초기화 금지 | 오너 근거 수락 후 기획자가 트래커 갱신 |

AP·소켓/보유 훈련은 오너의 **임시 구현 승인**을 반영했습니다. 나머지는 제안/판단 대기입니다. HP 회복 삭제, 파우치 지급, 화폐 변경, 실서버 구축은 실행하지 않습니다.

## 명확한 코드 차이

1. **N26-03A/B 구현·자동 회귀 완료:** 중심점·효과 반경 전달(`d50fdb6`) 후 원형 최대 포함 각도 스윕·안전한 평균(`add3a33`)을 연결했습니다. 실제 효과 적중·240개 독립 대조·72명 성능을 검증했습니다. 사람 재미 수락·타게팅 갱신 주기·Area2D 기술 결정은 별도입니다.
2. `CombatResourceSystem.advance`는 독립 `EnergyRegenerationPolicy`로 AP를 회복하고 충전 횟수는 기존 시간 규칙으로 따로 복구합니다. 정책을 제거하면 기존 드랍 전용 AP로 돌아갑니다.
3. 기본 자연 회복은 4초 후 초당 3 HP, 최대 65% 상한입니다. HP 드랍과 `ProgressionSystem.level_up_heal_amount=12`도 별도 존재해 자연 회복만 꺼서는 ‘키트만’ 규칙이 되지 않습니다.
4. `RunSettlementService`에 성공/사망 생명 주기는 있지만 파우치 컨테이너/보존 원장은 없습니다. 일반 창고와 파우치 보호는 다릅니다.

## 작업 편성

[현행 N26 작업선](current-milestone-workline.md#notion-20260907)에서 선행 결정·모듈·플레이어 수락 기준을 확인합니다. 기존 P7/P8 이력을 보존하고 P9/P10 착수 판단 전에 생존·파우치·심층과 기존 기능 차이를 정렬합니다. N26은 Notion 공식 Phase가 아닌 내부 변경 묶음입니다.

새 목록이 필요한 **실제 구현 단계**에서 Google Sheet를 확장합니다. 회복/비용 프로필, 파우치 허용 목록, 저항·키카드 목록은 계획일 뿐 아직 Sheet/CSV를 변경하지 않았습니다. 1행 변수명·2행 설명·3행 데이터, 실시간 테스트→확정 CSV를 유지합니다.

## 독립 구현 후속

N26-03A/B와 N26-08A 훈련 세팅·복원은 구현·자동 회귀를 통과했습니다. **N26-08B는 진행 중**이며 다음은 첫 출격 준비/초기 렌더링 계측 → 배포판 탈출 F 재현 → Web/Windows 10분 일반 플레이 동등성입니다. 회복·소유권·수치 정책 및 14개 미정의 확정 여부는 변경하지 않았습니다. [독립 작업 순서](current-milestone-workline.md#notion-20260907)를 단일 실행선으로 사용하며 이전 P9 착수 안내는 최신 순서로 사용하지 않습니다.

## 최초 대조 작업의 검증

**현행 재대조 검증(2026-09-07):** 원문·트래커 라이브 해시 일치, 66행 전수 대응과 추가 구현의 중복 ID/안전한 근거 경로/점수 비가산 검사 포함 24개 회귀 통과. strict 위키 빌드·96문서 링크/계층·역할/검색·가독성 계약 통과. 본문·기획자/개발자 작업실·오너 콘솔의 오래된 다음 작업을 N26-08B로 맞췄으며, 현재 결과는 코드 대응 판정입니다. 노션 쓰기·게임 규칙 변경·새 사람 플레이 수락은 하지 않았습니다.

2026-09-07: 원본·트래커 라이브 해시 일치, 수집 범위·페이지 나눔·미정 판독·66행 대응 회귀 22개 통과. 위키 strict 빌드, 96문서 링크·계층 검사, 역할 권한 테스트와 신규 스냅샷 비로그인 차단 검사를 통과했습니다. 오너 콘솔의 8결정·8작업 선행 관계도 검증했습니다. 게임 실행 코드는 변경하지 않았으며 신규 요구의 플레이 E2E는 N26-08에 남깁니다.

</details>

<!-- notion-audit:start -->

## 66개 항목 코드 대조

정적 코드·기존 테스트 소스 대조: **136.5/170 = 80.3%**. 출시 준비율이나 이번 턴의 실제 플레이 통과율이 아닙니다.

구현 근거 있음 45 / 부분 대응 1 / 규칙 충돌 0 / 신규 미구현 6 / 기획 판단 대기 14

확정 요구 ×3, 미정 ×1. 구현 근거 1점, 부분 0.5점, 충돌·신규 미구현·판단 대기 0점. 테스트 파일은 검증해야 할 기존 근거이며, 파일 존재만으로 최신 요구 전체의 E2E 통과를 선언하지 않습니다.

<details markdown="1"><summary>DATA-01-LOOT · 7개 항목</summary>

### [룬 1개당 골드 환전 가치 산정 공식 및 배율](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040818698d7e0ee28c35434)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 룬 티어별 환전 기본 골드(예: 100/300/1000G) 확정 필요

수락 기준: 룬 티어별 환전 기본 골드(예: 100/300/1000G) 확정 필요

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [사망 실패 시 런 획득물 및 지참 로드아웃 소실](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081f19fd2cad6784a8d28)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

성공 시 환전·영구 등록·창고 / 사망 시 소실을 생명 주기별 처리. 보안 파우치 예외는 없음.

수락 기준: 던전 내 사망 시 인벤토리 및 장착 템 증발

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [세션 증폭 룬/코어 인게임 실시간 소켓 장착](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040812e8dcfd3df7845372a)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-01**

오너 승인 임시 정책(2026-09-07): 총 용량 유지, 현재 무기 슬롯/정의 ID·개별 스킬 ID 귀속, 해제 가방 반환·재장착·탈출 환전. Q 누출·스킬별 효과·가방 부족 원자성·편집 취소 회귀 통과. 물리 인스턴스 귀속/대상 선택 UI는 후속 확장, 기본 UI는 현재 무기/첫 스킬.

수락 기준: 획득한 룬을 장비/스킬 소켓에 꽂아 세션 내 화력 폭발

코드 경계: `game/features/session_sockets/session_socket_service.gd`

기존 검사 근거: `game/tests/provisional_policy_contract_test.gd`, `game/tests/basic_loop_smoke_test.gd`

### [세션 증폭 룬/코어 탈출 시 대량 골드 자동 환전](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040815ab0aeef36ba2b2e92)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

성공 시 환전·영구 등록·창고 / 사망 시 소실을 생명 주기별 처리. 보안 파우치 예외는 없음.

수락 기준: 탈출 결과창에서 룬이 골드로 일괄 정산 환전

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [영구 자산형 장비 R키 현장 즉시 장착/스왑](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040810999edd6fb80fbe7f5)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

현장 장비 교체 경로가 있음. 인벤토리 R 회전과 컨텍스트 분리 회귀를 유지.

수락 기준: 장비 비교창에서 R키 누르면 현장에서 즉시 장착

코드 경계: `game/features/field_loot/field_loot_equip_service.gd`

기존 검사 근거: `game/tests/field_loot_acquisition_contract_test.gd`

### [영구 자산형 장비 탈출 성공 시 로비 상점 영구 해금](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040812281c4e91a314d0451)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

성공 시 환전·영구 등록·창고 / 사망 시 소실을 생명 주기별 처리. 보안 파우치 예외는 없음.

수락 기준: 탈출 성공 시 획득 아이템이 로비 상점에 영구 등록

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [영구 자산형 장비(무기/스킬/도면) F키 가방 획득](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081cdbb32c02a13bc9624)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

현장 획득 요청과 가방 수납·실패 피드백 경로의 기존 근거.

수락 기준: 전리품 근처에서 F키 누르면 가방으로 습득

코드 경계: `game/features/field_loot/field_loot_inventory_service.gd`

기존 검사 근거: `game/tests/field_loot_acquisition_contract_test.gd`

</details>

<details markdown="1"><summary>DATA-02-POUCH · 2개 항목</summary>

### [보안 파우치 (사망 시 100% 보존되는 안전 금고 기본 1~2칸)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408180a869d144728e8907)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-04**

파우치와 확장·사망 보존 정책 미구현. 일반 가방 크기 확장만으로 대체 불가.

수락 기준: 파우치 내 설계도/유물 수납 후 사망 시 로비 창고로 안전 회수 확인

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

### [보안 파우치 거점 성장 업그레이드 (최대 3~4칸 확장)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408145bf92e84e1e0a0f01)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-04**

파우치와 확장·사망 보존 정책 미구현. 일반 가방 크기 확장만으로 대체 불가.

수락 기준: 거점 업그레이드 완료 시 파우치 슬롯이 3~4칸으로 확장되는지 확인

코드 경계: `game/features/run_settlement/run_settlement_service.gd`

기존 검사 근거: `game/tests/run_settlement_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-00-ENV · 6개 항목</summary>

### [Area2D 기반 타겟팅 및 탈출 구역 콜리전 구조 셋업](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081fa8aa8ee14acbebda3)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-01**

dda00af: 기존 탈출 Area2D에 더해 무기/스킬 후보를 TargetCandidateArea의 실제 겹침 목록으로 수집. 소유 공급자·중심 사거리·정렬은 유지. 초기/반경 변경/워프/신규 생성은 물리 갱신 전 제공자 폴백, 비물리 더미 호환, 삭제 대상 배제. 첫 공격·실제 겹침·반경 변경 및 전체 전투 E2E 통과.

수락 기준: 반경 콜리전 진입/이탈 시그널 정상 감지

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [CharacterBody2D 기반 플레이어 이동 물리 셋업](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408188aaf0cf37578f63be)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

플레이어가 CharacterBody2D이며 이동 컴포넌트와 충돌을 분리.

수락 기준: 충돌체를 가진 캐릭터가 2D 평면에서 정상 이동

코드 경계: `game/features/player/player.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [Custom Resource 기반 데이터 관리 아키텍처 셋업](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040817bbd84efe3ea8a93e7)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

기존 Godot 프로젝트·선택 모듈과 기본 루프 검사 근거. 지정 기술/성능의 완전 일치는 별도 확인.

수락 기준: 무기/스킬/룬 데이터가 리소스 파일로 관리 및 로딩

코드 경계: `game/core/feature_manifest.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [Godot 4.x 2D 탑다운 엔진 기본 프로젝트 및 씬 구축](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081fd8f66dbb618b30881)

노션: **결정 (미구현)** · 코드: **부분 대응** · 작업: **N26-08**

2026-09-09 a41f424: 전체 게임·E2E·40스킬/24초기조합 회귀 재실행 통과. 청크 렌더러 대체 승인은 유지합니다. 그러나 배포 Web/독립 Windows 각각10분 일반 플레이와 간헐 탈출F 수락이 남아 partial 유지. 신규 훈련 라이브 동등성 오류는 별도 QA-LIVE-TRAINING으로 재현·등록했으며 자동 통과를 제품 수락으로 해석하지 않습니다.

수락 기준: 2D 뷰포트에서 기본 씬이 60FPS로 구동 확인

코드 경계: `project.godot`

기존 검사 근거: `game/tests/performance_budget_test.gd`, `game/tests/rendered_soak_test.gd`, `game/tests/frame_feedback_contract_test.gd`, `game/tests/release_boot_contract_test.gd`

### [TileMapLayer 기반 2D 던전 맵 렌더링 파이프라인](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040813893c2fc6eddfae751)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-01**

2026-09-09 오너 대체 승인: '현재 사용하지 않는 타일맵 레이어도 근거가 변경된 이유를 적고 완료 처리'. 첫 GPU 업로드 지연을 줄이기 위해 TileMapLayer 대신 Node2D ChunkedCellTexture를 사용합니다. 동일 PC 각3회 첫 프레임 중앙값 중형197→23ms·대형304→27ms. 좌표/사용 셀 계약, 충돌·길찾기 분리를 유지하며 floor_render_contract_test가 검증합니다. 지정 노드의 실제 사용이 아닌 승인된 대체 구현 완료이며 Notion 원문/상태는 보존합니다. 양 플랫폼 일반10분 QA는 별도 부분 행에 남깁니다.

수락 기준: 타일맵 레이어로 벽/바닥 충돌 및 렌더링 확인

코드 경계: `game/features/map_generation/map_generator.gd`, `game/features/map_generation/dungeon_floor_layer.gd`

기존 검사 근거: `game/tests/floor_render_contract_test.gd`, `game/tests/basic_loop_smoke_test.gd`

### [타일셋 그래픽 스타일 및 픽셀 뷰포트 해상도 규격](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408128b071df1c2bf344ce)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 해상도(예: 640x360 픽셀아트 vs 1920x1080) 확정 필요

수락 기준: 해상도(예: 640x360 픽셀아트 vs 1920x1080) 확정 필요

코드 경계: `game/core/feature_manifest.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

</details>

<details markdown="1"><summary>PLAN-01-CTRL · 10개 항목</summary>

### [F 키 입력 시 맵 내 오브젝트 상호작용](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040816bb578f9cc78ce74a2)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

물리 Action·스킬 배치·쿨타임·상호작용 구현 근거. 실제 키는 K 설정 값을 사용.

수락 기준: 상자/신호기 근처에서 F키 누를 때 상호작용 트리거

코드 경계: `game/features/skill_binding/skill_binding_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [Q 키 입력 시 주무기 ↔ 보조무기 실시간 스왑](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408183a83eff9dc784a5ef)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

주·보조 무기 전환과 태그 적합성 갱신의 기존 구현 근거.

수락 기준: 무기 교체 시 들고 있는 스프라이트/태그 즉각 변경

코드 경계: `game/features/equipment/equipment_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [Space 키 입력 시 이동 방향 회피(대쉬) 발동](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040817ca4e2f02aff23ace5)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

Input.get_vector 및 현재 dash Action 기반 가속·대시. 실제 기본 키/재매핑은 KeyMapping과 연동.

수락 기준: 대쉬 시 순간 가속 및 회피 동작 수행

코드 경계: `game/features/player/player_movement.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [WASD 키보드 8방향/360도 평면 이동 벡터 제어](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081ef93aced46ee9dcd7e)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

Input.get_vector 및 현재 dash Action 기반 가속·대시. 실제 기본 키/재매핑은 KeyMapping과 연동.

수락 기준: 조준점 무관하게 입력 방향으로 즉각 이동 확인

코드 경계: `game/features/player/player_movement.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [공용 자원(AP/스태미나) 소모 및 회복 사이클](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081f9b4ebcbb242aa37ab)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-02**

오너 승인 임시 정책(2026-09-07): 마지막 AP 소모 후 1초부터 초당10 자연 회복, 최대치 제한, 드랍·충전은 독립 유지. 프레임 분할 동등성·정책 교체/제거·대기 시간 원복·비정상 값 거부 계약 통과. HP 정책 및 기획 최종 수치는 별도.

수락 기준: 스킬 사용 시 AP 차감, 미사용 시 초당 자연 회복

코드 경계: `game/features/combat_resources/combat_resource_system.gd`

기존 검사 근거: `game/tests/provisional_policy_contract_test.gd`, `game/tests/basic_loop_smoke_test.gd`

### [기본 AP 최대치 및 초당 자연 회복량 기본 수치](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081c69ad2d96b2d2305c1)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 기본 AP(예: 100) 및 초당 회복량(예: 20) 확정 필요

수락 기준: 기본 AP(예: 100) 및 초당 회복량(예: 20) 확정 필요

코드 경계: `game/features/skill_binding/skill_binding_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [마우스 좌클릭 등 기본 스킬 홀드(Hold) 연속 시전](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081e589a4dca71f46ec3f)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

기본 공격 홀드 연사 경로 구현. 모든 액티브 스킬의 자동 반복을 확정한 것으로 확대하지 않음.

수락 기준: 버튼 누르고 있을 때 공속/쿨타임 주기로 자동 연사

코드 경계: `game/features/weapons/auto_weapon.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [스킬별 개별 쿨타임(Cooldown) 카운트다운](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408102b0c9db415bca981e)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

스킬별 쿨타임과 자원 가드 존재.

수락 기준: 스킬 사용 후 쿨타임 완료 전까지 재사용 불가

코드 경계: `game/features/combat_skills/combat_skill_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [완전 자유 스킬 바인딩 (Any Skill to Any Key)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408127b2fee3b3ce1920c1)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

스킬→Action 매핑과 물리 키→Action 매핑은 별도 서비스. 충돌 교환·저장 계약 유지.

수락 기준: 인풋 슬롯(좌/우클릭, Space, 1~9)에 임의 스킬 1:1 자유 매핑

코드 경계: `game/features/skill_binding/skill_binding_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [인게임 최대 동시 장착 스킬 슬롯 수 확정](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040816daecbdc8652d0d8de)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. UI 상 4개, 5개, 6개 중 최종 규격 확정 필요

수락 기준: UI 상 4개, 5개, 6개 중 최종 규격 확정 필요

코드 경계: `game/features/skill_binding/skill_binding_service.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

</details>

<details markdown="1"><summary>PLAN-02-TARGET · 6개 항목</summary>

### [광역기 클러스터 탐색 반경 기본값 수치](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081768debc7f5a868a5ff)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 클러스터링 밀집도 판정 반경(px) 확정 필요

수락 기준: 클러스터링 밀집도 판정 반경(px) 확정 필요

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [광역기: 스킬 반경 내 최대 적 밀집 클러스터 중심점 자동 투하](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408147a809d56ce5ef98cc)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

N26-03A/B(d50fdb6, add3a33): 중심 보존·효과 반경/배율 전달, 원형 최대 포함 각도 스윕과 안전한 평균, 사거리·대표 적·기존 정책 호환. 240개 독립 교차점 대조, 36개 회전 배치, 실제 효과 2명/5명 적중·72명 요청 성능·입력 E2E 통과. 사거리 안 적 중심 기준 구현 근거이며 신규 기본 스킬/사람 재미 수락/Area2D 방식 결정은 아님.

수락 기준: 몹이 가장 뭉쳐 있는 위치의 중심 좌표에 스킬 투하

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`, `game/features/smart_targeting/circular_coverage_solver.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`, `game/tests/smart_targeting_center_contract_test.gd`, `game/tests/circular_coverage_contract_test.gd`

### [단일기: 사거리 내 최단거리(Closest) 적 기본 록온](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081dca9bcd63057e33c1b)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

대상 선택 정책의 nearest/highest_health/elite/direction 분기와 기존 검사 근거.

수락 기준: 플레이어와 가장 가까운 적을 우선 추적 발사

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [단일기: 특정 옵션 시 최고체력/엘리트(Highest HP) 동적 전환](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040813c8525fceeaed2654f)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

대상 선택 정책의 nearest/highest_health/elite/direction 분기와 기존 검사 근거.

수락 기준: 옵션 활성화 시 사거리 내 최고 HP 적으로 타겟 변경

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [이동기: 현재 입력된 이동 방향 벡터로 즉시 발동](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081a9b8c9f6677ca3970c)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

대상 선택 정책의 nearest/highest_health/elite/direction 분기와 기존 검사 근거.

수락 기준: 이동 방향 벡터로 즉시 대쉬/돌진 발동

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [타겟 록온 갱신 주기 (초당 30회 vs 60회)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081008288f8c33727429f)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 성능 및 타겟 전환 반응속도 튜닝 필요

수락 기준: 성능 및 타겟 전환 반응속도 튜닝 필요

코드 경계: `game/features/smart_targeting/smart_targeting_policy.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

</details>

<details markdown="1"><summary>PLAN-03-FLOW · 5개 항목</summary>

### [1단계 로비 허브 상시 공간 인터페이스 구축](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408169834bc9955f1af304)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

거점→준비→확정 투입→정산 복귀 연결과 조합별 기존 계약 검사. 새로운 UI 정책 수락은 별도.

수락 기준: 창고, 상점, 제작소, 연습장, 도감, 랭킹 모듈 접근 가능

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [2단계 출격 준비 세션 (로드아웃 + 맵 계약 + 페널티)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081e6b05ff5697a9bfd26)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

거점→준비→확정 투입→정산 복귀 연결과 조합별 기존 계약 검사. 새로운 UI 정책 수락은 별도.

수락 기준: 출격 클릭 시 작전 브리핑 세션 진입 및 총비용 차감

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [3단계 인게임 던전 세션 로딩 및 결과 복귀](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040818d8fa2cedb610d6633)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

거점→준비→확정 투입→정산 복귀 연결과 조합별 기존 계약 검사. 새로운 UI 정책 수락은 별도.

수락 기준: 계약 완료 시 던전 로딩, 탈출/사망 시 로비 복귀

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [인게임 진입/복귀 시 씬 전환 로딩 연출](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d4a174d2cb05748c11)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 페이드 인/아웃 또는 암전 연출 규격

수락 기준: 페이드 인/아웃 또는 암전 연출 규격

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [출격 준비 세션 UI 상세 레이아웃 및 UX](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040818883aecd19e9ee4a43)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 단일 화면 모달 vs 탭 분할 화면 UI 확정 필요

수락 기준: 단일 화면 모달 vs 탭 분할 화면 UI 확정 필요

코드 경계: `game/scenes/game.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-04-SHOP · 8개 항목</summary>

### [상점 리롤 1회당 비용 증가 곡선 (점진 증가 vs 고정)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408128baafd108e1f9602f)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 리롤 비용(예: 100G ➔ 200G ➔ 400G 등) 확정 필요

수락 기준: 리롤 비용(예: 100G ➔ 200G ➔ 400G 등) 확정 필요

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [상점: 골드 소모 수동 리롤(Reroll) 기능](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d8bd12f016a1a7a63e)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

회전 상점·리롤·품질 매물 경로 구현. 운영 수치는 임시이며 확정 승인과 구분.

수락 기준: 리롤 버튼 클릭 시 골드 차감 후 매물 즉시 갱신

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [상점: 기본 순정품 및 고성능 꿀매물 무작위 스폰](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081a2bd08e8bcb4537422)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

회전 상점·리롤·품질 매물 경로 구현. 운영 수치는 임시이며 확정 승인과 구분.

수락 기준: 표준품 및 추가옵션 꿀매물이 무작위 확률로 등장

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [상점: 성능 -10%~-30% 손상된 하자품 헐값(20~30%) 판매](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040811db001d577cf80a660)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-01**

dda00af: 품질 Resource의 성능0.7~0.9·표준 단가 비율0.2~0.3을 견적/구매에 강제. 표준 누락·모호한 단가·범위 밖 구매를 무차감 거부. Sheet ShopOffer G3=6/G6=23과 CSV/payload 일치, 표준 단가 대비26.67%/25.56%. 경계값·실물 지급·장착 계약 통과. 임시 개별 운영값은 최종 밸런스 수락과 구분.

수락 기준: 초특가 손상 장비가 상점 매물로 스폰

코드 경계: `game/features/p5_hub_progression/shop_quote_policy.gd`

기존 검사 근거: `game/tests/shop_quality_inventory_contract_test.gd`, `game/tests/partial_completion_contract_test.gd`

### [상점: 인게임 세션 복귀 시 자동 품목 갱신(로테이션)](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040810fb02cfd14fa4b714c)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

회전 상점·리롤·품질 매물 경로 구현. 운영 수치는 임시이며 확정 승인과 구분.

수락 기준: 런을 다녀올 때마다 상점 매물 자동 새로고침

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [손상 장비에 붙는 세부 페널티 목록 풀](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081e4bfade202866c131b)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 공격력 저하, 공속 저하, AP 소모 증가 등 풀 확정 필요

수락 기준: 공격력 저하, 공속 저하, AP 소모 증가 등 풀 확정 필요

코드 경계: `game/features/p5_hub_progression/rotating_shop_service.gd`

기존 검사 근거: `game/tests/shop_browser_contract_test.gd`

### [제작소: 추가 재화 소모를 통한 추가 옵션/소켓 고점 부여](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040810f83b7fb7f6ebb80a9)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

비용·재료·옵션/소켓·실물·거래 ID 원자 적용. 옵션 범위 임시 승인은 별도.

수락 기준: 제작 시 랜덤 추가 옵션/소켓이 붙어 빌드 고점 돌파

코드 경계: `game/features/p5_hub_progression/workshop_craft_transaction_service.gd`

기존 검사 근거: `game/tests/workshop_craft_transaction_contract_test.gd`

### [제작소: 파밍한 설계도 영구 등록 기반 확정 타겟 제작](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040814c99d0c971098fd15c)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

도면 영구 등록 기반 제작 자격과 중복 등록/재접속 보존 구현.

수락 기준: 보유 설계도로 원하는 장비 골드 소모 확정 제작

코드 경계: `game/features/p5_hub_progression/workshop_unlock_service.gd`

기존 검사 근거: `game/tests/workshop_blueprint_registry_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-05-TRAIN · 5개 항목</summary>

### [단일 고체력 보스 허수아비 더미 배치](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040811eba68f8adf646f3ac)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

단일 1기·밀집 8기 더미, 실제 공격·계측·무비용 장비 편집·퇴장 원복의 기존 E2E 근거.

수락 기준: 단일 록온 및 단일 DPS 측정 더미 피격 동작

코드 경계: `game/features/training_ground/training_ground_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

### [밀집 잡몹 허수아비 더미군 배치](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d3b102c4b1eda1ef98)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

단일 1기·밀집 8기 더미, 실제 공격·계측·무비용 장비 편집·퇴장 원복의 기존 E2E 근거.

수락 기준: 광역 클러스터링 및 연쇄 폭발 범위 타격 테스트

코드 경계: `game/features/training_ground/training_ground_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

### [보유 장비/스킬/룬 무상 자유 세팅 콘솔](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040810bb4e6fd07961bb518)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

오너 승인 임시 정책(2026-09-07): 보유 가방/장착 RunAsset만 무료 시험, 대상별 효과 적용, 종료·실패 가방/AP/소켓 원복·저장 격리. 미보유 거부·I 편집 취소·복원 계약과 전체 E2E 통과. 영구 룬 카탈로그는 새로 만들지 않으며 기획 최종 수치/사람 수락은 별도.

수락 기준: 연습장 내에서 비용 없이 자유롭게 빌드 스왑

코드 경계: `game/features/training_ground/training_loadout_service.gd`

기존 검사 근거: `game/tests/provisional_policy_contract_test.gd`, `game/tests/training_ground_gameplay_e2e_test.gd`, `game/tests/training_loadout_restore_contract_test.gd`, `game/tests/training_optional_matrix_test.gd`

### [실시간 DPS, 단일 타격 수치, AP 소모율 모니터링 UI](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408134bf81d6d748487eb2)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

타격·DPS·AP 소모율·쿨타임 계측과 HUD 연결의 기존 검사 근거.

수락 기준: 허수아비 공격 시 화면 상단/측면에 실시간 수치 표기

코드 경계: `game/features/training_ground/training_telemetry_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

### [허수아비 속성 저항 및 방어력 설정 옵션 지원](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408103a93cd48292d9f86b)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 연습장 옵션 패널에서 더미 방어력 조절 기능 여부

수락 기준: 연습장 옵션 패널에서 더미 방어력 조절 기능 여부

코드 경계: `game/features/training_ground/training_ground_service.gd`

기존 검사 근거: `game/tests/training_ground_gameplay_e2e_test.gd`

</details>

<details markdown="1"><summary>PLAN-06-EXTRACT · 7개 항목</summary>

### [구역 이탈 시 타이머 일시정지(Pause) 및 재진입 재개(Resume)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081aa8a0fd4dac4b38604)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

신호기 활성·체류 카운트다운·이탈 일시정지·재개·성공 정산 구현. 방어 시간/배율 승인 별도.

수락 기준: 원 밖으로 나가면 타이머 일시정지, 재진입 시 재개

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [기본 탈출 방어 카운트다운 시간 기본값 (15초 vs 20초)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081cab26af5ed495e7156)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 맵 크기별 탈출 방어 시간 확정 필요

수락 기준: 맵 크기별 탈출 방어 시간 확정 필요

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [맵 내 탈출 신호기(Beacon) 접근 후 F키 상호작용 가동](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081739ff3e8871dc690f7)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

신호기 F 활성·방어 카운트다운 연결의 구현 근거는 있음. 최근 E2E에서 F 진입 단발 실패 후 재실행 통과: 상세 진단을 추가했으나 원인 수정은 미완료이며 N26-08B 재현 대상으로 유지. 기능 부재와 간헐적 품질 위험을 구분하고 무결함/사람 플레이 완료로 승격하지 않음.

수락 기준: F키 입력 시 탈출 방어 시퀀스 활성화

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`, `game/tests/e2e_play_session_test.gd`

### [원형 탈출 구역(Area2D) 내 N초 생존 카운트다운](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081c6b32efda2ccb10389)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

ExtractionZone은 Area2D를 상속하고 원형 CollisionShape2D를 구성. 반경 내 방어 카운트다운·이탈 일시정지·재진입 재개·완료 신호 연결. N초 운영값 확정은 별도.

수락 기준: 구역 내 체류 시 타이머 작동 및 웨이브 스폰

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [타이머 0초 도달 시 탈출 성공 및 정산창 진입](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408106ad61d91cfe0c6f1b)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

신호기 활성·체류 카운트다운·이탈 일시정지·재개·성공 정산 구현. 방어 시간/배율 승인 별도.

수락 기준: 생환 성공 처리 및 획득물 영구 정산

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [탈출 활성화 시 몰려오는 몬스터 웨이브 스폰 배율](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081378239cf2fd6b253e8)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 일반 대비 스폰 밀도 가중치 수치

수락 기준: 일반 대비 스폰 밀도 가중치 수치

코드 경계: `game/features/extraction/extraction_zone.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### [파산 방지: 무료 기본 무장 및 기본 맵 상시 제공](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081189deee5b4e70508fb)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

BankruptcyProtectionPolicy가 잔액 조건과 entry_cost=0인 반복 무료 출격 프리셋을 제공. 기본 무장·무료 진입은 P5 계약 검사로 확인하며 탈출 타이머와 별개.

수락 기준: 잔고 0원 시 언제든 기본 무장 무료 지급 (Zero-Risk)

코드 경계: `game/features/p5_hub_progression/bankruptcy_protection_policy.gd`, `game/features/p5_hub_progression/p5_hub_progression_service.gd`

기존 검사 근거: `game/tests/p5_hub_progression_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-07-LEADER · 5개 항목</summary>

### [동일 규격(대형 맵+페널티) 내 비동기 3대 래더 집계](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081c88a80fd7b8c71b99d)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

대형/페널티 규격의 로컬 3대 보드·시즌 경로. 실제 계정/서버 검증과 로컬 기록은 별도.

수락 기준: 최다 루팅, 스피드런, 최다 킬 3대 기록 등록 (P6 로컬)

코드 경계: `game/features/conditional_ranking/conditional_ranking_system.gd`

기존 검사 근거: `game/tests/ranking_season_contract_test.gd`

### [시즌 명예 보상(칭호, 오라 이펙트) 지급](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081159b5cc24724367086)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

로컬 지급·칭호/오라 장착 구현. 실서버 보상 지급으로 간주하지 않음.

수락 기준: 상위 랭커 전용 칭호 및 캐릭터 오라 이펙트 장착

코드 경계: `game/features/conditional_ranking/season_reward_service.gd`

기존 검사 근거: `game/tests/season_reward_contract_test.gd`

### [실서비스 계정 서버 및 무결성 검증 연동](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408185ae76d5cd6a8c0355)

노션: **미정 (검토필요)** · 코드: **기획 판단 대기** · 작업: **N26-01**

기획 확정 대기. 현재 유사 기능/임시 설정이 있어도 이 항목의 최종 규격 수락을 의미하지 않음. 실서버 랭킹 API 연동 (현재 P6 로컬 마일스톤 상태)

수락 기준: 실서버 랭킹 API 연동 (현재 P6 로컬 마일스톤 상태)

코드 경계: `game/features/conditional_ranking/conditional_ranking_system.gd`

기존 검사 근거: `game/tests/ranking_season_contract_test.gd`

### [원정 맵 크기(소/중/대) 및 Biome 계약 선택](https://wobbly-pawpaw-1ff.notion.site/3d35b7280040815fb78de820fa8127de)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

규모·지역 계약 및 조합 검증 구현.

수락 기준: 맵 크기 및 지역별 드랍 테이블 선택 기능

코드 경계: `game/features/operation_contract/operation_contract_service.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [자발적 페널티 모디파이어 선택 시 보상 배율(Multiplier) 증가](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408113b892e6ce524b1f43)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-08**

원정 계약·페널티 보상 배율 견적·확정 연결.

수락 기준: 페널티 토글 시 최종 보상 배율 실시간 산출

코드 경계: `game/features/operation_contract/operation_contract_service.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

</details>

<details markdown="1"><summary>PLAN-08-SURVIVAL · 2개 항목</summary>

### [표준 자원 마모형 체력 모델 (자연회복 불가, 소모품 한정 관리)](https://wobbly-pawpaw-1ff.notion.site/3d35b72800408159819af0dc9eb951b5)

노션: **결정 (미구현)** · 코드: **구현 근거 있음** · 작업: **N26-02**

2026-09-08 오너 승인: 표준 HP 키트 전용. 자연·드랍·레벨업·버프 회복과 부상 최대치 교체 우회 차단. 지참 KIT 버튼·수량·회복 페널티 연결. 계약·소/중/대 조립/UI 검사 통과. AP·훈련 원복 독립, 배포10분 수락은 partial 유지.

수락 기준: 피격 시 체력이 영구 누적 차감되고 자연 회복되지 않는지 확인

코드 경계: `game/features/health_recovery/health_recovery_system.gd`, `game/features/player/health_recovery_policy.gd`, `game/features/p5_hub_progression/utility_investment_service.gd`, `game/features/p5_hub_progression/medkit_button.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`, `game/tests/kit_only_health_contract_test.gd`

### [혈전/버서커 특화 빌드 (HP 소모 스킬 + 흡혈 + 회복약 효과 반감)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081658cffcd45118d9084)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-07**

AP 비용 계약만 있음. HP 지불·타격/처치 흡혈·물약50%를 결합한 별도 빌드 정책은 미구현.

수락 기준: 스킬 시전 시 HP가 차감되고 타격 시 흡혈 및 물약 효과 50% 반감 확인

코드 경계: `game/features/combat_resources/combat_resource_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

</details>

<details markdown="1"><summary>PLAN-09-DEPTH · 3개 항목</summary>

### [심층 코어 우회 돌파로 (수문장 처치 시 저항 장비 100% 드랍)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081c1a28dfe60b47f8cf9)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-06**

저항 자격/오염 피해·수문장 보장 드랍·키카드 금고 정책은 미구현. 기존 추격 보스와 수문장은 별도 역할.

수락 기준: 수문장 엘리트 몹 처치 시 저항 장비 완제품 100% 현장 드랍 확인

코드 경계: `game/features/map_generation/map_generator.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [심층 코어 정규 진입로 (환경 저항 장비 착용자 통과)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081a69988e39812a2e2f6)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-06**

저항 자격/오염 피해·수문장 보장 드랍·키카드 금고 정책은 미구현. 기존 추격 보스와 수문장은 별도 역할.

수락 기준: 환경 저항 장비 착용 시 심층부 오염 지속 피해 면역 확인

코드 경계: `game/features/map_generation/map_generator.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

### [심층 코어 최상위 보안 금고 (특수 키카드 소지자 전용 개방)](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081e584ffd1cd87160366)

노션: **결정 (미구현)** · 코드: **신규 미구현** · 작업: **N26-06**

저항 자격/오염 피해·수문장 보장 드랍·키카드 금고 정책은 미구현. 기존 추격 보스와 수문장은 별도 역할.

수락 기준: 특수 키카드 소지 시에만 심층부 보안 금고 문이 열리는지 확인

코드 경계: `game/features/map_generation/map_generator.gd`

기존 검사 근거: `game/tests/operation_combination_contract_test.gd`

</details>

## 노션에 세부 규격이 없는 기존 구현 {#implemented-outside-notion}

최신 GDD 62블록과 트래커 66행에 세부 규격이 명시되지 않은 기존 구현 묶음. 과거 사용자 요청으로 구현된 범위이며 삭제 대상이나 신규 기획 확정이 아님. 아래 묶음 수는 요구 행 수와 다르며 진행률 분자/분모에 포함하지 않음.

**10개 게임 기능 묶음**입니다. 위 66개 요구 행과 단위가 다르므로 합쳐서 완료율을 계산하지 않습니다.

### EXT-INVENTORY · [크기가 다른 가방 아이템 이동·R 회전·저장 확인](../features/grid-inventory.md)

일반 F 획득 요구와 별개인 공간 배치 규칙. 3×2↔2×3, 충돌 거부, 편집 저장/취소가 있으며 현장 R 장착과 입력 맥락을 분리합니다.

코드 경계: `game/features/inventory/grid_inventory.gd`, `game/features/inventory/inventory_edit_session.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`, `game/tests/support/inventory_editor_contract.gd`

### EXT-MOBILE · [PC/모바일 선택·가로형 터치 조작·HUD 설정](../features/mobile-hud-settings.md)

좌하단 이동, 우하단 공격/스킬, 배율·가로 안내·1회성 도움말을 제공하는 별도 입력/표현 계층입니다. 전 기종 실기기 수락 완료를 뜻하지 않습니다.

코드 경계: `game/features/mobile_controls/mobile_control_pad.gd`, `game/features/mobile_controls/mobile_orientation_policy.gd`

기존 검사 근거: `game/tests/mobile_control_entry_contract_test.gd`, `game/tests/mobile_hud_elite_contract_test.gd`

### EXT-VISION · [방·통로 안개·전체 지도·조건부 워프](../features/fog-of-war.md)

현행은 익스트랙션 구역 단위 전체 공개·탐색 기억과 전체 M 지도·안전 단말 워프입니다. 단말 근접/주변 위협/봉쇄를 검증합니다. 과거 전방 원뿔·모든 클리어방 원격 워프 설명은 기본 정책의 근거가 아닙니다.

코드 경계: `game/features/fog_of_war/fog_of_war.gd`, `game/features/room_navigation/room_warp_system.gd`, `game/features/fog_of_war/space_visibility_field.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`, `game/tests/e2e_play_session_test.gd`

### EXT-ROOM · [도시 도로·시설과 선택형 봉쇄 교전·보상](../features/room-encounters.md)

도로/건물/가구 배치를 분리하고 일반 교전에서는 후퇴, 금고 단말 F 선택 목표에서는 봉쇄/전멸/보상을 적용합니다. 모든 방의 무조건 봉쇄는 이전 정책입니다. 저항 장비·키카드·심층 수문장 구현은 별도 미완료입니다.

코드 경계: `game/features/room_encounters/room_encounter_system.gd`, `game/features/room_encounters/room_credit_reward_box.gd`, `game/features/room_encounters/district_encounter_system.gd`, `game/features/map_generation/urban_block_layout.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`, `game/tests/e2e_play_session_test.gd`

### EXT-PURSUIT · [진입 비용 50% 회수 시 추격 보스·방향 경고](../features/elite-pursuit.md)

현재 설정은 휴대 크레딧 임계 0.5배이며 방 봉쇄와 독립된 추격자입니다. 노션의 보스 계약 선택이나 저항 장비를 보장 드랍하는 심층 수문장과 동일하지 않습니다.

코드 경계: `game/features/elite_pursuit/elite_pursuit_service.gd`, `game/features/elite_pursuit/configs/default_elite_pursuit.tres`

기존 검사 근거: `game/tests/support/pursuit_boss_contract.gd`, `game/tests/mobile_hud_elite_contract_test.gd`

### EXT-IDENTITY · [무기8종·방어구14종·3세트와 고정 고유 효과](../features/equipment-fixed-identity.md)

총기5·근접3, 방어구4부위14종/3세트의 2·4개 효과를 구현했습니다. 고정 옵션/고유 효과는 내외부 레벨과 분리하고 세트 resolver가 스탯을 전달합니다. 수치는 임시이며 일반 제작 요구와 별도 콘텐츠입니다.

코드 경계: `game/features/weapons/weapon_innate_skill_system.gd`, `game/features/equipment/equipment_fixed_option.gd`, `game/features/equipment/armor_set_resolver.gd`

기존 검사 근거: `game/tests/equipment_fixed_identity_contract_test.gd`, `game/tests/armor_set_contract_test.gd`, `game/tests/weapon_arsenal_contract_test.gd`

### EXT-GROWTH · [내부 임시 버프·외부 캐릭터/장비 성장](../features/growth.md)

런 임시 강화와 정산 뒤 캐릭터/장비 메타 성장 경로를 분리합니다. 현재 표준 HP는 오너 승인에 따라 키트 전용이므로 레벨업 HP 회복은 비활성입니다. GDD의 큰 성장 개념 외 세부 규격을 별도로 보존합니다.

코드 경계: `game/features/experience/progression_system.gd`, `game/features/meta_progression/meta_progression_system.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`

### EXT-CUSTOMIZATION · [고유 파츠·영구 모듈 코스트·강화·개조](../features/equipment-customization.md)

48c12bf: 위아래 무기 카드/그림 주변 파츠, E/I 공통 무기·방어구·캐릭터 모듈 카드와 슬롯별 타입 소켓을 구현했습니다. 최대 레벨 해금·일치 비용 절반 올림·강화 CSV 확장·저장/복원 검증. 캐릭터 외부40 해금은 임시 정책이며 촉매/레벨 초기화는 없음. 최신 노션의 런 전용 룬/코어와 다른 영구 장비 개조이므로 66행 점수에 중복 가산하지 않습니다.

코드 경계: `game/features/equipment/equipment_system.gd`, `game/features/equipment/equipment_module_instance.gd`, `game/features/equipment/module_socket_policy.gd`, `game/features/equipment/module_workspace.gd`, `game/features/equipment/weapon_attachment_rack.gd`

기존 검사 근거: `game/tests/basic_loop_smoke_test.gd`, `game/tests/module_socket_workspace_test.gd`, `game/tests/weapon_attachment_rack_test.gd`, `game/tests/e2e_play_session_test.gd`

### EXT-FEEDBACK · [타격 방향 충격·처치 링·대시 잔상/속도선](../features/hit-feedback.md)

최신 반응 표현과 유휴 반복 작업 감소를 반영했습니다. 핵앤슬래시 재미라는 의도와 관련되지만 세부 연출 규격은 노션에 없습니다. 평균 FPS 향상이나 사람 재미 수락을 증명한 것은 아닙니다.

코드 경계: `game/features/hit_feedback/hit_feedback_director.gd`, `game/features/player/player_movement_feedback.gd`

기존 검사 근거: `game/tests/frame_feedback_contract_test.gd`

### EXT-ACTIVE-SKILLS · [초기 요원·무기 선택, 고정 패시브와 액티브40종](../features/tactical-skill-catalog.md)

3요원·8무기 초기24조합, 고정 계열 특화, 기존4+신규36 액티브를 구현했습니다. 공용3슬롯·신규36종 무료 수치는 임시. Skill/SkillPattern/Character 잠금과 실제 발동 회귀가 있으며 훈련 라이브 값 불일치는 별도 잔여 QA입니다.

코드 경계: `game/features/character_selection/initial_loadout_panel.gd`, `game/features/combat_skills/effects/tactical_pattern_effect.gd`, `game/features/combat_skills/skill_balance_snapshot.gd`

기존 검사 근거: `game/tests/tactical_skill_catalog_test.gd`

<!-- notion-audit:end -->

## 검색 별칭

최신 기획, GDD v128, 66개 작업, 원본 이관, 코드 대조, 73.2%, 회복 충돌, 혈전, 버서커, 보안 파우치, 심층 진입, 수문장, 키카드, N26, 오너 판단
