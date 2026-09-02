---
title: 역할 로그인
description: SFH 기획자와 개발자 작업 공간에 안전하게 진입하는 로그인 화면
search:
  exclude: true
hide:
  - toc
---

# 역할 로그인

<section class="sfh-auth-panel" data-sfh-auth-login>
  <header>
    <span class="sfh-kicker">ROLE ACCESS GATE</span>
    <h2>작업 역할을 선택하세요</h2>
    <p>공개 위키는 로그인 없이 읽을 수 있습니다. 아래 인증은 역할별 작업 탭과 계정 설정에만 사용됩니다.</p>
  </header>
  <div class="sfh-auth-tabs" role="tablist" aria-label="로그인 역할">
    <button type="button" role="tab" aria-selected="true" data-sfh-login-role="planner">기획자</button>
    <button type="button" role="tab" aria-selected="false" data-sfh-login-role="developer">개발자</button>
  </div>
  <form class="sfh-auth-form">
    <input type="hidden" name="role" value="planner">
    <label><span>아이디</span><input name="username" autocomplete="username" minlength="4" maxlength="40" required></label>
    <label><span>비밀번호</span><input name="password" type="password" autocomplete="current-password" maxlength="128" required></label>
    <button type="submit">로그인</button>
    <p class="sfh-auth-status" data-sfh-auth-status aria-live="polite"></p>
  </form>
  <footer>5회 연속 실패 시 15분 동안 잠깁니다. 초기 계정은 첫 로그인 직후 변경 화면으로 이동합니다.</footer>
</section>
