---
title: 개발자 작업실
description: 프로젝트 오너가 판단하고 개발자가 객체·관계·코드·검증·배포 계보를 추적하는 보호 운영 화면
search:
  exclude: true
hide:
  - toc
---

# 개발자 작업실

작업·구조·검증 근거를 골라 확인하세요. 최종 판단은 프로젝트 오너가 합니다.

<nav class="sfh-workspace-launcher" aria-label="개발자 작업 바로가기">
  <a href="#map-workbench"><small>공간</small><strong>맵·피스 설계실</strong><span>게임 배치 대조와 오너 판단 초안</span></a>
  <a href="#owner-decision-console"><small>판단</small><strong>작업·오너 판단</strong><span>선행 조건과 판단 대기열</span></a>
  <a href="#confirmed-balance"><small>밸런스</small><strong>확정안·현행 수치</strong><span>미확정 항목은 현재 CSV로 확인</span></a>
  <a href="#code-module-map"><small>구조</small><strong>코드·모듈 관계</strong><span>구현 연결과 영향 추적</span></a>
  <a href="../../design/current-milestone-workline/#notion-20260907"><small>실행</small><strong>현재 작업선</strong><span>작업 순서·중단·완료 조건</span></a>
  <a href="../../quality/e2e-play-session/"><small>품질</small><strong>플레이 검증</strong><span>회귀 위험과 수락 근거</span></a>
  <a href="#developer-contract"><small>원칙</small><strong>개발·운영 계약</strong><span>모듈 경계와 검증 규칙</span></a>
</nav>

<p class="sfh-workspace-notice">판단 콘솔·그래프는 읽기 전용입니다. 기획 확정, 오너 승인, 게임 적용 상태를 구분해서 확인합니다.</p>

<details class="sfh-workspace-block" markdown="1" id="map-workbench">
<summary>맵·피스 설계실 <small>현행 CSV 배치와 시험안을 비교</small></summary>

## 지역별 필수 공간과 무작위 피스

맵 설계실은 양 역할 모두 시험할 수 있습니다. 기존 기획 확정 그래프의 읽기 전용 권한은 바꾸지 않습니다. 초안은 오너 판단 요청이며 게임 적용·기획 확정이 아닙니다.

<div data-sfh-map-workbench data-catalog="../../assets/map-catalog.json">맵 자료 준비 중…</div>

