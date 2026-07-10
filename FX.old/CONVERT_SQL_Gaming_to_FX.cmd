@echo off

:: CONVIERTE PROC/VIEWS de Gaming a Forex cambinado nombres de TABLAS
:: 
:: rf 28.01.2023 Parámetro 1: Máscara de input file por ej *FACT2_AFF* sólo procesará estos files de entrada
::              (Parámetro 1 es obligatorio -puede ser ALL- si hay parámetro 2)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cls

::----------------------------------------------------------
if /I [%1.] EQU [?.]  goto Show_param

REM call UTIL_SetEnvironment.cmd

REM SET "InputDir_Views=d:\Reinaldo\_FRA\db\VIEWs\"
SET "InputDir_Procs=d:\Reinaldo\_FRA\db\PROCEDUREs\FX"
REM SET "InputDir_Trigg=d:\Reinaldo\_FRA\db\TRIGGERs\TRIGGER_MANUAL\"

SET "FileInputMask=*.sql"

:Check_parameters
if /I [%1.] EQU [.]   (SET "FileInputMask=*") else (SET "FileInputMask=%1")

dir /b /s /a-d "%InputDir_Procs%\%FileInputMask%"
Pause

pwsh -File .\CONVERT_SQL_Gaming_to_FX.ps1 -folder "%InputDir_Procs%" -fileMask "%FileInputMask%"

goto :eof

for /f "tokens=*" %%f in ('dir /b /s /a-d "%InputDir_Procs%\%FileInputMask%"') do (
   Set "fileIN=%%f"
   call :Update_file
)
 REM FOR /F "tokens=*" %%D IN (.\temp\update_dump_dblist.txt) DO call :Dump_import_db %%D

REM FOR /F %%G IN (%InputDir_Procs%\%FileInputMask%) do call :Update_file %%G

goto :eof

::::::::::::::::::::::::::::::::::::::::::
:Update_file

   echo - Processing file: %fileIN%
   
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'account_landing_pages','forex_landing_pages_2'               | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_advertiser','forex_advertiser'                      | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_campaign','forex_campaign'                          | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_deal_affiliate','forex_deal_affiliate'              | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_deal_gestor','forex_deal_gestor'                    | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_deal_gestor_prod_date','forex_deal_gestor_prod_date'| Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_deal_marketplace','forex_deal_marketplace'          | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_marketing_source','forex_marketing_source'          | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_mkt_source_deal','forex_marketing_source_deal_date' | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'campaign_username','forex_advertiser_account'                | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'Snapshot_day_by_day_fact1','forex_day_by_day_fact1_2'        | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'Snapshot_day_by_day_fact2','forex_day_by_day_fact2_2'        | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'Snapshot_day_by_day_lm','forex_day_by_day_lm_2'              | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'Snapshot_day_by_day_lm_temp','forex_day_by_day_lm_temp_2'    | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'Snapshot_day_by_day_temp','forex_day_by_day_temp_2'          | Out-File -encoding UTF8 '%fileIN%'"
   pwsh.exe -Command "(Get-Content '%fileIN%') -replace 'Snapshot_day_by_day','forex_day_by_day_2'                    | Out-File -encoding UTF8 '%fileIN%'"
   REM pause

exit /b

::::::::::::::::::::::::::::::::::::::::::
:Show_param

echo ----------------------------------------------------------------------
echo ----------------INSTALL/UPDATE VIEWs/PROCEDUREs/TRIGGERs MANUALES-----
echo ----------------------------------------------------------------------
echo -
echo Parametro/s: %1 -- PARAMETROS PROCESABLES
echo -
echo ----------------------------------------------------------------------
echo Parametro 1: input file mask/* (Asume *=ALL) (Ej: *FACT1* / event* / *matrix)
echo            : (Obligatorio Parametro 1)
echo -
echo ----------------------------------------------------------------------
echo -
echo -
REM pause
goto :eof

:::::::::::::::::::::::::::::::::::::::::
