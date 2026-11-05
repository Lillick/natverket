# NÄTVERKET – första samlade testversionen

Lägg `index.html` i roten av ett GitHub-repository och importera repot i Vercel. Välj Framework Preset **Other**. Ingen build command behövs.

Öppna webbplatsen, ange Supabase Project URL och den publika anon/publishable key och logga in med admin-kontot.

**Viktigt:** använd aldrig `service_role`-nyckeln i webbläsaren. Använd endast testdata tills RLS, behörigheter och dataskydd har granskats. Detta är en tidig MVP, inte en färdig produktionslösning. Matchning kör den befintliga funktionen `generate_request_matches`.
