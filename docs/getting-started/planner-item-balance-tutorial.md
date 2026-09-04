---
title: 기획자 튜토리얼 · 아이템 추가와 밸런싱
description: 시트의 어느 칸을 바꿀지부터 실시간 시험, 개발 요청, CSV 확정과 되돌리기까지
tags: [기획자, 아이템 추가, 밸런싱, Google Sheets, CSV, 튜토리얼]
---

# 기획자 튜토리얼 · 아이템 추가와 밸런싱

**코드를 몰라도 수치와 기획 의도를 작성할 수 있습니다.** 다만 시트에 이름을 적었다고 새로운 총이나 특수 효과가 저절로 생기지는 않습니다. 기획자는 **무엇을 바꿀지**, 개발자는 **게임에 연결·검증·배포**하는 일을 맡습니다.

[기획자 작업실로 돌아가기](../access/planner.md) · [공용 밸런스 시트 열기](https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/edit) · [Notion에 결정 남기기](https://wobbly-pawpaw-1ff.notion.site/SFH-6b45b728004082af8a4a811ef0a1c5e9)

2026-09-03에 실제 시트의 탭과 1·2행을 읽어 코드와 대조했습니다. 아래 수치는 **설명용 예시이며 이번 작업에서 시트 값을 바꾸지 않았습니다.**

## 1. 먼저 할 일 고르기 {#choose}

| 하고 싶은 일 | 여기부터 | 개발자 도움이 필요한 때 |
|---|---|---|
| 이미 있는 소총을 더 강하게 | [수치 조정 연습](#balance) | 지원하지 않는 새 효과·열을 추가할 때 |
| 새 무기·방어구·모듈·파츠 추가 | [새 아이템 등록](#new-item) | 실제 장비 정의·효과·가방 연결은 개발 작업 |
| 기존 물건이 더 자주 나오게 | [드랍 표 연결](#drop) | 새 획득 출처나 새 드랍 동작이 필요할 때 |
| 이번 판 강화·레벨별 능력 조정 | [성장과 시즌 보상](#growth) | 새로운 스탯/효과 종류를 만들 때 |
| 시험한 값을 정식 배포 | [확정과 되돌리기](#publish) | 개발자가 CSV 검증·PR·Web/Windows 배포 |

!!! warning "공용 시트는 연습장만은 아닙니다"
    다른 사람이 실시간 테스트 중이면 내 수정도 그 사람에게 적용될 수 있습니다. 먼저 시험 시간·대상 ID를 합의하세요. 시트에는 비밀번호·토큰·개인정보를 넣지 않습니다. 이 위키에 로그인해도 Google Sheet 편집 권한이 자동으로 생기지는 않습니다.

## 2. 표를 읽는 법 {#sheet}

- **1행 = 변수명:** 게임이 읽는 주소입니다. 이름·열 구조를 임의로 바꾸지 마세요.
- **2행 = 설명:** 단위와 허용 값을 읽습니다. 두 행은 이미 고정되어 있습니다.
- **3행부터 = 물건 하나씩:** 한 행 전체가 같은 물건입니다. 한 열만 따로 정렬하면 다른 물건의 수치가 섞입니다.
- **ID = 변하지 않는 이름표:** 화면 이름과 다릅니다. 예: `assault_rifle`은 ID, `돌격소총`은 표시 이름입니다. 출시된 ID를 이름 변경 용도로 고치거나 재사용하지 않습니다.
- **runtime_enabled = 사용 허용:** 이 열이 있는 탭에서 TRUE인 행만 해당 공급자가 읽습니다. FALSE는 기획 초안에 쓸 수 있지만, 참조 중인 기존 행을 끄면 드랍/장착 연결도 깨질 수 있습니다.

| 탭 | 무엇을 적나 | 적용 범위와 주의 |
|---|---|---|
| Weapon | 무기, 피해·발사 간격·사거리 | 지원하는 전투 열은 실시간. 태그·소켓·새 무기 정의는 개발 연결 필요 |
| Armor | 방어구, 기본 체력·방어·슬롯 | 현재는 정의 원본. **직접 실시간 로더 없음**; 수정 후 개발자에게 반영 요청 |
| Item | 모듈·파츠·소모품·크레딧·도면·런 자산 | 생명 주기 열은 실시간. 실물 효과·가방 칸·연결 Resource는 별도 정의 필요 |
| LootTable | 어디에서 무엇이 얼마나 나오는가 | 기존 정의 ID를 참조. 가중치는 확률 %가 아님 |
| RunBuff / Upgrade | 판 안의 강화 / 장비·모듈 레벨 효과 | [아래 성장 설명](#growth) 참고 |
| Skill / Character / Utility / OperationPreset | 스킬 / 요원 / 소모품 준비 / 추천 작전 | 이미 지원하는 ID·태그·정책 범위에서 작성 |
| ShopOffer / Recipe / TrainingScenario / Codex | 상점 / 제작 / 훈련 / 도감 | P7-01B 품질 실물·실제 수치와 P7-02 회전·리롤 연결 완료. 가격·배율·옵션·소켓·리롤 운영값은 기획 확정 필요 |
| SeasonReward | 칭호·오라 | 로컬 시즌의 외형 보상만. 다음 시즌부터 적용 |

Weapon의 기존 `run_investment_price` 열은 남아 있지만 **현재 로비에 장착한 무기를 출격 때 다시 구매·청구하지 않습니다.** 상점 가격과 혼동하지 마세요.

!!! warning "현재 Item 탭 정리 요청"

    2026-09-04 점검에서 `Item!A18:P21`에 `standard_field_pack`, `expanded_field_pack`, `shock_cell`, `emergency_extraction_beacon`이 중복 입력된 것을 확인했습니다. 이 4개는 이미 `Utility` 탭이 소유하므로 **Item에서 삭제하고 Utility 행만 유지**해야 합니다. 검증기는 `loot_family=utility`를 Item 스키마 오류로 차단하며, 정리 전 값은 CSV와 게임에 자동 반영하지 않습니다. 근거와 완료 조건은 기획 요청 `DATA-SHEET-ITEM-UTILITY-01`에 기록했습니다.

## 3. 연습 A · 기존 무기 수치 바꾸기 {#balance}

1. `Weapon` 탭에서 A열 `weapon_id`가 `assault_rifle`인 행을 찾습니다. 행 번호는 정렬하면 달라지므로 ID로 찾으세요.
2. H열 `damage`의 원래 값을 메모합니다. 예: **1.6 → 1.8**로 바꿔 “투사체 한 발을 약 12.5% 강하게” 시험합니다. 한 번에 하나만 바꿉니다.
3. F열 `runtime_enabled`가 TRUE인지 확인합니다. Google Sheet는 자동 저장되지만 **게임 배포가 된 것은 아닙니다.**
4. 로비 I/U에서 해당 무기를 장착하고 저장합니다. 동쪽 작전 게이트에 가서 F → 지역·규모 → 장착 확인 → **3단계 검토·투입의 실시간 테스트**를 선택합니다.
5. 작전에 들어가 같은 적·거리·장비·버프 조건에서 비교합니다. Weapon 공급자는 정상 연결 시 기본 3초 주기로 갱신합니다. **총 피해는 강화·모듈·치명타·적 방어의 영향도 받으므로 damage와 화면 숫자가 항상 같지는 않습니다.**
6. 원래 값과 새 값 각각의 처치 시간·발사 횟수·체감을 기록합니다. 화면 변화만으로 최신 시트 반영을 단정하지 말고, 불확실하면 개발자에게 소스 상태 확인을 요청합니다.
7. 좋으면 Notion에 변경 전/후 값과 이유를 확정하고 [CSV 반영 요청](#publish)을 보냅니다. 시험만 했다면 원래 값으로 되돌립니다.

### 자주 헷갈리는 숫자

| 변수/형태 | 예 | 뜻 |
|---|---|---|
| `damage` | 1.8 | 투사체 한 발의 기본 피해. 초당 피해가 아님 |
| `fire_interval_sec` | 0.78 → 0.6 | 간격이 짧아져 더 자주 공격함 |
| `critical_chance` | 0.05 | 5%. 숫자 5를 넣는 것이 아님 |
| `critical_multiplier` | 1.75 | 치명타일 때 1.75배 |
| `target_range_px` | 820 | 자동 탐지 거리, 픽셀 단위 |
| `*_add` | 15 | 기존 값에 더함 |
| `*_multiply` | 1 / 1.1 / 0.9 | 유지 / 10% 증가 / 10% 감소 |

곱셈의 “변화 없음”은 **1**, 덧셈의 “변화 없음”은 **0**입니다. 소수는 점으로 적고, 숫자 칸에 `10초`, `+10%`, `1,000 C` 같은 문장을 쓰지 않습니다. 허용 범위는 각 열 설명과 검증기를 따릅니다.

## 4. 연습 B · 새 아이템 등록하기 {#new-item}

예를 들어 **소총용 새 파츠**를 기획한다면 다음 순서입니다.

1. 먼저 “소총 전용 / optic 소켓 / 어떤 효과 / 가방 2×1 / 어디서 드랍 / 탈출·사망 결과”를 Notion에 적습니다.
2. Item의 기존 `rifle_scope_item` 행 **전체를 복사해 마지막 데이터 아래 새 행에 붙입니다.** 복사본부터 `runtime_enabled=FALSE`로 두세요. 기존 행은 지우지 않습니다.
3. 새 `item_id`(예: `rifle_scope_mk2_item`), 표시 이름, 설명을 적습니다. 이 ID는 예시이며 실제 추가 여부·중복 검사는 개발자와 확인합니다.
4. `linked_resource`는 파일 업로드 칸이 아니라 실제 효과 정의를 가리키는 ID입니다. 새 파츠라면 개발자가 대응 Resource를 만들고, 소총 소분류·optic 소켓 제약과 인벤토리 카탈로그에 연결해야 합니다.
5. [LootTable](#drop)에 드랍 초안을 FALSE로 작성합니다. 상점·제작에도 필요하면 ShopOffer·Recipe의 해당 연결을 함께 요청합니다.
6. 개발자가 정의·태그·가방·드랍을 연결하고 검증한 뒤 관련 행을 함께 활성화합니다. 하나만 먼저 켜면 없는 ID 참조로 새 표가 거부될 수 있습니다.
7. 실제 **획득 → I 가방 → 장착/교체/해제 → 탈출 반출 → 재실행 복원**, 그리고 사망 시 소실을 확인한 뒤 완료로 표시합니다.

### 종류별로 추가로 필요한 것

| 종류 | 원본 탭 | 반드시 함께 확인할 연결 |
|---|---|---|
| 무기 | Weapon | WeaponDefinition, 장착 태그, 현장 카탈로그, 전투 수치, 필요 시 Upgrade·LootTable |
| 방어구 | Armor | ArmorDefinition, 슬롯·스탯, 현장 카탈로그, 필요 시 Upgrade·LootTable |
| 모듈·고유 파츠 | Item | 실제 효과 Resource, 모듈 코스트/태그 또는 파츠 소분류/소켓, 가방 정의 |
| 크레딧·도면 | Item | 지갑 또는 영구 해금 정책, 드랍 표; 새 도면의 해금 대상·제작 연결 |
| 룬·코어·유물 | Item + RunAsset | 런 소켓 효과·태그, 탈출 자동 환전, 사망 소실 |

**무기·방어구를 Item에 중복 등록하지 않습니다.** LootTable은 현장 카탈로그에 연결된 Weapon·Armor·Skill ID도 참조할 수 있습니다. 현재 Item 2행의 분류 설명은 일부만 나열하므로 룬·도면 등의 전체 정책은 [전리품 생명 주기](../features/loot-lifecycle.md)와 실제 기존 행을 함께 확인하세요.

## 5. 드랍 표 연결하기 {#drop}

예: 기존 소총 파츠를 산업 지구의 방 보상에서 더 자주 나오게 하려면 `LootTable`에서 같은 ID·지역·출처의 행을 찾습니다.

- `entry_id`: 드랍 행 자체의 고유 ID. `item_id`와 다릅니다.
- `region_id`: `ruined_city` / `industrial_district` / `research_complex`.
- `difficulty_id`: `any` 또는 `standard` / `veteran` / `nightmare`.
- `map_size`: `any` 또는 `small` / `medium` / `large`.
- `source_type`: `enemy` / `room_reward` / `vault` / `boss`. `vault`는 확장 지점이지 모든 금고의 실물 드랍 보장이 아닙니다.
- `item_id`: 준비된 아이템 ID와 정확히 같아야 합니다.
- `base_weight`: 같은 조건에 걸린 후보끼리 비교하는 추첨 비중. **20을 적어도 20%가 아닙니다.** 등급 보정·후보 필터·생성 정책이 결과에 영향을 줍니다.
- `minimum_quantity ≤ maximum_quantity`: 수량 범위.
- `runtime_enabled`: 참조 검증이 끝난 관련 행만 함께 활성화.

방에서 반드시 몇 번 뽑을지, 적 처치 시 실제 드랍을 시도할지 등은 별도 생성 정책입니다. 가중치만 올려도 “모든 적에게서 반드시 드랍”이 되지는 않습니다.

## 6. 성장과 시즌 보상 조정 {#growth}

**RunBuff**는 한 판의 강화 선택지입니다. `maximum_stacks`는 최대 중첩, `heal_on_apply`는 선택 즉시 회복입니다. 기본 레벨업 회복 전체를 뜻하지 않습니다.

**Upgrade**는 `target_kind + target_id + level`이 한 묶음의 주소입니다. 예: `module / ballistic_core / 2`. 같은 조합의 행을 두 개 만들지 않습니다.

- 해당 레벨의 효과는 **누적값**입니다. Lv.2 행을 Lv.1에 또 더할 값으로 작성하지 않습니다.
- `credit_cost`, `material_quantity`는 현재 레벨 → 다음 레벨 강화 비용입니다. 최고 레벨 행은 0.
- `module_capacity_cost`는 장착할 때 차지하는 코스트이며 강화 결제액이 아닙니다.
- 현재 `target_kind`는 weapon/armor/module. **고유 파츠 강화 비용은 아직 Resource 정책**이므로 새 part 행을 임의로 추가하지 말고 개발 요청합니다.

**SeasonReward**는 외형만 바꿉니다. `ranking_id`는 recovered_value/elapsed_seconds/kills, `kind`는 title/aura, `max_rank`는 조건별 상위 몇 명까지 줄지입니다. `color`는 `02e5e1`처럼 **# 없는 6자리 문자열**입니다. 앞의 0이 지워지지 않게 텍스트 형식을 유지합니다.

시즌 시작 시 보상 목록을 고정하므로 실시간 수정도 **다음 시즌부터** 적용됩니다. 현재는 기기 내 로컬 기록·로컬 외형 지급입니다. 대형·최소 페널티 10점이 신규 기본 참가 조건이며 기존 진행 시즌은 시작 때 조건을 유지합니다. 운영용 기간·점수·상위 인원은 별도 기획 승인 대상입니다.

## 7. 확정 요청과 되돌리기 {#publish}

기획자는 터미널 명령을 외울 필요가 없습니다. 아래 내용을 복사해 Notion에 적고 개발자에게 링크를 전달하세요.

~~~text
[DATA-아이템ID-날짜] 변경 제목
대상: Weapon / assault_rifle / damage
변경 전 → 후: 1.6 → 1.8 (설명용 예시)
이유: 같은 적을 처치하는 시간이 너무 길다
시험 조건: 빌드 / 실시간 또는 CSV / 요원 / 장비 / 지역·난이도·규모
관찰: 수정 전·후 처치 시간, 화면 또는 영상
연결: 새 아이템이면 Item·LootTable·Upgrade 등의 ID
상태: 초안 / 테스트 요청 / 기획 확정
수락 기준: 장착·드랍·탈출·사망·재실행에서 기대한 결과
되돌릴 값: 원래 값
~~~

개발자는 **해당 탭 동기화 → 참조/형식 검사 → 게임 E2E → CSV와 Web payload 함께 커밋 → PR 검증 → Web·Windows 같은 커밋 배포**로 처리합니다. Google Sheet 저장과 CSV 확정은 다른 단계입니다. `확정 CSV` 버튼은 기존 배포값을 읽는 버튼이지 Sheet를 저장소로 확정하는 버튼이 아닙니다.

??? info "개발자용 동기화 명령 보기"

    저장소 루트에서 변경한 공급자만 동기화합니다. 읽기만 하는 검사는 `--check`입니다.

    ~~~powershell
    python scripts/sync_weapon_balance.py --url "https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=Weapon"
    python scripts/sync_weapon_balance.py --check
    python scripts/sync_item_lifecycle.py --check
    python scripts/sync_loot_table.py --check
    python scripts/sync_growth_balance.py --check
    python scripts/sync_season_rewards.py --check
    ~~~

    Item·LootTable·SeasonReward의 실제 동기화는 각 스크립트를 `--check` 없이 실행합니다. 성장 동기화는 `python scripts/sync_growth_balance.py --spreadsheet-id "1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM"`입니다. Weapon은 위처럼 명시적 URL이 필요합니다. Armor 정의, 가방 크기, 새 파츠/모듈 효과와 카탈로그 연결은 이 CSV 명령이 자동 생성하지 않습니다.

되돌릴 때는 **테스트 중인 Sheet 값은 기존 값으로 복구**, 이미 배포했다면 **개발자에게 이전 검증 CSV/코드로 되돌리는 PR을 요청**합니다. 공유 시트 전체 버전을 임의로 복원하면 다른 기획자의 변경도 지워질 수 있으므로 대상 셀 단위 복원을 우선합니다. 오래된 아이템 ID 삭제는 저장 호환성 검토 없이 진행하지 않습니다.

## 안 바뀌는 것 같다면 {#troubleshoot}

| 증상 | 먼저 볼 것 |
|---|---|
| Sheet를 저장했는데 그대로 | 확정 CSV 모드인지, 올바른 ID/장착 무기인지, TRUE인지 |
| 특정 탭만 반응 없음 | Armor·정의용 열처럼 실시간 대상이 아닌지 |
| 실시간인데 예전 값 유지 | 네트워크/공개 CSV, 중복 ID·숫자·참조 오류; 정상값 보존 폴백일 수 있음 |
| 새 물건이 안 나옴 | 실제 정의·카탈로그, LootTable 조건/지역, 드랍 시도 정책이 연결됐는지 |
| 새 시즌 보상명이 안 바뀜 | 현재 시즌은 고정. 다음 시즌부터 적용하는지 |
| 브라우저와 다운로드가 다름 | 동일 빌드인지, 실시간/확정 모드가 같은지, 이전 버전을 실행 중인지 |

오류를 숨기려고 더 많은 열을 동시에 고치지 말고 **탭·ID·변경 전후·발생 조건**을 함께 보고하세요.

## 관련 상세 문서

[무기 밸런스](../features/weapon-balance.md) · [성장/강화](../features/growth-balance.md) · [생명 주기](../features/loot-lifecycle.md) · [드랍 표](../features/loot-tables.md) · [기획 요청 방식](../design/planner-request-workflow.md) · [P6 로컬 마감 범위](../features/ranking-provider.md#p6-closeout)
