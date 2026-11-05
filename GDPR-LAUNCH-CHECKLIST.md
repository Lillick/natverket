# NÄTVERKET – GDPR- och säkerhetscheck inför lansering

Status: arbetsdokument. Detta dokument är inte ett juridiskt utlåtande eller bevis på GDPR-efterlevnad.

## 1. Nuvarande läge
- Publik informationssida finns i `index.html`.
- Administrationsdelen nås via `/?admin=1` och kräver Supabase-inloggning.
- Publika förfrågnings- och intresseformulär är avsiktligt inte aktiverade.
- Databasen innehåller register för personer, kunder, företag, uppdrag, matchningar och uppföljning.
- Lägg inte in riktiga personuppgifter i testmiljön innan kontrollpunkterna nedan är genomförda.
- Den publika webbplatsen är en informations-/förhandsversion, inte en fungerande öppen marknadsplats.

## 2. Beslut som verksamhetsägaren måste fatta
Fyll i innan publicering av formulär:
- Juridiskt ansvarig person/företag: **[MÅSTE FYLLAS I]**
- Organisationsnummer (om bolag): **[MÅSTE FYLLAS I]**
- Postadress och kontaktväg för integritetsfrågor: **[MÅSTE FYLLAS I]**
- Personuppgiftsansvarig: **[MÅSTE FASTSTÄLLAS]**
- Om NÄTVERKET agerar självständigt personuppgiftsansvarig, gemensamt ansvarig eller biträde i varje flöde: **[MÅSTE BEDÖMAS]**
- Verksamhetsmodell: ren förmedling, rekrytering, bemanning eller flera roller: **[MÅSTE FASTSTÄLLAS]**
- Geografisk lansering och målgrupper: Jönköping är planerad första marknad; bekräfta omfattning.
- Avgifter/provision, vem som fakturerar och vem som är avtalspart: **[MÅSTE FASTSTÄLLAS]**

## 3. Behandlingsregister – första utkast
| Flöde | Möjliga uppgifter | Ändamål | Åtgärd före lansering |
|---|---|---|---|
| Person-/kompetensregister | Namn, kontaktuppgifter, ort, erfarenhet, kompetens, tillgänglighet | Administrera nätverk och relevanta matchningar | Fastställ rättslig grund, information, gallring och åtkomst |
| Kundregister | Namn, e-post, telefon, ort, kundtyp, ärendenoteringar | Hantera kundrelation och förfrågningar | Minimera fält och definiera lagringstid |
| Företagsregister | Företagsnamn, org.nr, kontaktperson, kontaktuppgifter | Företagsrelationer och uppdrag | Kontaktpersoners uppgifter är personuppgifter; fastställ grund |
| Uppdragsregister | Beskrivning, ort, budget, startdatum, kopplad kund | Hantera och matcha behov | Undvik känsliga personuppgifter i fritext |
| Matchningar | Koppling mellan uppdrag och person, poäng, status, anteckningar | Föreslå relevanta kontakter | Transparens om matchningslogik; mänsklig kontroll |
| Kommunikation/uppföljning | Datum, kanal, anteckningar, svar | Följa upp kontakter och uppdrag | Begränsa anteckningar och behörigheter |
| Provision/ersättning | Uppdrags- och betalningsuppgifter | Ekonomisk uppföljning | Fastställ bokföringskrav och separat gallring |

## 4. Rättslig grund och transparens
- Bestäm rättslig grund separat för varje ändamål. Samtycke ska inte användas slentrianmässigt; pröva om avtal, rättslig förpliktelse eller dokumenterad intresseavvägning är korrekt.
- Om samtycke används ska det vara frivilligt, specifikt, informerat, otvetydigt, dokumenterat och lika enkelt att återkalla.
- Ge information när uppgifterna samlas in och när uppgifter hämtas från annan källa.
- Beskriv ändamål, rättslig grund, kategorier av uppgifter, mottagare, eventuella tredjelandsöverföringar, lagringstid, rättigheter, klagomål till IMY och eventuell profilering/automatiserat beslutsfattande.
- Matchningsförslag ska ha mänsklig granskning. Utred om någon matchning eller rangordning kan utgöra profilering eller automatiserat beslut med betydande effekt.
- Samla inte in personnummer, hälsouppgifter, uppgifter om brott eller andra känsliga uppgifter om det inte finns ett separat dokumenterat behov och lagligt stöd.

