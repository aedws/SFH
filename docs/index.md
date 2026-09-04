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
  <summary><span class="sfh-day-title"><b>2026-09-04</b><i class="sfh-latest">최신</i><small>12 UPDATE BUNDLES · BUILD 31 · IMPROVE 41 · CHANGE 51 · FIX 28</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>12</b><small>UPDATE BUNDLES</small></span><span><b>31</b><small>BUILD</small></span><span><b>41</b><small>IMPROVE</small></span><span><b>51</b><small>CHANGE</small></span><span><b>28</b><small>FIX</small></span></div>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 12</small><b>무기 고정 정체성 · 고유 스킬·옵션·타격 인지</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 무기마다 명중 누적 고유 효과와 구분되는 타격 표현이 생기고, 무기·방어구 옵션은 내부/외부 성장과 모듈에 흔들리지 않는 장비 고유값으로 유지됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>고정 옵션 Resource·payload 어댑터·고유 스킬 정의/발동기·잠금 CSV 조회기를 독립 모듈로 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>5개 무기의 총구 섬광, 투사체 glow, 충격 색·크기·카메라 반응과 명중 누적 전기 효과를 구분했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>Weapon/Armor Sheet, 7행 확정 CSV, 장비 UI, 검색, 모듈 감사와 E2E 계약을 고정 정체성 기준으로 확장했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>발사 후 Q 교체 시 탄환 정체성 혼선, 성장 배율의 고유 효과 침범, 획득 옵션이 실제 장착 계산으로 이어지지 않던 단절을 차단했습니다.</p></div>
        <p>전체 구조는 기능 57·클래스 231·의존 26·순환 0·Scene 침범 0입니다. 신규 수치는 임시값이며 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/equipment-fixed-identity/">장비 고정 정체성 →</a> · <a href="architecture/module-audit/#equipment-fixed-identity-2026-09-04">모듈 감사 →</a> · <a href="quality/player-perception-audit/#equipment-fixed-identity-perception-2026-09-04">인식 검사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>P8 체감 전수 감사 · 보이지 않던 계측과 반복 측정 복구</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 구현돼도 화면 밖이라 알 수 없던 훈련 계측과 무료 세팅이 화면 안에 배치되고, 큰 빈 패널이 사라지며, 더미 재생성 뒤에도 새 측정이 즉시 시작됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>뷰포트 크기만 받아 계측·세팅·스킬 패널을 배치하는 독립 <code>TrainingHudLayout</code>을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>우측 상단 계측, 바로 아래 무료 세팅, 우측 하단 84px 스킬 HUD로 정보 위치와 문구·중앙 시야·반복 피드백을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>P8 계약·실제 Game E2E·CI 마커·모듈 감사·플레이어 인식 문서를 화면 내부·비겹침·재측정 기준으로 강화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>계측/세팅 패널의 음수 X 화면 이탈, 내용 없는 240px 중앙 가림, 자동 reset 뒤 고정 결과만 남던 생명주기 불일치를 제거했습니다.</p></div>
        <p>전체 구조는 기능 57·클래스 226·의존 26·순환 0·Scene 침범 0입니다. Sheet/CSV·밸런스·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="quality/player-perception-audit/#p8-perception-audit-2026-09-04">체감 감사 →</a> · <a href="architecture/module-audit/#p8-perception-audit-2026-09-04">모듈 감사 →</a> · <a href="features/training-ground/">훈련장 계약 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>코드 모듈 지도 초안 · 방향 고정과 한글 역할명</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 개발자는 선택 기능을 가운데 두고 왼쪽 사용처와 오른쪽 의존처를 바로 구분하며, 기획자는 한글 이름과 업무 영역으로 필요한 시스템을 찾을 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>게임 기능과 플레이 수치는 변경하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>고정 방향 관계도, 한글 역할명, 9개 업무 영역 필터, 탐색 이력, 모바일 목록 전환을 적용했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>60개 코드 모듈의 역할·영역 메타데이터와 생성 스키마·CI 계약·설명 문서를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>기존 결함 수정이 아니라 구조 판독성을 높이는 위키 초안입니다.</p></div>
        <p>실제 GDScript 272개를 다시 스캔하며 새 목록·Sheet/CSV·게임 데이터·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="architecture/code-module-map/">직관형 코드 모듈 지도 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>P8 마감 · 계측 HUD·무비용 세팅 복원·산출물 정리</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 훈련에서 실제 DPS·AP·쿨타임을 읽고 장비·스킬을 비용 없이 시험한 뒤, 작전 준비로 나가면 원래 세팅으로 안전하게 돌아옵니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 6</h3><p>타격 수집기, 시간창 서비스, 계측 HUD, 로드아웃 스냅샷·복원 서비스·자유 세팅 UI를 독립 모듈로 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>DPS·최대 타격·누적 피해·AP/s·평균 쿨타임을 압축하고, 격리된 실제 스킬 런타임과 종료 결과 고정을 연결했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>P8 로드맵·기획자/개발자 화면·검색·E2E·모듈 감사를 P8 완료와 P9-01 다음 순서로 현행화하고 Actions 산출물 최신 1세트 유지 정책을 CI에 추가했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>훈련 종료 중복 final 신호, 작전 준비 화면 위에 남던 계측 결과, 이동한 적을 생성 위치로 오판해 간헐 실패하던 스폰 안전 판정을 차단했습니다.</p></div>
        <p>GitHub Actions 산출물 430개 약 7.15GB를 정리해 최신 성공 런의 Web·Windows·위키 3개만 유지합니다. 새 목록이 없어 Sheet/CSV와 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/training-ground/">P8 완료 흐름 →</a> · <a href="architecture/module-audit/#p8-complete-2026-09-04">모듈 감사 →</a> · <a href="quality/e2e-play-session/#p8-training-ground-e2e">P8 E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>플레이 감각 회귀 · 스폰 안전·상호작용·첫 레이아웃 수정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 방에 들어가자마자 포위되어 사망하거나, F 안내가 보이는데 실행되지 않고, 가방 첫 화면이 겹쳐 보이던 체감 오류를 실제 플레이 기준으로 고쳤습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>적 수량과 분리된 교체형 RoomEncounterSpawnSafetyPolicy를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>288px 생성 배제, 1.6초 접촉 피해 유예·반투명 전개, 훈련 타격 즉시 수치, 모바일 14% 점유 예산·44px 터치 표적을 적용했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>훈련 더미를 단말에서 분리하고, 작전 2단계를 읽기 전용 READY 확인표로 바꾸며, 첫 가방 레이아웃을 컨테이너 정렬 뒤 확정합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 6</h3><p>게이트·거점 시설·보상함의 프롬프트/실행 범위 불일치, 첫 가방 압축, 즉사형 근접 생성, 훈련 단말 겹침을 회귀 테스트로 차단했습니다.</p></div>
        <p>방당 12~34기와 경제·과금 데이터는 변경하지 않았습니다. 전체 E2E와 대형 전장 60fps CPU 예산을 통과했습니다.</p>
        <p><a href="features/room-encounters/#spawn-safety">방 스폰 안전 계약 →</a> · <a href="quality/e2e-play-session/#player-perception-regression-2026-09-04">플레이어 인식 회귀 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>P8-01 · 실제 단일·밀집 더미 훈련장</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 거점 훈련 단말에서 단일 보스와 밀집 8기를 전환하고, 실제 공격·자동 초기화를 보상 없이 반복할 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>시나리오 Resource, 더미 생성기, 초기화 서비스, 훈련장 façade와 실제 거점 단말을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>좌클릭 피해·스마트 타게팅·타격 기록을 실제 더미에 연결하고 밀집 배치의 겹침과 반복 측정 동선을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>TrainingScenario 12열 전체 스키마, Manifest 선택 제거, 코드 노드맵, P8 로드맵·검색·E2E 문서를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>거점 기능을 끈 선택 빌드에서 훈련장 선행 의존성이 전체 Manifest 오류로 번지던 경계를 차단했습니다.</p></div>
        <p>일반 적 스폰·경험치·전리품·처치·방 보상에는 영향을 주지 않습니다. 기존 TrainingScenario 2행을 재사용했으며 임시 수치와 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/training-ground/">P8-01 플레이와 구조 →</a> · <a href="quality/e2e-play-session/#p8-training-ground-e2e">실제 플레이 E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>P7-04 · 원자적 맞춤 제작과 전체 모듈 감사</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 제작 전에 비용·재료·옵션/소켓 범위를 확인하고, 실제 결과와 거래 기록이 한 번에 저장됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>Roll 정책, 원자적 제작 거래, 전체 시스템 모듈 검사기를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>견적 선공개, 중복 없는 실제 옵션, 실제 소켓, 재접속 보존을 연결했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>단일 프로필 거래·P5 façade·69개 Manifest 플래그·CI·P8 다음 작업선을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>제작 저장 실패 부분 차감, 세부 표현 모듈 실행 목록 누락, 테스트 저장 경로의 프로세스 간 충돌을 차단했습니다.</p></div>
        <p>전체 감사: 기능 56·클래스 213·의존 25·순환 0·서비스 Scene 침범 0. Sheet/CSV와 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/blueprint-crafting/#p7-04">원자적 제작 →</a> · <a href="architecture/module-audit/#p7-04-2026-09-04">전체 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
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
