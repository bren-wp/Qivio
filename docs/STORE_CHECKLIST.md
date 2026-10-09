# QREX — Google Play and Apple App Store Checklist

This is an engineering checklist, **not** a statement that either store has approved the app.

## Google Play / Android

- [x] Standalone Kotlin/Jetpack Compose Android project without login or ads.
- [x] Target and compile Android API 36.
- [x] Camera permission requested for scanning; system image picker instead of broad media permission.
- [x] Android backup and unencrypted cleartext traffic disabled in the manifest.
- [x] Privacy policy published in English, with an offline localized summary in app Settings.
- [x] GitHub Actions builds an Android debug APK and executes unit tests.
- [ ] Validate each locale's UI and screenshots on multiple display sizes and Android versions.
- [ ] Confirm all transitive library privacy and permission requirements.
- [ ] Protect manually saved credentials before production.
- [ ] Sign the release AAB with the project's production Play upload key.
- [ ] Fill in the Google Play Data safety, age rating and store listing forms with real screenshots.
- [ ] Complete internal/closed testing on physical devices.

## Apple App Store / iOS

- [x] Standalone SwiftUI application using AVFoundation, Vision, PhotosPicker and Core Image.
- [x] Privacy manifest supplied and bundled by XcodeGen.
- [x] Camera and photo picker purpose strings declared in English.
- [x] GitHub Actions builds an unsigned iOS simulator application.
- [ ] Verify packaged language resources and execute all XCTest tests on an available simulator.
- [ ] Confirm required-reason API declarations and privacy manifests for any SDK dependencies.
- [ ] Protect manually saved credentials before production.
- [ ] Complete App Store Connect metadata, privacy disclosure, ratings, contact and support information.
- [ ] Sign with valid Apple Developer certificates/provisioning profiles and test on real devices.
- [ ] Use authentic runtime screenshots for App Store Connect; mockups are not substitutes.

## Official sources

- Google: https://support.google.com/googleplay/android-developer/answer/11926878
- Google privacy: https://support.google.com/googleplay/android-developer/answer/10144311
- Apple review guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple requirements: https://developer.apple.com/news/upcoming-requirements/
- Apple privacy manifest: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files

Recheck all requirements immediately before submitting a new version.
