#!/usr/bin/env python3
"""Static checks and unit tests for ProfessionWheel, run on a real Lua 5.1 VM.

Requires the `lupa` package (bundles Lua 5.1):  python -m pip install lupa

Checks:
  1. Every Lua file listed in the TOC compiles as Lua 5.1 (WoW's dialect base:
     no goto, no //, no bitwise operators, no integer division).
  2. No global writes except an explicit allowlist.
  3. Pure-logic unit tests in tests/test_*.lua.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
from addon_files import toc_files  # noqa: E402

ALLOWED_GLOBALS = {
    "ProfessionWheel",                    # binding handler table (Bindings.xml)
    "ProfessionWheelCharDB",              # SavedVariablesPerCharacter
    "BINDING_NAME_PROFESSIONWHEEL_OPEN",  # Key Bindings label
    "ProfessionWheel_OnAddonCompartmentClick",  # TOC AddonCompartmentFunc
}


def main() -> int:
    try:
        from lupa import lua51
    except ImportError:
        print("lupa is required: python -m pip install lupa")
        return 2
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    if "5.1" not in lua.eval("_VERSION"):
        print("not a Lua 5.1 runtime")
        return 2

    errors = []
    scan = lua.execute((ROOT / "scripts" / "lua51_globals.lua").read_text(encoding="utf-8"))
    lua_files = [f for f in toc_files() if f.endswith(".lua")]
    for rel in lua_files:
        src = (ROOT / rel).read_text(encoding="utf-8")
        result = scan(src, "@" + rel)
        found, err = result if isinstance(result, tuple) else (result, None)
        if found is None:
            errors.append(f"syntax: {err}")
            continue
        for item in found.values():
            name = item["name"]
            if name not in ALLOWED_GLOBALS:
                errors.append(f"global write: {rel}:{int(item['line'])} '{name}'")
    print(f"syntax + globals: {len(lua_files)} files checked")

    lua.globals().ROOT = ROOT.as_posix()
    harness = lua.execute((ROOT / "tests" / "harness.lua").read_text(encoding="utf-8"))
    for test_file in sorted((ROOT / "tests").glob("test_*.lua")):
        chunk = lua.eval("loadfile")(test_file.as_posix())
        if chunk is None:
            errors.append(f"test file failed to load: {test_file.name}")
            continue
        chunk(harness)
    print(f"tests: {int(harness.passed)} passed, {int(harness.failed)} failed")
    for failure in harness.failures.values():
        errors.append("test: " + failure)

    for e in errors:
        print("  FAIL", e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
