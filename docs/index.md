---
title: SFH 개발 현황
description: 최신 구현·개선·수정·버그픽스와 기능별 진행 상태를 한눈에 보는 개발 대시보드
tags:
  - 홈
  - 개발 현황
  - 업데이트
  - 진행률
  - 구현
  - 개선
  - 수정
  - 버그픽스
hide:
  - navigation
  - toc
---

<section class="sfh-hero">
  <div class="sfh-hero-copy">
    <div class="sfh-brand">
      <span class="sfh-mark">SFH</span>
      <span class="sfh-brand-copy"><strong>SURVIVE · FIGHT · HAUL</strong><small>MODULAR EXTRACTION SURVIVORS</small></span>
    </div>
    <span class="sfh-kicker">DEVELOPMENT COMMAND CENTER</span>
    <h1>살아서 싸우고,<br>가져와 성장하세요.</h1>
    <p>Godot 4 기반 탑다운 뱀서라이크에 익스트랙션 슈터의 작전 선택, 파밍, 장비, 탈출을 결합합니다. 이 화면에서 현재 플레이 가능한 범위와 최신 변경을 바로 확인할 수 있습니다.</p>
    <div class="sfh-actions">
      <a class="sfh-button primary" href="getting-started/run-project/">프로젝트 실행 <b>→</b></a>
      <a class="sfh-button" href="development-status/">전체 업데이트 <b>⌄</b></a>
      <a class="sfh-button" href="architecture/module-rules/">모듈 규칙 <b>↗</b></a>
    </div>
  </div>
  <aside class="sfh-operation-card">
    <header><strong>현재 빌드 상태</strong><b class="sfh-live">PLAYABLE</b></header>
    <p>작전 규모 선택부터 전투·파밍·탈출 또는 사망까지 최소 게임 루프가 연결되어 있습니다.</p>
    <div class="sfh-operation-grid">
      <span><b>3</b><small>MAP TIERS</small></span>
      <span><b>Q·F·I·U</b><small>ACTIVE INPUTS</small></span>
      <span><b>PASS</b><small>SMOKE TEST</small></span>
    </div>
  </aside>
</section>

<div class="sfh-stats">
  <div class="sfh-stat"><small>Core loop</small><strong>작전 가능</strong><span>선택 → 전투 → 파밍 → 탈출</span></div>
  <div class="sfh-stat"><small>World</small><strong>소·중·대형</strong><span>랜덤 방·복도·기둥·미니맵</span></div>
  <div class="sfh-stat"><small>Loadout</small><strong>장비 기반 완료</strong><span>무기·방어구·파츠·모듈</span></div>
  <div class="sfh-stat"><small>Balance</small><strong>Sheet + CSV</strong><span>실시간 테스트·확정 데이터</span></div>
</div>

<div class="sfh-section-head">
  <div><span class="sfh-kicker">RELEASE NOTES</span><h2>📢 최신 업데이트</h2></div>
  <p>날짜별 핵심 변경을 먼저 읽고, 필요한 항목만 펼쳐 상세 내용과 관련 문서로 이동합니다.</p>
</div>

<div class="sfh-release-stats"><span>최신 2026-08-30</span><span>4 categories · 8 verified items</span><span>PR #6 · main merged</span></div>

