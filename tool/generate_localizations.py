#!/usr/bin/env python3
"""Regenerate identical localization resources for Android and iOS.

Run: python3 tool/generate_localizations.py
Check: python3 tool/generate_localizations.py --check
"""
from __future__ import annotations

import json
import pathlib
import sys
import xml.sax.saxutils as xml

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "l10n/catalog.json"
ANDROID = ROOT / "platforms/android/app/src/main/res"
IOS = ROOT / "platforms/ios/QREX"


def swift_escaped(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def android_escaped(value: str) -> str:
    return xml.escape(value).replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"').replace("\n", "\\n")


def make_files() -> dict[pathlib.Path, str]:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    languages = catalog["languages"]
    keys = tuple(languages["en"]["strings"])
    assert len(languages) >= 22 and len(keys) >= 60
    assert catalog["default"] == "en"
    outputs = {}
    for code, entry in languages.items():
        translations = entry["strings"]
        if tuple(translations) != keys:
            raise ValueError(f"{code}: translation keys or key order differ from English")
        if any(not isinstance(v, str) or not v.strip() for v in translations.values()):
            raise ValueError(f"{code}: empty translation")
        values = ANDROID / ("values" if code == "en" else f"values-{code}") / "strings.xml"
        lines = ['<?xml version="1.0" encoding="utf-8"?>', "<resources>"]
        for key, val in translations.items():
            lines.append(f'    <string name="{key}">{android_escaped(val)}</string>')
        lines.append("</resources>")
        outputs[values] = "\n".join(lines) + "\n"
        ios_file = IOS / f"{code}.lproj" / "Localizable.strings"
        outputs[ios_file] = "".join(
            f'"{key}" = "{swift_escaped(val)}";\n' for key, val in translations.items()
        )

    language_cases = "\n".join(f'        "{key}" -> R.string.{key}' for key in keys)
    language_codes = ", ".join(f'"{code}"' for code in languages)
    outputs[ROOT / "platforms/android/app/src/main/java/com/brendigo/qrex/QREXStrings.kt"] = """package com.brendigo.qrex

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

/** User-selected language shared with the iOS catalog; never uses network translation. */
object QREXStrings {
    val languages: List<String> = listOf(%s)
    fun get(context: Context, code: String, key: String): String {
        val id = when (key) {
%s
            else -> R.string.scan
        }
        val locale = if (code == "system") context.resources.configuration.locales[0]
            else Locale.forLanguageTag(code)
        val config = Configuration(context.resources.configuration)
        config.setLocale(locale)
        return context.createConfigurationContext(config).resources.getString(id)
    }
}
""" % (language_codes, language_cases)
    outputs[IOS / "QREXStrings.swift"] = """import Foundation

enum QREXStrings {
    static let supported: [String] = [%s]
    static func text(_ key: String, language: String) -> String {
        let code = language == "system" ? (Locale.preferredLanguages.first ?? "en")
            .components(separatedBy: "-").first ?? "en" : language
        let selected = Bundle.main.path(forResource: code, ofType: "lproj")
            .flatMap(Bundle.init(path:))
        let english = Bundle.main.path(forResource: "en", ofType: "lproj")
            .flatMap(Bundle.init(path:))
        return selected?.localizedString(forKey: key, value: nil, table: nil)
            ?? english?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
}

func tr(_ key: String) -> String {
    QREXStrings.text(key, language: UserDefaults.standard.string(forKey: "qrex.language") ?? "en")
}
""" % (", ".join(f'"{code}"' for code in languages))
    return outputs


def main() -> None:
    check = "--check" in sys.argv
    files = make_files()
    stale = [str(path.relative_to(ROOT)) for path, body in files.items()
             if not path.exists() or path.read_text(encoding="utf-8") != body]
    if check and stale:
        raise SystemExit("Localization out of date:\n" + "\n".join(stale))
    if not check:
        for path, content in files.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
    print(f"{len(files)} localization files checked; {len(stale)} generated.")


if __name__ == "__main__":
    main()
