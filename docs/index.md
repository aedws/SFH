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
        <b>96%</b>
      </div>
      <div class="sfh-progress-track" role="progressbar" aria-label="SFH 기획 진행도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="96"><i style="width: 96%"></i></div>
      <p>우선순위 10개 구현 완료 · 입력·전투 3× · 타게팅·탈출 2× · 기타 1×</p>
      <a href="development-status/#_1">산정 근거 확인 →</a>
      <a href="https://wobbly-pawpaw-1ff.notion.site/SFH-6b45b728004082af8a4a811ef0a1c5e9">공개 기획 원본 ↗</a>
    </div>
    <header><strong>현재 빌드 상태</strong><b class="sfh-live">PLAYABLE</b></header>
    <p>거점에서 지역·난이도·페널티·소모품을 준비하고, 투입 비용을 지불해 전투·파밍·탈출 방어·영구 정산 뒤 복귀합니다.</p>
    <div class="sfh-operation-launch">
      <a class="sfh-operation-play" href="play/">
        <span><small>PLAY CURRENT MAIN</small><strong>브라우저로 플레이</strong><em>설치 없이 바로 작전 준비</em></span>
        <b aria-hidden="true">▶</b>
      </a>
      <div class="sfh-operation-meta" aria-label="현재 플레이 빌드 요약">
        <span><b>3</b><small>MAP TIERS</small></span>
        <span><b>K · 21 ACTIONS</b><small>FREE KEY MAPPING</small></span>
        <span><b>PASS</b><small>WEB BUILD</small></span>
      </div>
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

<div class="sfh-release-stats"><span>최신 2026-08-31</span><span>SEARCH COMMAND</span><span>2 DAYS · 26 TOPICS</span><span>기획 진행도 96% · 타격 피드백 1차</span></div>

