---
title: 개발 현황과 업데이트
description: 날짜와 구현·개선·수정·버그픽스로 묶은 SFH 릴리스 노트와 기능 진행 상태
tags:
  - 개발 현황
  - 진행률
  - 업데이트
  - 릴리스 노트
  - 구현
  - 개선
  - 수정
  - 버그픽스
---

<div class="sfh-section-head">
  <div><span class="sfh-kicker">RELEASE NOTES</span><h1>📢 SFH 업데이트</h1></div>
  <p>공동 작업자가 코드 저장소를 열지 않아도 날짜별 핵심 변경, 상세 구현과 검증 상태를 확인할 수 있습니다.</p>
</div>

<div class="sfh-release-stats"><span>최신 2026-09-01</span><span>SEARCH COMMAND</span><span>4 DAYS · 53 TOPICS</span><span>59 DOCS · CLOUDFLARE LIVE</span></div>

## 기획 기준 진행도

<div class="sfh-progress-panel">
  <div class="sfh-progress-heading">
    <span><small>MASTER GDD ALIGNED · 2026-09-01</small><strong>현재 기획 진행도</strong></span>
    <b>75%</b>
  </div>
  <div class="sfh-progress-track" role="progressbar" aria-label="SFH 기획 진행도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="75"><i style="width: 75%"></i></div>
  <p>공개 Master GDD의 8개 확정 시스템을 저장소와 재대조하고 2026-09-01에 다시 확인했습니다. 원문 범위 변화가 없어 게임 기능 진행도는 75%를 유지하며, 배포·보안 작업은 이 수치에 가산하지 않았습니다.</p>
</div>