## 5. Säkerhetskrav – teknisk spärrlista
- Kontrollera RLS på samtliga tabeller och vyer. Ingen anonym/public roll ska kunna läsa eller skriva person-, kund-, företags-, uppdrags- eller matchningsdata.
- Kontrollera varje policy med negativa tester: anon ska nekas; vanlig inloggad användare ska endast se vad rollen behöver; admin ska ha minsta nödvändiga åtkomst.
- Granska alla SECURITY DEFINER-funktioner: fast search_path, begränsad EXECUTE-behörighet, kontroll av användarroll inne i funktionen.
- Service-role-nyckel får aldrig finnas i webbläsare, GitHub eller klientkod. Endast publishable/anon-nyckel får användas i klient och då med korrekt RLS.
- Slå på MFA för administratörskonton där det stöds; använd unika lösenord och begränsa administratörsbehörighet.
- Säkerställ säker sessionhantering, återställning av lösenord, utloggning och borttagning av åtkomst för tidigare administratörer.
- Kontrollera att loggar inte innehåller lösenord, tokens eller onödiga personuppgifter.
- Lägg inte personuppgifter i URL:er, felmeddelanden eller publika Git-commits.
- Gör backup- och återställningstest; fastställ vem som får åtkomst till backup.
- Kontrollera leverantörsavtal, underbiträden, datalagringsregioner och eventuella överföringar utanför EES för Supabase, Vercel, e-post, analys och andra tjänster.
- Gör säkerhetstest före öppning av externa formulär. Lägg till rate limiting, spam-/bot-skydd, validering på serversidan och säker felhantering.

## 6. Rättigheter och operativa rutiner
Skapa dokumenterade processer för:
- Registerutdrag och tillgång.
- Rättelse.
- Radering och invändning.
- Begränsning av behandling.
- Dataportabilitet när tillämpligt.
- Återkallelse av samtycke när samtycke används.
- Identifiering av begäran och svar inom GDPR:s tidsfrister.
- Gallring och radering i databasen, loggar, exportfiler och säkerhetskopior enligt fastställd policy.
- Incidenthantering: dokumentera alla personuppgiftsincidenter; bedöm anmälningsplikt och anmäl normalt till IMY inom 72 timmar när incidenten sannolikt medför risk. Informera berörda vid sannolik hög risk.
- Behörighetsgranskning minst kvartalsvis och vid rollförändring.

## 7. Dokument som behövs före skarp drift
- Integritetspolicy som speglar verkliga dataflöden.
- Användarvillkor för kunder och personer som erbjuder tjänster/arbete.
- Förmedlings-/matchningsvillkor och tydlig beskrivning av vem som är avtalspart.
- Personuppgiftsbiträdesavtal med leverantörer där sådana krävs samt lista över underbiträden.
- Register över behandlingar (ROPA) när skyldigheten gäller.
- Dokumenterad intresseavvägning där berättigat intresse används.
- Gallrings- och lagringsplan.
- Incident- och begäransrutiner.
- Eventuell konsekvensbedömning (DPIA) om behandlingen sannolikt medför hög risk.
- Bedömning av arbetsrätt, rekryterings-/bemanningsregler, konsumenträtt, skatter och ansvar för tjänsteutförare utifrån den slutliga affärsmodellen.

## 8. Godkännandekriterier – öppna inte formulär förrän
- [ ] Juridisk verksamhetsägare och personuppgiftsansvarig är fastställda.
- [ ] Alla ändamål och rättsliga grunder är dokumenterade.
- [ ] Integritetstext och villkor är granskade och kompletta.
- [ ] Leverantörernas personuppgiftsbiträdesavtal och överföringar är kontrollerade.
- [ ] RLS och behörigheter är verifierade med negativa tester.
- [ ] Admin-MFA och säker sessionhantering är aktiverade där möjligt.
- [ ] Gallring, registerutdrag, rättelse och radering är testade.
- [ ] Incidentprocess och kontaktvägar finns.
- [ ] Säkerhetskopiering och återställning är testade.
- [ ] Formulär har serversidevalidering, spam-skydd och dataminimering.
- [ ] En oberoende teknisk och juridisk granskning har gjorts.

## Officiella källor
- GDPR, förordning (EU) 2016/679: https://eur-lex.europa.eu/eli/reg/2016/679/oj?locale=sv
- IMY – rättslig grund: https://www.imy.se/verksamhet/dataskydd/det-har-galler-enligt-gdpr/rattslig-grund/
- IMY – registrerades rättigheter: https://www.imy.se/verksamhet/dataskydd/det-har-galler-enligt-gdpr/de-registrerades-rattigheter/
- IMY – personuppgiftsbiträdesavtal: https://www.imy.se/verksamhet/dataskydd/det-har-galler-enligt-gdpr/personuppgiftsansvariga-och-personuppgiftsbitraden/personuppgiftsbitradesavtal/
- IMY – personuppgiftsincidenter: https://www.imy.se/verksamhet/dataskydd/det-har-galler-enligt-gdpr/personuppgiftsincidenter/

Senast uppdaterad: 2026-11-05
