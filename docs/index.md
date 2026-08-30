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
        <b>71%</b>
      </div>
      <div class="sfh-progress-track" role="progressbar" aria-label="SFH 기획 진행도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="71"><i style="width: 71%"></i></div>
      <p>제공된 기획 원문 재대조 · 확정 전투 3× · 코어 루프 2× · 기타 1×</p>
      <a href="development-status/#_1">산정 근거 확인 →</a>
      <a href="https://wobbly-pawpaw-1ff.notion.site/SFH-6b45b728004082af8a4a811ef0a1c5e9">공개 기획 원본 ↗</a>
    </div>
    <header><strong>현재 빌드 상태</strong><b class="sfh-live">PLAYABLE</b></header>
    <p>거점에서 지역·난이도·페널티·소모품을 준비하고, 투입 비용을 지불해 전투·파밍·탈출 방어·영구 정산 뒤 복귀합니다.</p>
    <div class="sfh-operation-grid">
      <span><b>3</b><small>MAP TIERS</small></span>
      <span><b>1·2·3·⇧·Q·F</b><small>ACTIVE INPUTS</small></span>
      <span><b>PASS</b><small>SMOKE TEST</small></span>
    </div>
  </aside>
</section>

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

<div class="sfh-release-stats"><span>최신 2026-08-30</span><span>DAILY ROLLUP</span><span>1 DAY · 12 TOPICS</span><span>기획 진행도 71% · 원문 재대조</span></div>