[RegionalDistrictPlan 계약·검증](../features/extraction-district.md#regional-map). Godot 순수 배치 → 카탈로그·27개 기준 맵 → JS 동등성 검사로 연결합니다. 전투 시뮬레이터가 아니며, 초안은 자동 공유·저장되지 않습니다.

</details>

**최신 오너 승인 변경:** [익스트랙션 구역·공간 공개](../features/extraction-district.md) → [모듈 경계](../architecture/module-audit.md#extraction-district) → [플레이 수락 근거](../quality/e2e-play-session.md#extraction-district). 기존 전방/반경 시야와 모든 방 봉쇄는 기본값이 아니라 이전 정책입니다.

<details class="sfh-workspace-block" markdown="1">
<summary>작업·오너 판단 콘솔 <small>필요한 작업과 근거를 선택</small></summary>

<div id="owner-decision-console" data-sfh-owner-decision-console-host data-focus-object="work:n26-08"></div>

</details>

<details class="sfh-workspace-block" markdown="1">
<summary>기획 확정안·현행 밸런스 <small>확정이 없으면 현재 CSV 수치 표시</small></summary>

## 기획 확정 수치 그래프 {#confirmed-balance}

맨 앞 전투 그래프는 **최신 유효 기획 확정안**을 기본으로 사용합니다. 전투 확정이 없거나 원본·계산 모델이 변경된 안건이면 현재 구현값의 장비·캐릭터·스킬 그래프를 보여줍니다. 조회 실패는 ‘확정 없음’으로 오인하지 않도록 별도 경고합니다. 확정 시 선택한 파츠·모듈·품질·적 조건과 스킬별 독립 그래프가 함께 보존됩니다. **현행 CSV ≠ 기획 확정 ≠ 오너 승인**이며 자동 게임 적용은 없습니다. 아래 원본 CSV 조회와 과거 확정안 이력도 유지합니다.

<div data-sfh-balance-gallery data-catalog="../../assets/balance-catalog.json">확정안·현행 밸런스 읽는 중…</div>

<details markdown="1">
<summary>효과·스탯 구현 툴킷 · 원본 변수와 동작 확인</summary>

<div data-sfh-effect-toolkit data-readonly="true" data-catalog="../../assets/effect-toolkit.json">효과 구현 경로 읽는 중…</div>

[EffectSpec 검증·구현 인계](../tools/effect-toolkit.md). 기획 확정과 오너 승인을 구분하고 미지원 행동은 새 모듈 작업으로 편성합니다.

</details>

</details>

<nav class="sfh-developer-shortcuts" aria-label="개발자 빠른 문서">
  <a href="../../design/current-milestone-workline/#notion-20260907">현재 작업선 →</a>
  <a href="../../design/master-gdd-alignment/#current-classification">기획·구현 대조 →</a>
  <a href="../../quality/e2e-play-session/">플레이 검증 →</a>
  <a href="../../development-status/">변경 이력 →</a>
</nav>

<details class="sfh-developer-fold" markdown="1" data-sfh-lazy-code>
<summary>코드 구현 관계 · 필요할 때 지도 펼치기</summary>

## 코드 구현 관계

판단 콘솔에서 선택한 요구·위험·작업이 실제로 어느 모듈에 연결되는지 확인합니다. 코드는 근거이며, 프로젝트 오너의 확정 없이 범위나 출시 상태를 대신 결정하지 않습니다.

<div id="code-module-map" data-sfh-code-module-map-host></div>

</details>

<details class="sfh-developer-fold" markdown="1">
<summary>운영 안내 · 최신 기획, 원칙과 전체 문서</summary>

## 최신 기획 대조 · 오너 판단

[66항목 코드 대조와 8개 충돌 판단](../design/master-gdd-alignment.md#owner-conflicts) · [N26 다음 작업 순서](../design/current-milestone-workline.md#notion-20260907)

2026-09-07 GDD v128·62블록과 트래커 66행을 라이브 재확인했습니다(내용 변경 없음). `1bd3b12` 기준 **구현 근거 38 / 부분 7 / 신규 미구현 6 / 충돌 1 / 판단 대기 14**, 가중 대응도 **73.2% 유지**입니다. [세 갈래 분류·남은 범위](../design/master-gdd-alignment.md#current-classification)와 [노션에 세부 규격이 없는 기존 구현 9묶음](../design/master-gdd-alignment.md#implemented-outside-notion)을 구분합니다. 노션 ‘미구현’ 태그나 개발 기반 구축을 게임 진행률로 바꾸지 않습니다.

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

콘솔은 개요를 먼저 보여주고, 필요한 객체와 근거를 선택해서 좁혀 봅니다. 검색·필터·목록 페이지는 탭을 오갈 때 유지됩니다. 탭은 좌우 화살표·Home·End로 이동할 수 있습니다.

| 화면 | 답하는 질문 | 실패 신호 |
|---|---|---|
| 작업 개요 | 지금 볼 작업과 선행 조건은 무엇인가? | 원본과 다른 다음 행동·집계를 게임 진행률로 오인 |
| 판단 대기열 | 지금 프로젝트 오너가 무엇을 결정해야 하는가? | 오너·수락 조건·다음 행동 누락 |
| 객체 탐색 | 요구와 연결된 실제 코드·문서·원본은 무엇인가? | 고유 ID 중복·원본 없는 객체 |
| 관계·계보 | 이 판단의 선행 근거와 후속 영향은 무엇인가? | 깨진 링크·구현/검증 근거 단절 |
| 행동·관측 | 누가 무엇을 입력해 어떤 결과를 만들며 무엇이 차단하는가? | 권한 우회·실패 검사 뒤 배포 |

전체 문서 지도는 대·중분류 `문서 묶음`에 자동 연결되고, 기존 작업선의 `BASE-*`·`P*-*` 항목과 최신 N26 판단·작업을 구분해 추적합니다. [행동·관측 바로 열기](?view=operations)에서 Notion 스냅샷 나이와 Google Sheet 실시간 확인 필요 상태를 먼저 본 뒤 작업합니다. 생성 객체는 파생 뷰이므로 콘솔에서 직접 수정하지 않습니다.

## 다음 실행선과 현재 위험

| 우선순위 | 대상 | 현재 상태 | 오너가 확인할 완료 조건 |
|---:|---|---|---|
| 1 | N26-08B 첫 출격 지연·탈출 F 재현·배포 동등성 | 진행 중 | 초기 렌더링 지연 원인 분리, 단발 F 실패 재현, Web/Windows 10분 일반 플레이 수락 |
| 판단 | N26 회복/AP·파우치·심층·혈전·소켓·기술 | 선행 결정 대기 | 원인별 회복 허용표·소유권·정산·진입 조건을 오너가 결정 |
| 후순위 | P9-01 도감 해금률·지역 힌트 | N26 정렬 후 재편성 | 잠금/해금·지역 힌트의 잔여 범위와 플레이 E2E 수락. 현재 1순위 아님 |
| 판단 | P7 품질·리롤·제작 운영값 | 오너 판단 필요 | 가격·배율·옵션/소켓 범위·재화 소모를 확정 CSV로 승인 |
| 차단 | Item·Utility 중복 원본 | Sheet 정리 대기 | Utility 단일 원본 지정, 중복 제거, 동기화 검증 성공 |
| 보류 | 서버 위변조·거래 원장 | 별도 승인 전 미착수 | 공급자·보존 기간·비용·복구 권한·제재 기준 승인 |

## 개발자 실행 계약 {#developer-contract}

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

</details>
