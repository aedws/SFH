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

<div class="sfh-release-stats"><span>최신 2026-08-30</span><span>7 META SYSTEMS</span><span>6.890ms LARGE RAID</span><span>MODULAR PASS</span></div>

## 기획 기준 진행도

<div class="sfh-progress-panel">
  <div class="sfh-progress-heading">
    <span><small>PLANNING PROGRESS · 2026-08-30</small><strong>현재 기획 진행도</strong></span>
    <b>71%</b>
  </div>
  <div class="sfh-progress-track" role="progressbar" aria-label="SFH 기획 진행도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="71"><i style="width: 71%"></i></div>
  <p>2026-08-30에 사용자가 제공한 기획 원문을 기준으로, 저장소에서 실제 확인되는 범위만 완료 또는 부분 완료로 계산했습니다.</p>
</div>

기획 원본은 [SFH 프로젝트 노션](https://app.notion.com/p/SFH-6b45b728004082af8a4a811ef0a1c5e9)입니다. 연결 API는 여전히 원본 페이지 권한을 받지 못하지만, 사용자가 이번 대화에 제공한 전체 본문을 권위 있는 스냅샷으로 사용해 저장소와 다시 대조했습니다. Phase 체크박스는 모두 미체크이므로 완료 증거로 사용하지 않고 실제 코드·자동 테스트만 판정 근거로 삼았습니다.

| 기획 묶음 | 가중치 | 구현률 | 현재 근거 |
|---|---:|---:|---|
| 확정 전투 원칙 | ×3 | 90% | 수동 조준 없는 이동·자동 공격·1~3 직접 스킬·쿨타임 HUD 구현, 별도 에너지/충전 자원은 후속 확장 |
| 스마트 오토 타겟팅 `(미확정)` | ×1 | 65% | 등급·체력 비율·밀집 가중 정책 구현. 최대 HP 우선, 밀집 **지점** 선택과 스킬 유형별 정책 분리는 미구현 |
| 코어 플레이 루프 | ×2 | 85% | 거점 준비→탐험·전투·파밍→탈출 방어→성공/사망 정산 구현. 시간 기반 환경 페널티는 미구현 |
| 로비 인베스트먼트·타겟 파밍 | ×1 | 55% | 맵·지역·난이도 비용과 보상/도면 배율 구현. 보스 확정, 고등급 가중치와 지역별 전체 드랍 테이블은 미구현 |
| 성장·순환형 해금 | ×1 | 60% | 영구 프로필·지역 해금·상점·창고·소모품 소비 구현. 장비/스킬 상점 등록과 무료 기본 맵은 미구현 |
| 무기 태그·스킬 장착 | ×1 | 55% | 3단계 태그 호환·0~10개 제한 구현. 등급별 발동 변형과 상태 부여→트리거 연계 기반은 미구현 |
| 페널티 모디파이어 | ×1 | 65% | 자발적 선택·복수 합성·보상 배율 구현. 회복 감소·시야 제한·탈출 지연 유형은 미구현 |
| 조건부 랭킹 | ×1 | 45% | 동일 조건 격리와 기록 저장 구현. 최소 페널티 점수 및 루팅·시간·처치 3종 분리 순위는 미구현 |

계산식은 `Σ(기획 묶음 구현률 × 가중치) ÷ Σ가중치`입니다. 명시적으로 확정된 전투 원칙은 ×3, 코어 루프는 ×2, `(미확정)`을 포함한 세부 묶음은 ×1을 적용했습니다. 현재 결과는 `(90×3 + 65 + 85×2 + 55 + 60 + 55 + 65 + 45) ÷ 11 ≈ 71%`입니다.

`완료`는 기능 이름이 존재한다는 뜻이 아니라 기획의 세부 수용 기준까지 충족한 경우에만 부여합니다. 따라서 이번 7개 시스템의 코드 구현 자체는 완료됐지만, 기획 요구와 다른 정책이나 빠진 변형은 위 표에서 부분 완료로 감점했습니다.

| 이번 요청의 저장소 구현 상태 | 상태 | 자동 검증 |
|---|---|---|
| 탈출 방어전·성공/실패 정산 | 완료 | 카운트다운 지속·완료·선택 비활성 폴백 |
| 투입 비용·지역·난이도 데이터 | 완료 | 최종 비용 173 C와 적·보상 합성 배율 |
| 영구 해금·상점·창고·소모품 | 완료 | 구매·해금·출격 소비·JSON 왕복 |
| 스마트 자동 타게팅 | 완료 | 거리 외 처형·등급·밀집 정책과 최근접 폴백 |
| 도면 제작·랜덤 옵션 | 완료 | 비용 소비·옵션 1~2개·중복 방지 |
| 페널티 변형 | 완료 | 최대 3개 선택 계약과 적·보상 배율 합성 |
| 조건부 랭킹 | 완료 | 성공만 제출·동일 조건 격리·정렬·JSON 왕복 |

#### 기획 마일스톤 판정

| Phase | 판정 | 저장소 대조 |
|---|---|---|
| Phase 1 · 이동·스킬·스마트 타게팅 | 부분 완료 | 이동·회피·3스킬과 가중 타게팅은 구현, 최대 HP/밀집 지점 정책은 불일치·미구현 |
| Phase 2 · 탈출 방어·정산 | 완료 | 탈출 활성화, 규모·난이도별 카운트다운, 생존·사망 정산 자동 검증 통과 |
| Phase 3 · 로비 투자·영구 해금 상점 | 부분 완료 | 맵·지역·난이도 비용과 상점·창고는 구현, 장비/스킬 상점 등록과 타겟 드랍표는 미구현 |
| Phase 4 · 태그 슬롯·페널티 | 부분 완료 | 3단계 태그 제약과 페널티 배율은 구현, 등급별 스킬 변형·상태 연계·기획 예시 페널티는 미구현 |

### 2026-08-30 기획 원문 재대조

[SFH 프로젝트 노션](https://app.notion.com/p/SFH-6b45b728004082af8a4a811ef0a1c5e9)의 본문을 사용자가 대화에 직접 제공했으며 다음 상태를 확인했습니다.

- `수동 조준 배제`는 확정 사항이며 현재 구현과 일치합니다.
- 스마트 자동 타게팅, 시간 경과 위험 증가, 장비·스킬 상점 영구 등록은 `(미확정)` 상태입니다.
- Phase 2의 탈출 방어·생존/사망 정산은 수용 기준을 충족합니다.
- Phase 1·3·4는 핵심 기반이 있으나 세부 정책 차이와 빠진 기능 때문에 부분 완료입니다.
- 네 Phase 체크박스 자체는 모두 미체크이므로 자동으로 체크 상태를 바꾸지 않았습니다.

### 앞으로 해야 할 작업

| 우선순위 | 작업 | 기획 상태 | 완료 조건 |
|---:|---|---|---|
| 1 | 스마트 타게팅을 스킬 유형별 정책으로 분리 | `(미확정)` | 단일은 최대 HP/등급, 범위는 최고 밀집 지점, 이동은 입력 벡터 사용 |
| 2 | 조건부 랭킹을 기획의 3개 종목으로 분리 | 요구 | 동일 맵·최소 페널티 점수에서 루팅·최단 시간·최다 처치 각각 정렬 |
| 3 | 투자 비용 기반 보스·고등급 드랍과 지역 드랍표 | 요구 | 고비용 보스 확정, 등급 가중치, 지역별 장비/스킬 풀 적용 |
| 4 | 무료 기본 맵과 완전 소모성 장비 로드아웃 | 요구 | 파산 상태 진입 가능, 장비 포함 투입품이 사망 시 소실 |
| 5 | 페널티 유형 확장 | 요구 | 회복 감소·시야 제한·탈출 지연을 독립 Resource로 선택·합성 |
| 6 | 무기 등급별 스킬 변형과 상태 연계 기반 | 요구 | 등급이 발동 방식을 바꾸고 상태 부여→트리거 조합이 데이터로 동작 |
| 7 | 시간 경과 위험·환경 페널티 | `(미확정)` | 체류 시간에 따라 적 스펙·물량·환경 위험이 단계적으로 증가 |
| 8 | 제작 장비를 U 화면과 실제 스탯에 연결 | 구현 후속 | 제작 인스턴스와 랜덤 옵션이 장비 슬롯·스탯 집계에 반영 |

<div class="sfh-notes">
<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-08-30</b><i class="sfh-latest">최신</i><small>방·통로 안개 전환 · 7개 작전·영구 성장 시스템 통합</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>전기 스킬 표현 · 대형 작전 성능 예산</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-summary">
      <strong>핵심 변경 · 5개 주제</strong>
      <ul>
        <li><code>1</code> 점멸은 전기 잔상, <code>2</code> 자기장은 원형 전기장, <code>3</code> 가속은 추적형 전기 방출을 표시합니다.</li>
        <li>공용 전기 렌더러와 세 프로필을 분리해 패턴·색·수명·밀도·갱신률을 데이터로 교체합니다.</li>
        <li>형상 10~20Hz 캐시, HUD 10Hz, one-shot Timer로 매 프레임 갱신과 할당을 줄였습니다.</li>
        <li>연속 맵 충돌체 병합, 적 A* 0.7초 분산 갱신과 생성 목록 Signal 정리를 적용했습니다.</li>
        <li>대형 맵·적 72명에서 평균 6.887ms, 최대 10.328ms, Node 1,490개, 충돌체 6.7%를 검증했습니다.</li>
      </ul>
      <p class="sfh-intent"><b>검증 결과</b><span>기능 스모크 테스트와 별도 대형 작전 성능 게이트를 통과했으며 실제 최소 사양은 저사양 GPU 실기 인증 전까지 임시 목표로 관리합니다.</span></p>
    </div>
    <div class="sfh-group"><h3>🆕 구현 · 2</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">공용 전기 아크와 스킬별 프로필</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>점멸·자기장·가속이 같은 렌더러에 독립 Resource를 주입합니다.</p><a href="../features/combat-skills/">스킬 계약 →</a></div></details>
      <details class="sfh-entry"><summary><i class="sfh-badge is-build">구현</i><span class="sfh-entry-title">성능 예산 자동 테스트</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>대형 작전 240프레임의 평균·최대 시간과 SceneTree 예산을 검사합니다.</p><a href="../performance/minimum-requirements/">사양·성능 예산 →</a></div></details>
    </div>
    <div class="sfh-group"><h3>🧩 수정 · 1</h3>
      <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">충돌·경로·UI 핫패스 최적화</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>기능 경계를 유지하면서 반복 Node·배열·경로 계산만 각 소유 모듈 안에서 줄였습니다.</p><a href="../architecture/module-audit/">모듈 감사 →</a></div></details>
    </div>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>큰 시작 거점 · F 작전 게이트 · 전투 세션 복귀</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>내부 성장 · 무기·방어구·모듈 Google Sheets 연동</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>2.5~5배 회수 · 유한 적 재생성 · 핵앤슬래시 무브먼트</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>방·통로 전장의 안개 최적화 · 정면 시야 확장</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>맵 비례 적 증원 · 최소 2.5배 회수 가치 · 전체 결합 재점검</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>화면 한 장급 방 · 전장의 안개 · 자원 회수 지점</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>전체 화면 장비 · 모듈 인벤토리 UI</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>확장 맵 · 10분 런 · 반응형 이동 · 부분 회복</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>로그라이크 성장 · 강화 경제 · 모듈 전수 점검</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>무기 밸런스 · 격자 가방 · 장비 개조</small></span><em class="sfh-chevron">⌄</em></summary>
  <div class="sfh-day-body">
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
| 기본 작전 루프 | ✅ 플레이 가능 | 9~11분 작전 선택 → 전투·파밍 → 신호 개방 후 F 탈출 또는 사망 | 로비·반출 결과 |
| 랜덤 맵·미니맵 | 🧱 확장 완료 | 18~60방, 실내 벽·기둥, A*, 전체 지도 | 바이옴·특수 방 |
| 이동·생존 | 🧱 기반 완료 | 가속·제동·역선회·회피, 지연형 65% 부분 회복 | 피격 연출·회피 무적 판정 |
| 장비·스킬 | 🧱 기반 완료 | 태그, 파츠, 모듈, 강화, 개조 | 특수 효과 실행기 |
| 로그라이크 성장 | 🧱 기반 완료 | 내부 XP·5종 버프·3계열 외부 레벨·저장 | 수치 정책·로비 성장 UI |
| 격자 가방 | 🧱 기반 완료 | 가변 점유, I UI, 장비 연동 | 영속 창고·전리품 반출 |
| 무기 밸런스 | 🧱 기반 완료 | Q 교체, 2종 특색, Sheet/CSV | 신규 무기·수치 확정 |
| 경제·저장 | 🧱 기반 진행 | 작전 크레딧 회수, 파츠·모듈 강화 비용, 외부 성장 저장 | 로비 재화·창고 저장 |

## 자동 검증 기준

`./scripts/test-game.cmd`가 다음을 한 번에 확인합니다.

- 소·중·대형 확장 맵과 9~11분 목표·시간 잠금 탈출
- 가속·제동·역선회·회피 이동 응답과 부분 체력 회복 상한
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
