---
title: K 입력 설정과 자유 스킬 배치
description: 물리 키와 스킬의 1~9 Action 배치를 분리해 K 화면에서 교체하고 영구 저장하는 입력 모듈
tags:
  - 키 설정
  - 키 매핑
  - 바인딩
  - K
  - 입력
  - 접근성
---

# K 입력 설정과 자유 스킬 배치

거점과 작전에서 `K`를 누르면 입력 설정 화면이 열립니다. `키 배치` 탭은 이동·전투·메뉴를 포함한 22개 Action의 물리 키를 바꾸고, `스킬 배치` 탭은 장착한 스킬을 허용된 1~9 Action으로 옮깁니다. 두 단계는 독립 저장되므로 물리 키만 바꾸거나 스킬 위치만 바꿀 수 있습니다.

## 사용법

1. `K`로 입력 설정을 엽니다.
2. `키 배치`에서 바꾸려는 Action의 현재 키 버튼을 누른 뒤 원하는 키나 마우스 버튼을 입력합니다.
3. `스킬 배치`에서 스킬 행의 이전·다음 버튼으로 1~9 슬롯을 선택합니다.
4. 이미 다른 스킬이 있는 슬롯을 선택하면 두 스킬의 위치가 교환됩니다.
5. `전체 기본값 복원`은 물리 키와 스킬 위치를 함께 초기화합니다.

물리 키는 `user://sfh_key_mapping.json`, 스킬 위치는 `user://sfh_skill_bindings.json`에 즉시 저장됩니다. `ESC`는 입력 대기를 취소하고 화면을 닫는 비상 키라서 재지정할 수 없습니다.

## 두 단계가 분리되는 이유

- `1` 키를 `마우스 4`로 바꾸는 일은 **물리 키 → Action** 변경입니다.
- 점멸을 스킬 1에서 스킬 4로 옮기는 일은 **skill_id → Action** 변경입니다.
- HUD와 실제 발동은 `SkillBindingService`가 제공한 Action을 읽고, 그 Action의 현재 물리 키 이름은 `KeyMappingService`에서 읽습니다.

따라서 키 변경이 스킬 정의를 덮어쓰지 않고, 스킬 위치 변경도 프로젝트의 InputMap 기본값을 훼손하지 않습니다.

## 모듈 구조

```text
KeyMappingCatalog Resource
  └─ Action ID · 표시명 · 기획 분류 22개

KeyMappingService
  ├─ InputMap 기본값 캡처
  ├─ 키보드·마우스 입력 정규화
  ├─ 중복 키 교환
  ├─ JSON 저장·복원
  └─ bindings_changed Signal

KeyMappingPanel
	├─ 키 배치 / 스킬 배치 탭
	├─ K/ESC 입력과 입력 대기 UI
	└─ 두 Service의 공개 계약만 호출

SkillBindingProfile Resource
	└─ 허용 Action 1~9 · 기본 skill_id→action_id

SkillBindingService
	├─ 스킬 슬롯 이동·충돌 교환
	├─ JSON 저장·복원
	├─ 물리 키 표시명 합성
	└─ bindings_changed Signal
```

플레이어 이동은 더 이상 `WASD` 물리 키를 직접 읽지 않습니다. `move_up/down/left/right`와 `dash` Action만 읽으므로 저장된 설정이 실제 이동과 대시에 그대로 적용됩니다. I/U/E 같은 기존 화면도 각각의 Action을 사용해 같은 저장 계약을 공유합니다.

## 기본값

| 분류 | Action | 기본값 |
| --- | --- | --- |
| 이동 | 위/아래/왼쪽/오른쪽 | `W` / `S` / `A` / `D` |
| 이동 | 대시 | `Space` |
| 전투 | 기본 공격 / 상호작용 / 무기 교체 | `마우스 1` / `F` / `Q` |
| 스킬 | 전투 스킬 1~9 | 숫자 `1`~`9` |
| 메뉴 | 가방 / 장비 / 모듈·파츠 / 확장 전술 지도 / 키 설정 | `I` / `U` / `E` / `M` / `K` |

## 교체·비활성화

- `FeatureManifest.key_mapping_enabled=false`이면 서비스와 K 화면만 설치하지 않습니다.
- `FeatureManifest.skill_binding_enabled=false`이면 물리 키 설정은 유지하고 자유 스킬 배치만 제거됩니다.
- Action 목록과 기획자 표시 순서는 `default_key_mapping.tres`에서 바꿉니다.
- 저장 방식을 클라우드 프로필로 교체하려면 `KeyMappingService`의 공개 계약을 구현하는 제공자로 바꿉니다.
- 자동 검증은 물리 Action 22개, 장착 스킬 3개, 허용 슬롯 9개, 두 종류의 충돌 교환, JSON 재로딩, K/ESC 실제 입력을 검사합니다.

## 검색 별칭

키 설정, 키매핑, 키 매핑, 키 변경, 조작 변경, 자유 키, 바인딩, 리바인드, 단축키, K 설정, M 미니맵, WASD 변경, 마우스 버튼, 키 중복, 기본값 복원, 입력 저장
