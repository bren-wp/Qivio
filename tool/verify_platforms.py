#!/usr/bin/env python3
"""Fail CI when generated iOS/Android configuration loses QREX privacy rules."""
from __future__ import annotations

import pathlib
import plistlib
import sys
from xml.etree import ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
ANDROID_NS = "http://schemas.android.com/apk/res/android"


def check_android() -> None:
    manifest = ET.parse(ROOT / "android/app/src/main/AndroidManifest.xml").getroot()
    app = manifest.find("application")
    assert app is not None
    assert app.attrib.get(f"{{{ANDROID_NS}}}allowBackup") == "false", "Android backup must be off"
    assert app.attrib.get(f"{{{ANDROID_NS}}}usesCleartextTraffic") == "false", "No cleartext traffic"
    assert any(
        p.get(f"{{{ANDROID_NS}}}name") == "android.permission.CAMERA"
        for p in manifest.findall("uses-permission")
    ), "QR scanner needs a camera permission"

    gradle = ROOT / "android/app/build.gradle.kts"
    if not gradle.is_file():
        gradle = ROOT / "android/app/build.gradle"
    content = gradle.read_text(encoding="utf-8")
    assert ("targetSdk = 36" in content or "targetSdkVersion 36" in content), "Target API 36 missing"
    assert ("compileSdk = 36" in content or "compileSdkVersion 36" in content), "Compile API 36 missing"
    print("Android: API 36, permissions and backup/network rules confirmed.")


def check_ios() -> None:
    runner = ROOT / "ios/Runner"
    info = plistlib.loads((runner / "Info.plist").read_bytes())
    assert info.get("NSCameraUsageDescription"), "Camera usage description required"
    assert info.get("NSPhotoLibraryUsageDescription"), "Photo picker usage description required"

    privacy = runner / "PrivacyInfo.xcprivacy"
    data = plistlib.loads(privacy.read_bytes())
    assert data.get("NSPrivacyTracking") is False, "App does not track"
    for key in ("NSPrivacyCollectedDataTypes", "NSPrivacyAccessedAPITypes"):
        assert isinstance(data.get(key), list), f"Missing {key}"
    project = (ROOT / "ios/Runner.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
    assert "PrivacyInfo.xcprivacy in Resources" in project, "Privacy manifest not added to app bundle"
    print("iOS: permission reasons and app privacy manifest included in Xcode project.")


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in ("android", "ios"):
        raise SystemExit("Usage: python3 tool/verify_platforms.py android|ios")
    if sys.argv[1] == "android":
        check_android()
    else:
        check_ios()
