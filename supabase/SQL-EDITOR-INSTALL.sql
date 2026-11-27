-- C&R Premium Supabase starter schema
-- Run in Supabase SQL Editor on a NEW project. Keep the project service-role key server-side only.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','employee')),
  employee_id text unique,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint profile_employee_role_link check ((role = 'admin' and employee_id is null) or role = 'employee')
);

create table if not exists public.employees (
  employee_id text primary key,
  user_id uuid unique references auth.users(id) on delete set null,
  login_email text not null unique,
  full_name text not null,
  position text not null default '',
  department text not null default '',
  phone text not null default '',
  email text not null default '',
  address text not null default '',
  status text not null default 'Active',
  nationality text not null default '',
  qid_number text not null default '',
  qid_issue date,
  qid_expiry date,
  passport_number text not null default '',
  passport_issue date,
  passport_expiry date,
  photo_path text,
  login_blocked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.request_prices (
  request_type text primary key,
  amount_qAR numeric(12,2) not null default 0 check (amount_qAR >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.employee_requests (
  id uuid primary key default gen_random_uuid(),
  employee_id text not null references public.employees(employee_id) on update cascade on delete cascade,
  request_type text not null,
  description text not null default '',
  amount_to_pay numeric(12,2) not null default 0 check (amount_to_pay >= 0),
  status text not null default 'Pending' check (status in ('Under Process','Pending','On Hold','Rejected','Completed')),
  payment_status text not null default 'Not paid' check (payment_status in ('Paid','Not paid')),
  paid_at timestamptz,
  source text not null default 'Employee',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.employee_payments (
  id uuid primary key default gen_random_uuid(),
  employee_id text not null references public.employees(employee_id) on update cascade on delete cascade,
  amount numeric(12,2) not null check (amount >= 0),
  currency text not null check (currency in ('QAR','USD')),
  reason text not null,
  payment_date date not null default current_date,
  method text not null check (method in ('Cash','Bank','Check','Card')),
  reference text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.employee_progress (
  id uuid primary key default gen_random_uuid(),
  employee_id text not null references public.employees(employee_id) on update cascade on delete cascade,
  request_id uuid references public.employee_requests(id) on delete set null,
  title text not null,
  status text not null default 'Pending' check (status in ('Under Process','Pending','On Hold','Rejected','Completed')),
  updated_by uuid references auth.users(id),
  updated_by_role text not null default 'Admin' check (updated_by_role in ('Admin','Employee')),
  completed_at date,
  updated_at timestamptz not null default now()
);

create table if not exists public.employee_documents (
  id uuid primary key default gen_random_uuid(),
  employee_id text not null references public.employees(employee_id) on update cascade on delete cascade,
  document_type text not null,
  file_name text not null,
  storage_path text not null unique,
  mime_type text not null,
  file_size bigint not null default 0,
  uploaded_by uuid references auth.users(id),
  uploaded_at timestamptz not null default now()
);

create table if not exists public.employee_messages (
  id uuid primary key default gen_random_uuid(),
  employee_id text not null references public.employees(employee_id) on update cascade on delete cascade,
  subject text not null,
  body text not null,
  message_type text not null default 'Message',
  broadcast_id uuid,
  sent_by uuid references auth.users(id),
  sent_at timestamptz not null default now()
);

create table if not exists public.finance_entries (
  id uuid primary key default gen_random_uuid(),
  entry_type text not null check (entry_type in ('Budget added','Expense')),
  description text not null,
  amount_qAR numeric(12,2) not null check (amount_qAR > 0),
  entry_date date not null default current_date,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.company_settings (
  id integer primary key default 1 check (id = 1),
  company_name text not null default 'C&R Premium Hospitality and Cleaning Services',
  address text not null default '',
  phone text not null default '',
  location text not null default '',
  updated_at timestamptz not null default now()
);
insert into public.company_settings(id) values (1) on conflict (id) do nothing;
insert into public.request_prices(request_type, amount_qAR) values
  ('Annual leave',0),('Uniform request',100),('Document renewal',250),('Other request',0)
on conflict (request_type) do nothing;

create or replace function public.app_role() returns text
language sql stable security definer set search_path = public
as $$ select role from public.profiles where user_id = auth.uid() and active = true limit 1 $$;
create or replace function public.app_employee_id() returns text
language sql stable security definer set search_path = public
as $$ select employee_id from public.profiles where user_id = auth.uid() and active = true limit 1 $$;
create or replace function public.is_active_admin() returns boolean
language sql stable security definer set search_path = public
as $$ select coalesce(public.app_role() = 'admin', false) $$;

-- Safe employee directory projection: exposes only display name and profession.
create or replace function public.team_directory()
returns table (
  employee_id text,
  full_name text,
  position text
)
language sql stable security definer set search_path = public
as $$
  select e.employee_id, e.full_name, e.position
  from public.employees e
  where auth.uid() is not null and public.app_role() in ('admin','employee')
  order by e.full_name
$$;

-- Safe aggregate used for the employee portal's all-team open-request count.
create or replace function public.team_open_request_count()
returns bigint
language sql stable security definer set search_path = public
as $$
  select count(*) from public.employee_requests
  where auth.uid() is not null and public.app_role() in ('admin','employee')
    and status not in ('Completed','Rejected')
$$;

alter table public.profiles enable row level security;
alter table public.employees enable row level security;
alter table public.request_prices enable row level security;
alter table public.employee_requests enable row level security;
alter table public.employee_payments enable row level security;
alter table public.employee_progress enable row level security;
alter table public.employee_documents enable row level security;
alter table public.employee_messages enable row level security;
alter table public.finance_entries enable row level security;
alter table public.company_settings enable row level security;

-- Profiles are self-readable; Admin can view/manage all profiles.
create policy profiles_read_self_or_admin on public.profiles for select to authenticated
using (user_id = auth.uid() or public.is_active_admin());
create policy profiles_admin_all on public.profiles for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());

-- Employees see only their own full record; team directory uses the restricted RPC above.
create policy employees_read_self_or_admin on public.employees for select to authenticated
using (user_id = auth.uid() or public.is_active_admin());
create policy employees_admin_all on public.employees for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());

create policy prices_read_authenticated on public.request_prices for select to authenticated using (true);
create policy prices_admin_all on public.request_prices for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());

create policy requests_read_own_or_admin on public.employee_requests for select to authenticated
using (employee_id = public.app_employee_id() or public.is_active_admin());
create policy requests_insert_self_or_admin on public.employee_requests for insert to authenticated
with check ((employee_id = public.app_employee_id() and created_by = auth.uid()) or public.is_active_admin());
create policy requests_admin_update_delete on public.employee_requests for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());

create policy payments_read_own_or_admin on public.employee_payments for select to authenticated
using (employee_id = public.app_employee_id() or public.is_active_admin());
create policy payments_admin_all on public.employee_payments for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());

create policy progress_read_own_or_admin on public.employee_progress for select to authenticated
using (employee_id = public.app_employee_id() or public.is_active_admin());
create policy progress_employee_create_own on public.employee_progress for insert to authenticated
with check (employee_id = public.app_employee_id() and updated_by = auth.uid() and updated_by_role = 'Employee');
create policy progress_employee_edit_own on public.employee_progress for update to authenticated
using (employee_id = public.app_employee_id() and updated_by = auth.uid() and updated_by_role = 'Employee')
with check (employee_id = public.app_employee_id() and updated_by = auth.uid() and updated_by_role = 'Employee');
create policy progress_admin_all on public.employee_progress for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());

