---
title: SFH 플레이 테스트
description: 살아서 싸우고 회수하는 탑다운 익스트랙션 액션 SFH의 공개 플레이 테스트 페이지
tags: [SFH, 플레이 테스트, 탑다운 액션]
hide:
  - navigation
  - toc
search:
  exclude: true
---

<section class="sfh-hero sfh-public-hero">
  <div class="sfh-hero-copy">
    <div class="sfh-brand">
      <span class="sfh-mark">SFH</span>
      <span class="sfh-brand-copy"><strong>SURVIVE · FIGHT · HAUL</strong><small>MODULAR EXTRACTION ACTION</small></span>
    </div>
    <span class="sfh-kicker">PUBLIC PLAYTEST</span>
    <h1>살아서 싸우고,<br>가져와 성장하세요.</h1>
    <p>거점에서 출격을 준비하고, 자동 전투와 스킬로 위험한 방을 돌파해 전리품을 회수하는 탑다운 익스트랙션 액션입니다.</p>
    <div class="sfh-actions">
      <a class="sfh-button primary sfh-operation-play" data-sfh-surface="gameplay" href="https://sfh-game.vstock-market.workers.dev/" target="_blank" rel="noopener noreferrer">브라우저 플레이 <b>▶</b></a>
      <a class="sfh-button" data-sfh-surface="windows-download" href="https://sfh-game.vstock-market.workers.dev/downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip">Windows 다운로드 <b>↓</b></a>
    </div>
    <p class="sfh-public-note">개발 중인 테스트 빌드입니다. 진행 상황과 내부 설계 문서는 역할 로그인 뒤 제공됩니다.</p>
  </div>
  <aside class="sfh-operation-card sfh-public-card">
    <span class="sfh-kicker">TEST BUILD</span>
    <header><strong>현재 테스트 상태</strong><b class="sfh-live">PLAYABLE</b></header>
    <div class="sfh-public-features">
      <span><i>01</i><b>준비</b><small>요원·장비·작전 선택</small></span>
      <span><i>02</i><b>전투</b><small>자동 공격·3개 스킬</small></span>
      <span><i>03</i><b>회수</b><small>파밍·탈출·영구 성장</small></span>
    </div>
    <a class="sfh-public-login" href="access/login/"><span><b>팀 작업 공간 로그인</b><small>기획자 · 개발자</small></span><em>→</em></a>
  </aside>
</section>

<section class="sfh-public-test-guide" aria-label="테스트 안내">
  <article><span>MOVE</span><b>WASD / 방향키</b><p>거점의 작전 게이트까지 이동해 F로 상호작용하세요.</p></article>
  <article><span>SKILL</span><b>1 · 2 · 3</b><p>점멸, 지속형 자기장, 이동 가속을 상황에 맞게 사용하세요.</p></article>
  <article><span>ESCAPE</span><b>F / M</b><p>보상을 회수하고 지도와 탈출 지점을 확인해 살아서 돌아오세요.</p></article>
</section>

<div class="sfh-notes sfh-public-release">
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-02</b><i class="sfh-latest">최신</i><small>1 UPDATE BUNDLES · BUILD 5 · IMPROVE 4 · CHANGE 4 · FIX 2</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>1</b><small>UPDATE BUNDLES</small></span><span><b>5</b><small>BUILD</small></span><span><b>4</b><small>IMPROVE</small></span><span><b>4</b><small>CHANGE</small></span><span><b>2</b><small>FIX</small></span></div>
    <details class="sfh-bundle" open>
      <summary><span><small>LATEST</small><b>랭킹 기록 보호 · 오프라인 재시도</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>탈출 성공 기록을 기기에 먼저 보존하고, 인터넷 연결이 끊기면 다음 연결 때 다시 제출하도록 개선했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>익명 신원, 검증 봉투, 중복 방지, 영구 재시도, 결과 상태를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>오프라인 보존, 제출 상태 이해, 저장 복구, 온라인 공급자 교체성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>정산 런 ID, 랭킹 설정, 테스트와 내부 작업 문서를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>같은 런의 중복 집계와 연결 실패 기록 유실 가능성을 차단했습니다.</p></div>
      </div>
    </details>
  </div>
</details>
</div>
