#!/usr/bin/env python3
"""Create matching QREX launcher and splash icons; configure generated Flutter native hosts.

Run AFTER: flutter create --platforms=android,ios --org com.brendigo --project-name qrex .
Uses only the Python standard library.
"""
from __future__ import annotations

import json
import pathlib
import plistlib
import re
import uuid
import struct
import zlib
from xml.etree import ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
ANDROID_NS = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ANDROID_NS)


def png_chunk(kind: bytes, contents: bytes) -> bytes:
    return struct.pack(">I", len(contents)) + kind + contents + struct.pack(
        ">I", zlib.crc32(kind + contents) & 0xFFFFFFFF
    )


def rounded(x: float, y: float, x1: float, y1: float, x2: float, y2: float, r: float) -> bool:
    px = max(x1 + r, min(x, x2 - r))
    py = max(y1 + r, min(y, y2 - r))
    return (x - px) ** 2 + (y - py) ** 2 <= r ** 2


def stroke_segment(x: float, y: float, a: tuple[float, float], b: tuple[float, float], thick: float) -> bool:
    vx, vy = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((x - a[0]) * vx + (y - a[1]) * vy) / (vx * vx + vy * vy)))
    return (x - a[0] - vx * t) ** 2 + (y - a[1] - vy * t) ** 2 <= (thick / 2) ** 2


SEGMENTS = (
    ((.22, .39), (.22, .30)), ((.22, .30), (.30, .22)), ((.30, .22), (.39, .22)),
    ((.61, .22), (.70, .22)), ((.70, .22), (.78, .30)), ((.78, .30), (.78, .39)),
    ((.22, .61), (.22, .70)), ((.22, .70), (.30, .78)), ((.30, .78), (.39, .78)),
    ((.61, .78), (.70, .78)), ((.70, .78), (.78, .70)), ((.78, .70), (.78, .61)),
)


def pixel(x: float, y: float) -> tuple[int, int, int, int]:
    if not rounded(x, y, 0, 0, 1, 1, .228):
        return 3, 12, 27, 255
    f = min(1, (x + y) / 2)
    if f < .52:
        t = f / .52
        color = (int(1 + 21*t), int(190 - 80*t), int(252 + 3*t))
    else:
        t = (f - .52) / .48
        color = (int(22 + 87*t), int(110 - 80*t), int(255 - 4*t))
    if rounded(x, y, .375, .375, .625, .625, .045):
        color = (118, 162, 255)
    if .20 < x < .80 and abs(y - .5) < .012:
        color = (190, 219, 255)
    if any(stroke_segment(x, y, a, b, .081) for a, b in SEGMENTS):
        color = (250, 253, 255)
    return *color, 255


def render_png(destination: pathlib.Path, size: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    # 2x supersampling for small icons prevents jagged QR scanner corners.
    multiplier = 2 if size <= 192 else 1
    rows = []
    for py in range(size):
        row = bytearray()
        for px in range(size):
            values = [0, 0, 0, 0]
            for sy in range(multiplier):
                for sx in range(multiplier):
                    sample = pixel((px + (sx + .5)/multiplier)/size, (py + (sy + .5)/multiplier)/size)
                    for i in range(4):
                        values[i] += sample[i]
            count = multiplier * multiplier
            row.extend(v // count for v in values)
        rows.append(b"\x00" + row)
    data = b"".join([
        b"\x89PNG\r\n\x1a\n",
        png_chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)),
        png_chunk(b"IDAT", zlib.compress(b"".join(rows), level=6)),
        png_chunk(b"IEND", b""),
    ])
    destination.write_bytes(data)


