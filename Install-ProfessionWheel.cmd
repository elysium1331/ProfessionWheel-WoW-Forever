@echo off
rem Installs the built ProfessionWheel zip into your WoW Forever AddOns folder (developer helper).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1" %*
pause
