@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build_free_aab_auto_version.ps1" %*

if errorlevel 1 (
  exit /b 1
)

exit /b 0
