# Sync the scripts in DGUS.rbxlx with src/<Explorer path>.luau (graphify indexes src/).
#   python tools/export_scripts.py           place -> src (overwrites src/)
#   python tools/export_scripts.py --import  src -> place (close the place in Studio first, reopen after)
#     A new .luau ModuleScript in a folder that already holds scripts is added to the place too,
#     and a ModuleScript whose .luau was deleted is taken out of it.
# Import refuses if the place changed since the last export, so Studio edits are never overwritten.
import hashlib, re, shutil, sys, uuid, xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}
SUFFIX = {"Script": ".server", "LocalScript": ".client", "ModuleScript": ""}
SOURCE_RE = re.compile(r'(<ProtectedString name="Source">)(.*?)(</ProtectedString>)', re.S)
root = Path(__file__).resolve().parent.parent
place = root / "DGUS.rbxlx"
out = root / "src"
stamp = out / ".place_sha256"

def prop(item, tag, name):
    props = item.find("Properties")
    el = props.find(f"{tag}[@name='{name}']") if props is not None else None
    return el.text or "" if el is not None else None

def scripts(xml=None):
    """(file path, source) for every script, in document order (of the place file, or of xml text)."""
    found = []
    def walk(item, parts):
        name = prop(item, "string", "Name") or item.get("class")
        parts = parts + [name.replace("/", "_").replace("\\", "_")]
        cls = item.get("class")
        if cls in SCRIPT_CLASSES:
            # a script with child scripts is a folder; its own source goes in init
            has_kids = any(c.get("class") in SCRIPT_CLASSES for c in item.iter("Item") if c is not item)
            sfx = SUFFIX[cls]
            path = out.joinpath(*parts, f"init{sfx}.luau") if has_kids else out.joinpath(*parts[:-1], f"{parts[-1]}{sfx}.luau")
            found.append((path, prop(item, "ProtectedString", "Source") or ""))
        for child in item.findall("Item"):
            walk(child, parts)
    doc = ET.fromstring(xml) if xml is not None else ET.parse(place).getroot()
    for top in doc.findall("Item"):
        walk(top, [])
    assert found, "no scripts found"
    assert len({p for p, _ in found}) == len(found), "two scripts map to the same file path"
    return found

def remove_deleted_modules(text, found):
    """Take ModuleScripts whose .luau file was deleted from src/ out of the place too.
    Only childless ModuleScripts: anything else must be removed in Studio."""
    matches = list(SOURCE_RE.finditer(text))
    cuts = []
    for m, (path, _) in zip(matches, found):
        if path.exists():
            continue
        start = text.rindex("<Item ", 0, m.start())
        if not text.startswith('<Item class="ModuleScript"', start):
            sys.exit(f"{path} was deleted but isn't a ModuleScript: remove it in Studio")
        end = text.index("</Item>", m.end()) + len("</Item>")
        if text[start:end].count("<Item") != 1:
            sys.exit(f"{path} was deleted but has child scripts: remove it in Studio")
        line = text.rindex("\n", 0, start)  # take its indentation and line break with it
        cuts.append((line, end))
        print(f"Removing deleted ModuleScript {path.relative_to(out)}")
    for a, b in sorted(cuts, reverse=True):
        text = text[:a] + text[b:]
    return text, len(cuts)

def add_new_modules(text, found):
    """Add src/ files the place doesn't have yet as ModuleScripts, each copied from a script
    beside it in the same folder (same properties; new referent, id, name and source)."""
    known = {p for p, _ in found}
    matches = list(SOURCE_RE.finditer(text))
    inserts = []
    for path in sorted(out.rglob("*.luau")):
        if path in known:
            continue
        if path.name.endswith((".server.luau", ".client.luau")) or path.stem == "init":
            sys.exit(f"{path}: only new ModuleScripts can be added (create Scripts/LocalScripts in Studio)")
        sib = next((i for i, (p, _) in enumerate(found) if p.parent == path.parent and not p.name.endswith((".server.luau", ".client.luau")) and p.stem != "init"), None)
        if sib is None:
            sys.exit(f"{path}: no ModuleScript in that folder to copy, so the place has nowhere to put it")
        m = matches[sib]
        start = text.rindex('<Item class="ModuleScript"', 0, m.start())
        end = text.index("</Item>", m.end()) + len("</Item>")
        item = text[start:end]
        assert item.count("<Item") == 1, "template script has children"
        src = path.read_text(encoding="utf-8")
        item = re.sub(r'referent="[^"]*"', 'referent="RBX' + uuid.uuid4().hex.upper() + '"', item, count=1)
        item = SOURCE_RE.sub(lambda mm: mm.group(1) + "<![CDATA[" + src.replace("]]>", "]]]]><![CDATA[>") + "]]>" + mm.group(3), item, count=1)
        item = re.sub(r'(<string name="Name">)[^<]*(</string>)', lambda mm: mm.group(1) + path.stem + mm.group(2), item, count=1)
        item = re.sub(r'(<UniqueId name="UniqueId">)[0-9a-f]*(</UniqueId>)', lambda mm: mm.group(1) + uuid.uuid4().hex + mm.group(2), item, count=1)
        indent = text[text.rindex("\n", 0, start) + 1:start]
        inserts.append((end, "\n" + indent + item))
        print(f"Adding new ModuleScript {path.relative_to(out)}")
    for at, block in sorted(inserts, reverse=True):
        text = text[:at] + block + text[at:]
    return text, len(inserts)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def export():
    found = scripts()
    for stale in out.rglob("*.luau"):  # files only: Windows locks folders open in an editor or shell
        stale.unlink()
    for path, src in found:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(src, encoding="utf-8", newline="")
    stamp.write_text(sha(place.read_bytes()))
    print(f"Exported {len(found)} scripts to {out}")

def import_():
    raw = place.read_bytes()
    if not stamp.exists() or stamp.read_text().strip() != sha(raw):
        sys.exit("DGUS.rbxlx changed since the last export (saved from Studio?). Export first, then redo the edits in src/.")
    text = raw.decode("utf-8")
    text, removed = remove_deleted_modules(text, scripts())
    text, added = add_new_modules(text, scripts(text))
    added += removed
    found = scripts(text)
    matches = list(SOURCE_RE.finditer(text))
    assert len(matches) == len(found), f"{len(matches)} Source blocks but {len(found)} scripts"
    pieces, last, changed = [], 0, added
    for m, (path, old) in zip(matches, found):
        new = path.read_text(encoding="utf-8")
        body = m.group(2)
        if new != old:
            body = "<![CDATA[" + new.replace("]]>", "]]]]><![CDATA[>") + "]]>"
            changed += 1
        pieces += [text[last:m.start(2)], body]
        last = m.end(2)
    pieces.append(text[last:])
    if not changed:
        print("No script changes to import")
        return
    shutil.copy2(place, place.with_suffix(".rbxlx.bak"))
    result = "".join(pieces).encode("utf-8")
    place.write_bytes(result)
    stamp.write_text(sha(result))
    # self-check: the written place parses and reads back exactly what src/ holds
    assert all(src == path.read_text(encoding="utf-8") for path, src in scripts()), "round-trip mismatch"
    print(f"Imported {changed} changed script(s) into {place.name} (backup: {place.name}.bak)")

import_() if "--import" in sys.argv else export()
