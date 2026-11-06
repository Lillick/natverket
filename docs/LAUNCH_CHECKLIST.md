# NÄTVERKET – lanseringsplan och verifieringsstatus

Detta repo innehåller en tidig admin-MVP och publik informationssida. Att kod finns i GitHub eller att grundläggande SQL-kontroller passerar betyder inte att tjänsten är produktionsklar.

## Verifierat i Supabase – 2026-11-06

Följande kontroller har körts och resultaten har rapporterats:
- [x] RLS aktiverat på samtliga 16 publika tabeller.
- [x] Inga anonyma tabellbehörigheter kvar efter att SELECT på audit_events återkallats.
- [x] Inga publika funktioner med EXECUTE för rollen anon.
- [x] De tre dataskyddstabellerna privacy_requests, privacy_records och audit_events finns och har RLS.
- [x] generate_request_matches(uuid) är SECURITY DEFINER, har tom search_path, kräver admin och filtrerar på people.status = 'active'.
- [x] audit_events ger authenticated endast SELECT; anon har ingen behörighet.

Detta är en grundläggande teknisk kontroll, inte en fullständig penetrationstestning, behörighetsrevision eller ett juridiskt GDPR-godkännande.

## Vad som faktiskt finns i appen

- [x] Publik informationssida med beskrivning av NÄTVERKET och tjänsteområden.
- [x] Separat adminväg via `/?admin=1`.
- [x] Admininloggning via Supabase Auth och kontroll av adminroll i profiles.
- [x] Adminvyer för personer, kunder, företag, uppdrag och matchningar.
- [x] Matchningsvyn anropar Supabase RPC.
- [ ] Publika formulär för kundförfrågan och intresseanmälan.
- [ ] Server-side intake med validering, spam-/rate-limit-skydd och säker hantering.
- [ ] Adminvyer för GDPR-ärenden, revisionslogg, uppföljningar, tilldelningar och provisioner.
- [ ] Test av flöden med admin, vanligt konto och utloggad besökare.
- [ ] Säkerhetskopiering och återställning testad.
- [ ] Juridiska texter färdigställda med verkliga företags- och kontaktuppgifter.
- [ ] Dokumenterat acceptanstest på mobil och dator.

## Nästa arbetsfaser – samla arbetet i större leveranser

### Fas 1 – fungerande intag från publika webbplatsen
1. Bygg två tydliga publika flöden: "Jag behöver hjälp" och "Jag söker jobb eller uppdrag".
2. Skicka formulärdata via en server-side Supabase Edge Function; ge aldrig anon direkt INSERT/SELECT i registertabellerna.
3. Lägg till validering, honeypot och lämpligt spam-/rate-limit-skydd.
4. Spara minsta nödvändiga uppgifter och visa tydlig bekräftelse utan att exponera interna register.
5. Lägg till inkomna förfrågningar i adminflödet med status "ny".

### Fas 2 – komplett adminflöde
1. Lägg till adminvyer för uppföljningar, tilldelningar, provisioner och dataskyddsärenden.
2. Visa revisionslogg skrivskyddat.
3. Förbättra matchningshantering: godkänna kontakt, registrera svar och följa status.
4. Lägg till redigering, arkivering och kontrollerad radering där det behövs.

### Fas 3 – GDPR och juridik
1. Fastställ personuppgiftsansvarig och kontaktuppgifter.
2. Dokumentera ändamål, rättslig grund per flöde, datakategorier, mottagare/biträden, överföringar och lagringstider.
3. Färdigställ integritetspolicy, cookiebedömning och villkor efter beslutad affärsmodell.
4. Bygg och testa processer för registerutdrag, rättelse, radering, begränsning, invändning och dataportabilitet där tillämpligt.
5. Dokumentera incidentrutin, backup/återställning och bedömning av DPIA.
6. Låt juridiska texter och ansvarsfördelning granskas innan publik lansering.

### Fas 4 – kvalitetssäkring och lansering
1. Testa samtliga flöden på mobil och dator.
2. Testa behörigheter med admin, vanligt inloggat konto och utloggad besökare.
3. Kontrollera att endast anon/publishable key finns i webbläsaren. service_role får endast finnas som server-side secret.
4. Genomför dokumenterad acceptans- och återställningstest.
5. Öppna publik registrering först när samtliga lanseringskrav är uppfyllda.

## GDPR – miniminivå

- Samla bara in uppgifter som behövs för ett tydligt ändamål.
- Informera innan uppgifter samlas in; skilj mellan nödvändig behandling och frivillig marknadsföring.
- Använd inte samtycke slentrianmässigt när annan rättslig grund är korrekt.
- Bestäm gallringsfrister och radera/anonymisera uppgifter när de inte längre behövs.
- Begränsa åtkomst enligt minsta privilegium och logga relevanta administrativa åtgärder.
- Ha process för registrerades rättigheter och incidenthantering.
- Bedöm om konsekvensbedömning (DPIA) krävs innan mer omfattande eller riskfylld behandling.

## Viktigt

Databastabeller för dataskydd är stöd för en process, inte en färdig GDPR-process i sig. Detta dokument är en teknisk och operativ plan, inte juridisk rådgivning eller ett intyg om GDPR-efterlevnad. Använd inte riktiga personuppgifter eller öppna publik registrering förrän relevanta säkerhets-, drift- och dataskyddskrav är testade.
