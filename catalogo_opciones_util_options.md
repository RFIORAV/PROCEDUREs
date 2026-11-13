# Catálogo de opciones (util_options) — decisiones e inventario

Fecha: 06.11.2026 · Script: `D:\REINALDO\_FRA\db\PROCEDUREs\CREATE_TABLE_util_options_v2.sql` (v1 → `.old`)

## Estado
- **06.11.2026:** v2 ejecutado en `ritemood` (servidor MySQL 8.4.8, colación `utf8mb4_0900_ai_ci`) **sin errores**.
  - Cargado: 4 idiomas, 13 grupos, 49 opciones y 196 traducciones (49 × 4).
  - Controles: no falta ninguna traducción y ningún grupo tiene más de una opción por defecto. Quedan 28 opciones sin explicación (control c).

## Cómo ejecutar SQL en la db local desde Claude
El shell remoto de Claude no llega a `localhost:3304` de Windows.

**Flujo:**
1. Claude escribe el SQL en `D:\REINALDO\_FRA\db\_claude_run\input.sql`.
2. El usuario hace doble clic en `run_sql.bat`.
3. Claude lee `output.txt`.

**Qué hace el `.bat`:**
- Usa `C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe`.
- Conecta a `ritemood` con `--table -vvv --force`.
- Guarda toda la salida en `output.txt`.

## Objetivo
Una sola fuente para las listas de los campos de selección de **portalv2** (React 17 + react-select + i18next), con etiqueta y explicación traducidas al idioma elegido en la app.

## Decisiones tomadas con el usuario
| Tema | Decisión |
|---|---|
| Alcance | Campos de componentes React que despliegan una lista (no SP). Solo **dominios de negocio** (no rangos numéricos ni opciones de UI) |
| Traducciones | Tabla hija por idioma (`util_options_i18n`) |
| Idiomas | `en, es, it, pt` (los del selector IntlDropdown). Fallback `en` |
| Idioma del usuario | Se elige en la app (i18next, solo en el navegador) → el frontend lo envía en cada petición. `account_account.language` existe pero el selector no lo actualiza |
| Estados | **Un grupo por campo** (mismo código significa cosas distintas según la entidad) |
| Variación por Owner/edición | No: catálogo único por base de datos |
| Atributos por opción | Default, color/icono, opción padre (cascada), visibilidad por perfil |
| Perfil | `account_account_groups.group_id` (2=Gestor, 3=Affiliate), tal como lo lee `read_alias()` en Django |

## Modelo
- `util_languages` (Lang PK)
- `util_option_groups` (Group_code único, Value_type INT|STRING)
- `util_options` (Group_id, Option_value, Parent_option_id, Sort_order, Is_default, Color, Icon, Is_active)
- `util_options_i18n` (Option_id+Lang PK, Label, Description)
- `util_options_access` (Option_id+Account_group_id; sin filas = visible para todos)

Las opciones no se borran: se desactivan con `Is_active=0`.

## Inventario de portalv2 (src, sin @fake-db)
- 124 arrays de opciones fijos en el código (649 opciones literales en 85 archivos); **0 usan `t()`**.
- `statusColor` está copiado en 16+ archivos con subconjuntos distintos del dominio Django `Status_Choice` (0 Pending, 1 Active, 2 Paid, 3 Blocked, 4 Paused, 5 Not determined, 6 Paused auto NM, 9 Old). Colores: light-success / light-danger / light-secondary / light-warning / light-info.
- Grupos cargados en v2: ACCOUNT_STATUS, ACTIVE_INACTIVE, YES_NO_INT, YES_NO, TICKET_STATUS, TRAFFIC_SOURCE, PRODUCT, BUSINESS_CATEGORY, AFFILIATE_PLATFORM, CURRENCY, ACCOUNT_AREA, BONUS_CONDITIONS, INVOICE_CATEGORY.

## Pendientes / ambigüedades detectadas (no cargadas)
- **Estado de movimientos financieros:** `1` es Confirmed en React, pero Accepted en los SP (`Report_balance_by_affiliate`, `economics_by_affiliate1`). `3` es Denied, o Non_applied.
- **Métodos de pago:** React usa `'Bank Transfer'`/`'Credit Card'`, y `util_settings` usa `'BankTransfer'`/`'CreditCard'`. ¿Cuál se guarda en BD?
- **RevenueShareBase:** 3 subconjuntos distintos según el formulario (Deals, DealMaster/Marketplace, Notifications).
- **Prioridad:** `High/Medium/Low` frente a `low/medium/high`. La BD no distingue mayúsculas, pero en JS `===` sí.
- **Tipo de contacto:** `optionType` mezcla `1=WhatsApp` con `'Telegram'='Telegram'`.
- **Bugs vistos en React:**
  - `FinancialMovements.js`: `'Paid'` tiene la etiqueta `'Pending'`.
  - `Affiliate/Form_v1.js`: `3='Paused'`.
  - Valor con errata `'Insurace'` (en la tabla se conserva el valor; la etiqueta es Insurance).
- **Explicaciones pendientes:** 28 opciones (TRAFFIC_SOURCE, PRODUCT, BUSINESS_CATEGORY, AFFILIATE_PLATFORM, ACCOUNT_AREA). Se listan con el control c del script.
- **Siguiente paso:** SP/endpoint de lectura (`Report_Options`: varios grupos, Lang, perfil, `Last_Update` para la caché del frontend) y el contrato JSON con el frontend.
