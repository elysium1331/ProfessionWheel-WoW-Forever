"""Single source of truth for the addon's version and release contents."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON = "Elysium_ProfessionWheel"
TOC = ROOT / f"{ADDON}.toc"

# Explicit inclusion rules for the installable zip (in addition to TOC-listed files).
EXTRA_RUNTIME = ["Bindings.xml", f"{ADDON}.toc"]
LEGAL = ["LICENSE", "THIRD_PARTY_NOTICES.md"]
DOCS = ["README.md", "CHANGELOG.md"]


def toc_text() -> str:
    return TOC.read_text(encoding="utf-8")


def toc_field(name: str) -> str:
    m = re.search(rf"^## {re.escape(name)}:\s*(.+?)\s*$", toc_text(), re.M)
    if not m:
        raise SystemExit(f"TOC is missing ## {name}")
    return m.group(1)


def version() -> str:
    return toc_field("Version")


def toc_files() -> list:
    files = []
    for line in toc_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        files.append(line.replace("\\", "/"))
    return files


def media_refs() -> list:
    """Runtime textures referenced from Art.lua (relative paths inside the addon)."""
    text = (ROOT / "Art.lua").read_text(encoding="utf-8")
    # In Lua source each path separator is written as two backslashes.
    refs = re.findall(r'"Interface\\\\AddOns\\\\' + re.escape(ADDON) + r'\\\\([^"]+)"', text)
    return sorted({r.replace("\\\\", "/") for r in refs})


def release_files() -> list:
    return list(dict.fromkeys(EXTRA_RUNTIME + toc_files() + media_refs() + LEGAL + DOCS))
