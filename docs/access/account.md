---
title: 계정 설정
description: 로그인한 SFH 역할 계정의 고정 아이디를 확인하고 비밀번호를 변경하는 보호 화면
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
    초기 비밀번호입니다. 역할 탭을 열기 전에 새 비밀번호로 변경해 주세요.
  </div>
  <form class="sfh-auth-form">
    <label><span>현재 비밀번호</span><input name="current_password" type="password" autocomplete="current-password" maxlength="128" required></label>
    <label><span>새 비밀번호</span><input name="new_password" type="password" autocomplete="new-password" minlength="4" maxlength="128" required></label>
    <label><span>새 비밀번호 확인</span><input name="confirm_password" type="password" autocomplete="new-password" minlength="4" maxlength="128" required></label>
    <small>아이디는 역할에 따라 <code>planner</code> 또는 <code>developer</code>로 고정됩니다. 새 비밀번호는 4~128자로 입력하세요.</small>
    <button type="submit">비밀번호 변경</button>
    <p class="sfh-auth-status" data-sfh-auth-status aria-live="polite"></p>
  </form>
</section>