create policy documents_read_own_or_admin on public.employee_documents for select to authenticated
using (employee_id = public.app_employee_id() or public.is_active_admin());
drop policy if exists documents_insert_own_or_admin on public.employee_documents;
create policy documents_insert_own_or_admin on public.employee_documents for insert to authenticated
with check ((employee_id = public.app_employee_id() and uploaded_by = auth.uid()) or public.is_active_admin());
drop policy if exists documents_update_own_or_admin on public.employee_documents;
create policy documents_update_own_or_admin on public.employee_documents for update to authenticated
using ((employee_id = public.app_employee_id() and uploaded_by = auth.uid()) or public.is_active_admin())
with check ((employee_id = public.app_employee_id() and uploaded_by = auth.uid()) or public.is_active_admin());
create policy documents_delete_own_or_admin on public.employee_documents for delete to authenticated
using (employee_id = public.app_employee_id() or public.is_active_admin());

create policy messages_read_own_or_admin on public.employee_messages for select to authenticated
using (employee_id = public.app_employee_id() or public.is_active_admin());
create policy messages_admin_all on public.employee_messages for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());

create policy finance_admin_all on public.finance_entries for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());
create policy settings_read_authenticated on public.company_settings for select to authenticated using (true);
create policy settings_admin_all on public.company_settings for all to authenticated
using (public.is_active_admin()) with check (public.is_active_admin());

