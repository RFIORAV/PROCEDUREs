@echo off
cd /d "%~dp0"
set OUT=%~dp0out_v1.5.txt
set MYSQL=mysql
where mysql >nul 2>&1 || (
  for /d %%D in ("C:\Program Files\MySQL\*" "C:\Program Files\MariaDB*" "C:\xampp\mysql" "C:\laragon\bin\mysql\*" "C:\wamp64\bin\mysql\*") do if exist "%%~D\bin\mysql.exe" set "MYSQL=%%~D\bin\mysql.exe"
)
echo MYSQL=%MYSQL% > "%OUT%"
echo ==== INSTALL ==== >> "%OUT%"
"%MYSQL%" -h localhost -P 3304 -u b3w1nn3r -pabcd --default-character-set=utf8mb4 ritemood < "..\PROCEDURE_Report_Postback_daily_v1.5.sql" >> "%OUT%" 2>&1
echo INSTALL_RC=%ERRORLEVEL% >> "%OUT%"
echo ==== TESTS ==== >> "%OUT%"
"%MYSQL%" -h localhost -P 3304 -u b3w1nn3r -pabcd --default-character-set=utf8mb4 -t --force ritemood < "tests_v1.5.sql" >> "%OUT%" 2>&1
echo TESTS_RC=%ERRORLEVEL% >> "%OUT%"
echo DONE >> "%OUT%"
