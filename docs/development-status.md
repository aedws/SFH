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

<div class="sfh-release-stats"><span>최신 2026-09-23</span><span>SEARCH COMMAND</span><span>16 DAYS · 176 TOPICS</span><span>CLOUDFLARE LIVE</span></div>

## 9/23 승인 정책 첫 반영

권장15~20분·20분 오염/Hunter·30분 붕괴를 구현하고 단일 정산·문 독립 추적·기존50% 보스 병존을 자동 검증했습니다. 추가15고유요구만의 코드 상태는 **구현7·부분5·미구현3**입니다. 전체82행의 새 백분율·장시간 사람 수락 완료는 아닙니다. [동작과 임시 수치](features/extraction-defense-results.md#pressure-20260923) · [검수 경계](quality/e2e-play-session.md#pressure-20260923).

가방/파우치·심층·룬·요원의 미정 세부값은9/23 승인에 따라 교체 가능한 임시 정책으로 진행합니다. 기존 저장품의 옵션·강화·회전은 보존해야 하며 아래 과거 ‘판단 대기’는 현행 대기가 아닙니다. 실서비스 계정·과금은 제외합니다. [현재 실행 순서](design/current-milestone-workline.md#approved-20260923).

## 9/22 결정 항목 반영

[런 소켓 대상 선택](features/session-sockets.md#target-selection-20260922)을 보완했습니다. 가방에서 적용 스킬을 고르고 저장 확인 후 대상/실물 아이템을 재검증합니다. 기존 전역 소켓 용량·효과값은 유지하며 스킬별1~3소켓·4계열 룬 전체는 미완료이므로 고유15요구의 구현5·부분5·미구현5는 변하지 않습니다. 공개 GDD101블록/작업표82행 해시도 재조회에서 동일합니다.

후속으로 [플레이 흐름 계측](quality/e2e-play-session.md#run-flow-20260922)을 구현했습니다. 구간별 실제 경과·전리품 판단·후퇴/미완료/누락을 로컬 보고서로 남깁니다.1~2분 순환·보상 전체 처리3초의 사람 수락은 미검증이므로 부분 구현 수를 임의로 줄이지 않습니다.

장착 룬 정산·실시간 가방에 이어 [전술 적응](features/character-selection.md#tactical-adaptation-20260922)을 구현했습니다. 신규16행 중 중복1행을 제외한15요구는 코드 구현5·부분5·미구현5입니다. 원본 GDD101블록/작업표82행은9/21 해시와 동일하며 기획 상태는 수정하지 않았습니다. 전체82행 진행률이나 정상10분 사람 검수 완료를 뜻하지 않습니다. [변화·검증·다음 작업](design/current-milestone-workline.md#decided-20260922).

## 9/21 원본 재확인 · 최신 대응도 재산정 대기

공개 GDD v206·101블록/작업표82행을 재조회했습니다. 신규39블록·16행이며 기존66행은 동일합니다. 아래80.3%는 **9/9 이전 범위의 감사 이력**이고 최신82행 진행률이 아닙니다. 신규 미니루프2행 중복 후보와 코드/정책 충돌을 분리한 뒤 재산정합니다. [조회 해시·코드 차이·다음 판단](design/master-gdd-alignment.md#source-recheck-20260921).

## 이전 66행 기준 코드 대응도 (9/9 이력)

<div class="sfh-progress-panel">
  <div class="sfh-progress-heading">
    <span><small>GDD + TRACKER · 2026-09-09</small><strong>확정도 가중 코드 대응도</strong></span>
    <b>80.3%</b>
  </div>
  <div class="sfh-progress-track" role="progressbar" aria-label="최신 기획 코드 대응도" aria-valuemin="0" aria-valuemax="100" aria-valuenow="80.3"><i style="width: 80.3%"></i></div>
  <p>당시 GDD v128·62블록과 트래커66행을 코드·기존 테스트 소스와 대조한 이력입니다. 9/21 신규82행의 진행률·출시 준비율·실제 플레이 통과율이 아닙니다. 기존96%도 이전 백업 기준 이력입니다.</p>
</div>

원본: [최신 Master GDD](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed) · [기능 구현·상태 트래커](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2).
**기획 대응도 기준은 9/9 20:12의 `a41f424`, 당시 마감 게임은 `a423dad`입니다.** 위 숫자는 당시 공개 GDD·트래커 대조 결과이며9/10에 재산정하거나 새 Notion 조회로 표시하지 않습니다. 훈련 라이브 수치는9/10 수정·회귀 완료했으나 일반10분/F·맵/스킬 체감 수락은 남습니다. **아직100%가 아닙니다.** [후속 수정·근거](quality/full-system-audit-20260909.md#followup-20260910) · [다음 실행](design/current-milestone-workline.md#next-20260910).

| 코드 판정 | 항목 수 | 점수 |
|---|---:|---:|
| 구현 근거 있음 | 45 | 1 |
| 부분 대응 | 1 | 0.5 |
| 신규 미구현 | 6 | 0 |
| 기존 규칙과 충돌 | 0 | 0 |
| 기획 판단 대기 | 14 | 0 |

노션 결정52개×3·미정14개×1로 가중합니다. `(45×3 + 1×0.5×3) ÷ (52×3 + 14) = 136.5/170 = 80.3%`. [노션 외 구현10묶음](design/master-gdd-alignment.md#implemented-outside-notion)·위키 도구는 가산하지 않습니다. 미정14행 제외87.5%. 선행 정책 대기6행까지 제외한46행 참고값은98.9%이나, 별도 품질 오류와 일반 플레이 잔여 때문에 제품 완료율로 사용할 수 없습니다.

## 현재 빌드 상태

**현행 콘텐츠:** 시작3요원·8무기 선택, 고정 패시브, 액티브40종(동시3), 방어구14종/3세트, 16:10 PC 장비 UI입니다. 9/22 전술 적응 반영으로 CSV는 `2026-09-22.1`입니다. AP 패시브 배율만 확정값으로 교체했고 기본 AP 정책과 다른 임시 수치는 유지합니다. [검증·다음 작업](quality/e2e-play-session.md#vanguard-20260922). 아래 날짜별 배포 커밋은 당시 이력입니다.

**최신 공간 규칙:** B 복합 구역의 제한된 입구·내부 연결에 A 불규칙 바닥과 C 단계별 다각형 변형을 적용합니다. 시설마다 도로 직결/출입구 2개는 폐기한 이전 규칙입니다. 위험 1~10단계는 같은 지역·규모의 기본 투입비와 연동하고 장비 추가비는 분리합니다. 일반 후퇴·금고 F 선택 봉쇄·두 출구 방어·안전 단말 워프·실제 바닥 기반 공간 공개는 유지합니다. [현행 계약](features/extraction-district.md#compound-20260909) · [90생성/30출격·배포 검수](quality/e2e-play-session.md#compound-20260909).

2026-09-08: 표준 HP는 키트 전용이며 KIT 버튼에서 지참 수량을 사용합니다. 자연·HP 드랍·레벨업·버프 회복은 차단하고 AP는 유지합니다. 아래 기존 마일스톤 설명 중 HP 충돌 대기는 이번 승인으로 대체됩니다. N26-08B의 첫 GPU 프레임·배포 양 플랫폼10분 일반 플레이 수락은 계속 진행 중입니다.

거점 → 작전 → 방 전투·파밍 → 탈출·정산을 유지합니다. 임시 AP·소켓·훈련에 손상 매물 가격 범위와 실제 바닥/타겟 어댑터를 추가했습니다. ShopOffer의 2개 가격만 Sheet·CSV·Web payload에 동기화했으며 HP 규칙·영구 저장 스키마는 유지합니다.

최신 원본에서는 키트 중심 생존, 보안 파우치, 심층 진입과 혈전 프로필 요구가 추가되거나 구체화됐습니다. 기존 HP 자연 회복·드랍·레벨업 회복과의 충돌, AP와 충전의 차이, 광역 타게팅 중심 덮어쓰기를 별도 작업으로 분리했습니다.

## 다음 작업과 판단

**2026-09-10 우선순위:** 훈련/작전 라이브 동등성 수정→모듈 감사 보강→양 플랫폼 정상10분/F→B+A+C·1/5/10단계 FUN QA→스킬 계열 체감→회귀·위키 마감. [시작 파일·명령·완료 기준](design/current-milestone-workline.md#next-20260910)을 준비했습니다. 파우치·심층·혈전 및 최종 밸런스는 기획자 제안·오너 승인을 기다리며 임의 변경하지 않습니다.

[오너 판단표](design/master-gdd-alignment.md#owner-conflicts)에서 회복·AP·파우치·심층·혈전·소켓·기술·상태의 8개 결정을 확인합니다. 기존 사용자 지시를 대체하는 규칙은 승인 전에 적용하지 않습니다.

[최신 N26 작업선](design/current-milestone-workline.md#notion-20260907):
N26-03A/B·훈련 복원·승인 임시 AP/소켓과 손상 매물·청크 바닥 대체·후보 Area2D는 구현·자동 회귀 근거가 있습니다. 남은 부분 대응은 배포 Web/Windows 일반 플레이 검수1행입니다. HP 키트 전용은 승인 구현됐으며 파우치·심층·혈전 정책은 별도 결정으로 유지합니다.
P1~P10은 기존 이력을 보존하며 최신 우선순위는 N26 기준입니다.

<div class="sfh-notes">

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-23</b><i class="sfh-latest">최신</i><small>3 UPDATE BUNDLES · BUILD 3 · IMPROVE 3 · CHANGE 1 · FIX 2</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 3</small><b>작은 가방과 보호 주머니 · 실패해도 지킬 전리품 선택</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>가방36칸과 보호 주머니4칸을 적용했습니다. 도면·룬·코어·유물을 넣고 저장하면 실패 시 원형으로 거점 보관에 돌아옵니다. 성공 시에는 기존 해금·환전 규칙을 따릅니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>기존 초과 저장품은 삭제하지 않고 보관합니다. Windows 보호 체크포인트와 소켓 왕복에서도 실물 ID·부가 데이터를 유지합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>가방36/48/60/72칸과 주머니4/6/8칸을 공유 시트·잠금 CSV·Web 데이터로 분리했습니다. 확장 가격 미승인으로 구매는 잠금 상태입니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>사망 복귀에서 보호 가방 상태가 누락되지 않게 했습니다. 미저장 편집·반복 정산·실패한 결제로 아이템이나 재화를 중복 처리하지 않습니다.</p></div>
        <p><a href="/features/grid-inventory/#pouch-20260923">사용법·가격 판단</a> · <a href="/quality/e2e-play-session/#pouch-20260923">검증과 남은 수락</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>장비를 그대로 보관 · 무손실 가방 이관 기반</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>거점 I에서 실물 보관과 꺼내기를 추가했습니다. 옵션·강화·회전·실물 ID를 유지하고, 저장하지 않은 이동은 취소할 수 있습니다. 전투 중 보관 이동은 차단합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>가방 축소 초과분을 수량 창고로 바꾸지 않고 같은 저장 문서에서 보존합니다. 기본96칸은 유지하며, 등급별36~72칸 적용과 보안 파우치는 다음 단계입니다.</p></div>
        <p><a href="/features/grid-inventory/#reserve-20260923">보관 사용법·미구현 경계</a> · <a href="/quality/e2e-play-session/#reserve-20260923">저장·취소·재시작 검증</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>오래 머무를수록 위험 · 20분 Hunter와 30분 붕괴</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>15~20분 생환을 권장합니다. 20분에는 일반 적이 강화되고 문을 무시하는 Hunter가 한 번 등장합니다. 기존 회수액50% 추격 보스도 유지됩니다. 30분까지 탈출하지 못하면 작전이 실패합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>출격 전 시간 규칙을 안내하고 전투 HUD에 붕괴 잔여 시간을 표시합니다. 조기 탈출은 그대로 가능하며 시간·강화 수치는 독립 정책으로 분리했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>작전이 끝난 뒤 늦게 들어온 탈출·사망 신호가 정산 결과를 바꾸지 못하도록 막았습니다. 자동 시간 경계 검사와 정상 속도 장시간 플레이 수락은 구분합니다.</p></div>
        <p><a href="/features/extraction-defense-results/#pressure-20260923">시간·정산 계약</a> · <a href="/quality/e2e-play-session/#pressure-20260923">검증과 미수락 범위</a> · <a href="/design/current-milestone-workline/#next-20260923">승인된 다음 작업</a></p>
      </div>
    </details>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-22</b><small>4 UPDATE BUNDLES · BUILD 4 · IMPROVE 3 · CHANGE 1 · FIX 1</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 4</small><b>코어를 원하는 스킬에 직접 장착</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>가방에서 코어의 적용 스킬을 직접 선택합니다. 첫 스킬 외에도 장착할 수 있으며 취소하면 아이템과 효과는 그대로 유지됩니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>저장 확인 중 대상이 바뀌면 장착을 멈추고 재선택을 안내합니다. 같은 아이템이 여러 개여도 선택한 것만 사용합니다. 기존 소켓 수와 효과값은 유지합니다.</p></div>
        <p><a href="/features/session-sockets/#target-selection-20260922">대상 선택 사용법</a> · <a href="/quality/e2e-play-session/#socket-target-20260922">검증과 미수락 범위</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>뱅가드 · 이동하며 AP를 더 빠르게 회복</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>선봉대의 임시 피해 보너스를 전술 적응으로 교체했습니다. 기본 AP +15%, 실제 이동 중 자연 회복 +20%로 훈련과 작전에 적용합니다. 요원을 반복 교체해도 AP가 공짜로 채워지지 않습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>공유 시트·Web 데이터·계산기를 함께 갱신했습니다. 정지/이동 조건을 비교할 수 있으며 기본 AP 수치는 임시, 패시브 배율은 확정으로 구분합니다.</p></div>
        <p><a href="/features/character-selection/#tactical-adaptation-20260922">패시브와 데이터 계약</a> · <a href="/quality/e2e-play-session/#vanguard-20260922">검증 근거</a> · <a href="/design/current-milestone-workline/#next-20260922">잔여 작업</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>전투·보상·이동이 끊기는 구간을 따로 기록</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>방 방문부터 전투·보상 선택·다음 방 이동까지 구간별 관측을 추가했습니다. 후퇴·보류·사망은 정상 완료와 나눠 기록하며 전투 화면이나 밸런스는 바꾸지 않습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>최신 로컬 보고서로 느린 구간을 찾을 수 있습니다. 계측 검증과 실제 재미 수락을 구분하고, 다음은 정상 속도10분/F·중대형·모바일 플레이 확인입니다.</p></div>
        <p><a href="/quality/e2e-play-session/#run-flow-20260922">기록 해석과 검수 기준</a> · <a href="/design/current-milestone-workline/#next-20260922">다음 작업</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>전투는 가방에서도 계속 · 장착 룬 환전 검증</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>작전 중 I/E 가방·모듈 편집과 저장 확인에서 시간·적·피격·쿨타임이 계속됩니다. UI 뒤 이동·공격과 사망 후 미저장 편집 적용은 막고 현재 HP를 표시합니다. 거점 준비는 종전 방식을 유지합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>장착 룬도 환전하는 기존 정산을 실제 드랍·F 획득·해제/재장착·탈출·사망·중복 지급 시험으로 확인했습니다. 신규15개 고유 요구의 코드 상태는 구현4·부분6·미구현5이며 전체82행 완료율이 아닙니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>음향 자동 검사의 대기 시간을 실제 음향 제한과 같은 시계로 맞췄습니다. 게임 음향·전투 밸런스는 바꾸지 않았습니다.</p></div>
        <p><a href="/features/grid-inventory/#realtime-20260922">가방 변화</a> · <a href="/features/session-sockets/#settlement-20260922">장착 룬 정산</a> · <a href="/quality/e2e-play-session/#decided-20260922">검증과 미수락 범위</a> · <a href="/design/current-milestone-workline/#next-20260922">다음 순서</a></p>
      </div>
    </details>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-21</b><small>3 UPDATE BUNDLES · BUILD 1 · IMPROVE 2 · CHANGE 2 · FIX 1</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 3</small><b>적의 공격을 보고 회피 · 신규 기획16행 대조와 다음 작업 정리</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>적의 즉시 접촉 피해를0.4초 붉은 경고와 좁은 고정 방향 타격으로 바꿨습니다. 옆으로 피하면 빗나가고 기절·넉백·사망은 경고를 취소합니다. 기존 추격 보스의 문 무시는 유지합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>신규 기획16행을 코드·시험 근거에 연결했습니다. 중복1행을 제외하고 코드 구현2·부분8·미구현5이며, 이는 전체82행 완료율이 아닙니다. 다음은 장착 룬 정산 검증·실시간 가방·짧은 루프 계측 순서입니다.</p></div>
        <p><a href="/features/enemies/#telegraph-20260921">변경된 공격</a> · <a href="/quality/e2e-play-session/#telegraph-20260921">검증·미수락 범위</a> · <a href="/design/current-milestone-workline/#delta-audit-20260921">전체 대조와 작업 순서</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>탈출은 잠깐 벗어나도 유지 · 오래 이탈하면 방어 시간 역행</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>탈출 방어 중 구역을 벗어나면2초 동안 진행을 보존하고 이후 초당1초씩 남은 시간이 늘어납니다. 돌아오면 자동 재개하며 처음 방어 시간보다 늘어나지 않습니다. 두 출구의 유예·역행·정산 회귀를 추가했습니다.</p></div>
        <p><a href="/features/extraction-defense-results/#decay-20260921">변경된 탈출 규칙</a> · <a href="/quality/e2e-play-session/#decay-20260921">검증 범위</a> · <a href="/design/current-milestone-workline/#notion-implementation-20260921">신규 기획 반영 순서</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>전투 표현 마감 · 전리품 비교 보완 · 기획 원본 재확인</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>총탄·근접·명중·40스킬의 밝기와 잔광을 보강했습니다. 밝고 어두운 바닥92사례와 전투 회귀를 검사하고 피해 수치·이펙트 수 상한은 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>크레딧·룬을 총기와 비교하던 표시와 방어구의 무기 전용 등급 필드 접근을 수정했습니다. 실제 교체 슬롯과 비교하며 등급 없는 장비에 등급을 만들지 않습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>공개 기획 갱신을 확인하고 변경 요구·기존 규칙과의 차이를 팀 문서에 분리했습니다. 이 원본 재확인 시점에는 신규 기획 미적용이었으며 이후 첫 반영은 위 UPDATE 2를 참조하세요. 정상10분 플레이 수락은 미완료입니다.</p></div>
        <p><a href="/features/hit-feedback/#readability-20260910">표현·예산</a> · <a href="/quality/e2e-play-session/#readability-20260910">검사 범위</a> · <a href="/design/master-gdd-alignment/#source-recheck-20260921">팀 문서 · 원본 재확인</a></p>
      </div>
    </details>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-10</b><small>3 UPDATE BUNDLES · BUILD 1 · IMPROVE 3 · CHANGE 0 · FIX 2</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 3</small><b>공격이 보이도록 · 전투 이펙트 전수검수와 전리품 비교 수정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>총탄 궤적·근접 잔광·접촉 섬광·스킬 전류를 보강하고 밝은 바닥과 축소 화면까지92사례를 검사했습니다. 전투 수치와 카메라 상한은 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>실제28처치·회수 검수에서 크레딧과 룬을 현재 총기와 비교하던 표시를 수정했습니다. 장비는 실제 교체 슬롯과 비교합니다. 정상10분 플레이는 계속 검수 대상입니다.</p></div>
        <p><a href="/features/hit-feedback/#readability-20260910">표현 변경·예산</a> · <a href="/quality/e2e-play-session/#readability-20260910">전수검사·실제 플레이 근거</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>모듈 지도 · 클래스 참조까지 같은 기준으로 감사</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>경로만 보던 감사에 클래스·상속 참조를 더하고 위키 노드맵과 분석기를 통일했습니다. 공개 CSV 파서와 확장 회귀를 보완했습니다. 동적 조립 검토와 정상10분 수락은 별도 잔여입니다.</p></div>
        <p><a href="/architecture/module-audit/#training-feedback-20260910">모듈 경계·검사</a> · <a href="/design/current-milestone-workline/#next-20260910">다음 실행 순서</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>훈련 수치 일치 · 발사·스킬·명중·처치 피드백</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>상업 이용이 허용된 CC0 효과음6종을 선별해 발사·근접·스킬 발동·체력/장갑 명중·처치에 연결했습니다. 출처·라이선스·해시와 동시8음성 예산을 함께 관리합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>직선 폭·부채꼴 경계·원형/링 맥동·연쇄 타격·접촉 스파크를 보강했습니다. 전체 게임/E2E와 실제 GPU·오디오 믹서 검사는 통과했으며 정상10분 재미 수락과 구분합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>훈련장이 라이브 스킬 대신 원본 수치를 쓰던 문제를 공통 불변 스냅샷으로 수정했습니다. 입장 시 갱신하고 실험 중 고정하며 종료 시 기존 장착·자원을 복원합니다.</p></div>
        <p><a href="/features/hit-feedback/#combat-audio-20260910">타격 표현·상업 이용 근거</a> · <a href="/quality/e2e-play-session/#training-feedback-20260910">수정 전후·검증 범위</a></p>
      </div>
    </details>
  </div>
</details>
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-09</b><small>14 UPDATE BUNDLES · BUILD 6 · IMPROVE 13 · CHANGE 1 · FIX 8</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 14</small><b>오늘 마감 · 위키 현행성·내일 시작 패킷</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>맵 출입·실제 바닥 시야·10단계 투자 계약을 현행 코드와 맞추고 이전 설명은 이력으로 분리했습니다. 내일 훈련 수치 동등성부터 수정하도록 코드 위치·재현·검사 명령·수락 기준을 연결했습니다. 게임·CSV·기획 점수는 변경하지 않습니다.</p></div>
        <p><a href="/quality/full-system-audit-20260909/#day-close-20260909">충돌 대조</a> · <a href="/design/current-milestone-workline/#start-packet-20260910">내일 첫 작업 열기</a>. 일반10분·체감 검수는 미완료로 유지합니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>복합 구역 맵 · 위험 1~10단계</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>B 구역 연결에 A 불규칙 바닥과 C 다각형 위험 변형을 결합했습니다. 모든 건물 주변을 우회하던 도로를 줄이고 내부 시설·후퇴 경로를 구분합니다. 1~10단계 투자·적 배수는 Difficulty 시트와 확정 CSV로 분리했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>실제 바닥을 시야·스폰·보상·지도 판정에 공유하고 출격 검증을 30조합으로 확장했습니다. 위키 설계실도 현재 구역과 위험 단계별 형태를 표시합니다. 수치는 임시이며 자동 검사와 정상 체력 재미 수락은 구분합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>Web 첫 무기 선택이 비어 로비에 진입하지 못하던 리소스 열거를 수정했습니다.</p></div>
        <p><a href="/features/extraction-district/#compound-20260909">변경 이유·시트 입력·모듈 경계·수락 기준</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 12</small><b>전체 검사 · 완료율과 잔여 작업 구분</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>전체 모듈·게임·E2E를 재검사하고 최신 노션과 대조했습니다. 기준 a41f424, 136.5/170=80.3%, 미정14행 제외87.5%. 자동 회귀는 통과했지만 훈련 라이브 수치 불일치와 일반10분 수락이 남아100%로 표시하지 않습니다.</p></div>
        <p><a href="/quality/full-system-audit-20260909/">원본·계산·재현 오류·다음 실행 순서</a> · 문서 현행화이며 해당 오류 수정 배포는 아닙니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>첫 출격 요원·무장 선택 · 액티브 40종과 고정 패시브</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>PC/모바일 선택 뒤 요원·초기 무장을 정하고 로비로 들어갑니다. 기존4종에 신규36종을 더했으며 요원별 고정 패시브가 돌파·기동·구역 유지 계열을 특화합니다. 저장 장비와 로비→작전 장착 상태는 보존합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>SkillPattern 시트와 효과 컴파일러, 독립 발동 스냅샷을 연결했습니다. 실제40종 자원·쿨타임과 초기24조합 출격을 검사합니다. 신규 수치는 임시이며 일반10분 플레이 수락과 구분합니다.</p></div>
        <p><a href="/features/tactical-skill-catalog/">전체 목록·시트 조정·검증 범위</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>16:10 장비 화면 · 무기와 방어구 중심 배치</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>PC·브라우저 기준 화면을 1280×800으로 변경했습니다. 파츠 화면은 무기 거치대를 확대하고, 장비 작업대와 모듈 화면은 실물 미리보기·장착 카드·효과를 중심으로 재배치했습니다. 모바일 터치 배율은 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>창을 줄인 뒤 이전 가방 폭이 남는 현상과 긴 제목이 패널 높이를 키우는 문제를 수정했습니다. 작은 화면은 내부 스크롤, 파츠 호환·교체·저장 확인은 기존 동작을 유지합니다.</p></div>
        <p><a href="/quality/game-ui-rematch/#equipment-1610">화면 구성과 검증 범위</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>방어구 14종 · 4부위와 2/4세트 효과</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>수호자·질주자·축전자 12종을 추가했습니다. 머리·몸·손·발에 장착하며 2/4세트와 2+2 혼합으로 생존·기동·스킬 성능을 조정합니다. 기존 방탄복·전투화와 저장 장비는 유지합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>지역별 방 보상·보스 드랍, 가방 편집·저장·복원, 모듈 화면의 세트 활성 표시, 게임과 같은 DPS·성장 그래프를 연결했습니다. 공유 시트에 ArmorSet 탭과 방어구·성장·드랍 목록을 추가했습니다. 수치는 임시입니다.</p></div>
        <p><a href="/features/armor-sets/">방어구 세트·조정 방법</a> · <a href="/quality/e2e-play-session/#armor-20260909">검증 범위</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>무기 8종 · 실제 근접 베기와 찌르기</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>단검·대검은 실제 근접 베기, 신규 창은 긴 찌르기로 변경했습니다. 산탄총 5발 분산과 레일 소총 관통으로 총기 5종·근접 3종을 구성합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>근접 무기가 소총 기본값으로 발사되고 기본 주무기 슬롯에 장착되지 않던 제약을 수정했습니다. 기존 Windows 저장의 기본 슬롯도 장비를 보존하며 갱신합니다. 근접 판정은 벽·후방·거리·중복 타격을 검사합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>Sheet 무기 8행과 드랍 101행, 가방·로비 장착·작전 유지·DPS 그래프를 연결했습니다. 새 수치는 임시 밸런스이며 장시간 재미 검수와 구분합니다.</p></div>
        <p><a href="features/weapons/#arsenal-20260909">무기별 차이·획득·조정 방법</a> · <a href="quality/e2e-play-session/#arsenal-20260909">검증 범위</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>무기 드랍 재검증 · 교체 스킬 키·복원 수정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>교체 스킬이 사용자 지정 키를 잃던 출격 경로와 K 설정·연속 교체·복귀 시 배치 불일치를 수정했습니다. 임시 스킬 ID는 영구 설정에 남기지 않습니다.</p><p>실행 계약 없는 효과가 유효한 스킬로 인정되던 검증 누락을 막았습니다. 정의·효과를 교체한 시험 스킬도 공통 실행기로 발동합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>무기 방/보스 드랍 54경로와 실제 가방·장착·정산 E2E를 확인하고, 세 규모 보조 출구를 실제 F 입력으로 검사했습니다. 일반 적 무기 드랍 행은 없으며 보상 정책은 유지합니다.</p></div>
        <p><a href="quality/e2e-play-session/#loot-skill-20260909">감사 결과·수정·남은 일반 플레이 QA</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>기획자 안내 · 미정 14건의 판단 질문과 예시</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>최상단 판단 안내에 추가 미정 14건의 선택 질문·미승인 예시를 항목별로 제공했습니다. 같은 요청 ID는 항목 이름까지 전달하고, 임시 구현 유지와 새 승인·서버 운영을 구분합니다.</p></div>
        <p><a href="access/planner/#decisions-needed">기획자 판단·Notion 전달 안내</a>. 실제 게임 정책이나 수치는 변경하지 않습니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>기획 판단 안내 · 거점 게이트 F 판정 통합</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 1</h3><p>기획자 작업실 최상단에 필요한 판단·미승인 예시·Notion 작성 후 오너 개인 메시지 안내를 배치했습니다. 접힌 항목으로 내용을 나누고 기존 승인·자동 배포 경계는 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>거점 게이트에서 F 안내를 보고 눌러도 열리지 않던 서로 다른 거리/중첩 판정을 하나의 공개 계약으로 통합했습니다. 경계·반경 변경·위치 변환·이탈 입력 회귀를 추가했습니다.</p></div>
        <p><a href="access/planner/#decisions-needed">판단 요청</a> · <a href="quality/e2e-play-session/#hub-gate-20260909">배포 재현·검증</a>. 거점 오류 수정과 탈출 F·양 플랫폼 10분 수락은 구분합니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>출격 준비 · 보유 응급키트 장착 무반응 수정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>준비실에서 보유 응급키트 버튼을 눌러도 장착되지 않던 배열 타입 오류를 수정했습니다. 장착·해제·준비실 재진입과 빈 재고 거부를 실제 입력 회귀에 추가했습니다.</p></div>
        <p>키트 회복량·가격·재고·런 유틸리티 정책은 유지합니다. 이번 수정 통과를 10분 플레이 완료로 계산하지 않습니다. <a href="quality/e2e-play-session/#preparation-medkit-20260909">재현·검증·잔여 경로</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>배포 분리 · 소스는 Git, 실행 파일은 Cloudflare</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>구현 · 1</h3><p>자체 러너에서 검증된 위키·Web·Windows 파일을 Cloudflare로 직접 전달합니다. GitHub에는 변경 이력과 검사·복구 기록을 남기고 필수 테스트는 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>GitHub 파일 보관 한도로 배포가 막히던 경로를 제거했습니다. Windows 다운로드는 공개 주소를 유지하면서 Web와 같은 커밋으로 전환하고, 직전 정상본을 보존합니다.</p></div>
        <p><a href="getting-started/source-control-and-cleanup/#source-only-delivery">전달 검증·복구·사용량 경계</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>도시형 맵 · 도로와 건물로 읽는 전장</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>개선 · 2</h3><p>넓은 대로·이면도로를 먼저 놓고 건물 정면과 보도·서비스 마당을 연결했습니다. 차선·주차선·외벽 패널·시설별 바닥·선반과 침상으로 공간을 구분합니다.</p><p>같은 지역의 필수 기준점은 유지하면서 보조 건물과 가구는 시드에 따라 달라집니다. 기획자·개발자 맵 설계실도 같은 도시 골격을 표시합니다.</p></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>도로 배치·가구 배치·표면 표현을 교체 가능한 모듈로 나눴습니다. 기존 전투·후퇴·금고·두 출구·확정 CSV 흐름은 유지합니다.</p></div>
        <p><a href="features/extraction-district/#urban-20260909">변경과 조정점</a> · <a href="quality/e2e-play-session/#urban-20260909">검증·성능·사람 플레이 잔여</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>바닥 렌더러 대체 승인 · 배포 플레이 검수 착수</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>수정 · 1</h3><p>첫 화면 지연을 줄인 청크 텍스처 방식을 지정 타일 레이어 대신 유지하도록 승인했습니다. 기존 개선을 되돌리지 않고 변경 이유와 검증 계약을 남겼습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>배포 중형 작전을 일반 입력으로 검수했습니다. 18처치·드랍 표시·02:45 사망 정산·거점 복귀를 확인했으며, 10분 완주와 탈출 검수는 계속 진행할 항목으로 구분했습니다.</p></div>
        <p><a href="access/login/?return=%2Fdesign%2Fmaster-gdd-alignment%2F%23day-close">팀 승인·계산 근거</a> · <a href="quality/e2e-play-session/#release-normal-20260909">QA 결과와 미완료 범위</a> · <a href="design/current-milestone-workline/#next-20260909">작업 순서</a></p>
      </div>
    </details>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-08</b><small>18 UPDATE BUNDLES · BUILD 11 · IMPROVE 21 · CHANGE 4 · FIX 16</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 18</small><b>오늘 마감 · 진행률 근거 정정과 내일 작업 순서</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-group"><h3>수정 · 1</h3><p>최신 노션 GDD62블록·트래커66행과 현행 코드를 다시 대조했습니다. 지정 기술과 실제 구현의 차이를 정정해 135/170 = 79.4%이며 출시 준비율은 아닙니다.</p></div>
        <p>원본·확정도 가중 계산과 상세 잔여는 <a href="access/login/?return=%2Fdesign%2Fmaster-gdd-alignment%2F%23day-close">팀 마감 근거</a>, 다음 착수 조건은 <a href="design/current-milestone-workline/#next-20260909">내일 실행 순서</a>에서 확인합니다. 오늘은 신규 게임 구현 없이 마무리합니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 17</small><b>성장 그래프 · 대상 하나의 단계별 변화</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 무기·캐릭터·방어구를 각각 하나씩 선택하여 레벨·강화 단계에 따른 성능, 증가량과 성장률을 확인합니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>실제 장착 계산으로 다른 조건을 고정한 성장 곡선을 제공합니다. 기획 목표값 시험과 개발자 현행 조회를 분리했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>서로 다른 아이템을 선으로 이어 성장처럼 보이던 목록 그래프를 원본 표로 교체했습니다. 성장 효과 없음과 단계별 하락도 그대로 표시합니다.</p></div>
        <p><a href="tools/balance-workbench/#growth">성장 계산 조건·원본 주의사항 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 16</small><b>무기 거리 피해 · 거리 선택에 따라 달라지는 화력</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 권총은 근거리, 소총은 중거리 유지, 펄스 소총은 중거리 강화 곡선으로 직격 피해가 달라집니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>발사 순간 곡선·사거리를 고정하고 관통 감쇠와 분리했습니다. 고유 고정 피해는 유지하며 현재 곡선은 임시 정책입니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>기획자 거리 DPS 수정·확정 파일 전달과 개발자 현행 전용 그래프, Weapon 시트 곡선 열, 신규 무기 작성 양식을 추가했습니다.</p></div>
        <p><a href="../features/weapon-distance/">곡선·작성 양식·적용 및 검증 범위 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 15</small><b>성능 실험실 · 장착 조합과 스킬별 그래프 연결</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 파츠·모듈·방어구·캐릭터를 선택하면 실제 장착 규칙으로 피해와 생존 성능을 비교합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>장비 강화·품질·소켓 비용, 스킬별 독립 AP 피해, HP·방어·이동 속도와 피격 생존 그래프를 추가했습니다. 실제 Godot 장착 계산 104조합과 대조했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>개발자 기본 그래프는 유효한 최신 기획 확정안을 우선하고, 없거나 원본이 바뀌면 현행 구현값과 사유를 표시합니다. 확정은 게임 자동 적용과 별개입니다.</p></div>
        <p><a href="../tools/dps-lab/">계산 범위·장착 방법·검수 근거 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 14</small><b>전투 연출 · 달리기, 발사, 전기 스킬을 더 선명하게</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 진행 방향 카메라와 짧은 줌아웃, 방향성 발사 섬광, 지속 중인 전기 효과를 강화했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>독립 발사 FX 모듈을 추가하고 동시 16개·0.12초 상한을 적용했습니다. 기존 CC0 에셋을 재사용합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>점멸 출발·도착, 자기장 고정 외곽, 가속 아크를 보강하고 자기장 내부 채움은 줄였습니다. 카메라는 정지 후 원복합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>스킬 취소·시간 변경과 이펙트 수명을 일치시켰습니다. 보스 전리품보다 먼저 보스를 제거할 수 있던 E2E 순서도 수정했습니다.</p></div>
        <p><a href="../features/hit-feedback/#speed-shot-fx">연출 변경·성능 예산·검수 범위 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>효과 툴킷 · Notion 명세에서 실제 구현 변수까지</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 스킬·무기·캐릭터·모듈 효과를 현행 코드 기준으로 지정하고 명세를 검증합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>35개 변수·92개 대상별 값과 Notion 작성 도구, 읽기 전용 변경 계획 검증기를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>공유 시트 EffectGuide·EffectSpec을 확장했습니다. 신규 행동은 구현 요청으로 구분하며 기존 게임 밸런스는 유지합니다.</p></div>
        <p><a href="../tools/effect-toolkit/">효과 작성·검증·구현 인계 방법 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 12</small><b>개발자 밸런스 · 확정 전에도 현재 수치 확인</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획 확정안이 없으면 빈 화면 대신 현재 CSV 수치와 그래프를 보여줍니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>19개 수치 목록의 변수·원본 표·버전·근거를 조회합니다. 일부 확정된 경우에도 현행 데이터는 별도로 확인하며 게임 수치는 바꾸지 않습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>확정 없음과 연결 오류를 구분하고 모바일 그래프 축 겹침을 줄였습니다. 4해상도 조회·재시도·권한 회귀를 검증합니다.</p></div>
        <p><a href="../tools/balance-workbench/">확정안과 현행 CSV를 구분하는 방법 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>지역 맵 · 기억할 기준점과 피스 설계실</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 같은 지역에서 큰길·필수 건물을 익히고, 주변 시설만 새롭게 탐색합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>기획자·개발자 맵 생성 미리보기와 피스 시험·Notion 초안을 제공합니다. 시험은 승인·게임 적용과 분리합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>지역별 필수 기준점, 고정 도로 골격, 랜덤 보조 시설로 변경했습니다. Facility는 12열·5개 피스로 확장했습니다.</p></div>
        <p><a href="../features/extraction-district/#regional-map">맵 규칙·임시 수치·검증 범위 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>전체 게임 UI · 기능 도구에서 선택과 회수의 화면으로</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 준비실·제작·도감·설정·시즌 화면을 게임 흐름으로 정리하고, 전투 시야를 가리지 않는 HUD는 유지했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>제작은 도면 선택→재료·비용 확인→제작 확정, 도감은 수집 대상·지역·진행 카드로 바뀝니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>준비·장비·설정의 실행 버튼과 그림문자, 현장 전리품 종류·품명, 게임 내 시즌 보관소로 정보 위계를 맞췄습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 4</h3><p>첫 열림의 창 넘침, 훈련 HUD가 다른 창 위에 남는 겹침, 선택 글자 대비, 모바일 안내와 메뉴 교차를 수정했습니다.</p></div>
        <p><a href="quality/game-ui-rematch/">전체 화면 판정·검증 범위 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>역할 작업실 · 필요한 작업을 바로 여는 블록 구성</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 긴 설명 대신 역할별 6개 작업 블록에서 시작하고 필요한 도구와 근거만 펼칩니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>기획자는 수치·요청·초안, 개발자는 판단·구조·검증에 바로 접근합니다. 모바일은 보조 설명을 줄이고 핵심 제목·키보드 포커스·초안 상태를 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>접힌 내용의 직접 링크와 문서 변환 중 폼 분리를 검사하고, 기존 확정 그래프·코드 지도·역할 권한을 회귀 검증합니다.</p></div>
        <p><a href="../quality/wiki-responsive-e2e/#role-workspace">작업실 사용·검증 계약 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>기획 수치 실험 · 확정 그래프 역할 분리</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획자는 수치와 그래프를 시험하고, 개발자는 기획 확정 시점의 그래프만 읽습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>DPS·시설·회수·19개 CSV 숫자 열 비교와 Notion 근거를 포함한 불변 기획 확정본 전달을 연결했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>임시 시험·기획 확정·오너 승인·게임 적용을 분리하고 역할·CSRF·원본 갱신·중복 제출을 검사합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>일일 업데이트 합계를 분류 이름으로 계산하고 최신 항목만 펼쳐 현행 문서 형식의 오판독을 수정했습니다.</p></div>
        <p><a href="../tools/balance-workbench/">수치 조정·확정 전달 사용법 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>익스트랙션 구역 · 후퇴와 귀환을 선택하는 공간</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 순환 도로·두 출입구로 우회하고, 일반 교전은 후퇴하며 금고만 선택 봉쇄합니다. 현재 공간 전체를 읽고 두 출구 중 직접 귀환할 길을 고릅니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>시드 구역·Facility 시트 4종·실시간→다음 작전 고정·CSV/Web/Windows 데이터 경로를 연결했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>공간 공개·지형만 기억·문턱 완화, 일반 무리 후퇴/생존, 금고 F 선택과 1~5상자를 구분합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>시간/전체 방 대기 대신 두 출구 현장 방어. 워프는 안전 단말 사이로 제한하며 임시 수치와 기획 사유를 별도 안내합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>워프 카메라·단말 표시·확보 알림·중복 정산을 보강했습니다. 인접 전리품이 ESC 보류 직후 비교창을 다시 열던 문제도 수정했습니다.</p></div>
        <p><a href="../features/extraction-district/">현재 규칙·모듈 계약 →</a> · <a href="../access/planner/#extraction-rationale">기획 사유 →</a> · <a href="../quality/e2e-play-session/#extraction-district">회귀 근거·인간 플레이 잔여 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>인벤토리 · 아이템 실루엣과 장착 카드</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 큰 단색 텍스트 블록을 아이템 도형 카드로 바꾸고, 장착 장비·가방·선택 미리보기를 분리했습니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>실제 장착 슬롯만 표시하고 작은 화면은 가방을 먼저 배치합니다. 작은 아이템은 아이콘과 상세 보기로 구분하며 이동·R 회전·저장 확인은 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>탭 전환 시 선택 정보와 가방 표시가 같은 데이터를 공유해 표시가 비워질 수 있던 문제를 수정했습니다.</p></div>
        <p><a href="../features/grid-inventory/#item-presentation">화면 구성·모듈 계약 →</a> · <a href="../quality/e2e-play-session/#inventory-presentation">4해상도·입력·저장 회귀 검증 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>기획자 DPS 실험실 · 피해와 처치 시간 비교</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 무기·스킬 시험값과 적 체력·방어막을 바꾸면 원본 대비 피해 그래프와 처치 시간이 함께 갱신됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>무기 5종·스킬 4종 원본, 점사·치명·지속 피해·AP·충전 계산기를 기획자/개발자 인증 문서로 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>목표 처치 시간, 적 접촉 DPS, 모바일 입력·그래프 수치 표를 제공하고 미확정 대체값·이론 상한·실제 플레이 검수 범위를 구분합니다.</p></div>
        <p><a href="../tools/dps-lab/">DPS 실험실·계산 범위·검증 →</a> · 시험값은 원본 시트와 게임 저장을 변경하지 않습니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>로그라이크 시야 · 현재/탐색/미탐색 분리</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 방 전체를 켜는 대신 주변 360도 시야를 사용하고, 지나온 곳은 어두운 지형으로 기억합니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>방·통로 동일 시야, 벽·문 차폐, 전체 미니맵 유지. 계산·월드 연결·기억 렌더를 분리했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>탐색 기억은 불투명한 간략 지형만 표시해 현재 안 보이는 적·전리품을 숨깁니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>막힌 대각선·얇은 문 뒤 시야 누출을 차단하고 문 개폐·워프·세 규모 생성 맵·GPU 픽셀 검사를 추가했습니다.</p></div>
        <p><a href="features/fog-of-war/">시야 규칙·모듈 계약 →</a> · <a href="quality/e2e-play-session/#roguelike-fog">렌더 검증·수락 잔여 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>보급품 선택 카드 · 회수/분실 정산 화면</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 보급소는 품질과 가격을 보고 선택하고, 작전 종료는 회수/분실을 먼저 확인한 뒤 상세 기록을 펼칩니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>상점 품질 카드·잔액 비교, 성공/실패 결과 카드·고정 복귀 버튼으로 정보 위계를 나눴습니다. 청록 테마와 키보드 입력은 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>실물 가방 지급을 창고로 안내하던 오인을 수정하고, 창고 폴백은 품질 효과 미적용으로 구분했습니다.</p></div>
        <p><a href="quality/player-perception-audit/#game-ui-audit">전체 UI 검토·다음 순서 →</a> · <a href="quality/e2e-play-session/#player-facing-ui">4해상도·실제 입력 검증 →</a> · 로비 준비·도감·제작·시즌 화면은 후속 대상입니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>작전 첫 화면 끊김 · 바닥 렌더 준비 축소</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 출격 직후 바닥 타일을 한꺼번에 준비하며 멈추던 구간을 줄였습니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>맵 바닥을 셀당1픽셀 청크 텍스처로 교체. 같은PC 각3회 첫 렌더 중앙값: 중형197→23ms·대형304→27ms.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>첫 화면의 대량 타일 갱신·업로드 제거. 바닥 무늬·빈 영역·벽/충돌·안개는 유지하고 실제 렌더 픽셀 회귀를 추가했습니다.</p></div>
        <p><a href="performance/minimum-requirements/#first-frame-20260908">측정 조건·원시 근거 →</a> · <a href="quality/e2e-play-session/#first-frame-render">QA 범위 →</a> · CPU 전체 로딩·콜드 캐시·10분 일반 플레이는 별도 검수.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>소모품 전용 HP · 지참 키트 사용</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · HP는 지참 키트로만 회복합니다. 체력 옆 KIT 버튼에서 남은 수량을 보고 사용합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>회복 원인 정책과 실제 키트 사용·수량 차감을 연결했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>최대 HP·사망·수량 부족은 미소모, 증강의 HP 회복 미적용을 안내합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>오너 승인으로 자연·드랍·레벨업·버프 HP 회복을 중단합니다. AP는 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>부상 중 최대 HP 장비 교체 회복을 차단하고, 키트를 지참해도 브리핑이 소모품 비어 있음으로 표시하던 오인을 수정했습니다.</p></div>
        <p><a href="features/health-recovery/">사용법 →</a> · <a href="design/master-gdd-alignment/#health-20260908">노션 대조 80.3%·부분 검수 잔여 →</a> · 양 플랫폼10분 일반 플레이·첫 GPU 프레임 수락은 미완료.</p>
      </div>
    </details>
  </div>
</details>

<details class="sfh-day" open>
  <summary><span class="sfh-day-title"><b>2026-09-07</b><i class="sfh-latest">최신</i><small>16 UPDATE BUNDLES · BUILD 19 · IMPROVE 34 · CHANGE 24 · FIX 30</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>16</b><small>UPDATE BUNDLES</small></span><span><b>19</b><small>BUILD</small></span><span><b>34</b><small>IMPROVE</small></span><span><b>24</b><small>CHANGE</small></span><span><b>30</b><small>FIX</small></span></div>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 16</small><b>오늘 마감 · 노션 대비 코드 대응도 78.5%</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 홈에서 로그인 후 마감 근거로 이동하고, 개발 현황에서 기획 대응도와 잔여 범위를 확인할 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>개발 현황의 현재 빌드 상태 위에서 78.5%를 확인합니다. 공개 홈은 플레이 소개를 유지하며 상세 계산은 팀 로그인 뒤에 제공합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>최신 공개 노션 재수집과 배포 코드 대조를 마쳤습니다. 오늘의 파츠·모듈 UI/소켓은 별도 추가 구현 근거로 갱신하고 진행률에 중복 가산하지 않습니다.</p></div>
        <p><a href="design/master-gdd-alignment/#day-close">마감·계산 근거 →</a> · 2026-09-07 작업 종료. 새 게임 규칙·노션 원문·밸런스 목록 변경 없음.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 15</small><b>무기·방어구·캐릭터 모듈 카드 · 슬롯 소켓</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · E에서 세 대상의 모듈을 카드로 편집하고, 최대 레벨 슬롯에 소켓을 부여해 비용을 줄입니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>캐릭터 공용 모듈과 슬롯별 타입 소켓을 추가했습니다. 일치 비용은 강화 후 기본 비용의 절반을 올림합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>대상·적용 수치 / 장착·보유 카드 / 코스트·설정으로 나누고 검색·정렬·좁은 화면 세로 배치를 제공합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>E와 I 모듈 설정을 같은 초안 편집 화면으로 연결했습니다. 최대 레벨 전 잠금·이탈 저장 확인·기존 세이브를 보존합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>실제 강화 비용과 슬롯 할인으로 용량을 판정합니다. 캐릭터 상태가 없던 훈련 원본을 복원할 때 불필요한 상태 생성도 차단했습니다.</p></div>
        <p><a href="features/equipment-customization/#module-sockets">사용 방법·원작과 차이 →</a> · <a href="quality/e2e-play-session/#module-sockets">입력·저장 검증 →</a> · 캐릭터 해금40은 임시 정책. 촉매 소모·레벨 초기화·새 Sheet 목록 추가 없음.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 14</small><b>두 무기 카드 · 그림 주변 파츠 슬롯</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · I 무기 탭에서 메인·보조를 위아래로 보고, 무기 주변 슬롯을 눌러 파츠를 장착합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>실제 무기 소켓에 연결된 카드형 파츠 UI와 보유 호환 파츠 선택을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>빈 슬롯·장착·선택 상태를 아이콘과 테두리로 구분하고, 클릭/Enter 선택·4폭 배치·저장 보호를 검사합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>파츠 교체는 분리 초안에서 이전 파츠/강화 상태를 가방으로 반환하며, 실패 시 복구합니다. 저장 확인과 U/E 고급 기능은 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>배포 전 패키지 검사에서 발견한 밸런스 CSV의 번역 리소스 오인식을 수정했습니다. CSV 18종 원본 보존과 패키지 거점·작전 부팅을 검사합니다.</p></div>
        <p><a href="../features/grid-inventory/#weapon-attachment-rack">사용 방법 →</a> · <a href="../quality/e2e-play-session/#weapon-attachment-rack">입력·저장 검증 →</a> · 참고 이미지의 에셋을 복사하지 않은 SFH 코드 도식. 새 파츠 목록·밸런스 변경 없음.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>FUN QA · 출격 정보와 탈출 경계</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 규모 선택은 잘리지 않는 요약과 상세로 나뉘고, 탈출 원과 F 안내가 실제 작동 범위에 맞습니다.</strong></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>마우스를 올리지 않아도 선택 규모의 방·적 수를 읽을 수 있습니다. 실제 충돌/F·첫 브리핑·5폭 글자 너비를 필수 검사로 추가했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>최신 기획 재대조 후 판단 없는 신규 미구현은 없음으로 분리했습니다. 오너 판단이 필요한 6건과 코드 대응도78.5%는 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>몸만 구역에 걸친 상태의 잘못된 F 시작 안내와 규모 카드 말줄임을 수정했습니다. 선택 상세 추가 시 초기 높이 회귀도 함께 차단했습니다.</p></div>
        <p><a href="../quality/player-perception-audit/#fun-qa-affordance">FUN QA 결과 →</a> · <a href="../architecture/module-audit/#fun-qa-affordance">모듈 경계 →</a> · 일반 Web 입력으로 14처치·문 개방·레벨2·룬 장착·31크레딧 회수 확인. 양 플랫폼10분 완주·사람 재미 합격은 별도 수락입니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 12</small><b>손상품 가격 · 타일/타겟 어댑터 · 체감 QA</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 손상품은 실제로 저렴해지고, 바닥과 적 탐색은 독립 엔진 어댑터를 사용합니다. 무기 정보는 전투 중앙을 가리지 않습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>실제 바닥 TileMapLayer와 무기/스킬 공통 후보 Area2D를 연결하고 기존 충돌·길찾기·타겟 우선순위를 유지했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>첫 생성·사거리 변경·삭제·화면 중앙 가림을 별도 회귀 계약으로 추가했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>3행 추가 검증으로 코드 대응도 78.5%(133.5/170). 배포판 일반 플레이·첫 진입 지연은 별도 검수로 남깁니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 6</h3><p>손상품 가격·중앙 정보 가림에 더해 릴리스 초기화 실패, 저프레임 카메라 이탈로 검게 보이는 전장, 작전 중 훈련 문구, Windows 거점 HUD의 과도한 빈 높이를 수정했습니다.</p></div>
        <p><a href="quality/player-perception-audit/">플레이어 인식 QA →</a> · <a href="architecture/module-audit/#partial-adapters">모듈 경계 →</a> · 코드 cd25dfe. Web 일반 입력 전투·사망·거점 복귀 및 Windows 메뉴 검수. 10분 일반 플레이와 사람 재미 수락은 별도입니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>기획 기준 현행화 · 코드 대조와 다음 작업 편성</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 오래된 기획 백업 대신 최신 원본과 작업 목록을 연결하고, 이미 구현된 것과 새 요구의 차이를 분리했습니다. 게임 규칙은 변경하지 않았습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>기획 작업 스냅샷과 코드·검사 근거 대조표를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>기획 상태와 구현 상태를 분리하고, 충돌 판단과 의존성별 작업 순서를 개발자 작업실에 연결했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>진행도 기준과 최신 원본 링크를 현행화했습니다. 상세 산정·수락 조건은 팀 로그인 후 확인합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>백업본을 최신 원본으로 읽던 연결과 상위 페이지 수정을 본문 변경으로 오판하던 수집 범위를 수정했습니다. 타게팅 등 게임 차이는 후속 작업으로 등록했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>타게팅 중심 보존 · 독립 구현 시작</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 지점형 스킬에 전달되던 군집 중심이 적 좌표로 바뀌는 오류를 수정했습니다. 현재 자기장·점멸의 사용 방식은 유지합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>스킬 효과 반경과 최종 배율을 타게팅에 전달하는 선택형 계약을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>동률 결과를 고정하고 기존 정책 호환 경로를 보존했으며, 별도 기획 판단 없이 이어갈 작업을 분리했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>부분 구현 상태와 잔여 범위를 명시하고 실제 스킬 실행 회귀를 추가했습니다. 새 밸런스 목록과 확정 수치는 추가하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>중심점 덮어쓰기와 사거리 밖·삭제·중복 후보가 대표 대상에 섞이는 문제를 차단했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>범위 공격 · 최대 피격 위치와 계산 최적화</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 적 한 마리 주변만 보던 범위 타게팅을 개선해 적 사이에 공격을 놓을 수 있고, 중심 이동으로 가장자리 적을 놓치는 현상을 방지합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>원형 범위의 최대 포함 위치를 찾는 순수 좌표 계산기를 타게팅 정책에 연결했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>피격 수를 유지하는 경우에만 평균 중심을 사용하고, 숫자 배열 정렬로 계산 시간과 임시 할당을 줄였습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>독립 계산 대조와 실제 효과 적중·72명 성능을 회귀 검사에 추가했습니다. 기존 반경·스킬·저장·밸런스 목록은 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>두 적 사이의 가능한 타격을 놓치는 경우와, 한쪽에 적이 몰리면 평균 중심이 반대편 적을 제외하는 경우를 수정했습니다.</p></div>
        <p><a href="features/smart-targeting/#n26-03b">타게팅 계약·검증 근거 →</a> · 다음 작업은 훈련 세팅·복원입니다. 신규 기본 스킬 추가나 사람 재미 수락 완료를 뜻하지 않습니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>훈련 무료 세팅 · 종료 원복과 저장 보호</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 훈련에서 스킬과 공용 룬을 바꿔 비교하고 종료 버튼으로 원래 장비에 돌아옵니다. 시험 세팅이 다음 작전이나 자동 저장에 섞이지 않도록 보완했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>룬·코어·유물 시험 선택과 종료·원복 버튼을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>복원 대상에 스킬·자원·공용 소켓을 포함하고, 참여자 등록 방식으로 확장했습니다. 시험 스킬을 교체해도 해당 슬롯의 사용자 지정 키를 유지합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>3개 화면 크기의 버튼 배치와 복원·실패 재시도·상점 이동을 자동 검사에 추가했습니다. 새 밸런스 목록과 과금 변경은 없습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>반복 입장 시 훈련 목록이 사라지는 참조 공유, 시험 장비 자동 저장, 창 이탈 취소 전에 훈련부터 원복하던 순서를 수정했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>훈련 잔여 오류 수정 · 선택 기능과 출격 회귀</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 일부 기능을 끈 빌드에서도 훈련과 출격을 이어가며, 사용할 수 없는 교체 버튼과 같은 스킬 재선택에 따른 쿨타임 초기화를 방지합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>선택 기능을 제거한 5개 구성의 훈련→종료→중형 출격 자동 검사를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>시험 중 원본 복원 제공자 교체를 막고, 중·대형 성능 검사를 4개 조건과 실제 공격 입력으로 확장했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>성공 문구뿐 아니라 런타임 오류도 판정합니다. CPU 단기 검사와 실제 화면을 켠 10분 플레이의 검증 범위를 분리했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 4</h3><p>선택 기능 제거 시 배열 타입 오류, 없는 스킬 교체 버튼, 동일 스킬 재선택 자원 초기화, 키 어댑터 재구성 중복 연결을 수정했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>실시간 렌더링 검수 · 자동 검사와 실제 플레이 구분</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 화면을 실제로 그리는 상태에서 이동·교전·안개·프레임·메모리를 확인하는 장시간 검사 도구를 추가했습니다. 자동 검사를 사람의 플레이 수락으로 표시하지 않습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>별도 저장소에서 실행하는 렌더링 세션 검사와 결과·로그·화면 기록을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>중·대형 각각 실제 600초 렌더링 검사 통과(평균 59.91/59.88 FPS·종료 잔류 Node 0). 검사기 정체를 실패로 처리하며, 순간 프레임 간격과 자동 입력 조건은 <a href="../performance/minimum-requirements/#rendered-soak">상세 계측 기록</a>에서 구분합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>Web 화면 확인, Windows 파일 검증, 소스 렌더링 계측, 사람 수락의 근거를 분리했습니다. 남은 플랫폼 검수는 별도로 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>게임 규칙과 수치는 유지합니다. 이번 경로 보정은 자동 검사기에만 적용되며 과금·자동 실행 설정 변경은 없습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>타격·속도감 강화 · 프레임 반복 작업 축소</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 단발 충격과 처치 표시를 구분하고 대시 표현을 강화했습니다. 화면을 불필요하게 다시 그리는 작업을 줄였으며, 첫 출격 순간 지연은 별도 검수 대상으로 남깁니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>지연 시점·교전 상태·CPU 지표와 화면 저장 비용을 기록하는 검사를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>안개 임시 할당 감소, 효과 대기 중 갱신 축소, 방향성 타격·처치 링, 대시 카메라·속도선 표현을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>피해량·이동 속도·대시 쿨타임은 유지하며, 반복 작업 감소와 실제 프레임 지연 해결 여부를 구분합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>점멸·워프 뒤 잔상이 방을 가로질러 이어지는 표시 오류를 방지했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>기획·위키 재대조 · 구현 범위와 잔여 작업 구분</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 원문 요구와 실제 구현을 다시 대조해 완료 근거, 부분·미구현, 원문 외 기존 기능을 나눴습니다. 지난 작업을 다시 해야 하는 것처럼 보이던 안내도 바로잡았습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>게임 규칙·아이템·밸런스 변경 없이 문서와 검증 도구를 최신화했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>팀 작업실에서 기획 요구의 남은 범위와 별도 구현 목록을 구분하고, 진행도 계산에 추가 기능이 섞이지 않도록 검사를 강화했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>공개 원문 재수집 시각과 현행 코드 근거를 갱신하고, 자동 검사와 일반 플레이 수락을 분리했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>오래된 다음 작업·저장 지원 안내의 문서 불일치를 바로잡았습니다. 게임 버그 수정 완료를 뜻하지 않습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>개발자 작업 공간 · 개요에서 근거로 좁히는 운영 화면</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 긴 대시보드를 한 번에 읽는 대신 현재 작업을 먼저 보고, 필요한 객체·관계·검증 근거만 펼쳐 확인합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>작업 개요를 기본 화면으로 추가하고 원본에 기록된 다음 행동과 선행 조건을 연결했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>객체 목록을 6개씩 탐색하고, 선택한 정보는 별도 검사 패널에서 읽으며, 코드 지도와 긴 안내는 필요할 때 펼칩니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>등록 객체 집계와 게임 진행률을 구분합니다. 인증·원본 데이터·게임 규칙은 변경하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>전체 객체에 도달하지 못하던 목록 제한과 선택·탭 전환 시 검색 조건이 초기화되던 문제를 수정했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>위키 문서 동선 · 큰 주제에서 세부 기능으로</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 홈에서 로그인 후 종합 문서로 들어가고, 주제 설명을 읽으며 세부 기능으로 내려가도록 정리했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>내부 주제 문서에 검토 원본과 연결된 구현 단계·남은 경계 안내를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>하위 문서마다 설명을 표시하고 공개 홈에서 문서 읽기와 게임 플레이의 진입을 구분했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>문서 정리와 게임 기능 완료를 분리합니다. 부분 구현은 정책 결정·코드·검증이 끝나기 전까지 그대로 표시합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>로그인된 사용자가 문서 링크를 열면 요청 문서 대신 역할 작업실로 이동하던 경로를 수정했습니다.</p></div>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>AP 재생 · 대상별 룬과 보유 훈련</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · AP는 잠시 쉬면 회복되고, 룬 효과는 장착한 대상에만 적용됩니다. 해제한 자산은 가방에서 다시 쓸 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>1초 미사용 후 10 AP/s, 무기·스킬별 효과 귀속, 해제 가방 반환·재장착을 임시 정책으로 연결했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>훈련은 보유품만 무료로 시험하고 종료 시 원복합니다. 모든 CI를 수동 기동 자체 러너로 전환해 hosted 비용 폴백을 없앴습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>회복·귀속·입출금의 교체 경계를 분리하고 승인 임시/기획 확정을 구분했습니다. 66행 중 3행을 검증 근거로 갱신해 코드 대응도 75.9%, 부분 잔여 4행입니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>가방 부족·편집 취소 때 자산/효과 손실을 차단하고 컨테이너 파일 소유권으로 다음 CI가 막히던 문제를 수정했습니다.</p></div>
        <p>원본·계산: 최신 GDD/트래커 해시 동일, 코드 dfe0f1f, 129/170. 정책 계약·전체 플레이 회귀 통과이며 사람 재미/모든 기기 수락과는 별도입니다.</p>
      </div>
    </details>
  </div>
</details>

<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-06</b><small>4 UPDATE BUNDLES · BUILD 6 · IMPROVE 11 · CHANGE 9 · FIX 6</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>4</b><small>UPDATE BUNDLES</small></span><span><b>6</b><small>BUILD</small></span><span><b>11</b><small>IMPROVE</small></span><span><b>9</b><small>CHANGE</small></span><span><b>6</b><small>FIX</small></span></div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>FUN QA · 조작 피드백과 진입 가독성</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기능은 작동하지만 잘못 보이거나 반응이 없다고 느껴지던 입력·이동·거점·작전 화면을 플레이어 인식 계약에 맞췄습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>대상이 없을 때 자동 타게팅 대기 문구와 주변 레티클을 표시하고, 거점 시작점부터 작전 게이트 방향·거리를 계속 안내하며, 온톨로지 입력 해시를 운영체제와 무관하게 고정합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 6</h3><p>모바일 스킬을 번호+상태로 압축하고, 이동 리드·스트레치·속도선 지속을 강화하며, 작전 규모 카드를 세 줄로 정돈하고 테스트·시즌 상세는 기본 접음으로 분리했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>대시 HUD가 KeyMapping의 현재 바인딩을 즉시 표시하고, 로비 세팅 단말과 실제 작전 게이트의 이름·종료 문구·목적을 구분합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 4</h3><p>기본 Space와 SHIFT 표기 불일치, 좁은 모바일 버튼의 한글 침범, 대상 없는 좌클릭의 무반응 오인, Windows와 Linux 간 줄바꿈 차이로 발생한 CI 온톨로지 오판정을 자동 회귀로 고정했습니다.</p></div>
        <p>게임 스모크, 모바일 5해상도×3배율, 실제 입력 E2E 23상태·31인식·15인과 흐름을 통과했습니다. 신규 목록 데이터와 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="quality/player-perception-audit/#fun-qa-2026-09-06">FUN QA 결과 →</a> · <a href="architecture/module-audit/#fun-qa-modularity-2026-09-06">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>배포 효율 · 필요한 검사와 검증된 산출물 재사용</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 문서 수정 때 게임을 다시 배포하지 않고, 게임 변경은 동일 소스와 파일 해시가 검증된 Web 산출물을 재사용합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>변경 파일 분류와 소스 트리·파일 SHA-256 기반 재사용 검증을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>오래된 PR 실행 취소, 문서 전용 게임 빌드 생략, 위키 데이터 사전 검증을 적용했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>Windows 패키징은 main에서 실행하고, 백업·산출물 정리를 배포 작업에 통합했습니다. 전용 WSL2 Linux 러너와 온라인 상태 자동 확인을 연결했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>선행 검사 실패가 생략된 성공으로 보이지 않도록 최종 build 판정을 유지합니다.</p></div>
        <p class="sfh-intent"><b>검증</b><span>게임·E2E·위키·다운로드 검증을 유지하면서 정상 PR+배포의 hosted 사용 분 추정이 24분에서 6분으로 줄었습니다. 과금 설정은 변경하지 않았습니다.</span></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>재미 검수 · 한 판의 다섯 순간 제안</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 첫 교전·장비·강화·탈출·재도전의 개선 제안과 인간 플레이 검수 계획을 문서화했습니다. 게임 변경은 아직 적용하지 않았습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>제안서 작성만 진행했습니다. 게임 기능 구현은 포함하지 않습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>기능 검사와 재미 판단을 분리하고 순간별 목표·관찰 기준·승인 순서를 정리했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>역할 작업실·검색·문서 노드맵에서 제안서를 찾도록 연결했습니다. 수치·보상 변경은 별도 승인 대상입니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>현재 게임과 확정 CSV를 유지합니다.</p></div>
        <p><a href="quality/five-moment-fun-proposal/">제안서 · 오너 판단표 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 4</small><b>개발 환경 · WSL 수동 켜기와 끄기</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 개발하지 않을 때 WSL이 계속 메모리를 점유하던 자동 실행을 없애고, 필요한 때만 켜는 방식으로 변경했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>러너 켜기·끄기·상태 조회 명령과 사용자 폴더 바로가기를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>빌드 중에는 종료를 거부하고, 상태 조회는 WSL을 깨우지 않습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>재설치·부팅·로그인 때 자동 시작하지 않도록 수동 작업만 등록합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>WSL을 종료해도 매분 다시 켜지던 유지 작업의 자동 트리거를 제거했습니다. 과금 설정과 게임 규칙은 변경하지 않습니다.</p></div>
      </div>
    </details>
  </div>
</details>
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-05</b><small>7 UPDATE BUNDLES · BUILD 15 · IMPROVE 26 · CHANGE 33 · FIX 6</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>7</b><small>UPDATE BUNDLES</small></span><span><b>15</b><small>BUILD</small></span><span><b>26</b><small>IMPROVE</small></span><span><b>33</b><small>CHANGE</small></span><span><b>6</b><small>FIX</small></span></div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>단일 작업 폴더 · Git 커밋 기반 복구</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 바탕화면 폴더 복사를 백업으로 쓰지 않고, 원격 커밋·PR·검증된 main을 유일한 복구 기준으로 고정했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p><code>audit-worktrees.ps1</code>가 보존·제거 후보를 판정하고, 게임 스모크가 새 clone의 import·전역 클래스 캐시를 먼저 구성합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>기본 <code>Newgame</code> 하나만 상시 유지하고 임시 폴더는 PR 병합·배포 뒤 제거하며, 불확실한 변경은 WIP 원격 커밋으로 먼저 보존하고 GDScript UID는 소스와 함께 추적합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>직접·squash 병합 판정, 4단계 복구, worktree 제거, 92개 UID 추적, 실행·위키 안내와 검색·노드맵을 같은 계약으로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>오래된 완료 worktree 혼선, Windows PowerShell의 UTF-8 한글 검사 파싱, 신규 clone의 클래스 캐시·폰트 import 부재로 첫 스모크가 실패하는 문제를 차단했습니다.</p></div>
        <p>완료 worktree 10개를 Git 등록에서 제거했습니다. 기본 폴더의 Godot 에디터 재저장 상태는 <code>codex/backup-desktop-pre-cleanup-20260905</code> 커밋 <code>5e57fde</code>로 원격 보존한 뒤 최신 <code>main</code>으로 정리했습니다. 게임 코드·Sheet/CSV·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="getting-started/source-control-and-cleanup/">형상 관리·복구 운영안 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>가방 아이템 R 회전 · 방향 저장</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · I 가방에서 아이템을 한 번 선택하고 R을 누르면 3×2↔2×3처럼 점유 방향을 바꾸고, 저장한 방향이 다음 실행에도 유지됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p><code>GridInventory</code> 인스턴스별 회전 상태와 <code>GridInventoryWindow</code> 선택 회전 입력·버튼을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>현재 점유 크기·기본/회전 방향을 표시하고, K에서 재설정한 현장 장착 키가 가방 안에서는 회전으로 동작하도록 문맥을 분리했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>현재 방향 기준 이동·충돌·경계와 저장 검증, 구 저장 기본 방향 호환, 실제 클릭→R→저장·재실행 E2E를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>기존 결함 수정이 아니라 가방 편집 기능 확장입니다.</p></div>
        <p>회전할 공간이 없으면 원래 위치와 방향을 보존합니다. 새 아이템·밸런스 목록이 없어 Google Sheet·확정 CSV·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/grid-inventory/">플레이 규칙 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a> · <a href="quality/e2e-play-session/#desktop-save-e2e">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>프로젝트 오너 판단 온톨로지 · 개발자 콘솔</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획자와 개발자는 근거 제공자로 분리하고, 사용자인 프로젝트 오너가 범위·우선순위·수락·출시를 최종 판단하는 읽기 전용 운영 계층을 개발자 화면 최상단에 추가했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p><code>owner-decision-registry.json</code>, 코드·문서 결합 생성기, 상태·유형·검색과 선택 상세를 제공하는 오너 판단 콘솔을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>결정·위험·작업·원칙 객체를 판단 필요·차단·준비·검증·보류 순서로 표시하고, 직접 관계만 탐색하며 모바일·키보드 접근성을 유지합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>Notion=기획, Sheet=후보, CSV=확정 데이터, Git/E2E=구현 근거, 위키=읽기 전용 뷰로 원본 경계를 고정했습니다. 생성·CI 검사가 중복 ID·소유권 누락·깨진 관계·없는 문서를 차단합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>기획자를 최종 판단자로 오인하던 협업 표현을 바로잡고, 하위 문서에서 게임 배포 주소 레지스트리를 현재 경로 아래로 잘못 요청하던 404를 제거했습니다.</p></div>
        <p><a href="architecture/project-ontology/">판단 온톨로지 계약 →</a> · <a href="access/developer/">개발자 판단 화면 →</a></p>
        <p>게임 코드·밸런스 Sheet/CSV·과금·서버 설정은 변경하지 않았습니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>권한별 위키 재배치 · 운영 온톨로지 폐루프</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 개발자는 객체·관계·행동·원본·검증을 한 콘솔에서 추적하고, 기획자는 게임 대상을 기획 가능한 형식으로 작성하며, 공개 사용자는 플레이 가치와 테스트 진입만 보도록 역할별 화면을 전면 재배치했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>객체 유형·인터페이스·원본 시스템 6개·행동 계약 5개·생명 주기와 객체 탐색·관계 계보·행동 관측 화면을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>개발자 화면은 판단 폐루프를, 기획자 화면은 객체→관계·행동→수락 기준 작성법을, 공개 홈은 실제 플레이 특징 6개를 먼저 보여줍니다.</p></div>
        <div class="sfh-group"><h3>수정 · 7</h3><p>프로젝트 오너의 최종 판단권, 자동 행동 금지, Notion·Sheet·CSV·Git·E2E·CI 원본 계보, 공개/기획/개발 접근 경계를 생성·빌드·Worker E2E 계약으로 고정했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>기능 결함 수정이 아니라 정보 구조와 운영 계약 확장입니다.</p></div>
        <p><a href="architecture/project-ontology/">운영 온톨로지 계약 →</a> · <a href="access/developer/">개발자 운영 콘솔 →</a> · <a href="access/planner/">기획 작성 가이드 →</a></p>
        <p>게임 코드·밸런스 Sheet/CSV·과금·서버 설정은 변경하지 않았습니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>문서·마일스톤 자동 계보 · 원본 최신성 경고</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 개발자 콘솔이 수동으로 적은 일부 객체만 보여주지 않고, 전체 문서와 현행 작업선을 자동 연결하며 외부 원본을 언제 다시 확인해야 하는지 표시합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>문서 묶음 27개·문서 소속 관계, 마일스톤 작업 28개, Notion 스냅샷과 Google Sheet 최신성 상태를 생성합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>95개 문서가 모두 관계망에 포함되고, 행동·관측 화면에서 고립 문서·자동 작업·원본 확인 경고와 직접 진입 주소를 확인합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>스키마 v3와 CI가 고립 문서, 마일스톤 오너·수락·E2E 계보, Notion revision·관측 시각, Sheet 미검증 상태를 강제합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>기존 게임 결함 수정이 아니라 운영 정보 누락 방지와 자동화 범위 확장입니다.</p></div>
        <p><a href="architecture/project-ontology/">자동 계보 계약 →</a> · <a href="access/developer/?view=operations">원본 건강도 →</a> · <a href="quality/wiki-responsive-e2e/">E2E 기준 →</a></p>
        <p>새 게임 목록이 없어 Google Sheet/확정 CSV를 확장하지 않았고 게임 코드·과금 모델·배포 주소는 변경하지 않았습니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>Actions artifact Node 24 선제 전환</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · GitHub의 Node 20 사용 중단 경고가 실제 장애로 바뀌기 전에 Web·Windows·위키 산출물 전달 액션을 공식 Node 24 릴리스로 교체했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>배포 경계 검사에 승인된 Node 24 artifact 액션 SHA와 적용 개수, 구 SHA 재유입 차단 계약을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p><code>upload-artifact</code> v7.0.1과 <code>download-artifact</code> v8.0.1을 정식 릴리스 전체 SHA로 고정했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>Web·Windows·위키 업로드 3곳과 Cloudflare 배포 다운로드 3곳을 같은 Node 24 공급망 기준으로 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>실행 결함 수정이 아니라 예정된 런타임 중단 위험의 선제 제거입니다.</p></div>
        <p><a href="getting-started/source-control-and-cleanup/#actions-2026-09-05">Actions 공급망 기준 →</a> · <a href="architecture/module-audit/#actions-artifact-node24-2026-09-05">감사 결과 →</a></p>
        <p>산출물 내용·보존 기간·R2 전환·게임 코드·Sheet/CSV·과금 모델은 변경하지 않았습니다.</p>
      </div>
    </details>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 7</small><b>QA 1차 · 전체 다운로드의 잘못된 206 응답 수정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · Range를 요청하지 않은 브라우저 게임과 Windows 다운로드가 부분 응답처럼 보이던 배포 경계를 정상적인 전체 200 응답으로 바로잡았습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>실제 R2가 전체 객체에도 범위 메타데이터를 주는 상황을 재현하는 Worker 계약을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>전체 응답 길이·범위 지원을 명시하고, main 배포 E2E가 홈·ZIP 200과 실제 Range 206을 구분해 검사합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>부분 응답 판정을 객체 메타데이터에서 요청 헤더로 옮기고 Range HEAD도 동일한 R2 읽기 계약을 사용하도록 정리했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>전체 게임 HTML·Windows ZIP에 `206`과 전체 범위 `Content-Range`가 붙던 프로토콜 오판을 제거했습니다.</p></div>
        <p><a href="quality/e2e-play-session/#deployment-full-response-qa-2026-09-05">QA 결과 →</a> · <a href="architecture/module-audit/#r2-full-partial-response-2026-09-05">경계 감사 →</a></p>
        <p>게임 Scene·저장·밸런스·Sheet/CSV·R2 데이터·과금 모델은 변경하지 않았습니다.</p>
      </div>
    </details>
  </div>
</details>
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-04</b><small>17 UPDATE BUNDLES · BUILD 37 · IMPROVE 57 · CHANGE 75 · FIX 36</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>17</b><small>UPDATE BUNDLES</small></span><span><b>37</b><small>BUILD</small></span><span><b>57</b><small>IMPROVE</small></span><span><b>75</b><small>CHANGE</small></span><span><b>36</b><small>FIX</small></span></div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>잔여 작업 재대조 · P7-01B 다음 순서 유지</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 공개 Notion과 최신 main·배포 상태를 다시 확인해 완료, 다음 구현, 별도 승인 대기를 구분했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>이번 묶음은 상태 감사이며 새 기능을 완료로 계산하지 않습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 0</h3><p>플레이어 UI·밸런스·데이터 스키마는 변경하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>Notion v1005·77블록·해시 614a0b8ddee4와 체크 0/6을 재확인했습니다. 저장소 구현과 플레이어 인식 E2E를 기준으로 94% 산식 및 P7-01B→P7-02~04→P8→P9→P10 순서를 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>실행 코드 변경은 없습니다.</p></div>
        <p>P6-01~04는 로컬 프로토타입 완료입니다. 온라인 계정·검증 서버·서버 시간·확정 시즌 지급은 별도 승인 전 미착수이며, 상점 품질 실성능·실물 지급과 혼동하지 않습니다.</p>
        <p><a href="design/master-gdd-alignment/">94% 산정 근거 →</a> · <a href="design/current-milestone-workline/">현행 작업 순서 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>P7-01B · 품질 장비 실물 지급과 실제 성능</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 상점 구매가 창고 숫자에서 끝나지 않고 I 가방 실물, U/E 장착, 실제 품질 수치까지 이어집니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>품질별 개별 아이템 payload와 가방 실물 지급, 장비·모듈·무기 능력치 배율을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>구매 전 가방 수용 가능성을 검사하고, 옵션·소켓·가방 보유량과 실제 지급 결과를 상점 UI에 표시합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>품질 정책→지급 어댑터→장비 계산을 공개 계약으로 분리하고, 거점/작전 가방 교체 때 공급자를 다시 연결합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>구매품이 장비 편집과 분리되던 문제, 모듈 장착·해제 왕복에서 품질 payload가 유실되던 경로를 수정했습니다.</p></div>
        <p>`P7_SHOP_QUALITY_OK`는 고성능 모듈 구매→I→U→실제 1.25배→해제 보존을 판정합니다. 현행 품질 수치는 임시이며 Sheet 목록과 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/hub-economy/#shop-browser">P7-01A/B 규칙 →</a> · <a href="architecture/module-audit/#p7-01b-2026-09-04">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>P7-01B 후속 · 품질 모듈/저장/CI 엄밀화</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 모듈 감사에서 발견한 CI 누락, 하드코딩 품질, 암묵적 payload, 롤백·저장·선택 제거 검증 공백을 모두 닫았습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p><code>ItemQualityCatalog</code> Resource, <code>ItemQualityDescriptor</code> 공용 계약, 실물 지급 OFF 전용 Game E2E를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>표시명·옵션·소켓을 코드 밖에서 교체하고 장비·모듈·UI가 동일 배율 함수를 사용하며 Windows 품질 재시작 보존을 검사합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>품질·제거성 계약과 코드 노드맵 검사를 PR 필수 CI 경로에 추가하고 모듈 정적 검사도 새 계약을 강제합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 4</h3><p>노드맵 최신성 누락, 품질 키/계산 중복, 공급자 롤백 실패의 이중 획득 위험, 데스크톱 저장 품질 미검증을 해결했습니다.</p></div>
        <p>기존 플레이 수치와 확정 ShopOffer CSV는 유지합니다. 옵션·소켓 Resource는 임시값이며 과금 모델·Cloudflare 플랜은 변경하지 않았습니다.</p>
        <p><a href="features/p5-hub-progression/#quality-module-contract">P5 모듈 계약 →</a> · <a href="architecture/module-audit/#p7-01b-2026-09-04">감사 결과 →</a> · <a href="quality/e2e-play-session/#p7-shop-e2e">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>개발자 코드맵 우선 · P7-02 상점 회전/리롤</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 개발자 작업실의 첫 정보가 실제 코드 모듈 관계망이 됐고, 상점은 작전 복귀와 유료 리롤을 서로 다른 원인으로 안전하게 갱신합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p><code>ShopRotationPolicy</code>, <code>ShopRotationState</code>, <code>ShopRerollTransactionService</code>와 실제 리롤 버튼·영수증을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>개발자 로그인 첫 화면에서 코드 관계·상속·검증 노드를 바로 탐색하고 P7-03 큐로 이동할 수 있게 했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>서비스 façade, 작전 취소 경계, P7 로드맵, 기획 요청 카드, 검색 우선순위와 플레이어 인식 E2E를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>정산·거점 복귀 중복 갱신, 작전 조립 실패의 잘못된 회전, 동일 리롤 거래의 재차감 경로를 제거했습니다.</p></div>
        <p>가격 25 C·3슬롯·품질 보장·이전 매물 회피는 기획 확정 전 임시 Resource입니다. 새 Sheet 목록이나 외부 과금 구성은 만들지 않았습니다.</p>
        <p><a href="features/hub-economy/#p7-02">P7-02 플레이 규칙 →</a> · <a href="architecture/module-audit/#p7-02-2026-09-04">모듈 감사 →</a> · <a href="quality/e2e-play-session/#p7-shop-e2e">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>P7-03 · 반출 설계도 영구 등록과 제작 후보</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 작전에서 반출한 설계도가 영구 등록되고, 재접속 뒤에도 제작소에서 어떤 장비를 만들 수 있는지 바로 구분됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p><code>BlueprintRegistry</code>, <code>WorkshopRecipeProvider</code>, <code>WorkshopUnlockService</code>를 추가해 저장·Recipe 조회·반출 해금 책임을 분리했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>제작소에 도면 X/Y와 후보별 재제작 가능/반출 필요 상태를 표시하고, 잘못된 ID·수량 0·중복 등록을 안전하게 거부합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>P5 파사드·계약·CI, P7 로드맵·기획 요청·검색·E2E·모듈 감사를 P7-03 완료와 P7-04 다음 순서로 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>기존 플레이 결함 수정이 아니라 제작 해금 구조를 확장한 작업입니다.</p></div>
        <p>실시간 Google Sheet의 Recipe 3행은 CSV와 같았습니다. Item 탭에 잘못 중복된 Utility 4행은 검증에서 차단해 반영하지 않았고, 기획 요청 <code>DATA-SHEET-ITEM-UTILITY-01</code>로 분리했습니다. 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/blueprint-crafting/#p7-03">설계도 흐름 →</a> · <a href="architecture/module-audit/#p7-03-2026-09-04">모듈 감사 →</a> · <a href="quality/e2e-play-session/#p7-blueprint-e2e">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>P7-04 · 원자적 맞춤 제작과 전체 모듈 감사</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 제작 전에 비용·재료·옵션/소켓 범위를 확인하고, 실제 결과와 거래 기록이 한 번에 저장됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p><code>WorkshopRollPolicy</code>, <code>WorkshopCraftTransactionService</code>, 전체 시스템 모듈 검사기를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>후보 견적 선공개, 중복 없는 실제 옵션, 실제 소켓 배열, 게임 재접속 보존을 연결했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>프로필 단일 경제 거래, P5 façade/config, 69개 Manifest 플래그, CI와 P7→P8 작업선·문서를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>제작 저장 실패의 부분 차감, 세부 표현 모듈 실행 목록 누락, 별도 Godot 프로세스가 같은 테스트 저장 폴더를 재사용하던 간헐 회귀를 차단했습니다.</p></div>
        <p>전체 감사 결과는 기능 경계 56개·클래스 213개·의존 25개·순환 0·서비스 Scene 침범 0입니다. 새 목록이 필요하지 않아 Sheet/CSV와 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/blueprint-crafting/#p7-04">P7-04 제작 →</a> · <a href="architecture/module-audit/#p7-04-2026-09-04">전체 감사 →</a> · <a href="quality/e2e-play-session/#p7-workshop-e2e">E2E →</a></p>
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
        <p><a href="features/training-ground/">P8-01 플레이와 구조 →</a> · <a href="architecture/module-audit/#p8-01-2026-09-04">모듈 감사 →</a> · <a href="quality/e2e-play-session/#p8-training-ground-e2e">실제 플레이 E2E →</a></p>
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
      <summary><span><small>UPDATE 12</small><b>무기 고정 정체성 · 고유 스킬·옵션·타격 인지</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 무기마다 명중 누적 고유 효과와 구분되는 타격 표현이 생기고, 무기·방어구 옵션은 내부/외부 성장과 모듈에 흔들리지 않는 장비 고유값으로 유지됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>고정 옵션 Resource·payload 어댑터·고유 스킬 정의/발동기·잠금 CSV 조회기를 독립 모듈로 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>5개 무기의 총구 섬광, 투사체 glow, 충격 색·크기·카메라 반응과 명중 누적 전기 효과를 구분했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>Weapon/Armor Sheet, 7행 확정 CSV, 장비 UI, 검색, 모듈 감사와 E2E 계약을 고정 정체성 기준으로 확장했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 4</h3><p>발사 후 Q 교체 시 탄환 정체성 혼선, 성장 배율의 고유 효과 침범, 획득 옵션의 장착 계산 단절, 새 정체성 Resource가 다운로드판 저장 코덱에서 거부되던 문제를 차단했습니다.</p></div>
        <p>전체 구조는 기능 57·클래스 231·의존 26·순환 0·Scene 침범 0입니다. 신규 수치는 임시값이며 과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/equipment-fixed-identity/">장비 고정 정체성 →</a> · <a href="architecture/module-audit/#equipment-fixed-identity-2026-09-04">모듈 감사 →</a> · <a href="quality/player-perception-audit/#equipment-fixed-identity-perception-2026-09-04">인식 검사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>기획 기준 전환 · Master GDD 백업본 고정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 앞으로 기획 변경과 진행도를 확인할 공개 Notion 기준이 사용자가 지정한 2026-09-02 04:14 Master GDD 백업본으로 통일됐습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>게임 기능과 플레이 수치는 변경하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>진행도 점검·기획 요청·후속 로드맵이 하나의 공개 기준 페이지를 사용합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>수집기, 고정 스냅샷, 기획 요청, P7+ 로드맵, 기획 대조, 기획자 안내의 주소와 검증값을 함께 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>복제 페이지에서 바뀐 블록 ID 때문에 근거 앵커 검증이 끊기는 문제를 제목·종류 일대일 대응으로 이관했습니다.</p></div>
        <p>새 기준은 root v153·77블록·해시 f06bd08f2159이며 Phase 체크는 0/6입니다. 기존 77개 기획 블록의 내용은 동일하고 과금·게임 데이터는 변경하지 않았습니다.</p>
        <p><a href="design/master-gdd-alignment/">새 Master GDD 대조 기준 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 14</small><b>전장의 안개 체감 개선 · 문턱·벽·탐색 기억</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 문 앞 왕복에서 화면이 깜빡이지 않고, 통로 시야가 벽과 기둥을 통과하지 않으며, 빠르게 다음 방에 들어가도 이전 방이 한 프레임에 사라지지 않습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>48광선 벽·코너 차폐와 오브젝트를 노출하지 않는 방문 방 기억색을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>14px 공간 히스테리시스, 프레임률 독립 방향 보간, 빠른 방 간 마스크 교대, 정적 안개 질감을 적용했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>맵 가시성 계약, 단일 Shader, 플레이어 인식 E2E와 성능·모듈 문서를 새 판정 기준으로 확장했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 4</h3><p>시간만으로 남던 방 시야, 문턱 떨림, 180도 시야 튐, 벽 너머 통로 노출을 차단했습니다.</p></div>
        <p>대형 작전 성능은 평균 7.527ms·피크 19.855ms·Node 2,022개로 예산을 통과했습니다. Sheet/CSV·경제·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/fog-of-war/">새 안개 동작 →</a> · <a href="quality/player-perception-audit/#fog-perception-2026-09-04">인식 검사 →</a> · <a href="architecture/module-audit/#fog-perception-2026-09-04">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 15</small><b>펄스 오버플로 · 명중 지점 전기 광역 피해</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 펄스 소총 탄환이 적에게 명중할 때마다 타격 지점 주변에 청록색 전기 충격을 방출해 밀집된 적을 함께 공격합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>단일/전기 광역 효과 정의, 반경·거리순 대상 선택, 광역 피해 문맥과 발동 집계를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>반경 144·최대 8명 상한, 큰 중심 충격 링, U 장비 상세의 실제 발동 설명으로 전투 체감과 판독성을 높였습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>펄스 소총 Resource, 잠금 CSV 스키마·검증기, 명중 대상 공급, 계약 테스트와 장비 위키를 광역 효과 계약으로 확장했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>광역 효과가 반경 밖 적이나 무제한 대상에게 적용될 수 있는 경로를 거리 필터와 대상 예산으로 차단했습니다.</p></div>
        <p>명중마다 피해 1·반경 144·최대 8명은 기획 확정 전 임시값입니다. 성장·모듈·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/equipment-fixed-identity/#펄스-오버플로-예시">고유 기능 규칙 →</a> · <a href="architecture/module-audit/#전기-광역-무기-고유-기능--2026-09-04">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 16</small><b>기획자 장비 드랍 안내 · 획득처와 정산 경계</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획자 전용 문서에서 무기·방어구가 어느 보상에서 나오고, 도면과 무엇이 다르며, 주운 뒤 탈출·사망에 따라 어떻게 처리되는지 한 흐름으로 확인할 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>게임 코드와 드랍 데이터는 변경하지 않았습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>보상 출처 비교, 획득부터 영구 창고까지의 생명 주기, 기획자가 확정할 목록을 쉬운 말로 정리했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>기획자 페이지, 검색 우선순위, 반응형 위키 E2E 계약, 생성 문서 검증을 장비 드랍 안내 기준으로 확장했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>런타임 동작 변경 없이 문서에서 혼동되던 직접 장비·도면·재료 보상의 경계를 명확히 했습니다.</p></div>
        <p>일반 적은 현재 재료 중심이고, 방 클리어는 무기→방어구→모듈→파츠 순환, 보스는 후보 중 2개 무작위입니다. 목록과 확률은 기획 확정 전 임시값이며 Sheet/CSV·경제·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="../access/planner/#equipment-drop-flow">기획자용 장비 드랍 안내 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 17</small><b>기획자 Notion 작성 기준 · 부분 확정과 임시값 분리</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 완성되지 않은 기획도 확정·임시·미정 항목을 나눠 적으면 개발자가 추측 없이 반영할 수 있고, 장비 드랍 예시를 복사해 바로 시작할 수 있습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>상태·대상·결정·미정·적용 시점·재검토·이전 결정 교체를 포함하는 상태 인식 Notion 초안 생성기를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>6개 상태 의미, 최소 5줄, 부분 확정, 수치·변경 예시, 작성 뒤 실제 개발 반영 순서를 기획자 언어로 정리했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>기획자 작업실, 요청 운영 계약, 위키 반영 안내, 검색 우선순위, 생성 HTML·스크립트 검증을 같은 작성 기준으로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>비어 있거나 서로 섞인 요구가 암묵적인 확정값으로 해석될 여지를 `미정`·결정 계보·반영 상태 규칙으로 차단했습니다.</p></div>
        <p>Notion 저장은 자동 배포가 아니며 작업 요청 시 최신 공개 원문을 다시 확인합니다. 게임 데이터·Sheet/CSV·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="../access/planner/#notion-authoring">기획자 Notion 작성 가이드 →</a></p>
      </div>
    </details>
  </div>
</details>
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-03</b><small>16 UPDATE BUNDLES · BUILD 26 · IMPROVE 35 · CHANGE 27 · FIX 30</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>16</b><small>UPDATE BUNDLES</small></span><span><b>26</b><small>BUILD</small></span><span><b>35</b><small>IMPROVE</small></span><span><b>27</b><small>CHANGE</small></span><span><b>30</b><small>FIX</small></span></div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>전투 HUD 가장자리 재배치 · 중앙 시야 확보</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 전투 화면 중앙을 비우고 스킬·에너지·소켓·조작 정보를 하단 가장자리의 짧은 시선 이동으로 읽도록 재배치했습니다.</strong><ul>
          <li><b>스킬:</b> 중앙 우측의 세로 3단 패널을 우하단 440×82px 가로 클러스터로 전환했습니다.</li>
          <li><b>소켓:</b> 빈 슬롯은 숨기고 실제 룬·코어·유물을 장착한 뒤에만 하단 중앙에 표시합니다.</li>
          <li><b>배치 책임:</b> 세션 소켓의 독립 상단 앵커를 제거하고 <code>CombatHudPresenter</code>가 스킬·대시·소켓·행동 도크를 함께 배치합니다.</li>
          <li><b>인지 계약:</b> 장착 전 결정은 전리품 패널, 장착 후 상태는 RUN ONLY 소켓 패널이 설명하도록 분리했습니다.</li>
          <li><b>검증:</b> 지속 HUD 16% 상한, 중앙 56%×54% 안전 영역 무침범, 비겹침과 빈 상태 즉시 숨김을 스모크·31개 인식 E2E로 고정했습니다.</li>
        </ul><p class="sfh-intent"><b>모듈 경계</b><span>전투 계산·소켓 규칙·스킬 상태는 변경하지 않고 각 HUD의 읽기 전용 스냅샷과 배치 Presenter만 수정했습니다. Sheet·CSV·과금 모델은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>가로형 스킬 클러스터, 중앙 안전 영역, 상황형 소켓 표시 계약을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>시야 점유, 시선 이동, 에너지 판독, 가장자리 정렬, 좁은 화면 축약을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>HUD Presenter, 스킬·소켓 표현, 플레이어 인식 기준, 관련 위키를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p><code>queue_free()</code> 지연으로 빈 패널이 남는 현상과 중앙 세로 HUD의 전장 침범을 제거했습니다.</p></div>
        <p><a href="features/game-loop/">전투 HUD →</a> · <a href="features/combat-skills/">스킬 UI →</a> · <a href="features/session-sockets/">런 소켓 →</a> · <a href="quality/e2e-play-session/">E2E →</a></p>
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
        <p><a href="features/operation-entry-wizard/">튜토리얼 계약 →</a> · <a href="quality/e2e-play-session/">열린 상태 E2E →</a></p>
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
      <summary><span><small>UPDATE 9</small><b>보스 등장 경고 · 외곽 접근 방향</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 보스가 나타나면 짧게 경고하고, 화면 밖에서 오는 방향을 외곽 화살표로 알려줍니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>추격·일반 보스 등장 배너와 보스별 화면 외곽 방향 표시를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>카메라·줌에 맞춰 방향을 갱신하고 화면 안 진입·처치·가방·일시정지 시 표시를 정리해 전투 시야를 확보합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>추적·좌표·표현·수치를 독립 모듈로 분리하고 8방향·4화면 크기·실제 I/ESC E2E를 필수 검사에 추가했습니다. 입력 대기 후 카메라 좌표도 새로 계산해 화면 내부 판정의 오탐을 방지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>보스 발생 임계·드랍·전투 수치는 변경하지 않았습니다.</p></div>
        <p><a href="features/elite-pursuit/">경고·방향 표시 규칙 →</a> · <a href="quality/e2e-play-session/">검증 범위 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>Windows 자동 저장 · 종료 후 진행 이어가기</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 다운로드판을 껐다 켜도 확정한 거점 세팅과 반출한 재화·성장·기록을 이어갑니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>가방·장비·모듈·파츠 체크포인트와 최근 100회 작전 이력을 로컬 저장합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>기존 프로필·성장에 검증 저장과 이전본 복구를 더하고, 거점 상태·다운로드 안내로 저장 위치를 확인합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>파일 보관·형식 변환·런 경계·표시를 분리하고 재실행 검증을 배포 필수 검사에 추가했습니다. Sheet 목록·밸런스는 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>재실행 시 거점 세팅이 사라지는 경로와 개발 테스트가 플레이어 기본 저장을 사용하는 경로를 수정했습니다.</p></div>
        <p>전투 도중 이어하기·클라우드 동기화는 아닙니다. 중단 시 미반출 전리품은 지급하지 않으며 기존 실패 규칙을 유지합니다.</p>
        <p><a href="getting-started/run-project/#desktop-save">저장·백업 안내 →</a> · <a href="quality/e2e-play-session/#desktop-save-e2e">재실행 검증 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>상점 매물 비교 · 골라서 구매 · 다음 작업 범위 정정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 상점 버튼이 첫 상품을 즉시 사던 동작을 없애고, 가격·수량을 비교한 뒤 고른 상품만 구매합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>3품질 매물 카드와 읽기 전용 견적·명시적 선택 구매 화면을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>같은 상품의 개당 가격을 비교하고, ESC로 준비 화면과 거점의 이전 일시정지 상태로 돌아갑니다. 4개 화면 크기에서 버튼 경계를 검사합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>Notion v1005·77블록은 재조회 결과 동일합니다. 실제 품질 성능과 구매/제작 장비 지급 연결은 미완료로 정정했고, 경제 항목 재산정에 따라 전체 가중 추정치는 94%입니다. 위변조 감지·감사·백업 확장은 구현 예정으로만 등록했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>상점 열기만으로 결제되던 경로와 오래된 회전 견적으로 구매하던 경로를 차단했습니다.</p></div>
        <p>P7-01A 완료 범위는 비교·선택 구매입니다. 현재 지급은 창고 수량이며 실제 품질 성능·I/U 실물 장착 연결은 다음 P7-01B에서 처리합니다. Sheet·CSV·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/hub-economy/#shop-browser">상점 사용법 →</a> · <a href="quality/e2e-play-session/#p7-shop-e2e">검증 범위 →</a> · <a href="design/master-gdd-alignment/">94% 산정 근거 →</a> · <a href="design/p7-plus-preimplementation/#economy-integrity-plan">보안·백업 구현 예정 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 12</small><b>로비 상점·출격 준비 · 장착한 그대로 작전 진입</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 로비에서 세팅을 마친 뒤 작전에 들어갑니다. 진입 화면에서 무기를 다시 고르지 않습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>로비 보급 상점·출격 준비 단말을 F로 열고 요원·스킬·소모품을 준비합니다. 위치·이름·반경은 별도 Scene에서 조정합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>작전 2단계를 현재 장착 상태 확인 전용으로 바꾸고, 준비 패널은 4개 화면 크기에서 세로 스크롤과 고정 닫기·장비 버튼을 제공합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>실물 장비 상태를 출격 원본으로 고정했습니다. 위키 사용법·모듈 관계·E2E도 새 로비 동선으로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>카탈로그가 로비 무기·모듈·파츠를 덮어쓰거나 장착 무기를 재청구하던 경로를 제거했습니다. 미저장 편집을 직접 출격 호출로 우회하지 못하게 했습니다.</p></div>
        <p>브리핑 취소·정상 복귀는 세팅 보존, 사망/실패의 장착품 소실은 기존 규칙입니다. 상점 품질 실성능·전체 실물 지급(P7-01B), Sheet·CSV 수치, 과금 모델은 이번 변경에 포함하지 않습니다.</p>
        <p><a href="features/hub-economy/#hub-preparation">로비 사용법 →</a> · <a href="features/loadout-investment/">장착 보존 계약 →</a> · <a href="quality/e2e-play-session/#hub-preparation-e2e">회귀 검증 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>기획자 아이템·밸런싱 튜토리얼 · P6 로컬 마감 재검증</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획자 작업실에서 수치 조정과 새 아이템 추가 절차를 바로 찾고, 시즌 참가 조건을 정확히 확인합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>실제 계정 서버·온라인 경쟁·서버 지급은 구현 완료로 처리하지 않습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>실제 Sheet 1·2행을 확인한 튜토리얼과 검색·문서 노드 연결을 추가했습니다. 시트 수정·실시간 시험·CSV 확정·되돌리기 및 개발자가 연결할 영역을 분리합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>공개 Notion v1005·77블록·해시 614a0b8ddee4 재조회 동일. P6 로컬/실서비스 종료 조건과 다음 P7-01B 작업을 구분했습니다. 문서/검증 추가만으로 기존 94% 추정치를 올리지 않습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>소·중·대 모두 허용하던 신규 시즌 기본값을 Notion의 대형 조건으로 수정했습니다. 구 시즌은 시작 때 조건과 기록을 보존하고 다음 시즌부터 새 정책을 적용합니다.</p></div>
        <p>시즌 81조합·구 정책 저장/전환·대형 보상, 전체 플레이/실패 정산 E2E와 기존 모듈 계약을 검사합니다. Sheet 수치·CSV·과금·도메인은 변경하지 않았습니다.</p>
        <p><a href="getting-started/planner-item-balance-tutorial/">기획자 튜토리얼 →</a> · <a href="features/ranking-provider/#p6-closeout">P6 마감 경계 →</a> · <a href="quality/e2e-play-session/#p6-closeout-e2e">검증 기준 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 14</small><b>PC·모바일 시작 선택 · 양손 터치 전용 화면</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 실행할 때 조작 방식을 선택합니다. 모바일은 좌하단 조이스틱·우하단 공격과 스킬로 플레이합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>PC/모바일 진입 선택과 손가락별 조이스틱 입력을 추가했습니다. 선택 뒤에는 로비 준비→작전 게이트 동선을 유지합니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>모바일 버튼에 에너지·쿨타임을 표시하고 PC용 중복 HUD를 숨깁니다. 가로/세로 논리 해상도와 양손 영역을 별도로 배치합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>선택은 표시 설정에 저장하며 K/화면 설정에서 변경합니다. 입력·뷰포트·시작 조립을 분리하고 전투와 장비 원본은 유지합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>터치 버튼이 이벤트 기반 가방·지도·설정을 열지 못하던 경로를 수정했습니다. 창 전환·백그라운드·기기 모드 변경 때 눌린 입력을 해제합니다.</p></div>
        <p><a href="features/mobile-hud-settings/">모바일 사용법 →</a> · <a href="quality/e2e-play-session/#mobile-entry-e2e">입력·화면 검증 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 15</small><b>모바일 크기 조절 · 첫 조작 안내 팝업</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 모바일 버튼과 글자가 커지고, 첫 모바일 선택 때 조작 안내를 확인한 뒤 로비로 이동합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>1회성 모바일 팝업에 이동·공격·스킬·사용 안내와 크기 선택을 제공합니다. 확인 완료는 이 브라우저·기기에 저장됩니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>기본 125%, 설정에서 100/125/150%를 선택합니다. 조작 글자·에너지·상단 메뉴 가독성을 높이고 좁은 화면은 양손 영역이 겹치지 않는 최대 크기로 맞춥니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>배치 정책·안내 UI·설정 저장을 분리했습니다. 기존 PC 배치와 저장 파일은 유지하며 표시 설정 초기화로 안내를 반복하지 않습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>확인 전 종료·저장 실패는 안내 완료로 기록하지 않습니다. 배율 변경 때 눌린 입력을 해제하며 설정 실제 클릭·5화면×3배율을 회귀 검사합니다.</p></div>
        <p><a href="features/mobile-hud-settings/">크기·첫 안내 사용법 →</a> · <a href="quality/e2e-play-session/#mobile-entry-e2e">모바일 검수 기준 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 16</small><b>모바일 가로 기본 · 회전 요청과 안전한 폴백</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 모바일은 가로 플레이를 기본으로 선택하고, 세로로 열었으면 회전 방법을 안내합니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 1</h3><p>모바일 활성화 시 가로 방향을 요청합니다. 세로 시작 화면과 첫 팝업에 전체화면·가로 전환 요청 버튼을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 1</h3><p>네이티브 기본 방향을 좌·우 가로 센서로 지정하고, 이미 가로인 화면에는 추가 버튼을 숨깁니다.</p></div>
        <div class="sfh-group"><h3>수정 · 1</h3><p>방향 요청은 독립 정책 모듈이 담당합니다. 1회 안내와 크기 저장, PC 창 크기는 보존합니다. 전체화면은 명시적 버튼 클릭으로만 요청합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>잠금 미지원·거절·예외가 로비 진입을 막지 않게 처리했습니다. 팝업 검수를 실제 세로 논리 해상도와 스크롤 클릭으로 보강했습니다.</p></div>
        <p><a href="features/mobile-hud-settings/">가로 사용법·지원 경계 →</a></p>
      </div>
    </details>
  </div>
</details>
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-02</b><small>15 UPDATE BUNDLES · BUILD 55 · IMPROVE 65 · CHANGE 62 · FIX 33</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>15</b><small>UPDATE BUNDLES</small></span><span><b>55</b><small>BUILD</small></span><span><b>65</b><small>IMPROVE</small></span><span><b>62</b><small>CHANGE</small></span><span><b>33</b><small>FIX</small></span></div>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>Master GDD v1005 재대조 · P7 이후 작업선 세팅</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획자가 확정한 로비 허브·상점·제작소·훈련장 범위를 새 기준선으로 삼고, 공식 Phase 1~6 뒤 내부 P7~P10을 바로 착수 가능한 계약으로 준비했습니다.</strong><ul>
          <li><b>원문:</b> 공개 Notion을 root v1005·77블록·해시 <code>614a0b8ddee4</code>로 갱신하고 0~10장을 다시 대조했습니다.</li>
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
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>P5-01 캐릭터 투자 · Windows 최신본 보존</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 작전 전에 캐릭터 가격과 패시브를 비교해 선택하고, 배포 저장소에는 검증된 최신 Windows 다운로드만 남깁니다.</strong><ul>
          <li><b>캐릭터:</b> 선봉대·질주자·방벽병 3종, 추가 비용과 패시브를 작전 브리핑에 연결했습니다.</li>
          <li><b>데이터:</b> Character Sheet·확정 CSV·Web payload의 12열 계약과 임시/확정 상태를 분리했습니다.</li>
          <li><b>모듈:</b> Definition/Table/Service/Presenter/OperationContract/Player modifier source를 단방향으로 조립했습니다.</li>
          <li><b>보존:</b> Cloudflare 다운로드 E2E 뒤 이전 Windows R2 객체만 제거하고 패키징 출력은 현재 버전만 유지합니다.</li>
          <li><b>다음:</b> P5-02 주·보조무기와 스킬 투자로 이동합니다.</li>
        </ul><p class="sfh-intent"><b>검증</b><span>3종 파싱·선택, 비용 1회 합산, 브리핑, 실전 속도 300→330, 9개 작전 조합과 파일 정리 범위를 통과했습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>캐릭터 투자 전 구간과 Windows 최신본 보존을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>플레이어 선택 인과, 데이터 교체성, 저장 공간 관리를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 2</h3><p>작업선·기획 요청·노드맵·검색을 P5-02 기준으로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>신규 결함 수정 없이 기능·배포 보존 범위만 확장했습니다.</p></div>
        <p><a href="features/character-selection/">캐릭터 선택 계약 →</a> · <a href="architecture/module-audit/#p5-01windows-2026-09-02">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 3</small><b>P5-02 무기·스킬 런 투자 · 실전 복원</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 주·보조무기와 스킬 3칸을 작전 전에 투자하고, 잠김·태그·결제·실전·복귀를 하나의 플레이어 인과로 연결했습니다.</strong><ul>
          <li><b>선택:</b> 주무기·보조무기·S1~S3의 소유/잠김/런 구매 상태와 추가 비용을 브리핑에서 비교합니다.</li>
          <li><b>결제:</b> 캐릭터·로드아웃 추가 비용을 작전 계약이 한 번 합산하고 실패·취소에는 재화가 빠지지 않습니다.</li>
          <li><b>실전:</b> 펄스 소총·아크 대시 선택을 장비/스킬 공개 계약에 적용하고 거점 복귀 때 원래 준비 상태로 복원합니다.</li>
          <li><b>데이터:</b> Weapon·Skill Sheet에 가격·소유·해금·허용 슬롯을 확장하고 확정 CSV·Web payload를 동기화했습니다.</li>
          <li><b>다음:</b> P5-03 유틸리티 투자로 이동하며 실제 목록이 필요할 때 Item Sheet를 같은 구조로 확장합니다.</li>
        </ul><p class="sfh-intent"><b>검증</b><span>소유/잠김/런 구매, 무차감 차단, 140C 1회 합산, 태그 적합성, 실전 발동, 성공·사망 복원과 평균 PC 성능 예산을 통과했습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>카탈로그·선택 서비스·브리핑·결제·런타임 교체/복원을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>투자 비교·상태 피드백·데이터 교체성·인식 E2E를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>작업선·진행률·기획 요청·검색·노드맵을 P5-03 기준으로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>소형 작전 보상 용량을 넘던 임시 가격을 140C로 보정했습니다.</p></div>
        <p><a href="features/loadout-investment/">무기·스킬 투자 계약 →</a> · <a href="architecture/module-audit/#p5-02-2026-09-02">모듈 감사 →</a> · <a href="quality/e2e-play-session/">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 4</small><b>P5 완전 종료 · 거점 진행 통합·모듈 감사</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 유틸리티·불변 작전 초안·파산 보호·회전 상점·제작·훈련·도감을 P5-03~10 완료 계약으로 연결했습니다.</strong><ul>
          <li><b>Sheet:</b> Utility·OperationPreset·ShopOffer·Recipe·TrainingScenario·Codex 탭과 Item 4행을 추가했습니다.</li>
          <li><b>거래:</b> 작전·구매·재굴림·제작의 1회 차감과 중복 차단, 실패 롤백을 적용했습니다.</li>
          <li><b>영구성:</b> 반출 도면과 도감 누적을 저장하고 재접속 후 지역 힌트·제작 가능 상태를 복원합니다.</li>
          <li><b>훈련:</b> 단일·밀집 시나리오와 DPS·타격·AP·쿨타임 계측, 무료 세팅 원복을 제공합니다.</li>
          <li><b>감사:</b> 7개 서비스 개별 제거와 Scene 내부 접근 금지, 대형 60 FPS 예산을 통과했습니다.</li>
        </ul><p class="sfh-intent"><b>검증</b><span><code>P5_HUB_PROGRESSION_OK</code>, 실제 플레이 E2E, 평균 6.880ms·피크 8.204ms를 통과했습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 8</h3><p>P5-03~10의 플레이어 흐름과 영구 저장을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>거점 비교·거래 안전·재접속·데이터 교체·제거성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>94% 산식·P6-01 작업선·검색·E2E·노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>전리품 Dictionary 수량을 도감이 숫자로 가정하던 오류를 수정했습니다.</p></div>
        <p><a href="features/p5-hub-progression/">P5 거점 진행 →</a> · <a href="architecture/module-audit/#p5-0310-2026-09-02">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 5</small><b>P5 엄밀 모듈성 보강 · 실제 타격 계측·원자적 거래</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · P5 완료 판정을 정적 파일 존재가 아니라 제거·오류·실패 경로를 견디는 실행 계약으로 다시 고정했습니다.</strong><ul>
          <li><b>제거:</b> 활성 하위 모듈만 지연 로드하고 비활성 CSV 경로는 검증 대상에서 제외합니다.</li>
          <li><b>정합:</b> Google Sheet와 확정 CSV의 Recipe·Codex·OperationPreset ID를 기존 표준 카탈로그와 통일했습니다.</li>
          <li><b>실전:</b> 적 피해 신호→훈련 façade→DPS/AP/쿨타임 계측 경로를 연결했습니다.</li>
          <li><b>원자성:</b> 상점·리롤·제작 저장 실패를 강제로 발생시켜 크레딧·재료·창고·제작 결과가 모두 원복됨을 검증합니다.</li>
          <li><b>조립:</b> P5 행동·문구는 Presenter가 소유하고 Game은 공개 액션 전달만 수행합니다.</li>
        </ul><p class="sfh-intent"><b>검증</b><span><code>P5_MODULARITY_OK</code>, <code>P5_HUB_PROGRESSION_OK … schema_rejection transaction_rollback</code>, 게임 스모크를 통과했습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>지연 설치·공개 façade·Presenter·피해 텔레메트리를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>데이터·제거·원자성·수명 제한 검사를 강화했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>Sheet·CSV·위키·E2E 기준을 동일 ID 계약으로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 5</h3><p>정적 로드·비활성 경로·내부 테스트 우회·부분 거래·UI 도메인 누수를 수정했습니다.</p></div>
        <p><a href="features/p5-hub-progression/">P5 계약 →</a> · <a href="architecture/module-audit/#p5-2026-09-02">엄밀 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 6</small><b>실시간 코드 모듈 노드맵 · 상속·의존 양방향 추적</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 실제 GDScript 상태를 위키 노드로 자동 생성하고 모듈 사용처·의존처와 클래스 상속을 반응형으로 탐색합니다.</strong><ul>
          <li><b>산출:</b> 178개 스크립트→53개 모듈·159개 클래스·157개 관계와 전체 소스 해시를 생성합니다.</li>
          <li><b>탐색:</b> 계약·조립·기능·검증 필터와 검색, 선택 노드의 들어오는/나가는 관계 버튼을 제공합니다.</li>
          <li><b>상속:</b> 엔진 기반과 프로젝트 내부 기반을 클래스별로 표시해 상속과 합성의 경계를 분리합니다.</li>
          <li><b>반응형:</b> 2단 비교에서 1열 흐름까지 자동 전환하고 44px 터치·포커스·고대비를 보장합니다.</li>
          <li><b>게이트:</b> 생성 데이터 현행성·관계 무결성·내비게이션·JS·CSS를 strict 빌드 전에 검사합니다.</li>
        </ul><p class="sfh-intent"><b>영향</b><span>위키 가시화와 검증만 추가했습니다. 게임 로직·데이터·과금·Cloudflare 플랜은 불변입니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>코드 스캐너와 반응형 노드 탐색기를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>모듈 관계·상속·모바일·접근성 인지를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>아키텍처 문서·검색·문서 노드맵·E2E 계약을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>수동 구조 기록과 현재 코드가 어긋날 수 있던 현행성 공백을 차단했습니다.</p></div>
        <p><a href="architecture/code-module-map/">코드 모듈 노드맵 →</a> · <a href="architecture/module-rules/">모듈 규칙 →</a> · <a href="quality/wiki-responsive-e2e/">반응형 E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 7</small><b>P6-01 랭킹 공급자 · 방사형 코드 관계 웹</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 랭킹 기록을 로컬에 우선 보존하면서 온라인 공급자를 교체할 수 있게 했고, 코드 노드맵은 선택 모듈 중심 거미줄로 관계를 직접 보여줍니다.</strong><ul>
          <li><b>랭킹 경계:</b> 공통 <code>RankingProvider</code>, 로컬 구현, 온라인 어댑터, 설정 Resource, 조립 façade를 분리했습니다.</li>
          <li><b>장애 안전:</b> 공급자가 없거나 실패해도 작전 기록은 로컬에 확정되고 결과 화면에 오프라인·동기화 대기 상태가 표시됩니다.</li>
          <li><b>관계 웹:</b> 선택 모듈을 중앙 원형에 두고 최대 12/8/6개 관계를 데스크톱·태블릿·모바일별 방사형 화살표로 연결합니다.</li>
          <li><b>현행성:</b> 코드 맵을 53모듈·163클래스·157관계로 다시 생성하고 검색·전체 문서맵·P6 작업선을 갱신했습니다.</li>
          <li><b>다음:</b> P6-02 신원·서명·멱등 키·검증 큐는 서버/계정/보안 제공자 결정 뒤 별도 계약으로 연결합니다.</li>
        </ul><p class="sfh-intent"><b>검증·비용</b><span><code>P6_RANKING_PROVIDER_OK</code>와 위키 320·390·1440px E2E를 적용합니다. Sheet 목록·과금·Cloudflare 유료 설정은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>공급자 계약·로컬 구현·온라인 어댑터·상태 표시·방사형 관계 웹을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>기록 보존·공급자 교체·장애 인지·관계 가시성·반응형 탐색을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>진행률 95%, P6-02 작업선, 코드맵 데이터, 검색, 문서 노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>온라인 연결 실패가 랭킹 기록 자체를 잃게 만들 수 있는 확장 경계 공백을 차단했습니다.</p></div>
        <p><a href="features/ranking-provider/">P6 랭킹 제공자 →</a> · <a href="architecture/code-module-map/">방사형 코드 노드맵 →</a> · <a href="quality/e2e-play-session/">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 8</small><b>작전 진입 3단계화 · 전 경로 복구 · 첫 투입 가이드</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 작전 설정을 지역·장비·최종 확인으로 나누고, 모든 초기 실행 방식을 작전 또는 안전한 복구 화면으로 연결했습니다.</strong><ul>
          <li><b>동선:</b> 기본 플레이는 거점 작전 게이트의 F 진입을 그대로 유지합니다.</li>
          <li><b>UI:</b> 지역·작전→요원·장비→검토·투입 세 단계와 좌·우 키·44px 버튼을 적용했습니다.</li>
          <li><b>튜토리얼:</b> 첫 투입에 이동·전투·방 확보·탈출을 안내하는 4단계 비차단형 현장 가이드를 표시합니다.</li>
          <li><b>복구:</b> 투자 승인 뒤 맵 조립 실패도 완전 롤백하고 부분 전장을 제거한 뒤 거점 또는 설정으로 이동합니다.</li>
          <li><b>검증:</b> 실제 게이트를 거친 9개 규모·난이도와 거점/설정 플래그 4경로를 모두 자동 실행합니다.</li>
        </ul><p class="sfh-intent"><b>경계</b><span>목록형 데이터가 없어 Sheet는 확장하지 않았고, 과금·Cloudflare 유료 설정은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>단계 상태·3페이지 UI·초기 라우터·실패 복구·첫 투입 가이드를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 6</h3><p>작전 결정 밀도·탐색·터치·첫 플레이 이해·반복 투입·위키 홈 밀도를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>작전 계약 문서·E2E·모듈 감사·검색·홈 표시를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>비표준 진입의 빈 화면, 조립 실패 잔존, 정산 비활성 반복 투입 차단을 수정했습니다.</p></div>
        <p><a href="features/operation-entry-wizard/">작전 진입 마법사 →</a> · <a href="quality/e2e-play-session/">실제 플레이 E2E →</a> · <a href="architecture/module-audit/#2026-09-02">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 9</small><b>기획자·개발자 역할 로그인 · 최초 계정 변경</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 공개 위키는 그대로 두고, 기획자와 개발자는 로그인 뒤 자기 업무에 필요한 보호 탭만 열도록 분리했습니다.</strong><ul>
          <li><b>기획자:</b> 결정 대기·데이터 요청·Notion 대조·플레이 인식 검수를 먼저 봅니다.</li>
          <li><b>개발자:</b> 다음 작업선·코드 노드맵·모듈 감사·E2E를 먼저 봅니다.</li>
          <li><b>계정:</b> 임시 계정은 첫 로그인 직후 아이디·비밀번호 변경을 강제하고 기존 세션을 폐기합니다.</li>
          <li><b>보안:</b> 비밀번호 해시·8시간 세션·CSRF·실패 잠금을 Pages Function과 전용 Private R2에 격리했습니다.</li>
          <li><b>검색:</b> 보호 페이지는 공개 검색 색인에서 제외하며 서버가 역할을 검사하기 전에는 HTML을 내려주지 않습니다.</li>
        </ul><p class="sfh-intent"><b>경계</b><span>기획 원본은 Notion·Sheet, 개발 원본은 PR입니다. 게임 계정·결제·Cloudflare 플랜은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>역할 로그인, 보호 경로, 계정 변경, 서버 세션, 전용 저장소 배포를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 6</h3><p>역할별 첫 화면·검색 노출·모바일 입력·협업 책임·세션 안전·배포 검증을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>홈·내비게이션·수정 안내·E2E·모듈 감사를 역할 인증 기준으로 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>클라이언트 숨김만으로 보호되는 문제, 초기 계정 재배포 덮어쓰기, 역할 교차 접근 가능성을 차단했습니다.</p></div>
        <p><a href="architecture/wiki-role-auth/">역할 인증 계약 →</a> · <a href="access/login/">역할 로그인 →</a> · <a href="quality/wiki-responsive-e2e/">위키 E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 10</small><b>웹 로비 복구 · 27개 작전 조합 실전 회귀</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · Web export에서 누락된 P5 데이터 때문에 거점 조립이 중단되던 원인을 제거하고, 모든 규모·난이도·요원 조합과 ESC 복귀를 실제 세션으로 고정했습니다.</strong><ul>
          <li><b>동선:</b> 기본 실행은 거점→게이트 F→3단계 브리핑→작전이며 설정 취소·작전 중단은 거점으로 돌아갑니다.</li>
          <li><b>데이터:</b> Utility·OperationPreset·ShopOffer·Recipe·TrainingScenario·Codex CSV를 동기화된 Web payload로 공급합니다.</li>
          <li><b>경제:</b> 요원·장비 추가 비용으로 투입비가 커져도 `LootValueAllocationPolicy`가 박스 수와 단가를 분리해 총 회수 2.5~5배를 구성합니다.</li>
          <li><b>회귀:</b> 3규모×3지역×3난이도×3요원 81개 모두 실제 맵 생성·계약 일치·ESC 거점 복귀를 통과해야 배포됩니다.</li>
        </ul><p class="sfh-intent"><b>검증</b><span><code>P5_HUB_PROGRESSION_OK web_payload_fallback_6</code>, <code>OPERATION_COMBINATION_OK combinations_81 … esc_return</code>, 게임 스모크와 플레이 E2E를 통과했습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>Web payload 6종, 가치 배분 정책, 명시적 복구 상태를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>거점 연속성·경제 확장성·오류 피드백을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>CI 문자열·동기화 검사·작전 계약·E2E/감사를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 4</h3><p>웹 로비 누락, 요원 변경 투입 실패, 기본 투입 중단, ESC 무응답을 제거했습니다.</p></div>
        <p><a href="features/operation-entry-wizard/">작전 진입 계약 →</a> · <a href="quality/e2e-play-session/">실제 플레이 E2E →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 11</small><b>작전 사전검증 · 모든 세팅의 확장 안전 계약</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 총기·파츠·모듈 등 세팅을 바꾼 뒤 조립 실패로 거점에 되돌아오던 구조를 결제 전 검증과 불변 작전 계획으로 교체했습니다.</strong><ul>
          <li><b>근본 수정:</b> 요원·로드아웃·유틸리티를 일반 설정 기여자로 집계하고 장비·가방·전리품을 결제 전에 검증합니다.</li>
          <li><b>확장성:</b> 새 설정은 중앙 비용 분기를 수정하지 않고 기여자/검증기 등록만으로 작전 계획에 참여합니다.</li>
          <li><b>장비:</b> 같은 무기는 장착 파츠·모듈을 유지하고, 다른 작전 무기는 해당 슬롯만 임시 교체한 뒤 거점 상태를 복원합니다.</li>
          <li><b>원자성:</b> 서명된 계획과 실제 결제 계약이 다르면 조립하지 않으며 실패 시 크레딧·소모품·장비가 변하지 않습니다.</li>
          <li><b>E2E:</b> 기존 81개 조합에 12개 세팅 변경 프로필과 중복 파츠·가방 겹침·계획 변조 실패 경로를 추가했습니다.</li>
        </ul><p class="sfh-intent"><b>경계</b><span>새 목록이 없어 Google Sheet를 확장하지 않았고 게임 과금·Cloudflare 플랜·결제 설정은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>사전검증 서비스, 설정 기여자, 런타임 검증기, 불변 계획 계약을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 6</h3><p>세팅 확장성·실패 인지·장비 복원·결제 원자성·검증 재사용·회귀 범위를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>모듈 원칙·작전 문서·E2E·검색·문서 노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>결제 후 늦은 실패, 세팅 변경 진입 회귀, 0원 작전 전리품 범위 불일치를 수정했습니다.</p></div>
        <p><a href="features/operation-launch-preflight/">작전 사전검증 →</a> · <a href="quality/e2e-play-session/">93조합·실패 E2E →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 12</small><b>역할 로그인 복구 · 고정 ID와 비밀번호 변경</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획자·개발자 계정을 역할명으로 고정하고 공통 초기 비밀번호로 복구해, 기존 저장 상태와 무관하게 다시 로그인할 수 있게 했습니다.</strong><ul>
          <li><b>고정 계정:</b> <code>planner/0000</code>, <code>developer/0000</code>으로 각각 자기 보호 탭에 접근합니다.</li>
          <li><b>설정:</b> 계정 화면은 아이디를 바꾸지 않고 비밀번호만 4~128자로 변경합니다.</li>
          <li><b>런타임 수정:</b> Cloudflare workerd가 거부하던 PBKDF2 210,000회를 지원 상한 100,000회로 맞췄습니다.</li>
          <li><b>1회 교정:</b> revision 3보다 오래된 Private R2 계정만 교정하고 이후 변경 비밀번호는 CI가 보존합니다.</li>
          <li><b>검증:</b> Seed digest·salt·반복 상한, 두 기본 로그인, 역할 교차 차단, ID 변조, 변경 전후 세션과 배포 Pages 실로그인을 판정합니다.</li>
        </ul><p class="sfh-intent"><b>경계</b><span>인증 모듈과 전용 R2 외 게임·다운로드·결제·Cloudflare 플랜은 불변입니다. 공개 초기 비밀번호는 로그인 후 변경을 권장합니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>고정 ID·공통 초기 비밀번호·revision 3 복구와 실로그인 배포 게이트를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>로그인 UX·복구·비밀번호 보존·역할 격리·배포 검증을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>역할 UI·Worker 계약·운영 문서·검색 그래프를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>가변 아이디 잔존, PBKDF2 런타임 상한 초과, 로그인 없는 배포 검증 공백을 제거했습니다.</p></div>
        <p><a href="access/login/">로그인 →</a> · <a href="architecture/wiki-role-auth/">인증 계약 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>역할별 작업실 · 공개 플레이 홈 최소화</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 공개 위키를 홍보용 플레이 테스트 홈으로 줄이고, 상세 기획·개발 정보는 로그인한 역할별 작업실에서 목적에 맞게 읽도록 재구성했습니다.</strong><ul>
          <li><b>공개:</b> 게임 한 문장 소개, 브라우저 플레이, Windows 다운로드, 최소 조작 안내와 팀 로그인만 먼저 제공합니다.</li>
          <li><b>기획자:</b> 전문 용어 없이 게임 흐름→완료된 플레이→남은 기획 결정→Notion·Sheet 작성 방법 순으로 설명합니다.</li>
          <li><b>개발자:</b> 완료 기준선→오류·위험→P6-02 이후 작업→모듈 구조·프로그래밍 원칙→E2E 순으로 배치합니다.</li>
          <li><b>실제 보호:</b> 내부 HTML뿐 아니라 검색 색인·문서/코드 노드 JSON·검색 우선순위·사이트맵도 서버 인증 전에 제공하지 않습니다.</li>
          <li><b>접근:</b> 두 역할은 공유 내부 문서를 읽을 수 있지만 서로의 전용 첫 탭은 403으로 격리됩니다.</li>
        </ul><p class="sfh-intent"><b>경계</b><span>게임 기능·밸런스·Google Sheet·결제·Cloudflare 플랜은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>게임 기능 추가 없이 위키 접근과 정보 구조만 변경했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>공개 첫인상, 기획자 이해 경로, 개발자 실행 경로를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>홈·역할 탭·인증 계약·반응형 E2E 문서를 새 공개 범위에 맞췄습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>내부 문서·검색 데이터 노출, 숨은 보호 문서 링크, Pages 파일/Worker 전파 시점 차이로 생기던 배포 오판을 수정했습니다.</p></div>
        <p><a href="access/planner/">기획자 작업실 →</a> · <a href="access/developer/">개발자 작업실 →</a> · <a href="architecture/wiki-role-auth/">인증 계약 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 14</small><b>P6-02 검증형 랭킹 제출 · 영구 재시도</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 성공 런을 익명 신원과 검증 봉투로 묶고, 중복·변조·네트워크 단절이 있어도 로컬 기록과 제출 상태를 잃지 않게 했습니다.</strong><ul>
          <li><b>신원:</b> 교체 가능한 익명 기기 ID를 별도 저장해 외부 로그인 제공자와 게임 프로필을 결합하지 않습니다.</li>
          <li><b>검증:</b> run ID·조건·시간·처치·회수 가치를 SHA-256 무결성 다이제스트와 멱등 키로 묶습니다.</li>
          <li><b>재시도:</b> 공급자 단절·시간초과 제출을 JSON 큐에 보존하고 연결 복구나 명시적 재시도 때 다시 보냅니다.</li>
          <li><b>거부:</b> 변조·형식 오류·서버 영구 거부는 이유를 표시하고 무한 재전송하지 않습니다.</li>
          <li><b>플레이어 결과:</b> 탈출 결과에서 서버 검증 완료, 로컬 보존, 재시도 건수 또는 거부 이유를 읽습니다.</li>
        </ul><p class="sfh-intent"><b>검증·경계</b><span>중복·변조·단절·시간초과·저장 복원·영구 거부와 실제 결과 화면 E2E를 통과했습니다. 외부 서버·계정·Sheet·결제·Cloudflare 유료 설정은 추가하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>익명 신원, 제출 봉투, 멱등 처리, 영구 큐, 결과 상태 표시를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>오프라인 안전성, 상태 이해, 저장 마이그레이션, 공급자 교체성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>런 ID 정산, 공급자 설정, P6 작업선, E2E·코드 노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>같은 런의 중복 집계와 연결 실패 기록의 조용한 유실 가능성을 차단했습니다.</p></div>
        <p><a href="features/ranking-provider/">P6 검증 제출 →</a> · <a href="architecture/module-audit/#p6-02-2026-09-02">모듈 감사 →</a> · <a href="quality/e2e-play-session/">E2E →</a></p>
      </div>
    </details>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 15</small><b>작전 브리핑 화면 폭 · 브라우저 잘림 수정</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 작전 검토 화면의 좌우 내용이 브라우저 캔버스 밖으로 밀리던 고정 폭을 제거하고, 화면 너비에 따라 정보 우선순위를 바꾸도록 개선했습니다.</strong><ul>
          <li><b>근본 원인:</b> 고정 500px 프리뷰·좌측 열과 줄바꿈되지 않는 우측 설명이 합쳐져 실제 패널 최소 폭이 화면을 초과했습니다.</li>
          <li><b>데스크톱:</b> 패널을 최대 1160px로 제한하고 프리뷰를 현재 열 크기에 비례해 그립니다.</li>
          <li><b>좁은 화면:</b> 1120px 아래는 축소 2열, 840px 아래는 장식 프리뷰를 접은 단일 계약 열로 전환합니다.</li>
          <li><b>텍스트:</b> 단일행 말줄임과 설명 문단 줄바꿈을 분리해 폭·높이 폭주를 함께 차단했습니다.</li>
          <li><b>E2E:</b> 1280·1024·768·480px 폭 예산과 실제 세 단계 Control 경계·투입·ESC·44px 탐색을 검사합니다.</li>
        </ul><p class="sfh-intent"><b>경계</b><span>표시 Presenter와 코드 프리뷰만 변경했습니다. 작전 비용·세팅·게임 데이터·Google Sheet·과금 설정은 불변입니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>반응형 폭 계약과 프리뷰 비율 드로잉을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>화면 여백, 정보 우선순위, 텍스트 밀도, 모바일 계약 열을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>작전 브리핑 문서, 플레이 E2E, 모듈 감사를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>좌우 화면 잘림과 일괄 줄바꿈으로 생길 수 있는 세로 폭주를 제거했습니다.</p></div>
        <p><a href="features/operation-entry-wizard/">작전 진입 UI →</a> · <a href="quality/e2e-play-session/">화면 폭 E2E →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
  </div>
</details>
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-01</b><small>20 UPDATE BUNDLES · BUILD 69 · IMPROVE 80 · CHANGE 99 · FIX 31</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>20</b><small>UPDATE BUNDLES</small></span><span><b>69</b><small>BUILD</small></span><span><b>80</b><small>IMPROVE</small></span><span><b>99</b><small>CHANGE</small></span><span><b>31</b><small>FIX</small></span></div>
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
    <details class="sfh-bundle">
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
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 13</small><b>지역·난이도 타겟 파밍 · 안개 문턱 UX · 위키 최신순</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · P4-02를 완료해 작전 조건과 실제 전리품 후보를 연결하고, 방↔통로 시야 전환의 급격한 끊김을 완화했습니다.</strong>
          <ul>
            <li><b>Sheet/CSV:</b> 독립 LootTable 탭에 세 지역 27행을 추가하고 Item 정의·지역 태그를 교차 검증합니다.</li>
            <li><b>Provider:</b> 지역·난이도·규모·출처·투자 배율로 후보를 만들고 동일 seed 추첨과 실시간/확정 폴백을 제공합니다.</li>
            <li><b>브리핑:</b> 대표 전리품 3개·후보 수·최고 등급을 표시해 지역 선택의 결과를 투입 전에 이해할 수 있습니다.</li>
            <li><b>안개:</b> 문턱 유예→퇴장→통로→입장 여섯 상태, 220px 주변·320px 안심 외곽과 정면 보간을 적용했습니다.</li>
            <li><b>위키:</b> 홈 일일 업데이트를 최신 작업 우선으로 뒤집고 소스·생성 HTML 모두에서 GitHub 역링크를 금지합니다.</li>
          </ul>
          <p class="sfh-intent"><b>검증 결과</b><span>전리품 계약·게임 smoke·실제 입력 E2E 24/6·대형 성능 6.882ms·위키 링크/검색/반응형 게이트를 통과 기준으로 고정했습니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>전리품 행·테이블·설정·결정적 공급자·작전 타겟 브리핑을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>지역 파밍 판단, 문턱 시야 연속성, 정면 가독성, Web 데이터 추적, 기획 검색을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>Manifest·작전 조립·E2E·성능 문서·마일스톤·홈 일일 묶음 순서를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>잘못된 지역 태그 수용, 문턱 밝기 단절, 위키 GitHub 역링크와 오래된 최신순 판정을 차단했습니다.</p></div>
        <p><a href="features/loot-tables/">지역·난이도 전리품 →</a> · <a href="features/fog-of-war/">전장의 안개 →</a> · <a href="quality/e2e-play-session/">E2E →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 14</small><b>기획 요청 허브 · P4-03 현장 비교·획득 · Sheet 상시 확장 규칙</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary">
          <strong>무엇이 변했나 · 기획 결정과 데이터 요청을 첫 화면에서 추적하고, 방 보상 전리품의 비교·보류·획득을 실제 플레이로 연결했습니다.</strong>
          <ul>
            <li><b>요청 데이터:</b> `planner-requests.json`이 작업 요청·밸런스 데이터·완료 안내와 고유 ID를 소유합니다.</li>
            <li><b>Notion 근거:</b> 각 카드가 공개 Master GDD로 연결되고 기획자는 같은 ID로 확정·보류·수정 근거를 작성합니다.</li>
            <li><b>Sheet 권한:</b> 신규 열거형 목록이 필요한 향후 모든 작업은 별도 재승인 없이 1행 변수·2행 설명·3행 데이터와 실시간/확정 CSV 계약을 확장합니다.</li>
            <li><b>P4-03:</b> 방 확보→월드 신호→비교 패널→ESC 보류→재접근→F 획득→런 임시 보관을 구현했습니다.</li>
            <li><b>검증:</b> 계약 테스트, 실제 입력 E2E 25/7, 모듈 제거, 반응형 위키 요청 데이터와 Notion 링크를 자동 판정합니다.</li>
          </ul>
          <p class="sfh-intent"><b>책임 경계</b><span>현장 획득은 장비 교체나 정산을 직접 수행하지 않습니다. P4-04의 기존 항목 처리와 P4-05의 소켓 수치는 상단 기획 요청 카드의 답을 받아 진행합니다.</span></p>
        </div>
        <div class="sfh-group"><h3>구현 · 6</h3><p>비교·월드 드랍·패널·획득 서비스와 데이터 기반 요청 허브를 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>기획 인계, 요청 분류, 전리품 판단, 반응형 밀도, E2E 인식 범위를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>Manifest·방 조립·마일스톤·검색·노드맵·문서 검증을 P4-03 완료 상태로 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>ESC 보류가 월드 전리품까지 제거하지 않도록 상태 전이를 분리했습니다.</p></div>
        <p><a href="features/field-loot-acquisition/">현장 전리품 →</a> · <a href="design/planner-request-workflow/">기획 요청 운영 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 15</small><b>P4-04A 현장 무기 즉시 장착 · 역할형 협업 위키</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 방 보상 무기를 R로 바로 사용하고, 기획자와 AI 개발자의 다음 행동·완료 근거를 첫 화면에서 분리합니다.</strong><ul>
          <li><b>게임:</b> Weapon·LootTable Sheet 기반 전격 펄스 소총, R 즉시 장착, 기존 무기 런 임시 보관·거점 복구를 연결했습니다.</li>
          <li><b>위키:</b> 담당 역할·차단·상태·수락 기준·Sheet 위치·검증 근거·Notion 마지막 확인 시각과 역할 필터를 추가했습니다.</li>
          <li><b>경계:</b> 미확정 영구 해금·소실을 선행하지 않고 P4-04B 스킬 교체와 P4-06 정산을 별도 작업으로 남겼습니다.</li>
        </ul></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>무기 정의·장착 카탈로그·교체 서비스·R 입력을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>협업 역할, 최신성, 담당자, 수락 기준, 근거 가시성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>Sheet·CSV·Manifest·키 설정·작업 라인을 갱신했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>미확정 정책의 영구 반영을 구조적으로 차단했습니다.</p></div>
        <p><a href="features/field-loot-immediate-equip/">현장 즉시 장착 →</a> · <a href="design/wiki-collaboration-workflow/">협업 개선안 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 16</small><b>P4-04B 현장 스킬 교체 · Notion 결정 계보·안전 제안 UI</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 현장 스킬을 실제 R로 교체하고 기획 원본→결정→구현→E2E를 한 ID 계보로 연결했습니다.</strong><ul>
          <li><b>구현:</b> 아크 질주, 슬롯 3·3번 키 유지, 태그 거부, 자원·쿨다운·충전 비교와 복구.</li>
          <li><b>데이터:</b> Skill 14열·4행, LootTable 29행, 확정 CSV·Web PCK·Windows 해시 연결.</li>
          <li><b>협업:</b> Notion root v797·57블록·SHA-256, source anchor·DEC·supersedes/conflict, 로컬 초안 복사 UI.</li>
          <li><b>배포:</b> 목표 `sfh-game.play-preview.dev`는 미등록으로 차단하고 현행 Worker를 유지해 무중단·무과금 경계를 지켰습니다.</li>
        </ul></div>
        <div class="sfh-group"><h3>구현 · 5</h3><p>스킬 정의·교체 서비스·시트 동기·상태 복구·제안 초안기를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 6</h3><p>플레이 판단, 키 연속성, 기획 출처·결정 계보, 모바일 입력, 역할 인계를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 8</h3><p>Manifest·빌드·E2E·마일스톤·검색·노드맵·요청 JSON·배포 표면을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>런 키 영구 저장, 미등록 도메인 무중단 절체, 추천 검색의 색인 미실행 위험을 차단했습니다.</p></div>
        <p><a href="features/field-loot-skill-swap/">현장 스킬 교체 →</a> · <a href="design/wiki-collaboration-workflow/">협업 운영 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 17</small><b>남은 11개 작업 패킷 · Master GDD 진행도 78%</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 공개 기획의 확정 상태와 현재 main 구현을 다시 대조해 남은 작업·차단 데이터를 한 실행선으로 정리했습니다.</strong><ul>
          <li><b>Notion:</b> 당시 v797·57블록·해시 `b22dce53d706` 유지. 체크 6/6이라는 과거 판독은 문자열 처리 오류였으며 9월 3일 정정했습니다.</li>
          <li><b>저장소:</b> P4-04A/B의 무기·스킬 현장 교체와 복구 E2E를 전리품 구현률 40%로 반영.</li>
          <li><b>산식:</b> 핵심 흐름 ×2·기반/확장 ×1의 기존 가중치를 유지해 78%로 현행화.</li>
          <li><b>잔여:</b> P4 2개, P5 5개, P6 4개 총 11개. 다음은 P4-05 세션 소켓.</li>
          <li><b>기획 인계:</b> P4 소켓 수치, P5 캐릭터·유틸리티 카탈로그, P6 서버·시즌 정책을 별도 카드로 추적.</li>
        </ul><p class="sfh-intent"><b>판정 경계</b><span>Notion 체크는 범위 확정, 저장소 코드·데이터·플레이어 인식 E2E는 구현 완료 근거입니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 0</h3><p>기능 추가 없이 원문·main·검증 근거를 재감사했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 2</h3><p>남은 작업 순서와 선행 기획 데이터의 가시성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 4</h3><p>진행 산식·마일스톤·검색·기획 요청 카드를 P4-04B 이후 상태로 수정했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>Phase 체크 상태와 전리품 구현률이 오래된 값으로 남은 문서 불일치를 제거했습니다.</p></div>
        <p><a href="#_1">진행도·남은 작업 →</a> · <a href="design/master-gdd-alignment/">Master GDD 대조 →</a> · <a href="design/current-milestone-workline/">작업 라인 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 18</small><b>P4-05 RunAsset 세션 소켓 · 임시값 교체형 모듈</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획 수치가 없어도 안전한 임시값으로 룬·코어·유물을 실제 런 전투에 연결하고, 최종값은 데이터만 교체할 수 있게 했습니다.</strong><ul>
          <li><b>플레이:</b> 세션 자산 접근 시 F 런 소켓 장착, 즉시 피해·쿨다운·이동 변화, RUN ONLY HUD 점유·클릭 해제를 제공합니다.</li>
          <li><b>임시 정책:</b> 룬 2·코어 1·유물 1, 동일 아이템 1개, 가득 차면 오래된 항목 교체를 사용합니다.</li>
          <li><b>데이터:</b> Google Sheet `RunAsset` 14열·3규칙과 확정 CSV·Web payload·Windows 데이터 해시를 같은 계약으로 연결했습니다.</li>
          <li><b>모듈:</b> Rule/Table/Config/Service/HUD를 영구 장비 모듈·정산과 분리하고 Manifest로 단독 제거할 수 있습니다.</li>
          <li><b>E2E:</b> 실제 F 입력→전도 룬 피해 증가→HUD 버튼 해제→원복과 중복 제한·런 초기화를 판정합니다.</li>
          <li><b>다음:</b> P4-06에서 탈출 자동 환전·영구 해금·사망 소실·중복 정산 방지를 연결합니다.</li>
        </ul><p class="sfh-intent"><b>기획 교체 지점</b><span>DATA-P4-05-01이 확정되면 RunAsset과 Item 값만 바꾸고 같은 E2E를 재실행합니다. 코드·영구 장비·과금 모델은 변경하지 않습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 6</h3><p>RunAsset 데이터, 소켓 규칙·서비스, 반응형 HUD, 세 효과, 현장 F 연결을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>런 전용 의미, 기획 교체성, HUD 밀도, Web 폴백, 플레이어 인식 E2E를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 7</h3><p>Manifest·전투 modifier·내보내기·릴리스 메타·마일스톤·검색·노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 1</h3><p>영구 장비 모듈과 런 전용 자산이 같은 슬롯으로 오인될 수 있는 책임 혼합을 제거했습니다.</p></div>
        <p><a href="features/session-sockets/">세션 소켓 →</a> · <a href="design/current-milestone-workline/">다음 P4-06 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 19</small><b>9개 작전 조합 복구 · P4-06 전리품 정산 · Phase 4 완료</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 작전 조립 회귀를 고치고 전리품 획득부터 성공·사망 정산까지 Phase 4 전체 인과를 닫았습니다.</strong><ul>
          <li><b>작전 진입:</b> 전리품 가치 목표를 실제 박스 수·단가 용량과 교차해 소·중·대형×표준·숙련·악몽 9개 조합이 모두 전투를 시작합니다.</li>
          <li><b>오류 가시성:</b> 조립 실패 시 거점 복귀 문구가 원인을 덮지 않고 실제 실패 메시지를 보존합니다.</li>
          <li><b>탈출:</b> Item 생명 주기대로 자동 환전·영구 해금·상점 등록·창고 보관을 한 번만 적용합니다.</li>
          <li><b>사망:</b> 런 획득 전리품을 영구 프로필에 반영하지 않고 소실 종류와 수량을 결과 화면에 표시합니다.</li>
          <li><b>E2E:</b> 실제 설정 UI 9조합, 성공 정산·중복 방지, 사망 소실을 더해 23 UI·28 인식·13 인과 흐름을 판정합니다.</li>
          <li><b>다음:</b> [P5·P6 사전 구현 설계](design/p5-p6-preimplementation.md)에 따라 P5-01 캐릭터 선택부터 시작합니다.</li>
        </ul><p class="sfh-intent"><b>모듈·데이터 경계</b><span>Lifecycle→Settlement→Profile 단방향을 유지하고 정산 모듈만 제거 가능하게 검증했습니다. 기존 Item 15종으로 충분해 Sheet와 과금 모델은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 4</h3><p>정산 서비스·Manifest 조립·성공/사망 결과·중복 방지 계약을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>9개 조합 UI E2E, 플레이어 손익 인식, 오류 가시성, 후속 사전 설계를 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 8</h3><p>진행률 87%, Phase 4 완료, CI·검색·노드맵·품질 문서를 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>배치 불가능한 전리품 목표의 전투 조립 실패와 실제 오류 문구 유실을 해결했습니다.</p></div>
        <p><a href="features/run-settlement/">런 전리품 정산 →</a> · <a href="quality/e2e-play-session/">실제 플레이 E2E →</a> · <a href="design/p5-p6-preimplementation/">P5·P6 사전 설계 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 20</small><b>모바일 플레이 · 이동 가능한 상태 HUD · 투입액 회수 엘리트</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 모바일 브라우저 조작과 플레이어별 HUD 표현 설정을 추가하고, 투입 비용을 회수한 뒤의 위험을 전역 엘리트 추격으로 연결했습니다.</strong><ul>
          <li><b>모바일 입력:</b> 16개 터치 버튼이 키보드와 동일한 semantic Action을 사용하며 모달에서는 숨고 전투·거점 복귀 시 다시 표시됩니다.</li>
          <li><b>HUD 설정:</b> 상태 HUD 좌하단 기본, 하단 좌·중·우 이동, 키 표시 간결·대괄호·숨김, 터치 자동·표시·숨김을 K에서 저장합니다.</li>
          <li><b>엘리트:</b> 실제 작전 투입액과 같은 휴대 크레딧 임계에서 랜덤 1~2명을 한 번 생성하고 현재 플레이어보다 8% 빠르게 전역 추적합니다.</li>
          <li><b>방 독립:</b> 일반 적 예산·방 ID·문 충돌을 분리해 엘리트가 남아도 방 문이 열리고 보상이 생성됩니다.</li>
          <li><b>배포:</b> 브라우저·Windows가 같은 CI 커밋과 데이터 입력에서 생성되고 E2E·ZIP 체크섬을 함께 통과해야 최신으로 판정합니다.</li>
          <li><b>문서:</b> 위키 수정 안내를 제안 초안·Notion 근거·비공개 원본 PR·Cloudflare 배포 순서로 바꾸고 71개 전체 노드맵에 신규 문서를 연결했습니다.</li>
        </ul><p class="sfh-intent"><b>종료 판단</b><span>23 UI·30 플레이어 인식·15 인과 흐름, 신규 모듈 on/off·의존성 계약을 통과했습니다. 목록 추가가 없어 Sheet와 과금 모델은 변경하지 않았습니다.</span></p></div>
        <div class="sfh-group"><h3>구현 · 6</h3><p>표시 설정·터치 패드·K 설정·HUD 이동·엘리트 정책·전역 추격을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 5</h3><p>모바일 조작, 전투 시야, 키 가독성, 위험 인지, Web/Windows 동기 가시성을 개선했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 8</h3><p>Manifest·조립·CI·E2E·위키 수정 안내·검색·노드맵·배포 계약을 수정했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>터치 입력 부재와 엘리트가 방 문 개방을 막을 결합 위험을 제거했습니다.</p></div>
        <p><a href="features/mobile-hud-settings/">모바일·HUD 설정 →</a> · <a href="features/elite-pursuit/">엘리트 추격자 →</a> · <a href="architecture/module-audit/">모듈 감사 →</a></p>
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
    <details class="sfh-bundle" open>
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
  <summary><span class="sfh-day-title"><b>2026-08-30</b><small>21 UPDATE BUNDLES &middot; BUILD 44 &middot; IMPROVE 37 &middot; CHANGE 18 &middot; FIX 11</small></span><em class="sfh-chevron">&#x2303;</em></summary>
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
              <details class="sfh-entry"><summary><i class="sfh-badge is-change">수정</i><span class="sfh-entry-title">공개 기획 원본 고정</span><b class="sfh-chevron">⌄</b></summary><div class="sfh-entry-body"><p>게시된 Notion 본문을 직접 대조하고 향후 진행도 점검의 권위 있는 주소로 지정했습니다.</p><a href="https://wobbly-pawpaw-1ff.notion.site/Master-GDD-2026-09-02-04-14-00-3ce5b728004081bfa94fe42e4ed48767">공개 기획 원본 ↗</a></div></details>
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
        <details class="sfh-bundle" open>
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
