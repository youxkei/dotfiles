@echo off
rem Usage: trash <path>...
rem PowerShell and cmd cannot run bin/trash (it is a bash script without an extension), so this shim
rem runs trash.ps1 beside it. Git Bash keeps using bin/trash.
pwsh -NoProfile -NonInteractive -File "%~dp0trash.ps1" %*
