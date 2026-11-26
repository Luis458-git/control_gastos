@echo off
title WeSpend - Control de Gastos (Puma Server)
set "PATH=C:\Ruby33-x64\bin;%PATH%"
cd /d "%~dp0"

echo ===================================================
echo   Iniciando WeSpend en http://localhost:4567
echo   - Pagina Principal: http://localhost:4567/welcome
echo   - Inicio de Sesion: http://localhost:4567/login
echo   - Panel de Gastos:  http://localhost:4567/
echo ===================================================
echo.

C:\Ruby33-x64\bin\bundle.bat exec puma -C config/puma.rb
pause
