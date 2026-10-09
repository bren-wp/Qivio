# QREX — Android i iOS

Dva zasebna projekta implementirana platformskim alatima, bez Flutter enginea i bez WebViewa.

| | Android | iOS |
| --- | --- | --- |
| Jezik | Kotlin | Swift |
| Sučelje | Jetpack Compose | SwiftUI |
| Kamera | CameraX + ML Kit (lokalni QR model) | AVFoundation |
| Fotografije | Sustavni odabir + ML Kit | PhotosPicker + Vision |
| QR generiranje | ZXing | Core Image |
| Pohrana | Privatni SharedPreferences | UserDefaults |
| Pristup | Bez računa | Bez računa |

**Status: razvojna grana, ne zamjena za izdanje v0.1.3.** Trenutna javna verzija aplikacije koristi Flutter; ne smije se označiti kao puna platformska zamjena dok svi zasloni i interakcije ne dosegnu funkcionalnu i vizualnu podudarnost i dok Android/iOS CI ne prođu. Potpisivanje, fotografije stvarnih uređaja i testovi kamere na fizičkim uređajima ostaju zasebni koraci.

U aplikacijama nema razvojnih poruka, testnih gumba, demonstracijskih računa, oglasa, analitike ni teksta o korištenoj tehnologiji. Opisi tehnologija ograničeni su na razvojnu dokumentaciju.

## Android

Otvoriti `platforms/android` u Android Studiju s JDK 17 i Android SDK 36 ili pokrenuti `gradle :app:assembleDebug :app:testDebugUnitTest` iz direktorija. APK je **razvojna datoteka** i nije za objavu na Google Playu bez potpisivanja i potpunih provjera.

## iOS

Instalirati XcodeGen, pokrenuti `xcodegen generate --spec project.yml` u `platforms/ios` i otvoriti `QREX.xcodeproj` u Xcodeu. iOS aplikacija zahtijeva valjano Apple potpisivanje za stvarne uređaje.

## Usklađivanje prije zamjene

- [ ] Android Kotlin projekt prolazi vlastitu kompilaciju i testove.
- [ ] iOS Swift projekt prolazi vlastitu kompilaciju i testove.
- [ ] Uskladiti kreator za sve QR kategorije, PNG dijeljenje, pristup galeriji, zumiranje i bljeskalicu na oba sustava.
- [ ] Napraviti stvarne snimke svih ekrana i usporediti s postojećim QREX prikazima.
- [ ] Testirati dozvole, povratak iz pozadine i prekinuto skeniranje na fizičkim uređajima.
- [ ] Validirati i dokumentirati privatnost i potpisivanje u Google Play Consoleu i App Store Connectu.

**Razvio Brendigo** · https://brendigo.com
