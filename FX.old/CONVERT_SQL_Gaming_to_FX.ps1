# Creado por chatGPT 2023.01.29
# Puede utilizar el cmdlet Get-ChildItem para obtener todos los archivos de una carpeta específica que cumplan con una máscara de nombre específica, y luego utilizar el cmdlet ForEach-Object para 
# procesar cada archivo. Dentro del bloque ForEach-Object, puede utilizar el cmdlet Get-Content para leer el contenido del archivo y el cmdlet Set-Content para escribir el contenido modificado de 
# vuelta al archivo.

param (
    [string]$folder,
    [string]$fileMask
)

Get-ChildItem -Path $folder -Filter $fileMask -File | ForEach-Object {
   $file = $_.FullName
   $content = Get-Content -Path $file

   # Tables and Views
   $content = $content -replace "account_landing_pages"                   ,"forex_landing_pages_2"
   $content = $content -replace "campaign_advertiser"                     ,"forex_advertiser"
   $content = $content -replace "campaign_campaign"                       ,"forex_campaign"
   $content = $content -replace "campaign_deal_affiliate"                 ,"forex_deal_affiliate"
   $content = $content -replace "campaign_deal_gestor"                    ,"forex_deal_gestor"
   $content = $content -replace "campaign_deal_gestor_prod_date"          ,"forex_deal_gestor_prod_date"
   $content = $content -replace "campaign_deal_marketplace"               ,"forex_deal_marketplace"
   $content = $content -replace "campaign_marketing_source"               ,"forex_marketing_source"
   $content = $content -replace "campaign_mkt_source_deal"                ,"forex_marketing_source_deal_date"
   $content = $content -replace "campaign_publisher"                      ,"forex_campaign_publisher"
   $content = $content -replace "campaign_username"                       ,"forex_advertiser_account"
   $content = $content -replace "Snapshot_day_by_day_fact1"               ,"forex_day_by_day_fact1_2"
   $content = $content -replace "Snapshot_day_by_day_fact2"               ,"forex_day_by_day_fact2_2"
   $content = $content -replace "Snapshot_day_by_day_lm"                  ,"forex_day_by_day_lm_2"
   $content = $content -replace "Snapshot_day_by_day_lm_temp"             ,"forex_day_by_day_lm_temp_2"
   $content = $content -replace "Snapshot_day_by_day_temp"                ,"forex_day_by_day_temp_2"
   $content = $content -replace "Snapshot_day_by_day"                     ,"forex_day_by_day_2"
   $content = $content -replace "view_monthly_fact_aff3"                  ,"forex_view_monthly_fact_aff3"
   $content = $content -replace "account_financial_movement"              ,"forex_account_financial_movement"
   $content = $content -replace "account_manual_adjustments"              ,"forex_account_manual_adjustments"
   $content = $content -replace "view_monthly_fact_aff2"                  ,"forex_view_monthly_fact_aff2"
   $content = $content -replace "total_monthy_comm_ges"                   ,"forex_total_monthy_comm_ges"
   $content = $content -replace "Totali_affiliate_new"                    ,"forex_Totali_affiliate_new"
   $content = $content -replace "Totali_username_new"                     ,"forex_Totali_username_new"

   # Procedures
   $content = $content -replace "Aff_MarketingSources"                    ,"FX_Aff_MarketingSources"
   $content = $content -replace "Balance_Affiliate"                       ,"FX_Balance_Affiliate"
   $content = $content -replace "Check_DbD"                               ,"FX_Check_DbD"
   $content = $content -replace "Compare_DbD_DbD_lm"                      ,"FX_Compare_DbD_DbD_lm"
   $content = $content -replace "Compare_Fact1_Fact2_lm"                  ,"FX_Compare_Fact1_Fact2_lm"
   $content = $content -replace "Dash_BrandMatrix"                        ,"FX_Dash_BrandMatrix"
   $content = $content -replace "Dash_GestorOrAffiliate_TotalByAffiliate" ,"FX_Dash_GestorOrAffiliate_TotalByAffiliate"
   $content = $content -replace "Dash_Gestor_ProfitByAff"                 ,"FX_Dash_Gestor_ProfitByAff"
   $content = $content -replace "Dash_Gestor_TotalByAdvertiser"           ,"FX_Dash_Gestor_TotalByAdvertiser"
   $content = $content -replace "Dash_TotalByAffiliate"                   ,"FX_Dash_TotalByAffiliate"
   $content = $content -replace "economics_by_affiliate"                  ,"FX_economics_by_affiliate"
   $content = $content -replace "Gestor_MarketingSources"                 ,"FX_Gestor_MarketingSources"
   $content = $content -replace "Gestor_MonthlySources"                   ,"FX_Gestor_MonthlySources"
   $content = $content -replace "NR_ByAFFILIATE_by_MonthOrDay_BrandMatrix","FX_NR_ByAFFILIATE_by_MonthOrDay_BrandMatrix"
   $content = $content -replace "MktSrcDeal"                              ,"FX_MktSrcDeal"
   $content = $content -replace "Report_Affiliates"                       ,"FX_Report_Affiliates"
   $content = $content -replace "Report_Brands"                           ,"FX_Report_Brands"
   $content = $content -replace "Report_Countries"                        ,"FX_Report_Countries"
   $content = $content -replace "Report_Deal_MktPlace"                    ,"FX_Report_Deal_MktPlace"
   $content = $content -replace "Report_MarketingSources"                 ,"FX_Report_MarketingSources"
   $content = $content -replace "Report_Publisher"                        ,"FX_Report_Publisher"
   $content = $content -replace "Report_FinMov_ManAdj"                    ,"FX_Report_FinMov_ManAdj"
   $content = $content -replace "ShowNotif_Affiliate"                     ,"FX_ShowNotif_Affiliate"
   $content = $content -replace "Show_Diff_CPA_DbD_yesterday"             ,"FX_Show_Diff_CPA_DbD_yesterday"
   $content = $content -replace "Show_mkt_sources_deal"                   ,"FX_Show_mkt_sources_deal"
   $content = $content -replace "Snapshot_day_by_day_fact1_upd_from_dbd"  ,"FX_Snapshot_day_by_day_fact1_upd_from_dbd"
   $content = $content -replace "Snapshot_day_by_day_fact1_upd_lm"        ,"FX_Snapshot_day_by_day_fact1_upd_lm"
   $content = $content -replace "Snapshot_day_by_day_fact1_upd"           ,"FX_Snapshot_day_by_day_fact1_upd"
   $content = $content -replace "Snapshot_day_by_day_fact2_upd_cm"        ,"FX_Snapshot_day_by_day_fact2_upd_cm"
   $content = $content -replace "Sync_Fact2_from_Fact1"                   ,"FX_Sync_Fact2_from_Fact1"
   $content = $content -replace "Sync_MS_DbD_DbD_lm"                      ,"FX_Sync_MS_DbD_DbD_lm"
   $content = $content -replace "Sync_MS_Fact1_Fact2_lm"                  ,"FX_Sync_MS_Fact1_Fact2_lm"
   $content = $content -replace "total_monthy_comm_ges_upd"               ,"FX_total_monthy_comm_ges_upd"

   Set-Content -Path $file -Value $content
}
