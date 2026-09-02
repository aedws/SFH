---
title: 계정 설정
description: 로그인한 SFH 역할 계정의 아이디와 비밀번호를 변경하는 보호 화면
search:
  exclude: true
hide:
  - toc
---

# 계정 설정

<section class="sfh-auth-panel" data-sfh-auth-account>
  <header>
    <span class="sfh-kicker">PROTECTED ACCOUNT CONTROL</span>
    <h2 data-sfh-auth-identity>로그인 정보 확인 중</h2>
    <p>이 화면은 로그인 세션을 확인한 사용자에게만 제공됩니다.</p>
  </header>
  <div class="sfh-auth-required" data-sfh-auth-required hidden>
    초기 계정입니다. 역할 탭을 열기 전에 아이디와 비밀번호를 변경해 주세요.
  </div>
  <form class="sfh-auth-form">
    <label><span>현재 비밀번호</span><input name="current_password" type="password" autocomplete="current-password" maxlength="128" required></label>
    <label><span>새 아이디</span><input name="new_username" autocomplete="username" minlength="4" maxlength="40" pattern="[A-Za-z0-9._-]+" required></label>
    <label><span>새 비밀번호</span><input name="new_password" type="password" autocomplete="new-password" minlength="16" maxlength="128" required></label>
    <label><span>새 비밀번호 확인</span><input name="confirm_password" type="password" autocomplete="new-password" minlength="16" maxlength="128" required></label>
    <small>16자 이상, 영문 대·소문자·숫자·특수문자를 각각 포함해야 합니다.</small>
    <button type="submit">아이디·비밀번호 변경</button>
    <p class="sfh-auth-status" data-sfh-auth-status aria-live="polite"></p>
  </form>
</section>
