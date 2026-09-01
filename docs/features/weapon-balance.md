---
title: Q 무기 교체와 Google Sheets 밸런스
description: 에임 없는 자동 전투에 맞춘 무기 특색, 실시간 Google Sheets CSV 테스트와 확정 CSV 운영 절차
tags:
  - Q키
  - 무기 교체
  - 구글 시트
  - Google Sheets
  - CSV
  - 실시간 밸런스
---

# Q 무기 교체와 Google Sheets 밸런스

## 현재 구현

거점과 작전 중 `Q`를 누르면 메인 무기와 보조 무기를 전환합니다. 거점에서 고른 슬롯은 출격 후에도 유지됩니다. HUD와 U/E 장비 목록의 `▶`가 활성 슬롯을 표시하고, 작전 HUD 아래에는 현재 무기 특색·피해·자동 탐지 거리·밸런스 출처가 표시됩니다.

| 슬롯 | 무기 | 현재 특색 |
|---|---|---|
| 메인 | 돌격소총 | 긴 자동 탐지 거리, 안정적인 3점사, 청록색 투사체 |
| 보조 | 제식 권총 | 짧은 거리, 단발 고위력, 1회 관통과 관통 후 65% 피해, 주황색 투사체 |

`CharacterEquipmentSystem`이 활성 슬롯만 소유하고, `AutoWeapon`은 슬롯 변경 Signal과 현재 밸런스 행만 소비합니다. 따라서 장비 UI, 밸런스 데이터, 실제 발사 동작을 서로 교체할 수 있습니다.

## 에임 없는 SFH용 수치

참조 프로젝트 식별자 `aedws/LootShooter_2025_2D`는 수동 에임과 반동을 전제로 합니다. SFH는 가장 가까운 적을 자동 선택하므로 ADS, 에임 중 이동 배율, 반동, 조준 분산·회복 수치는 가져오지 않았습니다.

대신 다음 값으로 무기 선택의 차이를 만듭니다.

- `target_range_px`: 자동 타기팅 반경
- `fire_interval_sec`: 한 발 또는 한 버스트 뒤 다음 공격까지의 시간
- `burst_count`, `burst_interval_sec`: 점사 수와 점사 내부 간격
- `projectiles_per_shot`, `spread_angle_deg`: 다중 투사체와 고정 분산각
- `damage`, `critical_chance`, `critical_multiplier`: 직접 피해와 치명타
- `pierce_count`, `pierce_damage_retention`: 추가 관통 수와 관통 후 피해 유지율
- `projectile_speed_px_sec`, `projectile_lifetime_sec`: 피하기 쉬운 정도와 최대 비행 거리

공용 [SFH_item_Balance Google Sheet](https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/edit?usp=sharing)는 무기·방어구·아이템을 행 단위로 비교하는 구조를 사용합니다.

| 행 | 역할 |
|---|---|
| 1행 | 코드에서 사용하는 변수명. 이름을 바꾸면 동기화 검증이 실패함 |
| 2행 | 각 변수의 뜻, 단위, 입력 규칙 |
| 3행 이후 | 무기·방어구·아이템별 개별 데이터 |

- `Weapon`: 무기 정의와 전투 수치만 기록합니다. `runtime_enabled`가 켜진 행만 실시간 전투와 확정 CSV에 반영됩니다.
- `Armor`: 방어구 정의와 스탯만 기록합니다.
- `Item`: 파츠·모듈·소비 아이템·크레딧·도면·룬·코어·유물만 기록합니다. 무기·방어구는 넣지 않습니다.

현재 런타임 실시간 연결 대상은 `Weapon`, `Item`, `RunBuff`, `Upgrade`입니다. `Item`의 생명 주기 열은 [전리품 생명 주기](loot-lifecycle.md)가 소비하고 성장 수치는 ID로 연결된 `Upgrade` 탭이 담당합니다. `Armor`는 정의 데이터 원본으로 유지합니다.

## 두 가지 데이터 모드

`WeaponBalanceConfig`가 데이터 출처를 선택합니다.

| 모드 | 용도 | 동작 |
|---|---|---|
| `LOCKED_CSV` | 기본 실행·배포 | 저장소의 검증된 `weapon_balance.csv`를 읽음 |
| `LIVE_GOOGLE_SHEET` | 개발 중 실시간 비교 | 공개 Google Sheets CSV를 기본 3초마다 다시 읽음 |

