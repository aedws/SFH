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
  <summary><span class="sfh-day-title"><b>2026-09-03</b><i class="sfh-latest">최신</i><small>9 UPDATE BUNDLES · BUILD 18 · IMPROVE 22 · CHANGE 18 · FIX 19</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>9</b><small>UPDATE BUNDLES</small></span><span><b>18</b><small>BUILD</small></span><span><b>22</b><small>IMPROVE</small></span><span><b>18</b><small>CHANGE</small></span><span><b>19</b><small>FIX</small></span></div>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 9</small><b>보스 등장 경고 · 외곽 접근 방향</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 보스가 나타나면 짧게 경고하고, 화면 밖에서 오는 방향을 외곽 화살표로 알려줍니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>추격·일반 보스 등장 배너와 보스별 화면 외곽 방향 표시를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>카메라·줌에 맞춰 방향을 갱신하고 화면 안 진입·처치·가방·일시정지 시 표시를 정리해 전투 시야를 확보합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>추적·좌표·표현·수치를 독립 모듈로 분리하고 8방향·4화면 크기·실제 I/ESC E2E를 필수 검사에 추가했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>보스 발생 임계·드랍·전투 수치는 변경하지 않았습니다.</p></div>
        <p><a href="features/elite-pursuit/">경고·방향 표시 규칙 →</a> · <a href="quality/e2e-play-session/">검증 범위 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>P6 로컬 완결 · 장비 드랍으로 한 판 파밍</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 주운 장비·모듈·파츠를 실제 가방에서 사용하고 탈출해 반출합니다. 시즌 마감 후 칭호·오라도 장착할 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>실물 가방 획득, 방·적·보스 드랍 연결, 시즌 칭호·오라 지급/장착을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>네 방의 무기→방어구→모듈→파츠 순환과 가방 부족·태그 불일치 안내로 한 판의 파밍 목적을 명확히 했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>LootTable 77행·SeasonReward 6행을 Sheet/CSV에 반영하고 생성·가방·정산·지급·표현의 모듈 경계를 분리했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>장비 정의 초기화 순서로 인한 반출 누락, 가방과 창고 이중 보유, 실패한 획득 입력이 다른 상호작용으로 전달되는 경로를 차단했습니다.</p></div>
        <p>실제 네 방·F/I·장착·보스·탈출·사망 자동 E2E를 통과했습니다. P6는 로컬 프로토타입 완료이며 실서비스 계정·서버 검증 지급은 별도입니다. 과금·도메인은 변경하지 않았습니다.</p>
        <p><a href="features/field-loot-acquisition/">한 판 파밍 방법 →</a> · <a href="features/ranking-provider/">시즌 명예 보상 →</a> · <a href="quality/e2e-play-session/">검증 범위 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>50% 회수 추격 보스 · 거점 인벤토리 자유 전환</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 진입비의 절반을 회수하면 보스가 한 번 등장합니다. 방을 클리어해 문이 열려도 추격과 전투는 끝나지 않습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>추격자를 명시적 보스 역할로 생성해 보스 격파·랭킹 집계에 연결했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>거점 I/U/E 여섯 방향 전환, 장비·모듈·파츠 변경 후 최신 편집본과 저장 확인을 실제 입력으로 검증합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>기존 100% 회수·엘리트 1~2기를 50% 회수·추격 보스 1기로 변경했습니다. 임계·수량·재시도는 정책 Resource로 분리합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>열린 장비 창 재진입 후 거점이 멈추던 일시정지 오류와, 생성 실패가 추격자의 1회 등장 기회를 소모하던 오류를 수정했습니다.</p></div>
        <p>101 C 진입은 51 C, 무료 작전은 첫 1 C 회수 기준입니다. 보스 처치 뒤 같은 런에서 재생성하지 않습니다. Sheet 목록·과금 변경 없음.</p>
        <p><a href="features/elite-pursuit/">추격 보스 →</a> · <a href="features/grid-inventory/">거점 편집 →</a> · <a href="quality/e2e-play-session/">검증 목록 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>체크박스 판독 정정 · 보스 격파 · 로컬 시즌</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 출격 전에 시즌 참가 조건과 종료 시각을 확인하고, 보스 격파를 포함한 결과와 마감 이력을 읽을 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>보스 격파 계측·제출과 P6-03 로컬 시즌 기간·참여·마감 저장·조회 모듈을 연결했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>준비 단계의 참가 안내·기록 버튼과 결과 화면의 보스·시즌 상태로 집계 여부를 설명합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>시즌 경계·재시작·선택 제거 E2E, 역할 작업실·기획 요청을 현행화했습니다. 다음 작업은 P6-04 보상입니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>Notion No를 참으로 읽던 오류(실제 0/6), 보스 격파 통계 누락, 방 생성에서 보스 확정 조건이 빠지던 경로를 수정했습니다.</p></div>
        <p>주간 7일·페널티 10·보스 동점 정렬은 임시 정책입니다. 실제 서버·명예 보상은 미구현입니다.</p>
        <p><a href="features/ranking-provider/">시즌 동작 →</a> · <a href="design/master-gdd-alignment/">판독 정정 근거 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>위키 검색·플레이 구분과 실행 아이콘 정렬</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 원형 삼각형 대신 청록색 게임 플레이 버튼을 표시하고 문서 검색은 돋보기와 검색 문구로 구분합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>독립 헤더 스타일과 폰트에 의존하지 않는 SVG 실행 아이콘을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>휴대폰에서도 검색·플레이 글자를 유지하고 44px 클릭 영역과 키보드 포커스를 적용했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>검색은 현재 위키, 플레이는 새 게임 탭이라는 동작과 안내·검증 계약을 분리했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>아이콘을 밀던 점멸 가상 요소와 검색창이 헤더·모바일 문서 너비를 침범하던 스타일을 제거했습니다.</p></div>
        <p><a href="getting-started/search-wiki/">사용법 →</a> · <a href="quality/wiki-responsive-e2e/">화면별 검증 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>위키 문서형 탐색 · 큰 문서에서 작은 문서로</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 긴 기능 목록 대신 SFH 종합 문서에서 작전·전투·장비·전리품·성장 주제를 읽고, 필요한 세부 문서로 내려갑니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>주제별 상위 문서와 빌드 시 자동 생성하는 상위·하위 문서 탐색을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>목차·읽는 순서·모바일 한 열 링크를 제공하고, 전체 노드맵은 필요할 때만 펼칩니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>역할 작업실과 검색 진입점을 종합 문서로 연결하고 탐색·추가 문서 작성 안내를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>상위 문서에서 빠진 세부 링크와 고정 문서 수 안내를 정리하고, 실제 출력 HTML의 누락·깨진 링크를 검사합니다.</p></div>
        <p><a href="features/">SFH 종합 문서 →</a> · <a href="getting-started/search-wiki/">읽는 방법 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>통합 인벤토리 · 이동·장착·저장 확인</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 보기만 하던 I 가방에서 아이템 이동, 장비 교체, 무기·방어구 모듈 편집까지 처리하고 탭을 나갈 때 저장 여부를 선택합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>원본과 분리된 편집본, 무기/방어구 모듈 탭, 저장·취소·계속 편집 확인을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>장비→스탯→스크롤 가방→상세 정보 배치, 칸 크기 자동 조정, 작은 화면 세로 구성을 적용했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>이동·장착·해제 입력, 캐릭터 수치 미리보기, 4해상도×3탭과 저장 흐름 E2E를 연결했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>미저장 이탈, 가방 공간/슬롯 불일치 시 손실, 편집 중 원본 변경의 무단 덮어쓰기를 차단했습니다.</p></div>
        <p><a href="features/grid-inventory/">편집·저장 범위 →</a> · <a href="quality/e2e-play-session/">인벤토리 E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>첫 작전 튜토리얼 · 화면 가림과 조작 안내 수정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 화면을 가로지르던 검은 안내판을 좌상단 338px 카드로 축소하고, 튜토리얼이 열린 상태까지 전투 시야 검사에 포함했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>열린 안내판의 4화면×4단계 경계·실제 버튼 클릭·이동·임무 복원 회귀를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>임무 영역을 안내와 공유하고, 44px 조작 버튼과 짧은 문장으로 중앙 전장을 비웠습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>대시는 회피, 점멸은 별도 스킬로 설명하며 스킬·지도·상호작용 키 재설정도 안내에 반영합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>좌우 앵커로 인한 화면 밖 확장, 줄바꿈 전 최소 높이 잔류, 튜토리얼을 닫은 뒤에만 시야를 검사하던 누락을 해결했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>전투 HUD · 중앙 시야 확보</b></span><em class="sfh-chevron">⌄</em></summary>
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
