@echo off
setlocal

rem Run only this repository-owned script with a process-scoped policy override.
rem This does not change the user's PowerShell execution policy.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0wiki.ps1" %*
exit /b %ERRORLEVEL%