grant execute on function public.team_directory() to authenticated;
grant execute on function public.team_open_request_count() to authenticated;

-- Stable app-generated identifiers let the existing portal retain its human-facing row IDs.
alter table public.employee_requests add column if not exists client_ref text unique;
alter table public.employee_payments add column if not exists client_ref text unique;
alter table public.employee_progress add column if not exists client_ref text unique;
alter table public.employee_documents add column if not exists client_ref text unique;
alter table public.employee_messages add column if not exists client_ref text unique;
alter table public.finance_entries add column if not exists client_ref text unique;

-- Create a PRIVATE Storage bucket for employee documents. The first folder segment
-- must be the employee_id (e.g. CR-1001/qid-copy.pdf).
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('employee-documents','employee-documents',false,3145728,array['application/pdf','image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=false, file_size_limit=3145728,
  allowed_mime_types=array['application/pdf','image/jpeg','image/png','image/webp'];
create policy employee_documents_storage_read on storage.objects for select to authenticated
using (bucket_id='employee-documents' and (public.is_active_admin() or (storage.foldername(name))[1]=public.app_employee_id()));
create policy employee_documents_storage_insert on storage.objects for insert to authenticated
with check (bucket_id='employee-documents' and (public.is_active_admin() or (storage.foldername(name))[1]=public.app_employee_id()));
create policy employee_documents_storage_update on storage.objects for update to authenticated
using (bucket_id='employee-documents' and (public.is_active_admin() or (storage.foldername(name))[1]=public.app_employee_id()))
with check (bucket_id='employee-documents' and (public.is_active_admin() or (storage.foldername(name))[1]=public.app_employee_id()));
create policy employee_documents_storage_delete on storage.objects for delete to authenticated
using (bucket_id='employee-documents' and (public.is_active_admin() or (storage.foldername(name))[1]=public.app_employee_id()));

-- Do not store employee passwords or recovery phrases in these tables.
-- Password authentication belongs to Supabase Auth; the frontend must never use service_role.

-- Tighten the profile-role relationship.
alter table public.profiles drop constraint if exists profile_employee_role_link;
alter table public.profiles add constraint profile_employee_role_link
  check ((role = 'admin' and employee_id is null) or (role = 'employee' and employee_id is not null));

-- Never trust employee-supplied request price or payment state. The database
-- applies the current Admin-set price and forces new employee requests unpaid.
create or replace function public.enforce_employee_request_rules()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if public.app_role() = 'employee' then
    if tg_op = 'INSERT' then
      new.created_by := auth.uid();
      new.status := 'Pending';
      new.payment_status := 'Not paid';
      new.paid_at := null;
      select rp.amount_qAR into new.amount_to_pay
        from public.request_prices rp where rp.request_type = new.request_type;
      if new.amount_to_pay is null then
        raise exception 'Unknown request type';
      end if;
    else
      new.employee_id := old.employee_id;
      new.created_by := old.created_by;
      new.payment_status := old.payment_status;
      new.paid_at := old.paid_at;
      new.amount_to_pay := old.amount_to_pay;
      new.status := old.status;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists employee_request_guard on public.employee_requests;
create trigger employee_request_guard before insert or update on public.employee_requests
for each row execute function public.enforce_employee_request_rules();

-- Grant API table privileges only to signed-in users; RLS above constrains each row.
grant select, insert, update, delete on public.profiles, public.employees,
  public.request_prices, public.employee_requests, public.employee_payments,
  public.employee_progress, public.employee_documents, public.employee_messages,
  public.finance_entries, public.company_settings to authenticated;
revoke all on public.profiles, public.employees, public.request_prices,
  public.employee_requests, public.employee_payments, public.employee_progress,
  public.employee_documents, public.employee_messages, public.finance_entries,
  public.company_settings from anon;

-- Employees may set only their own photo path; all other profile changes remain Admin-only.
create or replace function public.set_own_employee_photo(new_photo_path text) returns void
language plpgsql security definer set search_path = public
as $$
begin
  update public.employees set photo_path = new_photo_path, updated_at = now()
    where user_id = auth.uid() and employee_id = public.app_employee_id();
  if not found then raise exception 'Employee profile not found'; end if;
end;
$$;
grant execute on function public.set_own_employee_photo(text) to authenticated;


-- ============================================================================
-- INITIAL ACCOUNT/EMPLOYEE BOOTSTRAP
-- BEFORE RUNNING: create the Admin and every employee as Auth users in
-- Supabase Dashboard > Authentication > Users. Use verified email addresses.
-- Edit v_admin_email and v_employees below; never add passwords here.
-- ============================================================================
do $bootstrap$
declare
  v_admin_email text := 'REPLACE_WITH_ADMIN_AUTH_EMAIL';
  -- Example employee object keys: employee_id, auth_email, full_name,
  -- position, department, phone, address, nationality, status,
  -- qid_number, qid_issue, qid_expiry, passport_number,
  -- passport_issue, passport_expiry.
  -- Replace [] with the employee template below, repeated once per real employee.
  -- Example (uncomment and replace every sample value):
  -- v_employees jsonb := jsonb_build_array(
  --   jsonb_build_object('employee_id','CR-1001','auth_email','employee@example.com',
  --     'full_name','Employee Name','position','Profession','department','Department',
  --     'phone','+97400000000','address','Doha, Qatar','nationality','Nationality',
  --     'status','Active','qid_number','','qid_issue','','qid_expiry','',
  --     'passport_number','','passport_issue','','passport_expiry','')
  -- );
  v_employees jsonb := '[]'::jsonb;
  v_admin_user_id uuid;
  v_employee_user_id uuid;
  v_item jsonb;
  v_employee_id text;
  v_email text;
  v_full_name text;
begin
  if v_admin_email = 'REPLACE_WITH_ADMIN_AUTH_EMAIL' then
    raise exception 'Edit v_admin_email in this script to the email of the Admin Auth user you created first.';
  end if;
  select id into v_admin_user_id from auth.users where lower(email)=lower(v_admin_email) limit 1;
  if v_admin_user_id is null then
    raise exception 'Admin Auth user not found. Create that Auth user in Supabase Dashboard > Authentication > Users before running this script.';
  end if;
  insert into public.profiles(user_id,role,employee_id,active)
  values(v_admin_user_id,'admin',null,true)
  on conflict(user_id) do update set role='admin',employee_id=null,active=true;

  for v_item in select value from jsonb_array_elements(v_employees)
  loop
    v_employee_id := upper(trim(v_item->>'employee_id'));
    v_email := trim(v_item->>'auth_email');
    v_full_name := trim(v_item->>'full_name');
    if coalesce(v_employee_id,'')='' or coalesce(v_email,'')='' or coalesce(v_full_name,'')='' then
      raise exception 'Each employee needs employee_id, auth_email, and full_name.';
    end if;
    select id into v_employee_user_id from auth.users where lower(email)=lower(v_email) limit 1;
    if v_employee_user_id is null then
      raise exception 'Auth user % not found. Create every employee Auth user in Supabase Dashboard before running this script.',v_email;
    end if;

    insert into public.employees(
      employee_id,user_id,login_email,full_name,position,department,phone,email,address,status,nationality,
      qid_number,qid_issue,qid_expiry,passport_number,passport_issue,passport_expiry
    ) values(
      v_employee_id,v_employee_user_id,v_email,v_full_name,
      coalesce(v_item->>'position',''),coalesce(v_item->>'department',''),coalesce(v_item->>'phone',''),v_email,
      coalesce(v_item->>'address',''),coalesce(v_item->>'status','Active'),coalesce(v_item->>'nationality',''),
      coalesce(v_item->>'qid_number',''),nullif(v_item->>'qid_issue','')::date,nullif(v_item->>'qid_expiry','')::date,
      coalesce(v_item->>'passport_number',''),nullif(v_item->>'passport_issue','')::date,nullif(v_item->>'passport_expiry','')::date
    ) on conflict(employee_id) do update set
      user_id=excluded.user_id,login_email=excluded.login_email,full_name=excluded.full_name,
      position=excluded.position,department=excluded.department,phone=excluded.phone,email=excluded.email,
      address=excluded.address,status=excluded.status,nationality=excluded.nationality,
      qid_number=excluded.qid_number,qid_issue=excluded.qid_issue,qid_expiry=excluded.qid_expiry,
      passport_number=excluded.passport_number,passport_issue=excluded.passport_issue,passport_expiry=excluded.passport_expiry;

    insert into public.profiles(user_id,role,employee_id,active)
    values(v_employee_user_id,'employee',v_employee_id,true)
    on conflict(user_id) do update set role='employee',employee_id=excluded.employee_id,active=true;
  end loop;
end;
$bootstrap$;

-- Verification (should return one Admin profile and one row per configured employee):
select p.role,p.employee_id,u.email,p.active
from public.profiles p join auth.users u on u.id=p.user_id
order by p.role,p.employee_id;
