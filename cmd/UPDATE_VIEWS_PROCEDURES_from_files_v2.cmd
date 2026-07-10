@echo off

:: EJECUTA SQL CON PROCEDURES y VIEWS
:: Reemplaza a UPDATE_VIEWs_from_files.cmd y UPDATE_PROCEDUREs_from_files.cmd
:: rf 04.09.2022 V1 Extrae lista de DB desde `information_schema`.SCHEMATA y ejecuta para todas
:: rf 05.09.2022 Parámetro 1: Database/ALL (Asume ALL por defecto. Si está informado sólo se ejecuta para esta DB o para ALL)
:: rf 06.09.2022 Parámetro 2: Máscara de input file por ej *FACT2_AFF* sólo procesará estos files de entrada
::              (Parámetro 1 es obligatorio -puede ser ALL- si hay parámetro 2)
:: RF 20.09.2022 call UTIL_SetEnvironment.cmd LOCAL
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cls
if /I [%1.] EQU [?.]  goto Show_param

call UTIL_SetEnvironment.cmd

SET "CSV_InputDir_Views=d:\Reinaldo\_FRA\db\VIEWs\"
SET "CSV_InputDir_Procs=d:\Reinaldo\_FRA\db\PROCEDUREs\"

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
   echo ('betmedia_datain','information_schema','mysql','performance_schema','sys','settings_db');   >>.\temp\update_proc_dblist.tmp

   %MySQL_run_Ns%<.\temp\update_proc_dblist.tmp>.\temp\update_proc_dblist.txt

   FOR /F "tokens=*" %%D IN (.\temp\update_proc_dblist.txt) DO call :Run_for_database %%D

exit /b
::::::::::::::::::::::::::::::::::::::::::
:Run_for_database

   IF /i [%1] EQU [SCHEMA_NAME] EXIT /B
   SET DB2update=%1

   FOR /F "tokens=*" %%G IN ('dir %CSV_InputDir_Views%%FileInputMask%.sql /b /ON') DO call :Update_procedure "%CSV_InputDir_Views%%%G"
   IF NOT EXIST %CSV_InputDir_Views%%DB2update%\%FileInputMask%.sql goto GoProcs
   FOR /F "tokens=*" %%G IN ('dir %CSV_InputDir_Views%%DB2update%\%FileInputMask%.sql /b /ON') DO call :Update_procedure "%CSV_InputDir_Views%%DB2update%\%%G"

   :GoProcs
   IF NOT EXIST %CSV_InputDir_Procs%%FileInputMask%.sql exit /b
   FOR /F "tokens=*" %%G IN ('dir %CSV_InputDir_Procs%%FileInputMask%.sql /b /ON') DO call :Update_procedure "%CSV_InputDir_Procs%%%G"

exit /b
::::::::::::::::::::::::::::::::::::::::::
:Update_procedure

   echo USE %DB2update%;  >.\temp\update_proc.tmp
   type %1               >>.\temp\update_proc.tmp
   echo Server: %Server% - Updating %DB2update% - Processing file: %1
   
   REM ECHO.%Variable% | FIND /I "ABC">Nul && ( Echo.Found "ABC" ) || ( Echo.Did not find "ABC" )

   %MySQL_run_Ns%<.\temp\update_proc.tmp
   IF %ERRORLEVEL% NEQ 0 pause
   
exit /b

::::::::::::::::::::::::::::::::::::::::::
:Show_param

echo ----------------------------------------------------------------------
echo ----------------INSTALL/UPDATE VIEWs and PROCEDUREs-------------------
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
   echo -- Update VIEWs en DB %DBInput% - Files mask: %FileInputMask%
   echo --
   echo -- Files que van a utilizarse en este proceso:
   echo --
   REM @echo on
   IF /i [%DBInput%] EQU [all] (dir %CSV_InputDir_Views%%FileInputMask%.sql /b /s /ON) else (dir %CSV_InputDir_Views%%FileInputMask%.sql /b /ON)
   IF /i [%DBInput%] NEQ [all] (dir %CSV_InputDir_Views%%DBInput%\%FileInputMask%.sql /b /ON)
   IF /i [%DBInput%] EQU [all] (dir %CSV_InputDir_Procs%%FileInputMask%.sql /b /S /ON) else (dir %CSV_InputDir_Procs%%FileInputMask%.sql /b /ON)
   REM @echo off
   echo --
   echo --
   echo --
   Echo Any key to continue or Ctrl+C to cancel
   PAUSE >nul
exit /b
