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
search:
  exclude: true
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
        <b>95%</b>
      </div>
      <div class="sfh-progress-track" role="progressbar" aria-label="SFH 기획 진행도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="95"><i style="width: 95%"></i></div>
      <p>Master GDD v1005 · 10개 확정 시스템 · Phase 1~5 + P6-01 완료 · 가중 산식 95%</p>
      <a href="development-status/#_1">산정 근거 확인 →</a>
      <a href="https://wobbly-pawpaw-1ff.notion.site/SFH-6b45b728004082af8a4a811ef0a1c5e9">공개 기획 원본 ↗</a>
    </div>
    <header><strong>현재 빌드 상태</strong><b class="sfh-live">PLAYABLE</b></header>
    <p>거점에서 지역·난이도·페널티·소모품을 준비하고, 투입 비용을 지불해 전투·파밍·탈출 방어·영구 정산 뒤 복귀합니다.</p>
    <div class="sfh-operation-launch">
      <a class="sfh-operation-play" data-sfh-surface="gameplay" href="https://sfh-game.vstock-market.workers.dev/" target="_blank" rel="noopener noreferrer">
        <span><small>PLAY CURRENT MAIN</small><strong>브라우저로 플레이</strong><em>설치 없이 바로 작전 준비</em></span>
        <b aria-hidden="true">▶</b>
      </a>
      <a class="sfh-operation-download" data-sfh-surface="windows-download" href="https://sfh-game.vstock-market.workers.dev/downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip">
        <span><small>WINDOWS X86_64 · v0.1.0</small><strong>Windows 빌드 다운로드</strong><em>검증 완료 실행의 ZIP · SHA-256 제공</em></span>
        <b aria-hidden="true">↓</b>
      </a>
      <div class="sfh-surface-map" aria-label="배포 영역 분리 상태">
        <span data-sfh-surface="wiki"><small>DOCS · PAGES</small><strong>SFH DEV WIKI</strong><em>문서·검색만 제공</em></span>
        <span data-sfh-surface="gameplay"><small>PLAY · WORKER</small><strong>SFH GAME</strong><em>브라우저 실행 전용</em></span>
        <span data-sfh-surface="r2"><small>ASSETS · PRIVATE R2</small><strong>NO PUBLIC LINK</strong><em>Worker 바인딩만 허용</em></span>
      </div>
      <p class="sfh-cutover-note"><b>NEXT ORIGIN</b><span>sfh-game.play-preview.dev · 도메인 등록·DNS·E2E 완료 후 무중단 전환</span></p>
      <div class="sfh-operation-meta" aria-label="현재 플레이 빌드 요약">
        <span><b>3</b><small>MAP TIERS</small></span>
        <span><b>K · 23 + 9</b><small>KEY + SKILL BINDING</small></span>
        <span><b>PASS</b><small>WEB BUILD</small></span>
      </div>
    </div>
  </aside>
</section>

<section class="sfh-planner-requests" data-sfh-planner-requests aria-labelledby="sfh-planner-requests-title">
  <header class="sfh-planner-requests__heading">
    <div><span class="sfh-kicker">PLANNER REQUEST LINK</span><h2 id="sfh-planner-requests-title">기획 요청 · 데이터 결정</h2></div>
    <span class="sfh-planner-requests__status" data-sfh-planner-request-status>요청 목록 연결 중</span>
  </header>
  <p class="sfh-planner-requests__intro">개발 진행에 필요한 결정만 상단에 압축합니다. 담당 역할·차단 상태·수락 기준·검증 근거까지 같은 ID로 추적합니다.</p>
  <div class="sfh-planner-source" data-sfh-planner-source aria-live="polite">공개 Notion 확인 시각을 불러오는 중</div>
  <p class="sfh-planner-requests__instruction" data-sfh-planner-request-instruction>요청 ID를 Notion 결정 제목에 함께 적어 주세요.</p>
  <div class="sfh-planner-filters" data-sfh-planner-filters aria-label="협업 요청 역할 필터">
    <button type="button" data-filter="all" aria-pressed="true">전체</button>
    <button type="button" data-filter="planner" aria-pressed="false">기획자 할 일</button>
    <button type="button" data-filter="ai_developer" aria-pressed="false">AI 개발자 할 일</button>
    <button type="button" data-filter="complete" aria-pressed="false">검증 완료</button>
  </div>
  <div class="sfh-planner-requests__grid" data-sfh-planner-request-grid aria-live="polite"></div>
  <footer><a href="design/wiki-collaboration-workflow/">협업 문제·수정 대안 →</a> · <a href="design/planner-request-workflow/">요청 작성·Sheet 확정 규칙 →</a></footer>
