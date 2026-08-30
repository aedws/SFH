@echo off
setlocal
cd /d "%~dp0.."
set "SFH_PYTHON="
if exist ".venv\Scripts\python.exe" set "SFH_PYTHON=.venv\Scripts\python.exe"
if not defined SFH_PYTHON where py >nul 2>nul && set "SFH_PYTHON=py -3"
if not defined SFH_PYTHON where python >nul 2>nul && set "SFH_PYTHON=python"
if not defined SFH_PYTHON (
  echo Python 3 was not found.
  exit /b 1
)
if /i "%~1"=="check" goto check
if /i "%~1"=="sync" goto sync
goto usage

:check
%SFH_PYTHON% scripts\sync_growth_balance.py --check
exit /b %errorlevel%

:sync
if "%~2"=="" goto usage
%SFH_PYTHON% scripts\sync_growth_balance.py --spreadsheet-id "%~2"
exit /b %errorlevel%

:usage
echo Usage: scripts\growth-balance.cmd check
echo        scripts\growth-balance.cmd sync "GOOGLE_SHEETS_ID"
exit /b 2
