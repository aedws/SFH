---
title: 기획자 작업실
description: 게임을 처음 보는 사람도 현재 완성 범위와 남은 기획 결정을 이해하는 기획자 전용 화면
search:
  exclude: true
hide:
  - toc
---

# 기획자 작업실

<a class="sfh-article-entry" href="../../features/"><strong>SFH 종합 문서부터 읽기 →</strong><small>게임 개요 → 작전·전투·장비 → 세부 규칙. 큰 문서에서 작은 문서로 내려갑니다.</small></a>

<section class="sfh-role-console is-planner sfh-role-workspace">
  <header><span class="sfh-kicker">PLANNER ROOM · PLAIN LANGUAGE</span><h2>이 게임을 처음 봐도 여기서부터 읽으면 됩니다</h2><p>SFH는 거점에서 장비를 고르고, 위험한 지역에 들어가 전리품을 모은 뒤, 살아서 탈출해 다음 출격을 준비하는 탑다운 액션 게임입니다.</p></header>
  <div class="sfh-plain-loop" aria-label="플레이 흐름 다섯 단계">
    <span><i>1</i><b>준비</b><small>요원·장비·지역 선택</small></span>
    <span><i>2</i><b>진입</b><small>비용을 내고 작전 시작</small></span>
    <span><i>3</i><b>전투</b><small>방을 확보하고 적 처치</small></span>
    <span><i>4</i><b>회수</b><small>전리품을 챙겨 탈출</small></span>
    <span><i>5</i><b>성장</b><small>거점에서 다음 런 준비</small></span>
  </div>
</section>

## 지금 플레이할 수 있는 것

**이번 변경:** 준비 화면의 상점에서 상품을 골라 가격과 구매 후 잔액을 확인한 뒤 구매합니다. 열거나 누르기만 해서 첫 상품을 자동 구매하지 않습니다. 아직 손상/고성능이 실제 성능에 적용되지는 않아 화면에 `후속 구현`이라고 안내합니다. 이 차이를 완료로 잘못 셌던 경제 진행률을 정정해 전체 기능 추정치는 94%입니다. 새 보안·백업 방식은 계획만 적었으며 켜지지 않았습니다. 공개 Notion은 v1005·77블록으로 변함없고 Phase 체크 0/6도 그대로입니다.

<div class="sfh-role-status-grid">
  <article><span>완료</span><b>거점과 작전</b><p>거점의 게이트에서 작전 조건을 고르고 전장에 들어간 뒤 결과와 함께 돌아옵니다.</p></article>
  <article><span>완료</span><b>전투와 방 확보</b><p>자동 공격과 세 가지 스킬로 싸우고, 방의 적을 모두 쓰러뜨리면 문과 보상이 열립니다.</p></article>
  <article><span>완료</span><b>파밍과 탈출</b><p>아이템을 비교·획득·교체하고 탈출 성공 여부에 따라 보관·환전·소실 결과가 나뉩니다.</p></article>
  <article><span>완료</span><b>장비와 거점 성장</b><p>무기·방어구·파츠·모듈·상점·제작·훈련·도감을 한 준비 흐름에서 사용합니다.</p></article>
  <article><span>로컬 완료</span><b>기록과 제출 준비</b><p>성공 기록은 내 기기에 남습니다. 제출·재시도 계약은 있지만 실제 계정 서버와 정상 플레이를 검증하는 운영 서버는 아직 없습니다.</p></article>
</div>

<p class="sfh-role-explain"><b>“완료”의 뜻</b><span>코드 파일이 있다는 뜻이 아니라, 플레이어가 입력하고 화면 변화를 확인하며 다음 행동까지 이어갈 수 있고 자동 테스트가 그 흐름을 통과했다는 뜻입니다.</span></p>

## 이제 기획자가 정해야 할 것

<div class="sfh-decision-lanes">
  <a href="../../design/planner-request-workflow/"><small>먼저 결정</small><b>실서비스 랭킹 신원</b><span>현재 익명 기기 ID를 어떤 로그인 계정으로 교체하고, 어떤 서버가 최종 기록을 승인할지 정해야 합니다.</span><em>P6 LIVE</em></a>
  <a href="../../design/current-milestone-workline/"><small>그다음 결정</small><b>시즌과 명예 보상</b><span>시즌 기간·참가 조건·동점·주간 칭호·오라의 지급 기준과 중복 지급 정책이 필요합니다.</span><em>P6-03~04</em></a>
  <a href="../../design/planner-request-workflow/"><small>수치 확정</small><b>상점·제작·훈련 데이터</b><span>현재 교체 가능한 임시값을 실제 가격·효과·회전 주기·레시피·계측 기준으로 확정해야 합니다.</span><em>SHEET</em></a>
  <a href="../../quality/player-perception-audit/"><small>플레이 판단</small><b>재미와 이해 가능성</b><span>처음 플레이한 사람이 준비→전투→회수→성장을 설명 없이 이해하는지 수락 여부를 남겨야 합니다.</span><em>PLAYTEST</em></a>