권위 있는 기획 원본은 [게시된 SFH 프로젝트 Master GDD](https://wobbly-pawpaw-1ff.notion.site/SFH-6b45b728004082af8a4a811ef0a1c5e9)입니다. 2026-09-01 공개 페이지의 실제 렌더링 본문 `0~8장`을 읽었습니다. 현재 본문에는 `(미확정)` 표기가 없으므로 모두 확정 요구로 처리합니다. 핵심 플레이 흐름은 ×2, 기반·확장 서비스는 ×1을 적용하며 실제 코드·데이터·자동 검증만 완료 근거로 사용합니다. 전체 상세 대조는 [Master GDD 구현 대조](design/master-gdd-alignment.md)에 기록했습니다.

재확인 시 공개 원문의 요구와 Phase 1~6 체크 상태는 이전 대조 이후 달라지지 않았습니다. Notion 체크박스는 수동 현황이므로 완료 근거로 승격하지 않고, 저장소 구현과 플레이어 인식 E2E를 기준으로 판정합니다.

| 기획 묶음 | 가중치 | 구현률 | 현재 근거 |
|---|---:|---:|---|
| 기술 기반 | ×1 | 100% | Godot 4.x·GDScript·CharacterBody2D·Area2D·TileMapLayer·Camera2D와 기능별 Node/Scene 경계 구현 |
| 입력·자유 스킬 바인딩 | ×2 | 100% | 물리 키와 스킬→Action 배치를 분리하고 충돌 교환·HUD 반영·JSON 저장·초기화를 구현 |
| 스마트 자동 타게팅 | ×2 | 95% | 최근접·최대 HP·엘리트·밀집 중심·이동 벡터·자기 대상을 정의별로 선택하고 무기·스킬에 연결. 추가 콘텐츠 튜닝이 남음 |
| 로비 인베스트먼트·타겟 파밍 | ×2 | 65% | 맵·지역·난이도·페널티·상점 구현. 캐릭터와 완성형 무기·스킬·유틸리티 투자 UI가 남음 |
| 전리품 2대 분류·현장 파밍 | ×2 | 25% | 크레딧·도면·상점 등록 구현. 현장 장비/스킬 교체, 세션 룬·코어·유물 소켓과 자동 환전은 없음 |
| 가변 태그·등급 확장 | ×1 | 80% | 동적 태그·등급·불일치 비활성·메커니즘 변형 구현. 무기별 독립 스킬 프리셋이 남음 |
| 탈출·생환·파산 방지 | ×2 | 95% | F 방어전, 이탈 일시정지·재개, 성공·사망 정산, 무료 기본 진입 구현. 신규 룬 환전 연결이 남음 |
| 비동기 랭킹·시즌 보상 | ×1 | 40% | 동일 조건 3대 로컬 랭킹 구현. 서버 검증과 주간 칭호·오라 보상은 없음 |

계산식은 `Σ(기획 묶음 구현률 × 가중치) ÷ 13`입니다. 현재 결과는 `(100×1 + 100×2 + 95×2 + 65×2 + 25×2 + 80×1 + 95×2 + 40×1) ÷ 13 ≈ 75%`입니다.

`완료`는 클래스나 UI가 존재한다는 뜻이 아니라 최신 기획의 동작 조건까지 충족한 경우입니다. 현재 빌드는 거점→작전→파밍→탈출→정산을 플레이할 수 있지만, 아래 규격 차이가 남아 있습니다.

#### 기획 마일스톤 판정

| Phase | 판정 | 저장소 대조 |
|---|---|---|
| Phase 1 · 이동·타게팅·자유 바인딩 | 완료 | 키 배치와 스킬 배치를 분리하고 실제 발동·HUD·영구 저장까지 연결 |
| Phase 2 · Q·태그·AP·쿨타임 | 완료 | 주·보조 교체, 태그 호환성, 에너지·충전·개별 쿨타임 구현 |
| Phase 3 · 탈출 방어·정산 | 완료 | F 방어전, 이탈 일시정지·재개, 성공·사망 정산 자동 검증 |
| Phase 4 · 현장 교체·룬 소켓·환전 | 미완료 | 장비/스킬 현장 드랍·즉시 교체와 세션 룬 자동 환전이 없음 |
| Phase 5 · 로비 4대 세팅·계약·상점 | 부분 완료 | 계약·페널티·상점은 구현. 캐릭터·무기·스킬·유틸리티 선택 흐름이 불완전 |
| Phase 6 · 비동기 랭킹·시즌 보상 | 로컬 기반 | 3대 로컬 보드만 구현. 서버 제공자와 칭호·오라 보상이 없음 |

### 2026-09-01 Master GDD 재대조·재확인

- **새 확정:** 단순 키 변경이 아닌 스킬과 Action의 자유로운 1:1 배치가 필요합니다.
- **새 확정:** 무기·스킬·도면은 현장 교체와 영구 해금, 룬·코어·유물은 세션 증폭과 탈출 자동 환전으로 분리됩니다.
- **새 확정:** 로비 준비는 캐릭터·무기·스킬·유틸리티 네 범주를 모두 투자 대상으로 다룹니다.
- **새 확정:** 랭킹은 비동기 공식 기록과 주간 시즌 칭호·오라 보상까지 포함합니다.
- **유지:** 스마트 타게팅, Q 교체, AP·쿨타임, 탈출 일시정지·재개, 파산 방지 기본 무장은 기존 구현 방향과 일치합니다.

### 앞으로 해야 할 작업

| 우선순위 | 작업 | 현재 차이 | 완료 조건 |
|---:|---|---|---|
| 완료 | Phase 1 자유 스킬 배치 | 물리 키와 스킬 위치의 두 단계 편집 구현 | 충돌 교환·HUD/발동·JSON 복구와 실제 K/ESC E2E 완료 |
| 완료 | 배포·보안 작업선 | Pages·Worker·비공개 R2가 섞여 보일 수 있었음 | 문서·플레이·원본 보관 표면 분리, 이중 백업·복구 PR·정적 경계 검사 완료 |
| 1 | Phase 4 전리품 생명주기 | 크레딧·도면 중심 | 영구 자산형과 세션 증폭·환금형의 획득·탈출·사망 정책 분리 |
| 2 | Phase 4 현장 순환 | I/U 장착·영구 모듈 기반만 존재 | 드랍→비교→교체/소켓→전투 변화→해금/환전 E2E 통과 |
| 3 | Phase 5 로비 4대 세팅 | 맵·페널티·상점·소모품 일부 구현 | 캐릭터·무기·스킬·유틸리티 투자와 BEP 미리보기 연결 |
| 4 | Phase 6 비동기 시즌 | 3대 로컬 랭킹 구현 | 서버 검증 제공자와 주간 칭호·오라 보상 모듈 연결 |

세부 작업 ID와 중단 조건은 [현행 마일스톤 작업 라인](design/current-milestone-workline.md)에서 추적합니다.

<div class="sfh-notes">
<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-09-01</b><i class="sfh-latest">최신</i><small>12 UPDATE BUNDLES · BUILD 33 · IMPROVE 43 · CHANGE 47 · FIX 18</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>12</b><small>UPDATE BUNDLES</small></span><span><b>33</b><small>BUILD</small></span><span><b>43</b><small>IMPROVE</small></span><span><b>47</b><small>CHANGE</small></span><span><b>18</b><small>FIX</small></span></div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>M 확장 지도 워프 · 전투 방 완주 조기 탈출 · 크레딧 보상 박스</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 방 전투의 끝을 탐색·회수·조기 탈출로 직접 연결</strong>
          <ul>
            <li><b>조기 탈출:</b> 최대 교전 방을 확보했거나 적 생성 예산이 최소 무리보다 작아진 시점에, 9~10분 타이머를 기다리지 않고 탈출 신호가 열립니다.</li>
            <li><b>M 지도:</b> 우측 상단 저점유 지도는 그대로 유지하고, M을 누르면 화면 중앙의 클릭 가능한 전체 지도로 확대합니다.</li>
            <li><b>조건부 워프:</b> 시작 지역·끝 지역·클리어한 4방향 교차 방만 후보로 표시합니다. 방 봉쇄 중이거나 미클리어 일반 방이면 서버 역할의 워프 서비스가 다시 거부합니다.</li>
            <li><b>방 보상:</b> 접촉형 내부 경험치 1개 대신 방 면적과 ±1 난수 보정으로 F 상호작용 크레딧 박스 1~5개를 생성합니다.</li>
            <li><b>검증:</b> 실제 M 키와 지도 클릭, 미클리어 거부, 제한 시간 전 개방, F 크레딧 회수, 선택 모듈 제거, 대형 34기 성능을 자동 판정했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>성능 결과</b><span>1280×720 GL Compatibility, 대형 방 34기·전기 효과 3개에서 평균 6.894ms, 피크 8.948ms, Node 최대 1,773개로 60 FPS CPU 예산 통과.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 4</h3><p>전투 방 완료 Signal, M 확장 지도, 조건부 RoomWarpSystem, 방 크기 기반 크레딧 보상 박스를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 4</h3><p>완주 후 대기 제거, 지도 탐색 동선 단축, F 회수 감각, 실제 입력 E2E 범위를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 3</h3><p>방 보상 경제, 맵 방향 스냅샷, 키 설정 카탈로그를 각각 크레딧·4방향·22개 Action 기준으로 수정했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3><p>확장 레이아웃 첫 프레임에도 클릭 영역이 음수 또는 0이 되지 않도록 양수 사각형으로 보정했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>전체 문서 노드맵 · 안정 주소 · 반응형 계층 탐색</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 추천 문서 8개가 아니라 위키 55개 전체를 대→중→소→세부 계층으로 찾습니다.</strong>
          <ul>
            <li><b>404 수정:</b> 현재 페이지 상대 주소 대신 <code>knowledge-map.js</code>의 고정 배포 위치에서 <code>/SFH/</code> 루트를 산출해 모든 문서 링크와 JSON 요청에 적용합니다.</li>
            <li><b>홈 통합:</b> 기존 자주 찾는 카드 위치에 같은 노드맵 컴포넌트를 장착해 중복 탐색 UI를 제거했습니다.</li>
            <li><b>반응형 CSS:</b> 넓은 화면 4열, 992px 이하 2열, 640px 이하 1열로 바꾸고 모든 분기 노드를 연결 레일에 시각적으로 묶습니다.</li>
            <li><b>회귀 차단:</b> 55개 Markdown·내비게이션·JSON 경로 일치에 더해 루트 이탈 주소와 불안정한 런타임 URL 생성도 빌드에서 거부합니다.</li>
          </ul>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 1</h3><p>홈 명시 마운트와 문서 하단 자동 마운트를 공유하는 전체 노드맵 컴포넌트를 구성했습니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3><p>계층 인지, 터치 조작성, 화면 폭별 정보 밀도를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 2</h3><p>홈 탐색 구조와 지식 그래프 데이터 날짜·버전을 현재 빌드 기준으로 수정했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3><p>Material 즉시 이동 뒤 최초 문서의 `base`가 남아 노드 경로가 중첩되던 404를 제거했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>모바일 위키 전면 최적화 · 전체 화면 검색 · 4단계 실브라우저 E2E</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 기획자와 개발자가 휴대폰에서도 같은 정보 구조를 읽고 검색하고 검증 근거까지 추적합니다.</strong>
          <ul>
            <li><b>모바일 검색:</b> 6px로 접혀 보이지 않던 출력 영역을 <code>100dvh</code> 전체 화면과 독립 스크롤로 복구하고, 입력 전 우선 문서와 입력 후 실시간 결과를 모두 검증했습니다.</li>
            <li><b>반응형 읽기:</b> 320·390px에서 페이지 가로 넘침 없이 본문 15.2~16px, 44px 터치 목표, 1열 노드맵을 유지합니다.</li>
            <li><b>태블릿·데스크톱:</b> 768px에서는 넓은 표만 내부 스크롤하고 2열 노드맵을, 1440px에서는 4열 노드맵과 4열 요약을 유지합니다.</li>
            <li><b>동선:</b> PLAN·DEV·QA·DOCS 역할 링크, 문서 맵 검색, 중첩 경로 즉시 이동, 브라우저 플레이 루트까지 실제 클릭으로 확인했습니다.</li>
            <li><b>회귀 게이트:</b> CSS·내비게이션·검색/플레이 루트·56개 문서 데이터 계약을 strict 빌드와 배포 작업에 연결했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>측정 결과</b><span>320×568, 390×844, 768×1024, 1440×900 모두 문서 clientWidth=scrollWidth. 모바일 검색 795px 출력·796px 스크롤 영역, 태블릿 표 724→992px 내부 스크롤, 브라우저 콘솔 오류 0.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3><p>역할 기반 홈 내비게이션과 모바일 위키 E2E 계약·CI 게이트를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 6</h3><p>safe-area, 읽기 폭, 터치 목표, 검색, 표·코드, 고대비·감소 모션까지 반응형 CSS를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 3</h3><p>홈 정보 순서, 4·2·1열 문서맵, 최신 일일 묶음 기본 펼침 규칙을 사용자 동선 기준으로 수정했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 2</h3><p>모바일 검색 빈 화면과 1440px 헤더가 우측으로 101px 넘치던 문제를 실제 브라우저 측정으로 제거했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>Master GDD 재대조 · 진행률 72% · 확정 범위 재분류</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 2026-09-01 게시된 Master GDD 0~8장을 저장소 구현과 다시 대조했습니다.</strong>
          <ul>
            <li><b>입력:</b> 22개 Action의 키 변경은 구현됐지만, 원하는 스킬을 마우스·Space·Q·E·1~9에 배치하는 자유 바인딩은 별도 미완료입니다.</li>
            <li><b>전리품:</b> 크레딧·도면·영구 상점은 있으나 현장 무기/스킬 교체, 룬·코어·유물의 세션 소켓과 탈출 자동 환전은 없습니다.</li>
            <li><b>로비:</b> 맵·지역·난이도·페널티·소모품은 연결됐지만 캐릭터·무기·스킬·유틸리티 4대 투자 흐름은 불완전합니다.</li>
            <li><b>랭킹:</b> 동일 조건 3대 로컬 보드는 있으나 비동기 서버 검증과 주간 칭호·오라 보상은 없습니다.</li>
            <li><b>진행률:</b> 8개 확정 시스템, 핵심 ×2·기반/확장 ×1 산식으로 72%입니다. 기존 96% 대비 하락은 코드 퇴행이 아니라 확정 범위 확대입니다.</li>
          </ul>
          <p class="sfh-intent"><b>출처</b><span>로그인 없이 게시된 SFH 프로젝트 Master GDD 실제 렌더링 본문 · 2026-09-01 확인.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 0</h3><p>상태 감사 결과만 반영했으며 누락 기능을 구현 완료로 표시하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3><p>확정 요구의 출처 추적성과 기획자·개발자 공통 우선순위를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 4</h3><p>진행률 72%, 8개 시스템 근거표, 6개 Phase 판정, 6단계 후속 순서를 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3><p>이전 기획 기준의 96%가 최신 Master GDD를 대표하던 상태 문서 오류를 수정했습니다.</p></div>
        <p><a href="design/master-gdd-alignment/">Master GDD 상세 대조 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>현행 마일스톤 작업 라인 · Phase 1→4→5→6 실행 게이트</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 72% 이후 범위를 기능 목록이 아니라 구현·체감·검증이 끝나는 실행 단위로 다시 작성했습니다.</strong>
          <ul>
            <li><b>BASE:</b> 현재 코어 루프와 모듈 의존 방향을 잠그고 Phase 2·3을 전 구간 회귀선으로 둡니다.</li>
            <li><b>Phase 1:</b> `SkillBindingProfile/Service`로 자유 스킬 배치·충돌·저장·HUD 반영을 완결합니다.</li>
            <li><b>Phase 4:</b> 전리품 정책→드랍·비교→현장 교체·소켓→해금·환전·소실 순으로 연결합니다.</li>
            <li><b>Phase 5·6:</b> 로비 4대 투자와 무료 프리셋을 먼저 안정화한 뒤 비동기 검증과 시즌 보상을 붙입니다.</li>
            <li><b>공통:</b> 모듈 감사, 플레이어 인식 E2E, 평균 PC·웹 성능, Sheet/CSV 공급자, 위키 배포를 묶음마다 통과합니다.</li>
          </ul>
          <p class="sfh-intent"><b>중단 규칙</b><span>필수 E2E 실패, Phase 2·3 회귀, 데이터 마이그레이션 미정, 서버 검증 부재가 있으면 다음 작업 번호로 넘어가지 않습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 0</h3><p>로드맵 작성만 수행했으며 게임 기능 완료율은 72%로 유지합니다.</p></div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3><p>선행 조건, 플레이어 완료 조건, 자동 E2E 추적성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>🧭 수정 · 5</h3><p>2개 기준선·20개 Phase 작업, 5개 공통 게이트, 착수 순서, 모듈 경계, 중단 규칙을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 0</h3><p>별도 게임 버그 수정은 없습니다.</p></div>
        <p><a href="design/current-milestone-workline/">현행 마일스톤 작업 라인 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>위키 접근성·클릭 명확화 · Phase 1 자유 스킬 배치 완료</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 문서 탐색의 오작동을 제거하고 K 입력 설정에서 물리 키와 스킬 위치를 각각 편집할 수 있게 됐습니다.</strong>
          <ul>
            <li><b>위키:</b> 연결선 클릭 가로채기·선택 후 포커스 소실을 제거하고 44px 터치 범위와 명명된 ARIA 관계를 추가했습니다.</li>
            <li><b>입력:</b> 22개 물리 키와 9개 스킬 Action 배치를 분리하고 점유 슬롯 선택 시 두 스킬을 교환합니다.</li>
            <li><b>저장:</b> 물리 키와 스킬 위치를 별도 JSON에 저장하며 재시작·기본값 복구를 검증합니다.</li>
            <li><b>진행:</b> BASE-01/02와 P1-01~05를 완료 처리하고 다음 작업을 P4-01 전리품 분류로 이동했습니다.</li>
          </ul>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>SkillBindingProfile, 충돌 교환·영속 Service, 전투/HUD 배치 Provider 연결을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>K 두 단계 편집, 44px 터치 범위, 스크린리더 관계, 작업선 추적성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>물리 키·스킬 위치 저장을 분리하고 홈을 최신 하루로 제한했으며 진행도를 75%로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>노드 클릭 범위 교차, 재렌더링 포커스 소실, 비활성 버튼처럼 읽히던 루트 노드 의미를 바로잡았습니다.</p></div>
        <p><a href="features/key-mapping/">자유 스킬 배치 →</a> · <a href="design/current-milestone-workline/">다음 작업 라인 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>main 보호 · 독립 E2E · Windows x64 검증 빌드</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 저장소 변경과 배포 산출물이 같은 필수 검증선을 통과합니다.</strong>
          <ul>
            <li>main 직접·강제 푸시와 삭제를 막고 PR·대화 해결·필수 검사를 적용했습니다. 1인 개발 중 승인 수는 0명입니다.</li>
            <li>기존 export-game 내부 E2E 단계를 독립 <code>e2e</code> 잡으로 분리해 보호 규칙에서 직접 요구할 수 있습니다.</li>
            <li>Windows Desktop x86_64 프리셋과 v0.1.0 ZIP·SHA-256 생성기를 추가했습니다.</li>
            <li>BUILD-METADATA.json은 커밋·Godot 4.7.2·CSV 데이터 버전·CSV별 해시를 기록합니다.</li>
            <li>Actions 전체 SHA 고정과 Dependabot 주간 갱신을 구성하고, Cloudflare는 검증 후 GitHub Pages와 병행하는 순서를 유지합니다.</li>
          </ul>
          <p class="sfh-intent"><b>다음 게이트</b><span>이 PR의 export-game·e2e·package-windows·build가 통과한 뒤 e2e를 필수 검사에 추가하고 Actions 허용 목록·SHA 강제를 활성화합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>보호 규칙, 독립 E2E, Windows 패키지, 메타데이터·체크섬을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>공급망과 병합 안전성, 실행물 추적성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>검사 구조와 릴리스 데이터 원장, 화면의 실행 방식 구분, 무중단 전환 순서를 수정했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>존재하지 않는 E2E 컨텍스트를 먼저 요구해 main이 잠길 수 있는 순서 오류를 제거했습니다.</p></div>
        <p><a href="getting-started/run-project/#windows-x86_64">Windows 빌드 규격 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>Cloudflare 무중단 이중 배포 · Worker+R2 게임 게이트웨이</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 검증된 동일 산출물만 Cloudflare 후보 환경에 올리고 기존 GitHub Pages는 유지합니다.</strong>
          <ul>
            <li>위키는 실제 공개 프로젝트 `sfh-dev-wiki` Pages에 Direct Upload하고 `/play/`는 게임 Worker로 넘깁니다.</li>
            <li>Web 빌드는 R2 커밋별 불변 경로에 먼저 저장한 뒤 Worker 활성 커밋을 바꿉니다.</li>
            <li>Windows ZIP·체크섬은 `/downloads/v0.1.0/`에 함께 제공하며 E2E가 다시 내려받아 SHA-256을 확인합니다.</li>
            <li>Worker는 Godot에 필요한 COOP·COEP·Range·MIME·ETag·캐시 계약을 소유합니다.</li>
            <li>Cloudflare 위키·게임 E2E 전에는 기존 Pages·README 링크·저장소 공개 상태를 유지합니다.</li>
            <li>대형 홈 대시보드는 검색 색인에서 제외해 검색 첫 선택이 실제 상세 문서로 이동합니다.</li>
          </ul>
          <p class="sfh-intent"><b>다음 게이트</b><span>기존 `sfh-dev-wiki`를 유지하고 새 `sfh-game`, `sfh-game-artifacts`만 생성하며 다른 Cloudflare 프로젝트·버킷은 변경하지 않습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>R2 업로더·manifest, Worker, Direct Upload/E2E 작업을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>원자적 전환, 대용량 Web 전달, 다운로드 무결성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>실제 Pages 프로젝트명, 배포 주소, 저장 경계, 응답 헤더, 전환 순서를 수정했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>Pages 단일 파일 제한은 Worker+R2 분리로 해소하고, 검색 첫 결과가 홈으로 회귀하던 색인 오류는 홈 검색 제외로 차단했습니다.</p></div>
        <p><a href="getting-started/run-project/#cloudflare">Cloudflare 배포 계약 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>Cloudflare 운영 전환 · 직접 플레이·Windows 다운로드</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · Cloudflare 후보 배포를 실제 운영 주소와 다운로드 경로로 승격했습니다.</strong>
          <ul>
            <li><b>배포:</b> 기존 <code>sfh-dev-wiki.pages.dev</code>와 새 게임 Worker·R2 버킷을 연결하고 다른 프로젝트와 버킷은 변경하지 않았습니다.</li>
            <li><b>산출물:</b> Actions 실행 33470418826이 통과한 Web·Windows·위키 파일만 업로드했으며 활성 Worker 커밋은 <code>88eeba2d5bb20c23e51241bbba322419231f840f</code>입니다.</li>
            <li><b>플레이 E2E:</b> 위키 PLAY 카드→게임 Canvas, 콘솔 오류 0, 필수 보안 헤더와 WASM Range 206을 실제 배포에서 확인했습니다.</li>
            <li><b>다운로드 E2E:</b> 40,364,917바이트 Windows ZIP을 다시 받아 게시 체크섬과 SHA-256이 일치함을 확인했습니다.</li>
            <li><b>운영 안전:</b> Cloudflare API 토큰은 Pages·Workers Scripts·R2 쓰기만 허용하고, 과금 플랜·결제 설정은 손대지 않았습니다.</li>
          </ul>
          <p class="sfh-intent"><b>전환 완료</b><span>정식 링크 반영 PR과 main 재배포를 통과한 뒤 저장소를 Private으로 전환하고 GitHub Pages 폴백을 종료했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>운영 R2 버킷, 게임 Worker 활성 릴리스, 직접 Windows 다운로드를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>배포 추적성, 실행 접근성, 다운로드 무결성 확인을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>정식 위키·게임·다운로드 주소와 MkDocs 기준 URL, 폴백 종료 스위치를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>검색 시작 시 잘못된 문서로 향하던 색인과 Pages 대용량 제한을 운영 배포에서 재검증했습니다.</p></div>
        <p><a href="getting-started/run-project/#cloudflare">Cloudflare 운영·다운로드 규격 →</a> · <a href="architecture/module-audit/">배포 모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>Private 저장소 복구망 · 변경 직전·검증 완료 이중 백업</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 문제 발생 시 검증된 파일 상태를 새 복구 커밋과 PR로 되살립니다.</strong>
          <ul>
            <li><b>pre-main:</b> 모든 <code>main</code> push에서 직전 전체 SHA를 커밋 주소형 백업 브랜치로 보존합니다.</li>
            <li><b>verified-main:</b> Cloudflare 배포 E2E가 성공한 현재 전체 SHA만 별도 기준점으로 보존합니다.</li>
            <li><b>복구:</b> 허용 네임스페이스·브랜치 SHA를 검증하고 현재 <code>main</code> 위에 백업 트리 복원 커밋을 생성합니다.</li>
            <li><b>PR 게이트:</b> 자동 PR 권한이 없으면 compare URL을 제공하며, 어느 경로든 필수 검사를 다시 통과해야 합니다.</li>
            <li><b>운영 경계:</b> Private 상태와 현행 위키 도메인을 유지하고 Cloudflare 과금·결제·배포 자원은 건드리지 않습니다.</li>
          </ul>
          <p class="sfh-intent"><b>제약 공개</b><span>GitHub Free Private 저장소의 Ruleset 미지원은 숨기지 않고, PR 관례·정적 계약 검사·두 백업 계층으로 보완합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>pre-main, verified-main, recovery PR, 워크플로 정적 계약 검사를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>복구 가능성, SHA 추적성, PR 생성 권한 제한 대응을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>Private 운영과 백업·복구 책임 경계, 검증 완료 시점, 운영 절차를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>Actions가 PR을 열지 못하는 환경에서 복구 동선이 끊기던 경우를 compare URL 폴백으로 막았습니다.</p></div>
        <p><a href="getting-started/run-project/#private-repository-backup">백업·복구 절차 →</a> · <a href="architecture/module-audit/#private-repository-backup-audit">복구 모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>배포 표면 분리 · Notion 75% 재확인 · 보안 모듈 재감사</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · Wiki Pages, Game Worker, Private R2의 주소와 책임을 분리하고 다음 기능 착수점을 다시 고정했습니다.</strong>
          <ul>
            <li><b>Wiki Pages:</b> 문서·검색·개발 현황만 제공하고 게임 WASM/PCK는 Pages 산출물에 합치지 않습니다.</li>
            <li><b>Game Worker:</b> 위키의 모든 PLAY 버튼이 별도 Worker를 직접 열며 <code>/play/*</code>는 이전 링크 호환 302로만 유지합니다.</li>
            <li><b>Private R2:</b> 공개 원본 주소 없이 Worker binding으로만 접근하고 <code>game/releases</code>와 <code>downloads</code>를 겹치지 않게 고정합니다.</li>
            <li><b>Master GDD:</b> 공개 0~8장을 재확인했으며 요구 변화가 없어 게임 기능 진행률은 75%입니다. 인프라 완료를 기능 진행률에 더하지 않습니다.</li>
            <li><b>다음 작업:</b> P4-01에서 영구 자산형과 세션 증폭·환금형 전리품의 획득·탈출·사망 생명주기를 먼저 동결합니다.</li>
            <li><b>운영 안전:</b> Private 이중 백업, 복구 PR, Actions SHA 고정, Secret 주입, 과금 비변경 경계를 자동 검사합니다.</li>
          </ul>
          <p class="sfh-intent"><b>주소 주의</b><span><code>vstock-market</code>는 Cloudflare 계정의 Workers.dev suffix이며 기존 VStock 프로젝트나 저장소를 함께 쓴다는 뜻이 아닙니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>배포 표면 원장, 자동 경계 검사, Worker 표면 식별 응답을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>직접 플레이 동선, 문서 전용 산출물, 주소 설명, 반응형 표면 지도, 기능 작업 인계성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>링크·prefix·GDD 스냅샷·P4-01 패킷·보안 감사표를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>위키와 게임이 같은 배포처럼 보이던 상대 링크와 노드맵의 오래된 72% 요약을 수정했습니다.</p></div>
        <p><a href="getting-started/run-project/#cloudflare">배포 표면 계약 →</a> · <a href="design/master-gdd-alignment/">Master GDD 재대조 →</a> · <a href="design/current-milestone-workline/">다음 작업 라인 →</a> · <a href="architecture/module-audit/">보안·모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 12</small><b>전리품 생명 주기 P4-01 · Item Sheet 15종 · 탈출·사망 결과 계약</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 전리품의 소유 기간과 성공·실패 결과를 드랍 구현보다 먼저 데이터 계약으로 동결했습니다.</strong>
          <ul>
            <li><b>영구 자산:</b> 기존 파츠·모듈·소모품·크레딧과 도면은 탈출 시 창고·지갑·영구 해금 결과를 가집니다.</li>
            <li><b>세션 자산:</b> 룬·코어·유물은 이번 런의 별도 소켓에서 사용하고 성공 시 지정 크레딧으로 자동 환전합니다.</li>
            <li><b>Sheet/CSV:</b> Item 탭 1행 변수·2행 설명을 유지한 채 J:P 7열을 추가하고 15개 활성 행을 확정 CSV·Web payload와 동기화했습니다.</li>
            <li><b>표현:</b> Presenter가 `◆ 영구 자산`, `◇ 이번 런 자산`, 탈출 결과와 사망 소실을 아이템 상세용 단문으로 만듭니다.</li>
            <li><b>검증:</b> 중복 ID, 누락 지역, 상충 정책, 잘못된 실시간 갱신과 payload 불일치를 자동 차단합니다.</li>
            <li><b>작업선:</b> P4-01은 완료했고 다음은 지역·난이도별 후보와 확률을 분리하는 P4-02입니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 경계</b><span>생명 주기 서비스는 결과만 계산합니다. 실제 획득·현장 교체·프로필 저장·크레딧 정산은 후속 명령 모듈이 맡습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 6</h3><p>정의·파서·서비스·설정·표현·Sheet 동기화 계약을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>전리품 의미 가시성, 데이터 입력성, 공급자 교체성, 배포 추적성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>Manifest·밸런스 UI·export·release metadata·마일스톤을 P4-01 완료 상태로 변경했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>상충 정책 수용과 오류 갱신 시 마지막 정상 데이터 유실을 차단했습니다.</p></div>
        <p><a href="features/loot-lifecycle/">전리품 생명 주기 →</a> · <a href="design/current-milestone-workline/">P4 작업 라인 →</a> · <a href="architecture/module-audit/">P4-01 모듈 감사 →</a></p>
      </div>
    </details>
  </div>
</details>
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-31</b><i class="sfh-latest">&#xCD5C;&#xC2E0;</i><small>20 UPDATE BUNDLES &middot; BUILD 42 &middot; IMPROVE 62 &middot; CHANGE 24 &middot; FIX 8</small></span><em class="sfh-chevron">&#x2303;</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview">
      <span><b>20</b><small>UPDATE BUNDLES</small></span>
      <span><b>42</b><small>BUILD</small></span>
      <span><b>62</b><small>IMPROVE</small></span>
      <span><b>24</b><small>CHANGE</small></span>
      <span><b>8</b><small>FIX</small></span>
    </div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>방 진입 핵앤슬래시 무리 · 티어별 하드 최소 스폰 · 모듈 재감사</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>진입</b> · 플레이어가 일반 방 안쪽에 들어온 실제 위치 판정만 `room_entry` 교전을 시작합니다.</li>
            <li><b>밀도</b> · 소·중·대형 최소 12·18·24기, 최대 18·26·34기의 무리가 한 번에 생성됩니다.</li>
            <li><b>예산</b> · 남은 총량이나 배치 공간이 최소치보다 작으면 약한 부분 교전과 문 봉쇄를 만들지 않습니다.</li>
            <li><b>검증</b> · E2E가 진입 출처와 최소 충족을 확인하고 대형 34기 성능 예산을 별도 측정합니다.</li>
          </ol>
          <p class="sfh-intent"><b>모듈화 결론</b><span>Config·RoomEncounterSystem·EnemySpawner·MapGenerator 경계가 유지됐고 새 비모듈 결합은 없습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">최소 무리 하드 플로어</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>예산·배치·실제 생성 어느 단계에서도 최소치 미달 교전을 시작하지 않습니다.</p><a href="../features/room-encounters/">방 전투 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">진입·무리 관측 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>트리거 출처와 최소·최대·요청·생성 수를 읽기 전용 스냅샷으로 제공합니다.</p><a href="../architecture/module-audit/">모듈 감사 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">핵앤슬래시 방 밀도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>입장 직후 마주치는 최소 적 수를 기존 대비 두 배 이상 높였습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">유한 예산 끝자락 처리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>총 생성 한계 직전의 소수 잔여 적으로 약한 방 전투가 열리지 않습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">플레이어 진입 E2E</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>실제 이동→무리 생성→봉쇄→클리어→보상 인과 흐름에 최소 스폰 판정을 추가했습니다.</p><a href="../quality/e2e-play-session/">E2E 규격 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">방당 적 수 12~18 · 18~26 · 24~34</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>티어 수치는 교체 가능한 RoomEncounterConfig Resource에서만 관리합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>핵심 게임플레이 인과 E2E · 방 전투 · 10분 세션 · 안개 전환</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>좌클릭 전투</b> · 실제 마우스 입력이 대상 선택, 발사체, 피격, 처치, 드랍까지 이어지는지 한 체인으로 검증합니다.</li>
            <li><b>방 전투</b> · 실제 방 진입으로 적과 문이 활성화되고 전멸 뒤 문 개방, 보상 생성·회수까지 확인합니다.</li>
            <li><b>10분 페이싱</b> · 중형·대형 모두 599초 잠금, 600초 탈출 신호 개방을 별도 세션에서 확인합니다.</li>
            <li><b>전장의 안개</b> · 방→이탈 경계→통로→진입 경계→방의 상태 전환과 전체 미니맵 독립성을 확인합니다.</li>
          </ol>
          <p class="sfh-intent"><b>사람 기준 수정</b><span>처치 순간의 물리 오류와 방 클리어 문구가 즉시 사라지는 현상을 실제 E2E에서 발견해 수정했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">GameplayFlowJudge</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>다섯 핵심 흐름을 입력 전후의 읽기 전용 스냅샷으로 독립 판정합니다.</p><a href="../quality/e2e-play-session/">E2E 규격 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">기본기 인과 텔레메트리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>대상·트리거·발사체·피격·치명타격·드랍 누적값을 외부 검증에 제공합니다.</p><a href="../features/weapons/">무기 전투 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">방 보상 생명주기 스냅샷</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>활성 방, 마지막 클리어 방, 생성·회수 보상을 모듈 공개 계약으로 제공합니다.</p><a href="../features/room-encounters/">방 전투 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">런 시계·안개 상태 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>등급별 목표·신호 상태와 다섯 안개 전환, 미니맵 독립 표시를 조회합니다.</p><a href="../features/fog-of-war/">전장의 안개 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">실제 좌클릭→드랍 E2E</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>물리 마우스 입력과 적 제거·드랍 결과 사이의 인과 관계를 확인합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">실제 방 봉쇄→보상 E2E</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>생성 맵의 방에서 자동 진입·전투·문 개방·보상 획득을 재현합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">중·대형 600초 경계 E2E</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>논리 시계를 사용해 10분 경계를 빠르고 결정적으로 검사합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">방·통로 안개 전환 E2E</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>활성 방 전체 공개와 통로 정면 시야가 경계에서 자연스럽게 교대하는지 판정합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">대형 작전 10분 통일</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>대형 목표·탈출 개방을 660초에서 600초로 조정했습니다.</p><a href="../features/raid-setup-extraction/">작전 페이싱 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">전투 상태 알림 우선순위</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방 시작·클리어·보상 안내의 중요도와 유지 시간을 일반 획득보다 높였습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">피격 중 드랍 생성 오류</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>픽업 노드 생성을 지연해 Godot 물리 flushing queries 오류를 제거했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">방 이벤트·배포 E2E 판정 안정화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>클리어 안내의 덮어쓰기를 막고 CI도 23개 인식·5개 인과 흐름을 현재 계약으로 판정합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>공개 기획 재대조 · 진행률 69% · 잔여 개발 순서 확정</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 최신 Notion 수용 기준과 실제 코드 사이의 차이를 공개</strong>
          <ul>
            <li>2026-08-31 공개 Notion의 렌더링 본문을 다시 읽고 모든 최신 요구를 저장소와 대조했습니다.</li>
            <li>입력·전투 ×3, 타게팅·탈출 ×2, 기술·메타 ×1로 중요도를 반영했습니다.</li>
            <li>좌클릭·1~9 슬롯, 유형별 타게팅, 탈출 일시정지와 경제 완결 작업을 우선순위로 정렬했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 경계</b><span>체크박스나 기능 이름이 아니라 현재 코드·데이터·테스트로 충족률을 계산했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">기획 진행률과 남은 작업 근거 갱신</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>중복 가산을 제거하고 최신 조작·타게팅·탈출 기준을 반영해 진행률을 69%로 재산정했습니다.</p><a href="#_1">산정표 보기 →</a></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>우선순위 10개 구현 · 전투 운용·탈출·경제·랭킹 연결 · 93%</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>입력</b> · 자동 기본기에서 좌클릭 홀드로, 1~3 고정에서 1~9 슬롯·런타임 키 교체로 확장했습니다.</li>
            <li><b>타게팅</b> · 단일 가중 공식에서 최근접·HP·엘리트·밀집 중심·이동 벡터 정책으로 분리했습니다.</li>
            <li><b>탈출·손실</b> · 이탈 초기화를 남은 시간 일시정지·재개로 바꾸고 사망 장착품 소실을 연결했습니다.</li>
            <li><b>투자·해금</b> · 비용을 보스·고등급·지역 드랍과 연결하고 무료 복구 계약·영구 상점 등록을 추가했습니다.</li>
            <li><b>빌드·리스크</b> · 태그·등급·상태 연계, 회복·시야·탈출 페널티와 3개 조건부 랭킹을 실제 런타임에 연결했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>검증</b><span>기능별 Resource·서비스 경계를 유지하고 선택 비활성화·스모크·대형 작전 60 FPS CPU 예산을 통과했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 7</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">직접 공격·9슬롯 입력</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>좌클릭 홀드, 1~9 Action과 런타임 재설정 계약을 구현했습니다.</p><a href="../features/combat-skills/">스킬 계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">정책형 자동 타게팅</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>단일·범위·이동·자기 스킬의 대상 해석을 독립 정책으로 제공합니다.</p><a href="../features/smart-targeting/">타게팅 정책 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">탈출 시간 보존·실패 장비 소실</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>구역 이탈은 시간을 보존하고 사망 정산은 장착 로드아웃까지 잃습니다.</p><a href="../features/extraction-defense-results/">탈출 정산 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">투자 기반 파밍</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>보스 보장·고등급 가중치·지역 드랍표·무료 기본 계약을 데이터로 제공합니다.</p><a href="../features/operation-contracts/">작전 계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">도면 영구 상점 등록</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>성공 반출 도면이 구매 가능한 장비·스킬 항목으로 영구 저장됩니다.</p><a href="../features/hub-economy/">거점 경제 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">태그·등급·상태 트리거</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Q 활성 무기에 따라 스킬 호환·메커니즘이 바뀌고 감전 연계가 발동합니다.</p><a href="../features/weapons/">무기 규칙 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">페널티·3종 랭킹</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>회복·시야·탈출 위험과 가치·시간·처치 사다리를 독립 저장합니다.</p><a href="../features/penalty-ranking/">리스크·랭킹 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">작전 조건 사전 가시화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>무료 지원·보스·고등급·회복 배율을 출격 전 UI에 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">Q 교체 호환 피드백</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>활성 무기 변경과 동시에 스킬 태그 불일치를 HUD에 반영합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">결과 3종 순위</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>정산 화면에서 가치·시간·처치 순위를 한 번에 확인합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">자동 발사 → 좌클릭 홀드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>무조준은 유지하고 공격 의사만 플레이어 입력으로 옮겼습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">가중 대상 → 행동별 정책</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>스킬 성격마다 대상 선택 기준을 독립 지정합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">탈출 초기화 → 일시정지</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방어 진행도를 악용하거나 잃지 않도록 남은 시간을 보존합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">종합 랭킹 → 목적별 랭킹</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>파밍·스피드런·처치 플레이를 서로 다른 순위로 비교합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>실제 플레이 E2E · Web U/E 입력 수정 · 사람 기준 오작동 점검</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>실제 입력</b> · 거점 이동과 I/U/E/Q/F부터 작전 선택까지 키 이벤트로 실행합니다.</li>
            <li><b>한 판 완주</b> · 파밍, 탈출 방어 이탈·재개, 성공 정산·복귀를 검증합니다.</li>
            <li><b>실패 복귀</b> · 재투입 후 사망 정산과 두 번째 거점 복귀까지 같은 세션에서 확인합니다.</li>
            <li><b>육안 수정</b> · Web U→E 닫힘과 장비 호환 숫자·조작 안내의 의미 혼선을 수정했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>자동화 경계</b><span>세부 규칙은 계약 스모크, 플레이 순서는 E2E, 화면 의미와 밀도는 브라우저 육안 검수로 나눕니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">성공·실패 실제 입력 E2E</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>한 프로세스에서 성공과 실패 작전을 연속 완주합니다.</p><a href="../quality/e2e-play-session/">단계별 판정표 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">CI 배포 차단선</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>실제 플레이 세션이 실패하면 Web 내보내기와 위키 배포를 진행하지 않습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">장비 호환 정보</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>2/3 같은 값이 발동 스킬 수가 아니라 태그 호환 수임을 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">전투 조작 안내</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>LMB·1~9·U·E의 실제 계약으로 안내를 갱신했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">U/E Action 분리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비와 모듈·파츠 탭이 브라우저와 데스크톱에서 같은 Action 계약을 사용합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">열린 U 화면의 E 닫힘</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>E 입력이 창을 닫지 않고 모듈·파츠 탭으로 전환됩니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>K 자유 키 설정 · CC0 상업 VFX · 입력 모듈 감사</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>입력 카탈로그</b> · 이동·전투·1~9·메뉴 21개 Action의 표시명과 분류를 Resource로 정의했습니다.</li>
            <li><b>저장 서비스</b> · 키·마우스 변경, 중복 교환, 기본값 복원과 JSON 영속화를 UI 밖으로 분리했습니다.</li>
            <li><b>K 화면</b> · 거점·작전 어디서든 열고 ESC로 취소·종료하며 현재 조작 안내를 즉시 갱신합니다.</li>
            <li><b>승인 VFX</b> · Kenney CC0 2개 파일만 프로필에 주입하고 출처·원문·해시를 원장화했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>자동화 경계</b><span>스모크는 저장·충돌·라이선스·드로우 예산, E2E는 실제 K/ESC와 모달 복원을 검사합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">21 Action K 설정</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>브라우저·PC 공통 저장과 중복 키 교환, 전체 초기화를 제공합니다.</p><a href="../features/key-mapping/">모듈 계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">외부 자산 상업 이용 감사</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>CC0 원문과 원본 커밋·파일 해시를 저장소에 동봉합니다.</p><a href="../architecture/third-party-assets/">라이선스 원장 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">동적 조작 안내</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>HUD와 거점 안내가 현재 InputMap 바인딩을 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">CC0 전기 강조 레이어</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기존 캐시 선분 위에 프로필별 제한 텍스처를 합성합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">이동·대시 Action화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>물리 키 직접 조회를 제거해 재지정 값이 실제 조작에 반영됩니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>UI 상태 판정 E2E · 화면 경계·모달·HUD 비겹침</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>상태 계약</b> · 거점부터 성공·실패 복귀까지 21개 지점의 필수 표시·숨김 레이어를 정의했습니다.</li>
            <li><b>공간 판정</b> · 1280×720 화면 경계와 미니맵·스킬·대시 HUD 교차를 계산합니다.</li>
            <li><b>모달 판정</b> · K/I/U/E가 하나만 열리고 배경 HUD를 숨긴 채 게임을 정지하는지 확인합니다.</li>
            <li><b>결함 수정</b> · 결과 오버레이 뒤에 남던 전투 HUD·미니맵·스킬·대시를 정산 진입에서 종료했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>자동화 경계</b><span>판정기는 읽기만 하고, E2E는 입력만 보내며, 실제 UI 전환은 Game 조립부가 소유합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">21개 UI 상태 판정기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>표시·숨김·정지·모달 수·장비 탭·화면 경계·HUD 비겹침을 하나의 상태 표로 검사합니다.</p><a href="../quality/e2e-play-session/">상태 계약 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">맥락 포함 실패 출력</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>어느 플레이 단계에서 어떤 레이어가 누수·이탈·겹침됐는지 즉시 확인합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🛠️ 버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">성공·실패 정산 HUD 누수</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>결과 화면에서는 활성 전투 UI 4종을 모두 숨기고 정산 정보만 유지합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>참조 기반 작전 브리핑 · 명시적 투입 · 전술 HUD</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>브리핑</b> · 지역·규모·난이도와 코드 전술 경로, 목표 시간·방·적 범위를 왼쪽에 구성했습니다.</li>
            <li><b>계약 판단</b> · 실제 비용·회수·고등급·보스와 적 4종 배율·페널티·소모품을 양쪽에서 비교합니다.</li>
            <li><b>입력 안전</b> · 규모 카드는 선택만 하고 우측 하단 투입 버튼에서 비용 차감과 작전 조립을 확정합니다.</li>
            <li><b>전투 HUD</b> · 1040×144 상단 카드에 생존·탈출·성장·장비·무기를 압축하고 미니맵과 분리했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>모듈 경계</b><span>Presenter는 스냅샷을 표시할 뿐 계약·경제·맵·전투 수치를 계산하지 않습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">OperationSetupPresenter</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기존 Control을 1180×660 양쪽 브리핑으로 재배치하고 실제 계약 데이터를 투영합니다.</p><a href="../features/raid-setup-extraction/">작전 UI 계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">CombatHudPresenter</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>HUD 계산과 Signal을 건드리지 않고 정보 계층과 크기만 교체합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">작전 정보 계층</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>임무·보상·위험·준비·확정을 영역별로 분리해 오판과 시선 왕복을 줄였습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">전투 HUD 밀도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비·무기를 나란히 놓고 상단 높이를 144px로 제한했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">선택과 투입 분리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>소·중·대형 선택 직후 출격하지 않고 현재 계약을 확인한 뒤 확정합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>전투 HUD 분산 시선권 · 목표·생존·행동 정보 재정렬</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>임무</b> · 현재 방·교전·탈출 목표와 시간을 좌측 상단 338×108 추적기로 이동했습니다.</li>
            <li><b>생존</b> · 체력·경험치·런 지표·장비·현재 무기를 하단 중앙 600×142 코어에 모았습니다.</li>
            <li><b>행동</b> · 에너지·3개 스킬을 516×92, 대시를 178×62로 압축해 코어 바로 아래에 정렬했습니다.</li>
            <li><b>안전</b> · 상호작용 프롬프트와 미니맵을 별도 영역에 유지하고 모든 Rect 교차를 자동 검사합니다.</li>
          </ol>
          <p class="sfh-intent"><b>모듈 경계</b><span>Presenter는 기존 UI 노드와 공개 HUD Control의 배치만 바꾸며 체력·목표·쿨타임·에너지 계산은 각 모듈에 남습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">임무 추적 시선권</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>행동 목표와 시간만 좌측 상단에 분리해 전장 중앙 가림을 제거했습니다.</p><a href="../features/raid-setup-extraction/#hud">HUD 수치·배치 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">생존·화력 글랜스</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>체력부터 무기·스킬까지 하단 한 시선권에서 확인합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">스킬 카드 압축</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>전투 중 필요한 입력·준비·비용·쿨타임을 우선하고 긴 설명은 숨겼습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">상단 1040px HUD 폐기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>한 덩어리 정보판을 좌측 임무와 하단 전투 클러스터로 분리했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>타격감 1차 · 명중 문맥·액터 반응·월드 충격 분리</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>피해 문맥</b> · 기본기·점멸·자기장·접촉이 방향·출처·강도를 선택적으로 전달합니다.</li>
            <li><b>액터 반응</b> · 맞은 대상만 0.045~0.055초 경직되고 섬광·넉백을 적용합니다.</li>
            <li><b>월드 반응</b> · 0.18초 충격 링과 카메라 Trauma가 방어·전기·치명·플레이어 피격을 구분합니다.</li>
            <li><b>성능</b> · Director 하나가 최대 32개 충격 기록을 그려 타격별 SceneTree Node 생성을 피합니다.</li>
          </ol>
          <p class="sfh-intent"><b>모듈 경계</b><span>피드백은 실제 적용 피해와 damaged Signal을 소비할 뿐 체력·방어력·스킬 피해 공식을 수정하지 않습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">액터 HitReaction</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>플레이어와 적에 공통 섬광·국소 경직·넉백 계약을 연결했습니다.</p><a href="../features/hit-feedback/">수치·구조 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">월드 HitFeedback Director</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>액터 등록과 damaged Signal을 충격 드로잉·카메라 반응으로 변환합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">피드백 Profile</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>표현 수치와 상한을 코드에서 Resource로 이동했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">공격별 명중 구분</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방어·체력·전기 스킬과 플레이어 피격을 색과 강도로 구분합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">위험 인지</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>플레이어가 맞을 때 적 타격보다 큰 카메라 반응을 적용합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">전역 멈춤 대신 국소 경직</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>다수 적과 Web 입력 응답을 유지하도록 맞은 액터만 짧게 멈춥니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>모듈 UI 참조 재설계 · 세팅 결과와 후보 비교 일원화</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>세팅 보드</b> · 선택 장비명·모듈 슬롯·사용 코스트와 장착 카드의 레벨·태그를 한 영역으로 묶었습니다.</li>
            <li><b>적용 결과</b> · 장착 모듈의 스탯 수정자와 특수 기능 수를 읽어 왼쪽 적용 수치로 합산 표시합니다.</li>
            <li><b>후보 카드</b> · MOD/PART, 코스트·소켓·태그·호환 상태를 4열 카드에서 선택 전에 비교합니다.</li>
            <li><b>탐색</b> · 전체·모듈·파츠 필터에 현재 장비 추천 우선과 기본 코스트 정렬을 결합했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>검증</b><span>실제 E 입력, 1280×720 경계, 4열·메타 카드·적용 수치·정렬 상태와 장착 후 요약 갱신을 자동 검사합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">모듈 UI Presenter</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비·가방 공개 상태를 카드와 적용 수치로 바꾸는 표현 경계를 추가했습니다.</p><a href="../features/equipment-customization/">화면·계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">표시 전용 정렬 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>추천과 코스트 순서가 가방 원본 및 장착 판정에 영향을 주지 않습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">합산 적용 수치</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장착 결과를 최대 체력·방어·이동·피해 수치와 특수 기능 수로 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">4열 모듈 카드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>1280×720에서 후보 비교량을 늘리면서 카드 메타 정보를 보존했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">용량 위험 색상</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>코스트 사용률을 청록·황색·적색 단계로 구분합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">목록 중심 → 결과 중심 정보 계층</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>선택 장비, 현재 세팅 결과, 보유 후보 순서로 시선 흐름을 재배치했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 12</small><b>총기 파츠 UI · 코드 무기 도식과 실제 소켓 지도</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>도식</b> · 무기 `minor_tag`를 소총·권총·단검·대검 실루엣으로 변환합니다.</li>
            <li><b>소켓</b> · 정의의 `part_socket_ids`와 장착 파츠를 광학·총구·탄창·칼날 위치 카드로 표시합니다.</li>
            <li><b>조작</b> · 장착 소켓은 기존 파츠 선택으로, 빈 소켓은 파츠 필터와 장착 안내로 이어집니다.</li>
            <li><b>비무기</b> · 방어구는 파츠 미지원 상태를 명시하고 잘못된 장착 요청을 만들지 않습니다.</li>
          </ol>
          <p class="sfh-intent"><b>검증</b><span>실제 E 입력에서 296×122px 보드·소총 3소켓·무기 분류를 확인하고 장착 후 소켓 상태와 클릭 선택을 스모크로 검사합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🧱 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">코드 기반 무기 도식</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>상업 라이선스 추가 없이 무기 분류별 파츠 장착 배경을 제공합니다.</p><a href="../features/equipment-customization/">파츠 보드 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">소켓 상호작용 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>보드는 소켓 ID만 방출하고 Workbench가 기존 파츠 조작으로 연결합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>⚡ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">장착 위치·상태 비교</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>빈 슬롯·장착·현재 선택을 회색·청록·강조 테두리로 구분합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">소켓 메타 정보</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>optic·muzzle·magazine을 광학·총구·탄창 의미와 함께 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">파츠 비지원 가독성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방어구 선택이 오류가 아니라 의도된 제한임을 화면에서 설명합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">목록식 파츠 표현 → 위치식 소켓 표현</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기능 API는 유지하고 기본 파츠 표현만 참조 UI의 공간 구조로 교체했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>#02e5e1 사이버펑크 테마 · 게임·위키 공통 시각 언어</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>토큰</b> · 핵심 신호색 <code>#02e5e1</code>과 검정 계열 배경을 게임 Theme·위키 CSS에서 공유합니다.</li>
            <li><b>문자</b> · 한글 Galmuri 도트 글꼴을 게임 TTF·위키 WOFF2로 나누고 OFL 원문과 해시를 보존합니다.</li>
            <li><b>표현</b> · 정적 스캔라인·결정론적 희박 노이즈·모서리 표식과 작은 점멸 신호를 독립 표현 모듈로 추가합니다.</li>
            <li><b>검증</b> · 21개 UI 상태 E2E, 입력 통과, 1280×720 경계, 대형 맵 평균 6.889ms·최대 8.094ms를 확인했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>저작권 경계</b><span>제공된 스톡 참조 이미지는 포함하지 않았고, 기능적 HUD 문법만 코드와 CSS로 새로 구성했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">CyberpunkPresentation</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Theme·ScreenFX·Overlay를 전투·경제 상태를 수정하지 않는 표현 계약으로 추가했습니다.</p><a href="../design/cyberpunk-visual-theme/">모듈·토큰 보기 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Galmuri 배포 자산</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>고정 원본 커밋에서 가져온 글꼴과 SIL OFL 1.1 원문을 게임·문서 배포 경계별로 저장했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>개선 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">게임 HUD·모달 일관성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>작전·전투·장비·가방·스킬·미니맵을 같은 활성색과 각진 패널 계층으로 정렬했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">위키 검색·업데이트 가독성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>검색 명령창과 최신 변경 카드에 전술 격자·신호 점·스캔 표현을 적용했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">도트 문자와 한글 안정성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>브라우저 전달용 WOFF2와 게임용 벡터 TTF로 한글 글리프와 다양한 UI 크기를 유지합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">성능·접근성 경계</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>노이즈 재계산을 크기 변경으로 제한하고 reduced-motion 및 움직임·노이즈 개별 토글을 제공합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">화면별 스타일 → 공통 전술 단말기 테마</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>산발적인 청록·둥근 패널을 하나의 색·선·문자·상태 신호 규칙으로 바꿨습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 14</small><b>플레이어 인식 E2E 재작업 · 전체 범위 감사와 다음 검수 순서</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>표현 수집</b> · 실제 표시 중인 Label·Button만 읽고 깨진 문자·정보 부족·필수 의미 누락을 판정합니다.</li>
            <li><b>행동 검증</b> · 실제 Q·1·Space·F 입력 뒤 무기명·위치·에너지·쿨타임·크레딧·탈출 문구 변화를 검사합니다.</li>
            <li><b>연속 세션</b> · 거점→메뉴→작전→전투→파밍→탈출 성공→거점→재투입→실패→거점의 인식 맥락을 확인합니다.</li>
            <li><b>남은 범위</b> · 기본기 처치, 방 전투, 전장의 안개, 중·대형 10분 루프, 장비 지속성, 실기 성능과 음향을 후속 우선순위로 공개합니다.</li>
          </ol>
          <p class="sfh-intent"><b>검증 결과</b><span>UI 상태 21개와 플레이어 인식 19개 체크포인트·9개 판단 단위가 한 프로세스에서 통과하며 CI 배포 게이트에도 연결됩니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">읽기 전용 인식 판정기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>도메인 상태를 변경하지 않고 화면의 의미·수치·변화만 증거로 수집합니다.</p><a href="../quality/player-perception-audit/">19개 체크포인트·공백 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">실제 입력 인식 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>K·I·U·E·Q·1·Space·F와 성공·실패 복귀를 9개 인식 단위로 검증합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">기능 중심 목록 재작성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>플레이어가 무엇을 보고 어떤 결과를 이해해야 하는지 기준으로 전체 E2E를 다시 분류했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">거점 무기 교체 피드백</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Q를 누른 즉시 현재 무기명이 거점의 항상 보이는 안내에 갱신됩니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">자동·부분·수동 검수 구분</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>구현 여부를 과대평가하지 않도록 현재 증거와 남은 관찰 항목을 한 표로 통합했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">완료 판정 기준</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>클래스·노드 존재가 아니라 플레이어가 원인과 결과를 구분할 수 있어야 E2E를 통과합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Q 피드백의 숨은 HUD 의존</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>전투 HUD가 꺼진 거점에서도 교체 결과를 확인하도록 표시 위치를 보완했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">재매핑 뒤 대시 키 오안내</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>정적인 SHIFT/SPACE 문구를 키 설정과 충돌하지 않는 DASH·회피 식별자로 변경했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Pages 글꼴 import 런타임 누락</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Linux 컨테이너에 fontconfig를 명시해 Galmuri import 중 Godot가 종료되던 병합 후 배포 실패를 해결했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 15</small><b>조작감 가시화 · 이동 규칙과 독립된 모션 피드백 계층</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>원인 분리</b> · 기존 초동·정지는 이미 한 프레임 수준이므로 속도를 더 높이는 대신 표현 대비 부족을 해결했습니다.</li>
            <li><b>상태 신호</b> · 출발·급정지·큰 선회에 서로 다른 코드 드로잉 펄스·링·선을 표시합니다.</li>
            <li><b>방향 강조</b> · Body·Heading을 진행 방향으로 기울이고 Camera2D를 최대 30px 앞서 보간합니다.</li>
            <li><b>대시 강조</b> · 최대 10점 Line2D 궤적과 축 변형·확장 카메라 리드를 하나의 짧은 피드백으로 합성합니다.</li>
            <li><b>자동 검증</b> · 실제 Space 입력의 궤적·리드·표현 강도와 모듈 비활성 원상 복구를 CI에서 검사합니다.</li>
          </ol>
          <p class="sfh-intent"><b>성능·교체성</b><span>런타임 Node는 Line2D 하나뿐이고 점은 최대 10개입니다. MovementFeedback을 제거해도 PlayerMovement·충돌·장비 속도는 유지됩니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">MovementFeedback 표현 어댑터</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>velocity와 이동 스냅샷을 캐릭터 변형·카메라 리드·신호·궤적으로 바꿉니다.</p><a href="../features/player/">수치·표현·검증 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>개선 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">초동 펀치</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>입력이 시작되는 프레임을 청록 전방 신호와 캐릭터 리드로 강조합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">정지·선회 가독성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>브레이크 링과 선회 선으로 속도 변화의 종류를 구분합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">카메라 방향 리드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>플레이어 앞 공간을 열되 정지 시 기준 위치로 빠르게 돌아옵니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">대시 모션·E2E</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>청록 궤적·축 변형과 플레이어 인식 하한을 함께 추가했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">조작감 판정 기준</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>속도 계산 통과만으로 완료하지 않고 플레이어에게 보이는 모션 피드백까지 검증합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Linux import 후 엔진 종료 오류</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Godot exit 134를 무조건 허용하지 않고 한글 글꼴 2종 산출물과 전체 후속 계약·Web export 성공을 필수 조건으로 제한했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 16</small><b>내부 증강 카드 UI · 선택 표현과 성장 규칙 분리</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 변화</strong>
          <ol>
            <li><b>표시기 분리</b> · `RunBuffChoiceCard`가 선택 스냅샷만 받아 계열·이름·중첩·효과를 그립니다.</li>
            <li><b>3장 비교</b> · 동일한 세로 구조에 CHARACTER·WEAPON·ARMOR, 작전 한정과 실제 수치를 정렬했습니다.</li>
            <li><b>SFH 재해석</b> · 외부 이미지 없이 #02e5e1 각진 프레임·증강 코어·레일을 코드 드로잉으로 구성했습니다.</li>
            <li><b>입력·모달</b> · 1~3 즉시 선택과 포커스 이동을 추가하고 선택 중 다른 전투 HUD를 숨겼습니다.</li>
            <li><b>인식 검증</b> · 1280×720 경계, 보이는 문구, 실제 `2` 적용과 전투 복귀를 E2E에 추가했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>교체성</b><span>카드 Scene을 제거하거나 교체해도 RunBuffSystem의 후보·효과·중첩·외부 정산 계약은 바뀌지 않습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">독립 증강 카드 프레젠터</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>버프 적용 권한 없이 스냅샷을 카드 정보와 코드 드로잉으로 변환합니다.</p><a href="../features/progression/">성장 UI 계약 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Run buff choice E2E 상태</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>UI 상태를 23개, 플레이어 인식 체크포인트를 20개로 확장했습니다.</p><a href="../quality/e2e-play-session/">E2E 계약 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>개선 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">증강 비교 정보 계층</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>계열→이름→중첩→효과→입력의 동일한 순서로 카드 3장을 읽습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">식별 코드·회로 프레임</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>VIT·MOV·DMG·RATE·ARM과 포커스 청록광으로 효과와 현재 선택을 구분합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">숫자·방향·Enter 입력</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>즉시 선택과 탐색 후 확정 방식을 동시에 지원합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">모달 배타성과 복원</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>증강 선택 중 HUD를 숨기고 선택 뒤 정확한 전투 레이어만 복원합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">임시 버프 목록의 화면 역할</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>가로 알림 목록에서 런 빌드 결정을 위한 집중 선택 화면으로 전환했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 17</small><b>위키 지식 그래프 · 55문서 L1-L4 전역 HUD</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 탐색 변화</strong>
          <ol>
            <li><b>전수 분류</b> · MkDocs의 55개 문서를 7개 큰 영역과 17개 소그룹에 한 번씩 배치했습니다.</li>
            <li><b>전역 설치</b> · Material 즉시 탐색 이벤트마다 현재 본문 최하단에 동일한 노드 HUD를 한 번만 삽입합니다.</li>
            <li><b>현재 경로</b> · URL과 route를 대조해 현재 L2·L3·L4를 선택하고 세부 문서에 `YOU`를 표시합니다.</li>
            <li><b>직접 탐색</b> · 분류 선택·전체 노드 검색·클릭·터치·Tab·방향키를 같은 인터페이스에서 지원합니다.</li>
            <li><b>구조 게이트</b> · Markdown·내비게이션·JSON의 55개 완전성과 route 규칙을 PR·Pages 전에 검사합니다.</li>
          </ol>
          <p class="sfh-intent"><b>구조 분리</b><span>JSON은 정보 구조, JavaScript는 탐색 상태, CSS는 사이버펑크 HUD 표현만 소유해 각각 독립 교체할 수 있습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">전역 Knowledge Graph Renderer</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>55개 문서를 대·중·소·세부 노드와 현재 경로로 조립합니다.</p><a href="../getting-started/search-wiki/">사용·편집 방법 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">분류 완전성 검증기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>누락·중복·없는 파일·잘못된 route·스크립트 연결을 자동 검사합니다.</p><a href="../architecture/module-audit/">모듈 감사 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>개선 · 4</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">4단계 경로 인지</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>현재 시스템이 전체 프로젝트에서 어디에 속하는지 하단에서 바로 읽습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">분류·요약 통합 검색</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>55개 노드의 문서명과 소속·요약을 동시에 필터링합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">접근 가능한 노드 이동</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>키보드 포커스·방향 이동·현재 페이지 의미를 명시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">4·2·1열 반응형 HUD</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>데스크톱부터 모바일까지 노드 계층을 화면 폭에 맞춰 재배치합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">위키 탐색 모델</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>좌측 선형 내비게이션과 상단 검색에 관계 중심 하단 그래프를 추가했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 18</small><b>위키 가독성 팔레트 · 22개 대비 계약</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 인식 변화</strong>
          <ol>
            <li><b>신호색 보존</b> · #02e5e1은 활성·링크·현재 위치에 집중하고 긴 본문은 중립 청회색으로 분리했습니다.</li>
            <li><b>문자 계층</b> · 제목·본문·보조·최소 정보 네 단계가 각각 고정 토큰을 사용합니다.</li>
            <li><b>표면 계층</b> · 배경과 패널 3단을 명도로 구분하고 검색·표·카드·노드맵에 공유합니다.</li>
            <li><b>비색상 단서</b> · 링크 밑줄과 2px 키보드 포커스 외곽선을 추가했습니다.</li>
            <li><b>자동 차단</b> · 두 화면 모드의 문자·상태·경계 대비 22개와 베이스 컬러를 배포 전에 검사합니다.</li>
          </ol>
          <p class="sfh-intent"><b>검수 기준</b><span>본문 AAA 7:1, 최소 문자 AA 4.5:1, UI 경계 3:1을 공통 토큰 수준에서 보장합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">WikiColorContrast 계약 검사</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>팔레트 변경이 최소 명도 기준이나 베이스 컬러를 깨면 PR·Pages 빌드를 실패시킵니다.</p><a href="../design/cyberpunk-visual-theme/">시각 테마 규칙 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>개선 · 5</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">본문·보조 정보 분리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>긴 문단과 작은 메타 정보가 모두 충분한 대비를 가지면서 중요도는 유지합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">3단 패널 표면</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>겹친 카드와 노드의 앞뒤 관계를 명도만으로도 읽습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">탐색 상태 가시성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>링크 밑줄·hover·키보드 포커스가 서로 다른 단서를 제공합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">의미색 명도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>초록·보라·황색·적색을 어두운 패널에서 7:1 이상으로 조정했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">노이즈·잔상 절제</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>사이버펑크 분위기는 유지하면서 본문 위 시각 간섭을 줄였습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 19</small><b>아이콘형 전투 HUD · 캐릭터 중심 배치 · 반응형 압축</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 인식 변화</strong>
          <ol>
            <li><b>텍스트 해체</b> · 600×142 패널의 레벨·처치·크레딧·장비·무기 문장을 역할별 위젯으로 분리했습니다.</li>
            <li><b>위치 재구성</b> · HP/XP와 전투 수치를 플레이어 위, 장비/무기를 좌우, 스킬을 우측 세로열로 옮겼습니다.</li>
            <li><b>행동 압축</b> · 기본기·1~3·Q·F·I/U/E·K를 8개 아이콘과 현재 키 배지로 표시합니다.</li>
            <li><b>Web 안정화</b> · 12종 상태 상징을 코드 드로잉해 이모지 글리프 의존을 제거했습니다.</li>
            <li><b>반응형 전환</b> · 1100px 미만에서는 상세 장비·무기만 숨기고 핵심 위젯을 가장자리에 재배치합니다.</li>
            <li><b>인지 검증</b> · UI 상태 23개와 인식 20개가 아이콘 의미·수치 변화·키 재매핑을 통과했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>변경 영향</b><span>표현 계층만 교체했으며 전투 계산·장비 요약·스킬 상태·대시 스냅샷 계약은 유지됩니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">TacticalHudIcon 12종</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>HP·XP·전투·장비·스킬·행동 상징을 외부 자산 없이 그립니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">두 단계 반응형 레이아웃</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Player Orbit와 Compact Edge를 화면 폭으로 자동 선택합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">아이콘 의미 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>접근성 의미와 수치 전후 변화를 플레이어 인식 E2E에 포함했습니다.</p><a href="../quality/e2e-play-session/">E2E 기준 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>개선 · 5</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">HP·XP 중심 배치</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>플레이어와 생존 정보를 같은 시선권에 둡니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">장비·무기 독립 카드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방어와 화력 정보를 양쪽에 나눠 필요한 쪽만 읽습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">세로 스킬 스택</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>3개 쿨타임과 충전을 플레이어 우측에서 비교합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">대시·행동 모서리 분리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>좌측 대시와 우측 키 도크가 중앙 전투 공간을 비웁니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">현재 바인딩 동기화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>K 변경 직후 도크 키를 다시 그립니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>수정 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">문장형 조작 안내 제거</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>긴 한 줄을 행동 아이콘과 짧은 키 배지로 교체했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">브라우저 이모지 제거</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>폰트별로 깨지던 상태 상징을 벡터 도형으로 전환했습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 20</small><b>반응형 UI 핵심 기조 · 시야 방해 최소화 · 상황별 정보 확장</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>구현 단계와 플레이 인식 변화</strong>
          <ol>
            <li><b>지속 정보 선별</b> · 생존·행동·임무·전체 지도만 유지하고 장비·무기 상세를 상시 HUD에서 제외했습니다.</li>
            <li><b>변화 반응</b> · 장비·무기 Signal 뒤 해당 상세만 1.8초 표시하는 one-shot Timer를 연결했습니다.</li>
            <li><b>상황 초점</b> · F 가능 시 주변 HUD를 감쇠하고, 체력 35% 이하에서는 생존 코어만 강하게 강조합니다.</li>
            <li><b>지도 압축</b> · 전체 지형 텍스처는 유지하면서 미니맵 헤더·범례·그림자를 제거하고 900px 아래에서 축소합니다.</li>
            <li><b>다중 폭 검증</b> · 1100·900px 런타임 전환과 800px 축약 주입을 계약화했습니다.</li>
            <li><b>면적 예산</b> · 1280×720 지속 HUD 합계 20% 상한을 23개 UI 상태 E2E의 전투 판정에 추가했습니다.</li>
          </ol>
          <p class="sfh-intent"><b>모듈 경계</b><span>Presenter는 가시성·투명도·좌표만 바꾸며 장비·무기·체력·상호작용·지도 계산은 기존 모듈에 남습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Context Reveal 정책</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>상태가 변한 상세 카드만 잠시 열고 자동 회수합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">20% Obstruction Budget</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>전투 지속 UI의 단순 면적 합계를 상태 판정기에 포함합니다.</p><a href="../architecture/module-audit/">모듈 감사 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>개선 · 5</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">장비·무기 일시 표시</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>변경 피드백 뒤 1.8초가 지나면 상세가 사라집니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">상호작용 우선 대비</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>F 프롬프트가 주변 고정 정보보다 먼저 읽힙니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">저체력 선택 강조</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>위험 상태만 생존 패널을 불투명하게 만듭니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">미니맵 장식 제거</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>전체 지도는 보존하고 헤더·범례·그림자만 걷어냈습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">800px 반응형 회귀 검사</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>좁은 화면의 상세 제거와 가장자리 배치를 자동 확인합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>수정 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">상시 노출 우선순위</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>모든 정보를 유지하는 방식에서 생존·행동 중심으로 전환했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">미니맵 카드 역할</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>설명 카드에서 전체 지도 전용 위젯으로 역할을 좁혔습니다.</p></div></details>
        </div>
      </div>
    </details>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>21 UPDATE BUNDLES &middot; BUILD 41 &middot; IMPROVE 37 &middot; CHANGE 18 &middot; FIX 11</small></span><em class="sfh-chevron">&#x2303;</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview">
      <span><b>21</b><small>UPDATE BUNDLES</small></span>
      <span><b>41</b><small>BUILD</small></span>
      <span><b>37</b><small>IMPROVE</small></span>
      <span><b>18</b><small>CHANGE</small></span>
      <span><b>11</b><small>FIX</small></span>
    </div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>즉시 플레이 README · Godot Web · Pages 배포 게이트</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · GitHub 방문에서 첫 플레이까지 한 번의 클릭</strong>
          <ul>
            <li>README를 캐치프레이즈·게임 정체성·코어 루프·조작·현재 범위 순으로 전면 재구성했습니다.</li>
            <li>‘조준은 자동으로. 판단은 끝까지.’라는 전투 노선과 SURVIVE · FIGHT · HAUL을 명시했습니다.</li>
            <li>Godot 4.7.2 Web 내보내기를 /play/에 배포하고 main의 게임 변경도 자동 배포 조건에 포함했습니다.</li>
            <li>게임과 위키를 독립 빌드한 뒤 HTML·WASM·PCK가 모두 있을 때만 Pages 아티팩트를 게시합니다.</li>
            <li>Web에서 누락되던 한글 글리프를 OFL 전역 폰트와 자동 계약 검사로 복구했습니다.</li>
            <li>확정 밸런스 CSV 3종과 자동 동기화된 Web 내장 Resource로 작전 조립 실패와 즉시 거점 복귀를 수정했습니다.</li>
            <li>홈 현재 빌드 카드와 모든 문서의 상단 고정 플레이 버튼으로 Web 진입을 상시 노출합니다.</li>
            <li>전투 HUD와 주요 패널을 압축하고 작전 구성·I·U·E 화면 뒤의 HUD 중첩을 제거했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결과</b><span>Web 프리셋의 전체 프로젝트 PCK 내보내기, 게임 스모크, 위키 strict 빌드와 일일 묶음 검사를 수행합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">브라우저 플레이 빌드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>WebAssembly·PCK·HTML을 Godot 릴리스 프리셋으로 생성해 위키 아래에서 서비스합니다.</p><a href="../play/">SFH Web 실행 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">복합 Pages 검증 파이프라인</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>게임 export와 MkDocs build를 병렬 경계로 나누고 최종 아티팩트 직전에 결합합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 5</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">제품 중심 GitHub 첫 화면</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>개발 항목 나열을 게임 정체성 5축과 실제 플레이 루프로 압축했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">온보딩 경로 단축</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>설치 없는 플레이, 개발 위키, 로컬 실행을 목적별 버튼과 짧은 절차로 분리했습니다.</p><a href="../getting-started/run-project/">실행 안내 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">현재 빌드 플레이 카드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>작은 수치 카드 영역을 큰 실행 버튼과 압축된 Web 상태 정보로 바꿨습니다.</p><a href="../play/">SFH Web 실행 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">전역 Web 실행 도크</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Material 즉시 탐색 뒤에도 유지되는 상단 고정 헤더 플레이 진입점을 추가했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">플레이 화면 정보 밀도</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>상단 HUD·미니맵·스킬바·작전 구성·성장 선택 및 I·U·E 화면의 크기와 여백을 낮춰 전장 가시성을 확보했습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">README 역할 재정의</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>상세 구현 기록은 위키로 보내고 README는 게임 소개와 실행 진입점에 집중합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🩹 버그픽스 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Web 한글 폰트 누락</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>운영체제 폴백 대신 프로젝트 내 Nanum Gothic을 사용하고 대표 한글 글리프를 스모크 테스트에서 확인합니다.</p><a href="../getting-started/run-project/">브라우저 실행 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">브라우저 작전 즉시 회귀</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>브라우저에서 CSV 스트림을 열 수 없는 경우 원본과 자동 동기화된 내장 Resource로 폴백하도록 고정했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">HUD·패널 겹침</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>작전 구성이나 I·U·E 패널을 열면 배경 HUD를 숨기고 종료 시 직전 표시 상태만 복원합니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>플랫포머형 이동 응답 · 정지 스냅 · 급선회 그립</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 탑다운 이동에 플랫포머의 단단한 입력감 적용</strong>
          <ul>
            <li>16ms 첫 입력에서 기본 속도의 90% 이상으로 진입하고 입력 해제 시 정확히 정지합니다.</li>
            <li>90도 전환은 횡속도를 제거하고 180도 전환은 이전 속도를 18%만 보존합니다.</li>
            <li>대시 종료 관성을 0.08초·1.08배로 줄이고 Camera2D 추적 응답을 18로 높였습니다.</li>
            <li>독립 대시 카드에서 READY·사용 중·남은 재사용 시간과 준비 게이지를 표시합니다.</li>
            <li>스냅·그립·반전·가속·대시 종료 정책을 각각 export 값으로 노출했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결과</b><span>16ms 초동·완전 정지·역선회·90도 횡미끄러짐 10% 이하·대시 종료와 기존 전체 스모크를 통과했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">플랫포머 응답 정책</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>정지 스냅, 횡그립, 반전 속도 보존율을 PlayerMovement의 독립 파라미터로 추가했습니다.</p><a href="../features/player/">이동 설정과 검증 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">대시 준비·재사용 HUD</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Shift/Space 입력 상태를 이동 스냅샷으로 읽어 준비·사용·재사용을 왼쪽 아래에 표시합니다.</p><a href="../features/player/">대시 HUD 계약 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 3</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">초동·제동 응답</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>느린 가속과 정지 직전의 미끄러지는 속도 꼬리를 제거했습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">선회·반전 그립</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기존 진행 방향 관성보다 현재 입력 방향을 우선합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">대시 종료·카메라 추적</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>조작 종료 뒤 캐릭터와 화면이 늦게 따라오는 시간을 줄였습니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">이동 기본값 재튜닝</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>가속·제동·선회 기본 수치를 한 프레임 반응 목표에 맞췄습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>고밀도 I·U·E · 거점 편집 로드아웃 · 무손실 반환</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 거점 준비가 실제 작전에 연결</strong>
          <ul>
            <li>I·U·E 패널에 공통 ESC 닫기와 일시정지 복원을 적용했습니다.</li>
            <li>무기·방어구와 모듈·고유 파츠의 장착·교체·해제를 거점에 열었습니다.</li>
            <li>장비 상태·강화 단계·가방 공간을 보존하는 반환·롤백 계약을 추가했습니다.</li>
            <li>거점 편집 상태가 작전 진입과 귀환 후에도 유지됩니다.</li>
            <li>I 가방은 50px 12×8 격자·용량·선택 상세를, U/E는 압축 슬롯 레일과 3열 후보 카드를 표시합니다.</li>
            <li>U와 E가 장비·모듈 탭을 각각 직접 열고 열린 창에서는 즉시 상호 전환합니다.</li>
          </ul>
          <p class="sfh-intent"><b>자동 검증</b><span>ESC 2종, 장비 교체·해제, 모듈 장착·교체·해제, 파츠 장착·해제와 양방향 세션 보존을 검사합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">로드아웃 반출입 트랜잭션</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비·가방 제공자가 상태를 반환하고 공간 부족이나 장착 실패 시 원상 복구합니다.</p><a href="../features/equipment-customization/">장비 편집 설계 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">세션 준비 상태 스냅샷</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Node 수명과 별개로 장비·가방 상태를 거점과 작전 사이에 전달합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 5</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">I·U·E ESC 닫기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>열린 준비 패널을 동일한 취소 입력으로 닫습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">장착·교체·해제 UI</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비와 모듈·파츠의 변경 결과와 실패 원인을 표시합니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">I 가방 정보 계층</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>점유 격자·사용률·선택 아이템 정보를 중앙과 상세 패널로 분리했습니다.</p><a href="../features/grid-inventory/">격자 가방 설계 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">U·E 고밀도 카드 레이아웃</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>현재 슬롯·적용 수치·장착 항목·보유 후보를 화면 이탈 없이 비교합니다.</p><a href="../features/equipment-customization/">장비 편집 설계 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">U·E 직접 탭 라우팅</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>키 의미에 맞는 탭을 바로 열고 다른 탭 키 입력은 창을 유지한 채 전환합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>🧭 수정 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">거점 조회 전용 제한 제거</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>거점 Workbench를 실제 출격 준비 편집 모드로 바꿨습니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>전투 에너지 · 스킬 충전 · 처치 회복 드랍</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 확정 전투 자원 루프</strong>
          <ul>
            <li>공용 에너지 100과 점멸 2회·자기장 1회·가속 2회의 독립 충전을 구현했습니다.</li>
            <li>적 처치 시 에너지 20·체력 15 결정을 확률 생성하고 최소 1개 드랍을 보정합니다.</li>
            <li>HUD에서 굵은 에너지 게이지, 현재/최대·백분율·LOW/CRITICAL 상태와 스킬별 소비량·충전을 확인합니다.</li>
            <li>레벨업 HP 12 회복을 버프 선택 모듈과 분리해 원상 복구했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결과</b><span>소비·차단·충전 복구·2종 회수·레벨업 회복·모듈 비활성 폴백과 대형 작전 평균 6.889ms 예산을 통과했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">전투 에너지·충전 모듈</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>자원 은행을 스킬 실행기와 제공자 계약으로 연결해 비용·충전을 데이터로 교체합니다.</p><a href="../features/combat-resources/">전투 자원 설계 →</a></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">에너지·체력 Pickup</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>드랍률·양·최소 보정·자석 반경을 독립 설정 Resource로 관리합니다.</p></div></details>
        </div>
        <div class="sfh-group"><h3>✨ 개선 · 2</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">에너지·충전 HUD</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>쿨타임 외 발동 조건을 전투 중 한눈에 읽을 수 있습니다.</p></div></details>
          <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">에너지 임계 상태 표시</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>13px 게이지와 수치를 함께 표시하고 35% 이하 LOW, 15% 이하 CRITICAL을 색으로 경고합니다.</p><a href="../features/combat-resources/">자원 HUD 기준 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🐛 버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">레벨업 회복 누락 수정</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>임시 버프 선택기가 설치된 일반 플레이에서도 HP 12 회복이 적용됩니다.</p></div></details>
        </div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>적 군중 분리 · 안전 생성 · 성능 제한</b></span><em class="sfh-chevron">&#x2304;</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>핵심 변경 · 겹침 없는 핵앤슬래시 군중</strong>
          <ul>
            <li>생성 요청을 기존 적과 40px 이상 떨어진 걸을 수 있는 후보로 보정합니다.</li>
            <li>적 이동에 44px 반경·가까운 8명 제한의 분리 조향을 주입합니다.</li>
            <li>충돌 직경 안에서는 추적보다 분리를 우선하면서 적끼리 물리적으로 통로를 막지 않습니다.</li>
            <li>설정 Resource 비활성 폴백과 대형 방 성능 예산까지 자동 검증했습니다.</li>
          </ul>
          <p class="sfh-intent"><b>모듈 감사 결론</b><span>생성기 제공자 계약, 적 소비자, 군중 정책 데이터를 분리했으며 기존 방 전투·전역 증원 모두 같은 정책을 사용합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>🆕 구현 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">EnemyCrowdConfig 정책 모듈</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>간격·탐색 횟수·분리 강도·반경·이웃 상한·갱신 간격을 데이터로 이동했습니다.</p><a href="../features/enemies/">적·증원 시스템 →</a></div></details>
        </div>
        <div class="sfh-group"><h3>🐛 버그픽스 · 1</h3>
          <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">생성·추적 중 적 겹침 방지</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>동일 위치 생성과 한 목표를 향한 이동 중 중첩을 각각 간격 보정과 분리 우선 조향으로 해결했습니다.</p></div></details>
        </div>
      </div>
    </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 6</small><b>기획자 검색 허브 · 실시간 탐색 순위 · 검색 우선순위 데이터</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 검색 전 추천과 입력 후 전체 검색</strong>
              <ul>
                <li>검색 전에는 기획 우선순위 기반 TOP 10과 5개 기획 영역을 표시합니다.</li>
                <li>선택한 검색어의 횟수와 최근성을 현재 브라우저 안에서 즉시 순위에 반영합니다.</li>
                <li>입력 후에는 기존 MkDocs 한글 제목·본문·검색 별칭 결과를 그대로 사용합니다.</li>
                <li>검색 순위 JSON의 최소 10개 항목, 중복, 우선순위와 스크립트 연결을 자동 검사합니다.</li>
              </ul>
              <p class="sfh-intent"><b>모듈 감사 결론</b><span>검색 UI, 공동 우선순위 데이터, 개인 탐색 신호와 기본 문서 검색을 서로 분리했습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">검색 커맨드 센터</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>검색 전 추천 목록과 검색어 입력 후 실시간 결과 전환을 하나의 모달에 구성했습니다.</p><a href="../getting-started/search-wiki/">검색 구조 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">기획자 중심 검색 분류</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>현황·전투·작전·장비·검증의 빠른 검색 묶음과 설명을 데이터로 관리합니다.</p></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 7</small><b>하루 단위 업데이트 압축 · 일일 합계 · 중복 방지 검사</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 날짜당 카드 하나</strong>
              <ul>
                <li>같은 날짜의 릴리스 카드를 하루 카드 하나와 주제별 묶음으로 통합했습니다.</li>
                <li>오늘의 구현·개선·수정·버그픽스 합계와 주제 수를 카드 상단에서 확인합니다.</li>
                <li>모든 상세 기록과 문서 링크는 주제 묶음 안에 그대로 유지합니다.</li>
                <li>날짜 카드 중복 검사를 위키 빌드 과정에 추가했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>검증 결론</b><span>2026-08-30은 카드 1개·주제 15개, 2026-08-29는 카드 1개로 정리했습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">날짜별 업데이트 롤업</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>날짜 목록은 짧게 유지하고 필요한 주제만 2단계로 펼치도록 재구성했습니다.</p></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 8</small><b>거점 I·U/E·Q 로드아웃 확인</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 거점 입력 4종</strong>
              <ul>
                <li>I 가방과 U/E 장비 화면을 거점 플레이어 조립 단계에 추가했습니다.</li>
                <li>조회 전용 플래그로 장착·성장·강화·개조를 차단하면서 슬롯·태그·모듈 상세는 유지합니다.</li>
                <li>거점 Q 선택 슬롯을 조립 경계 값으로 보존해 출격과 귀환 사이에 유지합니다.</li>
                <li>향후 진행도 점검의 기준을 로그인 없이 읽을 수 있는 게시된 Notion 주소로 변경했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>모듈 감사 결론</b><span>별도 복제 UI 없이 기존 가방·장비 Scene을 표시 모드만 바꿔 재사용했습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">전초기지 로드아웃 조회</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>I·U/E·Q 입력과 현재 활성 무기 표시를 거점에 연결했습니다.</p><a href="../features/start-hub/">거점 흐름 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>🧩 수정 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">공개 기획 원본 고정</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>게시된 Notion 본문을 직접 대조하고 향후 진행도 점검의 권위 있는 주소로 지정했습니다.</p><a href="https://wobbly-pawpaw-1ff.notion.site/SFH-6b45b728004082af8a4a811ef0a1c5e9">공개 기획 원본 ↗</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 9</small><b>지속 자기장 · 방 진입 봉쇄 · 전멸 보상</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 2개 전투 모듈</strong>
              <ul>
                <li>2번 자기장이 플레이어를 따라 5초 동안 유지되며 0.5초 고정 틱으로 피해를 누적합니다.</li>
                <li>일반 방 안쪽 진입 시 적을 생성하고, 생성 성공 뒤에만 모든 출입문을 봉쇄합니다.</li>
                <li>해당 방 적의 수명만 추적해 전멸을 판정하고 문 개방과 내부 경험치 보상을 실행합니다.</li>
                <li>대형 방 적 14기·전기 효과 3개에서 평균 6.884ms, 최대 8.385ms를 확인했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>모듈 감사 결론</b><span>맵 스냅샷·위치 지정 생성·문·보상 계약을 분리했고 비활성 폴백 자동 검증을 통과했습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">방 단위 봉쇄 교전</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>진입→생성→봉쇄→전멸→보상 흐름과 등급별 수량·최대 교전 수를 Resource로 분리했습니다.</p><a href="../features/room-encounters/">방 전투 계약 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">2번 지속 원형 자기장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>단발 범위 피해를 플레이어 추적형 5초 지속·0.5초 누적 피해 필드로 변경했습니다.</p><a href="../features/combat-skills/">스킬 수치 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 10</small><b>방·통로 안개 전환 · 7개 작전·영구 성장 시스템 통합</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 7개 시스템 + 안개 전환 개선</strong>
              <ul>
                <li>방과 통로 경계의 즉시 전환을 입장 0.22초·퇴장 0.32초 크로스페이드로 교체</li>
                <li>탈출 카운트다운 방어전과 성공·실패 영구 결과 정산</li>
                <li>실제 투입비·지역·난이도·적 스탯·회수 배율 계약</li>
                <li>영구 해금·상점·창고·최대 3개 소모품 로드아웃</li>
                <li>거리·처형·등급·밀집도 스마트 자동 타게팅</li>
                <li>도면·고철·크레딧 제작과 중복 없는 랜덤 옵션</li>
                <li>적 강화·보상 증가 페널티 변형</li>
                <li>지역·난이도·맵·페널티별 조건부 랭킹</li>
              </ul>
              <p class="sfh-intent"><b>검증 결과</b><span>신규 정책 수치, 영구 소비·정산, 선택 모듈 폴백과 적 72명 성능 예산을 모두 통과했습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 7</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">탈출 방어·결과 정산</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>15~35초 구역 유지 뒤 영구 크레딧·고철·도면·랭킹을 정산합니다.</p><a href="../features/extraction-defense-results/">상세 규칙 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">작전 계약·거점 경제</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>실제 비용 차감, 지역 해금, 상점·창고·소모품을 영구 프로필에 연결했습니다.</p><a href="../features/operation-contracts/">계약 데이터 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">스마트 타게팅·도면 제작</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>가중 대상 정책과 도면 기반 랜덤 옵션 제작을 독립 Resource로 구성했습니다.</p><a href="../features/smart-targeting/">타게팅 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">페널티·조건부 랭킹</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>위험 배율과 동일 조건 점수표를 분리 저장합니다.</p><a href="../features/penalty-ranking/">변형·랭킹 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">방·통로 문턱 안개</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>현재 방은 자연스럽게 접고 새 방은 부드럽게 열면서 미탐색 방 차단을 유지합니다.</p><a href="../features/fog-of-war/">안개 전환 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 11</small><b>전기 스킬 표현 · 대형 작전 성능 예산</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 7개 주제</strong>
              <ul>
                <li><code>1</code> 점멸은 전기 잔상, <code>2</code> 자기장은 원형 전기장, <code>3</code> 가속은 추적형 전기 방출을 표시합니다.</li>
                <li>점멸의 실제 이동 선분에 폭 80px·12 피해·최대 24타격 경로 정책을 주입했습니다.</li>
                <li>Web 폰트에서 깨지던 번개 이모지를 고정 `EN` 에너지 표기로 교체했습니다.</li>
                <li>공용 전기 렌더러와 세 프로필을 분리해 패턴·색·수명·밀도·갱신률을 데이터로 교체합니다.</li>
                <li>형상 10~20Hz 캐시, HUD 10Hz, one-shot Timer로 매 프레임 갱신과 할당을 줄였습니다.</li>
                <li>연속 맵 충돌체 병합, 적 A* 0.7초 분산 갱신과 생성 목록 Signal 정리를 적용했습니다.</li>
                <li>대형 맵·적 72명에서 평균 6.887ms, 최대 10.328ms, Node 1,490개, 충돌체 6.7%를 검증했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>검증 결과</b><span>기능 스모크 테스트와 별도 대형 작전 성능 게이트를 통과했으며 실제 최소 사양은 저사양 GPU 실기 인증 전까지 임시 목표로 관리합니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 3</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">공용 전기 아크와 스킬별 프로필</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>점멸·자기장·가속이 같은 렌더러에 독립 Resource를 주입합니다.</p><a href="../features/combat-skills/">스킬 계약 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">점멸 경로 피해 정책</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>벽으로 잘린 실제 점멸 경로만 검사하고 피해량·폭·최대 대상 수를 Resource로 교체합니다.</p><a href="../features/combat-skills/">점멸 공격 계약 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">성능 예산 자동 테스트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>대형 작전 240프레임의 평균·최대 시간과 SceneTree 예산을 검사합니다.</p><a href="../performance/minimum-requirements/">사양·성능 예산 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>🧩 수정 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">충돌·경로·UI 핫패스 최적화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기능 경계를 유지하면서 반복 Node·배열·경로 계산만 각 소유 모듈 안에서 줄였습니다.</p><a href="../architecture/module-audit/">모듈 감사 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>🩹 버그픽스 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">Web 스킬 비용 글리프</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>내장 폰트에 없는 번개 이모지를 제거하고 EN 20·35·25 표기로 통일했습니다.</p></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 12</small><b>큰 시작 거점 · F 작전 게이트 · 전투 세션 복귀</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 5개 주제</strong>
              <ul>
                <li>첫 실행을 메뉴가 아닌 1800×1040px 단일 방의 안전 거점으로 전환했습니다.</li>
                <li>동쪽 작전 게이트 접근 후 F를 눌러 세션 구성 UI를 엽니다.</li>
                <li>전장 카드, 밸런스 데이터 모드와 ESC 복귀 동선을 한 화면에 정리했습니다.</li>
                <li>탈출·사망 결과 후 전투 Node만 정리하고 시작 거점을 다시 설치합니다.</li>
                <li>Notion 최신 상태를 재확인하고 진행도를 45%로 갱신했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>모듈 감사 결론</b><span>거점은 방·게이트만 소유하고 전장 생성과 전투를 모르며, Game은 두 세션의 설치·정리 순서만 조정합니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">이동 가능한 SFH 전초기지</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>화면보다 큰 안전 방, 충돌 경계, 거점 플레이어와 동쪽 작전 게이트를 추가했습니다.</p><a href="../features/start-hub/">시작 거점 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">전투 세션 진입·복귀 수명주기</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>거점→작전과 결과→거점 전환에서 동적 World·Modules·UI를 명시적으로 정리합니다.</p><a href="../features/raid-setup-extraction/">작전 흐름 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">작전 시작 UI 재구성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>안전 거점 HUD, 전장 카드, 데이터 모드와 ESC 취소를 명확한 계층으로 배치했습니다.</p></div></details>
            </div>
            <div class="sfh-group"><h3>🧩 수정 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">Notion 진행도·후속 목록 갱신</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>확정도 가중치로 45%를 계산하고 새 제작·확률 옵션 논의를 미확정 작업으로 분리했습니다.</p></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 13</small><b>내부 성장 · 무기·방어구·모듈 Google Sheets 연동</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 4개 주제</strong>
              <ul>
                <li><code>RunBuff</code> 탭은 한 판 내부 레벨업 선택지 5개의 중첩과 효과를 제공합니다.</li>
                <li><code>Upgrade</code> 탭은 무기·방어구·모듈의 레벨별 누적 스펙 25개를 제공합니다.</li>
                <li>실시간 테스트는 3초마다 세 성장 데이터를 함께 갱신하고, 배포는 확정 CSV를 사용합니다.</li>
                <li>잘못된 행은 반영하지 않고 마지막 정상값 또는 기존 Resource 폴백을 유지합니다.</li>
              </ul>
              <p class="sfh-intent"><b>검증 결과</b><span>시트 파싱, 누적 능력치, 모듈 장착 코스트·강화 견적, 오류 보존과 Game 제공자 연결이 자동 테스트를 통과했습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">RunBuff 실시간 성장 데이터</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>내부 성장 선택지의 캐릭터·무기·방어구 효과를 행 단위로 편집합니다.</p><a href="../features/growth-balance/">성장 시트 계약 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Upgrade 장비·모듈 스펙</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>ID와 레벨로 누적 스탯, 최대 레벨, 모듈 코스트와 다음 강화 비용을 조회합니다.</p><a href="../features/equipment-upgrade-economy/">강화 경제 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>🧩 수정 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">독립 성장 데이터 제공자</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>버프 선택·장비 상태·발사·경제 코드는 바꾸지 않고 공개 계약으로 데이터만 주입합니다.</p><a href="../architecture/module-audit/">모듈 점검 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 14</small><b>2.5~5배 회수 · 유한 적 재생성 · 핵앤슬래시 무브먼트</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 5개 주제</strong>
              <ul>
                <li>투입 코스트의 2.5~5배 범위에서 판마다 회수 목표를 선택하고 실제 배치 총액을 정확히 맞춥니다.</li>
                <li>배수의 최소·최대와 지점 수용량을 등급 Resource로 분리해 밸런스 범위를 유연하게 조절합니다.</li>
                <li>최초 배치를 포함한 총 적 생성 한계를 소형 120, 중형 220, 대형 360으로 제한합니다.</li>
                <li>생성 예산 소진 뒤에는 적을 처치해도 추가 증원이 발생하지 않습니다.</li>
                <li>초동·선회·역선회·대시 종료 관성을 강화하고 단계별 응답을 자동 검증했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>모듈 감사 결론</b><span>회수 범위, 적 생성 예산, 이동 응답은 각각 독립 Resource·export·공개 스냅샷으로 조정되며 Game 조립부에 정책 계산을 추가하지 않았습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">2.5~5배 목표 회수 경제</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>0.1배 단위로 선택한 목표에 맞춰 회수 지점 수와 개별 가치를 양방향 보정합니다.</p><a href="../features/credit-loot/">회수 경제 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">유한 증원 예산</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>남은 생성량과 소진 상태를 공개하고 한계에 도달하면 재생성을 종료합니다.</p><a href="../features/enemies/">적 생성 정책 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">동적 핵앤슬래시 무브먼트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>38% 초동 속도, 강화된 90도·180도 선회, 2.35배 대시와 종료 관성을 적용했습니다.</p><a href="../features/player/">이동 수치 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>🧩 수정 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">정책 경계와 검증 확장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>최소·최대 회수값, 남은 적 생성 예산, 이동 상태를 각 기능의 스냅샷으로 공개합니다.</p><a href="../architecture/module-audit/">모듈 점검 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 15</small><b>방·통로 전장의 안개 최적화 · 정면 시야 확장</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 5개 주제</strong>
              <ul>
                <li>현재 방에 진입하면 방 바닥과 외곽 벽 전체를 밝힙니다.</li>
                <li>통로에서는 주변 170px와 정면 780px·반각 62도 시야를 사용합니다.</li>
                <li>통로에서 다른 방 내부는 시야 원뿔과 겹쳐도 별도 마스크로 차단합니다.</li>
                <li>플레이어 방향과 맵 방 경계를 공개 메서드로 전달해 내부 Node·배열 결합을 피했습니다.</li>
                <li>세 맵 등급 자동 테스트와 1280×720 방·통로 실제 렌더를 확인했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>개선 의도</b><span>방 안에서는 다수 적 교전 가시성을 확보하고, 통로에서는 정면 탐색과 다른 방의 불확실성을 유지합니다.</span></p>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 3</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">방 단위 안개 제거</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>방 진입·이탈을 매 프레임 판정해 전체 방 시야와 통로 시야를 자동 전환합니다.</p><a href="../features/fog-of-war/">전장의 안개 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">정면 124도 확장 시야</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>캐릭터가 마지막으로 이동한 방향을 기준으로 넓고 긴 원뿔 시야를 제공합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">다른 방 완전 차단</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>통로에서는 전체 방 경계 마스크를 적용해 다음 방 내부를 미리 볼 수 없습니다.</p></div></details>
            </div>
            <div class="sfh-group"><h3>🧩 수정 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">가시성 제공자 계약</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>맵은 복사된 Rect2, 플레이어는 방향 Vector2만 제공하며 Shader 세부 구현은 안개 모듈에 유지합니다.</p><a href="../architecture/module-audit/">모듈 점검 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 16</small><b>맵 비례 적 증원 · 최소 2.5배 회수 가치 · 전체 결합 재점검</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 5개 주제</strong>
              <ul>
                <li>소형 24~36, 중형 36~54, 대형 52~72명 범위에서 판마다 목표 적 수를 무작위 선택합니다.</li>
                <li>생존 적이 목표의 75% 이하가 되면 6~16명 범위의 등급별 묶음 증원이 진입합니다.</li>
                <li>자원 배치 총액은 소형 250, 중형 750, 대형 1,750 이상을 보장합니다.</li>
                <li>생성 수량·증원 묶음·간격·반경을 기능 전용 Resource로 분리했습니다.</li>
                <li>전역 적 집계, 자동 무기 전역 탐색, 플레이어 내부 체력 접근과 파밍 계약 불일치를 제거했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>모듈 감사 결론</b><span>현재 기능은 기능별 Scene·Resource·공개 계약으로 교체 가능하며, Game은 `_install_*()` 조립과 Signal 연결만 담당합니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">목표 밀도 유지형 적 증원</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>맵 등급별 최소~최대에서 목표를 정하고 임계 수량 아래에서 묶음 증원합니다.</p><a href="../features/enemies/">적 생성 수치 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">투입 코스트 ×2.5 최소 가치</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>작전별 무작위 회수 지점의 실제 총액을 계산하고 부족분을 최대값 안에서 분배합니다.</p><a href="../features/credit-loot/">파밍 경제 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>🧩 수정 · 3</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">생성기별 인스턴스 추적</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>다른 생성기·보스·훈련 표적이 동시 수량 계산에 섞이지 않습니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">자동 무기 대상 제공자</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>자동 무기가 SceneTree를 직접 탐색하지 않고 생성기의 복사된 대상 목록을 받습니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">공개 스냅샷 계약 정리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>플레이어 체력과 파밍 총액을 내부 필드 대신 공개 스냅샷으로 검증합니다.</p><a href="../architecture/module-audit/">감사 기록 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 17</small><b>화면 한 장급 방 · 전장의 안개 · 자원 회수 지점</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 5개 주제</strong>
              <ul>
                <li>최소 방을 42×25셀 이상으로 확장해 방 하나가 기본 화면보다 작지 않게 했습니다.</li>
                <li>장애물을 출입구 있는 긴 칸막이, 설비 블록, 다중 기둥 구조로 재구성했습니다.</li>
                <li>플레이어 주변 월드만 보이는 전장의 안개 모듈을 추가했습니다.</li>
                <li>미니맵은 안개와 관계없이 전체 지형·현재 위치·탈출 위치를 유지합니다.</li>
                <li>보급 상자 대신 벽면 금고·자재함·회수 단말기에서 자원을 회수합니다.</li>
              </ul>
              <p class="sfh-intent"><b>개선 의도</b><span>각 방을 독립 전투·탐색 구역처럼 만들고, 제한된 월드 시야와 전체 전술 지도를 함께 사용해 익스트랙션 탐색 긴장감과 방향성을 동시에 확보합니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">월드 전장의 안개</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>초기 원형 시야를 독립 CanvasLayer로 적용했고, 후속 업데이트에서 방·통로 방향성 시야로 개선했습니다.</p><a href="../features/fog-of-war/">안개 설계 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">세 종류 자원 회수 지점</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>벽면 금고, 자재함, 회수 단말기가 배치 유형별 외형과 F 상호작용 문구를 사용합니다.</p><a href="../features/credit-loot/">자원 회수 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 3</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">화면 한 장급 방 노드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>소·중·대형 최소 방을 42×25, 46×28, 50×30셀로 상향했습니다.</p><a href="../features/map-generation/">맵 수치 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">건물 내부형 장애물</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>짧은 단독 장애물 대신 문 있는 칸막이·넓은 설비·기둥 열을 생성합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">FULL MAP 미니맵</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>월드 안개를 적용해도 전체 지형 스냅샷과 플레이어·탈출 표식을 유지합니다.</p><a href="../features/minimap/">미니맵 규칙 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 18</small><b>전체 화면 장비 · 모듈 인벤토리 UI</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 4개 주제</strong>
              <ul>
                <li>U 화면을 왼쪽 장비 슬롯, 선택 장비 상세, 카드 인벤토리의 3영역 구조로 재설계했습니다.</li>
                <li>장착 모듈 슬롯·코스트 막대와 보유 모듈·고유 파츠 카드 필터를 추가했습니다.</li>
                <li>첫 호환 아이템 자동 소비를 없애고 사용자가 고른 카드만 장착하도록 변경했습니다.</li>
                <li>장착 카드 선택, 강화 견적, 미니맵 표시 순서와 모듈 경계를 자동·시각 검증했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>개선 의도</b><span>장비와 개조 정보를 한 화면에서 비교하면서도 슬롯·코스트·호환 여부를 즉시 읽고, 원하는 아이템을 실수 없이 직접 선택하게 합니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">장착 모듈·파츠 카드 보드</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장착 슬롯, 빈 슬롯, 현재 코스트, 강화 단계와 비용 견적을 선택형 카드로 표시합니다.</p><a href="../features/equipment-customization/">장비 개조 UI →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">직접 선택 장비 인벤토리</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비·모듈·파츠의 개별 인스턴스를 선택하고 승인된 대상만 가방에서 소비합니다.</p><a href="../features/grid-inventory/">가방 연결 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">U 전체 화면 전술 레이아웃</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>4개 장비 슬롯을 고정 레일로 유지하고 장비 장착과 모듈·파츠 관리 탭을 분리했습니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">호환성·코스트 가시성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>호환 카드는 색상 강조, 불일치 카드는 흐림 처리하고 모듈 코스트를 막대로 표시합니다.</p></div></details>
            </div>
            <div class="sfh-group"><h3>🔧 버그픽스 · 1</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">U 화면 위 미니맵 겹침 방지</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>패널을 열 때 모달을 UI 최상단으로 이동해 우측 상단 미니맵이 장비 카드 위에 나타나지 않게 했습니다.</p></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 19</small><b>확장 맵 · 10분 런 · 반응형 이동 · 부분 회복</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 4개 주제</strong>
              <ul>
                <li>소형 18~24방, 중형 30~40방, 대형 45~60방으로 맵 규모와 방 면적을 크게 상향했습니다.</li>
                <li>소·중·대형 목표 시간을 9·10·11분으로 잡고 목표 시각에 탈출 신호가 열립니다.</li>
                <li>가속·빠른 제동·강한 역선회와 Shift/Space 짧은 회피를 적용했습니다.</li>
                <li>피격 4초 후 최대 체력 65%까지 초당 3을 회복하는 선택 모듈을 추가했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>개선 의도</b><span>맵 탐색과 생존 시간을 늘리면서도 이동 조작은 즉각적이고 손맛 있게 만들고, 회복은 긴장감을 지우지 않는 안전선까지만 제공합니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">등급별 탈출 신호 잠금</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>9·10·11분 목표 전에는 F 요청을 거부하고 HUD에 신호 개방 카운트다운을 표시합니다.</p><a href="../features/raid-setup-extraction/">작전 페이싱 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">부분 체력 회복 모듈</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>피격 지연, 초당 회복, 회복 상한을 독립 Resource와 Manifest 토글로 관리합니다.</p><a href="../features/health-recovery/">회복 규칙 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>✨ 개선 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">소·중·대형 맵 대폭 확장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>타일 32px는 유지하고 방 수와 각 방의 셀 면적을 동시에 상향했습니다.</p><a href="../features/map-generation/">맵 수치 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">FPS·플랫포머 감각의 탑다운 이동</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>정속 이동을 가속·제동·역선회·입력 버퍼 회피 방식으로 교체했습니다.</p><a href="../features/player/">이동 수치 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 20</small><b>로그라이크 성장 · 강화 경제 · 모듈 전수 점검</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 5개 주제</strong>
              <ul>
                <li>내부 레벨업마다 최대 3개의 임시 버프 선택지를 표시합니다.</li>
                <li>한 판에서 선택한 버프 수를 캐릭터·무기·방어구 외부 경험치로 분류합니다.</li>
                <li>작전 종료 시 세 계열을 독립 레벨업하고 영구 효과와 JSON 저장을 적용합니다.</li>
                <li>모듈·고유 파츠 강화에 동일 아이템과 크레딧 비용 정책을 연결했습니다.</li>
                <li>전체 기능의 토글·공개 계약·비활성화 폴백을 다시 검증했습니다.</li>
              </ul>
              <p class="sfh-intent"><b>모듈 감사 결론</b><span>현재 기능은 모두 공개 계약과 Manifest 토글로 분리되어 있으며, 후속 재점검에서 적 대상·체력·파밍의 남은 숨은 결합도 제거했습니다.</span></p>
            </div>
            <div class="sfh-group"><h3>🆕 구현 · 3</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">한 판 임시 버프 선택</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>생존·기동·화력·공속·장갑 버프를 Resource 카탈로그로 제공하고 중첩 적용합니다.</p><a href="../features/progression/">성장 문서 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">세 계열 외부 레벨과 저장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>선택 수량을 외부 XP로 바꾸고 캐릭터·무기·방어구 레벨을 독립 저장합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">별도 장비 강화 경제</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>모듈과 파츠가 동일 아이템 1개와 단계별 크레딧을 소비하도록 구성했습니다.</p><a href="../features/equipment-upgrade-economy/">강화 경제 문서 →</a></div></details>
            </div>
            <div class="sfh-group"><h3>🧩 수정 · 2</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">출처별 스탯 합산</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비, 한 판 버프, 외부 레벨이 서로 덮어쓰지 않고 출처 ID별로 합산됩니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">공개 계약 전수 점검</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>크레딧 내부 필드 직접 조회를 스냅샷 계약으로 교체하고 신규 모듈 토글을 검증했습니다.</p><a href="../architecture/module-audit/">감사 결과 →</a></div></details>
            </div>
          </div>
        </details>
        <details class="sfh-bundle">
          <summary><span><small>UPDATE 21</small><b>무기 밸런스 · 격자 가방 · 장비 개조</b></span><em class="sfh-chevron">&#x2304;</em></summary>
          <div class="sfh-bundle-body">
            <div class="sfh-summary">
              <strong>핵심 변경 · 6개 주제</strong>
              <ul>
                <li>Q 키로 메인 돌격소총과 보조 제식 권총을 즉시 교체합니다.</li>
                <li>소총 3점사와 권총 고위력 관통으로 무기별 전투 리듬을 분리했습니다.</li>
                <li>작전 선택 화면에서 확정 CSV와 Google Sheet 실시간 테스트 모드를 버튼으로 전환합니다.</li>
                <li>12×8 가변 격자 가방과 I 키 인벤토리를 구현했습니다.</li>
                <li>U 화면에서 무기·방어구, 고유 파츠, 모듈, 강화, 개조를 관리합니다.</li>
                <li>새 무기·파츠·모듈·스탯을 데이터 Resource로 확장할 수 있습니다.</li>
              </ul>
              <p class="sfh-intent"><b>개선 의도</b><span>작전 안에서 전투 선택과 전리품 관리가 연결되면서도, 미확정 경제·강화 정책은 각 기능 내부에 고정하지 않습니다.</span></p>
            </div>

            <div class="sfh-group"><h3>🆕 구현 · 6</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">Q 메인·보조 무기 교체</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비 시스템의 활성 슬롯을 Q 입력으로 전환하고 자동 무기와 HUD가 같은 상태를 구독합니다.</p><a href="../features/weapon-balance/">무기 밸런스 문서 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">돌격소총과 제식 권총 특색</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>돌격소총은 긴 탐지 거리의 안정 3점사, 권총은 짧은 거리의 고위력 단발과 1회 관통을 사용합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">밸런스 모드 선택 UI</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>작전 시작 전에 확정 CSV와 공용 Weapon Sheet 실시간 테스트를 화면 버튼으로 선택합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">12×8 가변 격자 가방</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>아이템마다 1×1부터 4×2까지 다른 칸을 차지하며 경계와 겹침을 검사합니다.</p><a href="../features/grid-inventory/">가방 설계 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">I 가방과 U 장비·개조 화면</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>I는 작전 가방, U는 무기·방어구 탭과 파츠·모듈 조작을 여는 상호 배타적 모달입니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">장비 레벨과 최고 레벨 개조 태그</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>최고 레벨에서 태그를 부여하면 같은 태그 모듈의 유효 코스트를 올림 처리한 절반으로 계산합니다.</p><a href="../features/equipment-customization/">개조 규칙 →</a></div></details>
            </div>

            <div class="sfh-group"><h3>✨ 개선 · 5</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">에임 없는 SFH용 수치 체계</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>ADS·반동·조준 회복을 제외하고 탐지 거리·발사 패턴·치명타·관통을 핵심 수치로 재구성했습니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">행 기반 공용 데이터 시트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>1행 변수명, 2행 설명, 3행 이후 개별 데이터로 고정하고 Weapon·Armor·Item 탭의 책임을 분리했습니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">모듈 강화 단계별 코스트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>강화 단계별 코스트 배열을 Resource로 분리해 모듈마다 다른 성장 곡선을 정의할 수 있습니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">데이터 기반 장비 확장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>무기 소분류, 파츠 소켓, 모듈 태그와 스탯을 enum 변경 없이 Resource로 추가합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-improve">개선</i><span class="sfh-entry-title">전투·장비 상태 HUD</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>현재 슬롯, 무기 특색, 피해, 사거리, 밸런스 출처와 방어·스킬 상태를 함께 표시합니다.</p></div></details>
            </div>

            <div class="sfh-group"><h3>🧩 수정 · 4</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">장비·밸런스·발사 모듈 경계</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비는 활성 ID, 밸런스 서비스는 외부 데이터, 자동 무기는 발사 실행만 담당합니다.</p><a href="../architecture/module-audit/">모듈 감사 →</a></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">FeatureManifest 토글과 의존성</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>inventory, equipment_customization, weapon_balance 토글과 Resource 경로 검사를 추가했습니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">장비 시스템 공개 계약 확장</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장착·교체·파츠·모듈·강화·레벨·개조 기능을 내부 Node 경로 대신 공개 메서드와 Signal로 연결합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">Q·I·U 조작 안내 통합</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>게임 HUD와 실행 문서에 무기 교체, 가방, 장비·개조 입력을 일관되게 표시합니다.</p></div></details>
            </div>

            <div class="sfh-group"><h3>🔧 버그픽스 · 4</h3>
              <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">외부 밸런스 실패 폴백</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>HTTP 오류나 잘못된 CSV가 마지막 정상값을 덮어쓰지 않으며 초기 실패는 확정 CSV로 복구합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">밸런스 CSV 입력 검증</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>필수 열 누락, 중복 ID, 잘못된 확률과 관통 유지율을 거부합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">U 화면 슬롯 선택 초기화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>Godot 실제 화면에서 비어 있던 슬롯 선택기를 런타임에 명시적으로 초기화합니다.</p></div></details>
              <details class="sfh-entry"><summary><i class="sfh-badge is-fix">버그픽스</i><span class="sfh-entry-title">선택 모듈 비활성화 조립</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>장비 또는 밸런스를 끈 테스트에서 남은 의존성이 조립을 막지 않으며 기본 스탯과 소총 폴백을 유지합니다.</p></div></details>
            </div>
          </div>
        </details>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-29</b><small>랜덤 작전 맵 · 미니맵 · 탈출 · 파밍 · 장비 기반</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-summary">
      <strong>기반 구축 · 7개 주제</strong>
      <ul>
        <li>Godot 4 탑다운 이동과 가장 가까운 적을 공격하는 최소 전투 루프를 만들었습니다.</li>
        <li>투자 등급에 따라 소·중·대형 랜덤 방 수와 맵 규모가 증가합니다.</li>
        <li>얇은 벽, 복도, 내부 벽과 기둥, A* 적 길찾기를 연결했습니다.</li>
        <li>우측 상단 미니맵과 F 상호작용 탈출을 추가했습니다.</li>
        <li>1회성 크레딧 보급 상자와 탈출 회수·사망 분실 흐름을 구현했습니다.</li>
        <li>플레이어·적 체력과 방어력 HUD를 개선했습니다.</li>
        <li>무기 3단계 태그, 0~10개 스킬 호환, 범용 방어구 스탯 기반을 만들었습니다.</li>
      </ul>
      <p class="sfh-intent"><b>설계 원칙</b><span>최상위 Game은 조립만 담당하고, 맵·미니맵·탈출·파밍·장비는 공개 계약으로 교체할 수 있게 유지합니다.</span></p>
    </div>
    <div class="sfh-group"><h3>🆕 기반 구현 · 5</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">소·중·대형 로그라이크 작전 맵</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>투자 코스트 등급에 따라 방 수와 전체 경계가 증가하며 모든 방을 복도로 연결합니다.</p><a href="../features/map-generation/">맵 생성 문서 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">전술 미니맵과 전체 티어 진입</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>생성 스냅샷만 소비하는 미니맵을 우측 상단에 배치하고 중형·대형 진입 흐름을 검증했습니다.</p></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">F 탈출과 크레딧 회수</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>최원거리 탈출 지점에서 F를 누르면 휴대 크레딧을 확보하고, 사망하면 분실합니다.</p></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">적 체력·방어력 컴포넌트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>적 전투 상태와 머리 위 체력·방어력 표시를 독립 컴포넌트로 분리했습니다.</p></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">캐릭터 장비와 태그 호환</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>메인·보조 무기 대·중·소분류, 0~10개 스킬 완전 일치, 범용 방어구 스탯을 Resource로 구성합니다.</p></div></details>
    </div>
  </div>
</details>
</div>

## 현재 기능 진행 보드

| 기능 | 상태 | 현재 완료 범위 | 다음 확장 |
|---|---:|---|---|
| 기본 작전 루프 | ✅ 플레이 가능 | 소형 9분·중형/대형 10분 작전 → 전투·파밍 → 신호 개방 후 F 탈출 또는 사망 | 로비·반출 결과 |
| 랜덤 맵·미니맵 | 🧱 확장 완료 | 18~60방, 실내 벽·기둥, A*, 전체 지도 | 바이옴·특수 방 |
| 이동·생존 | 🧱 기반 완료 | 가속·제동·역선회·회피·대시 HUD, 지연형 65% 부분 회복 | 피격 연출·회피 무적 판정 |
| 장비·스킬 | 🧱 기반 완료 | 태그, 파츠, 모듈, 강화, 개조 | 특수 효과 실행기 |
| 로그라이크 성장 | 🧱 기반 완료 | 내부 XP·5종 버프·3계열 외부 레벨·저장 | 수치 정책·로비 성장 UI |
| 격자 가방 | 🧱 기반 완료 | 가변 점유, I UI, 장비 연동 | 영속 창고·전리품 반출 |
| 무기 밸런스 | 🧱 기반 완료 | Q 교체, 2종 특색, Sheet/CSV | 신규 무기·수치 확정 |
| 경제·저장 | 🧱 기반 진행 | 작전 크레딧 회수, 파츠·모듈 강화 비용, 외부 성장 저장 | 로비 재화·창고 저장 |

## 자동 검증 기준

`./scripts/test-game.cmd`가 다음을 한 번에 확인합니다.

- 소형 9분·중형/대형 10분 확장 맵과 목표 시간 잠금 탈출
- 가속·제동·역선회·회피 이동 응답, 대시 재사용 HUD와 부분 체력 회복 상한
- Q 무기 교체, 소총 3점사, 권총 관통, 확정 CSV
- I 가변 격자 가방과 U 파츠·모듈·강화·개조
- 적 체력·방어력, 플레이어 HUD, 내부 XP와 버프 선택·중첩
- 작전 종료 외부 XP 정산, 캐릭터·무기·방어구 레벨과 저장
- 동일 아이템·크레딧을 소비하는 모듈·고유 파츠 강화
- 1회성 파밍, 크레딧 회수, F 탈출과 게임오버
- 장비·맵·무기 밸런스 선택 모듈 비활성화 폴백

성공하면 `SMOKE_TEST_OK`와 함께 `start_hub`, `start_hub_optional`, `operation_gate`, `optimized_setup_ui`, `combat_session`, `hub_return`, `growth_balance_csv`, `run_buff_sheet`, `upgrade_sheet` 등의 검증 토큰이 출력됩니다.

## 의도적으로 남긴 확장 지점

| 항목 | 현재 처리 | 연결 예정 모듈 |
|---|---|---|
| 강화 재료·비용 | 동일 아이템 + 작전 크레딧 최소 정책 | 로비 재화·제작·재료 다양화 |
| 외부 성장 수치 | 고정 최소 정책과 JSON 저장 | 밸런스 시트·로비 성장 UI |
| 특수 기능 | `special_feature_ids`로 선언 | 효과 실행기 |
| 영속 가방 | 작전 런타임 데이터 | 저장·창고·전리품 반출 |
| 장비 교체 UX | Q 즉시 전환, U 첫 호환 아이템 | 직접 선택·비교 UI |
| 실시간 밸런스 | 공개 CSV 개발 모드 | 팀용 Google Sheet 권한 정책 |

## 다음 우선순위 후보

1. 로비·창고와 작전 전후 영속 인벤토리
2. 장비 강화 재료와 실제 비용 정책
3. 신규 무기 종류와 추가 발사 패턴·효과
4. 모듈 `special_feature_ids` 실행기
5. 스킬 효과·쿨다운·자원 소비

## 검색 별칭

업데이트, 패치노트, 릴리스 노트, 변경사항, 개발 진행률, 완료율, 작업 현황, 구현 내역, 개선 내역, 수정 내역, 버그픽스, 협업 현황, 다음 작업