실시간 요청마다 캐시 무효화 값을 붙입니다. 요청 실패나 잘못된 열이 들어오면 마지막 정상값을 유지하며, 시작 시점부터 실패하면 확정 CSV로 폴백합니다. 배포 기본값은 네트워크 상태와 외부 편집에 영향을 받지 않는 `LOCKED_CSV`입니다.

## 게임 화면에서 모드 선택

게임을 실행하면 작전 규모 버튼 위에 다음 두 버튼이 표시됩니다.

- `확정 CSV`: 저장소에 검증·확정된 수치를 사용합니다. 기본 선택이며 일반 플레이와 배포에 권장합니다.
- `실시간 테스트`: 공용 `Weapon`, `Item`, `RunBuff`, `Upgrade`, `LootTable` Google Sheet를 기본 3초마다 다시 읽습니다. 네트워크 오류가 나면 마지막 정상값을 유지하거나 확정 CSV로 복구합니다.

선택한 모드는 이번 작전을 조립할 때 복제한 `WeaponBalanceConfig`에만 적용됩니다. 원본 Resource와 다른 모듈 설정은 수정하지 않으므로 버튼 UI를 제거해도 밸런스 서비스는 독립적으로 유지됩니다.

## Google Sheets 준비

1. 공용 시트의 `Weapon` 탭에서 3행 이후 무기 수치를 수정합니다. 1행 변수명은 유지합니다.
2. 전투에 연결할 무기 행의 `runtime_enabled` 체크박스를 켭니다.
3. Godot 작전 선택 화면에서 `실시간 테스트` 버튼을 누른 뒤 작전을 시작합니다. 공용 `Weapon` CSV URL은 이미 설정되어 있습니다.
4. 공개 CSV가 정상이라면 기본 3초 안에 현재 무기 런타임 값이 갱신됩니다. 상단 무기 HUD의 출처가 `Google Sheets 실시간`으로 바뀌는지 확인합니다.

!!! warning "공개 범위"
    게임은 편집 링크가 아니라 공개 CSV 내보내기 URL을 읽습니다. 현재 공용 시트의 `Weapon` CSV 응답은 확인했으며, 시트에는 비밀 값이나 계정 정보를 넣지 않습니다.

## 테스트 수치를 확정 CSV로 잠그기

실시간 테스트가 끝났으면 저장소 루트에서 다음 명령을 실행합니다.

```powershell
.\scripts\weapon-balance.cmd sync "https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/export?format=csv"
.\scripts\weapon-balance.cmd check
.\scripts\test-game.cmd
```

`sync`는 1행의 필수 변수명, 숫자 형식, 확률 범위, 중복 ID를 확인하고 2행 설명을 건너뛴 뒤 `runtime_enabled`가 켜진 무기만 배포 CSV로 확정합니다. 그 다음 설정을 `source_mode = 0`으로 돌리면 확정 수치만 사용합니다.

## 모듈 경계와 제거

```text
equipment/          활성 main/secondary 슬롯과 weapon_id
weapon_balance/     Google Sheets/확정 CSV 로드·검증·폴백
weapons/            자동 탐색, 발사 패턴, 투사체 관통
game.gd             위 세 계약을 조립하고 HUD에 표시
```

- `weapon_balance_enabled`를 끄면 `AutoWeapon`의 내장 최소값으로 동작합니다.
- `weapons_enabled`를 끄면 밸런스 모듈도 꺼야 하며 Manifest가 잘못된 조합을 막습니다.
- 장비 모듈을 끄면 밸런스·자동 공격은 기본 소총으로 계속 동작하지만 Q 슬롯 교체는 제공되지 않습니다.
- 새 무기는 장비 `weapon_id`와 CSV `weapon_id`가 같으면 되며, 열 추가가 필요할 때만 파서 계약을 확장합니다.

## 검색 별칭

Q키, 무기 바꾸기, 주무기 교체, 부무기 교체, 실시간 밸런싱, 구글 스프레드시트, Weapon 시트, Armor 시트, Item 시트, 변수명 1행, 설명 2행, 데이터 3행, CSV 내보내기, 수치 확정, 핫 리로드, 자동 조준, 에임 없음, 3점사, 관통탄
