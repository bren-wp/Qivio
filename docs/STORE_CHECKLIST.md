# QREX — Google Play i Apple App Store provjera

Ovaj popis je **tehnička priprema**, a nije tvrdnja da je aplikacija već prošla službeni pregled u trgovinama.

## Google Play (Android)

- [x] Odvojena mobilna aplikacija bez registracije, oglasa i vlastitog backenda.
- [x] Ciljati Android API 36 (Android 16) ili viši za nove prijave/ažuriranja od 31. 8. 2026. — konfiguraciju nameće `tool/prepare_platforms.py`; CI je provjerava.
- [x] Tražiti samo relevantno dopuštenje kamere; `android:allowBackup=false` i zabrana cleartext HTTP prometa unutar aplikacije.
- [x] Javna pravila privatnosti: [docs/PRIVACY.md](PRIVACY.md); dostupna i unutar aplikacije bez interneta.
- [x] CI izgrađuje APK i AAB te provjerava izlazne datoteke.
- [ ] Potpisati release **vlastitim Play upload ključem**; trenutni GitHub APK/AAB nisu datoteke spremne za službeni Play Console upload.
- [ ] Dovršiti Google Play Data safety obrazac prema stvarno uključenim SDK-ovima i vanjskim radnjama.
- [ ] Provjeriti popis dozvola u konačnom Android App Bundle manifestu.
- [ ] Pripremiti stvarne snimke zaslona, naziv, opis, ikonicu, dobnu ocjenu i kontaktne podatke.
- [ ] Interno testiranje i provjera sučelja, dostupnosti, sigurnosti i performansi na više fizičkih uređaja.

## Apple App Store (iOS/iPadOS)

- [x] Opisi dopuštenja kamere i odabira fotografije u `Info.plist`.
- [x] App-owned `PrivacyInfo.xcprivacy` manifest uključen u Runner resources tijekom generiranja iOS projekta.
- [x] Pravila privatnosti dostupna u aplikaciji i na javnom URL-u.
- [ ] Provjeriti i potpisati iOS aplikaciju valjanim Apple Developer timom/certifikatima i provisioning profilima.
- [ ] Prije prijave provjeriti Xcode i SDK minimum. U listopadu 2026. Apple zahtijeva Xcode 26 / SDK iOS 26 ili noviji.
- [ ] Pregledati **privacy manifests i required reason API deklaracije svih trećih SDK-ova** iz zaključanih dependency verzija; dodatno analizirati Xcode privacy report.
- [ ] Ispuniti App Privacy detalje, odgovore za dobnu ocjenu i metapodatke u App Store Connectu.
- [ ] Testirati kameru, fotogaleriju, dijeljenje, vezu s pozivateljima i mala/velika slova na stvarnim iPhone/iPad uređajima.
- [ ] Pripremiti realne snimke zaslona; dizajnerski mockup nije zamjena za stvarni prikaz aplikacije.

## Vanjski izvori

- Google: https://support.google.com/googleplay/android-developer/answer/11926878
- Google privatnost: https://support.google.com/googleplay/android-developer/answer/10144311
- Apple smjernice: https://developer.apple.com/app-store/review/guidelines/
- Apple vremenski zahtjevi: https://developer.apple.com/news/upcoming-requirements/
- Apple privacy manifest: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files

Ove zahtjeve potrebno je ponovo provjeriti neposredno prije objavljivanja, budući da se smjernice i treći SDK-ovi mijenjaju.
