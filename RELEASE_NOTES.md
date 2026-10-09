# QREX v0.1.1 — Pouzdanije skeniranje i profinjeniji UX

QREX ostaje jednostavna QR aplikacija za Android i iOS, bez prijave i bez oglasa.

### Poboljšanja
- Stabilnije skeniranje: uklonjene utrke između galerije i kamere, pouzdanije zaustavljanje i nastavak skenera, prilagodljiv okvir skeniranja.
- Sigurnija povijest: skeniranje ne sprema Wi-Fi lozinke automatski; već spremljeni kodovi ne dupliciraju se ponovnim skeniranjem.
- Wi-Fi privatnost: lozinka je zadano skrivena u rezultatima, a prije ručnog spremanja prikazuje se upozorenje.
- Rezultati: prikaz skeniranog QR koda, poboljšano dijeljenje na iPadu i dodatne provjere otvaranja vanjskih poveznica.
- Kreator: pregledniji odabir vrsta QR kodova, kontrola vidljivosti Wi-Fi lozinke, validacija GPS koordinata i ograničenje veličine podataka.
- Podržan veći raspon veličina zaslona. Dodani regresijski testovi sadržaja, spremanja i UI ekrana.
- Android automatsko sigurnosno kopiranje podataka aplikacije isključeno.

### Datoteke i instalacija
- **QREX-Android-v0.1.1.apk** — probni Android APK iz uspješnog GitHub Actions builda (nije potpisan za objavu na Google Playu).
- **SHA256SUMS.txt** — SHA-256 kontrolni zbroj.
- iOS: produkcijska kompilacija bez potpisivanja; za iPhone distribuciju potrebni su Apple certifikat i provisioning.

**Napomena:** Automatski testovi i kompilacija ne potvrđuju 1:1 podudarnost sa slikovnim predloškom niti ponašanje na svim fizičkim uređajima; završno testiranje ostaje obavezno.
