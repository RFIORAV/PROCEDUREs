-- TEST_Show_Diff_CPA_DbD_90days.sql
-- Procedimiento de prueba para verificar el funcionamiento del procedimiento corregido

-- Prueba 1: Verificar datos básicos
CALL Show_Diff_CPA_DbD_90days('Action=VIEW,LAPSE=3,Debug=KEYVALUES');

-- Prueba 2: Verificar solo diferencias negativas
CALL Show_Diff_CPA_DbD_90days('Action=VIEW,OnlyNegative=1,LAPSE=5,Debug=NO');

-- Prueba 3: Verificar todas las diferencias
CALL Show_Diff_CPA_DbD_90days('Action=VIEW,OnlyNegative=0,LAPSE=5,Debug=NO');

-- Prueba 4: Verificar con diferentes lapsos
CALL Show_Diff_CPA_DbD_90days('Action=VIEW,LAPSE=7,Debug=NO');

-- Prueba 5: Verificar datos de la tabla de acumulación
SELECT 
   COUNT(*) as Total_Records,
   COUNT(DISTINCT Date) as Distinct_Dates,
   MIN(Date) as Min_Date,
   MAX(Date) as Max_Date
FROM Snapshot_day_by_day_diff_90days;

-- Prueba 6: Verificar datos actuales de fact1
SELECT 
   COUNT(*) as Total_Records_Fact1,
   COUNT(DISTINCT Date) as Distinct_Dates_Fact1,
   MIN(Date) as Min_Date_Fact1,
   MAX(Date) as Max_Date_Fact1
FROM Snapshot_day_by_day_fact1 
WHERE Origin='' AND Date = CURDATE();

-- Prueba 7: Verificar diferencias específicas
SELECT 
   dd.Brand,
   dd.Username,
   dd.MS_id,
   dd.Product,
   dd.Day_0101 as Day_1,
   dd.Day_0102 as Day_2,
   COALESCE(cd.CPA, 0) as CPA_Today,
   (dd.Day_0101 - COALESCE(cd.CPA, 0)) as Diff_Today
FROM (
   SELECT 
      Brand,
      Username,
      MS_id,
      Product,
      MAX(CASE WHEN Date = '2025-01-01' THEN Qualified_Players ELSE 0 END) AS Day_0101,
      MAX(CASE WHEN Date = '2025-01-02' THEN Qualified_Players ELSE 0 END) AS Day_0102
   FROM Snapshot_day_by_day_diff_90days
   WHERE Date IN ('2025-01-01', '2025-01-02')
   GROUP BY Brand, Username, MS_id, Product
) dd
LEFT JOIN (
   SELECT 
      Brand,
      Username,
      ifnull(MS_id,0) AS MS_id,
      Product,
      sum(Qualified_Players) AS CPA
   FROM Snapshot_day_by_day_fact1 D
   WHERE D.Date = CURDATE() AND Origin=""
   GROUP BY Brand, Username, ifnull(MS_id,0), Product 
   HAVING sum(Qualified_Players)<>0
) cd ON dd.MS_id = cd.MS_id AND dd.Product = cd.Product
WHERE dd.Day_0101 != COALESCE(cd.CPA, 0)
LIMIT 10; 