</section>

<section class="sfh-proposal-composer" data-sfh-proposal-composer aria-labelledby="sfh-proposal-title">
  <header><div><span class="sfh-kicker">SAFE COLLABORATION INTAKE</span><h2 id="sfh-proposal-title">기획 제안 초안 생성</h2></div><span>LOCAL ONLY · NO PUBLIC WRITE</span></header>
  <p>위키는 익명 편집을 받지 않습니다. 아래에서 제안을 정규화해 복사한 뒤, 인증된 Notion에 붙여넣으면 AI 개발자가 다음 스냅샷·PR에서 동일 ID로 추적합니다.</p>
  <div class="sfh-proposal-grid">
    <label>종류<select name="kind"><option>PLAN</option><option>DATA</option><option>DEV</option><option>BUG</option></select></label>
    <label>요청 ID<input name="request_id" placeholder="PLAN-P4-04-01"></label>
    <label class="is-wide">제목<input name="title" placeholder="현장 교체 최종 처리 확정"></label>
    <label class="is-wide">작성 근거<input name="basis" placeholder="Notion Phase 4 블록 또는 DEC ID"></label>
    <label class="is-wide">수락 기준<input name="acceptance" placeholder="플레이어가 실제로 확인할 수 있는 결과"></label>
    <label class="is-wide">Sheet 대상<input name="sheet_target" placeholder="필요 시 Skill/Item 탭 확장"></label>
  </div>
  <textarea data-sfh-proposal-output readonly aria-label="Notion에 붙여넣을 제안 초안"></textarea>
  <div class="sfh-proposal-actions"><button type="button" data-sfh-proposal-copy>초안 복사</button><span data-sfh-proposal-state>이 화면은 외부로 전송하지 않습니다.</span></div>
</section>

<nav class="sfh-role-nav" aria-label="기획자와 개발자 빠른 이동">
  <a href="development-status/"><small>PLAN</small><strong>기획·진행 현황</strong><span>확정 근거와 다음 작업</span></a>
  <a href="architecture/module-rules/"><small>DEV</small><strong>개발·모듈 규칙</strong><span>계약과 확장 경계</span></a>
  <a href="quality/wiki-responsive-e2e/"><small>QA</small><strong>위키 E2E</strong><span>모바일·검색·링크 검증</span></a>
  <a href="#sfh-knowledge-map"><small>DOCS</small><strong>전체 문서 맵</strong><span>대·중·소·세부 탐색</span></a>
</nav>

<div class="sfh-stats">
  <div class="sfh-stat"><small>Core loop</small><strong>HUB → RAID → HUB</strong><span>게이트 진입 · 전투 세션 · 결과 후 복귀</span></div>
  <div class="sfh-stat"><small>World</small><strong>ROOM + CONE VISION</strong><span>방 전체 공개 · 통로 정면 시야 · 전체 미니맵</span></div>
  <div class="sfh-stat"><small>Combat</small><strong>3 ACTIVE SKILLS</strong><span>점멸 · 원형 자기장 · 기동 가속</span></div>
  <div class="sfh-stat"><small>Growth</small><strong>Run + Meta</strong><span>임시 버프·세 계열 영구 레벨</span></div>
</div>

<div class="sfh-section-head">
  <div><span class="sfh-kicker">RELEASE NOTES</span><h2>📢 최신 업데이트</h2></div>
  <p>날짜별 핵심 변경을 먼저 읽고, 필요한 항목만 펼쳐 상세 내용과 관련 문서로 이동합니다.</p>
</div>

