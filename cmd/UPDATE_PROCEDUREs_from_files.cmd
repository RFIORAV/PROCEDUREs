@echo off

:: EJECUTA SQL CON PROCEDURES
:: rf 04.09.2022 V1 Extrae lista de DB desde `information_schema`.SCHEMATA y ejecuta para todas
:: rf 05.09.2022 Parámetro 1: Database/ALL (Asume ALL por defecto. Si está informado sólo se ejecuta para esta DB o para ALL)
:: rf 06.09.2022 Parámetro 2: Máscara de input file por ej *FACT2_AFF* sólo procesará estos files de entrada
::              (Parámetro 1 es obligatorio -puede ser ALL- si hay parámetro 2)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cls
if /I [%1.] EQU [?.]  goto Show_param

call :getDateInfo
call :SetEnvironment
call :ConnectVPN

SET "CSV_InputDir=d:\Reinaldo\_FRA\db\PROCEDUREs\"

SET "FileInputMask=*"
SET "DBInput=ALL"

:Check_parameters
if /I [%1.] EQU [.]   (SET DBInput=ALL)       else (SET DBInput=%1)
if /I [%2.] EQU [.]   (SET "FileInputMask=*") else (SET "FileInputMask=%2")

if /I [%DBInput%] EQU [ALL] goto Continue_process

call :Show_files_confirm
call :Run_for_database %DBInput%
goto :eof

:Continue_process
call :Show_files_confirm
call :Get_database_names
goto :eof

::::::::::::::::::::::::::::::::::::::::::
:Get_database_names

   echo SELECT SCHEMA_NAME FROM `information_schema`.SCHEMATA WHERE SCHEMA_NAME NOT IN  >.\temp\update_proc_dblist.tmp
   echo ('betmedia_datain','information_schema','mysql','performance_schema','sys');   >>.\temp\update_proc_dblist.tmp

   %MySQL_run%<.\temp\update_proc_dblist.tmp>.\temp\update_proc_dblist.txt

   FOR /F "tokens=*" %%D IN (.\temp\update_proc_dblist.txt) DO call :Run_for_database %%D

exit /b
::::::::::::::::::::::::::::::::::::::::::
:Run_for_database

   IF /i [%1] EQU [SCHEMA_NAME] EXIT /B
   SET DB2update=%1

   FOR /F "tokens=*" %%G IN ('dir %CSV_InputDir%%FileInputMask%.sql /b /ON') DO call :Update_procedure "%CSV_InputDir%%%G"

exit /b
::::::::::::::::::::::::::::::::::::::::::
:Update_procedure

   echo USE %DB2update%;  >.\temp\update_proc.tmp
   type %1               >>.\temp\update_proc.tmp
   echo Updating %DB2update% - Processing file: %1
   %MySQL_run%<.\temp\update_proc.tmp
   IF %ERRORLEVEL% NEQ 0 pause
   
exit /b

::::::::::::::::::::::::::::::::::::::::::
:Show_param

