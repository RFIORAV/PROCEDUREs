import re
from pathlib import Path
from collections import defaultdict

ROOT = Path(r"d:\Reinaldo\_FRA\db\PROCEDUREs")
PROC_RE = re.compile(r"CREATE\s+(?:DEFINER[^P]+)?PROCEDURE\s+[`'\"]?(\w+)[`'\"]?", re.I)
d = defaultdict(list)
for p in sorted(ROOT.glob("PROCEDURE_*.sql")):
    t = p.read_text(encoding="utf-8", errors="replace")
    m = PROC_RE.search(t)
    if m:
        d[m.group(1)].append(p.name)
    else:
        d["__NONE__"].append(p.name)
dup = {k: v for k, v in d.items() if k != "__NONE__" and len(v) > 1}
print("Procedures:", len(d) - (1 if "__NONE__" in d else 0))
print("Duplicates:", len(dup))
for k, v in sorted(dup.items()):
    print(k, "->", v)
print("No proc:", d.get("__NONE__", []))
