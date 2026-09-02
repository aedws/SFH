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
  <summary><span class="sfh-day-title"><b>2026-09-03</b><i class="sfh-latest">최신</i><small>1 UPDATE BUNDLES · BUILD 3 · IMPROVE 5 · CHANGE 4 · FIX 2</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>1</b><small>UPDATE BUNDLES</small></span><span><b>3</b><small>BUILD</small></span><span><b>5</b><small>IMPROVE</small></span><span><b>4</b><small>CHANGE</small></span><span><b>2</b><small>FIX</small></span></div>
    <details class="sfh-bundle" open>
      <summary><span><small>LATEST</small><b>전투 HUD · 중앙 시야 확보</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>전투 필수 정보는 화면 가장자리로 압축하고, 비어 있는 런 소켓 패널은 숨겨 중앙 전장을 가리지 않게 했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>가로형 스킬 클러스터, 중앙 안전 영역, 상황형 소켓 표시 계약을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>스킬·에너지·소켓·행동 안내의 배치와 화면 점유율을 낮췄습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>런타임 HUD 배치 책임, 플레이어 인식 E2E, 기능·감사 문서를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>빈 소켓 패널 잔류와 중앙 우측 세로 스킬 패널의 시야 침범을 제거했습니다.</p></div>
      </div>
    </details>
  </div>
</details>
</div>