def android() -> None:
    app = ROOT / "android/app/src/main"
    manifest = app / "AndroidManifest.xml"
    if not manifest.is_file():
        raise SystemExit("Missing Android project. Run flutter create first.")
    tree = ET.parse(manifest)
    root = tree.getroot()
    if not any(item.get(f"{{{ANDROID_NS}}}name") == "android.permission.CAMERA"
               for item in root.findall("uses-permission")):
        permission = ET.Element("uses-permission", {f"{{{ANDROID_NS}}}name": "android.permission.CAMERA"})
        root.insert(0, permission)
    application = root.find("application")
    if application is None:
        raise SystemExit("Missing Android application manifest node")
    application.set(f"{{{ANDROID_NS}}}label", "QREX")
    # Keep user QR history outside automatic Android cloud backups.
    application.set(f"{{{ANDROID_NS}}}allowBackup", "false")
    application.set(f"{{{ANDROID_NS}}}usesCleartextTraffic", "false")
    tree.write(manifest, encoding="utf-8", xml_declaration=True)
    enforce_android_sdk()
    res = app / "res"
    for directory, size in (
        ("mipmap-mdpi", 48), ("mipmap-hdpi", 72), ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144), ("mipmap-xxxhdpi", 192),
    ):
        render_png(res / directory / "ic_launcher.png", size)
    # Android launch window before Flutter paints its first frame.
    background = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/black"/>
    <item><bitmap android:gravity="center" android:src="@mipmap/ic_launcher"/></item>
