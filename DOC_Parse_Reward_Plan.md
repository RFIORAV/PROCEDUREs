# Parseo de `Reward_plan` → CPA / RS / BL

Especificación derivada de las reglas de extracción sobre cadenas libres de planes de remuneración (MySQL 8.0+ / 8.4).

Script de referencia: `SCRIPT_Parse_Reward_Plan_v1.sql`

---

## Objetivo

A partir del texto `Reward_plan`, obtener:

| Campo | Significado | Tipo de salida |
|-------|-------------|----------------|
| **CPA** | Coste por adquisición (importe) | entero; `0` si no aparece pero sí hay RS o BL |
| **RS**  | Revenue Share / RevShare (porcentaje) | entero; `0` si no aparece pero sí hay CPA o BL |
| **BL**  | Baseline / umbral asociado | entero o cadena vacía `''` si no aparece |

Si **no** se obtiene ningún valor de CPA, RS ni BL → **ignorar la línea**.

---

## Reglas de extracción

### 1. Símbolo `%` ⇒ siempre RS

Si un número va seguido de `%` (con o sin espacios), ese número es **RS**, aunque no aparezca la palabra `RS` / `RevShare`.

Ejemplos:

- `Rev Share 30%` → RS=30
- `fullmoon_casino 100€ + 30%` → RS=30
- `100 CPA + 40%Rs` → RS=40
- `Rev share cap_5%_after_3y` → RS=5

### 2. CPA

Prioridad (primera coincidencia válida):

1. Número **antes** de la palabra `CPA`, con `EUR` / `€` opcional pegado o separado:  
   `80 CPA`, `80EUR CPA`, `200EUR CPA (IT) + 40 RS`
2. Número **después** de `CPA`:  
   `CPA 65€`, `CPA 100 + 40%`
3. Importe con `€` seguido de `+` (plan “nombre + importe + %”), **excluyendo** importes ligados a `BL`:  
   `fullmoon 75€ + 35%` → CPA=75
4. Forma corta `N + M%` al inicio:  
   `0 + 35%` → CPA=0, RS=35  
   `150 + 30% BL 30` → CPA=150
5. Forma corta `N+M` / `N + M` (solo dos números unidos por `+`, sin `%`):  
   `80+30` → CPA=80, RS=30

Si solo hay RS (o solo BL) y no hay CPA → **CPA = 0**.

### 3. RS (sin `%`)

Si no hubo `%`, buscar en este orden:

1. Número ligado a la palabra `RS` (mayúsculas/minúsculas):  
   `35 RS`, `+ 40 RS`, `RS 30`
2. Segundo número de la forma corta `N+M` / `N + M` (plan completo):  
   `80+30` → RS=30

Si solo hay CPA (o solo BL) y no hay RS → **RS = 0**.

### 4. BL

Prioridad:

1. Etiqueta explícita `BL` / `Bl`:  
   - `BL 10€`, `Bl 25€`, `20BL`, `(30BL)`, `(25 BL)`
2. Paréntesis **numéricos**:
   - `(10)` → BL=10
   - `(30/30)`, `(10/20)`, `(10/25)` → BL = **primer** número del par
3. Paréntesis **no numéricos** → **ignorar** (país, producto, texto):  
   `(IT)`, `(CZ)`, `(CASINO - SPORT)`, `(CZ SK)`, `(PT)`, etc.

Si no hay BL → devolver `''` (vacío), **no** `0`.

### 5. Líneas a ignorar

Sin ningún número interpretable como CPA/RS/BL, por ejemplo:

- `RevShare Flat per Product`
- `Subaffiliation - EUR`
- `RevShare Ladder`
- `RevShare Flat`
- `Hybrid (CPA/CPL+RevShare Flat)`
- `Bingo`
- `Empty`

---

## Ejemplos canónicos

| Reward_plan | CPA | RS | BL |
|-------------|-----|----|----|
| `80 CPA (30/30) (IT) + 35 RS` | 80 | 35 | 30 |
| `HYBRID - CPA 65€ + RS 35% - BL 10€` | 65 | 35 | 10 |
| `RS 30% (CASINO - SPORT)` | 0 | 30 | `''` |
| `80EUR CPA (10) (IT)` | 80 | 0 | 10 |
| `fullmoon_casino 100€ + 30%` | 100 | 30 | `''` |
| `150 + 30% BL 30` | 150 | 30 | 30 |
| `100 CPA + 40%Rs Bl 25€` | 100 | 40 | 25 |
| `CPA 100 + 40% (30BL)` | 100 | 40 | 30 |
| `35 RS` | 0 | 35 | `''` |
| `80+30` | 80 | 30 | `''` |
| `Bingo` | — | — | — (ignorar) |

---

## Defaults tras extracción parcial

| Situación | CPA | RS | BL |
|-----------|-----|----|----|
| Solo RS | 0 | valor | `''` |
| Solo CPA | valor | 0 | `''` |
| CPA + RS, sin BL | valor | valor | `''` |
| Nada extraíble | línea descartada | | |

---

## Notas de implementación (MySQL 8.4)

- MySQL 8.x: `REGEXP_SUBSTR` **no** admite grupo de captura (a diferencia de MariaDB). El número se obtiene con `REGEXP_REPLACE` sobre el match completo.
- Normalizar el texto con `TRIM`; no hace falta eliminar `€`/`EUR` antes del parseo.
- La comparación de claves/palabras es **case-insensitive** (`match_type 'i'`).
- Compatibilidad objetivo: MySQL **8.0.37+** / **8.4** (ICU REGEXP).
- Script de prueba con el dataset de muestra: `SCRIPT_Parse_Reward_Plan_v1.sql`.

### Aplicación a tabla real (ejemplo)

```sql
SELECT
  R.Reward_plan,
  /* columnas CPA, RS, BL según expresiones del script */
  ...
FROM Snapshot_day_by_day_rew_plan R
HAVING /* al menos un valor crudo no nulo */;
```

---

## Historial

| Fecha | Cambio |
|-------|--------|
| 08.10.2026 | Primera especificación a partir de dataset de Reward_plan y ejemplos canónicos |
| 08.10.2026 | Forma corta `N+M` → CPA=N, RS=M (ej. `80+30`) |
