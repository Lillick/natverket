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

## Status
Publika intag ska hållas avstängda tills samtliga krav ovan är verifierade. Den nuvarande webbplatsen är en informations-/adminprototyp och ska inte beskrivas som GDPR-färdig eller produktionsklar.
