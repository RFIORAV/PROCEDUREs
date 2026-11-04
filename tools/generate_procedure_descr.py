#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Genera archivos .descr para cada PROCEDURE_*.sql (un .descr por nombre de SP)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

HEADER_RE = re.compile(r"/\*(.*?)\*/", re.DOTALL)
PROC_RE = re.compile(
    r"CREATE\s+(?:DEFINER\s*=\s*[`'\"][^`'\"]+[`'\"]\s*@\s*[`'\"][^`'\"]+[`'\"]\s+)?"
    r"PROCEDURE\s+[`'\"]?(\w+)[`'\"]?",
    re.IGNORECASE,
)
COMMENT_RE = re.compile(r"COMMENT\s+'([^']*)'", re.IGNORECASE)

TABLE_SKIP = {
    "dual", "information_schema", "the", "each", "base", "not", "null", "where",
    "set", "select", "from", "into", "as", "on", "and", "or", "then", "else",
    "when", "case", "lateral", "desc", "asc", "factx", "ms_filtered", "filtered",
    "tmp", "temp", "cte", "subq", "t1", "t2", "t3", "a", "b", "c", "d", "m", "p",
}

TABLE_RE = re.compile(
    r"(?:FROM|JOIN|INTO|UPDATE)\s+[`'\"]?([a-zA-Z_][\w]*)[`'\"]?",
    re.IGNORECASE,
)

CATEGORY_HINTS = [
    ("Report_", "reporte tabular / exportación para grids dinámicos"),
    ("Dash_", "dashboard con KPIs y agregaciones para paneles"),
    ("Sync_", "sincronización ETL entre tablas o entornos"),
    ("Snapshot_", "generación o refresco de snapshots históricos"),
    ("Compare_", "comparación / auditoría de diferencias"),
    ("Check_", "validación, control de calidad o diagnóstico"),
    ("Edit_", "edición y persistencia (UPDATE/INSERT)"),
    ("HandleEdit", "operación transaccional de edición"),
    ("CopyTables", "copia de tablas entre entornos"),
    ("Optimize_", "mantenimiento de base de datos"),
    ("Log_Processes", "registro y trazabilidad de procesos"),
    ("monthly_comms", "cálculo de comisiones mensuales"),
    ("total_monthly", "totales mensuales de comisiones"),
    ("Aff_Channels", "portal afiliado: canales y deals por MS"),
    ("Aff_", "portal afiliado"),
    ("Affiliate_", "gestión / reportes de afiliados"),
    ("Gestor_", "portal gestor / publisher"),
    ("MS_", "marketing sources"),
    ("DbD_", "datos day-by-day (DbD)"),
    ("Cap_", "límites CPA / caps"),
    ("Postback", "postbacks salientes o entrantes"),
    ("TEST_", "pruebas de reglas de negocio"),
    ("Util_", "utilidad de administración de BD"),
    ("util_", "utilidad de administración de BD"),
    ("Calculate_", "cálculo de comisiones u operaciones"),
    ("Monitor_", "monitorización de tendencias"),
    ("Show_", "consultas de diferencias o alertas"),
    ("Publisher_", "operaciones de publisher"),
    ("TEMPLATE", "plantilla para nuevos SP"),
]

# Descripciones de negocio por nombre exacto o prefijo
BUSINESS_BY_NAME: dict[str, str] = {
    "Aff_Channel_DealMS": (
        "Reporte del portal de afiliado que lista marketing sources (MS) de un canal concreto, "
        "sus deals activos, métricas del mes corriente (CPA, FTD, clics, depósitos, etc.) desde "
        "`Snapshot_day_by_day_fact2`, shortlinks, landing pages y anuncios (Ads). "
        "Filtra MS activas (`Stat_aggreg` in 1,4,6) y deals vigentes según `DateLimitView`. "
        "Soporta subafiliados (grupo 6 en `account_account_groups`). "
        "Salida orientada a grilla con Meta=Yes (columnas Logo, Brand, Code, Deal, CPA Current/Limit, LP, Ads)."
    ),
    "Report_Channels": (
        "Listado de canales (landing pages / account_landing_pages) con filtros por afiliado, "
        "subafiliado, status, producto y modo MAF (master afiliado). "
        "Pensado para administración y portal; admite Filters y Meta para UI dinámica."
    ),
    "Optimize_tables": (
        "Mantenimiento: recorre tablas BASE de la BD activa y ejecuta TRUNCATE en tablas vacías "
        "(COUNT(*)=0) para liberar espacio y reiniciar AUTO_INCREMENT. "
        "Execute=No solo lista candidatas; Debug=Yes muestra SQL sin ejecutar."
    ),
    "Report_day_by_day": (
        "Reporte day-by-day (DbD) con desglose diario de métricas de afiliación; "
        "variante manual para ajustes o fuentes específicas según versión del archivo."
    ),
    "Dash_BrandMatrix": (
        "Dashboard matricial por brand con datos agregados para visualización gráfica "
        "(BrandMatrix); incluye subtotales y metadatos de renderizado."
    ),
}


