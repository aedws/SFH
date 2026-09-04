---
title: SFH 플레이 테스트
description: 살아서 싸우고 회수하는 탑다운 익스트랙션 액션 SFH의 공개 플레이 테스트 페이지
tags: [SFH, 플레이 테스트, 탑다운 액션]
hide:
  - navigation
  - toc
search:
  exclude: true
---

<section class="sfh-hero sfh-public-hero">
  <div class="sfh-hero-copy">
    <div class="sfh-brand">
      <span class="sfh-mark">SFH</span>
      <span class="sfh-brand-copy"><strong>SURVIVE · FIGHT · HAUL</strong><small>MODULAR EXTRACTION ACTION</small></span>
    </div>
    <span class="sfh-kicker">PUBLIC PLAYTEST</span>
    <h1>살아서 싸우고,<br>가져와 성장하세요.</h1>
    <p>거점에서 출격을 준비하고, 자동 전투와 스킬로 위험한 방을 돌파해 전리품을 회수하는 탑다운 익스트랙션 액션입니다.</p>
    <div class="sfh-actions">
      <a class="sfh-button primary sfh-operation-play" data-sfh-surface="gameplay" href="https://sfh-game.vstock-market.workers.dev/" target="_blank" rel="noopener noreferrer">브라우저 플레이 <b>▶</b></a>
      <a class="sfh-button" data-sfh-surface="windows-download" href="https://sfh-game.vstock-market.workers.dev/downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip">Windows 다운로드 <b>↓</b></a>
    </div>
    <p class="sfh-public-note">개발 중인 테스트 빌드입니다. 진행 상황과 내부 설계 문서는 역할 로그인 뒤 제공됩니다.</p>
  </div>
  <aside class="sfh-operation-card sfh-public-card">
    <span class="sfh-kicker">TEST BUILD</span>
    <header><strong>현재 테스트 상태</strong><b class="sfh-live">PLAYABLE</b></header>
    <div class="sfh-public-features">
      <span><i>01</i><b>준비</b><small>요원·장비·작전 선택</small></span>
      <span><i>02</i><b>전투</b><small>자동 공격·3개 스킬</small></span>
      <span><i>03</i><b>회수</b><small>파밍·탈출·영구 성장</small></span>
    </div>
    <a class="sfh-public-login" href="access/login/"><span><b>팀 작업 공간 로그인</b><small>기획자 · 개발자</small></span><em>→</em></a>
  </aside>
</section>

<section class="sfh-public-test-guide" aria-label="테스트 안내">
  <article><span>PREPARE</span><b>PC / 모바일 가로 선택</b><p>모바일은 기기를 가로로 돌려 주세요. 로비에서 준비한 뒤 게이트에서 F 또는 모바일 ‘사용’을 누릅니다.</p></article>
  <article><span>SKILL</span><b>1 · 2 · 3</b><p>점멸, 지속형 자기장, 이동 가속을 상황에 맞게 사용하세요.</p></article>
  <article><span>ESCAPE</span><b>F / M</b><p>보상을 회수하고 지도와 탈출 지점을 확인해 살아서 돌아오세요.</p></article>
</section>