<div class="sfh-notes">
<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-08-30</b><i class="sfh-latest">최신</i><small>Q 무기 교체와 Google Sheets 밸런스 파이프라인</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-summary">
      <strong>핵심 변경 · 4개 주제</strong>
      <ul>
        <li>Q로 메인 돌격소총과 보조 제식 권총을 즉시 교체합니다.</li>
        <li>소총은 장거리 3점사, 권총은 고위력 단발과 1회 관통으로 역할을 분리했습니다.</li>
        <li>Google Sheets 공개 CSV를 개발 중 갱신하고, 확정 수치는 저장소 CSV로 잠급니다.</li>
        <li>장비 상태·밸런스 출처·발사 실행을 독립 모듈 계약으로 연결했습니다.</li>
      </ul>
      <p class="sfh-intent"><b>개선 의도</b><span>에임이 없는 자동 전투에서도 무기 선택이 사거리와 발사 리듬, 관통 여부로 명확히 체감되게 합니다.</span></p>
    </div>

    <div class="sfh-group"><h3>🆕 구현 · 2</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Q 메인·보조 무기 교체</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비 시스템이 활성 슬롯을 관리하고 자동 무기가 변경 Signal을 받아 즉시 발사 프로필을 바꿉니다.</p><a href="features/weapon-balance/">상세 설계 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Google Sheets 실시간 테스트와 확정 CSV</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>공개 CSV를 3초 간격으로 읽는 개발 모드와 검증된 저장소 CSV를 사용하는 배포 모드를 분리했습니다.</p></div></details>
    </div>

    <div class="sfh-group"><h3>✨ 개선 · 2</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">에임 없는 전투용 밸런스 필드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>ADS·반동·조준 회복 대신 자동 탐지 거리, 버스트, 다중 투사체, 치명타와 관통을 핵심 수치로 사용합니다.</p></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">현재 무기와 출처를 보여주는 HUD</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>활성 슬롯, 무기 특색, 피해, 사거리와 실시간 Sheet 또는 확정 CSV 출처를 상단에서 확인합니다.</p></div></details>
    </div>

    <div class="sfh-group"><h3>🧩 수정 · 2</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">장비·밸런스·발사 경계 분리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비는 weapon_id, 밸런스 서비스는 외부 데이터, 자동 무기는 발사 패턴만 담당하도록 조립 구조를 정리했습니다.</p><a href="architecture/module-audit/">모듈 감사 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">FeatureManifest 밸런스 토글</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>weapon_balance만 끄면 자동 무기가 내장 소총값으로 폴백하며 다른 전투 기능은 유지됩니다.</p></div></details>
    </div>

    <div class="sfh-group"><h3>🔧 버그픽스 · 2</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">외부 CSV 실패 시 정상값 보존</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>네트워크 오류나 잘못된 행이 들어와도 마지막 정상값을 덮어쓰지 않고 확정 CSV로 복구합니다.</p></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">잘못된 밸런스 입력 차단</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>필수 열 누락, 중복 무기 ID, 잘못된 확률·관통 유지율을 런타임과 동기화 명령 양쪽에서 거부합니다.</p></div></details>
    </div>
  </div>
</details>
</div>

<div class="sfh-section-head">
  <div><span class="sfh-kicker">KNOWLEDGE BASE</span><h2>자주 찾는 문서</h2></div>
  <p>처음 시작하는 사람은 실행 문서부터, 공동 작업자는 모듈 규칙과 개발 현황부터 확인합니다.</p>
</div>

<div class="sfh-link-grid">
  <a class="sfh-link-card" href="getting-started/run-project/"><b>프로젝트 실행</b><span>Godot에서 소·중·대형 작전을 시작하고 Q/F/I/U 입력을 확인합니다.</span><small>GETTING STARTED →</small></a>
  <a class="sfh-link-card" href="development-status/"><b>전체 업데이트</b><span>날짜와 구현·개선·수정·버그픽스 태그별 변경 내역을 확인합니다.</span><small>RELEASE NOTES →</small></a>
  <a class="sfh-link-card" href="architecture/module-rules/"><b>모듈 작성 규칙</b><span>기능을 독립적으로 켜고 끄기 위한 폴더·Signal·의존성 규칙입니다.</span><small>ARCHITECTURE →</small></a>
  <a class="sfh-link-card" href="features/weapon-balance/"><b>무기 밸런스</b><span>Google Sheets 실시간 테스트와 확정 CSV 운영 절차를 설명합니다.</span><small>BALANCE PIPELINE →</small></a>
  <a class="sfh-link-card" href="features/grid-inventory/"><b>격자 가방</b><span>아이템별 점유 크기와 I 키 인벤토리의 현재 구현을 확인합니다.</span><small>INVENTORY →</small></a>
  <a class="sfh-link-card" href="getting-started/edit-wiki-online/"><b>웹에서 위키 수정</b><span>GitHub 웹 편집과 자동 Pages 배포 흐름을 따라갑니다.</span><small>COLLABORATE →</small></a>
</div>

## 검색 요령

상단 검색창 또는 `/` 키를 사용합니다. `Q키`, `구글 시트`, `가방`, `모듈 코스트`, `소분류`, `미니맵`, `탈출`, `버그픽스`처럼 기능·입력·증상 단어로 검색할 수 있습니다.