<div class="sfh-release-stats"><span>최신 2026-09-02</span><span>SEARCH COMMAND</span><span>1 DAY · 7 TOPICS</span><span>77 DOCS · CLOUDFLARE LIVE</span></div>

<div class="sfh-notes">
<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-09-02</b><i class="sfh-latest">최신</i><small>7 UPDATE BUNDLES · BUILD 28 · IMPROVE 28 · CHANGE 28 · FIX 10</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>7</b><small>UPDATE BUNDLES</small></span><span><b>28</b><small>BUILD</small></span><span><b>28</b><small>IMPROVE</small></span><span><b>28</b><small>CHANGE</small></span><span><b>10</b><small>FIX</small></span></div>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 7</small><b>P6-01 랭킹 공급자 · 방사형 코드 관계 웹</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 랭킹 기록을 로컬에 먼저 보존하면서 온라인 공급자를 교체할 수 있게 했고, 코드 노드맵은 선택 모듈 중심 거미줄로 바뀌었습니다.</strong><ul>
          <li><b>랭킹:</b> 공통 제공자·로컬 구현·온라인 어댑터·설정을 분리하고 장애 시 로컬 기록과 동기화 대기 상태를 유지합니다.</li>
          <li><b>노드맵:</b> 선택 모듈을 중앙에 두고 실제 사용처·의존처·상속·검증 관계를 방향 화살표로 연결합니다.</li>
          <li><b>반응형:</b> 화면 폭에 따라 관계 12/8/6개를 배치하고 연결이 많으면 좌우 버튼으로 넘깁니다.</li>
          <li><b>다음:</b> P6-02 신원·검증 제출·멱등·재시도 계약입니다.</li>
        </ul><p class="sfh-intent"><b>경계</b><span>Sheet 목록·결제·과금·Cloudflare 유료 설정은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>공급자 경계와 방사형 관계 웹을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>기록 보존·장애 인지·관계 탐색을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>95% 진행률·P6-02 작업선·검색·노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>온라인 실패 시 기록이 유실될 수 있는 확장 경계 공백을 차단했습니다.</p></div>
        <p><a href="features/ranking-provider/">P6 랭킹 제공자 →</a> · <a href="architecture/code-module-map/">방사형 노드맵 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>실시간 코드 모듈 노드맵 · 상속·의존 양방향 추적</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 위키에서 실제 코드 상태를 모듈 노드로 보고, 사용처·의존처와 클래스 상속을 화면 크기에 맞춰 바로 추적합니다.</strong><ul>
          <li><b>자동 산출:</b> GDScript 178개에서 53개 모듈·159개 공개 클래스·157개 관계와 소스 해시를 생성합니다.</li>
          <li><b>관계:</b> 계약·조립·기능·검증 레이어, Manifest 필수 의존, 코드 로드, 테스트 참조를 선택 노드 기준 양방향으로 보여줍니다.</li>
          <li><b>상속:</b> Godot 엔진 기반과 저장소 내부 기반을 클래스별로 분리해 합성 우선 구조를 직관적으로 확인합니다.</li>
          <li><b>반응형:</b> 데스크톱 2단 비교, 태블릿·휴대폰 세로 흐름, 44px 터치·키보드·고대비·모션 감소를 지원합니다.</li>
          <li><b>회귀 차단:</b> 코드 변경 뒤 JSON 미갱신, 사라진 관계 대상, 페이지·JS·CSS 누락은 위키 빌드에서 실패합니다.</li>
        </ul><p class="sfh-intent"><b>운영 경계</b><span>읽기 전용 구조 가시화이며 게임 로직·밸런스·배포 도메인·Cloudflare 플랜·과금 모델은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>코드 스캐너와 반응형 노드 탐색기를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>모듈 관계, 상속 인지, 모바일 탐색, 접근성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>아키텍처 내비게이션·문서 노드맵·검색 우선순위를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>수동 구조 문서가 코드와 달라질 수 있던 현행성 공백을 자동 게이트로 차단했습니다.</p></div>
        <p><a href="architecture/code-module-map/">코드 모듈 노드맵 →</a> · <a href="architecture/module-rules/">모듈 규칙 →</a> · <a href="quality/wiki-responsive-e2e/">반응형 E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>P5 엄밀 모듈성 보강 · 실제 타격 계측·원자적 거래</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · P5를 “켜고 끌 수 있음”에서 실제 파일 제거·잘못된 데이터·저장 실패까지 견디는 계약으로 강화했습니다.</strong><ul>
          <li><b>실제 제거:</b> 7개 하위 서비스를 정적 <code>preload</code>하지 않고 활성 플래그일 때만 문자열 경로로 로드합니다. 꺼진 모듈의 CSV·스크립트가 없어도 P5 코어가 구성됩니다.</li>
          <li><b>데이터 정합:</b> Recipe·Codex·OperationPreset의 도면·지역·무기·스킬 ID를 Item·작전·무기·스킬 표준 ID와 맞추고 Google Sheet도 같은 값으로 동기화했습니다.</li>
          <li><b>실전 훈련:</b> 적의 실제 피해 신호를 공개 <code>record_training_hit</code> 계약에 연결해 DPS·최대 타격이 테스트 내부 호출이 아닌 플레이 타격으로 누적됩니다.</li>
          <li><b>거래 안전:</b> 제작 결과 지급·거래 기록, 상점 지급·리롤 기록 중 하나라도 실패하면 아이템·재료·크레딧을 모두 원복합니다.</li>
          <li><b>UI 책임:</b> 상점·제작·유틸·훈련·도감 선택과 문구를 전용 Presenter로 이동해 <code>Game</code>은 버튼 전달과 출력만 담당합니다.</li>
        </ul><p class="sfh-intent"><b>검증</b><span>필수 열·중복 ID·외래 ID, 내부 우회 접근, 비활성 파일 누락, 실제 타격 브리지, 강제 거래 실패 롤백을 자동 판정합니다. 과금·Cloudflare 플랜은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>지연 설치, 공개 façade, 액션 Presenter, 실전 피해 텔레메트리 브리지를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>CSV 스키마·중복·외래 ID 검사, 초안 수명, 테스트 독립성, 거래 원자성을 강화했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>Sheet·CSV 표준 ID, P5 문서, E2E 계약, 검색 우선 설명을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 5</h3><p>정적 하위 로드, 비활성 CSV 강제 검사, 가짜 훈련 계측, 거래 부분 반영, P5 UI 도메인 누수를 제거했습니다.</p></div>
        <p><a href="features/p5-hub-progression/">P5 거점 진행 →</a> · <a href="architecture/module-audit/#p5-2026-09-02">엄밀 모듈 감사 →</a> · <a href="quality/e2e-play-session/">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>P5 완전 종료 · 거점 진행 통합·모듈 감사</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 유틸리티 투자부터 작전 확정, 파산 보호, 회전 상점, 제작소, 훈련장, 도감까지 P5-03~10을 한 거점 흐름으로 연결했습니다.</strong><ul>
          <li><b>준비:</b> 가방·구급키트·공격 전지·비상 신호기와 불변 작전 초안을 연결해 편집 중 무과금, 확정 시 1회 차감을 보장합니다.</li>
          <li><b>경제:</b> 재화 0 무료 프리셋, 손상·표준·고성능 회전 매물, 복귀 갱신·유료 재굴림, 거래 중복 차단을 구현했습니다.</li>
          <li><b>성장:</b> 반출 도면 영구 등록·옵션/소켓 제작, 단일·밀집 훈련 계측, 도감 진행·지역 힌트·재접속 유지를 구현했습니다.</li>
          <li><b>데이터:</b> Google Sheet에 6개 전용 탭과 Item 4행을 추가하고 모든 임시값을 <code>provisional</code>로 격리했습니다.</li>
          <li><b>모듈:</b> 7개 하위 서비스와 조립 서비스로 나누고 전체/개별 제거, Scene 내부 접근 금지, 60 FPS 성능 예산을 자동 판정했습니다.</li>
        </ul><p class="sfh-intent"><b>다음</b><span>P5는 종료했습니다. 다음 작업은 P6-01 랭킹 제공자 경계이며 결제 상품·Cloudflare 플랜·유료 설정은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 8</h3><p>유틸·초안·파산 정책·상점·제작·훈련·도감·거점 UI를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>플레이 전 비교, 중복 차감 방지, 재접속, 데이터 교체성, 모듈 제거성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>진행률 94%, 작업선 P6-01, 검색, E2E, 전체 문서 맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>실제 전리품 Dictionary 수량을 도감에서 읽을 때 발생하던 런타임 오류를 수정했습니다.</p></div>
        <p><a href="features/p5-hub-progression/">P5 거점 진행 →</a> · <a href="architecture/module-audit/#p5-0310-2026-09-02">모듈 감사 →</a> · <a href="quality/e2e-play-session/">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>P5-02 무기·스킬 런 투자 · 실전 복원</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 작전 전에 주·보조무기와 스킬 3칸의 가격·소유·해금·태그를 비교하고, 이번 런 구매부터 실전 발동과 거점 복원까지 한 흐름으로 연결했습니다.</strong><ul>
          <li><b>선택 UI:</b> 브리핑에 주무기·보조무기·S1~S3 선택, 개별 상태, 로드아웃 추가 비용과 출격 가능 여부를 압축 표시합니다.</li>
          <li><b>거래:</b> 캐릭터와 로드아웃 추가 비용을 작전 계약이 한 번만 합산하며, 미해금·태그 불일치는 차감 전에 출격을 차단합니다.</li>
          <li><b>실전:</b> 런 구매한 펄스 소총과 아크 대시를 장비·스킬 공개 계약으로 교체하고 성공·사망·롤백 뒤 준비 상태를 복원합니다.</li>
          <li><b>데이터:</b> Weapon·Skill Sheet에 가격·기본 소유·해금·허용 슬롯 열을 추가하고 실시간 시험→확정 CSV→Web payload 계약을 유지했습니다.</li>
          <li><b>검증:</b> 소유/잠김/런 구매, 1회 차감, 태그, 실전 무기·스킬, 거점 복원과 대형 성능 예산을 자동 판정했습니다.</li>
        </ul><p class="sfh-intent"><b>임시 기획값</b><span>펄스 소총 80C·아크 대시 60C는 `temporary` 데이터입니다. 확정 시 Sheet와 CSV만 교체하며 Cloudflare 플랜·과금 설정은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>카탈로그·선택 서비스·브리핑·작전 결제·런타임 장비/스킬 교체와 복원을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>투자 비교, 잠김 피드백, 데이터 교체성, 플레이어 인식 E2E를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>작업선·진행률·기획 요청·검색·노드맵을 P5-03 착수 기준으로 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>소형 작전에서 임시 로드아웃 가격이 보상 용량을 넘던 값을 플레이 가능한 140C로 보정했습니다.</p></div>
        <p><a href="features/loadout-investment/">무기·스킬 투자 계약 →</a> · <a href="architecture/module-audit/#p5-02-2026-09-02">모듈 감사 →</a> · <a href="quality/e2e-play-session/">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>P5-01 캐릭터 투자 · Windows 최신본 보존</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 작전 전에 캐릭터 가격과 패시브를 비교해 선택하고, 배포 저장소에는 검증된 최신 Windows 다운로드만 남깁니다.</strong><ul>
          <li><b>캐릭터:</b> 선봉대·질주자·방벽병 3종을 브리핑에서 순환하고 추가 투입 비용과 패시브를 즉시 확인합니다.</li>
          <li><b>실전 인과:</b> 캐릭터 비용은 총 견적에 한 번만 합산되고 선택 효과는 최대 체력·방어력·이동 속도 런타임 소스로 적용됩니다.</li>
          <li><b>데이터:</b> Google Sheet `Character` 12열과 확정 CSV·Web payload를 같은 공급자 계약으로 연결했으며 현재 값은 기획 교체 가능한 임시값입니다.</li>
          <li><b>보존:</b> 새 ZIP·SHA-256의 Cloudflare E2E가 성공한 뒤에만 R2 `downloads/`의 이전 Windows 파일을 삭제합니다. 로컬 패키징도 현재 버전만 유지합니다.</li>
          <li><b>검증:</b> 캐릭터 변경→견적→실전 패시브, 9개 작전 조합, Windows 정리 범위와 dry-run을 자동 판정합니다.</li>
        </ul><p class="sfh-intent"><b>안전 경계</b><span>게임 Web 릴리스·위키·백업·다른 R2 객체·Cloudflare 플랜과 결제 설정은 정리 대상이 아닙니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>캐릭터 Definition/Table/Service, 브리핑 선택·패시브 적용, 로컬·R2 최신본 보존을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>작전 전 비교 가능성, Sheet 교체성, 다운로드 저장 공간 관리를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>P5 작업선과 기획 요청을 P5-02 착수 기준으로 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>신규 결함 수정 없이 기능·배포 보존 범위만 확장했습니다.</p></div>
        <p><a href="features/character-selection/">캐릭터 선택 계약 →</a> · <a href="getting-started/run-project/">Windows 보존 규칙 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>Master GDD v1005 재대조 · P7 이후 작업선 세팅</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획자가 확정한 로비 허브·상점·제작소·훈련장 범위를 새 기준선으로 삼고, 공식 Phase 1~6 뒤 내부 P7~P10을 바로 착수 가능한 계약으로 준비했습니다.</strong><ul>
          <li><b>원문:</b> 공개 Notion을 root v1005·77블록·해시 <code>67f9bef85449</code>로 갱신하고 0~10장을 다시 대조했습니다.</li>
          <li><b>신규 범위:</b> 손상·표준·고성능 상점 매물, 런 종료 회전·리롤, 설계도 맞춤 제작, 단일·밀집 훈련 더미, DPS·AP·쿨타임 계측, 도감 힌트를 확정 요구로 반영했습니다.</li>
          <li><b>진행률:</b> 10개 기획 묶음·가중치 15 기준 79%입니다. 기존 87% 대비 하락은 구현 퇴행이 아니라 20개 신규 블록과 훈련장 0%가 분모에 추가된 결과입니다.</li>
          <li><b>P7+:</b> Notion 공식 Phase는 1~6으로 유지하고, 저장소 내부 후속 ID로 P7 경제→P8 훈련→P9 도감·프리셋→P10 출시 후보 회귀를 세팅했습니다.</li>
          <li><b>자동 게이트:</b> P7 로드맵의 원문 버전·블록 근거·모듈·데이터 게이트·플레이어 결과·E2E 인과를 위키 빌드에서 검사합니다.</li>
        </ul><p class="sfh-intent"><b>데이터·과금 경계</b><span>실제 목록이 필요해질 때만 ShopOffer·Recipe·TrainingScenario·Codex Sheet를 확장합니다. 결제·유료 재화·Cloudflare 유료 플랜은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>이번 묶음은 기능 구현이 아닌 후속 작업 계약 세팅이며 완료율로 올리지 않았습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>기획 출처 추적, P7 이후 착수성, 기획자 데이터 요청 가시성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>Notion 스냅샷, 79% 산식, 확장 P5·P6, 검색 우선순위, 전체 문서 노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>구형 v797 스냅샷이 최신 기획을 대표하던 문서 기준선 오류를 제거했습니다.</p></div>
        <p><a href="design/master-gdd-alignment/">최신 GDD 대조 →</a> · <a href="design/p7-plus-preimplementation/">P7 이후 사전 설계 →</a> · <a href="design/current-milestone-workline/">작업 순서 →</a></p>
      </div>
    </details>
  </div>
</details>
</div>

<div data-sfh-knowledge-map-host></div>

## 검색 요령

상단 검색창 또는 `/` 키를 사용합니다. `Q키`, `구글 시트`, `가방`, `모듈 코스트`, `소분류`, `미니맵`, `탈출`, `버그픽스`처럼 기능·입력·증상 단어로 검색할 수 있습니다.

검색 전 TOP 10, 기획 영역 바로가기와 개인 탐색 순위의 동작은 [위키 실시간 검색 사용법](getting-started/search-wiki.md)에서 확인합니다.
