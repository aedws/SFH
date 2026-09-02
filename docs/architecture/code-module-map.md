---
title: 현재 코드 모듈 노드맵
description: 실제 GDScript를 스캔해 모듈·클래스·상속·참조·검증 관계를 반응형 노드로 보여주는 구조 지도
tags:
  - 코드 구조
  - 모듈
  - 상속
  - 의존성
  - 반응형
---

# 현재 코드 모듈 노드맵

이 페이지는 사람이 손으로 그린 고정 도표가 아닙니다. `game/` 아래 실제 GDScript에서 `class_name`, `extends`, `res://game/` 로드 경로, 테스트 참조와 `FeatureManifest` 토글을 읽어 현재 구조를 만듭니다. 선택한 모듈은 중앙에 놓이고 사용처·의존처가 거미줄처럼 방사형으로 펼쳐집니다.

<div class="sfh-code-map-guide" markdown>
  <span><b>01 · 노드 선택</b><small>기능 폴더 하나의 공개 클래스와 연결을 확인</small></span>
  <span><b>02 · 관계 추적</b><small>누가 쓰고 무엇을 쓰는지 양방향으로 이동</small></span>
  <span><b>03 · 상속 판별</b><small>Godot 엔진 기반과 프로젝트 내부 기반을 분리</small></span>
  <span><b>04 · 계약 이동</b><small>관련 위키 문서에서 제거·교체 규칙 확인</small></span>
</div>

<div data-sfh-code-module-map-host></div>

## 읽는 기준

- **계약**은 기능 토글과 유효성 검사를 소유합니다.
- **조립**은 기능을 직접 구현하지 않고 활성 노드를 연결합니다.
- **기능**은 `game/features/<module>/` 경계를 기준으로 집계합니다.
- **검증**은 기능 내부가 아니라 공개 계약과 플레이 흐름을 참조해야 합니다.
- `ENGINE BASE`는 Godot 기본 타입 상속, `PROJECT BASE`는 저장소 내부 스크립트 상속입니다. 상속이 적다는 것은 합성(Node·Resource·Signal)을 우선하는 현재 구조와 일치합니다.

## 자동 현행화 계약

- 갱신: `python scripts/generate_code_module_map.py`
- 검사: `python scripts/generate_code_module_map.py --check`

코드가 바뀌었는데 JSON을 갱신하지 않으면 위키 빌드가 실패합니다. 따라서 배포된 노드 수·클래스·관계·소스 해시는 해당 빌드의 코드 상태와 항상 함께 움직입니다. 세부 독립성 판정은 [모듈화 점검 기록](module-audit.md), 구현 원칙은 [모듈 작성 규칙](module-rules.md)에서 확인합니다.

## 반응형·접근성 계약

- 데스크톱에서는 중앙 선택 노드와 최대 12개 직접 관계를 실제 화살표로 비교하고, 연결이 많으면 좌우 페이지 버튼으로 넘깁니다.
- 태블릿은 최대 8개, 휴대폰은 최대 6개 관계만 한 화면에 배치해 선·버튼 겹침을 줄입니다. 아래 전체 모듈 인덱스는 4열에서 1열까지 자동 전환됩니다.
- 모든 선택 노드는 최소 44px 터치 범위, 키보드 포커스, `aria-pressed` 상태를 유지합니다.
- 바깥 노드를 누르면 해당 모듈이 즉시 중앙으로 이동합니다. 화살표 시작·끝은 **사용처 / 의존처** 방향을, 선 색은 필수 의존·코드 참조·검증·프로젝트 상속을 뜻합니다.
- `prefers-reduced-motion`과 고대비 설정을 존중하고 외부 그래프 라이브러리를 사용하지 않습니다.

## 검색 별칭

현재 코드 상태, 코드 노드맵, 모듈 상속, 클래스 상속, 기능 의존성, 모듈 관계, GDScript 구조, FeatureManifest, 코드 아키텍처
