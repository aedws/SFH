---
title: 웹에서 위키 수정
description: GitHub 웹 편집기로 위키 문서를 수정하고 자동 배포하는 방법
tags:
  - 위키
  - 웹 편집
  - GitHub Pages
  - 배포
---

# 웹에서 위키 수정

온라인 위키는 [https://aedws.github.io/SFH/](https://aedws.github.io/SFH/)에서 확인합니다.

## 문서 한 페이지 수정

1. 온라인 위키에서 수정할 문서를 엽니다.
2. 문서 우측 상단의 연필 아이콘을 누릅니다.
3. GitHub에 로그인합니다.
4. Markdown 내용을 수정하고 `Commit changes`를 누릅니다.
5. 가능하면 새 브랜치와 Pull Request를 만들어 변경 내용을 확인합니다.
6. 변경이 `main` 브랜치에 병합되면 위키가 자동으로 다시 배포됩니다.

## 여러 문서 수정

[SFH 저장소](https://github.com/aedws/SFH)를 연 상태에서 `.` 키를 누르면 브라우저용 VS Code 편집기인 GitHub.dev가 열립니다. `docs/` 아래의 Markdown 파일을 수정하고 Source Control에서 커밋할 수 있습니다.

## 어떤 파일을 수정해야 하나

- 문서 본문: `docs/**/*.md`
- 좌측 메뉴와 검색 설정: `mkdocs.yml`
- 위키 패키지: `requirements-docs.txt`
- 자동 배포 과정: `.github/workflows/deploy-wiki.yml`

`docs/` 밖의 게임 파일은 위키 본문으로 표시되지 않습니다.

## 배포 확인

저장소의 `Actions` 탭에서 `Deploy developer wiki` 실행을 확인합니다. 초록색 체크가 표시되면 잠시 후 온라인 위키에 변경 내용이 반영됩니다.

## 공개 범위

현재 SFH 저장소와 GitHub Pages는 공개 상태입니다. 저장소 읽기 권한이 있는 사람은 문서를 볼 수 있지만, 수정하려면 저장소 쓰기 권한 또는 Pull Request 절차가 필요합니다.

## 검색 별칭

온라인 편집, 웹 수정, 연필 아이콘, GitHub Pages, GitHub Actions, 문서 배포, 위키 업데이트
