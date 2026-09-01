---
title: 외부 에셋 라이선스 원장
description: 상업 배포 전에 확인한 외부 에셋의 출처·라이선스·반입 범위
tags:
  - 라이선스
  - 상업 이용
  - 에셋
  - CC0
  - 저작권
---

# 외부 에셋 라이선스 원장

SFH에 새 외부 에셋을 반입할 때는 원본 배포자가 명시한 라이선스 원문, 출처 URL, 기준 버전 또는 커밋, 실제 반입 파일과 해시를 저장소에 함께 남깁니다. 출처가 불명확하거나 상업 이용 조건이 모호한 파일은 반입하지 않습니다.

## 현재 반입 자산

| 자산 | 원작자 | 라이선스 | 상업 이용 | SFH 반입 범위 |
| --- | --- | --- | --- | --- |
| Kenney Particle Pack 1.1 | Kenney Vleugels | CC0 1.0 Universal | 허용, 표기 의무 없음 | `spark_01.png`, `spark_04.png` 2개 |
| Galmuri 11 | Lee Minseo (`quiple`) | SIL Open Font License 1.1 | 허용, 라이선스 원문 동봉 | 게임 `Galmuri11-Bold.ttf`, 위키 `Galmuri11.woff2` |

Godot용 패키징 원본 식별자는 `Calinou/kenney-particle-pack`이며 반입 기준은 `ab7086639ee73be31abd87feb21bf1402d4e8144`입니다. 원본은 CC0 1.0을 명시하며, 실제 포함된 라이선스 원문은 `game/assets/vfx/kenney_particle_pack/LICENSE.txt`, 파일별 SHA-256과 용도는 같은 폴더의 `SOURCE.md`에 보존합니다.

Galmuri의 공식 원본 식별자는 `quiple/galmuri`이며 반입 기준은 `71e1cacf1437a11220307120e63e30bc275312d4`입니다. 라이선스 원문과 게임 파일 해시는 `game/assets/fonts/galmuri/`, 위키 전송본과 라이선스는 `docs/assets/fonts/galmuri/`에 보존합니다. 게임은 TTF만, 위키는 WOFF2만 사용해 불필요한 Godot 임포트와 중복 배포를 피합니다.

## 반입 규칙

1. 상업 이용이 명시된 `CC0`, `MIT`, `OFL` 등 검증 가능한 라이선스를 우선합니다.
2. 에셋 페이지 설명만 믿지 않고 원문 라이선스 파일까지 확인합니다.
3. 필요한 파일만 선별해 Web 다운로드·VRAM 비용을 줄입니다.
4. 원본 파일을 수정했다면 변경 범위와 파생 파일도 원장에 기록합니다.
5. 라이선스 의무가 있는 자산은 배포물의 크레딧·고지 파일까지 자동 검증 대상으로 둡니다.

이 문서는 법률 자문을 대신하지 않지만, 제작 과정에서 출처와 허용 범위를 재현할 수 있게 하는 기술적 감사 기록입니다.
