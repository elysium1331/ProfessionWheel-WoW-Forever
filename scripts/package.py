#!/usr/bin/env python3
"""Validate and build the installable ProfessionWheel release zip (stdlib only).

  python scripts/package.py                 # validate + build dist/Elysium_ProfessionWheel-<version>.zip
  python scripts/package.py --check         # validate only
  python scripts/package.py --install DIR   # build, then install into an AddOns folder
                                            # (an existing ProfessionWheel folder is backed up
                                            #  to ./backups/ first; nothing else is touched)

No credentials, network access or publication steps are involved.
"""
import argparse
import re
import shutil
import sys
import time
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import addon_files as af  # noqa: E402

ROOT = af.ROOT
ADDON = af.ADDON
LEGACY_FOLDERS = []  # no earlier folder names
FIXED_DATE = (2026, 1, 1, 0, 0, 0)  # deterministic zip timestamps

EXCLUDED_PATTERNS = [
    r"(^|/)\.git", r"(^|/)\.github/", r"(^|/)\.vscode/", r"(^|/)\.idea/", r"(^|/)tests?/",
    r"(^|/)scripts/", r"(^|/)docs/", r"(^|/)art/", r"(^|/)dist/", r"(^|/)backups/",
    r"__pycache__", r"\.py$", r"\.png$", r"\.psd$", r"\.kra$", r"\.xcf$", r"\.bak$", r"\.tmp$",
    r"~$", r"(^|/)WTF/", r"SavedVariables", r"\.env", r"(?i)secret|token\.txt|credential",
]
LOCAL_PATH_RE = re.compile(r"[A-Za-z]:\\\\?Users|/home/|/Users/")


def fail(errors, msg):
    errors.append(msg)


def validate_sources(errors):
    ver = af.version()
    if not re.fullmatch(r"\d+\.\d+\.\d+(-[0-9A-Za-z.]+)?", ver):
        fail(errors, f"TOC version '{ver}' is not semantic-version shaped")

    interface = af.toc_field("Interface")
    compat = (ROOT / "Compat.lua").read_text(encoding="utf-8")
    m = re.search(r"VERIFIED_INTERFACE = (\d+)", compat)
    if not m or m.group(1) not in [s.strip() for s in interface.split(",")]:
        fail(errors, f"TOC Interface ({interface}) does not include Compat.VERIFIED_INTERFACE")

    if af.toc_field("SavedVariablesPerCharacter") != "ProfessionWheelCharDB":
        fail(errors, "SavedVariablesPerCharacter must be ProfessionWheelCharDB")

    for rel in af.toc_files():
        if not (ROOT / rel).is_file():
            fail(errors, f"TOC lists a missing file: {rel}")
    if not (ROOT / "Bindings.xml").is_file():
        fail(errors, "Bindings.xml missing")

    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    if f"## [{ver}]" not in changelog:
        fail(errors, f"CHANGELOG.md has no '## [{ver}]' section")
    dist_doc = (ROOT / "docs" / "DISTRIBUTION.md").read_text(encoding="utf-8")
    if ver not in dist_doc:
        fail(errors, f"docs/DISTRIBUTION.md does not mention version {ver}")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    if ver not in readme:
        fail(errors, f"README.md does not mention version {ver}")


    for rel in af.toc_files():
        if rel.endswith(".lua"):
            text = (ROOT / rel).read_text(encoding="utf-8")
            if re.search(r'\.png["\']', text, re.I):
                fail(errors, f"{rel} references a PNG at runtime; convert to TGA/BLP")
            # In Lua source, a path separator inside "..." must be written as \\ .
            for m in re.finditer(r'"Interface(\\\\[^"\\]+)*\\[^\\"]', text):
                fail(errors, f"{rel}: single backslash in texture path near {m.group(0)!r}")


    for rel in af.LEGAL + af.DOCS:
        if not (ROOT / rel).is_file():
            fail(errors, f"missing release file: {rel}")


def build_zip(out: Path):
    out.parent.mkdir(parents=True, exist_ok=True)
    files = af.release_files()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for rel in files:
            data = (ROOT / rel).read_bytes()
            info = zipfile.ZipInfo(f"{ADDON}/{rel}", FIXED_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            z.writestr(info, data)
    return files


def validate_zip(path: Path, errors):
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        if f"{ADDON}/{ADDON}.toc" not in names:
            fail(errors, f"zip: TOC is not at {ADDON}/{ADDON}.toc")
        tocs = [n for n in names if n.lower().endswith(".toc")]
        for t in tocs:
            if t.count("/") != 1:
                fail(errors, f"zip: TOC not exactly one folder deep: {t}")
        for n in names:
            if not n.startswith(f"{ADDON}/"):
                fail(errors, f"zip: entry outside {ADDON}/: {n}")
            if n.startswith(f"{ADDON}/{ADDON}/"):
                fail(errors, f"zip: nested addon folder: {n}")
            inner = n[len(ADDON) + 1:]
            for pat in EXCLUDED_PATTERNS:
                if re.search(pat, inner):
                    fail(errors, f"zip: excluded content {n} (rule {pat})")
            body = z.read(n)
            try:
                text = body.decode("utf-8")
            except UnicodeDecodeError:
                continue
            if LOCAL_PATH_RE.search(text):
                fail(errors, f"zip: {n} contains a local filesystem path")
        for rel in af.toc_files() + ["Bindings.xml"]:
            if f"{ADDON}/{rel}" not in names:
                fail(errors, f"zip: missing runtime file {rel}")
        return names


def install(zip_path: Path, addons_dir: Path):
    if not addons_dir.is_dir() or addons_dir.name != "AddOns":
        raise SystemExit(f"not an AddOns folder: {addons_dir}")
    backup_root = ROOT / "backups"
    # The current folder, plus folder names used by earlier releases, so only one copy remains.
    for name in [ADDON] + LEGACY_FOLDERS:
        folder = addons_dir / name
        if folder.exists() and (name == ADDON or (folder / f"{name}.toc").is_file()):
            backup_root.mkdir(exist_ok=True)
            backup = backup_root / f"{name}-{time.strftime('%Y%m%d-%H%M%S')}"
            shutil.copytree(folder, backup)
            shutil.rmtree(folder)
            print(f"backed up and removed {folder} -> {backup}")
    target = addons_dir / ADDON
    with zipfile.ZipFile(zip_path) as z:
        for n in z.namelist():
            if not n.startswith(f"{ADDON}/") or ".." in n:
                raise SystemExit(f"refusing unsafe entry {n}")
        z.extractall(addons_dir)
    print(f"installed {zip_path.name} into {target}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="validate sources only")
    ap.add_argument("--install", metavar="ADDONS_DIR", help="install the built zip into this AddOns folder")
    args = ap.parse_args()

    errors = []
    validate_sources(errors)
    if errors or args.check:
        for e in errors:
            print("FAIL", e)
        print("source validation:", "failed" if errors else "ok")
        return 1 if errors else 0

    ver = af.version()
    out = ROOT / "dist" / f"{ADDON}-{ver}.zip"
    files = build_zip(out)
    names = validate_zip(out, errors)
    for e in errors:
        print("FAIL", e)
    if errors:
        return 1
    print(f"built {out.relative_to(ROOT)} ({len(names)} files, {out.stat().st_size} bytes)")
    for n in names:
        print("  ", n)
    if args.install:
        install(out, Path(args.install))
    return 0


if __name__ == "__main__":
    sys.exit(main())
