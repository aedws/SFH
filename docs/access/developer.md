---
title: 개발자 작업실
description: 완료 기준선, 현재 위험, 다음 구현, 구조와 원칙을 한곳에서 보는 개발자 전용 화면
search:
  exclude: true
hide:
  - toc
---

# 개발자 작업실

<section class="sfh-role-console is-developer sfh-role-workspace">
  <header><span class="sfh-kicker">DEVELOPER ROOM · EXECUTION FIRST</span><h2>다음 변경과 회귀 위험을 먼저 봅니다</h2><p>완료 이력은 기준선으로 압축하고, 현재 오류·다음 작업·모듈 경계·검증 원칙을 구현 순서대로 배치합니다.</p></header>
  <div class="sfh-dev-focus">
    <span><small>NEXT</small><b>P6-02</b><em>신원·제출·검증·재시도</em></span>
    <span><small>BASELINE</small><b>P1·P4·P5</b><em>완료·회귀 금지</em></span>
    <span><small>KNOWN GAP</small><b>P6</b><em>서버 검증·시즌·보상</em></span>
  </div>
</section>

## 다음 업데이트 큐

| 순서 | 작업 | 구현 경계 | 플레이어 완료 조건 |
|---:|---|---|---|
| 1 | P6-02 신원·제출·검증·재시도 | 기록 생성, 전송 공급자, 서버 판정, 재시도 큐, UI를 분리 | 제출 중·성공·대기·거부 이유를 식별 |
| 2 | P6-03 시즌 규칙 | 기간·참가 조건·종료 스냅샷을 `SeasonPolicy`로 격리 | 종료일과 참가 가능 여부를 사전에 확인 |
| 3 | P6-04 칭호·오라 | 지급은 보상 서비스, 소유는 프로필, 표현은 UI가 담당 | 1회 지급·재로그인 유지·장착 결과 확인 |
| 4 | 내부 P7~P10 | 경제→훈련→도감→출시 후보 회귀 순서 유지 | 각 흐름이 실제 입력 E2E와 산출물 동등성 통과 |

## 이미 진행한 기준선

- **Phase 1:** 자유 스킬 배치, 입력 충돌 교환, HUD 반영, 저장·초기화.
- **Phase 4:** 전리품 생명 주기, 드랍 표, 현장 비교·교체, 런 소켓, 탈출 정산.
- **Phase 5:** 요원·로드아웃 투자, 유틸리티, 원자적 작전 초안, 상점·제작·훈련·도감.
- **Phase 6 P6-01:** 로컬 랭킹 보존, 온라인 공급자 어댑터, 장애 폴백.
- **운영:** Web/Windows 동등 산출물, 역할 인증, Private R2, PR·필수 검사·백업.

## 현재 오류·위험 레지스터

| 상태 | 위험 | 처리 원칙 |
|---|---|---|
| 미구현 | 온라인 기록의 신원·서명·서버 검증이 없음 | P6-02 전에는 온라인 순위를 신뢰 가능한 완료로 표시하지 않음 |
| 기획 대기 | 시즌 기간·참가 조건·보상 기준이 확정되지 않음 | Policy/Definition 기본값만 격리하고 영구 지급 연결 금지 |
| 임시 데이터 | P5 상점·제작·훈련 일부 수치가 임시값 | 공급자 스키마를 유지하고 확정 CSV 교체만 허용 |
| 상시 회귀 위험 | 세팅 변경 뒤 작전 조립·결제·복원이 깨질 수 있음 | 불변 계획·사전 검증·93+ 조합 E2E를 병합 게이트로 유지 |

## 구조와 프로그래밍 원칙

1. 새 기능은 `Definition/Policy → Service → System/Presenter → Scene 조립`의 단방향 경계를 지킵니다.
2. 새 세팅은 중앙 분기문이 아니라 기여자·검증기 등록으로 작전 계획에 참여합니다.
3. UI는 도메인 값을 직접 변경하지 않고 공개 명령과 읽기 전용 상태만 사용합니다.
4. 거래·정산·지급은 멱등 키와 롤백을 포함해 원자적으로 처리합니다.
5. 선택 모듈은 비활성화·파일 제거 테스트를 통과해야 하며 내부 Node 경로 결합을 금지합니다.
6. 목록형 데이터가 새로 필요할 때만 Google Sheet를 확장하고 실시간 시험/확정 CSV 공급자를 같은 스키마 뒤에 둡니다.
7. 완료 판정은 파일 존재가 아니라 단서→입력→상태 변화→결과→다음 행동의 플레이어 인식 E2E로 합니다.
8. 병합은 빌드·Web/Windows export·E2E·위키 계약이 모두 성공한 PR만 허용합니다.

<nav class="sfh-role-console__grid" aria-label="개발자 핵심 문서">
  <a href="../../design/current-milestone-workline/"><b>실행 작업선</b><span>다음 ID·중단 조건·E2E 게이트</span></a>
  <a href="../../architecture/code-module-map/"><b>코드 관계 웹</b><span>상속·의존·사용처 현행 상태</span></a>
  <a href="../../architecture/module-audit/"><b>모듈 감사</b><span>제거성·교체성·경계 위반 기록</span></a>
  <a href="../../quality/e2e-play-session/"><b>실제 플레이 E2E</b><span>입력·상태 전이·회귀 검사</span></a>
</nav>