def read_text(path: Path) -> str:
    for enc in ("utf-8", "utf-8-sig", "latin-1"):
        try:
            return path.read_text(encoding=enc)
        except UnicodeDecodeError:
            continue
    return path.read_text(encoding="utf-8", errors="replace")


def version_score(filename: str) -> tuple:
    """Mayor = más reciente / preferido."""
    name = filename.lower()
    score = 0
    if "test" in name or "obsolet" in name or ".old" in name:
        score -= 100
    m = re.search(r"_v(\d+(?:\.\d+)*)", filename, re.I)
    if m:
        parts = [int(x) for x in m.group(1).split(".")]
        score += sum(p * (100 ** (4 - i)) for i, p in enumerate(parts[:4]))
    return (score, filename)


def pick_best_files(files: list[Path]) -> dict[str, Path]:
    by_proc: dict[str, list[Path]] = {}
    for path in files:
        content = read_text(path)
        m = PROC_RE.search(content)
        if not m:
            continue
        by_proc.setdefault(m.group(1), []).append(path)
    return {proc: max(paths, key=lambda p: version_score(p.name)) for proc, paths in by_proc.items()}


def extract_header_block(content: str) -> str:
    m = HEADER_RE.search(content)
    return m.group(1).strip() if m else ""


def extract_title_line(header: str, filename: str, proc_name: str) -> str:
    for line in header.splitlines():
        line = line.strip()
        if line and "PROCEDURE_" in line:
            return line
        if line and " - " in line and proc_name.lower() in line.lower():
            return line
    return f"{filename} - {proc_name}"


def extract_short_description(header: str) -> str:
    m = re.search(
        r"Descripción\s*:\s*\n?\s*(.+?)(?=\n\s*\n|\n\s*Observaciones|\n\s*Keys:|\Z)",
        header,
        re.DOTALL | re.IGNORECASE,
    )
    return " ".join(m.group(1).split()) if m else ""


def extract_keys_section(header: str) -> str:
    m = re.search(
        r"Keys\s*:(.*?)(?=Par[aá]metros|Ejemplos|\d{2}\.\d{2}\.\d{4}|\Z)",
        header,
        re.DOTALL | re.IGNORECASE,
    )
    return m.group(1).strip() if m else ""


def extract_observaciones(header: str) -> str:
    m = re.search(
        r"Observaciones\s*:(.*?)(?=Keys\s*:|Par[aá]metros|Ejemplos|\d{2}\.\d{2}\.\d{4}|\Z)",
        header,
        re.DOTALL | re.IGNORECASE,
    )
    return m.group(1).strip() if m else ""


def extract_examples(header: str, proc_name: str) -> list[str]:
    m = re.search(r"Ejemplos?\s*:(.*?)(?=\d{2}\.\d{2}\.\d{4}|\Z)", header, re.DOTALL | re.IGNORECASE)
    block = m.group(1) if m else ""
    examples = []
    for line in block.splitlines():
        line = line.strip()
        if re.match(r"(?i)(call|CALL)\s+", line):
            examples.append(line)
    if not examples:
        examples = [
            f"call {proc_name}('Debug=KeyValues');",
            f"call {proc_name}('Filters=Yes');",
        ]
    return examples


def extract_version_history(header: str) -> list[str]:
    return [ln.strip() for ln in header.splitlines() if re.match(r"\d{2}\.\d{2}\.\d{4}", ln.strip())]


SETTING_MARKER_RE = re.compile(r'''["']setting["']\s+as\s+Meta''', re.IGNORECASE)
FROM_DUAL_RE = re.compile(r"FROM\s+DUAL", re.IGNORECASE)
OMIT_IN_SETTING_RE = re.compile(r"omit\s*=\s*(?:yes|true)", re.IGNORECASE)
COLUMN_LINE_RE = re.compile(
    r"(?:^|,)\s*(.+?)\s+as\s+(`[^`]+`|'[^']+'|[A-Za-z_][\w ]*)\s*,?\s*$",
    re.IGNORECASE,
)
COLUMN_LINE_AS_RE = re.compile(
    r"['\"]([^'\"]+)['\"]\s+AS\s+(`[^`]+`|'[^']+'|[A-Za-z_][\w ]*)\s*,?\s*$",
    re.IGNORECASE,
)
COLUMN_LINE_IF_RE = re.compile(
    r"(?:^|,)\s*(IF\s*\(.+\))\s+as\s+(`[^`]+`|'[^']+'|[A-Za-z_][\w ]*)\s*,?\s*$",
    re.IGNORECASE,
)


