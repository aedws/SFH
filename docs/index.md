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
        <b>87%</b>
      </div>
      <div class="sfh-progress-track" role="progressbar" aria-label="SFH 기획 진행도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="87"><i style="width: 87%"></i></div>
      <p>Master GDD 8개 확정 시스템 · Phase 1~4 완료 · 저장소 구현/E2E 가중 산식 87%</p>
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

<div class="sfh-release-stats"><span>최신 2026-09-01</span><span>SEARCH COMMAND</span><span>1 DAY · 19 TOPICS</span><span>69 DOCS · CLOUDFLARE LIVE</span></div>

<div class="sfh-notes">
<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-09-01</b><i class="sfh-latest">최신</i><small>19 UPDATE BUNDLES · BUILD 63 · IMPROVE 75 · CHANGE 91 · FIX 29</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview">
      <span><b>19</b><small>UPDATE BUNDLES</small></span><span><b>63</b><small>BUILD</small></span><span><b>75</b><small>IMPROVE</small></span><span><b>91</b><small>CHANGE</small></span><span><b>29</b><small>FIX</small></span>
    </div>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 19</small><b>9개 작전 조합 복구 · P4-06 전리품 정산 · 진행도 87%</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 소형·표준 외 작전이 생성 직후 거점으로 돌아오던 문제를 제거하고, 획득 전리품의 성공·사망 결말을 실제 정산까지 연결했습니다.</strong><ul>
          <li><b>버그픽스:</b> 2.5~5배 회수 목표를 박스 수·단가로 실제 배치 가능한 범위와 교차해 중형·대형·고난이도 조립 실패를 제거했습니다.</li>
          <li><b>9조합 E2E:</b> 난이도 버튼·맵 카드·투입 버튼으로 소·중·대형×표준·숙련·악몽을 모두 실행하고 전투 유지·명시적 복귀를 확인합니다.</li>
          <li><b>P4-06:</b> 탈출 시 자동 환전·영구 해금·창고 보관, 사망 시 소실, 동일 run_id 중복 지급 방지를 분리 서비스로 구현했습니다.</li>
          <li><b>플레이어 인식:</b> 성공 화면은 환전·해금·창고, 실패 화면은 전리품 소실 종류·수량을 직접 표시합니다.</li>
          <li><b>다음:</b> Phase 4는 완료했으며, P5-01 캐릭터 선택부터 남은 9개 패킷을 진행합니다.</li>
        </ul><p class="sfh-intent"><b>데이터·과금 경계</b><span>기존 Item 15종으로 충분해 Sheet를 늘리지 않았고 과금·결제 모델은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>정산 서비스·Manifest 조립·성공/사망 결과·중복 방지 계약을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>9조합 UI E2E, 플레이어 결과 인식, 조립 오류 가시성, P5·P6 사전 설계를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 8</h3><p>진행률·마일스톤·검색·노드맵·품질 문서·CI 필수 검사를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>불가능한 전리품 목표로 인한 거점 회귀와 조립 실패 원인이 거점 문구에 덮이던 문제를 해결했습니다.</p></div>
        <p><a href="features/run-settlement/">런 전리품 정산 →</a> · <a href="design/p5-p6-preimplementation/">P5·P6 사전 설계 →</a> · <a href="quality/e2e-play-session/">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 18</small><b>P4-05 RunAsset 세션 소켓 · 진행도 80%</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획 수치가 없어도 임시값을 데이터로 격리해 룬·코어·유물을 실제 작전 전투에 연결했습니다.</strong><ul>
          <li><b>플레이:</b> 현장 세션 자산에 접근해 F로 런 소켓 장착, 즉시 피해·쿨다운·이동 변화, RUN ONLY HUD 버튼 해제를 수행합니다.</li>
          <li><b>임시값:</b> 룬 2·코어 1·유물 1, 동일 아이템 1개, 오래된 항목 교체이며 기획 확정 시 데이터만 교체합니다.</li>
          <li><b>Sheet:</b> 새 `RunAsset` 14열·3규칙을 확정 CSV·Web payload·Windows 데이터 해시에 연결했습니다.</li>
          <li><b>검증:</b> 실제 F→전도 룬 피해 증가→HUD 해제→원복, 중복 제한, 런 초기화, 모듈 단독 제거를 자동 판정합니다.</li>
          <li><b>다음:</b> 남은 10개 중 P4-06 자동 환전·영구 해금·사망 소실이 바로 다음입니다.</li>
        </ul><p class="sfh-intent"><b>기획 요청</b><span>DATA-P4-05-01은 더 이상 개발 차단이 아니며, 확정 답변을 받으면 RunAsset·Item 값만 교체합니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 6</h3><p>RunAsset 데이터, 소켓 규칙·서비스, 반응형 HUD, 세 효과, 현장 F 연결을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>런 전용 의미, 기획 교체성, HUD 밀도, Web 폴백, 플레이어 인식 E2E를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 7</h3><p>Manifest·전투 modifier·내보내기·릴리스 메타·마일스톤·검색·노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>영구 장비 모듈과 런 전용 자산의 책임 혼합 가능성을 제거했습니다.</p></div>
        <p><a href="features/session-sockets/">세션 소켓 →</a> · <a href="development-status/#_1">남은 작업 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 17</small><b>남은 11개 작업 패킷 · Master GDD 진행도 78%</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 공개 기획과 현재 main을 다시 대조해 완료 수치와 후속 순서를 같은 기준으로 정리했습니다.</strong><ul>
          <li><b>원문:</b> 공개 Notion v797·57블록·해시 `b22dce53d706`은 유지됐고 Phase 1~6 체크 6개가 모두 활성 상태입니다.</li>
          <li><b>진행도:</b> P4-04A/B 현장 무기·스킬 교체를 전리품 항목 40%로 반영해 가중 산식을 75%에서 78%로 수정했습니다.</li>
          <li><b>남은 범위:</b> P4-05~06 2개, P5-01~05 5개, P6-01~04 4개로 총 11개 구현 패킷입니다.</li>
          <li><b>즉시 순서:</b> P4-05 세션 소켓 → P4-06 자동 환전/해금/소실 → P5 로비 4대 세팅 → P6 비동기 시즌입니다.</li>
          <li><b>기획 요청:</b> P4 소켓 수치, P5 캐릭터·유틸리티 목록, P6 온라인 운영 정책을 역할형 카드로 분리했습니다.</li>
        </ul><p class="sfh-intent"><b>완료 판단</b><span>Notion 체크는 확정 범위의 근거이고, 실제 완료는 코드·데이터·플레이어 인식 E2E로만 판정합니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>이번 묶음은 기능 추가 없이 현행 구현 근거를 재감사했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>남은 작업 가독성과 기획자 선행 데이터 가시성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>진행률, 산식, 마일스톤, 검색 우선순위를 P4-04B 이후 기준으로 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>Notion Phase 체크가 미체크라고 남아 있던 오래된 상태 설명을 수정했습니다.</p></div>
        <p><a href="development-status/#_1">남은 작업표 →</a> · <a href="design/master-gdd-alignment/">진행 산식 →</a> · <a href="design/current-milestone-workline/">실행 순서 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 16</small><b>P4-04B 현장 스킬 교체 · 결정 계보형 협업 위키</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 방 보상 스킬을 즉시 교체하고, 기획 요구의 원본·결정·검증 계보를 위키 한 화면에서 추적합니다.</strong><ul>
          <li><b>현장 스킬:</b> 아크 질주의 슬롯·키·ENERGY·CD·충전을 비교한 뒤 R로 3번 스킬을 교체합니다.</li>
          <li><b>안전 복구:</b> 기존 스킬 정의·쿨다운·충전·Action을 런에만 보관하고 거점 복귀 전 복원합니다.</li>
          <li><b>Sheet:</b> 새 `Skill` 14열·4행과 `LootTable` 29행을 확정 CSV·Web PCK·Windows 메타데이터에 연결했습니다.</li>
          <li><b>협업 위키:</b> Notion 57블록 v797 해시, source anchor, DEC, supersedes/conflict, 로컬 제안 초안기를 추가했습니다.</li>
          <li><b>배포 안전:</b> `sfh-game.play-preview.dev`는 미등록이므로 목표로 고정하되 현행 Worker를 유지하고 과금·구매를 건드리지 않았습니다.</li>
        </ul><p class="sfh-intent"><b>다음 작업</b><span>P4-05 런 전용 룬·코어·유물 소켓. 수치·목록 확정이 필요하면 기존 권한에 따라 Google Sheet를 확장합니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>스킬 정의·교체 서비스·시트 동기·복구 스택·제안 초안기를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 6</h3><p>현장 판단 정보, 키 연속성, 기획 출처, 결정 이력, 역할 전달, 모바일 입력성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 8</h3><p>Manifest·빌드 CSV·E2E·마일스톤·검색·노드맵·요청 JSON·배포 표면 원장을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>런 키 영구 저장, 미등록 도메인 즉시 절체, 추천 검색이 실제 색인을 시작하지 않는 회귀를 차단했습니다.</p></div>
        <p><a href="features/field-loot-skill-swap/">현장 스킬 교체 →</a> · <a href="design/wiki-collaboration-workflow/">협업 운영 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 15</small><b>P4-04A 현장 무기 즉시 장착 · 역할형 협업 위키</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 방 보상 무기를 R로 바로 사용하고, 위키 첫 화면에서 기획자와 AI 개발자의 다음 행동을 분리합니다.</strong><ul>
          <li><b>현장 교체:</b> 전격 펄스 소총을 Weapon·LootTable에 추가하고 R 즉시 장착, F 런 보관, ESC 보류를 분리했습니다.</li>
          <li><b>안전 정책:</b> 기존 무기는 런 임시 보관 뒤 거점 복귀 전에 복구해 미확정 영구 해금·소실을 만들지 않습니다.</li>
          <li><b>협업 위키:</b> 담당 역할·차단·상태·수락 기준·Sheet 위치·검증 근거·Notion 확인 시각과 역할 필터를 추가했습니다.</li>
          <li><b>다음 작업:</b> P4-04B 현장 스킬 즉시 교체 뒤 P4-05 세션 소켓, P4-06 정산으로 진행합니다.</li>
        </ul><p class="sfh-intent"><b>모듈 판단</b><span>장착 정의·정책·변경 서비스·획득 조정·표시를 분리하고 유료 협업 기능은 추가하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>무기 정의·장착 카탈로그·교체 서비스·R 입력을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>위키 역할 필터, 최신성, 담당자, 수락 기준, 검증 근거를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>Sheet·CSV·Manifest·키 설정·마일스톤을 P4-04A 기준으로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>별도 결함 수정 없이 미확정 정책의 선행 적용을 구조적으로 차단했습니다.</p></div>
        <p><a href="features/field-loot-immediate-equip/">현장 즉시 장착 →</a> · <a href="design/wiki-collaboration-workflow/">협업 개선안 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 14</small><b>기획 요청 허브 · P4-03 현장 비교·획득 · Sheet 상시 확장 규칙</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 기획자는 위키 첫 화면에서 지금 결정할 항목을 보고, 플레이어는 방 보상 전리품을 확인한 뒤 보류하거나 획득할 수 있습니다.</strong>
          <ul>
            <li><b>기획 요청:</b> 작업 요청·밸런스 데이터·완료 안내를 요청 ID로 분리하고 각 카드에서 공개 Notion 근거 작성 위치로 이동합니다.</li>
            <li><b>상시 데이터 권한:</b> 앞으로 새 열거형 목록이 필요한 모든 작업은 별도 재승인 없이 Google Sheet→실시간 시험→확정 CSV 구조를 확장합니다.</li>
            <li><b>P4-03:</b> 방 확보 뒤 전리품 신호에 접근하면 현재 무기·후보 등급·보유 수량과 탈출·사망 결과를 비교합니다.</li>
            <li><b>선택:</b> ESC는 전리품을 월드에 유지한 채 패널만 닫고, 재접근 뒤 F는 런 임시 보관으로 이동합니다.</li>
            <li><b>E2E:</b> 실제 ESC/F를 포함해 플레이어 인식 25개·인과 흐름 7개와 독립 모듈 제거를 검증합니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 판단</b><span>비교·월드 신호·표시·획득을 분리하고 P4-04 장비 교체와 P4-06 정산을 호출하지 않습니다. 이번 단계는 기존 Item 15개·LootTable 27행으로 충분해 Sheet 목록을 늘리지 않았습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 6</h3><p>비교 서비스·월드 드랍·반응형 패널·획득 서비스·요청 데이터·Notion 연결 렌더러를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>기획 전달, 밸런스 요청 분리, 전리품 판단, 화면 점유, 데이터 확장 인계성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>Manifest·방 보상 조립·마일스톤·검색·노드맵·위키 검증선을 P4-03 완료로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>비교를 취소하면 전리품까지 사라질 수 있는 오해를 ESC 보류·월드 유지 계약으로 차단했습니다.</p></div>
        <p><a href="features/field-loot-acquisition/">현장 전리품 →</a> · <a href="design/planner-request-workflow/">기획 요청 운영 →</a> · <a href="quality/e2e-play-session/">E2E →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>지역·난이도 타겟 파밍 · 안개 문턱 UX · 위키 최신순</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 작전 전에 목표 전리품을 판단하고, 방에서 통로로 나갈 때 시야가 갑자기 끊기지 않습니다.</strong>
          <ul>
            <li><b>타겟 파밍:</b> 새 <code>LootTable</code> Sheet의 세 지역 27행을 지역·난이도·규모·적/방/금고/보스 출처로 필터링합니다.</li>
            <li><b>진입 판단:</b> <code>TARGET LOOT</code>에 대표 전리품 3개, 후보 수, 최고 등급을 표시하고 같은 seed 추첨을 재현합니다.</li>
            <li><b>안개 편의:</b> 문턱 0.55초 유예, 220px 주변 시야, 320px 안심 외곽과 정면 방향 보간을 적용했습니다.</li>
            <li><b>E2E:</b> 플레이어 인식 24개·인과 흐름 6개로 확장하고 대형 교전 평균 6.882ms를 확인했습니다.</li>
            <li><b>위키:</b> 홈은 당일 최신 작업부터 역순 표시하고 저장소·편집 UI를 포함한 GitHub 역링크를 모두 제거했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 판단</b><span>드랍 정의·CSV 파서·공급자·생명 주기·브리핑·안개 상태·Shader를 분리했습니다. P4-03 월드 드랍은 공개 추첨 결과만 소비합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>전리품 행·테이블·설정·결정적 공급자·작전 타겟 브리핑을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>지역 파밍 판단, 문턱 시야 연속성, 정면 가독성, Web 데이터 추적, 기획 검색을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>Manifest·작전 조립·E2E·성능 문서·마일스톤·홈 일일 묶음 순서를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>잘못된 지역 태그 수용, 문턱 밝기 단절, 위키 GitHub 역링크와 오래된 최신순 판정을 차단했습니다.</p></div>
        <p><a href="features/loot-tables/">지역·난이도 전리품 →</a> · <a href="features/fog-of-war/">전장의 안개 →</a> · <a href="quality/e2e-play-session/">E2E →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 12</small><b>전리품 생명 주기 P4-01 · Item Sheet 15종 · 탈출·사망 결과 계약</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 전리품을 줍기 전부터 이번 런 사용, 영구 해금, 자동 환전과 사망 소실 결과를 일관된 데이터로 알 수 있습니다.</strong>
          <ul>
            <li><b>두 분류:</b> 파츠·모듈·소모품·크레딧·도면은 영구 자산 후보, 룬·코어·유물은 이번 런 증폭 후 탈출 자동 환전 자산으로 분리했습니다.</li>
            <li><b>15개 목록:</b> Google Sheet <code>Item</code> 탭에 기존 9개, 도면 3개, 세션 자산 3개와 생명 주기 7열을 추가하고 같은 16열 확정 CSV를 만들었습니다.</li>
            <li><b>결과 계약:</b> 성공 시 창고·지갑·영구 해금·자동 환전, 사망 시 획득분 소실을 순수 결과로 계산합니다.</li>
            <li><b>플레이어 표시:</b> 브라우저 이모지 깨짐을 피한 단색 기호와 짧은 문구로 영구/이번 런·탈출·사망 결과를 제공합니다.</li>
            <li><b>다음 단계:</b> 지역 태그는 후보만 동결했으며 실제 지역·난이도별 드랍 확률은 P4-02에서 연결합니다.</li>
          </ul>
          <p class="sfh-intent"><b>안전 경계</b><span>서비스는 인벤토리·프로필·크레딧을 직접 수정하지 않으며 Cloudflare 과금·결제·배포 자원도 변경하지 않았습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 6</h3><p>Definition, Table, Service, Config, Presenter, Sheet 동기화 검사를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>기획 입력성, 탈출 결과 이해, 실시간/확정 공급자 일치, Web 배포 데이터 추적을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>Manifest, 작전 밸런스 모드, export, release 해시, P4 작업 라인을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>상충 생명 주기와 잘못된 실시간 CSV가 정상 카탈로그를 오염시키지 않도록 차단했습니다.</p></div>
        <p><a href="features/loot-lifecycle/">전리품 생명 주기 →</a> · <a href="design/current-milestone-workline/">P4 작업 라인 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>배포 표면 분리 · Notion 75% 재확인 · 보안 모듈 재감사</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 문서를 여는 주소, 게임을 실행하는 주소, 원본을 보관하는 공간을 서로 다른 책임으로 고정했습니다.</strong>
          <ul>
            <li><b>문서:</b> 기존 <code>sfh-dev-wiki.pages.dev</code>는 검색·기획·개발 현황만 제공하며 게임 WASM/PCK를 위키 산출물에 섞지 않습니다.</li>
            <li><b>플레이:</b> 모든 PLAY 버튼은 별도 <code>sfh-game.vstock-market.workers.dev</code>를 새 탭으로 직접 열고, 위키의 <code>/play/*</code>는 이전 링크용 302 호환 경로로만 남깁니다.</li>
            <li><b>보관:</b> R2 <code>sfh-game-artifacts</code>는 공개 주소가 없는 Worker 전용 원본 저장소이며 런타임과 다운로드를 서로 겹치지 않는 prefix로 분리합니다.</li>
            <li><b>기획:</b> 공개 Master GDD 0~8장을 다시 읽은 결과 요구 범위 변화가 없어 진행도는 <b>75%</b>를 유지합니다. 다음 기능 작업은 P4-01 전리품 생명주기 계약입니다.</li>
            <li><b>안전:</b> Private 저장소 이중 백업·복구 PR·Actions SHA 고정과 Cloudflare secret 경계를 다시 검사했습니다. 새 서비스나 과금 설정은 추가·변경하지 않습니다.</li>
          </ul>
          <p class="sfh-intent"><b>주소 식별</b><span><code>vstock-market</code>는 이 계정의 Workers.dev 하위 도메인일 뿐 기존 VStock 서비스 재사용을 뜻하지 않습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>배포 표면 원장, 자동 경계 검사, Worker 응답 표면 식별 헤더를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>직접 플레이 동선, 문서 전용 Pages 산출물, 주소 의미, 반응형 표면 지도, 다음 마일스톤 인계성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>플레이 링크, R2 prefix 인자, GDD 재확인 기록, P4-01 작업 패킷, 보안·모듈 감사표를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>상대 <code>/play/</code> 링크가 위키와 게임을 같은 배포로 오인시키던 문제와 노드맵의 오래된 72% 요약을 바로잡았습니다.</p></div>
        <p><a href="getting-started/run-project/#cloudflare">배포 표면 계약 →</a> · <a href="design/master-gdd-alignment/">Master GDD 재대조 →</a> · <a href="design/current-milestone-workline/">다음 작업 라인 →</a> · <a href="architecture/module-audit/">보안·모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>Private 저장소 복구망 · 변경 직전·검증 완료 이중 백업</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 문제가 생겨도 검증된 시점으로 이력을 지우지 않고 PR로 복귀할 수 있습니다.</strong>
          <ul>
            <li><b>변경 직전:</b> 모든 <code>main</code> push 이전 커밋을 <code>backup/pre-main/&lt;전체 SHA&gt;</code>에 자동 보존합니다.</li>
            <li><b>검증 완료:</b> 게임·위키·Cloudflare E2E를 통과한 커밋만 <code>backup/verified-main/&lt;전체 SHA&gt;</code>에 추가 보존합니다.</li>
            <li><b>안전 복구:</b> 허용된 백업 이름과 실제 SHA를 재검증한 뒤 복구 브랜치에 트리 복원 커밋을 만들고 PR로 제출합니다.</li>
            <li><b>이력 보존:</b> reset·강제 푸시·<code>main</code> 직접 덮어쓰기를 사용하지 않으며 복구 PR도 기존 필수 검사를 다시 통과해야 합니다.</li>
            <li><b>범위 고정:</b> 저장소는 Private을 유지하고 Cloudflare 프로젝트·R2·과금 플랜·결제 설정은 변경하지 않습니다.</li>
          </ul>
          <p class="sfh-intent"><b>현재 제한</b><span>GitHub Free Private 저장소는 서버 측 Ruleset 강제가 지원되지 않아 PR 관례와 불변 백업으로 보완합니다. 공개 전환이나 유료 플랜 변경은 하지 않습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>변경 직전 백업, 검증 완료 백업, PR 복구 워크플로, 정적 계약 검사를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>장애 복귀성, 커밋 추적성, Actions PR 권한 제한 시 수동 폴백을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>Private 운영 규칙, 백업 네임스페이스, 복구 검증선, 배포 후 기준점 기록을 명문화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>자동 PR 권한이 꺼진 저장소에서 복구 브랜치만 남고 다음 동선을 알 수 없던 상태를 compare URL 출력으로 보완했습니다.</p></div>
        <p><a href="getting-started/run-project/#private-repository-backup">백업·복구 절차 →</a> · <a href="architecture/module-audit/#private-repository-backup-audit">복구 모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>Cloudflare 운영 전환 · 직접 플레이·Windows 다운로드</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 검증된 main 산출물을 Cloudflare 정식 경로에서 바로 플레이하고 다운로드합니다.</strong>
          <ul>
            <li><b>정식 주소:</b> 위키는 기존 <code>sfh-dev-wiki.pages.dev</code>를 유지하고, 게임은 <code>sfh-game.vstock-market.workers.dev</code>에서 제공합니다.</li>
            <li><b>동일 산출물:</b> Actions 실행 33470418826의 Web·Windows·위키 산출물만 R2·Worker·Pages에 배포했으며 Worker 상태의 커밋과 빌드 커밋이 일치합니다.</li>
            <li><b>실제 검증:</b> 게임 Canvas 로딩, WASM Range 206, COOP·COEP, Windows ZIP 재다운로드와 SHA-256 일치를 통과했습니다.</li>
            <li><b>직접 다운로드:</b> 홈과 README가 Windows ZIP과 체크섬을 분리 제공해 Actions 화면을 거치지 않습니다.</li>
            <li><b>안전 경계:</b> 새 <code>sfh-game-artifacts</code> 버킷만 사용했고 기존 Cloudflare 프로젝트·버킷과 과금 플랜·결제 설정은 변경하지 않았습니다.</li>
          </ul>
          <p class="sfh-intent"><b>최종 전환</b><span>Cloudflare 배포와 E2E 성공 뒤 README·위키 기준 주소를 전환하고 저장소를 Private으로 보호했으며, GitHub Pages 폴백은 종료했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>R2 운영 버킷, 커밋 고정 Worker 배포, 검증 산출물 직접 다운로드 경로를 구성했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>브라우저 플레이 접근성, Windows 다운로드 무결성, 배포 추적성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>README·위키 기준 URL, 다운로드 카드, MkDocs 정식 주소, GitHub Pages 폴백 조건을 운영 환경에 맞췄습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>Cloudflare 검색 진입 오류와 대용량 Godot Web 파일의 Pages 제한을 각각 검색 색인 보정과 Worker+R2 분리로 해소했습니다.</p></div>
        <p><a href="getting-started/run-project/#cloudflare">Cloudflare 운영·다운로드 규격 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>Cloudflare 무중단 이중 배포 · Worker+R2 게임 게이트웨이</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 검증된 동일 산출물만 Cloudflare 후보 환경에 올리고 기존 GitHub Pages는 유지합니다.</strong>
          <ul>
            <li><b>위키 분리:</b> MkDocs 결과만 실제 공개 프로젝트 `sfh-dev-wiki.pages.dev`에 Direct Upload하며 `/play/`는 별도 게임 Worker로 전달합니다.</li>
            <li><b>대용량 게임:</b> 39MiB WASM을 포함한 Web 빌드는 R2 `game/releases/&lt;commit&gt;/`에 불변 업로드한 뒤 `sfh-game` Worker를 전환합니다.</li>
            <li><b>다운로드:</b> Windows ZIP·SHA-256은 R2 `/downloads/v0.1.0/`에 함께 배치합니다.</li>
            <li><b>서빙 계약:</b> Worker가 COOP·COEP·CORP, MIME, ETag, Range 206, 캐시와 다운로드 헤더를 제공합니다.</li>
            <li><b>전환 게이트:</b> 위키·게임·Range·ZIP 해시 E2E가 성공할 때까지 README·기본 링크와 저장소 공개 상태를 바꾸지 않습니다.</li>
            <li><b>검색 복구:</b> 대형 홈 대시보드를 검색 색인에서 제외해 첫 선택이 홈으로 회귀하지 않고 실제 상세 문서로 이동합니다.</li>
          </ul>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>R2 업로더·manifest, 게임 Worker, Cloudflare Direct Upload/E2E 작업을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>대용량 Web 전달, 원자적 커밋 전환, Windows 다운로드 무결성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>실제 Pages 프로젝트명, 위키·게임 저장 경계, 두 배포 주소, 캐시·보안 헤더, 무중단 전환 순서를 명시했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>Pages 단일 파일 제한은 Worker+R2 분리로 해소하고, 검색 첫 결과가 홈으로 회귀하던 색인 오류는 홈 검색 제외로 차단했습니다.</p></div>
        <p><a href="getting-started/run-project/#cloudflare">Cloudflare 배포 계약 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>main 보호 · 독립 E2E · Windows x64 검증 빌드</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 검증을 우회한 main 변경을 차단하고 같은 커밋에서 브라우저와 Windows 실행물을 만듭니다.</strong>
          <ul>
            <li><b>저장소 보호:</b> main은 PR, 대화 해결, export-game·build 성공이 필요하며 직접 푸시·강제 푸시·삭제를 차단합니다.</li>
            <li><b>E2E 분리:</b> 실제 입력 플레이 검증을 독립 <code>e2e</code> 상태 검사로 승격해 병합 조건으로 추적할 수 있게 했습니다.</li>
            <li><b>Windows:</b> Godot 4.7.2 x86_64 실행 파일과 PCK를 <code>SFH-Windows-x64-v0.1.0.zip</code>으로 묶습니다.</li>
            <li><b>추적성:</b> ZIP 안에 빌드 커밋·Godot 버전·CSV 데이터 버전과 CSV별 SHA-256을 기록하고 ZIP 체크섬을 별도 제공합니다.</li>
            <li><b>공급망:</b> GitHub Actions를 전체 커밋 SHA로 고정하고 Dependabot이 매주 안전한 갱신 PR을 제안합니다.</li>
          </ul>
        </div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>독립 E2E 잡, Windows 프리셋, 릴리스 패키저, 빌드 메타데이터 계약을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>병합 안전성, 실행물 추적성, 브라우저·Windows 선택 가시성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>승인 0명 1인 개발 규칙, Actions SHA 고정, CSV 버전 원장, 단계적 Cloudflare 전환 순서를 명시했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>필수 E2E 컨텍스트가 존재하지 않은 채 보호를 켜 main이 잠길 수 있던 배포 순서 문제를 단계 적용으로 차단했습니다.</p></div>
        <p><a href="getting-started/run-project/#windows-x86_64">Windows 빌드 규격 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>위키 접근성·클릭 명확화 · Phase 1 자유 스킬 배치 완료</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 문서 탐색의 오작동을 제거하고 K 입력 설정에서 물리 키와 스킬 위치를 각각 편집할 수 있게 됐습니다.</strong>
          <ul>
            <li><b>위키:</b> 장식 연결선의 클릭 가로채기와 선택 후 포커스 소실을 제거하고 44px 터치 범위·ARIA 관계를 고정했습니다.</li>
            <li><b>홈:</b> 전체 이력은 개발 현황에 유지하고 최신 업데이트는 현재 날짜 하루만 표시합니다.</li>
            <li><b>입력:</b> `키 배치` 22개와 `스킬 배치` 1~9를 분리하고, 점유 슬롯 선택 시 스킬을 서로 교환합니다.</li>
            <li><b>실전:</b> 배치 변경이 HUD 키 표기와 실제 스킬 Action에 즉시 반영되고 별도 JSON으로 복구됩니다.</li>
            <li><b>다음:</b> Phase 4 전리품 생명주기 계약부터 순서대로 진행합니다. 신규 목록이 필요할 때만 기존 Google Sheet→확정 CSV 공급 구조를 확장합니다.</li>
          </ul>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>SkillBindingProfile, 충돌 교환·영속 Service, 전투/HUD 배치 Provider 연결을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>K 두 단계 편집, 44px 터치 범위, 스크린리더 관계, 현행 작업선 추적성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>물리 키와 스킬 위치 저장을 분리하고 홈을 최신 하루로 제한했으며 진행도를 75%로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>노드 클릭 범위 교차, 재렌더링 포커스 소실, 비활성 버튼처럼 읽히던 루트 노드 의미를 바로잡았습니다.</p></div>
        <p><a href="features/key-mapping/">자유 스킬 배치 →</a> · <a href="design/current-milestone-workline/">다음 작업 라인 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>현행 마일스톤 작업 라인 · Phase 1→4→5→6 실행 게이트</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 72% 뒤에 남은 기능을 2개 기준선·20개 Phase 작업 ID와 5개 공통 품질 게이트로 분해했습니다.</strong>
          <ul>
            <li><b>Phase 1:</b> 물리 키 설정과 스킬↔Action 배치를 분리해 자유 스킬 바인딩을 먼저 완결합니다.</li>
            <li><b>Phase 4:</b> 전리품 생명주기를 동결한 뒤 현장 교체, 런 전용 소켓, 자동 환전을 하나의 플레이 인과로 연결합니다.</li>
            <li><b>Phase 5:</b> 캐릭터·무기·스킬·유틸리티와 계약·페널티를 단일 작전 초안과 BEP 견적으로 묶습니다.</li>
            <li><b>Phase 6:</b> 로컬 랭킹 뒤에 온라인 제공자·검증·시즌·칭호/오라 보상을 순서대로 연결합니다.</li>
            <li><b>완료 기준:</b> 각 작업선은 모듈 경계, 플레이어가 인식할 결과, 자동 E2E를 모두 통과해야 다음 단계로 이동합니다.</li>
          </ul>
          <p class="sfh-intent"><b>공통 회귀선</b><span>완료된 Phase 2의 무기 교체·태그·AP·쿨타임과 Phase 3의 탈출 방어·정산을 모든 작업의 필수 게이트로 유지합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 0</h3><p>이번 변경은 실행 로드맵을 고정한 문서 작업이며 미완료 게임 기능을 구현으로 표시하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3><p>작업 선행 관계, 플레이어 완료 조건, 각 단계 E2E 추적성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 5</h3><p>착수 순서, Phase별 종료 게이트, 모듈 경계, 중단 규칙, 공통 품질선을 현행 Master GDD에 맞췄습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 0</h3><p>별도 게임 버그 수정은 없습니다.</p></div>
        <p><a href="design/current-milestone-workline/">현행 마일스톤 작업 라인 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>Master GDD 재대조 · 진행률 72% · 전리품 순환 우선순위</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 기획자의 최신 Master GDD를 확정 원문으로 다시 읽고, 유사 기반이 아닌 완성된 플레이 흐름 기준으로 진행도를 재산정했습니다.</strong>
          <ul>
            <li>기존 96%는 확정 범위가 늘어난 현재 기획을 과대평가하므로 8개 시스템·가중치 13점 기준 <b>72%</b>로 수정했습니다.</li>
            <li>새 핵심 차이는 스킬↔키 자유 배치, 현장 장비·스킬 교체, 세션 룬·코어·유물 소켓·자동 환전, 비동기 시즌 보상입니다.</li>
            <li>Phase 2·3은 완료, Phase 1·5는 부분 완료, Phase 4는 미완료, Phase 6은 로컬 기반으로 판정했습니다.</li>
            <li>다음 작업을 전리품 분류→현장 교체→세션 룬 순환→자유 바인딩→로비 4대 세팅→비동기 시즌 순으로 재배치했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>판정 원칙</b><span>Notion에 적힌 체크나 유사 클래스가 아니라 실제 코드·데이터·자동 검증으로 연결된 플레이 흐름만 완료로 인정합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 0</h3><p>이번 변경은 최신 기획 재대조와 개발 순서 정리이며 게임 기능을 완료 처리하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3><p>확정도 판정 근거와 기획자→개발자 후속 작업 추적성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 4</h3><p>진행률, 8개 시스템 산식, 6개 Phase 판정, 다음 개발 순서를 Master GDD 기준으로 수정했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3><p>이전 공개안 기준 96%가 최신 확정 범위를 반영하지 못하던 문서 불일치를 해소했습니다.</p></div>
        <p><a href="design/master-gdd-alignment/">Master GDD 상세 대조 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>모바일 위키 전면 최적화 · 전체 화면 검색 · 4단계 실브라우저 E2E</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 휴대폰에서도 기획 현황을 찾고, 개발 계약을 읽고, 관련 문서로 이동하는 전 과정을 확대 없이 완료합니다.</strong>
          <ul>
            <li><b>검색 복구:</b> 모바일에서 6px로 접히던 검색 결과 영역을 <code>100dvh</code> 기반 전체 화면 패널과 독립 스크롤로 바꿨습니다.</li>
            <li><b>읽기 최적화:</b> 320px부터 제목·본문·버튼·카드가 화면 안에 유지되고, 넓은 표와 코드는 해당 블록 안에서만 가로 스크롤합니다.</li>
            <li><b>역할 동선:</b> 홈에서 PLAN·DEV·QA·DOCS를 바로 선택하고, 전체 56개 문서를 4·2·1열 노드맵으로 탐색합니다.</li>
            <li><b>주소 안정화:</b> 검색 결과와 브라우저 플레이 링크도 현재 문서의 깊이에 영향받지 않는 <code>/SFH/</code> 루트를 사용합니다.</li>
            <li><b>실기 검증:</b> 320×568·390×844·768×1024·1440×900에서 페이지 가로 넘침 0, 검색 입력·닫기, 역할 링크, 노드 검색·이동을 실제 브라우저로 통과했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>기획↔개발 연결</b><span>기획자는 진행 현황, 개발자는 모듈 계약, 공동 검수자는 E2E 근거로 두 번 이하의 선택 안에 이동합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3><p>역할별 빠른 이동 허브와 모바일 위키 전용 실브라우저 E2E 계약·빌드 게이트를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 6</h3><p>안전 영역, 터치 목표, 본문 행 길이, 반응형 카드, 표·코드 스크롤, 고대비·감소 모션 대응을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 3</h3><p>검색을 전체 화면으로, 문서 맵을 4·2·1열로, 최신 묶음만 기본 펼침 상태로 수정했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 2</h3><p>모바일 검색 빈 화면과 데스크톱 헤더의 브라우저 플레이 버튼으로 생긴 101px 가로 넘침을 제거했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>전체 문서 노드맵 · 404 차단 · 반응형 탐색 UI</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 홈의 고정 추천 카드 대신 55개 문서를 실제 계층과 배포 주소로 탐색합니다.</strong>
          <ul>
            <li>Material 즉시 이동 뒤에도 최초 페이지의 상대 경로를 재사용하지 않고, 고정된 위키 스크립트 주소에서 배포 루트를 계산합니다.</li>
            <li>홈의 <code>자주 찾는 문서</code> 블록을 전체 노드맵의 전용 위치로 교체하고 모든 일반 문서 하단에도 같은 탐색기를 유지합니다.</li>
            <li>4열·2열·1열 반응형 레이아웃, 연결 레일, 44px급 터치 노드와 줄바꿈 요약으로 화면 폭에 따른 탐색 밀도를 정리했습니다.</li>
          </ul>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 1</h3><p>홈 전용 노드맵 마운트 지점과 전체 문서 동적 검색을 하나의 컴포넌트로 연결했습니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3><p>전체 문서 가시성, 노드 연결선, 데스크톱·태블릿·모바일 레이아웃을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 2</h3><p>추천 카드 중심 홈을 전체 계층 탐색 중심으로 바꾸고 노드 데이터 버전을 2026-09-01 기준으로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3><p>즉시 페이지 이동 후 상대 경로가 중첩되어 일부 노드가 404로 열리던 문제를 배포 루트 고정으로 차단했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>M 확장 지도 워프 · 전투 방 완주 조기 탈출 · 방 보상 박스</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 탐색을 끝낸 플레이어가 남은 시간을 기다리지 않고 보상을 회수해 탈출할 수 있습니다.</strong>
          <ul>
            <li>전투 가능한 방을 모두 확보하거나 남은 적 생성 예산으로 최소 무리를 만들 수 없으면 탈출 신호를 즉시 개방합니다.</li>
            <li><code>M</code>으로 전체 지도를 확대하고 시작·탈출·클리어한 4방향 교차 방을 클릭해 워프합니다. 봉쇄 전투 중과 미클리어 일반 방은 거부합니다.</li>
            <li>방 중앙 자동 획득 경험치 1개를 없애고, 방 크기와 난수로 1~5개의 F 상호작용 크레딧 박스를 생성합니다.</li>
            <li>대형 34기 교전에서 평균 6.894ms, 최대 8.948ms로 60 FPS CPU 예산을 유지했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 판단</b><span>지도는 4방향 연결 스냅샷, 미니맵은 표시·클릭 요청, RoomWarpSystem은 이동 검증, RoomEncounterSystem은 교전·보상 정책만 소유합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">전투 방 완주 조기 탈출</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>시간 개방과 동일한 탈출 잠금 계약을 재사용해 완주 즉시 방어전을 시작할 수 있습니다.</p><a href="features/raid-setup-extraction/">탈출 규격 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">M 확장 전술 지도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>평소에는 저점유 미니맵, M 입력 뒤에는 후보를 클릭하는 반응형 전체 지도로 전환합니다.</p><a href="features/minimap/">지도 규격 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">조건부 방 워프 서비스</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>시작·끝 지역과 클리어한 4방향 교차 방만 허용하고 방 봉쇄 중 이동을 차단합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">1~5개 크레딧 보상 박스</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방 면적 보정과 난수를 결합하고 F로 직접 회수해야 휴대 크레딧에 반영됩니다.</p><a href="features/room-encounters/">방 보상 규격 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 4</h3><p>탐색 종료 동선, 전체 지도 조작성, 보상 회수 감각, 실제 입력 E2E를 함께 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 3</h3><p>방 보상을 내부 경험치에서 크레딧으로, 키 카탈로그를 22개 Action으로, 맵 스냅샷을 방향 연결 정보 포함 형태로 수정했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3><p>확장 지도 초기 레이아웃에서 0 이하 크기 사각형이 생길 수 있던 클릭 판정을 양수 영역으로 보정했습니다.</p></div>
      </div>
    </details>
  </div>
</details>
</div>

<div data-sfh-knowledge-map-host></div>

## 검색 요령

상단 검색창 또는 `/` 키를 사용합니다. `Q키`, `구글 시트`, `가방`, `모듈 코스트`, `소분류`, `미니맵`, `탈출`, `버그픽스`처럼 기능·입력·증상 단어로 검색할 수 있습니다.

검색 전 TOP 10, 기획 영역 바로가기와 개인 탐색 순위의 동작은 [위키 실시간 검색 사용법](getting-started/search-wiki.md)에서 확인합니다.
