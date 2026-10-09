# QREX Privacy Policy

**Last updated:** October 9, 2026  
**Developer:** Brendigo · https://brendigo.com

QREX is an Android and iOS application for scanning and generating QR codes locally. No account, registration or sign-in is required.

## Information processed on your device

- **Camera:** used to detect QR codes. The camera stream is processed locally; it is not uploaded to a QREX server. You may revoke camera permission in system settings.
- **Images:** you select an image through the operating system's photo picker. QR detection runs locally on the selected image and QREX does not upload it.
- **QR contents:** text, URLs, Wi-Fi credentials, contact details, locations and other input are processed locally when scanning or creating a code.
- **Optional history:** if enabled, QR contents and scan time can be stored in the application's local data, capped at 250 items. Wi-Fi QR codes are **not automatically recorded**. Manually saving a Wi-Fi code may also save its password.
- **Preferences:** your selected display theme, language and history preference are saved locally.

**Important:** The current local storage is not a dedicated encrypted secrets vault. Avoid manually saving sensitive passwords. More protection is planned before the platform-focused apps replace the existing public release.

## Data collection and sharing

QREX does not provide accounts, advertising, an analytics service or its own backend to collect QR content. The developer does not receive QR scan contents or device-local history through the app.

If you choose to open a URL, start a call, send an email, open a map or share information, another application or website may receive the content and apply its own privacy policy. QR URLs are not opened automatically.

## Retention and deletion

Local data persists until you delete it, uninstall QREX or the operating system removes application data. In **More → Settings** you may disable scan history and select **Delete all data** to remove local history, saved codes and preferences. Device or operating-system backups may contain copies depending on platform settings; the Android application backup is disabled in its manifest.

## Permissions

QREX requests camera permission for live scanning. Image access uses the platform-provided picker where available; scanning does not require the contacts, location or account permissions.

## Contact

For privacy-related requests, use the contact information at https://brendigo.com.

## Policy changes

Changes to this policy appear in the public repository and future app versions. An offline summary is available in the app. Store privacy declarations must be reevaluated for the exact binary and SDK versions submitted for review.
