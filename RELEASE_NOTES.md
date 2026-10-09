# QREX v0.1.3 — Pouzdanija pohrana i sigurniji QR sadržaji

- Wi-Fi QR parser prepoznaje eskapirane točke sa zarezom, dvotočke, zareze i obrnute kose crte bez zabune oko razdjelnika.
- URL i e-mail radnje imaju strože provjere kontrolnih znakova i formata.
- Lokalni zapisi i postavke upisuju se redoslijedom, uključujući brisanje podataka.
- Kopiranje i spremanje sada hvataju pogreške sustava te ih jasno prikazuju umjesto prekida radnje.
- Regresijski testovi pokrivaju Wi-Fi kodove s posebnim znakovima i paralelne operacije spremanja.
- „Razvio Brendigo”, lokalna pravila privatnosti i QREX identitet ostaju dostupni u postavkama.

Android CI izrađuje APK i AAB, iOS se kompilira bez potpisivanja. Instalacijski iOS IPA zahtijeva Appleov certifikat i provisioning profile; Android Store distribucija zahtijeva produkcijsko potpisivanje i završnu provjeru na fizičkim uređajima.

Automatska provjera ne dokazuje potpunu 1:1 podudarnost sa slikovnim predloškom ni rad bez rušenja na svim uređajima.
