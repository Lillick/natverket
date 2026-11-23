# NÄTVERKET PRO – CRM-arkitektur

## Syfte
NÄTVERKET PRO är en företagsarbetsyta i samma plattform som marknadsplatsen. Första CRM-versionen fokuserar på småföretag och enmansföretag: kontakter, affärsmöjligheter, uppgifter och aktivitetslogg.

## Datamodell
- `tenant_organizations`: kundföretag och abonnemangsmetadata.
- `organization_memberships`: kopplar autentiserade användare till ett företag med rollen owner, admin, member eller viewer.
- `crm_contacts`: företagets kunder, prospekt, partners och leverantörer.
- `crm_leads`: affärsmöjligheter och enkel pipeline.
- `crm_tasks`: uppgifter och uppföljningar.
- `crm_activities`: aktivitetslogg.

## Behörighet
- RLS är aktiverat på samtliga sex CRM-tabeller.
- `anon` saknar tabellåtkomst.
- Inloggade användare ser bara organisationer där de har en aktiv medlemsrad.
- Medlemmar kan arbeta med företagets CRM-poster. Viewer är skrivskyddad.
- Endast plattformsadministratör kan skapa organisationer och medlemskap.
- Referenser mellan kontakter, affärer och uppgifter begränsas till samma organisation med sammansatta foreign keys.
- Aktivitetsloggen är append-only för vanliga företagsanvändare.

## Nuvarande gränser
- Företagsytan har inloggning men ingen öppen registrering.
- Företagskonto och medlemskap måste provisioneras manuellt av plattformsadministratör innan användaren kan logga in.
- Endast ett företagsutrymme per användare stöds i första gränssnittet.
- Inga e-postutskick, betalningar, abonnemang eller externa integrationer är aktiverade.
- Dataisolering är verifierad på policy- och privilegienivå, men ska även testas med två separata företagskonton före extern pilot.

## Planerade nästa steg
1. Lägg till en säker administratörsfunktion för att godkänna företagsintresse och bjuda in företagskontakter.
2. Testa två organisationer med separata konton och verifiera att ingen data läcker mellan dem.
3. Lägg till export, redigering, arkivering och bättre sök/filter.
4. Först efter pilot: besluta om gratisnivå, PRO-abonnemang och eventuella betalningar.
