# 0001: Godot 4, GDScript, Material for MkDocs 사용

- 상태: 승인
- 날짜: 2026-08-29

## 결정

- 게임 엔진은 Godot 4 안정 버전을 사용합니다.
- 게임 코드는 GDScript로 작성합니다.
- 개발 위키는 Material for MkDocs로 생성합니다.
- 게임 코드와 문서는 같은 Git 저장소에서 관리합니다.

## 이유

Godot의 Scene과 Node 조합은 기능을 작은 단위로 나누기에 적합합니다. GDScript는 Godot 편집기와 통합이 잘 되어 있어 첫 Godot 프로젝트의 학습 부담이 비교적 낮습니다.

Material for MkDocs는 Markdown 기반이고 한글 전체 텍스트 검색, 검색어 제안, 결과 강조를 지원합니다. 문서를 코드와 함께 검토하고 변경 이력을 남길 수도 있습니다.

## 결과

새 기능을 완료하려면 기능 코드와 대응하는 위키 문서를 함께 변경해야 합니다.
