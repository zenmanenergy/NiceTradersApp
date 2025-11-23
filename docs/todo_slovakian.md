# NICE Traders - Zoznam Úloh pre MVP

**Prioritné úlohy na dosiahnutie statusu Minimálneho Životaschopného Produktu (MVP)**

---

## 🔴 Kritické - Nevyhnutné pre MVP

### Testovanie a Zabezpečenie Kvality
- [x] **Jednotkové Testy - Backend**
  - [x] Otestovať všetky Flask API endpointy (56 testov úspešných)
  - [x] Otestovať databázové operácie (CRUD)
  - [x] Otestovať autentifikáciu/správu relácií
  - [x] Otestovať výpočty výmenných kurzov
  - [x] Otestovať funkcionalitu kontaktov/správ
  - [x] Nastaviť pytest framework
  - [x] Vytvorená komplexná testovacia sada s fixtures
  - [x] Štandardizovaný UUID formát (3-písmenová predpona + 35-znakové UUID = 39 znakov)
  - [x] Opravené všetky nezrovnalosti názvov SQL stĺpcov
  - [ ] Pridať reportovanie testovacej pokrytosti (cieľ 80%+)

- [ ] **Jednotkové Testy - iOS**
  - [ ] Vytvoriť XCTest testovací cieľ
  - [ ] Otestovať funkcionalitu SessionManager
  - [ ] Otestovať výpočty ExchangeRatesAPI
  - [ ] Otestovať LocationManager
  - [ ] Otestovať view models a parsovanie dát
  - [ ] Otestovať konštrukciu URL pre API volania
  - [ ] Pridať UI testy pre kritické používateľské toky

- [ ] **Jednotkové Testy - Web**
  - [ ] Nastaviť Vitest alebo Jest
  - [ ] Otestovať integračné funkcie API
  - [ ] Otestovať validáciu formulárov
  - [ ] Otestovať správu relácií
  - [ ] Testovanie komponentov pre kritické zobrazenia

### Mapy a Lokácia
- [ ] **iOS Integrácia Máp**
  - [ ] Importovať MapKit framework
  - [ ] Vytvoriť MapView komponent
  - [ ] Zobraziť inzeráty na mape so špendlíkmi
  - [ ] Zobraziť aktuálnu polohu používateľa
  - [ ] Vypočítať a zobraziť vzdialenosti
  - [ ] Zoskupovať blízke špendlíky pre výkon
  - [ ] Pridať prepínač mapa/zoznam v SearchView
  - [ ] Implementovať funkcionalitu "Nájsť v blízkosti"

- [ ] **Web Integrácia Máp** (už má čiastočne Google Maps)
  - [ ] Overiť funkčnosť Google Maps API
  - [ ] Zobraziť inzeráty na mape
  - [ ] Pridať filtrovanie podľa vzdialenosti
  - [ ] Optimalizovať výkon máp

### Integrácia Platieb
- [ ] **PayPal Integrácia - iOS**
  - [ ] Pridať PayPal SDK do Xcode projektu
  - [ ] Implementovať skutočný tok platieb (momentálne placeholder)
  - [ ] Otestovať sandbox platby
  - [ ] Spracovať stavy úspechu/zlyhania platby
  - [ ] Uložiť záznamy transakcií

- [ ] **PayPal Integrácia - Web**
  - [ ] Implementovať PayPal checkout tok
  - [ ] Otestovať sandbox prostredie
  - [ ] Spracovať callbacks a webhooky

- [ ] **PayPal Integrácia - Backend**
  - [ ] Nastaviť PayPal API prihlasovacie údaje
  - [ ] Vytvoriť platobné endpointy
  - [ ] Overiť dokončenie platby
  - [ ] Uložiť históriu transakcií v databáze
  - [ ] Spracovať refundácie/spory

### Bezpečnosť a Autentifikácia
- [ ] **Zabezpečená Správa Relácií**
  - [ ] Implementovať expiráciu relácií
  - [ ] Pridať mechanizmus obnovovacieho tokenu
  - [ ] Zabezpečené uloženie relácií (iOS Keychain)
  - [ ] Vynútenie HTTPS
  - [ ] Audit prevencie SQL injection
  - [ ] Audit prevencie XSS

- [ ] **Validácia Dát**
  - [ ] Server-side validácia vstupov pre všetky endpointy
  - [ ] Sanitizovať všetky používateľské vstupy
  - [ ] Validovať kódy mien
  - [ ] Validovať sumy a čísla
  - [ ] Obmedzenie frekvencie požiadaviek na API endpointy

### Medzery v Základnej Funkcionalite
- [ ] **Systém Správ**
  - [ ] Real-time alebo takmer real-time správy (momentálne používa polling)
  - [ ] Potvrdenia o prečítaní správ
  - [ ] Zdieľanie obrázkov v správach (voliteľné pre MVP)
  - [ ] Funkcionalita blokovania/nahlasovania používateľov

