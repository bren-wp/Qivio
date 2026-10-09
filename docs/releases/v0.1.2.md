# QREX v0.1.2 — Privatnost, stabilnost i platforme

Nastavak razvoja QREX QR skenera i kreatora za Android i iOS.

### Novi sadržaj
- U **Više → O aplikaciji** dodano **„Razvio Brendigo”** s poveznicom na brendigo.com.
- U postavke dodana lako dostupna pravila privatnosti koja se čitaju offline i njihova javna verzija.
- Postavljen recovery zaslon za pogreške inicijalizacije lokalne pohrane, s mogućnošću ponovnog pokušaja.
- Android koristi API 36 i isključuje automatski backup te nešifrirani mrežni promet same aplikacije.
- iOS projekt uključuje privacy manifest aplikacije i opise korištenja kamere/fotografija.
- CI dodatno provjerava platformsku konfiguraciju; izrađuje Android APK i AAB, iOS bez potpisivanja.

### Sigurnost i objava
- Nema korisničkog računa, integrirane analitike ni reklamnog sustava.
- QR kodovi obrađuju se lokalno; vanjske poveznice otvaraju se samo korisničkim izborom.
- Instalacijski Android APK na GitHubu je testna release izgradnja, nije potpisan produkcijskim Play upload ključem.
- iOS kompilacija ne isporučuje instalacijski IPA bez Appleovog potpisivanja.

### Status
Automatska analiza i izgradnje nisu dokaz potpune 1:1 podudarnosti sa slikovnim predloškom, odsutnosti rušenja na svim uređajima ni konačnog prihvaćanja u trgovinama. Prije službene objave izvršiti [checklistu](docs/STORE_CHECKLIST.md) i testirati stvarne telefone.
