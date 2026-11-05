# NÄTVERKET – lanseringschecklista

Detta repo innehåller en tidig admin-MVP och publik informationssida. Att kod finns i GitHub betyder inte att tjänsten är produktionsklar.

## Status utifrån det som faktiskt är byggt
- [x] Publik startsida och grundläggande presentation.
- [x] Separat adminväg via `/?admin=1`.
- [x] Admininloggning via Supabase Auth.
- [x] Adminvy för personer, kunder, företag, uppdrag och matchningar.
- [x] Matchningsfunktion anropar befintlig Supabase RPC.
- [ ] Publika kundförfrågningar och intresseanmälningar – inte öppnade.
- [ ] Verifierad RLS och tabellbehörighet för varje tabell.
- [ ] Granskning av SECURITY DEFINER-funktioner och RPC-behörigheter.
- [ ] Raderings-, registerutdrags- och rättelserutiner testade.
- [ ] Backup/återställning och incidentrutin testade.
- [ ] Juridiska texter färdigställda med verkliga företagsuppgifter.
- [ ] Fullständigt acceptanstest på mobil och dator.

## Obligatoriskt före riktiga användare
1. Kör den read-only kontrollen i `supabase/SECURITY_AUDIT.sql` i Supabase SQL Editor.
2. Granska att RLS är aktiverat och att endast rätt roller får läsa/ändra varje tabell.
3. Granska alla funktioner med SECURITY DEFINER. Begränsa EXECUTE till avsedda roller och sätt ett säkert search_path.
4. Bekräfta att endast anon/publishable key finns i webbläsaren. Service role får aldrig finnas i frontend eller GitHub.
5. Bygg publika formulär via server-side Edge Function med validering, spam-/rate-limit-skydd och minimal datainsamling. Ge inte anon generell INSERT/SELECT på registertabellerna.
6. Dokumentera personuppgiftsansvarig, ändamål, rättslig grund, kategorier av uppgifter, mottagare/biträden, lagringstider, eventuella tredjelandsöverföringar och registrerades rättigheter.
7. Teckna/granska personuppgiftsbiträdesavtal där det behövs och kontrollera Supabase/Vercel-konfiguration och underbiträden.
8. Skriv riktiga villkor utifrån den slutliga affärsmodellen: vem förmedlar, vem ingår avtal, avgifter/provision, ansvar, reklamation, avbokning och tvist.
9. Testa behörigheter med minst ett admin-konto och ett vanligt konto. Testa även utloggad användare.
10. Gör ett dokumenterat lanseringsbeslut först när alla punkter är godkända.

## GDPR – miniminivå
- Samla bara in uppgifter som behövs för ett tydligt ändamål.
- Informera innan uppgifter samlas in; skilj mellan nödvändig behandling och frivillig marknadsföring.
- Använd inte samtycke slentrianmässigt när annan rättslig grund är korrekt.
- Bestäm gallringsfrister och radera/anonymisera uppgifter när de inte längre behövs.
- Begränsa åtkomst enligt minsta privilegium och logga relevanta administrativa åtgärder.
- Ha process för begäran om tillgång, rättelse, radering, begränsning och dataportabilitet där tillämpligt.
- Ha incidentrutin och bedömning av eventuell anmälningsskyldighet.
- Bedöm om konsekvensbedömning (DPIA) krävs innan mer omfattande eller riskfylld behandling.

## Viktigt
Detta är en teknisk och operativ checklista, inte juridisk rådgivning eller ett intyg om GDPR-efterlevnad. Lämna inte in verkliga personuppgifter förrän säkerhetsgranskningen är genomförd.