- [ ] **Návrhy Stretnutí**
  - [ ] Opraviť tok návrhov stretnutí ak je pokazený
  - [ ] Pridať integráciu kalendára (iOS)
  - [ ] Posielať pripomienky nadchádzajúcich stretnutí

- [ ] **Overenie Používateľa**
  - [ ] Systém overenia emailu
  - [ ] Overenie telefónu (SMS)
  - [ ] Overenie občianskeho preukazu (voliteľné pre MVP)
  - [ ] Odznaky dôvery pre overených používateľov

---

## 🟡 Vysoká Priorita - Odporúčané pre MVP

### Push Notifikácie
- [ ] **iOS Push Notifikácie**
  - [ ] Nastaviť Apple Push Notification service (APNs)
  - [ ] Registrovať tokeny zariadení
  - [ ] Posielať notifikácie pre nové správy
  - [ ] Posielať notifikácie pre návrhy stretnutí
  - [ ] Posielať notifikácie pre blízke inzeráty
  - [ ] Spracovať kliknutia na notifikácie

- [ ] **Backend Notifikačný Systém**
  - [ ] Vytvoriť frontu/službu notifikácií
  - [ ] Uložiť tokeny zariadení
  - [ ] Posielať push notifikácie cez APNs
  - [ ] Sledovať doručenie notifikácií

### Vylepšenia Používateľskej Skúsenosti
- [ ] **Tok Onboardingu**
  - [ ] Tutoriál pre nových používateľov
  - [ ] Žiadosti o povolenia (lokácia, notifikácie)
  - [ ] Sprievodca nastavením profilu

- [ ] **Vylepšenia Vyhľadávania**
  - [ ] Uložiť filtre vyhľadávania
  - [ ] História nedávnych vyhľadávaní
  - [ ] Navrhované vyhľadávania podľa lokácie
  - [ ] Možnosti triedenia (vzdialenosť, suma, dátum)

- [ ] **Vylepšenia Profilu**
  - [ ] Nahrávanie profilovej fotky
  - [ ] Sekcia bio/o mne
  - [ ] Hovorené jazyky
  - [ ] Preferované miesta stretnutí

### Dáta a Analytika
- [ ] **Logovanie Chýb**
  - [ ] Nastaviť sledovanie chýb (Sentry alebo podobné)
  - [ ] Logovať API chyby
  - [ ] Logovať crash reporty
  - [ ] Monitorovať problémy s výkonom

- [ ] **Analytika**
  - [ ] Sledovať akcie používateľov (vytváranie inzerátov, vyhľadávania)
  - [ ] Monitorovať konverzný lievik
  - [ ] Sledovať mieru úspešnosti platieb
  - [ ] Geografické vzorce používania

### Výkon
- [ ] **iOS Výkon**
  - [ ] Lazy loading pre dlhé zoznamy
  - [ ] Cachovanie obrázkov pre vlajky a fotky
  - [ ] Optimalizovať API volania (redukovať redundantné požiadavky)
  - [ ] Pozaďové obnovenie pre výmenné kurzy

- [ ] **Backend Výkon**
  - [ ] Optimalizácia databázových dotazov
  - [ ] Pridať indexy pre časté dotazy
  - [ ] Implementovať cachovanie (Redis)
  - [ ] Monitorovanie času odozvy API

---

## 🟢 Stredná Priorita - Užitočné Doplnky

### Pokročilé Funkcie
- [ ] **QR Kód Overenie**
  - [ ] Generovať QR kódy pre stretnutia
  - [ ] Implementácia skeneru (iOS)
  - [ ] Overiť dokončenie výmeny cez QR

- [ ] **Pokročilé Filtrovanie**
  - [ ] Filtrovať podľa hodnotenia používateľa
  - [ ] Filtrovať podľa stavu overenia
  - [ ] Filtrovať podľa dátumu dostupnosti

- [ ] **Sociálne Funkcie**
  - [ ] Sledovať častých obchodníkov
  - [ ] Zdieľať inzeráty cez sociálne médiá
  - [ ] Systém odporúčaní priateľov

### Administratívne
- [ ] **Administrátorský Dashboard** (Web)
  - [ ] Zobraziť všetkých používateľov
  - [ ] Zobraziť všetky inzeráty
  - [ ] Zobraziť všetky transakcie
  - [ ] Moderovať nahlásený obsah
  - [ ] Zablokovať/pozastaviť používateľov
  - [ ] Prehľad analytiky

- [ ] **Moderovanie Obsahu**
  - [ ] Funkcionalita nahlasovania inzerátov
  - [ ] Funkcionalita nahlasovania používateľov
  - [ ] Systém preskúmania nahlásení
  - [ ] Automatická detekcia spamu

### Dokumentácia
- [ ] **API Dokumentácia**
  - [ ] Vytvoriť OpenAPI/Swagger dokumentáciu
  - [ ] Dokumentovať všetky endpointy
  - [ ] Zahrnúť príklady request/response
  - [ ] Referencia chybových kódov

- [ ] **Používateľská Dokumentácia**
  - [ ] Sekcia Pomoc/FAQ
  - [ ] Stránka bezpečnostných tipov
  - [ ] Návody
  - [ ] Video tutoriály