def _parse_column_from_line(line: str) -> tuple[str, str] | None:
    line = re.sub(r"--.*$", "", line).strip()
    if not line or SETTING_MARKER_RE.search(line):
        return None

    m = COLUMN_LINE_IF_RE.search(line)
    if m:
        return m.group(1).strip(), m.group(2)

    m = COLUMN_LINE_RE.search(line)
    if m:
        return m.group(1).strip(), m.group(2)

    m = COLUMN_LINE_AS_RE.search(line)
    if m:
        return f'"{m.group(1)}"', m.group(2)

    return None


def _clean_column_alias(alias: str) -> str:
    alias = alias.strip()
    if len(alias) >= 2 and alias[0] == alias[-1] and alias[0] in ("`", "'"):
        return alias[1:-1]
    return alias


def _setting_directive_is_omit(val: str) -> bool:
    """True si la directiva Meta de la columna equivale a omit (yes/true)."""
    val = val.strip()
    if re.match(r"IF\s*\(", val, re.IGNORECASE):
        strings = re.findall(r'"([^"]*)"', val)
        if not strings:
            strings = re.findall(r"'([^']*)'", val)
        if not strings:
            return False
        return all(OMIT_IN_SETTING_RE.search(s) for s in strings)
    return bool(OMIT_IN_SETTING_RE.search(val))


def _extract_setting_blocks(content: str) -> list[str]:
    blocks: list[str] = []
    for m in SETTING_MARKER_RE.finditer(content):
        chunk = content[m.start() : m.start() + 8000]
        end_m = FROM_DUAL_RE.search(chunk)
        if end_m:
            blocks.append(chunk[: end_m.end()])
    return blocks


def extract_visible_columns(content: str) -> list[str]:
    """Columnas del reporte visibles en fila Meta=setting (excluye omit=yes/true)."""
    visible: list[str] = []
    seen: set[str] = set()

    for block in _extract_setting_blocks(content):
        for line in block.splitlines():
            parsed = _parse_column_from_line(line)
            if not parsed:
                continue
            val, alias_raw = parsed
            alias = _clean_column_alias(alias_raw)
            if alias.lower() == "meta" or alias in seen:
                continue
            if _setting_directive_is_omit(val):
                continue
            seen.add(alias)
            visible.append(alias)

    return visible


def infer_category(filename: str) -> str:
    for prefix, desc in CATEGORY_HINTS:
        if filename.startswith(prefix) or prefix in filename:
            return desc
    return "procedimiento almacenado euroaffiliati"


def business_description(proc_name: str, filename: str, short_desc: str, comment: str) -> str:
    if proc_name in BUSINESS_BY_NAME:
        return BUSINESS_BY_NAME[proc_name]

    # heurística por tokens del nombre
    tokens = re.findall(r"[A-Za-z]+", proc_name)
    lower = proc_name.lower()
    parts = []

    if lower.startswith("report_"):
        domain = proc_name.replace("Report_", "").replace("_", " ")
        parts.append(f"Reporte de {domain}. Devuelve filas para consulta/exportación.")
    elif lower.startswith("dash_"):
        domain = proc_name.replace("Dash_", "").replace("_", " ")
        parts.append(f"Dashboard: {domain}. Agrega métricas para visualización en panel.")
    elif lower.startswith("sync_"):
        parts.append("Proceso de sincronización/replicación de datos entre fuentes del sistema.")
    elif "monthly" in lower and "comm" in lower:
        parts.append("Calcula o actualiza comisiones mensuales de afiliados o gestores.")
    elif lower.startswith("check_"):
        parts.append("Validación o diagnóstico; revisar discrepancias o reglas de negocio.")
    elif lower.startswith("edit_") or lower.startswith("handle"):
        parts.append("Operación de escritura; modifica registros — usar con precaución en producción.")
    else:
        parts.append(f"Procedimiento `{proc_name}` del dominio {filename.replace('PROCEDURE_', '').split('_v')[0]}.")

    if short_desc and short_desc not in parts[0]:
        parts.append(short_desc)
    if comment:
        parts.append(comment)
    return " ".join(parts)


