---
title: 기획자 작업실
description: 게임을 처음 보는 사람도 현재 완성 범위와 프로젝트 오너에게 제안할 항목을 이해하는 기획자 전용 화면
search:
  exclude: true
hide:
  - toc
---

# 기획자 작업실

**이번에 확인할 것:** [방 하나를 돌고 다음 방으로 가는 데 어디서 오래 걸리는지](../quality/e2e-play-session.md#run-flow-20260922) 기록할 수 있습니다. “싸움이 긴지, 보상 선택이 어려운지, 길 찾기가 막히는지”를 구분하기 위한 도구입니다. 첫 보상 하나를 빨리 골랐다고 보상 전체를3초 안에 정리했다고 보지 않습니다. 플레이 후 구간과 이유를 남겨 주세요. 재미 목표는 아직 수락 전입니다.

**9/22 현재 변화:** 작전 중 가방을 열어도 적과 시간이 멈추지 않습니다. 장착한 룬도 탈출 시 환전되는 기존 동작을 전용 시험으로 확인했습니다. [사용 방법과 위험 안내](../features/grid-inventory.md#realtime-20260922) · [다음 작업과 확인할 것](../design/current-milestone-workline.md#next-20260922). 신규15고유요구는 코드 구현4·부분6·미구현5이며 전체82행 완료율이나 재미 검증 완료율이 아닙니다. 훈련 라이브 동등성 수정은 완료했지만 실제 플레이 수락과 파우치·심층·혈전 등의 오너 판단은 남아 있습니다.

**요원·스킬 시험:** [초기 무장과 액티브 40종](../features/tactical-skill-catalog.md). 3요원의 고정 패시브가 돌파/기동/구역 유지로 특화합니다. 신규36종 수치는 임시이며 Skill은 자원, SkillPattern은 효과, Character는 특화를 조정합니다. 공용 액티브와 캐릭터 전용 제한의 차이, 적 제어 강도·상태 연계 보상을 시험한 뒤 Notion에 판단 이유를 남겨 주세요.

**새 무기 시험:** [총기 5종·근접 3종의 차이와 획득 방법](../features/weapons.md#arsenal-20260909). [공용 시트 Weapon](https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/edit#gid=0)에서 단검/대검 활성화와 산탄총·레일 소총·창의 임시값을 조정할 수 있습니다. 각 무기의 거리·리듬·명중 범위가 적절한지 시험한 뒤 Notion에 확정/임시와 판단 이유를 기록해 주세요.

**방어구 시험:** [수호자·질주자·축전자 3세트](../features/armor-sets.md). 같은 계열을 2개 또는 4개 입으면 추가 효과가 생깁니다. Armor는 개별 장비, ArmorSet은 세트 보너스, Upgrade는 성장, LootTable은 획득 장소입니다. 아래 성장/DPS 도구에서 한 장비의 단계 변화와 세트 조합을 확인한 뒤 Notion에 `확정/임시 · 변경 값 · 이유`를 적어 오너에게 알려 주세요. 현재 수치는 임시입니다.

<section class="sfh-workspace-block" markdown="1" id="decisions-needed" aria-labelledby="decisions-needed-title">

## 지금 결정해 주세요 {#decisions-needed-title}

**신규 기능을 시작하려면 아래 3가지 게임 규칙과 1가지 밸런스 판단이 필요합니다.** 먼저 파우치부터 작성해 주세요. 기획자는 안을 제안하고, 최종 적용 여부는 **프로젝트 오너**가 판단합니다. 아래 예시는 설명용이며 승인값·현재 게임 규칙이 아닙니다.

**작성한 내용을 Notion에 반영했다면 프로젝트 오너에게 개인 메시지로 알려 주세요.** 메시지에 `판단 ID · 수정한 Notion 링크/문단 · 변경 요약 · 확정/임시/미정 상태`를 포함해 주세요. 이 위키는 개인 메시지를 자동 전송하거나 Notion 변경을 자동 배포하지 않습니다.

<details markdown="1">
<summary>1. 파우치 · 죽어도 가져올 수 있는 물건은? <small>DEC-N26-POUCH · 파우치 2건의 선행 결정</small></summary>

파우치는 일반 가방과 달리 **사망해도 물건을 보존하는 작은 보관칸**입니다. 일반 창고와는 다릅니다.

- **결정할 것:** 시작 칸의 가로×세로, 확장 단계·비용, 허용/금지 품목, 회전 가능 여부, 작전 중 넣기·빼기 허용, 사망·중단·재접속 처리.
- **특히 선택:** 보존한 룬·도면을 물건 그대로 남길지, 영구 해금 또는 크레딧 환전으로 먼저 처리할지. 같은 물건을 보존하면서 동시에 환전하면 안 됩니다.
- **이렇게 판단할 수 있습니다 — 미승인 예시:** “임시안: 시작 2×1칸, 작전 중 이동·회전 허용, 재료만 보관하고 무기·방어구·룬·도면은 금지. 사망 시 원형 보존. 강제 종료는 사망과 동일, 재접속 시 동일 물건을 한 번만 복원. 확장 기능은 보류.”
- **다른 선택도 가능:** 도면까지 허용하되 탈출해야 해금되도록 할 수 있습니다. 이 경우 도면을 죽어서 보존한 뒤 다음 작전에서 가져갈 수 있는지도 명시해 주세요.
- **확인할 결과:** 사망 뒤 허용품만 남고, 가방↔파우치 이동·재접속으로 물건이나 재화가 늘어나지 않아야 합니다.

</details>

<details markdown="1">
<summary>2. 심층 지역 · 누가 들어가고 열쇠는 언제 쓰나? <small>DEC-N26-DEPTH · 심층 3경로의 선행 결정</small></summary>

심층은 더 위험한 안쪽 구역입니다. **입장 자격**과 **들어간 뒤 환경 피해를 막는 능력**은 서로 다른 규칙입니다.

- **결정할 것:** 저항 장비가 없으면 입구에서 막을지, 들어갈 수 있지만 오염 피해를 받을지. 저항 기준·피해를 선택한다면 수치와 주기도 필요합니다.
- **결정할 것:** 수문장 처치 보장 드랍의 품목·수량·지급 위치, 가방이 꽉 찼을 때 처리, 키카드 소비 시점·실패 시 차감 여부·재입장 범위. 수문장은 현재 추격 보스와 별개입니다.
- **이렇게 판단할 수 있습니다 — 미승인 예시:** “임시안: 지정 저항 장비 착용 시 심층 오염 피해 면역. 수문장을 잡으면 저항 장비 완제품 1개를 바닥에 보장 드랍, 가방이 꽉 차면 바닥에 유지. 키카드는 별도 획득 경로를 정하고, 금고 문을 실제로 연 순간 1개 소비. 실패는 무차감, 같은 작전에서 열린 문 재통과는 무료.” 수문장 드랍은 원문의 저항 장비를 유지한 예시이며 키카드 드랍으로 대체하려면 변경안으로 명시해야 합니다.
- **다른 선택도 가능:** 장비 없이 진입하되 초당 오염 피해를 받게 할 수 있습니다. 이 안은 피해량·저항 감소식·사망 가능 여부까지 적어야 구현 범위가 명확해집니다.
- **확인할 결과:** 입장 거부 이유를 알 수 있고, 문 열기 실패·연타로 키카드를 잃거나 중복 소비하지 않아야 합니다.

</details>

<details markdown="1">
<summary>3. 혈전 / 버서커 · 체력을 얼마나 쓰고 돌려받나? <small>DEC-N26-BLOOD · 신규 프로필 1건의 선행 결정</small></summary>

표준 캐릭터의 키트 전용 회복 규칙을 전부 바꾸는 것이 아니라, **특정 프로필에만 체력 소비·흡혈 예외**를 주는 안입니다.

- **결정할 것:** 적용 캐릭터/스킬, HP 고정량 또는 최대 HP 비율, 기존 AP 비용과 함께 낼지 대체할지, HP 부족 시 거부 또는 자해 사망 허용.
- **결정할 것:** 적중/처치 중 흡혈 조건, 실제 피해 기준인지 고정 회복인지, 초당 상한, 지속 피해·광역·다중 적중 처리, 키트 50%의 기준과 반올림.
- **이렇게 판단할 수 있습니다 — 미승인 예시:** “임시안: 지정 프로필의 스킬만 HP 10과 기존 AP를 함께 소비, 사용 후 HP가 1 미만이면 무차감 거부. 직접 적중 실제 피해의 5%를 회복하되 초당 최대 HP의 3%까지. 지속 피해와 처치 보너스 회복은 제외. 키트 회복량은 기본 회복량의 50%, 소수점 버림.”
- **함께 명시:** 광역은 적별 회복을 합쳐 같은 초당 상한을 적용할지, 프로필을 해제하면 다음 행동부터 표준 규칙으로 돌아갈지 적어 주세요.
- **확인할 결과:** AP만 차감되고 스킬은 실패하는 일이 없어야 하며, 다수 적·지속 피해로 흡혈 상한을 우회하지 않아야 합니다.

</details>

<details markdown="1">
<summary>4. 방탄복 성장 · 4단계 방어 보정 공백은 의도인가? <small>QA-BAL-01 · 기존 밸런스 확인</small></summary>

- **결정할 것:** 전술 방탄복 4단계 방어 보정 공백을 유지할지, 데이터를 채울지. 공백만 보고 개발자가 임의 수치를 넣지 않습니다.
- **이렇게 판단할 수 있습니다 — 미승인 예시:** “의도된 정체 구간이므로 유지. 다음 단계에서 방어가 다시 증가한다는 설명을 제공.” 또는 “누락이므로 4단계 목표 방어값/증가율을 지정하고 수정.”
- **수정안을 고르면:** 아래 성장 그래프에서 해당 방어구 하나를 선택해 3→4→5단계를 비교하고, 적용 변수·단위·최종 숫자와 판단 이유를 Notion에 기록해 주세요. ‘적당히 증가’만으로는 확정값이 아닙니다.
- **확인할 결과:** 확정 CSV·게임 실제 스탯·기획자 그래프가 동일한 값이어야 합니다. 신규 기능 6건과 별도인 밸런스 안건입니다.

</details>

<details markdown="1">
<summary>Notion 작성문과 개인 메시지 예시 <small>복사한 뒤 본인이 선택한 내용으로 바꿔 주세요</small></summary>

```text
판단 ID: DEC-N26-POUCH
상태: 임시 제안 / 확정 제안 / 미정 중 선택 (오너 승인과 구분)
대상·범위: 파우치에 들어갈 품목과 사망 처리
선택한 규칙·정확한 값/단위: [직접 작성]
예외: 가방 부족 / 사망 / 중단 / 재접속 / 중복 입력
기존 지시를 바꾸는 부분: [없음 또는 대체할 지시]
선택 이유와 기대 플레이: [직접 작성]
통과 기준: [플레이어 행동 → 보여야 하는 결과]
남은 미정·적용하지 않을 범위: [직접 작성]
오너 승인: 미승인 (실제 승인 전 임의 변경 금지)
```

**개인 메시지 예시:** “Notion에 DEC-N26-POUCH 임시안을 반영했습니다. [문단 링크] 재료만 보존하고 룬 환전은 제외하는 제안입니다. 확장은 미정입니다. 확인 후 적용 여부 판단 부탁드립니다.”

[Notion 기획 원문 열기](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed) · [기능 상태 트래커](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2) · [자세한 작성 가이드](#notion-authoring)

</details>

<details markdown="1">
<summary>추가 미정 14건 · 무엇을 확정하면 되나요? <small>기존 임시 구현은 유지 · 아래도 모두 미승인 예시</small></summary>

트래커의 ‘미정’은 코드가 없다는 뜻이 아닙니다. 기존 임시값을 **유지 / 수정 / 보류** 중 선택하고 사유를 적어 주세요. 같은 요청 ID가 여러 행에 있으므로 **ID와 항목 이름을 함께** Notion·개인 메시지에 적습니다. 다음 예시 숫자도 자동 적용값이 아닙니다.

1. **PLAN-02-TARGET · 타겟 갱신 주기:** 초당30회/60회 중 선택하고 반응성·성능 수락 조건을 정합니다. 예: “임시 30회, 밀집 전투에서 목표 변경이 늦게 느껴지면 60회와 비교 후 확정.”
2. **PLAN-05-TRAIN · 허수아비 설정:** 방어력·속성 저항을 어디까지 사용자가 조절할지 정합니다. 예: “방어력 0~100 시험 허용, 속성 저항 편집은 보류. 기존 훈련 기능은 유지.” 지원하지 않는 속성은 구현 범위도 별도 확인합니다.
3. **PLAN-00-ENV · 그래픽/기준 해상도:** 픽셀 표현 기준과 화면 확대 방식을 정합니다. 예: “640×360 기준 픽셀 표현을 제안하되 한글·모바일 가독성 검수 후 확정.” 승인된 청크 렌더러를 TileMapLayer로 되돌리는 결정은 아닙니다.
4. **PLAN-04-SHOP · 상점 리롤 비용:** 고정/증가식, 시작값·상한·초기화 시점을 정합니다. 예: “첫100C, 이후100C씩 증가, 최대500C, 새 작전 종료 후 초기화.” 가격 변경 여부는 오너 승인 전까지 기존값을 유지합니다.
5. **PLAN-06-EXTRACT · 탈출 증원 배율:** 일반 대비 수량·주기 중 무엇을 배율로 바꿀지, 총 생성 한계를 정합니다. 예: “동시 수량 상한은 유지, 증원 주기만 일반의0.8배. 총 생성 예산은 늘리지 않음.”
6. **PLAN-01-CTRL · 최대 스킬 슬롯:** 4/5/6 등 최종 슬롯 수와 모바일 배치를 정합니다. 예: “최대4개 제안, 기본 제공 스킬은 현재3종 유지, 새 슬롯을 새 스킬 제작으로 계산하지 않음.” 현재 키 바인딩·슬롯 구조 변경은 별도 영향 검토가 필요합니다.
7. **PLAN-02-TARGET · 광역 탐색 반경:** 대상 탐색 범위와 실제 피해 반경을 구분해 px 또는 스킬 정의 참조로 정합니다. 예: “탐색은 각 스킬 사거리 이내, 밀집도 계산은 그 스킬의 실제 효과 반경과 동일.”
8. **PLAN-07-LEADER · 실서버 랭킹/무결성:** 오프라인 프로토타입 유지 또는 서버 연동, 계정·기록 검증 범위·운영 비용 한도를 정합니다. 예: “현재 로컬 기록만 유지, 서버 구축은 보류.” 서버·계정·과금은 이 안내만으로 생성하거나 변경하지 않습니다.
9. **DATA-01-LOOT · 룬 환전 가치:** 티어별 C 또는 계산식, 강화·중복·손상 보정, 환전 시점을 정합니다. 예: “티어별100/300/1000C, 탈출 때만 환전, 사망은0C.” 파우치에 룬을 허용한다면 보존과 환전 우선순위도 함께 결정합니다.
10. **PLAN-03-FLOW · 준비 UI:** 단일 화면/탭/단계 분할 중 어떤 경험을 최종 수락할지 정합니다. 예: “로비에서 장비 준비, 게이트에서 현재3단계 검토·투입 유지.” 이미 승인된 로비 장착 흐름을 바꾸려면 대체 지시를 명시합니다.
11. **PLAN-01-CTRL · AP 최대·회복:** 최대치·초당 회복·피격/사용 후 지연·드랍 공존을 정합니다. 예: “현재 임시 회복인1초 지연·초당10을 유지해 비교, 최대치는 현행값 유지.” 충전 횟수와 HP 키트 회복은 별도입니다.
12. **PLAN-06-EXTRACT · 탈출 방어 시간:** 소/중/대 시간과 페널티 가산·이탈/재진입 처리 여부를 정합니다. 예: “기본20초를 전 규모 공통으로 유지, 이탈 시 일시정지, 재진입 시 남은 시간 재개.” 즉시 사용 가능한 현행 출구를 시간 잠금으로 바꾸는 뜻은 아닙니다.
13. **PLAN-03-FLOW · 씬 전환 연출:** 페이드/암전 방식, 길이·입력 잠금·완료 신호를 정합니다. 예: “전환 페이드0.2초, 실제 준비 완료 전 입력 잠금, 완료 후 로비/작전 이름 표시.” 연출로 로딩 실패를 가리지 않습니다.
14. **PLAN-04-SHOP · 손상 장비 페널티:** 대상 품목·가능한 효과·범위·동시 개수·중복을 정합니다. 예: “무기만 공격력-10% 또는 공격속도-10% 중1개, AP 페널티 제외, 방어구는 보류.” 구매 전 정확한 효과를 보여 주는지 확인합니다.

[원문별 대조표](../design/master-gdd-alignment.md) · [요청 목록](#planning-queue). 수치를 바꾼 안은 해당 계산기·실제 플레이 조건을 근거로 함께 전달해 주세요.

</details>

AP·소켓 등 이미 임시 구현된 규칙은 새 확정안이 없다는 이유로 중단하지 않습니다. HP 키트 전용·청크 렌더러 대체는 승인 완료라 다시 승인 요청하지 않습니다. 기다리는 동안 개발은 배포판 플레이·탈출 F·저장·성능·표시 불일치 검증을 진행합니다.

</section>

게임 규칙을 이해하고, 수치를 시험하고, 판단할 근거를 전달하는 공간입니다.

<nav class="sfh-workspace-launcher" aria-label="기획자 작업 바로가기">
  <a href="#map-workbench"><small>공간</small><strong>맵·피스 설계실</strong><span>필수 기준점과 랜덤 보조 시설 시험</span></a>
  <a href="#balance-workbench"><small>시험</small><strong>수치·그래프</strong><span>전투 DPS와 전체 밸런스 비교</span></a>
  <a href="#planning-queue"><small>할 일</small><strong>요청·완료 목록</strong><span>요청 ID, 상태, 수락 근거 확인</span></a>
  <a href="#proposal-draft"><small>전달</small><strong>기획 초안 작성</strong><span>Notion에 옮길 제안 만들기</span></a>
  <a href="#current-scope"><small>현재 게임</small><strong>구현 범위 확인</strong><span>완료 기능과 미정 정책 구분</span></a>
  <a href="#item-balance"><small>데이터</small><strong>아이템·시트</strong><span>추가 방법과 입력 규칙</span></a>
  <a href="#notion-authoring"><small>처음이라면</small><strong>작성 가이드</strong><span>확정·임시·변경 작성 예시</span></a>
</nav>

<p class="sfh-workspace-notice">기획 확정 → 오너 판단 → 구현·검증 → 배포. 수치 시험이나 초안 작성만으로 게임이 바뀌지는 않습니다.</p>

<details class="sfh-workspace-block" markdown="1" id="map-workbench">
<summary>맵·피스 설계실 <small>시드 비교 → 필수 피스 → Notion 제안</small></summary>

## 익힐 수 있는 지역 맵 만들기

**새 기준: B 복합 구역 + A 불규칙 바닥 + C 난이도 1~10.** 도로에서 모든 방에 바로 들어가는 구조를 없앴습니다. 위 설계실에서 위험 단계별 공간 형태·투입 배수를 비교하세요. [임시 수치·Difficulty 시트·기획 판단 기준](../features/extraction-district.md#compound-20260909). ‘입구를 찾고 퇴로를 기억할 수 있는가’를 기획 사유와 수락 기준으로 적어 주세요.

같은 지역·규모에서 큰길과 필수 건물의 위치·크기·출입 방향은 유지하고, 주변 보조 시설을 바꿉니다. **다른 시드**로 반복 비교한 뒤 공간을 선택해서 피스 규칙을 시험하세요. 건물 이름이 치료·상점·전용 드랍 기능까지 뜻하지는 않습니다.

<div data-sfh-map-workbench data-catalog="../../assets/map-catalog.json">맵 자료 준비 중…</div>

[맵 규칙·Facility 입력·검증 범위](../features/extraction-district.md#regional-map). 초안은 이 화면에만 있으며 자동 공유·저장되지 않습니다. Notion에 붙여 넣고 오너 판단을 요청하세요.

</details>

<details class="sfh-workspace-block" markdown="1">
<summary>변경 사유 <small>공간·탈출 정책이 달라진 이유</small></summary>

## 이번 공간·탈출 변경의 기획 사유 {#extraction-rationale}

**9/9 최종 배치:** 도시 골격 위에 제한된 구역 입구·불규칙 실내·내부 연결을 적용했고 전방위 서비스 마당은 제거했습니다. 건물 용도·필수 위치는 Facility, 단계별 투자·능력치·윤곽 비율은 Difficulty로 제안하세요. 가구·적을 포함하지 않는 맵 미리보기와 실제 플레이 수락은 다릅니다. [변경·임시값·판단 기준](../features/extraction-district.md#compound-20260909).

**모든 방을 청소하는 게임보다, 언제 더 들어가고 언제 가지고 나올지 고르는 게임으로 바꿉니다.** 일반 건물에서는 싸우다가 나올 수 있고, 더 받고 싶으면 금고 단말을 눌러 스스로 봉쇄전을 선택합니다. 출구 2곳을 처음부터 사용할 수 있지만 직접 가서 방어해야 합니다.

건물 전체가 보이는 시야는 방 내부 상황을 한 번에 읽게 하려는 선택입니다. 건물을 나오면 그 안의 적과 물건은 숨고 지형만 기억합니다. 원작의 에셋을 가져오거나 원작과 같은 전투 규칙을 강제하는 뜻은 아닙니다.

- **오너 승인:** 순환 도로·복수 출입구·일반 후퇴·선택 금고·두 출구·공간 공개. [현재 규칙](../features/extraction-district.md).
- **기획자 제안 필요:** 시설별 위험/자원 가중치, 첫 회수까지 시간, 금고 도전률, 출구까지 이동 시간. Facility 5개 피스와 배치 수치는 임시값입니다. 의료 구역이라는 이름만으로 치료 아이템 전용 드랍이 구현된 것은 아닙니다.
- **작성 예:** `[임시] 창고 cache_weight=1.4. 초보가 위험한 중심 금고 없이 3분 안에 소액 회수하는지 확인. 성공률/이동 시간을 근거로 오너에게 확정 요청.`
- [시트 입력 방법](../getting-started/planner-item-balance-tutorial.md#facility) · [자동 검사와 인간 플레이 잔여](../quality/e2e-play-session.md#extraction-district). 노션과 충돌하는 옛 방 봉쇄·시간 대기는 오너 승인 변경으로 따로 기록하며 노션 체크박스를 임의로 바꾸지 않습니다.

</details>

<details class="sfh-workspace-block" markdown="1" open>
<summary>수치 실험실 <small>계산기를 골라 시험하고 확정본 전달</small></summary>

## 수치로 전투 난이도 비교하기

[무기·스킬 DPS 실험실 열기](../tools/dps-lab.md) — 계산 범위와 실제 전투와의 차이를 확인합니다. 아래에서 직접 시험하고 기획 확정본을 전달할 수 있습니다.

**장비를 실제로 끼워서 비교하기:** 계산기의 ‘장착 시뮬레이터’를 열고 캐릭터 → 무기 파츠·모듈 → 방어구·캐릭터 모듈을 고릅니다. 강화 단계·품질·소켓 비용을 함께 검사합니다. 파츠를 넣었는데 DPS가 그대로라면 현행 코드에서 직접 피해에 연결되지 않은 항목인지 경고를 확인하세요. ‘스킬별 피해 · 캐릭터 생존 그래프’에서 스킬마다 같은 초기 AP를 가진 독립 결과와 연속 피격 HP를 볼 수 있습니다. 이는 여러 스킬을 동시에 사용한 합계가 아닙니다. 확정 전 장착 조건·적 조건·그래프를 함께 검토하세요.

## 수치 조정과 확정 그래프 {#balance-workbench}

<details markdown="1">
<summary>효과·스탯 툴킷 · 노션 명세와 시트 입력안 만들기</summary>

대상과 효과를 선택하고 수치를 지정하면 구현 변수를 확인하고 Notion 작성문을 생성합니다. [작성 규격·신규 효과 요청](../tools/effect-toolkit.md). 새 Sheet **EffectGuide**는 선택 사전, **EffectSpec**은 요청 명세입니다. 원본 Weapon·Character·Skill·Upgrade와 별개이며 승인 전 게임 값을 덮어쓰지 않습니다.

<div data-sfh-effect-toolkit data-catalog="../../assets/effect-toolkit.json">효과·스탯 자료 읽는 중…</div>

</details>

### 선택한 대상 하나의 성장률

무기·캐릭터·방어구를 각각 하나씩 선택해 **동일 대상의 단계별 성능 변화**를 확인합니다. 가로축은 다른 아이템이 아니라 강화 단계/레벨입니다. 1단계 대비 증가량·성장률을 함께 표시합니다. 기획자는 단계별 목표값을 시험·확정할 수 있습니다. [계산 조건과 사용법](../tools/balance-workbench.md#growth).

<details markdown="1" open>
<summary>무기 하나의 성장 추이</summary>
<div data-sfh-growth-lab data-kind="weapon" data-editable data-catalog="../../assets/dps-catalog.json">성장 추이 읽는 중…</div>
</details>

<details markdown="1">
<summary>캐릭터 하나의 성장 추이</summary>
<div data-sfh-growth-lab data-kind="character" data-editable data-catalog="../../assets/dps-catalog.json">성장 추이 읽는 중…</div>
</details>

<details markdown="1">
<summary>방어구 하나의 성장 추이</summary>
<div data-sfh-growth-lab data-kind="armor" data-editable data-catalog="../../assets/dps-catalog.json">성장 추이 읽는 중…</div>
</details>

**① 한 대상 선택 → ② 성장 추이·목표값 검토 → ③ Notion 사유 작성 → ④ 기획 확정본 저장.** 오너 승인·게임 데이터 반영·배포는 별도입니다.

<details markdown="1">
<summary>무기·스킬·적·AP 계산기</summary>
<div class="dps-lab" data-sfh-dps-lab data-confirmable data-catalog="../../assets/dps-catalog.json">계산기 준비 중…</div>
</details>

<details markdown="1">
<summary>무기 거리별 DPS · 곡선 수정·확정</summary>

[거리 곡선 규칙과 새 무기 작성 양식](../features/weapon-distance.md). 곡선 숫자와 파츠·모듈을 변경해 비교하고, 검토한 그래프를 명시적으로 확정합니다. **현재 값은 임시 정책**이며 새 무기는 이번 작업에서 추가하지 않았습니다.

<div data-sfh-distance-lab data-editable data-catalog="../../assets/dps-catalog.json">거리 곡선 읽는 중…</div>

</details>

<details markdown="1">
<summary>시설·회수·성장·강화·아이템 등 전체 수치 비교</summary>
<div data-sfh-balance-workbench data-catalog="../../assets/balance-catalog.json">수치 목록 준비 중…</div>
</details>

[수치 실험·확정 전달 사용법](../tools/balance-workbench.md). 전체 목록은 현행 CSV의 숫자 열을 비교합니다. 지원하지 않는 효과를 임의로 DPS로 환산하지 않습니다. 시설·회수 계산기의 기본값은 **시나리오 예시**이며 현재 작전의 실제 계약을 자동 불러오는 값이 아닙니다.

</details>

<details class="sfh-workspace-block" markdown="1">
<summary>기획·구현 대조 <small>최신 확인 기준과 남은 범위</small></summary>

## 최신 기획과 실제 구현 상태

[최신 GDD](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed)는 규칙을, [66개 작업 트래커](https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2)는 요청 상태를 관리합니다. 노션에서 미구현이어도 게임에는 이미 있을 수 있습니다. [코드 대조와 오너 판단표](../design/master-gdd-alignment.md)를 먼저 확인하세요.

새 회복·파우치·심층·버서커 정책은 아직 게임에 적용하지 않았습니다. 기획자는 허용/금지/예외와 수락 기준을 제안하고, 프로젝트 오너가 기존 규칙을 바꿀지 결정합니다.

**2026-09-07 재확인:** 공개 원문의 내용 변경은 없습니다. 66행 중 구현 근거 38, 부분 7, 새로 만들어야 하는 항목 6, 기존 규칙 충돌 1, 기획 판단 대기 14입니다. **73.2%는 기획 요구에 대한 코드 대응도**이지 플레이 완성도·재미 점수가 아닙니다.

- [게임에 있는 것과 아직 없는 것](../design/master-gdd-alignment.md#current-classification): 부분 7행의 남은 조건까지 짧게 확인합니다.
- [노션에 세부 규격이 없는 기존 기능](../design/master-gdd-alignment.md#implemented-outside-notion): 가방 회전·모바일·방 전투/시야·추격 보스 등 9묶음. 삭제 요청이 아니라 기획에 정식 편입할지 판단할 목록입니다.
- **2026-09-09 승인 반영 80.3%:** 기획66항목 중 구현45·부분1·미구현6·미정14입니다. 바닥을 그리는 기술을 더 빠른 청크 텍스처로 바꾼 것을 오너가 수락했습니다. 실제 TileMapLayer를 사용한다는 뜻은 아닙니다. 남은 부분 대응은 배포본 실제 플레이 검수입니다. [계산·변경 이유](../design/master-gdd-alignment.md#day-close).
- 훈련 수치 동등성 수정 후 다음은 배포판 실제 플레이 검수 → 정책 선택 → 파우치·보존 정산 → 심층3경로 → 혈전 순서입니다. [현재 작업표](../design/current-milestone-workline.md#next-20260910). 미구현 기능은 선행 정책 승인이 필요하며 하루에 모두 끝난다는 뜻은 아닙니다.

<a class="sfh-article-entry" href="#planner-start"><strong>기획 작성 가이드부터 시작하기 →</strong><small>객체를 고르고 관계와 플레이 결과를 적으면 개발 근거와 연결됩니다.</small></a>

</details>

<details class="sfh-workspace-block" markdown="1">
<summary>게임과 기획 구조 이해 <small>처음 읽는 사람을 위한 안내</small></summary>

<section class="sfh-role-console is-planner sfh-role-workspace">
  <header><span class="sfh-kicker">PLANNER ROOM · PLAIN LANGUAGE</span><h2>이 게임을 처음 봐도 여기서부터 읽으면 됩니다</h2><p>SFH는 거점에서 장비를 고르고, 위험한 지역에 들어가 전리품을 모은 뒤, 살아서 탈출해 다음 출격을 준비하는 탑다운 액션 게임입니다.</p></header>
  <div class="sfh-plain-loop" aria-label="플레이 흐름 다섯 단계">
    <span><i>1</i><b>준비</b><small>요원·장비·지역 선택</small></span>
    <span><i>2</i><b>진입</b><small>비용을 내고 작전 시작</small></span>
    <span><i>3</i><b>전투</b><small>방을 확보하고 적 처치</small></span>
    <span><i>4</i><b>회수</b><small>전리품을 챙겨 탈출</small></span>
    <span><i>5</i><b>성장</b><small>거점에서 다음 런 준비</small></span>
  </div>
</section>

## 팔란티어식 구조를 기획에 어떻게 쓰나요? {#planner-start}

어려운 데이터 용어를 외울 필요는 없습니다. SFH에서는 **게임 안의 실제 대상**, **대상 사이의 규칙**, **플레이어가 일으키는 변화**, **그 판단의 근거**를 서로 연결해 두는 방식입니다. 공식 개념의 객체·관계·행동·권한을 프로젝트 규모에 맞게 축소했으며, Palantir 제품이나 자동 의사결정 시스템을 도입한 것은 아닙니다.

<div class="sfh-planner-ontology" aria-label="기획자가 사용하는 온톨로지 네 요소">
  <article><i>OBJECT · 무엇</i><b>플레이어가 만나는 대상</b><p>무기, 방어구, 적, 방, 작전, 보상, 상점처럼 이름과 고유 ID가 필요한 대상입니다.</p></article>
  <article><i>LINK · 어떤 관계</i><b>왜 함께 움직이는가</b><p>무기가 스킬을 허용하고, 지역이 드랍 표를 선택하며, 페널티가 보상 배율을 높이는 연결입니다.</p></article>
  <article><i>ACTION · 무슨 변화</i><b>입력 뒤 무엇이 달라지는가</b><p>획득, 장착, 강화, 처치, 방 확보, 탈출처럼 시작 조건과 성공·실패 결과가 있는 행동입니다.</p></article>
  <article><i>EVIDENCE · 왜 맞는가</i><b>판단을 재현하는 근거</b><p>Notion 의도, Sheet 후보값, 확정 CSV, 플레이 영상·E2E 결과를 같은 요청 ID로 연결합니다.</p></article>
</div>

기획자가 만드는 것은 ‘완성 코드’가 아니라 **오너가 판단할 수 있는 설명 가능한 객체**입니다. 개발자는 이를 구현·검증 근거에 연결하고, 프로젝트 오너가 범위·우선순위·수락·출시를 최종 확정합니다. [운영 온톨로지의 공식 개념 참고](https://www.palantir.com/docs/foundry/ontology/overview)

### 새 기획을 적는 가장 짧은 순서

<div class="sfh-planner-gates">
  <article><i>01 · 대상</i><b>객체 하나를 먼저 고릅니다</b><p>“전투를 개선” 대신 “추격 보스의 등장 경고”처럼 플레이어가 구분할 수 있는 대상으로 좁힙니다.</p></article>
  <article><i>02 · 관계·행동</i><b>조건→변화→결과를 적습니다</b><p>무엇이 이 기능을 시작하고, 어떤 상태를 바꾸며, 성공·실패 때 무엇이 남는지 씁니다.</p></article>
  <article><i>03 · 수락</i><b>사람 눈에 보이는 완료를 적습니다</b><p>수치나 파일명이 아니라 플레이어가 어떤 입력 뒤 무엇을 보고 다음 행동을 할 수 있는지 씁니다.</p></article>
</div>

### 기획 제출 전 6문항

1. **대상:** 어떤 플레이어·적·아이템·화면·작전 규칙인가?
2. **발동 조건:** 어떤 입력이나 상태가 행동을 시작하는가?
3. **결과:** 성공과 실패 때 화면·저장·재화가 각각 어떻게 되는가?
4. **관계:** 어떤 기존 장비·스킬·드랍·성장·UI와 연결되거나 충돌하는가?
5. **미정:** 아직 모르는 수치·예외·운영 정책은 무엇인가?
6. **수락 기준:** 처음 플레이한 사람이 무엇을 보면 구현됐다고 느끼는가?

하나라도 비어 있으면 개발자는 임의 확정하지 않습니다. `미정`으로 남겨 시험 가능한 기본값과 작업 금지 범위를 분리하고, 프로젝트 오너 판단 대기열에 연결합니다.

</details>

<details class="sfh-workspace-block" markdown="1">
<summary>아이템·데이터 입력 <small>시트 추가와 수치 변경 방법</small></summary>

## 아이템 추가·밸런싱 처음 하기 {#item-balance}

**① 표에서 대상 찾기 → ② 하나씩 시험하기 → ③ Notion 확정 후 개발자에게 CSV 배포 요청.**

- [기존 무기 수치 바꾸기](../getting-started/planner-item-balance-tutorial.md#balance): 소총 피해 예제로 시작합니다.
- [새 아이템 추가하기](../getting-started/planner-item-balance-tutorial.md#new-item): 행 복사 → 새 ID → 실제 효과·드랍 연결 → 플레이 확인.
- [탭 선택과 전체 튜토리얼](../getting-started/planner-item-balance-tutorial.md): 단위, 성장, 드랍, 시즌 보상, 오류와 되돌리기.

시트는 1행 변수명·2행 설명·3행부터 데이터입니다. **Armor와 새 아이템 효과는 행 입력만으로 게임에 생성되지 않습니다.** 상세 튜토리얼에서 기획자 작성과 개발자 연결 작업을 구분했습니다.

</details>

<details class="sfh-workspace-block" markdown="1">
<summary>현재 게임·장비 획득 <small>완료 기능과 임시 드랍 정책</small></summary>

## 현재 변경과 완료 범위 {#current-scope}

**P6 마감 확인:** 시즌 신규 기본값은 대형/페널티 10점입니다. 이미 시작한 구 시즌은 마감까지 기존 조건을 유지합니다. 3대 기록·시즌 마감·칭호/오라는 로컬에서 검증했으며, 실제 계정 서버·서버 검증 지급은 아직 아닙니다. [완료/남은 범위](../features/ranking-provider.md#p6-closeout)를 구분해 두었습니다.

**이번 변경:** 무기 5종에 같은 무기라면 항상 같은 명중 누적 고유 스킬을 부여하고, 무기·방어구 기본 옵션과 제작·드랍 옵션을 성장·모듈에서 분리했습니다. Weapon/Armor Sheet의 이름·발동 횟수·고정 피해·옵션 값은 아직 임시이므로 [장비 고정 정체성 표](../features/equipment-fixed-identity.md)를 보고 확정이 필요합니다.

<div class="sfh-role-status-grid">
  <article><span>완료</span><b>거점과 작전</b><p>거점의 게이트에서 작전 조건을 고르고 전장에 들어간 뒤 결과와 함께 돌아옵니다.</p></article>
  <article><span>완료</span><b>전투와 방 확보</b><p>자동 공격과 세 가지 스킬로 싸우고, 방의 적을 모두 쓰러뜨리면 문과 보상이 열립니다.</p></article>
  <article><span>완료</span><b>파밍과 탈출</b><p>아이템을 비교·획득·교체하고 탈출 성공 여부에 따라 보관·환전·소실 결과가 나뉩니다.</p></article>
  <article><span>완료</span><b>장비와 거점 성장</b><p>무기·방어구·파츠·모듈·상점·제작·훈련·도감을 한 준비 흐름에서 사용합니다.</p></article>
  <article><span>로컬 완료</span><b>기록과 제출 준비</b><p>성공 기록은 내 기기에 남습니다. 제출·재시도 계약은 있지만 실제 계정 서버와 정상 플레이를 검증하는 운영 서버는 아직 없습니다.</p></article>
</div>

<p class="sfh-role-explain"><b>“완료”의 뜻</b><span>코드 파일이 있다는 뜻이 아니라, 플레이어가 입력하고 화면 변화를 확인하며 다음 행동까지 이어갈 수 있고 자동 테스트가 그 흐름을 통과했다는 뜻입니다.</span></p>

## 작전에서 무기·방어구를 얻는 방식 {#equipment-drop-flow}

**현재 무기와 방어구는 실제 작전 지도에 떨어지고, 플레이어가 직접 주워 가방에 넣거나 현장에서 교체할 수 있습니다.** 다만 모든 적이 장비를 떨어뜨리는 방식은 아닙니다. 장비를 얻는 핵심 지점은 **방 확보 보상**과 **보스 보상**입니다.

<div class="sfh-role-status-grid">
  <article><span>일반 적</span><b>자원 중심</b><p>일반 적 처치 시 현장 전리품은 12% 확률로 시도됩니다. 현재 후보는 크레딧·룬·코어 같은 자원이며 무기와 방어구는 직접 나오지 않습니다.</p></article>
  <article><span>방 확보</span><b>장비 순환 보상</b><p>방의 적을 모두 처치하면 문이 열리고 보상이 생성됩니다. 완료한 방 수에 따라 무기→방어구→모듈→파츠 순으로 보상 종류를 보정합니다.</p></article>
  <article><span>추격 보스</span><b>2회 무작위 추첨</b><p>보스 처치 시 전리품 2개를 추첨합니다. 무기·방어구·모듈·파츠가 같은 후보군에 있으므로 무기와 방어구가 매번 함께 나온다는 보장은 없습니다.</p></article>
  <article><span>도면</span><b>직접 장비와 별개</b><p>돌격소총 도면·전술 조끼 도면은 장비 자체가 아니라 제작·해금용 전리품입니다. 이름이 비슷해도 즉시 장착되는 무기·방어구와 구분합니다.</p></article>
</div>

### 현재 직접 획득 가능한 장비

| 획득처 | 무기 | 방어구 | 알아둘 점 |
|---|---|---|---|
| 방 확보 보상 | 돌격소총, 제식 권총, 대검 | 전술 조끼, 러너 부츠 | 네 종류 순환 보정으로 한 판에서 장비·모듈·파츠를 고르게 시험합니다. |
| 산업 지구 특수 보상 | 펄스 소총 | — | 현재 중형·베테랑 조건의 현장 교체 검증용 임시 배치입니다. |
| 보스 보상 | 돌격소총 포함 | 전술 조끼 포함 | 보스당 2개를 무작위 추첨하며 장비 외 후보도 함께 존재합니다. |
| 일반 적 | 없음 | 없음 | 크레딧·룬·코어 등 소형 전리품만 후보입니다. |

전투 단검은 장비 정의와 장착 규칙은 있지만 현재 실제 드랍 후보에는 없습니다. 위 표의 목록·지역·등급·가중치는 플레이 검증을 위한 **임시값**입니다.

### 주운 뒤에는 이렇게 처리됩니다

1. 전리품 근처에서 `F`를 누르면 이번 작전 가방에 들어갑니다. 가방이 가득 찬 경우 일부만 사라지지 않고 획득 전체가 취소됩니다.
2. 장비 비교 화면에서 허용되는 경우 `R`로 즉시 장착할 수 있습니다. 기존 장비는 이번 작전 임시 보관으로 이동하며 거점 복귀 때 복원됩니다.
3. 살아서 탈출하면 주운 장비가 영구 창고로 이동합니다.
4. 사망하거나 작전에 실패하면 이번 작전에서 주운 장비를 잃습니다.
5. 실제 자동 검사는 무기→방어구→모듈→파츠 획득, `I` 가방 장착, 탈출 정산과 영구 창고 반영까지 플레이어 입력으로 확인합니다.

### 기획자가 다음으로 제안할 항목

- 일반 적도 낮은 확률로 무기·방어구를 떨어뜨릴지, 지금처럼 방과 보스에 집중할지
- 방 보상 순환 순서와 한 판에서 기대하는 무기·방어구 수량
- 보스의 장비 확정 여부, 등급, 지역별 후보와 가중치
- 현장 즉시 장착을 계속 허용할지, 가방 보관 뒤에만 장착하게 할지
- 전투 단검과 이후 추가 장비의 지역·난이도·획득처

확정할 때는 [지역·난이도 드랍 표](../features/loot-tables.md), [전리품 생명 주기](../features/loot-lifecycle.md), [현장 비교·획득](../features/field-loot-acquisition.md)을 함께 보고 Notion에 **획득처 / 대상 장비 / 등급 / 확률 또는 가중치 / 성공·실패 결과**를 남기면 됩니다.

</details>

<details class="sfh-workspace-block" markdown="1">
<summary>Notion 작성 가이드 <small>상태·근거·변경 예시</small></summary>

## Notion에 어떻게 적어야 개발에 반영되나요? {#notion-authoring}

**완성된 기획서가 아니어도 됩니다.** 대신 `확정 / 임시 / 제안 / 보류 / 변경 / 검수 완료` 중 기획안의 성숙도를 먼저 쓰고, 모르는 값은 빈칸 대신 `미정`이라고 적어 주세요. 이 표시는 기획자의 제안 상태이며 프로젝트 최종 승인을 뜻하지 않습니다. 개발자는 적혀 있지 않은 규칙을 확정값으로 추측하지 않고, 프로젝트 오너가 개발자 판단 콘솔에서 범위·우선순위·수락 여부를 결정합니다.

| 상태 | 뜻 | 개발자가 처리하는 방식 |
|---|---|---|
| `확정` | 기획자가 이 규칙과 수치를 최종 후보로 제출 | 오너 판단 대상으로 올리고 승인 뒤 구현·E2E·위키·PR에 반영 |
| `임시` | 지금은 이 값으로 시험해도 됨 | 나중에 교체 가능한 Resource/Sheet/CSV/Policy로 구현하고 `provisional` 유지 |
| `제안` | 비교하거나 의견을 받고 싶음 | 구현하지 않고 선택지·영향·필요 결정을 정리 |
| `보류` | 아직 만들지 않음 | 코드·데이터 변경을 멈추고 보류 이유와 재개 조건만 추적 |
| `변경` | 이전 결정을 새 결정으로 교체 | 이전 결정 ID, 변경 전→후, 기존 저장·세이브 영향과 되돌리기 검사 |
| `검수 완료` | 기획자가 구현 결과와 의도가 맞음을 확인 | 화면·빌드·검수 근거를 오너에게 제공하며 최종 수락은 오너가 전환 |

### 작성 뒤 반영 가능 상태를 판단하는 법

- **오너 확정 검토 가능:** `확정`이며 대상·결정·적용 시점·수락 기준이 있고, 수치 단위와 충돌하는 이전 결정이 정리됨
- **임시 시험 가능:** `임시` 또는 `부분 확정`이며 시험할 대상과 플레이 결과는 분명하고, 바뀔 값이 `미정` 목록에 있음
- **결정 필요:** 상태가 없거나 대상·결과를 알 수 없음, 서로 다른 결정이 충돌하지만 `supersedes`가 없음
- **작업 금지:** `제안` 또는 `보류`. 비교·기록만 하고 기능과 데이터는 바꾸지 않음

기획자 작업실의 **기획 제안 초안 만들기**는 입력한 상태와 필수 항목을 기준으로 `정식 구현 검토 가능 / 시험 구현 가능 / 결정 필요 / 작업 금지`를 초안 안에 표시합니다.

### 최소한 이 5줄만 적어 주세요

기존 요청이면 위키 카드의 `PLAN-*` 또는 `DATA-*` ID를 그대로 씁니다. 새 아이디어라 ID가 없으면 `DRAFT-날짜-키워드`로 시작해도 됩니다. 다음 개발 작업에서 정식 요청 ID와 연결합니다.

~~~text
## [요청 ID][상태] 한 줄 제목
- 대상: 어느 화면 / 아이템 / 적 / 규칙인가
- 결정: 플레이어에게 무엇이 어떻게 일어나야 하는가
- 미정: 아직 결정하지 못한 값과 예외
- 적용 시점: 즉시 / 다음 빌드 / 다음 시즌 / 미정
- 확인 방법: 플레이어가 무엇을 보면 성공인지
~~~

한 결정 안에 상태가 섞여 있으면 제목을 `[부분 확정]`으로 쓰고 본문을 `확정`, `임시`, `미정`으로 나눕니다. **프로젝트 오너가 수락한 확정 줄만 최종 기준으로 계산**하고, 임시 줄은 교체 가능한 기본값으로 구현하며, 미정 줄은 판단 대기 목록에 남깁니다.

### 장비 드랍을 대충 적기 시작하는 예시

아래 숫자와 이름은 형식 설명용이며 실제 게임 확정값이 아닙니다.

~~~text
## [DRAFT-20260904-ROOM-LOOT][부분 확정] 방 클리어 장비 보상
- 대상: 일반 전투 방을 모두 정리했을 때 생기는 보상
- 확정: 방을 클리어하면 최소 1개 보상 오브젝트가 보여야 한다
- 임시: 무기 → 방어구 → 모듈 → 파츠 순서로 시험한다
- 미정: 맵 크기별 수량, 등급 가중치, 같은 아이템 중복 허용 여부
- 적용 시점: 다음 테스트 빌드
- 확인 방법: 문이 열린 뒤 보상이 생성되고 F로 가방에 넣을 수 있다
- 성공 결과: 탈출하면 영구 창고로 이동
- 실패 결과: 사망하면 이번 작전 획득물을 잃음
- Sheet 대상: LootTable / Item / Weapon / Armor
~~~

이 정도만 적혀도 개발자는 **보상 발생 자체는 확정**, 순환 순서는 **임시 데이터**, 수량·등급·중복은 **추가 결정 필요**로 나눌 수 있습니다.

### 수치까지 확정하는 예시

~~~text
## [DATA-EXAMPLE-01][확정 예시] 보스 장비 보상
- 대상: 추격 보스 최초 처치 보상
- 결정: 보스 후보군에서 2회 독립 추첨한다
- 단위와 범위: 보상 2개 / 중복 허용 / 장비 확정 보장 없음
- 예외: 가방이 가득 차면 바닥에 유지하고 자동 폐기하지 않음
- 적용 시점: 다음 빌드부터
- 확인 방법: 동일 조건 20회 시험에서 항상 2개가 생성되고 후보 밖 ID가 나오지 않음
- 근거: 플레이어가 위험 증가를 감수한 결과를 즉시 알아야 함
- 되돌릴 값: 현재 배포 CSV
~~~

실제 확정에는 `확정 예시`가 아니라 `확정`을 쓰고, 확률에는 `%` 또는 가중치, 거리에는 `px`, 시간에는 `초`, 비용에는 `C`처럼 단위를 붙입니다. 수치가 많으면 Notion에는 의도와 범위를 적고 Google Sheet의 정확한 탭·ID·열을 연결합니다.

### 이미 쓴 내용을 바꾸는 예시

~~~text
## [DATA-EXAMPLE-02][변경 예시] 방어구 보상 가중치 변경
- supersedes: DATA-이전결정-ID
- 변경 전 → 후: 전술 조끼 가중치 10 → 7
- 이유: 같은 방어구가 지나치게 자주 반복됨
- 기존 저장 영향: 이미 획득한 장비는 유지
- 적용 시점: 다음 CSV 배포부터
- 확인 방법: 후보표·브리핑·실제 드랍이 같은 버전을 표시
- 되돌릴 값: 가중치 10
~~~

이전 문장을 조용히 덮어쓰지 말고 새 변경 블록을 아래에 추가합니다. 날짜가 더 최신이고 `supersedes`로 이전 ID를 가리키는 결정만 새 기준으로 사용합니다.

### 작성 뒤 실제 반영 순서

1. 게시된 SFH Notion에 위 형식으로 적습니다. **Notion 저장만으로 자동 배포되지는 않습니다.**
2. 작업을 요청할 때 `노션 최신 내용 확인 후 [요청 ID] 반영`이라고 알려 주세요.
3. AI 개발자는 공개 Notion 원문과 이전 스냅샷을 비교하고 상태·요청 ID·최신 변경 관계를 확인합니다.
4. `확정`은 오너 승인 후보, `임시`는 교체 가능한 시험값, `제안/보류`는 구현하지 않는 항목으로 분리합니다.
5. 새 목록이 필요하면 Google Sheet를 확장하고 실시간 시험→확정 CSV 구조를 유지합니다.
6. 실제 플레이 입력과 화면 결과 E2E, Web·Windows 동일 빌드, 위키 업데이트를 통과한 뒤 PR로 병합합니다.
7. 결과가 맞으면 Notion에 `검수 완료`와 확인한 빌드 또는 화면 근거를 남기고, 프로젝트 오너가 개발자 판단 콘솔에서 최종 수락합니다.

작성 중 충돌하거나 빠진 값이 있으면 개발자는 임의로 확정하지 않고 프로젝트 오너 판단 콘솔의 **오너 판단 필요** 항목으로 돌려놓습니다.

</details>

<details class="sfh-workspace-block" markdown="1">
<summary>검토할 정책 후보 <small>프로젝트 오너에게 제안할 내용</small></summary>

## 기획자가 제안하고 프로젝트 오너가 판단할 것

<div class="sfh-decision-lanes">
  <a href="../../design/planner-request-workflow/"><small>후보 제안</small><b>실서비스 랭킹 신원</b><span>현재 익명 기기 ID를 어떤 로그인 계정으로 교체하고, 어떤 서버가 최종 기록을 승인할지 후보와 영향을 작성합니다.</span><em>P6 LIVE</em></a>
  <a href="../../features/ranking-provider/#p6-closeout"><small>운영값 제안</small><b>시즌과 명예 보상</b><span>대형 조건·마감·로컬 1회 지급은 구현됐습니다. 기간·최소 점수·동점·상위 인원과 실서버 지급 정책 후보를 제출합니다.</span><em>P6 LOCAL</em></a>
  <a href="../../design/planner-request-workflow/"><small>수치 확정</small><b>상점·제작·훈련 데이터</b><span>현재 교체 가능한 임시값을 실제 가격·효과·회전 주기·레시피·계측 기준으로 확정해야 합니다.</span><em>SHEET</em></a>
  <a href="../../quality/five-moment-fun-proposal/"><small>승인 전 제안</small><b>한 판의 다섯 순간</b><span>교전·장비·강화·탈출·재도전의 의도와 인간 검수 계획을 보완합니다. 최종 채택은 오너가 판단합니다.</span><em>PROPOSAL</em></a>
</div>

</details>

<details id="planning-queue" class="sfh-home-drawer sfh-planner-requests" data-sfh-planner-requests>
  <summary><span><span class="sfh-kicker">DECISION QUEUE</span><b>실제 기획 요청·완료 근거 보기</b><small>담당·상태·수락 기준을 요청 ID로 추적합니다.</small></span><em>＋</em></summary>
  <div class="sfh-home-drawer__body">
    <div class="sfh-planner-requests__heading"><span class="sfh-planner-requests__status" data-sfh-planner-request-status>요청 목록 연결 중</span></div>
    <div class="sfh-planner-source" data-sfh-planner-source aria-live="polite">Notion 확인 시각을 불러오는 중</div>
    <p data-sfh-planner-request-instruction>요청 ID를 Notion 결정 제목에 함께 적어 주세요.</p>
    <div class="sfh-planner-filters" data-sfh-planner-filters aria-label="협업 요청 역할 필터">
      <button type="button" data-filter="all" aria-pressed="true">전체</button>
      <button type="button" data-filter="planner" aria-pressed="false">기획자 할 일</button>
      <button type="button" data-filter="ai_developer" aria-pressed="false">개발자 할 일</button>
      <button type="button" data-filter="complete" aria-pressed="false">검증 완료</button>
    </div>
    <div class="sfh-planner-requests__grid" data-sfh-planner-request-grid aria-live="polite"></div>
  </div>
</details>

<details id="proposal-draft" class="sfh-home-drawer sfh-proposal-composer" data-sfh-proposal-composer>
  <summary><span><span class="sfh-kicker">NOTION DRAFT</span><b>기획 제안 초안 만들기</b><small>브라우저 안에서만 작성하며 자동 전송하지 않습니다.</small></span><em>＋</em></summary>
  <div class="sfh-home-drawer__body">
    <p class="sfh-proposal-local-state">LOCAL ONLY · NO PUBLIC WRITE</p>
    <div class="sfh-proposal-grid">
      <label>종류<select name="kind"><option>PLAN</option><option>DATA</option><option>DEV</option><option>BUG</option></select></label>
      <label>상태<select name="status"><option>제안</option><option>임시</option><option>부분 확정</option><option>확정</option><option>보류</option><option>변경</option><option>검수 완료</option></select></label>
      <label>요청 ID<input name="request_id" placeholder="PLAN-P6-03-01"></label>
      <label class="is-wide">제목<input name="title" placeholder="무엇을 결정하는지"></label>
      <label class="is-wide">대상·범위<input name="scope" placeholder="어느 화면·아이템·적·규칙에 적용하는지"></label>
      <label class="is-wide">결정 내용<input name="decision" placeholder="플레이어에게 무엇이 어떻게 일어나야 하는지"></label>
      <label class="is-wide">미정·예외<input name="unknowns" placeholder="모르는 값은 비우지 말고 미정으로 작성"></label>
      <label>적용 시점<input name="applies_at" placeholder="다음 빌드 / 다음 시즌 / 미정"></label>
      <label>재검토 조건<input name="review_trigger" placeholder="플레이 20회 후 / 없음"></label>
      <label class="is-wide">작성 근거<input name="basis" placeholder="Notion Phase 또는 DEC ID"></label>
      <label class="is-wide">수락 기준<input name="acceptance" placeholder="플레이어가 확인할 결과"></label>
      <label class="is-wide">Sheet 대상<input name="sheet_target" placeholder="목록이 필요할 때만 작성"></label>
      <label class="is-wide">이전 결정 교체<input name="supersedes" placeholder="변경일 때만 이전 결정 ID 입력"></label>
    </div>
    <textarea data-sfh-proposal-output readonly aria-label="Notion에 붙여넣을 제안 초안"></textarea>
    <div class="sfh-proposal-actions"><button type="button" data-sfh-proposal-copy>초안 복사</button><span data-sfh-proposal-state>외부로 자동 전송하지 않습니다.</span></div>
  </div>
</details>

<details class="sfh-workspace-block" markdown="1">
<summary>전달 순서·관련 문서 <small>작성 이후 확인할 곳</small></summary>

## 오너에게 전달할 기획 근거를 남기는 방법

1. [기획 요청 목록](../design/planner-request-workflow.md)에서 결정할 요청 ID를 확인합니다.
2. Notion 제목에 같은 요청 ID를 적고, “무엇을 / 언제 / 어느 수치로” 적용할지 한 문장으로 확정합니다.
3. 목록형 수치가 필요하면 Google Sheet의 1행 변수명·2행 설명·3행 이후 데이터 규칙으로 작성합니다.
4. 개발 완료 뒤 [플레이어 인식 검수](../quality/player-perception-audit.md)에서 실제 화면 결과를 보고 수락합니다.

<nav class="sfh-role-console__grid" aria-label="기획자 핵심 문서">
  <a href="../../design/planner-request-workflow/"><b>제안·데이터 요청</b><span>기획자가 근거를 보완하고 오너에게 올릴 항목</span></a>
  <a href="../../design/master-gdd-alignment/"><b>기획 원본 대조</b><span>Notion 확정 내용과 구현 차이</span></a>
  <a href="../../quality/player-perception-audit/"><b>플레이 수락 검사</b><span>사람 눈에 보이는 완료 기준</span></a>
  <a href="../../development-status/"><b>완료된 변경</b><span>하루 단위 구현 결과와 검증</span></a>
</nav>

</details>
