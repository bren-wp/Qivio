<div align="center">

<img src="assets/brand/qrex-logo.svg" width="420" alt="QREX logo">

# QREX
### Skeniraj. Stvori. Dijeli.

**Brz QR skener i kreator kodova za Android i iOS. Bez prijave. Bez računa.**

[![Mobile CI](https://github.com/bren-wp/Qivio/actions/workflows/mobile.yml/badge.svg)](https://github.com/bren-wp/Qivio/actions/workflows/mobile.yml)
![Flutter](https://img.shields.io/badge/Flutter-Android%20%2B%20iOS-1677FF)
![Privacy](https://img.shields.io/badge/Podaci-na%20ure%C4%91aju-10B981)

<img src="assets/brand/qrex-icon.svg" width="125" alt="Ikonica aplikacije">

</div>

## Jedna aplikacija. Sve što trebaš za QR.

**Skeniranje kamerom**, QR iz fotografije, izrada kodova, kopiranje, dijeljenje, otvaranje poveznica, lokalna povijest i spremljeni kodovi. Dizajn prati tamnu plavo-ljubičastu QREX paletu s dostavljenog vizualnog predloška, a radne funkcije ne zahtijevaju korisnički račun.

| Skeniraj | Stvori | Povijest | Više |
| --- | --- | --- | --- |
| Kamera, galerija, svjetiljka | URL, tekst, Wi-Fi, kontakt, e-mail, telefon, lokacija, događaj | Pretraživanje, spremanje, brisanje | Tema, kontrola povijesti, privatnost |

## Pokretanje

Potreban je **Flutter stable** i Android SDK / Xcode (za iOS isključivo na macOS-u).

```bash
flutter create --platforms=android,ios --org com.brendigo --project-name qrex .
python3 tool/prepare_platforms.py
flutter pub get
flutter run
```

Naredba `flutter create` generira standardne platformske direktorije iz Flutter predložaka. Namjerno se ne verzioniraju kako bi Android i iOS koristili aktualnu kompatibilnu Flutter konfiguraciju. Skripta postavlja naziv, permissions i sve veličine ikonica na obje platforme. CI radi isti postupak i provjerava buildove.

## Privatnost i sigurnost

- Skeniranje i generiranje rade na uređaju; nema aplikacijskog poslužitelja ni korisničkih računa.
- Povijest se pohranjuje u lokalne postavke uređaja, može se isključiti ili izbrisati.
- Poveznica se **ne otvara automatski** nakon skeniranja.
- Nema analitike, oglasa, trackera ni cloud sinkronizacije.
- Vanjske poveznice, dijeljenje i mail/karte mogu koristiti druge aplikacije i internet.
- QREX **ne jamči** sigurnost otvorene vanjske poveznice; korisnik vidi punu adresu prije otvaranja.

## Provjera kvalitete

GitHub Actions izvršava `flutter analyze`, `flutter test`, Android release APK build i odvojeni iOS no-codesign build na macOS runneru. APK se može preuzeti kao GitHub Actions artifact kad build završi uspješno. Za objavu na trgovinama potrebno je produkcijsko potpisivanje te provjera na fizičkim uređajima.

## Brending

Vektorski logotip i ikonica su u `assets/brand/`. Android i iOS launcher ikonice generira `tool/prepare_platforms.py` iz istog QREX dizajna. Vizualni predložak ostaje smjernica; vektorski prikaz se može dorađivati bez gubitka kvalitete.

**Repozitorij:** [bren-wp/Qivio](https://github.com/bren-wp/Qivio) · **Naziv aplikacije:** QREX · **Licencija:** MIT
