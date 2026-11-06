# NÄTVERKET – ny plattformsstruktur

## Målbild
En gemensam plattform med fyra tjänsteområden:
- Hemma – vardagshjälp, mobil/IT, montering, installation, hantverk och hemservice.
- Företag – personal, konsulter, leverantörer, partners och affärskontakter.
- Event – artister, DJs, fotografer, drönarfoto/-film, catering, lokaler, dekoration och eventproduktion.
- Bostad & Fastighet – mäklare, bostadsfoto, drönartjänster, styling, flytt, städ, besiktning och fastighetsservice.

## NÄTVERKET LIVE
Ett gemensamt flöde för akuta, snart behövda och planerade uppdrag: akut DJ, förrådstömning, flyttstädning, konsultbehov och bröllopspaket. Publika poster ska endast visa uppdragsinformation, kategori, ort, tid, budgetintervall och status. Namn, telefon, e-post och andra kontaktuppgifter får aldrig exponeras i det öppna flödet.

## Förtroende och kvalitet
- Leverantörsprofil kopplas till befintlig personpost.
- Personliga rekommendationer visas först efter uttryckligt publiceringsmedgivande och administrativ moderering.
- Endast verifierade och godkända kundomdömen räknas i betyg.
- Visa genomsnittsbetyg tillsammans med antal verifierade omdömen. Nya leverantörer märks som nya.
- Rangordning väger relevans, tillgänglighet, verifierade uppdrag, kvalitet och svarsfrekvens. Betald placering märks separat och påverkar inte kvalitetsbetyget.

## Adminnotiser
Databasen ska skapa en notis till administratörer när en ny förfrågan, LIVE-post, rekommendation eller recension kommer in. Notiser visas i adminpanelen och kan uppdateras i realtid. E-post/push kräver separat notifieringsleverantör, hemligheter och verifierade tester; de är inte aktiva innan dess.

## Säkerhet och GDPR
Nya tabeller ska ha RLS och sakna anonym åtkomst. Publik inlämning och läsning av LIVE-flödet ska gå via begränsade Edge Functions. Personuppgifter separeras från publika annonser. Rekommendationer kräver publiceringsmedgivande; omdömen modereras och verifieras. Före skarp drift måste personuppgiftsansvar, rättslig grund, integritetstext, lagringstider, gallring, rättigheter, incidentrutin, leverantörsavtal och eventuell DPIA fastställas. Teknisk implementation är inte i sig ett GDPR-godkännande.

## Öppna beroenden
1. Kör SQL-migrationen i rätt Supabase-projekt och kontrollera resultatet.
2. Uppdatera/deploya Edge Functions för LIVE-intag och säkert publikt flöde.
3. Konfigurera adminnotiser och välj e-post/push-leverantör om externa aviseringar önskas.
4. Uppdatera adminpanelen och publika gränssnittet.
5. Kör negativa behörighetstester och acceptanstester före aktivering.