def top_tables(content: str, limit: int = 10) -> list[str]:
    counts: dict[str, int] = {}
    for m in TABLE_RE.finditer(content):
        t = m.group(1)
        if t.lower() in TABLE_SKIP or len(t) < 3:
            continue
        if t[0].isupper() and "_" not in t and t.isupper() is False and len(t) < 5:
            continue
        counts[t] = counts.get(t, 0) + 1
    return [t for t, _ in sorted(counts.items(), key=lambda x: (-x[1], x[0]))[:limit]]


def detect_capabilities(content: str) -> list[str]:
    caps = []
    if re.search(r"Filters|filters|'filters'", content):
        caps.append("Filters=Yes → devuelve valores disponibles por filtro (Korder, Key, Value, Caption, id, extra).")
    if re.search(r"Meta|'setting'\s+AS\s+Meta|as Meta", content, re.I):
        caps.append("Meta=Yes → primera fila `setting`, datos en `data`, totales en `total` para grids dinámicos.")
    if re.search(r"Debug|KEYVALUES|PREPARE", content, re.I):
        caps.append("Debug=Yes → SQL generado sin ejecutar; Debug=KeyValues → parámetros parseados.")
    if "START TRANSACTION" in content.upper():
        caps.append("Transaccional: START TRANSACTION / COMMIT / ROLLBACK.")
    if re.search(r"DECLARE\s+.*HANDLER", content, re.I):
        caps.append("Manejo de errores con HANDLER.")
    if re.search(r"\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bTRUNCATE\b", content, re.I):
        caps.append("Incluye operaciones DML (escritura o mantenimiento).")
    return caps


def extract_mandatory_keys(content: str) -> list[str]:
    found = []
    if re.search(r"Affiliate_id.*mandatory|Affiliate_id.*OBLIGATORIO", content, re.I):
        found.append("Affiliate_id")
    m = re.search(
        r"IF\s+.*?(@Affiliate_id|v_Affiliate_id).*IN\s*\([^)]*ALL[^)]*\)",
        content,
        re.I | re.DOTALL,
    )
    if m and "Affiliate_id" not in found:
        found.append("Affiliate_id (no ALL)")
    m2 = re.search(
        r"IF\s+.*?(@Channel_id|v_Channel_id).*IN\s*\([^)]*ALL[^)]*\)",
        content,
        re.I | re.DOTALL,
    )
    if m2:
        found.append("Channel_id (no ALL)")
    return found


def when_to_call(proc_name: str, filename: str, mandatory: list[str]) -> str:
    fn = filename.lower()
    pn = proc_name.lower()
    base = (
        "Construir `call {proc}('Key=valor,...')` con valores sin comillas, cada par terminado en coma "
        "dentro del string."
    ).format(proc=proc_name)

    if mandatory:
        base += f" Parámetros obligatorios detectados: {', '.join(mandatory)}."

    if pn.startswith("report_") or pn.startswith("dash_") or "aff_" in pn:
        base += (
            " Si el usuario pide un listado o panel del mismo dominio, usar Filters=Yes para descubrir "
            "valores válidos y Meta=Yes si consume la UI de reportes."
        )
    elif "sync" in pn or "snapshot" in pn or "upd" in fn:
        base += " Uso batch/ETL; no es consulta ad hoc de usuario final."
    elif "edit" in pn or "handle" in pn or "set_record" in pn:
        base += " Solo cuando el requerimiento implica modificar datos; confirmar keys antes de ejecutar."

    return base


def default_observaciones_block() -> str:
    return (
        "Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles \")\n"
        "Cada par Key=Value debe ir seguido por una COMA\n"
        "El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE."
    )


