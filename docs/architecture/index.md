# 아키텍처

SFH는 Godot의 Scene, Node, Resource, Signal을 조합해 기능을 분리합니다. 게임의 규칙을 알고 싶다면 [SFH 종합 문서](../features/index.md), 코드가 연결되는 방식을 알고 싶다면 이 문서에서 시작하세요.

[TOC]

## 1. 읽는 순서

먼저 [프로젝트 오너 운영 온톨로지](project-ontology.md)에서 객체·관계·행동·원본·권한과 판단 폐루프를 확인합니다. 실제 구현 관계가 필요하면 [코드 모듈 노드맵](code-module-map.md), 조립 규칙은 [모듈 규칙](module-rules.md)과 [장면 트리](scene-tree.md)·[Signal 규칙](signals.md) 순서로 확인합니다.

## 2. 하위 문서

<!-- sfh:children -->

## 3. 위키 문서 구조도 모듈로 관리

`mkdocs.yml`의 중첩 목차가 상위·하위 관계의 원본입니다. `scripts/wiki_articles.py`는 빌드 시 이 관계에서 경로와 하위 문서 링크만 만들고, `docs/stylesheets/articles.css`가 읽기 화면을 담당합니다. 인증은 기존 Worker가 담당하며 이 탐색 모듈은 권한을 판단하지 않습니다.

문서 본문에 `<!-- sfh:children -->`을 넣은 주제 문서는 직계 하위 링크를 자동으로 받습니다. 새 주제는 목차의 첫 페이지로 등록하고, 전체 검색용 `knowledge-map.json`에도 빠짐없이 등록합니다. `test_wiki_articles.py`가 모든 문서 경로·실제 HTML 링크·고아 문서·공개 화면 제외를 검증합니다.
