---
title: 개발자 작업실
description: 프로젝트 오너가 판단하고 개발자가 객체·관계·코드·검증·배포 계보를 추적하는 보호 운영 화면
search:
  exclude: true
hide:
  - toc
---

# 개발자 작업실

<div id="owner-decision-console" data-sfh-owner-decision-console-host></div>

## 코드 구현 관계

판단 콘솔에서 선택한 요구·위험·작업이 실제로 어느 모듈에 연결되는지 확인합니다. 코드는 근거이며, 프로젝트 오너의 확정 없이 범위나 출시 상태를 대신 결정하지 않습니다.

<div id="code-module-map" data-sfh-code-module-map-host></div>

## 최신 기획 대조 · 오너 판단

[66항목 코드 대조와 8개 충돌 판단](../design/master-gdd-alignment.md#owner-conflicts) · [N26 다음 작업 순서](../design/current-milestone-workline.md#notion-20260907)

최신 원본은 GDD v128과 작업 트래커입니다. 기존 96%는 과거 기준이며 N26-03A/B 코드·자동 계약 반영 후 대응도는 73.2%입니다. 기획 ‘미구현’ 태그를 코드 부재로 해석하지 않습니다.

## SFH 운영 온톨로지 읽는 순서

<div class="sfh-planner-gates">
  <article><i>01 · OBJECT</i><b>실제 대상을 객체로 찾기</b><p>결정·위험·작업뿐 아니라 코드 모듈, 문서, 원본 시스템을 고유 ID로 추적합니다.</p></article>
  <article><i>02 · LINK</i><b>원인과 영향을 관계로 추적</b><p>무엇이 근거인지, 무엇을 막는지, 어느 모듈이 구현하고 어떤 E2E가 검증하는지 확인합니다.</p></article>
  <article><i>03 · ACTION</i><b>권한과 가드를 통과해 실행</b><p>기획 제출→오너 판단→모듈 구현→검증→배포 순서를 건너뛰지 않습니다.</p></article>
</div>

### 판단 폐루프

```text
Notion·Sheet 후보
  → 프로젝트 오너 확정·보류
  → Definition/Policy → Service → System/Presenter 조립
  → 플레이어 인식 E2E·Web/Windows 동등 검증
  → PR 병합·배포
  → 결과와 회귀 위험을 다시 판단 객체에 연결
```

콘솔의 네 화면은 각각 다른 질문에 답합니다.

| 화면 | 답하는 질문 | 실패 신호 |
|---|---|---|
| 판단 대기열 | 지금 프로젝트 오너가 무엇을 결정해야 하는가? | 오너·수락 조건·다음 행동 누락 |
| 객체 탐색 | 요구와 연결된 실제 코드·문서·원본은 무엇인가? | 고유 ID 중복·원본 없는 객체 |
| 관계·계보 | 이 판단의 선행 근거와 후속 영향은 무엇인가? | 깨진 링크·구현/검증 근거 단절 |
| 행동·관측 | 누가 무엇을 입력해 어떤 결과를 만들며 무엇이 차단하는가? | 권한 우회·실패 검사 뒤 배포 |

전체 문서 지도의 95개 문서는 대·중분류 `문서 묶음`에 자동 연결되고, 현행 작업선의 `BASE-*`·`P*-*` 28행은 오너·수락 조건·E2E 근거를 가진 작업 객체로 자동 변환됩니다. [행동·관측 바로 열기](?view=operations)에서 Notion 스냅샷 나이와 Google Sheet 실시간 확인 필요 상태를 먼저 본 뒤 작업합니다. 생성 객체는 파생 뷰이므로 콘솔에서 직접 수정하지 않습니다.

## 다음 실행선과 현재 위험

| 우선순위 | 대상 | 현재 상태 | 오너가 확인할 완료 조건 |
|---:|---|---|---|
| 1 | P9-01 도감 해금률·지역 힌트 | 구현 준비 | 잠금/해금·해금률·획득 지역 단서가 저장·복원되고 플레이 E2E 통과 |
| 판단 | P7 품질·리롤·제작 운영값 | 오너 판단 필요 | 가격·배율·옵션/소켓 범위·재화 소모를 확정 CSV로 승인 |
| 차단 | Item·Utility 중복 원본 | Sheet 정리 대기 | Utility 단일 원본 지정, 중복 제거, 동기화 검증 성공 |
| 보류 | 서버 위변조·거래 원장 | 별도 승인 전 미착수 | 공급자·보존 기간·비용·복구 권한·제재 기준 승인 |

## 개발자 실행 계약

1. 기획자는 의도와 후보를 제공하고, 개발자는 구현·위험·검증 근거를 제공합니다. **범위·우선순위·수락·출시는 프로젝트 오너만 확정합니다.**
2. 새 기능은 `Definition/Policy → Service → System/Presenter → Scene 조립` 단방향 경계를 지킵니다.
3. 새 세팅은 중앙 분기문이 아니라 기여자·검증기 등록으로 작전 계획에 참여합니다.
4. UI는 도메인 값을 직접 변경하지 않고 공개 명령과 읽기 전용 상태만 사용합니다.
5. 거래·정산·지급은 멱등 키와 롤백을 포함해 원자적으로 처리합니다.
6. 목록형 데이터가 필요할 때만 Google Sheet를 확장하고 실시간 시험/확정 CSV 공급자를 같은 스키마 뒤에 둡니다.
7. 완료는 파일 존재가 아니라 단서→입력→상태 변화→결과→다음 행동의 플레이어 인식 E2E로 판정합니다.
8. 빌드·Web/Windows export·E2E·위키 계약이 모두 성공한 PR만 병합합니다.
9. 판단 콘솔은 읽기 전용 파생 뷰입니다. Notion·Sheet/CSV·Git/E2E·CI보다 우선하지 않습니다.
10. 자동 승인·배포 버튼·과금 또는 서버 설정 변경은 이 콘솔에 포함하지 않습니다.

## 내부 문서 진입점

**오너 검토 제안:** [한 판의 다섯 순간 — 재미 선명화](../quality/five-moment-fun-proposal.md#owner-decision). 현행 관찰→교전 표현부터 시작하는 안이며, 게임 변경·수치·보상은 아직 승인하지 않은 상태입니다.

<nav class="sfh-role-console__grid" aria-label="개발자 핵심 문서">
  <a href="../../architecture/project-ontology/"><b>운영 온톨로지 계약</b><span>객체·관계·행동·인터페이스·원본·권한</span></a>
  <a href="../../design/current-milestone-workline/"><b>현행 실행 작업선</b><span>다음 작업 ID·중단 조건·E2E 게이트</span></a>
  <a href="../../architecture/module-audit/"><b>모듈 감사</b><span>제거성·교체성·경계 위반 기록</span></a>
  <a href="../../quality/e2e-play-session/"><b>실제 플레이 E2E</b><span>입력·상태 전이·회귀 검사</span></a>
  <a href="../../features/"><b>전체 게임 문서</b><span>작전·전투·장비·전리품·성장 규칙</span></a>
  <a href="../../development-status/"><b>업데이트·배포 이력</b><span>일자별 변경과 검증 결과</span></a>
</nav>
