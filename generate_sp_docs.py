import os
import glob
import re
import html as html_lib
import base64
from datetime import datetime
import mysql.connector

# Directorio actual (donde debe ejecutarse el script)
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
TRIGGERS_DIR = os.path.abspath(
    os.path.join(BASE_DIR, '..', 'TRIGGERs', 'TRIGGER_MANUAL')
)

DB_CONFIG = {
    "host": "localhost",
    "port": 3304,
    "user": "b3w1nn3r",
    "password": "abcd",
    "database": "euroaffiliati2",
}


def get_database_tables():
    """
    Obtiene la lista de tablas físicas del esquema configurado.
    Devuelve un diccionario con llave en minúsculas y nombre real como valor.
    """
    conn = None
    cursor = None
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT TABLE_NAME
            FROM information_schema.tables
            WHERE table_schema = %s
              AND table_type = 'BASE TABLE'
            """
            ,
            (DB_CONFIG["database"],),
        )
        rows = cursor.fetchall()
        return {row[0].lower(): row[0] for row in rows}
    except Exception as e:
        print(
            f"Error obteniendo tablas desde MySQL ({DB_CONFIG['database']}): {e}"
        )
        return {}
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()


def parse_sp_file(filepath, db_tables):
    filename = os.path.basename(filepath)
    upper_filename = filename.upper()
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except Exception as e:
        print(f"Error leyendo {filename}: {e}")
        return None

    # Extraer el bloque de comentario inicial /* ... */
    match = re.search(r'^\s*/\*(.*?)\*/', content, re.DOTALL)
    if not match:
        print(f"Aviso: No se encontró el bloque de comentario inicial en {filename}")
        return None
    
    comment_block = match.group(1).strip()
    lines = comment_block.split('\n')
    
    if not lines:
        return None

    # Extraer nombre del objeto desde CREATE ... PROCEDURE/FUNCTION/EVENT/TRIGGER `Nombre`...
    create_obj_match = re.search(
        (
            r'CREATE\s+'
            r'(?:DEFINER\s*=\s*`[^`]+`@`[^`]+`\s+)?'
            r'(?:PROCEDURE|FUNCTION|EVENT|TRIGGER)\s+`?([a-zA-Z0-9_]+)`?'
        ),
        content,
        re.IGNORECASE,
    )

    if create_obj_match:
        raw_title = create_obj_match.group(1).strip()
    else:
        # Fallback: usar primera línea del encabezado si no se encuentra CREATE
        raw_title = lines[0].strip()

    # Para visualización: ocultar prefijos estándar en nombres de archivo/objeto
    title = re.sub(
        r'^(?:PROCEDURE_|EVENT_|FUNCTION_|TRIGGER_)',
        '',
        raw_title,
        flags=re.IGNORECASE,
    )
    
    # Expresiones regulares para identificar las secciones
    sec_observaciones = re.compile(r'^\s*Observaciones:\s*$', re.IGNORECASE)
    sec_keys = re.compile(r'^\s*Keys:\s*$', re.IGNORECASE)
    sec_parametros = re.compile(r'^\s*Parámetros\s*\(.*?\)\s*$', re.IGNORECASE)
    sec_ejemplos = re.compile(r'^\s*Ejemplos:\s*$', re.IGNORECASE)
    # Detecta historial asumiendo que empieza con una fecha dd.mm.yyyy
    sec_historial = re.compile(r'^\s*\d{2}\.\d{2}\.\d{4}.*$', re.IGNORECASE)

    current_section = 'description'
    sections = {
        'title': title,
        'filename': filename,
        'object_type': (
            'SP' if upper_filename.startswith('PROCEDURE_')
            else 'EVENT' if upper_filename.startswith('EVENT_')
            else 'FUNCTION' if (upper_filename.startswith('FUNCTION_'))
            else 'TRIGGER' if upper_filename.startswith('TRIGGER_')
            else 'OTRO'
        ),
        'description': [],
        'ignore': [],
        'keys': [],
        'parametros': [],
        'ejemplos': [],
        'historial': [],
        'tablas': '',
        'source_code': content,
    }

    # Extract tables
    sql_no_comments = re.sub(r'--.*$', '', content, flags=re.MULTILINE)
    sql_no_comments = re.sub(r'/\*.*?\*/', '', sql_no_comments, flags=re.DOTALL)
    table_pattern = re.compile(r'\b(?:FROM|JOIN|UPDATE|INTO)\s+`?([a-zA-Z0-9_]+)`?(?:\.`?([a-zA-Z0-9_]+)`?)?', re.IGNORECASE)
    tables_found = set()
    for match_tbl in table_pattern.finditer(sql_no_comments):
        table_name = match_tbl.group(2) if match_tbl.group(2) else match_tbl.group(1)
        normalized = table_name.lower()
        if table_name.upper() in ('DUAL', 'LATERAL'):
            continue
        if normalized in db_tables:
            tables_found.add(db_tables[normalized])
    sections['tables_list'] = sorted(tables_found)
    sections['tablas'] = '\n'.join(sections['tables_list'])

    # Procesar líneas a partir de la segunda
    for line in lines[1:]:
        stripped = line.strip()
        
        # Determinar si la línea indica un cambio de sección
        if sec_observaciones.match(stripped):
            current_section = 'ignore'
            continue
        elif sec_keys.match(stripped):
            current_section = 'keys'
            continue
        elif sec_parametros.match(stripped):
            sections['parametros'].append(stripped) # Keep the header itself if it has info
            current_section = 'parametros'
            continue
        elif sec_ejemplos.match(stripped):
            current_section = 'ejemplos'
            continue
        elif sec_historial.match(stripped) and current_section != 'historial':
            current_section = 'historial'
            # No hacemos continue aquí para capturar esta línea como parte del historial

        sections[current_section].append(line.rstrip()) # Conservar indentación relativa

    # Limpiar secciones
    for key in ['description', 'keys', 'parametros', 'ejemplos', 'historial']:
        # Eliminar líneas vacías al inicio y al final
        while sections[key] and not sections[key][0].strip():
            sections[key].pop(0)
        while sections[key] and not sections[key][-1].strip():
            sections[key].pop()
            
        sections[key] = '\n'.join(sections[key])

    return sections


def build_table_index(sp_data_list):
    """
    Construye índice inverso: tabla -> lista de objetos SQL que la referencian.
    """
    index = {}
    for sp in sp_data_list:
        for table_name in sp.get('tables_list', []):
            index.setdefault(table_name, []).append({
                'filename': sp['filename'],
                'title': sp.get('title') or sp['filename'],
                'object_type': sp.get('object_type', 'OTRO'),
            })
    for table_name in index:
        index[table_name].sort(
            key=lambda item: (item.get('title') or item['filename']).lower()
        )
    return dict(sorted(index.items(), key=lambda item: item[0].lower()))


def table_dom_id(table_name):
    """Genera un id HTML seguro para una tabla."""
    safe = re.sub(r'[^a-zA-Z0-9_-]', '_', table_name)
    return f'table-{safe}'


def encode_source_b64(text):
    """Codifica el SQL en base64 para incrustarlo de forma segura en el HTML."""
    if not text:
        return ''
    return base64.b64encode(text.encode('utf-8')).decode('ascii')


def generate_html(sp_data_list):
    # Ordenar alfabéticamente por título del SP (extraído desde CREATE PROCEDURE)
    sp_data_list.sort(key=lambda x: (x.get('title') or x.get('filename', '')).lower())
    table_index = build_table_index(sp_data_list)

    def display_sp_name(sp_item):
        # Prioriza el título parseado desde CREATE PROCEDURE.
        if sp_item.get('title'):
            return sp_item['title']
        return re.sub(
            r'^(?:PROCEDURE_|EVENT_|FUNCTION_|TRIGGER_)',
            '',
            sp_item.get('filename', ''),
            flags=re.IGNORECASE,
        )
    
    html = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Documentación de Objetos SQL - Euroaffiliati</title>
    <style>
        :root {{
            --bg-color: #0f172a;
            --sidebar-bg: #1e293b;
            --text-color: #cbd5e1;
            --heading-color: #f8fafc;
            --accent-color: #38bdf8;
            --border-color: #334155;
            --code-bg: #0b1120;
            --card-bg: #1e293b;
        }}
        
        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}

        body {{
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            display: flex;
            height: 100vh;
            overflow: hidden;
            line-height: 1.6;
        }}

        /* Sidebar */
        .sidebar {{
            width: 350px;
            background-color: var(--sidebar-bg);
            border-right: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            height: 100%;
        }}

        .sidebar-header {{
            padding: 20px;
            border-bottom: 1px solid var(--border-color);
        }}

        .sidebar-header h2 {{
            color: var(--heading-color);
            font-size: 1.2rem;
            margin-bottom: 15px;
        }}

        .search-box {{
            width: 100%;
            padding: 10px 15px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background-color: var(--bg-color);
            color: var(--text-color);
            font-size: 0.9rem;
            outline: none;
        }}

        .search-box:focus {{
            border-color: var(--accent-color);
        }}

        .filter-box {{
            width: 100%;
            margin-top: 10px;
            padding: 10px 12px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background-color: var(--bg-color);
            color: var(--text-color);
            font-size: 0.9rem;
            outline: none;
        }}

        .filter-box:focus {{
            border-color: var(--accent-color);
        }}

        .filter-box:focus {{
            border-color: var(--accent-color);
        }}

        .sidebar-tabs {{
            display: flex;
            gap: 6px;
            margin-bottom: 12px;
        }}

        .sidebar-tab {{
            flex: 1;
            padding: 8px 10px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background-color: var(--bg-color);
            color: var(--text-color);
            font-size: 0.82rem;
            cursor: pointer;
            transition: all 0.2s ease;
        }}

        .sidebar-tab:hover {{
            border-color: var(--accent-color);
            color: var(--accent-color);
        }}

        .sidebar-tab.active {{
            background-color: rgba(56, 189, 248, 0.15);
            border-color: var(--accent-color);
            color: var(--accent-color);
            font-weight: 600;
        }}

        .sidebar-panel {{
            display: none;
            flex-direction: column;
            flex: 1;
            min-height: 0;
        }}

        .sidebar-panel.active {{
            display: flex;
        }}

        .table-list-item {{
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
        }}

        .table-list-item .table-count {{
            flex-shrink: 0;
            font-size: 0.72rem;
            color: #94a3b8;
            background-color: var(--bg-color);
            border: 1px solid var(--border-color);
            border-radius: 999px;
            padding: 1px 7px;
        }}

        .table-card {{
            background-color: var(--card-bg);
            border-radius: 8px;
            padding: 30px;
            margin-bottom: 40px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            border: 1px solid var(--border-color);
        }}

        .table-title {{
            color: var(--accent-color);
            font-size: 1.8rem;
            margin-bottom: 8px;
            padding-bottom: 10px;
            border-bottom: 1px solid var(--border-color);
        }}

        .table-subtitle {{
            color: #94a3b8;
            font-size: 0.9rem;
            margin-bottom: 20px;
        }}

        .xref-list {{
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }}

        .xref-list li {{
            margin: 0;
        }}

        .xref-link {{
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            padding: 10px 14px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background-color: var(--code-bg);
            color: var(--text-color);
            text-decoration: none;
            transition: all 0.2s ease;
        }}

        .xref-link:hover {{
            border-color: var(--accent-color);
            color: var(--accent-color);
            background-color: rgba(56, 189, 248, 0.08);
        }}

        .xref-link .xref-type {{
            flex-shrink: 0;
            font-size: 0.72rem;
            color: #94a3b8;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            padding: 2px 6px;
        }}

        .view-table-index .sp-card {{
            display: none;
        }}

        .view-objects .table-card {{
            display: none;
        }}

        .sp-list {{
            flex: 1;
            overflow-y: auto;
            padding: 10px 0;
        }}

        .sp-list-item {{
            display: block;
            padding: 10px 16px;
            color: var(--text-color);
            text-decoration: none;
            font-size: 0.82rem;
            border-left: 3px solid transparent;
            transition: all 0.2s ease;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }}

        .sp-list-item:hover, .sp-list-item.active {{
            background-color: rgba(56, 189, 248, 0.1);
            color: var(--accent-color);
            border-left-color: var(--accent-color);
        }}

        /* Main Content */
        .main-content {{
            flex: 1;
            overflow-y: auto;
            padding: 40px;
            scroll-behavior: smooth;
        }}

        .sp-card {{
            background-color: var(--card-bg);
            border-radius: 8px;
            padding: 30px;
            margin-bottom: 40px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            border: 1px solid var(--border-color);
        }}

        .sp-title {{
            color: var(--accent-color);
            font-size: 1.8rem;
            margin-bottom: 10px;
            padding-bottom: 10px;
            border-bottom: 1px solid var(--border-color);
        }}

        .sp-filename {{
            font-family: monospace;
            background-color: var(--code-bg);
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.9rem;
            color: #94a3b8;
            margin-bottom: 20px;
            display: inline-block;
        }}

        .section-title {{
            color: var(--heading-color);
            font-size: 1.2rem;
            margin: 25px 0 10px 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }}

        .section-title::before {{
            content: '';
            display: block;
            width: 4px;
            height: 1.2rem;
            background-color: var(--accent-color);
            border-radius: 2px;
        }}

        pre {{
            background-color: var(--code-bg);
            padding: 15px;
            border-radius: 6px;
            overflow-x: auto;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 0.9rem;
            border: 1px solid var(--border-color);
            color: #e2e8f0;
            white-space: pre-wrap;
            word-wrap: break-word;
        }}

        .keys-list {{
            background-color: var(--code-bg);
            padding: 15px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
        }}

        .keys-list p {{
            margin-bottom: 8px;
            font-family: monospace;
        }}
        
        /* Generado info */
        .footer-info {{
            text-align: center;
            padding: 20px;
            color: #64748b;
            font-size: 0.85rem;
            margin-top: 40px;
        }}

        /* Empty state */
        .empty-state {{
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
            color: #64748b;
            font-size: 1.2rem;
        }}

        .sp-description {{
            margin-bottom: 10px;
        }}

        .sp-description p {{
            white-space: pre-wrap;
        }}

        .description-actions {{
            margin-bottom: 12px;
        }}

        .btn-source {{
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 8px 14px;
            border-radius: 6px;
            border: 1px solid var(--accent-color);
            background-color: rgba(56, 189, 248, 0.12);
            color: var(--accent-color);
            font-size: 0.85rem;
            font-weight: 500;
            cursor: pointer;
            transition: background-color 0.2s ease, color 0.2s ease;
        }}

        .btn-source:hover {{
            background-color: var(--accent-color);
            color: var(--bg-color);
        }}

        /* Modal código fuente */
        .source-modal {{
            display: none;
            position: fixed;
            inset: 0;
            z-index: 1000;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }}

        .source-modal.is-open {{
            display: flex;
        }}

        .source-modal-overlay {{
            position: absolute;
            inset: 0;
            background-color: rgba(15, 23, 42, 0.82);
            backdrop-filter: blur(2px);
        }}

        .source-modal-dialog {{
            position: relative;
            z-index: 1;
            width: min(1100px, 96vw);
            max-height: 90vh;
            display: flex;
            flex-direction: column;
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 10px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.35);
        }}

        .source-modal-header {{
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            padding: 16px 20px;
            border-bottom: 1px solid var(--border-color);
        }}

        .source-modal-header h3 {{
            color: var(--heading-color);
            font-size: 1rem;
            font-weight: 600;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }}

        .source-modal-actions {{
            display: flex;
            gap: 8px;
            flex-shrink: 0;
        }}

        .btn-modal {{
            padding: 7px 12px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background-color: var(--code-bg);
            color: var(--text-color);
            font-size: 0.82rem;
            cursor: pointer;
            transition: border-color 0.2s ease, color 0.2s ease;
        }}

        .btn-modal:hover {{
            border-color: var(--accent-color);
            color: var(--accent-color);
        }}

        .btn-modal-primary {{
            border-color: var(--accent-color);
            color: var(--accent-color);
        }}

        .source-modal-body {{
            padding: 0;
            overflow: auto;
        }}

        .source-modal-body pre {{
            margin: 0;
            border: none;
            border-radius: 0 0 10px 10px;
            max-height: calc(90vh - 70px);
            font-size: 0.82rem;
            line-height: 1.45;
        }}
    </style>
</head>
<body>

    <div class="sidebar">
        <div class="sidebar-header">
            <h2>Documentación SQL</h2>
            <div class="sidebar-tabs">
                <button type="button" class="sidebar-tab active" data-view="objects" onclick="setSidebarView('objects')">Objetos</button>
                <button type="button" class="sidebar-tab" data-view="tables" onclick="setSidebarView('tables')">Tablas</button>
            </div>
            <input type="text" id="searchInput" class="search-box" placeholder="Buscar objeto...">
            <select id="typeFilter" class="filter-box">
                <option value="ALL">Todos</option>
                <option value="SP">SP</option>
                <option value="EVENT">Events</option>
                <option value="FUNCTION">Functions</option>
                <option value="TRIGGER">Triggers</option>
            </select>
            <input type="text" id="tableSearchInput" class="search-box" placeholder="Buscar tabla..." style="display:none; margin-top:10px;">
        </div>
        <div class="sidebar-panel active" id="objectsPanel">
            <div class="sp-list" id="spList">
                {"".join([f'<a href="#{sp["filename"]}" class="sp-list-item" data-type="{sp.get("object_type", "OTRO")}" onclick="setActiveObject(this)">{display_sp_name(sp)}</a>' for sp in sp_data_list])}
            </div>
        </div>
        <div class="sidebar-panel" id="tablesPanel">
            <div class="sp-list" id="tableList">
                {"".join([
                    f'<a href="#{table_dom_id(table_name)}" class="sp-list-item table-list-item" onclick="setActiveTable(this)">'
                    f'<span>{html_lib.escape(table_name)}</span>'
                    f'<span class="table-count">{len(usages)}</span></a>'
                    for table_name, usages in table_index.items()
                ]) if table_index else '<div class="empty-state" style="padding:20px;font-size:0.9rem;">No hay tablas referenciadas.</div>'}
            </div>
        </div>
    </div>

    <div class="main-content view-objects" id="mainContent">
        """

    if not sp_data_list and not table_index:
        html += '<div class="empty-state">No se encontraron procedimientos documentados.</div>'

    for table_name, usages in table_index.items():
        usage_items = []
        for usage in usages:
            usage_title = html_lib.escape(usage['title'])
            usage_filename = html_lib.escape(usage['filename'], quote=True)
            usage_type = html_lib.escape(usage.get('object_type', 'OTRO'))
            usage_items.append(
                f'<li><a href="#{usage["filename"]}" class="xref-link" '
                f'onclick="openObjectFromTable(event, \'{usage_filename}\')">'
                f'<span>{usage_title}</span>'
                f'<span class="xref-type">{usage_type}</span></a></li>'
            )
        html += f"""
        <div class="table-card" id="{table_dom_id(table_name)}">
            <h2 class="table-title">{html_lib.escape(table_name)}</h2>
            <div class="table-subtitle">{len(usages)} objeto(s) SQL utilizan esta tabla</div>
            <h3 class="section-title">Referencias cruzadas</h3>
            <ul class="xref-list">
                {"".join(usage_items)}
            </ul>
        </div>
        """
    
    for sp in sp_data_list:
        html += f"""
        <div class="sp-card" id="{sp['filename']}" data-type="{sp.get('object_type', 'OTRO')}">
            <h2 class="sp-title">{sp['title']}</h2>
            <div class="sp-filename">{sp['filename']}</div>
        """
        
        source_b64 = encode_source_b64(sp.get('source_code', ''))
        if source_b64 or sp['description']:
            html += """
            <div class="sp-description">
            """
            if source_b64:
                html += f"""
                <div class="description-actions">
                    <button type="button" class="btn-source"
                        data-source-b64="{source_b64}"
                        data-title="{html_lib.escape(sp['title'], quote=True)}"
                        onclick="openSourceModal(this)">
                        Ver código fuente
                    </button>
                </div>
                """
            if sp['description']:
                html += f"""
                <p>{html_lib.escape(sp['description'])}</p>
                """
            html += """
            </div>
            """

        if sp.get('tablas'):
            html += f"""
            <h3 class="section-title">Tablas Utilizadas</h3>
            <div class="keys-list">
                <pre>{sp['tablas']}</pre>
            </div>
            """

        if sp['keys']:
            html += f"""
            <h3 class="section-title">Keys (Parámetros de Entrada)</h3>
            <div class="keys-list">
                <pre>{sp['keys']}</pre>
            </div>
            """
            
        if sp['parametros']:
            html += f"""
            <div style="margin-top: 10px; font-style: italic; color: #94a3b8;">
                {sp['parametros']}
            </div>
            """

        if sp['ejemplos']:
            html += f"""
            <h3 class="section-title">Ejemplos de Uso</h3>
            <pre>{sp['ejemplos']}</pre>
            """

        if sp['historial']:
            html += f"""
            <h3 class="section-title">Historial de Versiones</h3>
            <pre>{sp['historial']}</pre>
            """

        html += """
        </div>
        """
        
    html += f"""
        <div class="footer-info">
            Documentación generada automáticamente el {datetime.now().strftime("%d/%m/%Y a las %H:%M:%S")}
        </div>
    </div>

    <div id="sourceModal" class="source-modal" aria-hidden="true">
        <div class="source-modal-overlay" onclick="closeSourceModal()"></div>
        <div class="source-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="sourceModalTitle">
            <div class="source-modal-header">
                <h3 id="sourceModalTitle">Código fuente</h3>
                <div class="source-modal-actions">
                    <button type="button" class="btn-modal btn-modal-primary" onclick="openSourceInNewTab()">Nueva pestaña</button>
                    <button type="button" class="btn-modal" onclick="closeSourceModal()">Cerrar</button>
                </div>
            </div>
            <div class="source-modal-body">
                <pre id="sourceModalCode"></pre>
            </div>
        </div>
    </div>

    <script>
        // Funcionalidad de búsqueda y filtro por tipo
        const searchInput = document.getElementById('searchInput');
        const tableSearchInput = document.getElementById('tableSearchInput');
        const typeFilter = document.getElementById('typeFilter');
        const spListItems = document.querySelectorAll('.sp-list-item:not(.table-list-item)');
        const tableListItems = document.querySelectorAll('.table-list-item');
        const spCards = document.querySelectorAll('.sp-card');
        const tableCards = document.querySelectorAll('.table-card');
        const mainContent = document.getElementById('mainContent');
        const objectsPanel = document.getElementById('objectsPanel');
        const tablesPanel = document.getElementById('tablesPanel');
        const sidebarTabs = document.querySelectorAll('.sidebar-tab');
        let currentView = 'objects';

        function setSidebarView(view) {{
            currentView = view;
            sidebarTabs.forEach(tab => {{
                tab.classList.toggle('active', tab.dataset.view === view);
            }});
            objectsPanel.classList.toggle('active', view === 'objects');
            tablesPanel.classList.toggle('active', view === 'tables');
            mainContent.classList.toggle('view-objects', view === 'objects');
            mainContent.classList.toggle('view-table-index', view === 'tables');
            searchInput.style.display = view === 'objects' ? 'block' : 'none';
            typeFilter.style.display = view === 'objects' ? 'block' : 'none';
            tableSearchInput.style.display = view === 'tables' ? 'block' : 'none';
            if (view === 'objects') {{
                applyObjectFilters();
            }} else {{
                applyTableFilters();
            }}
        }}

        function applyObjectFilters() {{
            const selectedType = typeFilter.value;
            const searchTerm = searchInput.value.toLowerCase();

            spListItems.forEach(item => {{
                const text = item.textContent.toLowerCase();
                const itemType = item.dataset.type || 'OTRO';
                const matchesSearch = text.includes(searchTerm);
                const matchesType = selectedType === 'ALL' || itemType === selectedType;
                item.style.display = (matchesSearch && matchesType) ? 'block' : 'none';
            }});

            spCards.forEach(card => {{
                const cardType = card.dataset.type || 'OTRO';
                card.style.display = (selectedType === 'ALL' || cardType === selectedType) ? 'block' : 'none';
            }});
        }}

        function applyTableFilters() {{
            const searchTerm = tableSearchInput.value.toLowerCase();
            tableListItems.forEach(item => {{
                const text = item.textContent.toLowerCase();
                item.style.display = text.includes(searchTerm) ? 'flex' : 'none';
            }});
            tableCards.forEach(card => {{
                const text = card.textContent.toLowerCase();
                card.style.display = text.includes(searchTerm) ? 'block' : 'none';
            }});
        }}

        function applyFilters() {{
            if (currentView === 'tables') {{
                applyTableFilters();
            }} else {{
                applyObjectFilters();
            }}
        }}

        searchInput.addEventListener('input', function() {{
            applyObjectFilters();
        }});

        tableSearchInput.addEventListener('input', function() {{
            applyTableFilters();
        }});

        typeFilter.addEventListener('change', function() {{
            applyObjectFilters();
        }});

        function clearActiveSidebarItems() {{
            document.querySelectorAll('.sp-list-item').forEach(item => {{
                item.classList.remove('active');
            }});
        }}

        function setActiveObject(element) {{
            clearActiveSidebarItems();
            element.classList.add('active');
        }}

        function setActiveTable(element) {{
            clearActiveSidebarItems();
            element.classList.add('active');
        }}

        function openObjectFromTable(event, filename) {{
            event.preventDefault();
            setSidebarView('objects');
            const targetCard = document.getElementById(filename);
            const targetLink = document.querySelector(`.sp-list-item[href="#${{filename}}"]`);
            if (targetLink) {{
                setActiveObject(targetLink);
            }}
            if (targetCard) {{
                targetCard.scrollIntoView({{ behavior: 'smooth', block: 'start' }});
            }}
        }}

        // Interseption observer para actualizar la barra lateral al hacer scroll
        const observerOptions = {{
            root: document.getElementById('mainContent'),
            rootMargin: '0px',
            threshold: 0.1
        }};

        const objectObserver = new IntersectionObserver((entries) => {{
            if (currentView !== 'objects') {{
                return;
            }}
            entries.forEach(entry => {{
                if (entry.isIntersecting) {{
                    const id = entry.target.id;
                    const activeLink = document.querySelector(`.sp-list-item[href="#${{id}}"]`);
                    if (activeLink) {{
                        clearActiveSidebarItems();
                        activeLink.classList.add('active');
                    }}
                }}
            }});
        }}, observerOptions);

        const tableObserver = new IntersectionObserver((entries) => {{
            if (currentView !== 'tables') {{
                return;
            }}
            entries.forEach(entry => {{
                if (entry.isIntersecting) {{
                    const id = entry.target.id;
                    const activeLink = document.querySelector(`.table-list-item[href="#${{id}}"]`);
                    if (activeLink) {{
                        clearActiveSidebarItems();
                        activeLink.classList.add('active');
                    }}
                }}
            }});
        }}, observerOptions);

        document.querySelectorAll('.sp-card').forEach(card => {{
            objectObserver.observe(card);
        }});

        document.querySelectorAll('.table-card').forEach(card => {{
            tableObserver.observe(card);
        }});

        // Aplicar filtros iniciales
        applyObjectFilters();

        // Modal de código fuente
        let currentSourceText = '';
        let currentSourceTitle = '';
        const sourceModal = document.getElementById('sourceModal');
        const sourceModalTitle = document.getElementById('sourceModalTitle');
        const sourceModalCode = document.getElementById('sourceModalCode');

        function decodeBase64Utf8(b64) {{
            const binary = atob(b64);
            const bytes = new Uint8Array(binary.length);
            for (let i = 0; i < binary.length; i++) {{
                bytes[i] = binary.charCodeAt(i);
            }}
            return new TextDecoder('utf-8').decode(bytes);
        }}

        function openSourceModal(button) {{
            currentSourceText = decodeBase64Utf8(button.dataset.sourceB64 || '');
            currentSourceTitle = button.dataset.title || 'Código fuente';
            sourceModalTitle.textContent = currentSourceTitle;
            sourceModalCode.textContent = currentSourceText;
            sourceModal.classList.add('is-open');
            sourceModal.setAttribute('aria-hidden', 'false');
            document.body.style.overflow = 'hidden';
        }}

        function closeSourceModal() {{
            sourceModal.classList.remove('is-open');
            sourceModal.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
        }}

        function openSourceInNewTab() {{
            if (!currentSourceText) {{
                return;
            }}
            const blob = new Blob([currentSourceText], {{ type: 'text/plain;charset=utf-8' }});
            const url = URL.createObjectURL(blob);
            const newWindow = window.open(url, '_blank');
            if (!newWindow) {{
                alert('El navegador bloqueó la nueva pestaña. Permita ventanas emergentes para este sitio.');
                URL.revokeObjectURL(url);
                return;
            }}
            newWindow.addEventListener('beforeunload', () => {{
                URL.revokeObjectURL(url);
            }});
        }}

        document.addEventListener('keydown', (event) => {{
            if (event.key === 'Escape' && sourceModal.classList.contains('is-open')) {{
                closeSourceModal();
            }}
        }});
    </script>
</body>
</html>
"""
    return html

