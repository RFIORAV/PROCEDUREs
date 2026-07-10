# Generación Automática de Documentación de Objetos SQL

El script `generate_sp_docs.py` genera una documentación HTML consolidada de objetos SQL del proyecto, con navegación lateral, búsqueda y filtros por tipo.

## Alcance Actual del Generador

El script ya no documenta solo Stored Procedures.

Actualmente procesa:
- `PROCEDURE_*.sql` (SPs)
- `EVENT_*.sql` (Events)
- `FUNCTION_*.sql` (Functions)
- `TRIGGER_*.sql` y `TRIGGER_*.SQL` dentro de `..\TRIGGERs\TRIGGER_MANUAL`

Archivo de salida:
- `SP_Documentation.html` (en `d:\Reinaldo\_FRA\db\PROCEDUREs`)

## Funciones y Características Nuevas

### 1) Parseo de múltiples tipos de objeto
- Detecta el nombre real del objeto desde `CREATE PROCEDURE/FUNCTION/EVENT/TRIGGER`.
- Clasifica cada elemento por tipo (`SP`, `EVENT`, `FUNCTION`, `TRIGGER`).
- Si no detecta el `CREATE`, usa como respaldo la primera línea del bloque de comentarios.

### 2) Extracción mejorada del contenido documental
- Lee el bloque inicial `/* ... */`.
- Extrae y organiza:
  - Descripción
  - `Keys`
  - `Parámetros (...)`
  - `Ejemplos`
  - `Historial` (líneas que comienzan con fecha `dd.mm.yyyy`)
- Mantiene indentación para que el contenido se vea correctamente en HTML.

### 3) Descubrimiento automático de tablas utilizadas
- Se conecta a MySQL con `mysql.connector` usando `DB_CONFIG`.
- Lee tablas físicas (`BASE TABLE`) desde `information_schema.tables`.
- Analiza SQL del archivo (sin comentarios) para detectar tablas en cláusulas:
  - `FROM`
  - `JOIN`
  - `UPDATE`
  - `INTO`
- Muestra en la documentación la sección **Tablas Utilizadas**.
- Si falla la conexión o lectura del esquema, el proceso continúa y esa sección queda vacía.

### 4) Interfaz HTML mejorada
- Diseño responsive con tema oscuro.
- Barra lateral con:
  - Búsqueda por texto
  - Filtro por tipo (`Todos`, `SP`, `Events`, `Functions`, `Triggers`)
- Sincronización visual de navegación con scroll (item activo automático).
- Orden alfabético por nombre del objeto detectado.

### 5) Normalización visual de nombres
- En la vista se ocultan prefijos estándar (`PROCEDURE_`, `EVENT_`, `FUNCTION_`, `TRIGGER_`) para legibilidad.
- Se conserva el nombre de archivo real en cada ficha.

## Requisitos

- Python 3.10+
- Paquete `mysql-connector-python`

Instalación:
```bash
pip install mysql-connector-python
```

## Configuración de Base de Datos

El script utiliza `DB_CONFIG` definido en `generate_sp_docs.py`:
- Host: `localhost`
- Puerto: `3308`
- Usuario: `b3w1nn3r`
- Base: `euroaffiliati2`

Si cambian los datos de conexión, actualizar este bloque antes de ejecutar.

## Cómo Ejecutarlo

Desde la carpeta `PROCEDUREs`:

```bash
python generate_sp_docs.py
```

Durante la ejecución se informa:
- Cantidad de tablas obtenidas del esquema
- Cantidad de archivos encontrados
- Cantidad de archivos parseados correctamente
- Ruta final del HTML generado

## Buenas Prácticas para que la Documentación Salga Completa

- Mantener el bloque inicial `/* ... */` en cada archivo SQL.
- Respetar etiquetas esperadas:
  - `Observaciones:`
  - `Keys:`
  - `Parámetros (...)`
  - `Ejemplos:`
  - Historial con fecha `dd.mm.yyyy ...`
- Incluir sentencias SQL claras para mejorar la detección de tablas.

## Resultado

`SP_Documentation.html` queda listo para abrir en navegador y consultar de forma centralizada la documentación de SPs, Events, Functions y Triggers del proyecto.
