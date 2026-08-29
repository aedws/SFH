---
title: 적과 생성 시스템
tags:
  - 적
  - 추적
  - 스폰
  - 난이도
---

# 적과 생성 시스템

## 목적

적이 플레이어 주변에서 생성되고 플레이어를 향해 이동합니다. 시간이 지날수록 생성 간격이 짧아집니다.

## 모듈 구성

- `game/features/enemies/`: 적의 이동, 체력, 접촉 피해
- `game/features/spawning/`: 생성 위치, 간격, 최대 적 수

두 폴더를 분리한 이유는 적의 종류와 생성 규칙을 서로 독립적으로 교체하기 위해서입니다.

## 조정 가능한 값

`enemy.tscn`의 Enemy Inspector:

- `Move Speed`: 추적 속도
- `Max Health`: 적 체력
- `Contact Damage`: 접촉 피해
- `Contact Interval`: 반복 피해 간격
- `Experience Reward`: 사망 시 경험치

`enemy_spawner.tscn`의 Inspector:

- `Initial Interval`: 최초 생성 간격
- `Minimum Interval`: 최소 생성 간격
- `Spawn Radius`: 플레이어와 생성 지점 사이 거리
- `Maximum Enemies`: 동시에 존재할 수 있는 적 수

## 활성화와 의존성

`FeatureManifest`에서 `Enemies Enabled`와 `Spawning Enabled`를 사용합니다. `spawning`만 단독으로 켤 수는 없습니다.

## 검색 별칭

몬스터, 좀비, 추적 AI, 적 생성, 스폰 속도, 웨이브, 접촉 피해