def build_descr(path: Path, proc_name: str) -> str:
    content = read_text(path)
    header = extract_header_block(content)
    title = extract_title_line(header, path.name, proc_name)
    short_desc = extract_short_description(header)
    keys = extract_keys_section(header)
    observaciones = extract_observaciones(header)
    examples = extract_examples(header, proc_name)
    comment_m = COMMENT_RE.search(content)
    comment = comment_m.group(1).strip() if comment_m else ""

    category = infer_category(path.name)
    biz = business_description(proc_name, path.name, short_desc, comment)
    tables = top_tables(content)
    caps = detect_capabilities(content)
    mandatory = extract_mandatory_keys(content)
    when = when_to_call(proc_name, path.name, mandatory)
    visible_cols = extract_visible_columns(content)

    detailed_lines = [
        f"Cometido: {biz}",
        f"Categoría: {category}.",
    ]
    if visible_cols:
        detailed_lines.append(
            "Columnas visibles del reporte (fila Meta=setting, sin omit=yes/true): "
            + ", ".join(visible_cols)
            + "."
        )
    if tables:
        detailed_lines.append(
            "Tablas clave: " + ", ".join(tables) + "."
        )
    if caps:
        detailed_lines.append("Modos y comportamiento:")
        for c in caps:
            detailed_lines.append(f"  - {c}")
    detailed_lines.append(f"Cuándo proponer el CALL: {when}")

    obs = observaciones if observaciones else ""
    if "cada key" not in obs.lower():
        obs = default_observaciones_block() + ("\n\n" + obs if obs else "")

    keys_block = keys if keys else (
        "InputCommLine = [Key=Value,...]. Parámetro único de entrada.\n\n"
        "Debug = [No | Yes | KeyValues]. OPCIONAL. Default=No."
    )

    out = [
        "/*",
        title,
        "",
        "Descripción, cometido y funciones:",
        *detailed_lines,
        "",
        "Observaciones:",
        "",
        obs.strip(),
        "",
        "Keys:",
        keys_block,
        "",
        "Parámetros ('[Key=Value[,...]]')",
        "",
        "Ejemplos:",
        "",
        *examples,
        "",
    ]
    out.append("*/")
    out.append("")
    return "\n".join(out)


def script_only_descr(path: Path) -> str | None:
    """Archivos SQL sin CREATE PROCEDURE."""
    name = path.stem
    if "Check_CAP_limit" in name:
        return "\n".join([
            "/*",
            f"{path.name} - Script Check CAP limit (sin CREATE PROCEDURE)",
            "",
            "Descripción, cometido y funciones:",
            "Cometido: Script de consulta/diagnóstico de límites CPA (CAP) del mes corriente.",
            "Compara CPA acumulado en snapshots contra límites configurados en publisher, brand, username, affiliate y MS.",
            "No es un stored procedure invocable con CALL; ejecutar el script SQL completo en la sesión MySQL.",
            "",
            "Observaciones:",
            "No usa InputCommLine. Parámetro de sesión `@Margen_Limit` (default 0.95) al inicio del script.",
            "",
            "Keys:",
            "(No aplica — script directo, no SP)",
            "",
            "Ejemplos:",
            "SOURCE d:/Reinaldo/_FRA/db/PROCEDUREs/PROCEDURE_Check_CAP_limit_v1.sql;",
            "",
            "*/",
            "",
        ])
    if "CompareDB_create" in name:
        return "\n".join([
            "/*",
            f"{path.name} - Util CompareDB (sin CREATE PROCEDURE)",
            "",
            "Descripción, cometido y funciones:",
            "Cometido: Utilidad interactiva que compara la BD activa contra euroaffiliati2",
            "y genera sentencias CREATE TABLE (y triggers) faltantes. Pensado para ejecutar manualmente",
            "copiando el resultado de los SELECT generados.",
            "",
            "Observaciones:",
            "Ejecutar interactivamente; revisar cada CREATE antes de aplicar en destino.",
            "",
            "Keys:",
            "(No aplica — script directo)",
            "",
            "Ejemplos:",
            "SOURCE d:/Reinaldo/_FRA/db/PROCEDUREs/PROCEDURE_Util_CompareDB_create_tables_and_triggers.sql;",
            "",
            "*/",
            "",
        ])
    return None


def main() -> int:
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT
    sql_files = sorted(ROOT.glob("PROCEDURE_*.sql")) + sorted(ROOT.glob("PROCEDURE_*.SQL"))
    # dedupe paths
    seen_paths: set[str] = set()
    unique_files: list[Path] = []
    for p in sql_files:
        key = str(p.resolve()).lower()
        if key not in seen_paths:
            seen_paths.add(key)
            unique_files.append(p)

    best = pick_best_files(unique_files)
    created = 0

    for proc_name, path in sorted(best.items()):
        body = build_descr(path, proc_name)
        (out_dir / f"{proc_name}.descr").write_text(body, encoding="utf-8")
        created += 1

    for path in unique_files:
        content = read_text(path)
        if PROC_RE.search(content):
            continue
        body = script_only_descr(path)
        if body:
            out_name = path.stem.replace("PROCEDURE_", "") + ".descr"
            (out_dir / out_name).write_text(body, encoding="utf-8")
            created += 1

    print(f"Generados/actualizados: {created} archivos .descr en {out_dir}")
    print(f"Procedures únicos: {len(best)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