<div class="sfh-notes">
<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-08-31</b><i class="sfh-latest">&#xCD5C;&#xC2E0;</i><small>8 UPDATE BUNDLES &middot; BUILD 17 &middot; IMPROVE 15 &middot; CHANGE 10 &middot; FIX 2</small></span><em class="sfh-chevron">&#x2303;</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview">
      <span><b>8</b><small>UPDATE BUNDLES</small></span>
      <span><b>17</b><small>BUILD</small></span>
      <span><b>15</b><small>IMPROVE</small></span>
      <span><b>10</b><small>CHANGE</small></span>
      <span><b>2</b><small>FIX</small></span>
    </div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>공개 기획 재대조 · 진행률 69% · 남은 작업 재정렬</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 기능 보유 여부가 아니라 최신 수용 기준으로 다시 계산</strong>
          <ul>
            <li>2026-08-31 공개 Notion 본문을 읽고 저장소 코드와 직접 대조했습니다.</li>
            <li>좌클릭 연속 기본기, 1~9 슬롯, 스킬 유형별 타게팅, 탈출 일시정지·재개를 최우선 차이로 확인했습니다.</li>
            <li>서로 겹치지 않는 다섯 기획 묶음에 확정 중요도 가중치를 적용해 진행률을 69%로 재산정했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>판정 원칙</b><span>Notion 체크박스가 아니라 실제 코드·데이터·검증으로 완료 여부를 판정합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">최신 기획 기준 진행률·개발 순서</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>새로 명시된 입력·타게팅·탈출 조건을 반영하고 남은 작업을 플레이 규격 차이부터 정렬했습니다.</p><a href="development-status/#_1">상세 산정 근거 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>자동 전투를 직접 운용으로 · 탈출·경제·랭킹 완결 · 진행률 93%</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 자동으로 흘러가던 프로토타입을 선택과 손실이 있는 작전으로 전환</strong>
          <ul>
            <li>항상 자동 발사하던 기본기가 좌클릭을 누르는 동안만 발동하며, 액티브 입력은 1~3 고정에서 1~9 슬롯·런타임 재설정 계약으로 확장됐습니다.</li>
            <li>한 개 가중치 타게팅은 최근접·최대 HP·엘리트·밀집 중심·이동 벡터 정책으로 분리돼 무기와 스킬이 목적별로 선택합니다.</li>
            <li>탈출 범위를 벗어나면 초기화되던 방어전이 남은 시간 일시정지·재개로 바뀌고, 사망 시 작전 장착품도 소실됩니다.</li>
            <li>투입 비용은 보스 보장·고등급 가중치·지역 드랍표로 실제 파밍 결과에 연결되고, 파산 시 무료 기본 계약과 무장이 복구됩니다.</li>
            <li>무기 전투 태그·등급별 스킬 변형과 감전→점멸 트리거를 연결하고, 회복·시야·탈출 페널티와 가치·시간·처치 3종 랭킹을 분리했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>당시 남은 7%</b><span>이 업데이트 뒤 K 키 설정·영구 저장을 완료했습니다. 현재 후속 범위는 구매품의 I/U 영구 인벤토리 연결, 온라인 검증 랭킹, 4~9번 콘텐츠와 고유 보스입니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 7</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">좌클릭 홀드·1~9 슬롯</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>공격 의사와 발사 주기는 분리하고 9개 입력 슬롯과 런타임 재설정 계약을 추가했습니다.</p><a href="features/combat-skills/">전투 입력 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">목적별 스마트 타게팅</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>단일·범위·이동·자기 스킬이 서로 다른 대상 해석을 데이터로 선택합니다.</p><a href="features/smart-targeting/">정책표 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">탈출 일시정지·사망 손실</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방어 시간을 보존해 재개하고 실패 작전의 장착 로드아웃도 정산 범위에 포함했습니다.</p><a href="features/extraction-defense-results/">탈출·정산 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">투자 기반 보스·드랍·무료 복구</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>비용·지역·난이도가 보스, 고등급, 드랍표에 반영되고 파산 시 기본 계약을 보장합니다.</p><a href="features/operation-contracts/">작전 계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">영구 상점 등록</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>도면 성공 반출과 상점 등록·구매 가능 상태를 프로필에 영구 저장합니다.</p><a href="features/hub-economy/">거점 경제 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">태그·등급·상태 연계</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>활성 무기 태그가 스킬을 제한하고 등급 수정자와 shock→ionized 연계를 적용합니다.</p><a href="features/weapons/">무기 계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">페널티·3종 랭킹</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>회복·시야·탈출 위험을 합성하고 가치·최단 시간·처치를 별도 순위로 저장합니다.</p><a href="features/penalty-ranking/">위험·랭킹 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">작전 선택 정보 밀도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>무료 지원, 보스 보장, 고등급 배율과 회복 페널티를 출격 전에 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">스킬 호환 피드백</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Q 교체 직후 태그 불일치 슬롯을 HUD에서 바로 식별합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">결과 순위 가독성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>종합 점수 하나 대신 가치·시간·처치 순위를 결과 화면에 함께 표시합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">자동 발사 → 좌클릭 홀드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>무조준 원칙은 유지하되 공격 시작과 중지는 플레이어가 통제합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">가중 대상 → 명시 정책</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>행동 성격에 맞는 대상 규칙을 정의 단위로 선택합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">탈출 초기화 → 시간 보존</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>구역 이탈을 실패 초기화가 아닌 방어전 일시정지로 처리합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">종합 점수 → 3개 사다리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>서로 다른 플레이 목표가 한 공식에 묻히지 않도록 순위를 분리했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>실제 플레이 E2E · U/E Web 입력 수정 · 화면 의미 정리</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 기능 보유 검사에서 실제 한 판 입력 흐름 검증으로 확장</strong>
          <ul>
            <li>실제 키로 거점 이동, I/U/E/Q/F, 소형 작전, 파밍, 탈출 일시정지·성공, 사망과 두 차례 거점 복귀를 연속 검사합니다.</li>
            <li>Web에서 열린 U 화면에 E를 누르면 닫히던 입력 충돌을 독립 Action으로 분리했습니다.</li>
            <li>`활성 스킬`로 오해되던 장비 호환 숫자와 오래된 1~3 조작 안내를 현재 의미에 맞췄습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검수 기준</b><span>상태가 맞아도 플레이어 눈에 오작동으로 보이면 실패로 기록하고, 자동 입력과 브라우저 육안 결과를 함께 남깁니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">실제 입력 플레이 세션 러너</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>성공·실패 한 판을 연속 실행하고 단계별 실패 원인을 출력합니다.</p><a href="quality/e2e-play-session/">E2E 목록 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">배포 전 E2E 차단선</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Pages Web 내보내기 전에 계약 스모크와 실제 입력 세션을 모두 통과해야 합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">장비 호환 숫자 명시</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>`활성 스킬` 대신 `장비 태그 호환`으로 실제 의미를 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">현재 조작 안내 동기화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>LMB 기본기와 1~9 스킬, U 장비와 E 모듈을 전투 HUD에 명시합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">U/E 독립 입력 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>UI가 물리 키를 추측하지 않고 장비와 모듈 Action을 각각 소비합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Web U→E 창 닫힘</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>열린 장비 화면에서 E가 닫기 토글이 아니라 모듈·파츠 탭 전환으로 작동합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>K 자유 키 설정 · CC0 상업 VFX · 입력 완전 Action화</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 고정 조작과 출처 불명 표현에서 재설정 가능한 입력·감사 가능한 VFX로 전환</strong>
          <ul>
            <li>K 화면에서 이동·대시·기본기·Q/F·1~9·I/U/E와 K 자체까지 21개 Action을 키보드·마우스로 변경하고 재실행 뒤에도 유지합니다.</li>
            <li>중복 키는 기존 Action과 교환하고 ESC는 입력 취소·화면 닫기용으로 고정해 설정 실수로 UI에 갇히지 않습니다.</li>
            <li>물리 WASD·Space 직접 조회를 제거해 실제 이동과 대시도 저장된 Action을 사용합니다.</li>
            <li>상업 이용 가능한 Kenney Particle Pack의 CC0 전기 텍스처 2개만 반입하고 원문·커밋·SHA-256을 함께 보존했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결과</b><span>21 Action·ESC·중복 교환·JSON 저장·CC0 원장·효과 예산 스모크와 실제 K/ESC E2E를 통과했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">K 키 설정·영구 저장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>카탈로그·저장 서비스·모달 UI를 분리하고 브라우저와 PC의 user 경로에 즉시 저장합니다.</p><a href="features/key-mapping/">키 변경 방법 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">상업 에셋 라이선스 원장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>CC0 원문, 원본 커밋, 선별 파일과 해시를 배포 가능한 감사 기록으로 남깁니다.</p><a href="architecture/third-party-assets/">라이선스 확인 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">현재 키 기반 HUD 안내</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>변경 직후 거점·전투 안내를 저장된 키 이름으로 다시 구성합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">전기 스킬 텍스처 강조</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>점멸·자기장·기동 가속에 프로필별 CC0 전기 구름을 제한된 수로 합성합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">물리키 직결 → Action 입력</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>플레이어 이동·대시가 WASD와 Space를 직접 읽지 않아 모든 변경값이 실제 조작에 반영됩니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>UI 상태 판정 E2E · 21개 전환 · 결과 HUD 누수 차단</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 화면이 열렸는지에서 플레이 상태 전체가 올바른지로 검증 확장</strong>
          <ul>
            <li>거점·K/I/U/E·작전 설정·전투·성공·실패·복귀의 21개 전환마다 표시·숨김·일시정지·모달 수를 판정합니다.</li>
            <li>1280×720 화면 경계와 미니맵·스킬·대시 비겹침을 실제 전역 Rect로 검사합니다.</li>
            <li>첫 실행에서 성공 정산 뒤 전투 HUD 4종이 남는 결함을 재현하고 정산 진입에서 일괄 종료했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>배포 기준</b><span>21개 UI 상태 계약 성공 토큰이 없으면 Web 내보내기와 위키 배포를 중단합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">UI 상태 계약 판정기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>플레이를 변경하지 않는 읽기 전용 판정기가 21개 전환의 레이어·정지·모달·탭 상태를 검사합니다.</p><a href="quality/e2e-play-session/">상태 판정표 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">상태별 실패 진단</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>실패한 플레이 맥락과 보이거나 겹친 레이어를 한 줄로 출력합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">정산 화면 뒤 전투 HUD 잔류</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>성공·실패 결과에서는 전투 HUD·미니맵·스킬·대시를 모두 숨기고 결과만 표시합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>작전 브리핑 UI · 선택 후 투입 확정 · 전술 HUD 재배치</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 작은 설정 버튼 모음에서 작전 판단을 위한 양쪽 브리핑 화면으로 전환</strong>
          <ul>
            <li>왼쪽에 지역·규모·난이도, 전술 경로, 목표 시간·방·적 범위, 투입 대비 회수·고등급·보스 정보를 묶었습니다.</li>
            <li>오른쪽에 지역·난이도·페널티·준비 기능, 규모 카드, 위험 배율, 소모품과 최종 투입 비용을 계층화했습니다.</li>
            <li>소·중·대형 카드는 선택만 수행하고 별도 작전 투입 버튼으로 계약을 확정해 오입력을 막습니다.</li>
            <li>전투 상단 HUD를 1040×144 전술 카드로 압축하고 장비와 현재 무기를 나란히 배치했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결과</b><span>양쪽 열 500px, 패널·투입 버튼 경계, 선택→확정, 21상태 E2E와 HUD 비겹침을 통과했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">작전 브리핑 Presenter</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기존 계약 스냅샷을 임무·위험·회수·확정 영역과 코드 전술 프리뷰에 투영합니다.</p><a href="features/raid-setup-extraction/">브리핑 구조 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">전투 HUD Presenter</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기존 체력·경험치·장비·무기 데이터를 유지하며 상단 정보 계층만 교체합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">투입 전 판단 가시성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>실제 비용·회수·고등급·보스·적 배율과 소모품을 출격 전에 한 화면에서 비교합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">상단 HUD 점유율</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>전투 정보를 144px 높이로 압축하고 우측 미니맵과 수직으로 분리합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">규모 클릭 즉시 출격 → 선택 후 확정</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>규모 변경은 계약 표시만 갱신하며 명시적 투입 버튼에서만 비용을 차감합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>전투 HUD 시선권 재구성 · 임무 추적기 · 하단 전투 클러스터</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 상단 전체 폭 정보판에서 전장을 비우는 분산형 HUD로 전환</strong>
          <ul>
            <li>작전 지역·현재 교전·탈출 시간은 좌측 상단 338×108 임무 추적기로 분리했습니다.</li>
            <li>체력·경험치·레벨·처치·크레딧·장비·현재 무기는 하단 중앙 600×142 생존 코어로 이동했습니다.</li>
            <li>에너지와 3개 스킬을 516×92로 압축하고 대시를 왼쪽 같은 높이에 배치해 한 번의 시선 이동으로 준비 상태를 읽습니다.</li>
            <li>상호작용 문구는 생존 코어 위 독립 영역에 두고 미니맵·스킬·대시와의 교차를 자동 검사합니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결과</b><span>1280×720 경계·비겹침, 실제 입력 21상태 E2E, 대형 작전 60 FPS 성능 예산을 유지했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">좌측 임무 추적기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>현재 목표와 시간만 좌측 상단에 남겨 이동 경로와 전장 중앙을 가리지 않습니다.</p><a href="features/raid-setup-extraction/#hud">전투 HUD 구조 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">하단 생존·무기 코어</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>체력에서 현재 무기와 스킬까지 캐릭터 아래 한 시선권으로 묶었습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">스킬·대시 밀도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>설명문을 접고 입력·준비·쿨타임·에너지 정보 중심으로 슬롯을 압축했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">상단 전술 카드 → 분산 시선권</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>1040px 상단 카드 대신 임무·생존·행동 정보를 서로 다른 화면 가장자리로 분리했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>타격 피드백 1차 · 피격 섬광·국소 경직·넉백·카메라 충격</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 체력 숫자만 줄던 타격에 시각·움직임·화면 반응을 연결</strong>
          <ul>
            <li>적과 플레이어가 맞으면 흰색 섬광, 약 0.05초의 해당 액터 국소 경직과 타격 방향 넉백이 발생합니다.</li>
            <li>방어·체력·전기·플레이어 피격을 색으로 구분한 충격 링과 방사선을 0.18초 동안 표시합니다.</li>
            <li>적 타격·플레이어 피격·치명타 강도를 합성한 Camera Trauma를 최대 6px 안에서 감쇠합니다.</li>
            <li>기본기·점멸 경로·지속 자기장·적 접촉이 공통 `hit_context`로 방향과 출처를 전달합니다.</li>
          </ul>
          <p class="sfh-intent"><b>성능·안전</b><span>타격별 Node를 만들지 않고 동시 충격 32개 상한을 유지하며, 전역 시간 정지 없이 맞은 액터만 반응합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">HitReaction2D</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>액터별 섬광·국소 경직·넉백을 독립 구성 요소로 적용합니다.</p><a href="features/hit-feedback/">타격 피드백 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">HitFeedbackDirector</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>damaged Signal을 충격 드로잉과 카메라 Trauma로 변환합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">HitFeedbackProfile</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>수명·반경·방사선·카메라 강도·동시 표시 상한을 Resource로 분리했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">기본기·스킬 명중 인지</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>투사체와 전기 스킬이 서로 다른 색·방향 피드백을 제공합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">플레이어 위험 피드백</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>적 접촉 시 붉은 충격과 더 강한 카메라 반응으로 피해를 즉시 알립니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">피해량 단일 인자 → 선택형 명중 문맥</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기존 호출을 유지하면서 방향·출처·표현 강도를 선택적으로 전달합니다.</p></div></details>
        </div>
      </div>
    </details>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>18 UPDATE BUNDLES &middot; BUILD 35 &middot; IMPROVE 31 &middot; CHANGE 12 &middot; FIX 8</small></span><em class="sfh-chevron">&#x2303;</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview">
      <span><b>18</b><small>UPDATE BUNDLES</small></span>
      <span><b>35</b><small>BUILD</small></span>
      <span><b>31</b><small>IMPROVE</small></span>
      <span><b>12</b><small>CHANGE</small></span>
      <span><b>8</b><small>FIX</small></span>
    </div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>브라우저 즉시 플레이 · 게임 정체성 README · 통합 배포</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 저장소 첫 화면에서 게임을 이해하고 바로 실행</strong>
          <ul>
            <li>README에 SURVIVE · FIGHT · HAUL과 ‘조준은 자동으로. 판단은 끝까지.’를 전면 배치했습니다.</li>
            <li>No-Aim Action, Invest & Extract, Room Hacking, 장비 빌드, 모듈 우선의 다섯 노선을 압축했습니다.</li>
            <li>Godot Web 빌드를 개발 위키의 /play/ 경로에 결합해 설치 없이 브라우저에서 실행합니다.</li>
            <li>게임 내보내기와 HTML·WASM·PCK 검증 실패 시 Pages 배포를 중단해 마지막 정상 빌드를 유지합니다.</li>
            <li>OFL 한글 폰트를 전역 자산으로 포함해 Web에서 네모 글리프로 깨지던 한글 UI를 복구했습니다.</li>
            <li>Web에서 확정 CSV를 열 수 없을 때 동일 원문의 내장 Resource로 전환해 작전 시작 직후 거점으로 돌아오던 실패를 해결했습니다.</li>
            <li>홈 빌드 카드와 모든 위키 화면의 고정 버튼에서 브라우저 플레이를 즉시 열 수 있습니다.</li>
            <li>전투 HUD·미니맵·스킬바와 I·U·E 화면의 점유 면적을 줄이고 상태별 UI를 배타적으로 표시합니다.</li>
          </ul>
          <p class="sfh-intent"><b>배포 경계</b><span>게임은 Godot Web 프리셋, 문서는 MkDocs로 각각 빌드한 뒤 하나의 검증된 Pages 아티팩트에서만 결합합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Godot Web 자동 내보내기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>main의 게임 변경마다 4.7.2 릴리스 템플릿으로 브라우저 빌드를 생성합니다.</p><a href="play/">브라우저에서 플레이 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">위키·게임 통합 Pages 게이트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>문서와 게임을 독립 빌드하고 필수 산출물 검증 뒤 /play/에 결합합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 5</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">게임 정체성 중심 README</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>캐치프레이즈, 핵심 노선, 코어 루프와 플레이 범위를 저장소 첫 화면에 압축했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">설치 없는 첫 플레이 동선</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>README와 실행 문서의 첫 행동을 브라우저 플레이로 통일했습니다.</p><a href="getting-started/run-project/">실행 방법 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">현재 빌드 플레이 카드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>우측 빌드 상태 블록을 큰 브라우저 플레이 버튼과 압축 상태 지표로 재구성했습니다.</p><a href="play/">브라우저로 플레이 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">전역 플레이 바로가기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>위키의 어느 문서에서도 상단 고정 헤더 버튼으로 현재 Web 빌드에 진입합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">게임 UI 화면 점유 압축</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>상단 HUD·미니맵·스킬바·작전 구성·성장 선택과 I·U·E 화면을 축소해 전장 가시 영역을 넓혔습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">README 정보 구조 전환</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>긴 구현 목록 중심에서 게임 소개→즉시 플레이→상세 개발 문서 순서로 바꿨습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🩹 버그픽스 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Web 한글 글리프 복구</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Nanum Gothic을 전역 폰트로 포함하고 한글 글리프 계약을 자동 검사해 브라우저의 네모 글자 표시를 막았습니다.</p><a href="getting-started/run-project/">Web 실행 기준 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Web 작전 시작 회귀</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>브라우저가 확정 CSV 스트림을 제공하지 못하면 원본과 자동 동기화된 내장 Resource를 읽어 성장 데이터 조립 실패와 자동 거점 복귀를 차단합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">HUD·모달 UI 중첩</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>작전 구성 및 I·U·E 화면을 열 때 거점·전투 HUD를 숨기고 닫을 때 이전 상태만 복원합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>플랫포머형 즉시 이동 · 단단한 정지 · 급선회 그립</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 밀리는 이동에서 입력대로 끊기는 이동으로</strong>
          <ul>
            <li>입력 첫 프레임에 기본 속도의 90% 이상으로 진입하고 손을 떼면 저속 꼬리 없이 정지합니다.</li>
            <li>90도 선회에서 옆 방향 관성을 제거하고, 180도 반전은 이전 속도를 18%만 보존합니다.</li>
            <li>대시 종료 관성을 0.08초·1.08배로 줄이고 카메라 추적 응답을 높였습니다.</li>
            <li>왼쪽 아래 전용 카드에서 대시 READY·사용 중·남은 재사용 시간과 준비 게이지를 표시합니다.</li>
            <li>초동·스냅·횡그립·반전 보존·대시 종료 값은 이동 컴포넌트에서 각각 교체 가능합니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 감사 결론</b><span>속도 정책은 PlayerMovement의 순수 계산 경계 안에 있고 맵·전투·장비 모듈을 참조하지 않습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">플랫포머형 이동 응답 정책</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>정지 스냅, 횡그립과 반전 속도 보존을 독립 이동 파라미터로 추가했습니다.</p><a href="features/player/">플레이어 이동 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">대시 준비·재사용 HUD</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Shift/Space 대시의 READY·DASH·남은 시간과 충전 게이지를 독립 카드로 표시합니다.</p><a href="features/player/">대시 HUD 계약 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">즉시 초동과 완전 정지</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>가속 응답을 높이고 50px/s 이하의 남은 속도를 0으로 스냅합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">급선회·반전 그립</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방향 전환 중 옆으로 흐르는 속도를 제거해 입력 방향을 즉시 되찾습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">대시·카메라 후행 축소</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>대시 뒤 미끄러짐과 화면 추적 지연을 함께 줄였습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">기본 이동 튜닝 상향</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>일반·선회·제동·역선회 기본값을 한 프레임 반응 기준으로 재설정했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>고밀도 I·U·E · 거점 로드아웃 편집 · 세션 상태 유지</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 거점에서 출격 장비를 완성</strong>
          <ul>
            <li>I·U·E 패널을 모두 ESC로 닫고 기존 일시정지 상태로 복귀합니다.</li>
            <li>거점에서 무기·방어구·모듈·고유 파츠를 장착·교체·해제합니다.</li>
            <li>해제한 장비와 강화 상태를 가방에 반환하며 공간 부족 시 변경 전 차단합니다.</li>
            <li>준비 로드아웃과 가방 배치를 작전 진입·거점 귀환 사이에 유지합니다.</li>
            <li>I 가방은 50px 12×8 격자·용량·상세 패널로, U/E는 3열 카드와 압축 슬롯 레일로 재구성했습니다.</li>
            <li>U는 장비, E는 모듈·파츠를 직접 열고 열린 상태에서는 창을 닫지 않고 탭을 전환합니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 감사 결론</b><span>Workbench는 공개 반출입 계약만 조정하고, Game은 불투명 런타임 스냅샷만 세션 사이에 전달합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">장비·모듈·파츠 반환 트랜잭션</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장착 상태와 강화 단계를 보존해 가방으로 반환하고 실패 시 원래 상태로 롤백합니다.</p><a href="features/equipment-customization/">거점 편집 규칙 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">거점↔작전 준비 상태 전달</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비와 가방 제공자의 export/restore 계약으로 Scene 교체 후에도 상태를 복구합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 5</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">I·U·E 공통 ESC 닫기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>열린 모달을 ESC 한 번으로 닫습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">교체·해제 전용 버튼과 상태 문구</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비와 장착 모듈·파츠의 반환 동선을 UI에서 명확히 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">I 가방 판독 밀도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>12×8 실제 점유 격자, 사용률과 선택 아이템 상세를 한 화면에서 비교합니다.</p><a href="features/grid-inventory/">격자 가방 UI →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">U·E 장비 카드 밀도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>슬롯 레일을 압축하고 장비·모듈·파츠 후보를 3열로 유지합니다.</p><a href="features/equipment-customization/">장비 UI →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">U·E 직접 탭 이동</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>U는 장비, E는 모듈·파츠 화면으로 바로 이동하며 열린 창에서 즉시 상호 전환합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">거점 조회 전용 정책 해제</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>시작 거점의 Workbench를 실제 출격 준비 편집 모드로 전환했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>전투 에너지 · 스킬 충전 · 처치 회복 드랍</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 처치로 다시 이어가는 자원 전투</strong>
          <ul>
            <li>공용 에너지 100과 스킬별 충전 횟수·복구 시간을 추가했습니다.</li>
            <li>적 처치 시 에너지·체력 결정을 떨어뜨리고 최소 1개 드랍을 보정합니다.</li>
            <li>하단 스킬 HUD에 굵은 에너지 막대, 현재/최대·백분율·LOW/CRITICAL 상태와 현재 충전을 표시합니다.</li>
            <li>레벨업 시 HP 12 회복을 임시 버프 여부와 무관하게 원상 복구했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 감사 결론</b><span>드랍 정책·자원 상태·Pickup·스킬 실행·레벨업 회복을 독립 계약으로 연결하고 대형 작전 평균 6.889ms 예산을 통과했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">에너지·충전 자원 은행</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>세 스킬의 에너지 소비와 슬롯별 충전 복구를 교체 가능한 Resource 정의로 연결했습니다.</p><a href="features/combat-resources/">전투 자원 보기 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">적 처치 회복 결정</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>에너지와 체력 결정을 독립 확률로 생성하고 자석 회수 후 실제 수치에 반영합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">스킬 자원 HUD</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>에너지 부족과 충전 대기를 슬롯에서 즉시 구분합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">에너지 판독 상태</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>13px 게이지와 현재/최대·백분율을 함께 표시하고 35%·15% 임계값을 색으로 구분합니다.</p><a href="features/combat-resources/">에너지 UI 규칙 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🐛 버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">레벨업 HP 회복 원상 복구</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>버프 선택 UI가 활성화돼도 레벨마다 HP 12가 정확히 한 번 회복됩니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>적 군중 분리 · 생성 간격 · 좁은 통로 흐름</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 겹치지 않되 서로 막지 않는 적 무리</strong>
          <ul>
            <li>같은 지점에 생성 요청이 몰려도 기존 적과 40px 이상 떨어진 걸을 수 있는 위치로 보정합니다.</li>
            <li>이동 중 가까운 적 최대 8명의 분리 방향을 추적에 합성하고 충돌 직경 안에서는 분리를 우선합니다.</li>
            <li>강체 충돌로 통로를 막지 않으며 후보가 없으면 겹친 채 생성하지 않고 요청을 취소합니다.</li>
            <li>간격·반경·강도·갱신 주기는 독립 Resource에서 조정하거나 한 번에 비활성화할 수 있습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결과</b><span>동일 좌표 생성·완전 중첩 이동·비활성 폴백과 대형 작전 평균 6.894ms 성능 예산을 통과했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">교체 가능한 적 군중 정책</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>생성 간격과 분리 조향 예산을 EnemyCrowdConfig로 분리했습니다.</p><a href="features/enemies/">적 시스템 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🐛 버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">적 중첩·밀집 해소</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>생성 순간과 플레이어 추적 중 적이 한 좌표에 겹치는 현상을 함께 차단했습니다.</p></div></details>
        </div>
      </div>
    </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 6</small><b>기획자 검색 허브 · 실시간 탐색 순위 · 빠른 영역 검색</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 검색 전부터 찾을 수 있는 위키</strong>
              <ul>
                <li>검색창을 열면 기획자가 자주 확인하는 TOP 10과 영역별 빠른 검색을 먼저 표시합니다.</li>
                <li>기획 우선순위와 현재 브라우저의 실제 검색 선택을 합산해 탐색 순위를 즉시 갱신합니다.</li>
                <li>검색어 입력 시 제목·본문·검색 별칭을 분석하는 실시간 문서 결과로 전환합니다.</li>
                <li>공동 기본 순위는 별도 JSON으로 관리하고 빌드에서 중복·누락·연결 상태를 검사합니다.</li>
              </ul>
              <p class="sfh-intent"><b>개선 의도</b><span>기획자가 정확한 문서명을 몰라도 현재 진행도와 주요 시스템에 바로 접근할 수 있게 합니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">기획자 검색 대시보드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>TOP 10, 최근 선택, 5개 기획 영역과 입력 즉시 결과 전환을 검색 모달에 연결했습니다.</p><a href="getting-started/search-wiki/">검색 사용법 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">데이터 기반 검색 우선순위</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기본 순위는 공동 JSON, 개인 탐색 신호는 해당 브라우저에만 보관하도록 분리했습니다.</p></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 7</small><b>하루 단위 업데이트 압축 · 일일 합계 · 중복 방지 검사</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 8</small><b>거점 I 가방 · U/E 장비 조회 · Q 무기 선택 유지</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 9</small><b>지속 원형 자기장 · 방 진입 봉쇄 전투 · 전멸 보상</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 10</small><b>방·통로 안개 전환 · 탈출 방어 · 영구 경제 · 스마트 타게팅 · 제작 · 랭킹</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 11</small><b>전기 스킬 이펙트 · 대형 작전 성능 최적화</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 7개 주제</strong>
              <ul>
                <li>점멸·자기장·기동 가속에 전기 잔상·고리·방사형 오라를 적용했습니다.</li>
                <li>점멸 이동 경로 폭 80px 안의 적에게 12 피해를 주는 교체형 경로 정책을 연결했습니다.</li>
                <li>Web에서 깨지는 번개 이모지 대신 고정 `EN` 에너지 비용 표기를 사용합니다.</li>
                <li>공용 렌더러와 스킬별 프로필을 분리해 패턴·색·밀도·갱신률을 교체할 수 있습니다.</li>
                <li>전기 형상 10~20Hz 캐시와 쿨타임 HUD 10Hz 제한으로 매 프레임 할당을 줄였습니다.</li>
                <li>대형 맵 벽·설비 충돌체를 병합하고 적 A* 재탐색을 분산했습니다.</li>
                <li>적 72명 대형 작전에서 평균 6.887ms, 최대 10.328ms, Node 1,490개를 검증했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>검증 결론</b><span>전기 표현은 스킬 규칙과 독립된 Resource이며 대형 작전 CPU·Node·충돌체·이펙트 예산을 자동 회귀 테스트로 고정했습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 4</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">모듈형 전기 스킬 표현</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>trail·ring·burst 프로필을 스킬별로 주입해 전기 표현만 독립 교체합니다.</p><a href="features/combat-skills/">전투 스킬 보기 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">점멸 경로 피해 정책</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>출발점부터 벽 앞 도착점까지 폭 80px 선분의 적 최대 24명에게 12 피해를 적용합니다.</p><a href="features/combat-skills/">점멸 수치·계약 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">대형 작전 엄격 최적화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>충돌체 병합, A* 캐시, HUD 갱신 제한을 적용하고 60 FPS CPU 예산을 통과했습니다.</p><a href="performance/minimum-requirements/">사양·성능 예산 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">성능 예산 자동 게이트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>평균·최대 프레임, Node, 충돌체 압축률과 동시 전기 효과의 상한을 자동 검사합니다.</p><a href="architecture/module-audit/">모듈 감사 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>🩹 버그픽스 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Web 스킬 비용 글리프 깨짐</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>번개 이모지 의존성을 제거하고 모든 브라우저 빌드에서 동일한 EN 텍스트를 표시합니다.</p></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 12</small><b>큰 시작 거점 · 작전 게이트 · 전투 세션 복귀</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 13</small><b>내부 성장 · 무기·방어구·모듈 Google Sheets 연동</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 14</small><b>2.5~5배 회수 · 유한 적 재생성 · 핵앤슬래시 무브먼트</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 15</small><b>방 전체 공개 · 통로 정면 원뿔 시야 · 다른 방 차단</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 16</small><b>맵 비례 적 증원 · 최소 2.5배 회수 가치 · 모듈 전수 감사</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 17</small><b>화면 크기 방 · 안개 · 금고형 자원 회수</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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
          <summary><span><small>UPDATE 18</small><b>U 장비 · 모듈 인벤토리 UI 개편</b></span><em class="sfh-chevron">&#x2304;</em></summary>
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

검색 전 TOP 10, 기획 영역 바로가기와 개인 탐색 순위의 동작은 [위키 실시간 검색 사용법](getting-started/search-wiki.md)에서 확인합니다.
