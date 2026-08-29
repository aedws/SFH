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
    <div class="sfh-progress-summary">
      <div class="sfh-progress-heading">
        <span><small>NOTION-ALIGNED</small><strong>기획 진행도</strong></span>
        <b>40%</b>
      </div>
      <div class="sfh-progress-track" role="progressbar" aria-label="SFH 기획 진행도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="40"><i style="width: 40%"></i></div>
      <p>확정 전투 원칙 3× · 코어 루프 2× · 기타 요구사항 1× 가중치</p>
      <a href="development-status/#_1">산정 근거 확인 →</a>
    </div>
    <header><strong>현재 빌드 상태</strong><b class="sfh-live">PLAYABLE</b></header>
    <p>작전 규모 선택부터 전투·파밍·탈출 또는 사망까지 최소 게임 루프가 연결되어 있습니다.</p>
    <div class="sfh-operation-grid">
      <span><b>3</b><small>MAP TIERS</small></span>
      <span><b>⇧·Q·F·I·U</b><small>ACTIVE INPUTS</small></span>
      <span><b>PASS</b><small>SMOKE TEST</small></span>
    </div>
  </aside>
</section>

<div class="sfh-stats">
  <div class="sfh-stat"><small>Core loop</small><strong>9–11 MIN</strong><span>전투 → 파밍 → 신호 개방 → 탈출</span></div>
  <div class="sfh-stat"><small>World</small><strong>18–60 ROOMS</strong><span>확장 방·복도·기둥·미니맵</span></div>
  <div class="sfh-stat"><small>Loadout</small><strong>장비 기반 완료</strong><span>무기·방어구·파츠·모듈</span></div>
  <div class="sfh-stat"><small>Growth</small><strong>Run + Meta</strong><span>임시 버프·세 계열 영구 레벨</span></div>
</div>

<div class="sfh-section-head">
  <div><span class="sfh-kicker">RELEASE NOTES</span><h2>📢 최신 업데이트</h2></div>
  <p>날짜별 핵심 변경을 먼저 읽고, 필요한 항목만 펼쳐 상세 내용과 관련 문서로 이동합니다.</p>
</div>

<div class="sfh-release-stats"><span>최신 2026-08-30</span><span>확장 맵 + 반응형 이동</span><span>자동 검증 PASS</span></div>

<div class="sfh-notes">
<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-08-30</b><i class="sfh-latest">최신</i><small>확장 맵 · 10분 런 · 반응형 이동 · 부분 회복</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-summary">
      <strong>핵심 변경 · 4개 주제</strong>
      <ul>
        <li>맵을 소형 18~24방, 중형 30~40방, 대형 45~60방으로 확장했습니다.</li>
        <li>9·10·11분 목표 시각에 탈출 신호가 개방되도록 적용했습니다.</li>
        <li>가속·제동·역선회와 Shift/Space 회피 이동을 구현했습니다.</li>
        <li>피격 4초 후 최대 체력 65%까지만 회복하는 모듈을 추가했습니다.</li>
      </ul>
      <p class="sfh-intent"><b>개선 의도</b><span>탐색과 생존 시간을 약 10분으로 늘리고, 긴 런에서도 조작과 제한 회복이 전투 리듬을 유지하게 합니다.</span></p>
    </div>

    <div class="sfh-group"><h3>🆕 구현 · 6</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">시간 잠금 탈출과 10분 페이싱</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>등급별 목표와 신호 개방 시간을 HUD·탈출 계약에 연결했습니다.</p><a href="features/raid-setup-extraction/">페이싱 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">부분 체력 회복</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>피격 지연 후 65%까지만 회복하는 독립 생존 모듈을 추가했습니다.</p><a href="features/health-recovery/">회복 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">내부 버프 선택과 외부 성장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>내부 레벨업 선택, 버프 중첩, 종료 정산, 세 계열 영구 레벨과 저장을 연결했습니다.</p><a href="features/progression/">성장 설계 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">모듈·고유 파츠 강화 비용</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>동일 아이템 재료와 휴대 크레딧을 확인·소비하는 독립 강화 서비스를 추가했습니다.</p><a href="features/equipment-upgrade-economy/">강화 경제 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Q 메인·보조 무기 교체</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비 시스템이 활성 슬롯을 관리하고 자동 무기가 변경 Signal을 받아 즉시 발사 프로필을 바꿉니다.</p><a href="features/weapon-balance/">상세 설계 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">밸런스 모드 선택 UI</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>작전 규모를 고르기 전에 확정 CSV와 Google Sheet 실시간 테스트를 화면 버튼으로 선택합니다.</p></div></details>
    </div>

    <div class="sfh-group"><h3>✨ 개선 · 4</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">18~60방 확장 맵</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>세 등급의 방 수와 개별 방 면적을 대폭 상향했습니다.</p><a href="features/map-generation/">맵 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">반응형 이동과 회피</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>가속·제동·역선회·Shift/Space 회피로 조작감을 개선했습니다.</p><a href="features/player/">이동 보기 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">에임 없는 전투용 밸런스 필드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>ADS·반동·조준 회복 대신 자동 탐지 거리, 버스트, 다중 투사체, 치명타와 관통을 핵심 수치로 사용합니다.</p></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">행 기반 공용 밸런스 시트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>1행 변수명, 2행 설명, 3행 이후 개별 데이터로 고정하고 Weapon·Armor·Item 탭의 책임을 분리했습니다.</p></div></details>
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
  <a class="sfh-link-card" href="features/progression/"><b>로그라이크 성장</b><span>한 판 임시 버프와 작전 종료 후 외부 성장 정산을 설명합니다.</span><small>RUN + META →</small></a>
  <a class="sfh-link-card" href="features/grid-inventory/"><b>격자 가방</b><span>아이템별 점유 크기와 I 키 인벤토리의 현재 구현을 확인합니다.</span><small>INVENTORY →</small></a>
  <a class="sfh-link-card" href="getting-started/edit-wiki-online/"><b>웹에서 위키 수정</b><span>GitHub 웹 편집과 자동 Pages 배포 흐름을 따라갑니다.</span><small>COLLABORATE →</small></a>
</div>

## 검색 요령

상단 검색창 또는 `/` 키를 사용합니다. `Q키`, `구글 시트`, `가방`, `모듈 코스트`, `소분류`, `미니맵`, `탈출`, `버그픽스`처럼 기능·입력·증상 단어로 검색할 수 있습니다.