echo ----------------------------------------------------------------------
echo ---------------------INSTALL/UPDATE PROCEDUREs------------------------
echo ----------------------------------------------------------------------
echo -
echo Parametro/s: %1 %2 -- PARAMETROS PROCESABLES
echo -
echo ----------------------------------------------------------------------
echo Parametro 1: Nada/ALL = todas las DB
echo -
echo Parametro 2: input file mask/* (Asume *=ALL) (Ej: *FACT1* / event* / *matrix)
echo            : (Obligatorio Parametro 1)
echo ----------------------------------------------------------------------
echo -
REM pause
goto :eof

:::::::::::::::::::::::::::::::::::::::::
:Show_files_confirm
   echo --
   echo -- Update Procedures en %1 DB - Files mask: %FileInputMask%
   echo --
   echo -- Files que van a utilizarse en este proceso:
   echo --
   dir %CSV_InputDir%%FileInputMask%.sql /b /ON
   echo --
   echo --
   echo --
   Echo Any key to continue or Ctrl+C to cancel
   PAUSE >nul
exit /b

::::::::::::::::::::::::::::::::::::::::::
::::::::::::::SUBROUTINES:::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::
:getDateInfo
	for /f %%a in ('wmic os get LocalDateTime ^| findstr ^[0-9]') do (set ts=%%a)
	
	set dateAAAAMMDD=%ts:~0,8%
	set dateAAAAMM=%ts:~0,6%
	set dateAAAA=%ts:~0,4%
	set dateMM=%ts:~4,2%
	set dateDD=%ts:~6,2%
	set dateDX=%ts:~6,1%
	set dateXD=%ts:~7,1%
	set timeHHMMSS=%ts:~8,6%
	set timeHHMM=%ts:~8,4%
	set timeHH=%ts:~8,2%
	set timeMM=%ts:~10,2%
	set timeSS=%ts:~12,2%
exit /B

::::::::::::::::::::::::::::::::::::::::::
:ConnectVPN
	call d:\Reinaldo\_FRA\db\ConnectVPN.cmd
exit /B

::::::::::::::::::::::::::::::::::::::::::
:SetEnvironment
	
	set MySQLexe="c:\Program Files\MariaDB 10.5\bin\mysql.exe"
	set MySQL57exe="c:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe"
	set MySQL80exe="c:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
	REM MySQLdumpexe="c:\Program Files\MariaDB 10.5\bin\mysqldump.exe"
	set MySQLdumpexe="c:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe"
	
	REM set  MySQL_local=%MySQLexe%   -t --host=localhost --port=3307 --user=root 
	REM set MySQL_local1=%MySQLexe%      --host=localhost --port=3307 --user=root 
	set  MySQL_local=%MySQL80exe% -t --host=localhost  	--port=3308 --user=b3w1nn3r --password=abcd --force 
	set MySQL_local1=%MySQL80exe%    --host=localhost  	--port=3308 --user=b3w1nn3r --password=abcd --force 
	set MySQL_remote=%MySQL80exe% -t --host=10.45.224.21 	--port=3306 --user=b3w1nn3r --password=qLgneYRDheXIp#mtFqn(Evgwy3HKWEl8
	set MySQL_remote1=%MySQL80exe%   --host=10.45.224.21 	--port=3306 --user=b3w1nn3r --password=qLgneYRDheXIp#mtFqn(Evgwy3HKWEl8

	REM set MySQL_run=%MySQL_remote1%
	REM set MySQL_run=%MySQL_local1%

   echo -
   echo -
   echo -
	Set /P Server=Ejecucion en LOCAL o en Server REMOTO (por defecto: LOCAL) || SET Server=LOCAL
	REM echo Ejecucion en: [%Server%]

   if /I [%Server%] EQU [REMOTO] (set "MySQL_run=%MySQL_remote1%") else (set "MySQL_run=%MySQL_local1%")
   
   echo -
   echo -
   echo --------------------------------------------------------
   echo CONFIRMAR EJECUCION SOBRE SERVER %Server%
   echo %MySQL_run%
   echo Ctrl+C para CANCELAR
   echo --------------------------------------------------------
   echo -
   echo -
   PAUSE >nul
	
   set MySQL57_local=%MySQL57exe%   -t --host=localhost     --port=3306 --user=b3w1nn3r --password=abcd 
	set MySQL80_local=%MySQL80exe%   -t --host=localhost     --port=3308 --user=b3w1nn3r --password=abcd --force 
	set MySQLdump_run=%MySQLdumpexe% 	--host=10.45.224.3 	--port=3306 --user=b3w1nn3r --password=qLgneYRDheXIp#mtFqn(Evgwy3HKWEl81
	set MySQLdump_run8=%MySQLdumpexe% --defaults-extra-file=additional_parameters.txt --host=10.45.224.21 --port=3306 --user=b3w1nn3r --password=qLgneYRDheXIp#mtFqn(Evgwy3HKWEl8

exit /B
