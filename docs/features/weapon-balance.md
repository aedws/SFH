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

작전 중 `Q`를 누르면 메인 무기와 보조 무기를 즉시 교체합니다. HUD의 `▶`가 활성 슬롯을 표시하고, 아래에는 현재 무기 특색·피해·자동 탐지 거리·밸런스 출처가 표시됩니다.

| 슬롯 | 무기 | 현재 특색 |
|---|---|---|
| 메인 | 돌격소총 | 긴 자동 탐지 거리, 안정적인 3점사, 청록색 투사체 |
| 보조 | 제식 권총 | 짧은 거리, 단발 고위력, 1회 관통과 관통 후 65% 피해, 주황색 투사체 |

`CharacterEquipmentSystem`이 활성 슬롯만 소유하고, `AutoWeapon`은 슬롯 변경 Signal과 현재 밸런스 행만 소비합니다. 따라서 장비 UI, 밸런스 데이터, 실제 발사 동작을 서로 교체할 수 있습니다.

## 에임 없는 SFH용 수치

참조 프로젝트 [LootShooter_2025_2D](https://github.com/aedws/LootShooter_2025_2D)는 수동 에임과 반동을 전제로 합니다. SFH는 가장 가까운 적을 자동 선택하므로 ADS, 에임 중 이동 배율, 반동, 조준 분산·회복 수치는 가져오지 않았습니다.

대신 다음 값으로 무기 선택의 차이를 만듭니다.

- `target_range_px`: 자동 타기팅 반경
- `fire_interval_sec`: 한 발 또는 한 버스트 뒤 다음 공격까지의 시간
- `burst_count`, `burst_interval_sec`: 점사 수와 점사 내부 간격
- `projectiles_per_shot`, `spread_angle_deg`: 다중 투사체와 고정 분산각
- `damage`, `critical_chance`, `critical_multiplier`: 직접 피해와 치명타
- `pierce_count`, `pierce_damage_retention`: 추가 관통 수와 관통 후 피해 유지율
- `projectile_speed_px_sec`, `projectile_lifetime_sec`: 피하기 쉬운 정도와 최대 비행 거리

전체 18개 열의 단위와 입력 설명은 Google Sheets용 `SFH_Weapon_Balance.xlsx`의 **Field Guide** 탭에 정리되어 있습니다. **Weapons** 탭 첫 행은 게임 CSV 계약이므로 이동하거나 이름을 바꾸지 않습니다.

## 두 가지 데이터 모드

`WeaponBalanceConfig`가 데이터 출처를 선택합니다.

| 모드 | 용도 | 동작 |
|---|---|---|
| `LOCKED_CSV` | 기본 실행·배포 | 저장소의 검증된 `weapon_balance.csv`를 읽음 |
| `LIVE_GOOGLE_SHEET` | 개발 중 실시간 비교 | 공개 Google Sheets CSV를 기본 3초마다 다시 읽음 |

실시간 요청마다 캐시 무효화 값을 붙입니다. 요청 실패나 잘못된 열이 들어오면 마지막 정상값을 유지하며, 시작 시점부터 실패하면 확정 CSV로 폴백합니다. 배포 기본값은 네트워크 상태와 외부 편집에 영향을 받지 않는 `LOCKED_CSV`입니다.

## Google Sheets 준비

1. 제공된 `SFH_Weapon_Balance.xlsx`를 Google Drive에 업로드하고 Google 스프레드시트로 변환합니다.
2. **Weapons** 탭을 `파일 → 공유 → 웹에 게시`에서 CSV 형식으로 게시합니다.
3. 생성된 `https://docs.google.com/spreadsheets/d/.../export?format=csv&gid=...` URL을 복사합니다.
4. `game/features/weapon_balance/configs/default_weapon_balance.tres`에서 `source_mode = 1`로 바꾸고 `live_csv_url`에 URL을 입력합니다.
5. Godot에서 작전을 시작한 뒤 시트 수치를 바꿉니다. 정상 공개된 CSV라면 기본 3초 안에 현재 무기 런타임 값이 갱신됩니다.

!!! warning "공개 범위"
    일반 공유 링크가 아니라 **웹에 게시한 CSV URL**이 필요합니다. 게시된 값은 링크를 아는 사람이 읽을 수 있으므로 비밀 값이나 계정 정보를 넣지 않습니다.

## 테스트 수치를 확정 CSV로 잠그기

실시간 테스트가 끝났으면 저장소 루트에서 다음 명령을 실행합니다.

```powershell
.\scripts\weapon-balance.cmd sync "GOOGLE_SHEETS_CSV_URL"
.\scripts\weapon-balance.cmd check
.\scripts\test-game.cmd
```

`sync`는 18개 열의 이름·순서, 숫자 형식, 확률 범위, 중복 ID를 확인한 뒤에만 `game/features/weapon_balance/data/weapon_balance.csv`를 교체합니다. 그 다음 설정을 `source_mode = 0`으로 돌리면 확정 수치만 사용합니다.

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

Q키, 무기 바꾸기, 주무기 교체, 부무기 교체, 실시간 밸런싱, 구글 스프레드시트, 시트 연동, CSV 내보내기, 수치 확정, 핫 리로드, 자동 조준, 에임 없음, 3점사, 관통탄
