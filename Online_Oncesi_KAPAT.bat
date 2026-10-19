@echo off
rem Online oncesi: Turkce yamayi pencere acmadan KAPATIR
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0GTA5_Turkce_Anahtar.ps1" -Islem Kapat
