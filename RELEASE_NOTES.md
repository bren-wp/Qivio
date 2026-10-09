# QREX v0.1.3 — Safer QR handling and more reliable local storage

This is the latest verified **public release**, built with the previous Flutter implementation.

- Improved Wi-Fi QR parsing for escaped separators and special characters.
- Stricter validation of URLs and email actions.
- Serialized writes to prevent old local history from reappearing after deletion.
- Better error feedback for clipboard and save failures.
- Regression tests covering suspicious links, Wi-Fi values and concurrent saves.
- Settings include **Developed by Brendigo** and an offline privacy explanation.

The public Android APK and its checksum are available through [Releases](https://github.com/bren-wp/Qivio/releases/tag/v0.1.3). An Android App Bundle is also built by CI. A signed iOS IPA needs Apple Developer credentials.

### Next-generation Android and iOS projects

Kotlin/Compose and Swift/SwiftUI projects now exist in the repository. Their **English-first, 23-language** localization is under development in the current feature branch; these changes are **not part of v0.1.3** until the next release is built and verified.

Automatic CI success is not a substitute for screenshot-to-reference visual QA, physical device testing or approval by Google Play and Apple.