<div class="sfh-notes">
<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-08-30</b><i class="sfh-latest">최신</i><small>12 UPDATE BUNDLES &middot; BUILD 24 &middot; IMPROVE 15 &middot; CHANGE 9 &middot; FIX 2</small></span><em class="sfh-chevron">&#x2303;</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview">
      <span><b>12</b><small>UPDATE BUNDLES</small></span>
      <span><b>24</b><small>BUILD</small></span>
      <span><b>15</b><small>IMPROVE</small></span>
      <span><b>9</b><small>CHANGE</small></span>
      <span><b>2</b><small>FIX</small></span>
    </div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>하루 단위 업데이트 압축 · 일일 합계 · 중복 방지 검사</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 날짜당 카드 하나</strong>
          <ul>
            <li>같은 날짜에 분리되어 있던 업데이트를 하루 카드 하나로 통합했습니다.</li>
            <li>하루 카드에서는 구현·개선·수정·버그픽스 합계와 주제 수를 먼저 확인합니다.</li>
            <li>상세 기록은 주제별 묶음으로 접어 필요한 내용만 펼칩니다.</li>
            <li>같은 날짜 카드가 다시 중복되면 위키 빌드가 실패하도록 검사합니다.</li>
          </ul>
          <p class="sfh-intent"><b>개선 의도</b><span>업데이트가 많아져도 날짜 목록은 짧게 유지하면서 상세 기록과 검색 가능성은 보존합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">일일 릴리스 롤업</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>날짜→주제→세부 항목의 3단계 구조로 업데이트 위키를 압축했습니다.</p><a href="development-status/">전체 업데이트 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>거점 I 가방 · U/E 장비 조회 · Q 무기 선택 유지</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 거점 준비 단축키</strong>
          <ul>
            <li>거점에서도 I 가방과 U/E 장비·모듈·파츠 화면을 열어 현재 구성을 확인합니다.</li>
            <li>거점 장비 화면은 조회 전용으로 장착·레벨업·강화·개조 변경을 차단합니다.</li>
            <li>Q로 선택한 메인·보조 무기 슬롯은 전투 세션에 유지되고 귀환 후에도 다시 확인할 수 있습니다.</li>
            <li>게시된 Notion을 향후 기획 진행도 점검의 권위 있는 공개 원본으로 지정했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결론</b><span>키 매핑, 패널 열기, 조회 전용 차단, 출격 선택 유지와 귀환 재설치를 자동 검증했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">거점 로드아웃 조회</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>I·U/E·Q 준비 동선을 전초기지에 연결하고 전투 UI 모듈을 조회 모드로 재사용합니다.</p><a href="features/start-hub/">거점 단축키 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🧩 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">공개 Notion 기준 링크</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>게시 페이지의 렌더링 본문을 대조하고 위키와 진행도 점검 규칙에서 같은 공개 주소를 사용합니다.</p><a href="https://wobbly-pawpaw-1ff.notion.site/SFH-6b45b728004082af8a4a811ef0a1c5e9">기획 원본 ↗</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>지속 원형 자기장 · 방 진입 봉쇄 전투 · 전멸 보상</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 전투 흐름 2개 개선</strong>
          <ul>
            <li>2번 자기장을 5초 동안 플레이어를 따라가며 0.5초마다 피해를 누적하는 지속 필드로 변경했습니다.</li>
            <li>일반 방 진입 시 등급별 적 무리를 생성하고 출입문을 물리적으로 봉쇄합니다.</li>
            <li>방 적 전멸 뒤 문을 열고 중앙에 내부 경험치 보상 오브젝트를 생성합니다.</li>
            <li>방 전투를 끄면 기존 전역 증원으로 복귀하며 총 생성 한계는 두 방식 모두 공유합니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결론</b><span>소·중·대형 봉쇄·전멸·보상, 선택 폴백과 대형 방 60 FPS CPU 예산을 통과했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">방 진입 봉쇄 전투</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>진입→적 생성→문 봉쇄→전멸→전투 데이터 보상을 독립 상태 머신으로 연결했습니다.</p><a href="features/room-encounters/">방 전투 보기 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">지속 원형 자기장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>단발 24 피해를 5초 동안 0.5초마다 6 피해를 누적하는 추적 필드로 교체했습니다.</p><a href="features/combat-skills/">스킬 규칙 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>방·통로 안개 전환 · 탈출 방어 · 영구 경제 · 스마트 타게팅 · 제작 · 랭킹</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 7개 시스템 + 안개 전환 개선</strong>
          <ul>
            <li>방과 통로 경계에서 즉시 끊기던 안개를 입장 0.22초·퇴장 0.32초 문턱 전환으로 개선했습니다.</li>
            <li>탈출 지점 F 상호작용을 15~35초 구역 유지형 방어전과 성공·실패 영구 정산으로 확장했습니다.</li>
            <li>지역·난이도·맵·페널티가 실제 투입 비용, 적 스탯, 회수·도면 배율에 연결됩니다.</li>
            <li>영구 크레딧·지역 해금·상점·창고·최대 3칸 소모품 로드아웃을 저장합니다.</li>
            <li>거리 45%·처형 20%·등급 20%·밀집 15%의 스마트 자동 타게팅을 적용했습니다.</li>
            <li>도면·고철·크레딧 제작과 중복 없는 1~2개 랜덤 옵션을 구현했습니다.</li>
            <li>적 강화와 회수 배율을 함께 올리는 페널티 변형 3종을 구현했습니다.</li>
            <li>지역·난이도·맵·페널티가 같은 기록만 비교하는 조건부 랭킹을 저장합니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 감사 결론</b><span>8개 신규 기능 토글을 모두 끈 폴백과 비용·제작·랭킹·카운트다운 계약을 자동 검증했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 5</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">작전 계약과 탈출 방어 정산</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>실제 투입비 차감부터 카운트다운, 반출·사망 정산까지 한 작전 수명주기로 연결했습니다.</p><a href="features/extraction-defense-results/">탈출·정산 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">영구 해금·상점·창고</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>전투 세션 밖 프로필에 재화·해금·아이템·소모품·제작품을 저장합니다.</p><a href="features/hub-economy/">거점 경제 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">스마트 자동 타게팅</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>거리 외 체력 비율·등급·밀집도를 함께 계산합니다.</p><a href="features/smart-targeting/">타게팅 규칙 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">도면 제작·랜덤 옵션</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>도면과 재료를 소비해 중복 없는 옵션 장비를 영구 생성합니다.</p><a href="features/blueprint-crafting/">제작 정책 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">페널티·조건부 랭킹</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>선택 위험과 동일 조건 점수표를 독립 저장합니다.</p><a href="features/penalty-ranking/">변형·랭킹 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">방 단위 던전 슈터식 안개 전환</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>문턱에서 방 전체 시야와 통로 정면 시야를 크로스페이드하고 다른 방은 계속 차단합니다.</p><a href="features/fog-of-war/">안개 규칙 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>전기 스킬 이펙트 · 대형 작전 성능 최적화</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 5개 주제</strong>
          <ul>
            <li>점멸·자기장·기동 가속에 전기 잔상·고리·방사형 오라를 적용했습니다.</li>
            <li>공용 렌더러와 스킬별 프로필을 분리해 패턴·색·밀도·갱신률을 교체할 수 있습니다.</li>
            <li>전기 형상 10~20Hz 캐시와 쿨타임 HUD 10Hz 제한으로 매 프레임 할당을 줄였습니다.</li>
            <li>대형 맵 벽·설비 충돌체를 병합하고 적 A* 재탐색을 분산했습니다.</li>
            <li>적 72명 대형 작전에서 평균 6.887ms, 최대 10.328ms, Node 1,490개를 검증했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결론</b><span>전기 표현은 스킬 규칙과 독립된 Resource이며 대형 작전 CPU·Node·충돌체·이펙트 예산을 자동 회귀 테스트로 고정했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">모듈형 전기 스킬 표현</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>trail·ring·burst 프로필을 스킬별로 주입해 전기 표현만 독립 교체합니다.</p><a href="features/combat-skills/">전투 스킬 보기 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">대형 작전 엄격 최적화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>충돌체 병합, A* 캐시, HUD 갱신 제한을 적용하고 60 FPS CPU 예산을 통과했습니다.</p><a href="performance/minimum-requirements/">사양·성능 예산 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">성능 예산 자동 게이트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>평균·최대 프레임, Node, 충돌체 압축률과 동시 전기 효과의 상한을 자동 검사합니다.</p><a href="architecture/module-audit/">모듈 감사 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>큰 시작 거점 · 작전 게이트 · 전투 세션 복귀</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 5개 주제</strong>
          <ul>
            <li>게임 시작 지점을 1800×1040px 크기의 큰 단일 안전 방으로 변경했습니다.</li>
            <li>동쪽 작전 게이트에서 F를 눌러 소·중·대형 전투 세션을 선택합니다.</li>
            <li>작전 UI를 전장 카드·밸런스 모드·ESC 복귀 중심으로 재구성했습니다.</li>
            <li>탈출·사망 결과 확인 후 전투 모듈만 정리하고 같은 시작 거점 흐름으로 복귀합니다.</li>
            <li>Notion을 다시 대조해 진행도를 45%로 갱신하고 후속 작업을 확정도별로 정리했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>개선 의도</b><span>메뉴에서 전투를 고르는 대신 실제 공간의 게이트를 통해 출격하고 귀환하는 익스트랙션 루프의 감각을 먼저 만듭니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">SFH 전초기지와 작전 게이트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>안전 구역 플레이어, 큰 방 경계와 F 상호작용 게이트를 독립 모듈로 추가했습니다.</p><a href="features/start-hub/">시작 거점 보기 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">거점↔전투 세션 전환</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>출격 시 거점을 제거하고 귀환 시 전투 Node를 정리해 세션 상태를 섞지 않습니다.</p><a href="features/raid-setup-extraction/">작전 흐름 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">세션 구성 UI 최적화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>전장 정보와 데이터 모드를 분리하고 취소·복귀 동선을 명확하게 표시합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>내부 성장 · 무기·방어구·모듈 Google Sheets 연동</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 4개 주제</strong>
          <ul>
            <li><code>RunBuff</code> 탭에서 한 판 내부 레벨업 선택지 5개와 중첩·효과를 관리합니다.</li>
            <li><code>Upgrade</code> 탭에서 무기·방어구·모듈의 레벨별 누적 효과와 비용 25개를 관리합니다.</li>
            <li>작전 시작 UI의 확정 CSV/실시간 테스트 모드가 세 성장 데이터에도 함께 적용됩니다.</li>
            <li>잘못된 행이나 네트워크 오류에는 마지막 정상값 또는 확정 CSV로 복구합니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 감사 결론</b><span>성장 서비스는 데이터만 제공하고 버프 선택, 장비 상태, 발사, 크레딧 소비는 기존 기능의 공개 계약에 맡깁니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">RunBuff 실시간 성장 데이터</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>최대 체력·방어력·이동 속도와 무기 피해·주기·거리 효과를 행 단위로 편집합니다.</p><a href="features/growth-balance/">성장 시트 계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">장비·모듈 강화 스펙 연동</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>ID와 레벨로 누적 스탯, 최대 레벨, 모듈 코스트와 다음 강화 비용을 조회합니다.</p><a href="features/equipment-upgrade-economy/">강화 경제 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🧩 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">Resource 폴백을 보존한 제공자 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>시트 기능을 끄면 기존 버프 카탈로그와 강화 비용 Resource로 자동 복귀합니다.</p><a href="architecture/module-audit/">모듈 점검 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>2.5~5배 회수 · 유한 적 재생성 · 핵앤슬래시 무브먼트</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 5개 주제</strong>
          <ul>
            <li>판마다 투입 코스트의 2.5~5배에서 회수 목표 총액을 선택합니다.</li>
            <li>최소·최대 배수와 지점별 수용량을 Resource로 분리해 범위를 유연하게 바꿀 수 있습니다.</li>
            <li>최초 배치를 포함한 총 적 생성 한계를 소형 120, 중형 220, 대형 360으로 적용했습니다.</li>
            <li>초동 가속, 90도 선회, 180도 역선회와 대시 종료 관성을 강화했습니다.</li>
            <li>세 등급 경제·스폰 정책과 유한 재생성·이동 단계를 자동 검증했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>개선 의도</b><span>작전 투자의 보상 폭은 명확히 보장하되 데이터로 재조정 가능하게 하고, 전투는 무한 리스폰 대신 끝이 있는 밀도 높은 핵앤슬래시 흐름으로 만듭니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">2.5~5배 판별 회수 목표</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>선택 배수의 목표 총액과 실제 회수 지점 총액을 정확히 일치시킵니다.</p><a href="features/credit-loot/">회수 경제 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">등급별 총 생성 예산</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>누적 생성량이 한계에 도달하면 생존 적이 줄어도 추가 증원을 중단합니다.</p><a href="features/enemies/">적 생성 정책 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">탑뷰 핵앤슬래시 동적 이동</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>빠른 출발·급선회·짧은 대시와 감쇠 관성으로 전투 중 방향 전환의 손맛을 강화했습니다.</p><a href="features/player/">이동 수치 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🧩 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">정책 Resource·스냅샷 계약 확장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>경제 범위, 남은 스폰 예산과 이동 상태를 기능별 공개 계약으로 분리했습니다.</p><a href="architecture/module-audit/">모듈 감사 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>방 전체 공개 · 통로 정면 원뿔 시야 · 다른 방 차단</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 4개 주제</strong>
          <ul>
            <li>방에 들어가면 현재 방과 경계 벽의 전장의 안개를 모두 제거합니다.</li>
            <li>통로에서는 주변 170px와 바라보는 방향 780px·약 124도 시야를 제공합니다.</li>
            <li>통로 정면이 다른 방을 향해도 해당 방 내부는 계속 가립니다.</li>
            <li>HUD와 FULL MAP 미니맵은 시야 모드와 관계없이 전체 정보를 유지합니다.</li>
          </ul>
          <p class="sfh-intent"><b>개선 의도</b><span>방 안의 핵앤슬래시 교전은 답답하지 않게 열고, 방 사이 이동은 정면 확인과 매복 위험이 공존하도록 탐색 리듬을 분리합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">방 전체 가시성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>현재 방 바닥과 벽은 완전히 밝히고 방을 나가면 다시 통로 시야로 전환합니다.</p><a href="features/fog-of-war/">시야 규칙 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">캐릭터 정면 확장 시야</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>이동 방향을 바라보는 방향 계약으로 공개하고 넓은 통로 원뿔 시야에 연결했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧩 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">방·통로 가시성 계약 분리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>안개가 맵 내부 배열을 읽지 않고 현재 영역과 방 경계 복사본만 받도록 모듈 경계를 유지했습니다.</p><a href="architecture/module-audit/">모듈 감사 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>맵 비례 적 증원 · 최소 2.5배 회수 가치 · 모듈 전수 감사</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 5개 주제</strong>
          <ul>
            <li>소형 24~36, 중형 36~54, 대형 52~72명 중 이번 판의 목표 동시 적 수를 무작위로 정합니다.</li>
            <li>적 수가 목표의 75% 이하가 되면 등급별 묶음 단위로 증원합니다.</li>
            <li>회수 가능 자원의 최소 배치 총액을 투입 코스트의 2.5배로 보정합니다.</li>
            <li>적 생성기가 자신이 만든 적만 추적하고 자동 무기에 대상 목록을 제공합니다.</li>
            <li>전역 집계·플레이어 내부 필드 접근·파밍 계약 불일치를 제거했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>개선 의도</b><span>맵이 클수록 더 많은 적이 일정 밀도로 재투입되는 핵앤슬래시 흐름을 만들고, 작전 투자 대비 탐색할 기본 자원 가치를 보장합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">등급별 목표 수량 + 묶음 증원</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>작전마다 최소~최대 사이 목표를 뽑고 75% 이하에서 증원 묶음을 투입합니다.</p><a href="features/enemies/">적 생성 설계 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">투입 코스트 2.5배 최소 배치</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>무작위 회수 지점 총액이 최소값에 미달하면 개별 최대값 안에서 부족분을 자동 분배합니다.</p><a href="features/credit-loot/">경제 보정 보기 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🧩 수정 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">생성기 소유 적만 추적</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>전역 enemies 그룹 수량 대신 생성기별 인스턴스 목록과 공개 스냅샷을 사용합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">대상·체력·파밍 계약 정리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>자동 무기 대상 제공자, 플레이어 체력 스냅샷, 파밍 배치 스냅샷을 명시적 계약으로 연결했습니다.</p><a href="architecture/module-audit/">모듈 감사 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>화면 크기 방 · 안개 · 금고형 자원 회수</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 5개 주제</strong>
          <ul>
            <li>가장 작은 방도 42×25셀로 확장해 기본 화면 한 장보다 크게 만들었습니다.</li>
            <li>긴 실내 칸막이, 설비 블록과 다중 기둥이 건물 내부 구조를 만듭니다.</li>
            <li>초기 원형 전장의 안개를 적용했고 후속 업데이트에서 방·통로 방향성 시야로 개선했습니다.</li>
            <li>우측 미니맵은 `FULL MAP` 전체 지형을 계속 표시합니다.</li>
            <li>벽면 금고·자재함·회수 단말기에서 F로 크레딧 자원을 확보합니다.</li>
          </ul>
          <p class="sfh-intent"><b>개선 의도</b><span>한 방 안에서도 탐색과 교전이 일어나고, 제한된 시야 속에서 전체 전술 지도를 활용하는 익스트랙션 감각을 강화합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">전장의 안개 + FULL MAP</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>월드만 시야 제한하고 HUD와 전체 미니맵은 밝게 유지합니다.</p><a href="features/fog-of-war/">시야 설계 보기 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">금고형 자원 회수 지점</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>상자 대신 세 유형의 회수 지점을 위치·벽 방향에 맞춰 배치합니다.</p><a href="features/credit-loot/">파밍 보기 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">화면 한 장급 방</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>세 등급의 방 최소 면적을 1280×720 화면보다 크게 상향했습니다.</p><a href="features/map-generation/">맵 수치 보기 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">건물 내부 구조 생성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>출입구 있는 칸막이·넓은 설비·기둥 열로 장애물 패턴을 강화했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 12</small><b>U 장비 · 모듈 인벤토리 UI 개편</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 5개 주제</strong>
          <ul>
            <li>U 화면을 장비 슬롯 레일, 선택 장비 상세, 아이템 카드 인벤토리의 3영역으로 개편했습니다.</li>
            <li>모듈 슬롯·코스트 막대와 전체/모듈/고유 파츠 필터를 추가했습니다.</li>
            <li>가방에서 원하는 장비·모듈·파츠 카드를 직접 선택해 장착합니다.</li>
            <li>호환 여부, 장착 레벨, 강화 재료와 크레딧 견적을 카드에서 확인합니다.</li>
            <li>U 화면이 미니맵보다 앞에 표시되도록 모달 순서를 수정했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>개선 의도</b><span>장비와 개조 정보를 한 화면에서 빠르게 비교하고, 자동 선택 없이 원하는 아이템을 정확히 장착하게 합니다.</span></p>
        </div>

        <div class="sfh-group"><h3>🆕 구현 · 7</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">U 장비·모듈 카드 인벤토리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>4개 슬롯 레일, 선택 장비 상세, 장착 모듈 보드와 직접 선택 인벤토리를 연결했습니다.</p><a href="features/equipment-customization/">장비 UI 보기 →</a></div></details>
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
  <a class="sfh-link-card" href="features/fog-of-war/"><b>전장의 안개</b><span>월드 시야 제한과 전체 미니맵의 분리된 동작을 설명합니다.</span><small>WORLD VISIBILITY →</small></a>
  <a class="sfh-link-card" href="features/grid-inventory/"><b>격자 가방</b><span>아이템별 점유 크기와 I 키 인벤토리의 현재 구현을 확인합니다.</span><small>INVENTORY →</small></a>
  <a class="sfh-link-card" href="getting-started/edit-wiki-online/"><b>웹에서 위키 수정</b><span>GitHub 웹 편집과 자동 Pages 배포 흐름을 따라갑니다.</span><small>COLLABORATE →</small></a>
</div>

## 검색 요령

상단 검색창 또는 `/` 키를 사용합니다. `Q키`, `구글 시트`, `가방`, `모듈 코스트`, `소분류`, `미니맵`, `탈출`, `버그픽스`처럼 기능·입력·증상 단어로 검색할 수 있습니다.
