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
if "%~1"=="" goto usage
if /i "%~1"=="check" (
  %SFH_PYTHON% scripts\sync_weapon_balance.py --check
  exit /b %errorlevel%
)
if /i "%~1"=="sync" (
  if "%~2"=="" goto usage
  %SFH_PYTHON% scripts\sync_weapon_balance.py --url "%~2"
  exit /b %errorlevel%
)
:usage
echo Usage: scripts\weapon-balance.cmd check
echo        scripts\weapon-balance.cmd sync "GOOGLE_SHEETS_CSV_URL"
exit /b 2
