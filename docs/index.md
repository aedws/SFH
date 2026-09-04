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
  <article><span>PREPARE</span><b>PC / 모바일 가로 선택</b><p>모바일은 기기를 가로로 돌려 주세요. 로비에서 준비한 뒤 게이트에서 F 또는 모바일 ‘사용’을 누릅니다.</p></article>
  <article><span>SKILL</span><b>1 · 2 · 3</b><p>점멸, 지속형 자기장, 이동 가속을 상황에 맞게 사용하세요.</p></article>
  <article><span>ESCAPE</span><b>F / M</b><p>보상을 회수하고 지도와 탈출 지점을 확인해 살아서 돌아오세요.</p></article>
</section>

<div class="sfh-notes sfh-public-release">
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-04</b><i class="sfh-latest">최신</i><small>5 UPDATE BUNDLES · BUILD 11 · IMPROVE 11 · CHANGE 17 · FIX 9</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>5</b><small>UPDATE BUNDLES</small></span><span><b>11</b><small>BUILD</small></span><span><b>11</b><small>IMPROVE</small></span><span><b>17</b><small>CHANGE</small></span><span><b>9</b><small>FIX</small></span></div>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 5</small><b>P7-03 · 반출 설계도 영구 등록과 제작 후보</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 작전에서 반출한 설계도가 재접속 뒤에도 남고, 제작소에서 제작 가능 여부를 바로 확인할 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>영구 도면 등록, Recipe 조회, 반출 해금 규칙을 독립 모듈로 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>제작소 버튼의 도면 X/Y와 후보별 가능/잠김 상태, 잘못된 도면·중복 등록 차단을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>P5 계약·CI와 P7 로드맵·검색·기획 요청·E2E·모듈 감사를 P7-04 다음 순서로 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>기존 기능 결함 수정이 아닌 제작 해금 구조 확장입니다.</p></div>
        <p>Google Sheet Recipe는 현행 CSV와 동일했습니다. Item에 중복된 Utility 4행은 반영하지 않고 정리 요청으로 분리했으며 과금 모델은 건드리지 않았습니다.</p>
        <p><a href="features/blueprint-crafting/#p7-03">설계도 제작 →</a> · <a href="development-status/">전체 상태 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>개발자 코드맵 우선 · P7-02 상점 회전/리롤</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 개발자는 로그인 직후 실제 코드 관계망부터 보고, 플레이어는 작전 복귀 갱신과 가격이 보이는 리롤을 사용할 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>런 종료 1회 자동 회전, 25 C 유료 리롤 영수증, 실제 소스 기반 코드 모듈 노드맵의 개발자 첫 화면 배치를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>회전 정책·런 상태·차감 서비스를 분리하고 이전 매물을 우선 회피하며 품질군 가시성을 유지합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>P7 작업선·기획 요청·검색·E2E·모듈 감사를 P7-02 완료와 P7-03 다음 순서로 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>거점 복귀 신호의 중복 회전, 조립 취소 뒤 매물 변경, 리롤 중복 차감과 오래된 선택 구매를 차단했습니다.</p></div>
        <p>현행 가격·슬롯·회전 규칙은 임시 Resource입니다. Sheet 목록·결제 상품·Cloudflare 과금 설정은 변경하지 않았습니다.</p>
        <p><a href="features/hub-economy/#p7-02">상점 회전 규칙 →</a> · <a href="architecture/code-module-map/">코드 관계 웹 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>품질 시스템 모듈화 강화 · 저장과 CI 안전망</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기존 상점→가방→장착 성능은 유지하면서 품질 규칙을 데이터로 교체하고, 재시작·모듈 제거·실패 보상까지 자동 검증합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>교체 가능한 품질 Resource, 공용 품질 payload 계약, 실물 지급 단독 제거 E2E를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>장비·모듈·UI의 품질 해석을 하나로 통합하고 Windows 별도 프로세스 저장 검사를 품질까지 확장했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>품질/제거성 테스트와 코드 노드맵 최신성 검사를 GitHub 필수 CI 흐름에 연결했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 4</h3><p>노드맵이 소스보다 뒤처지는 문제, 교체 공급자 롤백 실패 때 지급품과 환불액을 함께 얻을 수 있는 경로, 저장 품질 미검증을 차단했습니다.</p></div>
        <p>가격·성능 배율 CSV와 플레이 결과는 유지합니다. 옵션·소켓은 임시 Resource이며 결제 상품·Cloudflare 과금 설정은 변경하지 않았습니다.</p>
        <p><a href="features/p5-hub-progression/#quality-module-contract">모듈 계약 →</a> · <a href="quality/e2e-play-session/#p7-shop-e2e">품질 E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>P7-01B · 품질 장비 실물 지급과 실제 성능</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 상점에서 산 물건이 I 가방에 들어오고 U/E 장착 뒤 품질 배율로 실제 수치가 달라집니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>손상·표준·고성능별 실물 인스턴스와 품질 배율·옵션·소켓 보존, 가방→장비 실제 능력치 적용을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>상점에서 창고 수량 대신 가방 보유량·공간과 실제 지급 결과를 보여주며, 장착/해제 뒤에도 품질을 잃지 않습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>품질 정책·가방 지급 어댑터·장비 계산을 분리하고 E2E·모듈 감사·로드맵을 새 계약에 맞췄습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>구매품이 I/U 흐름과 단절되던 문제와 장착 왕복 중 품질 정보가 사라질 수 있던 경로를 제거했습니다.</p></div>
        <p>기존 확정 CSV 6행을 재사용했으며 가격·배율·옵션·소켓은 임시값입니다. Google Sheet 목록·결제 상품·Cloudflare 과금 설정은 변경하지 않았습니다.</p>
        <p><a href="features/hub-economy/#shop-browser">상점 품질 실물 규칙 →</a> · <a href="quality/e2e-play-session/#p7-shop-e2e">플레이어 인식 E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>잔여 작업 재대조 · P7-01B 다음 순서 유지</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 공개 기획 원문과 최신 배포 코드를 다시 대조해 다음 작업과 승인 대기 범위를 분리했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>상태 점검만 수행했으며 새 게임 기능이나 밸런스 수치를 완료로 계산하지 않습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 0</h3><p>기존 플레이·모바일·위키 UI는 변경하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>Notion v1005·77블록·해시 614a0b8ddee4가 동일함을 확인했습니다. 기능 가중 추정치 94%를 유지하고 다음 작업을 P7-01B 실제 품질 성능·실물 I/U 지급으로 고정했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>코드 변경이나 오류 수정은 포함하지 않습니다.</p></div>
        <p>후속 순서는 P7-01B→P7-02~04→P8→P9→P10입니다. 온라인 계정·검증 서버·서버 확정 시즌 보상은 별도 승인 전 미착수입니다.</p>
        <p><a href="development-status/">상세 잔여 작업과 산정 근거 →</a></p>
      </div>
    </details>
  </div>
</details>
</div>
