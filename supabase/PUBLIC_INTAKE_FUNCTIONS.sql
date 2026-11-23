-- NÄTVERKET public intake database functions
-- Snapshot of the live definitions after migration secure_public_intake_all_flows.
-- All three functions are SECURITY DEFINER with an empty search_path and EXECUTE is service_role-only.

CREATE OR REPLACE FUNCTION public.submit_company_application(p_payload jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_company text := btrim(coalesce(p_payload->>'company_name',''));
  v_org text := nullif(btrim(coalesce(p_payload->>'organization_number','')),'');
  v_industry text := nullif(btrim(coalesce(p_payload->>'industry','')),'');
  v_website text := nullif(btrim(coalesce(p_payload->>'company_website','')),'');
  v_contact text := nullif(btrim(coalesce(p_payload->>'contact_name','')),'');
  v_email text := lower(btrim(coalesce(p_payload->>'email','')));
  v_phone text := nullif(btrim(coalesce(p_payload->>'phone','')),'');
  v_city text := nullif(btrim(coalesce(p_payload->>'city','')),'');
  v_services text := nullif(btrim(coalesce(p_payload->>'services','')),'');
  v_interest text := btrim(coalesce(p_payload->>'interest_type',''));
  v_instagram text := nullif(btrim(coalesce(p_payload->>'instagram','')),'');
  v_notice text := btrim(coalesce(p_payload->>'privacy_notice_version',''));
  v_legal_basis text := btrim(coalesce(p_payload->>'legal_basis',''));
begin
  if length(v_company) < 2 or length(v_company) > 180
     or length(v_email) > 254
     or v_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$'
     or v_interest not in ('buy','sell','both')
     or v_notice = '' or length(v_notice) > 120
     or v_legal_basis not in ('consent','contract','legal_obligation','legitimate_interests','vital_interests','public_task')
     or (v_org is not null and (length(v_org) < 6 or length(v_org) > 24))
     or (v_industry is not null and (length(v_industry) < 2 or length(v_industry) > 120))
     or (v_website is not null and (length(v_website) > 300 or v_website !~ '^https?://[^[:space:]]+$'))
     or (v_contact is not null and (length(v_contact) < 2 or length(v_contact) > 160))
     or (v_phone is not null and length(v_phone) > 40)
     or (v_city is not null and (length(v_city) < 2 or length(v_city) > 100))
     or (v_services is not null and (length(v_services) < 2 or length(v_services) > 2000))
     or (v_instagram is not null and length(v_instagram) > 80)
     or (v_instagram is not null and v_instagram !~ '^@?[A-Za-z0-9._]{1,30}$'
         and v_instagram !~* '^https?://(www[.])?instagram[.]com/[A-Za-z0-9._]{1,30}/?$') then
    raise exception 'Ogiltiga ansökningsuppgifter';
  end if;

  insert into public.company_applications(
    company_name, organization_number, industry, website, contact_name, email,
    phone, city, services, interest_type, instagram_handle, privacy_notice_version, status
  )
  values (
    v_company, v_org, v_industry, v_website, v_contact, v_email,
    v_phone, v_city, v_services, v_interest, v_instagram, v_notice, 'pending'
  )
  returning id into v_id;

  insert into public.privacy_records(
    subject_type, subject_id, purpose, legal_basis, notice_version,
    consent_given, source, notes
  )
  values (
    'company', v_id,
    'Hantera företagets intresseanmälan och kontakta angiven företagskontakt. Frivilligt Instagram-konto används för att hitta företagets offentliga företagsprofil.',
    v_legal_basis, v_notice, null, 'public_website', 'Företagsintresse: ' || v_interest
  );

  insert into public.admin_notifications(recipient_id, notification_type, title, message, entity_type, entity_id)
  select p.id, 'company_application', 'Ny företagsintresseanmälan',
         'Ett företag har skickat in en intresseanmälan.', 'company_application', v_id
  from public.profiles p
  where p.role = 'admin';

  return v_id;
end;
$function$;
CREATE OR REPLACE FUNCTION public.submit_person_application(p_payload jsonb, p_legal_basis text, p_notice_version text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_person_id uuid;
  v_first text := btrim(coalesce(p_payload->>'first_name',''));
  v_last text := nullif(btrim(coalesce(p_payload->>'last_name','')),'');
  v_email text := lower(btrim(coalesce(p_payload->>'email','')));
  v_phone text := nullif(btrim(coalesce(p_payload->>'phone','')),'');
  v_city text := nullif(btrim(coalesce(p_payload->>'city','')),'');
  v_category text := nullif(btrim(coalesce(p_payload->>'interest_category','')),'');
  v_work_type text := nullif(btrim(coalesce(p_payload->>'work_type','')),'');
  v_availability text := nullif(btrim(coalesce(p_payload->>'availability','')),'');
  v_experience text := nullif(btrim(coalesce(p_payload->>'experience','')),'');
begin
  if length(v_first) < 2 or length(v_first) > 80
     or (v_last is not null and length(v_last) > 100)
     or v_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$'
     or length(v_email) > 254
     or (v_phone is not null and length(v_phone) > 40)
     or (v_city is not null and length(v_city) > 100)
     or (v_category is not null and length(v_category) > 120)
     or (v_work_type is not null and v_work_type not in ('Extrajobb vid behov','Enstaka uppdrag','Återkommande uppdrag','Deltidsanställning','Heltidsanställning','Konsultuppdrag','Öppen för flera alternativ'))
     or (v_availability is not null and v_availability not in ('Omgående','Inom två veckor','Inom en månad','Flexibelt / enligt överenskommelse','Helger och kvällar','Vardagar'))
     or (v_experience is not null and length(v_experience) > 2500)
     or p_notice_version is null or btrim(p_notice_version) = ''
     or p_legal_basis not in ('consent','contract','legal_obligation','legitimate_interests','vital_interests','public_task') then
    raise exception 'Ogiltiga intresseuppgifter';
  end if;

  insert into public.people(
    first_name, last_name, email, phone, city, experience_description,
    availability, employment_interest, freelance_interest, relationship_notes, status
  )
  values (
    v_first, v_last, v_email, v_phone, v_city, v_experience,
    v_availability,
    coalesce(v_work_type in ('Deltidsanställning','Heltidsanställning','Öppen för flera alternativ'), false),
    coalesce(v_work_type in ('Extrajobb vid behov','Enstaka uppdrag','Återkommande uppdrag','Konsultuppdrag','Öppen för flera alternativ'), false),
    case when v_work_type is null then null else 'Önskad uppdragsform: ' || v_work_type end,
    'inactive'
  )
  returning id into v_person_id;

  insert into public.service_profiles(
    person_id, service_categories, service_areas, profile_visibility, verification_status
  )
  values (
    v_person_id,
    case when v_category is null then '{}'::text[] else array[v_category] end,
    case when v_city is null then '{}'::text[] else array[v_city] end,
    'private', 'pending'
  );

  insert into public.privacy_records(
    subject_type, subject_id, purpose, legal_basis, notice_version,
    consent_given, source, notes
  )
  values (
    'person', v_person_id,
    'Hantera personens intresseanmälan, bedöma kompetens och kontakta personen om relevanta uppdrag.',
    p_legal_basis, btrim(p_notice_version), null, 'public_website', 'Publik kompetensanmälan'
  );

  insert into public.admin_notifications(recipient_id, notification_type, title, message, entity_type, entity_id)
  select p.id, 'person_application', 'Ny intresseanmälan',
         'En person har anmält intresse för att erbjuda sin kompetens.', 'person', v_person_id
  from public.profiles p
  where p.role = 'admin';

  return v_person_id;
end;
$function$;
CREATE OR REPLACE FUNCTION public.submit_public_request(p_payload jsonb, p_legal_basis text, p_notice_version text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_customer_id uuid;
  v_request_id uuid;
  v_name text := btrim(coalesce(p_payload->>'name',''));
  v_email text := lower(btrim(coalesce(p_payload->>'email','')));
  v_phone text := nullif(btrim(coalesce(p_payload->>'phone','')),'');
  v_city text := nullif(btrim(coalesce(p_payload->>'city','')),'');
  v_customer_type text := btrim(coalesce(p_payload->>'customer_type',''));
  v_category text := btrim(coalesce(p_payload->>'service_category',''));
  v_category_id uuid;
  v_title text := btrim(coalesce(p_payload->>'title',''));
  v_description text := nullif(btrim(coalesce(p_payload->>'description','')),'');
begin
  if length(v_name) < 2 or length(v_name) > 160
     or v_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$'
     or length(v_email) > 254
     or v_customer_type not in ('private','business')
     or length(v_category) < 2 or length(v_category) > 120
     or length(v_title) < 2 or length(v_title) > 160
     or (v_description is not null and length(v_description) > 3000)
     or (v_phone is not null and length(v_phone) > 40)
     or (v_city is not null and (length(v_city) < 2 or length(v_city) > 100))
     or p_notice_version is null or btrim(p_notice_version) = ''
     or p_legal_basis not in ('consent','contract','legal_obligation','legitimate_interests','vital_interests','public_task') then
    raise exception 'Ogiltiga förfrågningsuppgifter';
  end if;

  if v_category = 'Annat / vet inte ännu' then
    v_category := 'Övriga tjänster';
  end if;

  select c.id into v_category_id
  from public.categories c
  where c.name = v_category and c.active = true
  limit 1;

  if v_category_id is null then
    raise exception 'Tjänstekategorin kunde inte hittas';
  end if;

  insert into public.customers(name, email, phone, customer_type, city, status)
  values (v_name, v_email, v_phone, v_customer_type, v_city, 'active')
  returning id into v_customer_id;

  insert into public.requests(customer_id, category_id, title, description, location, city, status)
  values (v_customer_id, v_category_id, v_title, v_description, v_city, v_city, 'new')
  returning id into v_request_id;

  insert into public.privacy_records(
    subject_type, subject_id, purpose, legal_basis, notice_version,
    consent_given, source, notes
  )
  values (
    'customer', v_customer_id,
    'Hantera kundens tjänsteförfrågan och kontakta kunden om matchning och nästa steg.',
    p_legal_basis, btrim(p_notice_version), null, 'public_website', 'Publik kundförfrågan'
  );

  insert into public.admin_notifications(recipient_id, notification_type, title, message, entity_type, entity_id)
  select p.id, 'new_request', 'Ny kundförfrågan',
         'En ny förfrågan har kommit in inom ' || v_category || '.', 'request', v_request_id
  from public.profiles p
  where p.role = 'admin';

  return v_request_id;
end;
$function$;

revoke all on function public.submit_company_application(jsonb) from public, anon, authenticated;
grant execute on function public.submit_company_application(jsonb) to service_role;
revoke all on function public.submit_public_request(jsonb, text, text) from public, anon, authenticated;
grant execute on function public.submit_public_request(jsonb, text, text) to service_role;
revoke all on function public.submit_person_application(jsonb, text, text) from public, anon, authenticated;
grant execute on function public.submit_person_application(jsonb, text, text) to service_role;
