---
title: 자동 무기
tags:
  - 무기
  - 자동 공격
  - 투사체
  - 타겟팅
---

# 자동 무기

## 목적

플레이어 주변의 가장 가까운 적을 찾아 일정 간격으로 투사체를 발사합니다. 플레이어는 이동과 회피에 집중합니다.

## 구성

```text
AutoWeapon
└─ Projectile 인스턴스 → World/Projectiles에 생성
```

`AutoWeapon`은 `enemies` 그룹만 검색하므로 적 Scene의 내부 Node 구조를 알 필요가 없습니다. 투사체는 대상이 `take_damage` 메서드를 제공하는지만 확인합니다.

## 조정 가능한 값

- `Fire Interval`: 공격 간격
- `Projectile Damage`: 한 발의 피해
- `Target Range`: 자동 탐색 거리
- 투사체의 `Speed`, `Lifetime`

레벨이 상승하면 공격 간격이 감소하고 일정 레벨마다 피해가 증가합니다.

## 비활성화

`FeatureManifest.weapons_enabled`를 끄면 무기 Scene을 플레이어에게 설치하지 않습니다.

## 검색 별칭

자동 사격, 가장 가까운 적, 총알, 발사체, 공격 속도, 무기 끄기