</layer-list>
"""
    for path in [res / "drawable/launch_background.xml", res / "drawable-v21/launch_background.xml"]:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(background, encoding="utf-8")


def enforce_android_sdk() -> None:
    """Google Play requires API 36 for phone updates from August 2026."""
    kotlin = ROOT / "android/app/build.gradle.kts"
    groovy = ROOT / "android/app/build.gradle"
    path = kotlin if kotlin.is_file() else groovy
    if not path.is_file():
        raise SystemExit("No generated Android Gradle file.")
    content = path.read_text(encoding="utf-8")
    if path.suffix == ".kts":
        patterns = (
            (r"(?m)^([ \t]*)compileSdk = (?:flutter\.compileSdkVersion|[0-9]+)\s*$",
             r"\g<1>compileSdk = 36"),
            (r"(?m)^([ \t]*)targetSdk = (?:flutter\.targetSdkVersion|[0-9]+)\s*$",
             r"\g<1>targetSdk = 36"),
        )
    else:
        patterns = (
            (r"(?m)^([ \t]*)compileSdkVersion (?:flutter\.compileSdkVersion|[0-9]+)\s*$",
             r"\g<1>compileSdkVersion 36"),
            (r"(?m)^([ \t]*)targetSdkVersion (?:flutter\.targetSdkVersion|[0-9]+)\s*$",
             r"\g<1>targetSdkVersion 36"),
        )
    for pattern, replacement in patterns:
        content, count = re.subn(pattern, replacement, content)
        if count != 1:
            raise SystemExit(f"Could not safely enforce API 36 in {path}: {pattern}")
    path.write_text(content, encoding="utf-8")


def add_ios_privacy_manifest() -> None:
    """Add a valid app-owned privacy manifest to the generated Runner target.

    Third-party plugin manifests remain the responsibility of their SDKs.
    """
    runner = ROOT / "ios/Runner"
    manifest = runner / "PrivacyInfo.xcprivacy"
    manifest.write_bytes(plistlib.dumps({
        "NSPrivacyTracking": False,
        "NSPrivacyTrackingDomains": [],
        "NSPrivacyCollectedDataTypes": [],
        "NSPrivacyAccessedAPITypes": [],
    }, fmt=plistlib.FMT_XML))

    project = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    content = project.read_text(encoding="utf-8")
    if "PrivacyInfo.xcprivacy in Resources" in content:
        return
    reference_id = uuid.uuid5(uuid.NAMESPACE_URL, "qrex:privacy:file").hex[:24].upper()
    build_id = uuid.uuid5(uuid.NAMESPACE_URL, "qrex:privacy:build").hex[:24].upper()
    reference = (
        f"\t\t{reference_id} /* PrivacyInfo.xcprivacy */ = "
        '{isa = PBXFileReference; lastKnownFileType = text.xml; '
        'path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; };\n'
    )
    build = (
        f"\t\t{build_id} /* PrivacyInfo.xcprivacy in Resources */ = "
        f"{{isa = PBXBuildFile; fileRef = {reference_id} /* PrivacyInfo.xcprivacy */; }};\n"
    )

    def add_to_section(name: str, item: str) -> None:
        nonlocal content
        marker = f"/* Begin {name} section */\n"
        if marker not in content:
            raise SystemExit(f"iOS project missing section: {name}")
        content = content.replace(marker, marker + item, 1)

    add_to_section("PBXFileReference", reference)
    add_to_section("PBXBuildFile", build)

    # Only touch the Runner group and Runner resources phase; avoid Pods targets.
    group = re.compile(
        r"(?P<head>[0-9A-F]{24} /\* Runner \*/ = \{\s*"
        r"isa = PBXGroup;\s*children = \(\s*\n)"
    )
    content, group_count = group.subn(
        lambda m: m.group("head") +
        f"\t\t\t\t{reference_id} /* PrivacyInfo.xcprivacy */,\n",
        content,
        count=1,
    )
    if group_count != 1:
        raise SystemExit("Cannot find Runner group to add PrivacyInfo.xcprivacy")
    begin = "/* Begin PBXResourcesBuildPhase section */"
    end = "/* End PBXResourcesBuildPhase section */"
    if begin not in content or end not in content:
        raise SystemExit("Cannot find iOS Runner resources build phase.")
    prefix, tail = content.split(begin, 1)
    resources, suffix = tail.split(end, 1)
    # Flutter creates RunnerTests resources first, then Runner resources.
    # Attach the manifest specifically to the Runner application target.
    resources, resources_count = re.subn(
        r"(97C146EC1CF9000F007C117D /\* Resources \*/ = \{\s*"
        r"isa = PBXResourcesBuildPhase;\s*"
        r"buildActionMask = 2147483647;\s*files = \(\s*\n)",
        lambda m: m.group(1) +
        f"\t\t\t\t{build_id} /* PrivacyInfo.xcprivacy in Resources */,\n",
        resources,
        count=1,
    )
    if resources_count != 1:
        raise SystemExit("Unable to add privacy manifest to Runner resources.")
    project.write_text(prefix + begin + resources + end + suffix, encoding="utf-8")


def ios() -> None:
    runner = ROOT / "ios/Runner"
    plist = runner / "Info.plist"
    if not plist.is_file():
        raise SystemExit("Missing iOS project. Run flutter create first.")
    with plist.open("rb") as handle:
        data = plistlib.load(handle)
    data["CFBundleDisplayName"] = "QREX"
    data["NSCameraUsageDescription"] = "QREX treba kameru za skeniranje QR kodova."
    data["NSPhotoLibraryUsageDescription"] = "Odaberi fotografiju za čitanje QR koda."
    with plist.open("wb") as handle:
        plistlib.dump(data, handle)
    add_ios_privacy_manifest()
    icon_dir = runner / "Assets.xcassets/AppIcon.appiconset"
    icons = [
        ("iphone", "20x20", 2), ("iphone", "20x20", 3),
        ("iphone", "29x29", 2), ("iphone", "29x29", 3),
        ("iphone", "40x40", 2), ("iphone", "40x40", 3),
        ("iphone", "60x60", 2), ("iphone", "60x60", 3),
        ("ipad", "20x20", 1), ("ipad", "20x20", 2),
        ("ipad", "29x29", 1), ("ipad", "29x29", 2),
        ("ipad", "40x40", 1), ("ipad", "40x40", 2),
        ("ipad", "76x76", 1), ("ipad", "76x76", 2),
        ("ipad", "83.5x83.5", 2),
        ("ios-marketing", "1024x1024", 1),
    ]
    entries = []
    for idiom, dimensions, scale in icons:
        side = round(float(dimensions.split("x")[0]) * scale)
        name = f"QREX-{idiom}-{dimensions.replace('.', '_')}-{scale}x.png"
        render_png(icon_dir / name, side)
        entries.append({"idiom": idiom, "size": dimensions, "scale": f"{scale}x", "filename": name})
    (icon_dir / "Contents.json").write_text(
        json.dumps({"images": entries, "info": {"version": 1, "author": "xcode"}}, indent=2),
        encoding="utf-8",
    )
    splash = runner / "Assets.xcassets/LaunchImage.imageset"
    splash.mkdir(parents=True, exist_ok=True)
    images = []
    for scale in [1, 2, 3]:
        name = f"LaunchImage@{scale}x.png" if scale > 1 else "LaunchImage.png"
        render_png(splash / name, 120 * scale)
        images.append({"idiom": "universal", "filename": name, "scale": f"{scale}x"})
    (splash / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"version": 1, "author": "xcode"}}, indent=2),
        encoding="utf-8",
    )


if __name__ == "__main__":
    android()
    ios()
    print("QREX native privacy/SDK policies, app names, icons and splash generated.")