def main():
    print("Iniciando generación de documentación...")
    db_tables = get_database_tables()
    if db_tables:
        print(
            f"Se obtuvieron {len(db_tables)} tablas del esquema {DB_CONFIG['database']}."
        )
    else:
        print(
            f"Aviso: no se pudo obtener la lista de tablas de {DB_CONFIG['database']}."
        )
        print("La sección de tablas utilizadas quedará vacía.")

    source_patterns = [
        (BASE_DIR, ['PROCEDURE_*.sql', 'EVENT_*.sql', 'FUNCTION_*.sql']),
        (TRIGGERS_DIR, ['TRIGGER_*.sql', 'TRIGGER_*.SQL']),
    ]
    sp_files = []
    for source_dir, patterns in source_patterns:
        for pattern in patterns:
            sp_files.extend(glob.glob(os.path.join(source_dir, pattern)))

    # Evita duplicados si un mismo archivo cae en más de un patrón
    sp_files = sorted(list(set(sp_files)))
    print(
        f"Se encontraron {len(sp_files)} archivos con prefijos: "
        + ", ".join([p for _, p_list in source_patterns for p in p_list])
    )
    
    sp_data_list = []
    
    for filepath in sp_files:
        data = parse_sp_file(filepath, db_tables)
        if data:
            sp_data_list.append(data)
            
    print(f"Se parsearon exitosamente {len(sp_data_list)} archivos.")
    
    html_content = generate_html(sp_data_list)
    output_path = os.path.join(BASE_DIR, 'SP_Documentation.html')
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
        
    print(f"Documentación generada exitosamente en: {output_path}")

if __name__ == "__main__":
    main()