---

## 🔵 Nízka Priorita - Budúce Vylepšenia

### Android Aplikácia
- [ ] Portovať iOS aplikáciu na Android (Fáza 3)
- [ ] Odoslanie do Google Play Store

### Internacionalizácia
- [ ] Podpora viacerých jazykov
- [ ] Lokalizácia symbolov mien
- [ ] Lokalizácia formátu dátumu/času

### Pokročilé Platobné Možnosti
- [ ] Priama platba kreditnou kartou
- [ ] Integrácia Apple Pay
- [ ] Integrácia Google Pay
- [ ] Podpora kryptomien

---

## 📋 Kontrolný Zoznam pred Spustením

### Právne a Súlad
- [ ] Kontrola Zásad Ochrany Súkromia (právny poradca)
- [ ] Kontrola Podmienok Služby (právny poradca)
- [ ] Súlad spracovania platieb (PCI DSS)
- [ ] Súlad ochrany údajov (GDPR ak používatelia z EU)
- [ ] Založenie obchodnej entity
- [ ] Obchodné poistenie

### Infraštruktúra
- [ ] Nastavenie produkčného servera
- [ ] Automatizované zálohy databázy
- [ ] SSL certifikáty
- [ ] CDN pre statické assety
- [ ] Monitorovanie a upozorňovanie
- [ ] Plán obnovy po havárii

### Príprava na App Store
- [ ] **iOS App Store**
  - [ ] Nastavenie vývojárskeho účtu
  - [ ] App Store screenshoty
  - [ ] App Store popis
  - [ ] App Store kľúčové slová
  - [ ] Príprava na App review
  - [ ] Beta testovanie cez TestFlight
  - [ ] Privacy nutrition label

### Príprava Marketingu
- [ ] Vstupná stránka/webová stránka
- [ ] Účty na sociálnych médiách
- [ ] Press kit
- [ ] Získavanie beta používateľov
- [ ] Spustenie emailovej kampane

---

## 🎯 Aktuálny Stav

### ✅ Dokončené
- [x] Backend API so všetkými základnými endpointmi
- [x] Systém autentifikácie používateľov
- [x] CRUD operácie inzerátov
- [x] Funkcionalita vyhľadávania (základná)
- [x] Integrácia API výmenných kurzov
- [x] Web prototyp (Svelte)
- [x] iOS aplikácia základná štruktúra
- [x] Detekcia lokácie (iOS)
- [x] Správa relácií
- [x] Používateľské profily
- [x] UI správ (základné)
- [x] Systém hodnotenia (základný)
- [x] Databázová schéma kompletná (19 tabuliek)
- [x] Komplexné jednotkové testy backendu (56 testov, 100% úspešnosť)
- [x] Štandardizácia UUID naprieč celým kódom

### 🚧 Prebieha
- [ ] Dokončenie iOS natívnej aplikácie
- [ ] Integrácia platieb
- [ ] Integrácia máp
- [ ] Push notifikácie

### ❌ Nezačaté
- [ ] Administrátorský dashboard
- [ ] QR overenie
- [ ] Produkčné nasadenie

---

## 📊 Skóre Pripravenosti MVP

**Odhadované Dokončenie: ~70%** (Aktualizované zo 60%)

### Nedávny Pokrok:
- ✅ Backend jednotkové testovanie dokončené (56 testov)
- ✅ Databázová schéma validovaná a opravená
- ✅ UUID formát štandardizovaný naprieč systémom
- ✅ Všetky API endpointy otestované a overené

### Kritická Cesta k MVP:
1. **Testovacia Infraštruktúra** (2-3 týždne)
2. **Integrácia Platieb** (2-3 týždne)
3. **Integrácia Máp** (1-2 týždne)
4. **Push Notifikácie** (1-2 týždne)
5. **Bezpečnostný Audit** (1 týždeň)
6. **Beta Testovanie** (2-4 týždne)
7. **Opravy Chýb a Doladenie** (2-3 týždne)

**Odhadovaný čas do MVP: 11-17 týždňov** (za predpokladu 1 vývojár na plný úväzok)

---

## 🔄 Najbližšie Akcie

1. **Tento Týždeň:**
   - [ ] Nastaviť testovacie frameworky (pytest, XCTest)
   - [ ] Napísať prvé jednotkové testy pre kritické funkcie
   - [ ] Preskúmať požiadavky integrácie PayPal SDK

2. **Budúci Týždeň:**
   - [ ] Implementovať MapKit v iOS SearchView
   - [ ] Dokončiť 50% testovaciu pokrytosť na backende
   - [ ] Začať PayPal sandbox integráciu

3. **Tento Mesiac:**
   - [ ] Dokončiť všetky kritické testovanie
   - [ ] Dokončiť integráciu platieb
   - [ ] Nasadiť do TestFlight pre interné testovanie
   - [ ] Začať implementáciu push notifikácií

---

**Posledná Aktualizácia:** 23. november 2025
