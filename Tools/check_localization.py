#!/usr/bin/env python3
"""Check the six iOS resource tables and literal UI localization references."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "GdeiAssistant-iOS/Resources"
LOCALES = ("zh-Hans", "zh-HK", "zh-TW", "en", "ja", "ko")
ENTRY = re.compile(r'^\s*("(?:[^"\\]|\\.)*")\s*=\s*("(?:[^"\\]|\\.)*")\s*;\s*$')
FORMAT = re.compile(r'%(?:\d+\$)?[-+ #0]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|ll|[hlLzjtq])?[@diuoxXfFeEgGaAcCsSp%]')
REFERENCE = re.compile(r'(?:localizedString|NSLocalizedString|LocalizedStringKey)\(\s*"([^"\\]+)"')
UI_LITERAL = re.compile(r'(?:Text|Button|Label|Toggle|TextField|SecureField|Section|navigationTitle|accessibilityLabel)\(\s*"([^"\\]+)"')
errors = []


def table(path):
    result = {}
    in_comment = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        if in_comment:
            if "*/" in stripped:
                in_comment = False
            continue
        if not stripped or stripped.startswith("//"):
            continue
        if stripped.startswith("/*"):
            in_comment = "*/" not in stripped
            continue
        match = ENTRY.fullmatch(line)
        if not match:
            errors.append(f"{path.relative_to(ROOT)}:{number}: invalid resource entry")
            continue
        key, value = (json.loads(part) for part in match.groups())
        if key in result:
            errors.append(f"{path.relative_to(ROOT)}:{number}: duplicate key {key}")
        result[key] = value
    return result


def arguments(value):
    return sorted(argument for argument in FORMAT.findall(value) if argument != "%%")


tables = {locale: table(RESOURCES / f"{locale}.lproj/Localizable.strings") for locale in LOCALES}
baseline = tables["zh-Hans"]
refs = set()
hardcoded = []
for path in (ROOT / "GdeiAssistant-iOS").rglob("*.swift"):
    if "/Mock/" in str(path) or path.name.startswith("Mock"):
        continue
    source = "\n".join(line for line in path.read_text(encoding="utf-8").splitlines() if not line.lstrip().startswith("//"))
    refs.update(REFERENCE.findall(source))
    for value in UI_LITERAL.findall(source):
        if value in baseline or not re.search(r'[A-Za-z\u3400-\u9fff\u3040-\u30ff\uac00-\ud7af]', value):
            continue
        hardcoded.append(f"{path.relative_to(ROOT)}: {value}")
missing_refs = sorted(refs - baseline.keys())
errors.extend(f"missing literal localization key: {key}" for key in missing_refs)
errors.extend(f"hardcoded UI literal: {value}" for value in hardcoded)
report = {}
for locale, values in tables.items():
    missing = baseline.keys() - values.keys()
    extra = values.keys() - baseline.keys()
    empty = [key for key, value in values.items() if not value.strip()]
    formats = [key for key in baseline.keys() & values.keys() if arguments(values[key]) != arguments(baseline[key])]
    permissions = table(RESOURCES / f"{locale}.lproj/InfoPlist.strings")
    if set(permissions) != {"NSMicrophoneUsageDescription"} or not permissions.get("NSMicrophoneUsageDescription", "").strip():
        errors.append(f"{locale}: missing microphone permission localization")
    for label, keys in (("missing", missing), ("extra", extra), ("empty", empty), ("format", formats)):
        errors.extend(f"{locale}: {label} key {key}" for key in sorted(keys))
    report[locale] = {"keys": len(values), "missing": len(missing), "extra": len(extra), "empty": len(empty), "format_mismatch": len(formats), "permission_keys": len(permissions)}
print(json.dumps({"locales": report, "literal_references": len(refs), "missing_references": len(missing_refs), "hardcoded_ui_literals": len(hardcoded), "errors": errors}, ensure_ascii=False, indent=2))
sys.exit(bool(errors))
