# QREX — Pravila privatnosti

**Zadnje ažuriranje:** 9. listopada 2026.  
**Razvio:** Brendigo · [brendigo.com](https://brendigo.com)

QREX je Android/iOS aplikacija za lokalno skeniranje i stvaranje QR kodova. Nije potreban račun ni prijava. Ovaj dokument opisuje što aplikacija radi s podacima.

## 1. Podaci koje obrađuje

- **Kamera:** slika kamere obrađuje se radi prepoznavanja QR koda, bez slanja videozapisa na poslužitelje razvojnog tima. Dopuštenje za kameru kontroliraš u postavkama uređaja.
- **Fotografije:** datoteku odabireš iz sistemskog odabira fotografija. Odabrana slika analizira se za QR kod; QREX je ne prenosi na vlastiti poslužitelj.
- **QR sadržaj:** poveznice, tekst, kontakt, lokacija, e-mail ili Wi-Fi podaci obrađuju se lokalno kako bi aplikacija prikazala rezultat ili izradila kod.
- **Lokalna povijest:** ako je uključena, QR sadržaji i vrijeme skeniranja mogu se spremiti u lokalne postavke aplikacije, najviše 250 zapisa. Wi-Fi QR kodovi **ne spremaju se automatski**. Ručnim spremanjem Wi-Fi QR koda izričito spremaš i njegovu eventualnu lozinku.
- **Postavke:** izbor izgleda i uključivanje/isključivanje povijesti pohranjuju se lokalno.

Lokalna pohrana aplikacije nije namjenski šifrirani trezor. Nemoj spremati povjerljive lozinke ili druge tajne ako to nije nužno.

## 2. Prikupljanje i dijeljenje

QREX u ovoj verziji nema vlastiti backend, račune, oglase ni analitičko praćenje. Razvojni tim ne zaprima sadržaj QR kodova ni lokalnu povijest. Aplikacija ih sama ne šalje u oblak.

Ako svjesno odabereš **Otvori poveznicu**, **Pozovi**, **Pošalji e-mail**, **Karte** ili **Dijeli**, predani sadržaj obrađuje drugi pružatelj usluge/aplikacija prema svojim pravilima privatnosti. Vanjska web-mjesta mogu prikupljati podatke o pristupu. QR poveznice se ne otvaraju automatski.

## 3. Trajanje pohrane i brisanje

Lokalni podaci ostaju dok ih ne izbrišeš u aplikaciji ili dok uređaj/operacijski sustav ne ukloni podatke aplikacije. U **Više → Postavke** možeš isključiti bilježenje povijesti ili odabrati **Izbriši sve podatke** za brisanje povijesti, spremljenih kodova i lokalnih postavki. Deinstaliranje obično briše lokalne podatke aplikacije. Sigurnosne kopije operacijskog sustava mogu zadržati određene kopije prema korisničkim postavkama i pravilima sustava; Android automatski backup podataka aplikacije je isključen u konfiguraciji QREX-a.

## 4. Dopuštenja

QREX traži pristup kameri za funkciju skeniranja. Za fotografije koristi odabir kroz sustav gdje je dostupan. Ne treba pristup kontaktima, tvojoj lokaciji ili korisničkom računu kako bi izradio QR kod s podacima koje sam uneseš.

## 5. Kontakt

Za upite o ovoj politici i obradi podataka koristi kontaktne mogućnosti na [brendigo.com](https://brendigo.com).

## 6. Izmjene

Ažuriranja pravila objavljuju se u ovom javnom repozitoriju i u novim verzijama aplikacije. Tekst unutar aplikacije dostupan je i bez interneta. Podatke i deklaracije za App Store Connect / Google Play Console prije konačne objave treba uskladiti s točnim ponašanjem svih isporučenih verzija i SDK-ova.
