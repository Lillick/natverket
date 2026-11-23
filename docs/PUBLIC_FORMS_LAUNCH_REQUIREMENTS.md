# NÄTVERKET – publika formulär

Publika formulär ska inte anslutas direkt till Supabase-tabeller. Den publika webbplatsen ska skicka uppgifter till en serverfunktion som validerar innehållet och skriver till databasen med en server-side nyckel. Nyckeln får aldrig finnas i HTML, JavaScript som levereras till webbläsaren eller GitHub.

## Aktiveringskrav
- Serverfunktion deployad i rätt Supabase-projekt.
- Serverhemligheter konfigurerade i Supabase, aldrig i klienten.
- Tillåtna webbplats-origin(er) begränsade till den riktiga produktionsdomänen.
- Inlämningsflödet testat med testdata och avstängt för allmänheten under test.
- Integritetspolicy och villkor kompletterade med verkliga företags-/ansvariguppgifter, ändamål, rättslig grund, mottagare/biträden, lagringstider, rättigheter och kontaktvägar.
- Gallringsrutin, hantering av begäran från registrerade och skydd mot spam dokumenterade.

## Datamodell
Kundförfrågan ska skapa en kundpost och ett uppdrag. Intresseanmälan ska skapa en personpost. Ingen anonym INSERT-policy ska öppnas på tabellerna.

## Aktuell teknisk status – 2026-11-23
- Supabase Edge Function public-intake v9 är driftsatt och hanterar tekniskt tre typer: company, request och person.
- Funktionen har hård spärr INTAKE_ENABLED=false och accepterar därför inga personuppgifter.
- Webbplatsens PUBLIC_INTAKE_ENDPOINT är tom; de två publika formulären är dolda och har avstängda skicka-knappar.
- Företagsregistrering visas endast som inaktiv förhandsvisning; alla fält och knappen är avstängda.
- Tre databasfunktioner skapar företagsansökan, kundförfrågan respektive personintresse. EXECUTE är endast beviljad till service_role; anon och authenticated nekas.
- Databasfunktionerna skapar dataskyddsregistrering och intern adminnotis. Personprofiler skapas som inactive/private/pending tills administratör har granskat dem.
- Edge Function kräver PUBLIC_INTAKE_LEGAL_BASIS och PUBLIC_PRIVACY_NOTICE_VERSION när intaget senare ska öppnas. Dessa värden är inte konfigurerade.

Publika intag ska hållas avstängda tills samtliga krav ovan är verifierade. Den nuvarande webbplatsen är en informations-/adminprototyp och ska inte beskrivas som GDPR-färdig eller produktionsklar.
\n\n## Testresultat\n- [x] De tre databasfunktionerna testades med syntetiska testuppgifter i en transaktion som rullades tillbaka. Testet skapade förväntade poster och tre interna adminnotiser; inga testposter behölls.\n- [x] Behörighetskontroll visar EXECUTE=false för anon och authenticated och EXECUTE=true för service_role på samtliga tre intagsfunktioner.\n- [x] Edge Function v9 verifierades aktiv med INTAKE_ENABLED=false.\n- [ ] End-to-end-test via webbläsare och verkliga testkonton återstår innan öppning.\n