<div class="sfh-notes sfh-public-release">
<details class="sfh-day">
  <summary><span class="sfh-day-title"><b>2026-09-05</b><i class="sfh-latest">최신</i><small>3 UPDATE BUNDLES · BUILD 7 · IMPROVE 11 · CHANGE 14 · FIX 5</small></span><em class="sfh-chevron">⌃</em></summary>
  <div class="sfh-day-body">
    <div class="sfh-daily-overview"><span><b>3</b><small>UPDATE BUNDLES</small></span><span><b>7</b><small>BUILD</small></span><span><b>11</b><small>IMPROVE</small></span><span><b>14</b><small>CHANGE</small></span><span><b>5</b><small>FIX</small></span></div>
    <details class="sfh-bundle" open>
      <summary><span><small>UPDATE 3</small><b>프로젝트 오너 판단 온톨로지 · 개발자 콘솔</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 기획자와 개발자는 근거를 제공하고, 사용자인 프로젝트 오너가 범위·우선순위·수락·출시를 최종 판단하도록 개발자 화면을 재구성했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 3</h3><p>오너 판단 레지스트리, 코드·문서 결합 생성기, 검색·필터·직접 관계 상세 콘솔을 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>판단 필요·차단·준비·검증·보류를 분리하고, 선택 객체 주변 근거만 표시하며 모바일 한 열과 키보드 탐색을 지원합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 5</h3><p>Notion·Sheet/CSV·Git/E2E를 원본으로 유지하고 위키는 읽기 전용 파생 뷰로 고정했습니다. 중복 ID·소유권 누락·깨진 문서/모듈 관계는 빌드 실패로 처리합니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 2</h3><p>기획자를 최종 결정자로 오인하던 표현을 바로잡고, 하위 문서에서 게임 배포 주소 레지스트리를 현재 경로 아래로 잘못 요청하던 404를 제거했습니다.</p></div>
        <p>게임 코드·밸런스 Sheet/CSV·과금·서버 설정은 변경하지 않았습니다.</p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 2</small><b>가방 아이템 R 회전 · 방향 저장</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · I 가방에서 아이템을 한 번 선택하고 R을 누르면 3×2↔2×3처럼 점유 방향을 바꾸고, 저장한 방향이 다음 실행에도 유지됩니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>아이템 인스턴스별 회전 상태와 선택 아이템 회전 입력·버튼을 구현했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 3</h3><p>현재 점유 크기·방향을 상세 정보에 표시하고 K에서 바꾼 현장 장착 키를 가방 회전에도 문맥별로 재사용합니다.</p></div>
        <div class="sfh-group"><h3>수정 · 3</h3><p>회전 방향 기준 충돌·경계 검사, 구 저장 호환, 실제 클릭→R→저장과 별도 프로세스 복원 E2E를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 0</h3><p>기존 결함 수정이 아니라 가방 편집 기능 확장입니다.</p></div>
        <p>불가능한 회전은 위치와 방향을 바꾸지 않습니다. 새 아이템 목록·Sheet/CSV·과금 모델은 변경하지 않았습니다.</p>
        <p><a href="features/grid-inventory/">가방 회전 규칙 →</a> · <a href="architecture/module-audit/">모듈 경계 →</a></p>
      </div>
    </details>
    <details class="sfh-bundle">
      <summary><span><small>UPDATE 1</small><b>단일 작업 폴더 · Git 커밋 기반 복구</b></span><em class="sfh-chevron">⌄</em></summary>
      <div class="sfh-bundle-body">
        <div class="sfh-summary"><strong>무엇이 변했나 · 바탕화면 복제 폴더 대신 커밋·PR·검증 백업을 복구 기준으로 삼고, 완료된 임시 작업 폴더를 정리했습니다.</strong></div>
        <div class="sfh-group"><h3>구현 · 2</h3><p>삭제 없이 후보만 판정하는 worktree 감사와 새 clone의 Godot import 선행 검사를 추가했습니다.</p></div>
        <div class="sfh-group"><h3>개선 · 4</h3><p>상시 폴더 하나, 임시 worktree 수명, WIP 원격 보존과 Godot 스크립트 식별자 추적 원칙을 명확히 했습니다.</p></div>
        <div class="sfh-group"><h3>수정 · 6</h3><p>삭제 전 4중 확인, squash 병합 판정, 단계별 복구, UID 추적, 실행·협업 안내와 검색·노드맵을 현행화했습니다.</p></div>
        <div class="sfh-group"><h3>버그픽스 · 3</h3><p>오래된 작업 폴더 혼동, Windows PowerShell 한글 검사 파싱, 새 clone의 클래스 캐시·폰트 import 부재를 제거했습니다.</p></div>
        <p>로컬 에디터 상태는 원격 안전 브랜치에 먼저 커밋했습니다. 게임·Sheet/CSV·사용자 저장·Cloudflare 과금 설정은 변경하지 않았습니다.</p>
        <p><a href="getting-started/source-control-and-cleanup/">정리·복구 기준 →</a></p>
      </div>
    </details>
  </div>
</details>
</div>
