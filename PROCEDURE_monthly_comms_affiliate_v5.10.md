La especificación vigente del cálculo está en PROCEDURE_monthly_comms_affiliate.md
(alineada a PROCEDURE_monthly_comms_affiliate_v5.10.sql). Este archivo queda como
pedido original de la v5.10.

Modificar el procedure monthly_comms_affiliate_v5 (archivo
PROCEDURE_monthly_comms_affiliate_v5.10.sql) para:

1) Recibir mes a procesar (YYYY-MM); si NULL/vacío/inválido usar CURDATE()-2 meses.
2) Calcular CPA + Revenue Share del afiliado sobre Snapshot_day_by_day_fact2.
3) Modalidades RS:
   - Deal_Aff_RS=0 → sin RS (gross/net RS = 0)
   - Deal_Aff_RS_Against_CPA=1 → RS negativa se resta de gross_CPA_Val sin dejar CPA neto negativo
   - RS acumulado negativo → net_RS_Val=0
   - net_RS_Val nunca negativo: RS negativas se absorben en positivas del mismo KeyRSAcum
     (prorrateo del neto acumulado ≥ 0)
   - Acumulación según campaign_deal_affiliate.RS_Base
     (fallback Snapshot.Deal_Aff_RS_Base; default brand):
       account        → Affiliate_id + Account_id
       Operator       → Affiliate_id + Publisher_id
       brand          → Affiliate_id + Brand (default)
       Operator/brand → Affiliate_id + Publisher_id + Brand
4) Referral Master Affiliate (Comm_type=REFER) con master_affiliate_deals_v2:
   - Enlace vía master_affiliate_deals_per_affiliate (Status/Valid_From/Valid_To/Advertiser)
   - Un registro REFER por Sub_Affiliate_id + Month + Master + Brand
     (agrega accounts; conserva detalle por brand/Advertiser_id)
   - Deal MA: Advertiser_id=0 (todas) o match de brand; prioridad deal específico
   - Por SA+brand, acumular:
       Value_by_CPA × CPA
       Perc_on_Tot_Comm % sobre net_Total_comm
       Perc_on_CPA_Value % sobre net_CPA_Val
       Perc_on_RS % sobre net_RS_Val
       Perc_on_Margin_value % sobre Estimated_Margin (fact1 Gestor−Affiliate)
         del SA+brand+mes
5) Bonus por objetivos (Comm_type=BONUS) al final:
   - Tablas campaign_deal_affiliate_bonus + campaign_deal_affiliate_bonus_brand
   - Si el mes solapa Date_Valid_From..Date_Valid_to, acumula CPA/NR/FTD de TODO
     el mes en fact2 (Affiliate_id + brands; 0 filas hija=all; MS opcional)
   - No recorta métricas al día Date_Valid_to
   - Umbrales CPA_min/NR_min/FTD_min (0=no aplica); Conditions ANY|ALL
   - Importe = Bonus_Value + NR_mes * Bonus_NR / 100 + CPA_mes * Bonus_Value_per_CPA
   - Account_id=0; Brand = GROUP_CONCAT Advertiser_Name o ALL
6) Preferir CASE unificado (sin UNION de ramas CPA-vs-RS) y KeyRSAcum para acumulación.
7) No usar Owner en GROUP BY / ORDER BY (sí MAX(Owner) en SELECT).
8) Desde rs_acum en adelante, todo GROUP BY debe incluir Affiliate_id.