</div>

<details class="sfh-home-drawer sfh-planner-requests" data-sfh-planner-requests>
  <summary><span><span class="sfh-kicker">DECISION QUEUE</span><b>실제 기획 요청·완료 근거 보기</b><small>담당·상태·수락 기준을 요청 ID로 추적합니다.</small></span><em>＋</em></summary>
  <div class="sfh-home-drawer__body">
    <div class="sfh-planner-requests__heading"><span class="sfh-planner-requests__status" data-sfh-planner-request-status>요청 목록 연결 중</span></div>
    <div class="sfh-planner-source" data-sfh-planner-source aria-live="polite">Notion 확인 시각을 불러오는 중</div>
    <p data-sfh-planner-request-instruction>요청 ID를 Notion 결정 제목에 함께 적어 주세요.</p>
    <div class="sfh-planner-filters" data-sfh-planner-filters aria-label="협업 요청 역할 필터">
      <button type="button" data-filter="all" aria-pressed="true">전체</button>
      <button type="button" data-filter="planner" aria-pressed="false">기획자 할 일</button>
      <button type="button" data-filter="ai_developer" aria-pressed="false">개발자 할 일</button>
      <button type="button" data-filter="complete" aria-pressed="false">검증 완료</button>
    </div>
    <div class="sfh-planner-requests__grid" data-sfh-planner-request-grid aria-live="polite"></div>
  </div>
</details>

<details class="sfh-home-drawer sfh-proposal-composer" data-sfh-proposal-composer>
  <summary><span><span class="sfh-kicker">NOTION DRAFT</span><b>기획 제안 초안 만들기</b><small>브라우저 안에서만 작성하며 자동 전송하지 않습니다.</small></span><em>＋</em></summary>
  <div class="sfh-home-drawer__body">
    <p class="sfh-proposal-local-state">LOCAL ONLY · NO PUBLIC WRITE</p>
    <div class="sfh-proposal-grid">
      <label>종류<select name="kind"><option>PLAN</option><option>DATA</option><option>DEV</option><option>BUG</option></select></label>
      <label>요청 ID<input name="request_id" placeholder="PLAN-P6-03-01"></label>
      <label class="is-wide">제목<input name="title" placeholder="무엇을 결정하는지"></label>
      <label class="is-wide">작성 근거<input name="basis" placeholder="Notion Phase 또는 DEC ID"></label>
      <label class="is-wide">수락 기준<input name="acceptance" placeholder="플레이어가 확인할 결과"></label>
      <label class="is-wide">Sheet 대상<input name="sheet_target" placeholder="목록이 필요할 때만 작성"></label>
    </div>
    <textarea data-sfh-proposal-output readonly aria-label="Notion에 붙여넣을 제안 초안"></textarea>
    <div class="sfh-proposal-actions"><button type="button" data-sfh-proposal-copy>초안 복사</button><span data-sfh-proposal-state>외부로 자동 전송하지 않습니다.</span></div>
  </div>
</details>

## 기획 결정을 남기는 방법

1. [기획 요청 목록](../design/planner-request-workflow.md)에서 결정할 요청 ID를 확인합니다.
2. Notion 제목에 같은 요청 ID를 적고, “무엇을 / 언제 / 어느 수치로” 적용할지 한 문장으로 확정합니다.
3. 목록형 수치가 필요하면 Google Sheet의 1행 변수명·2행 설명·3행 이후 데이터 규칙으로 작성합니다.
4. 개발 완료 뒤 [플레이어 인식 검수](../quality/player-perception-audit.md)에서 실제 화면 결과를 보고 수락합니다.

<nav class="sfh-role-console__grid" aria-label="기획자 핵심 문서">
  <a href="../../design/planner-request-workflow/"><b>결정·데이터 요청</b><span>기획자가 지금 답해야 할 항목</span></a>
  <a href="../../design/master-gdd-alignment/"><b>기획 원본 대조</b><span>Notion 확정 내용과 구현 차이</span></a>
  <a href="../../quality/player-perception-audit/"><b>플레이 수락 검사</b><span>사람 눈에 보이는 완료 기준</span></a>
  <a href="../../development-status/"><b>완료된 변경</b><span>하루 단위 구현 결과와 검증</span></a>
</nav>
