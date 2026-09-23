-- ============================================================
-- Issue Tracker — ตั้งค่า Supabase
-- รันไฟล์นี้ทั้งไฟล์ใน Supabase > SQL Editor > New query > Run
-- ============================================================

-- ตารางทั้ง 3 เก็บ record เป็น JSON ทั้งก้อนในคอลัมน์ data
-- ทำให้เพิ่ม/แก้ฟิลด์ในแอปได้โดยไม่ต้อง migrate ฐานข้อมูล
create table if not exists public.projects (
  id          text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

create table if not exists public.issues (
  id          text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

create table if not exists public.members (
  id          text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- อัปเดต updated_at อัตโนมัติทุกครั้งที่แก้แถว
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists touch_projects on public.projects;
create trigger touch_projects before update on public.projects
  for each row execute function public.touch_updated_at();

drop trigger if exists touch_issues on public.issues;
create trigger touch_issues before update on public.issues
  for each row execute function public.touch_updated_at();

drop trigger if exists touch_members on public.members;
create trigger touch_members before update on public.members
  for each row execute function public.touch_updated_at();

-- ============================================================
-- Row Level Security
-- สำคัญที่สุด: เว็บเปิดสาธารณะและ anon key อยู่ในโค้ดที่ใครก็อ่านได้
-- ความปลอดภัยทั้งหมดอยู่ที่ตรงนี้ — อนุญาตเฉพาะผู้ที่ login แล้วเท่านั้น
-- ============================================================
alter table public.projects enable row level security;
alter table public.issues   enable row level security;
alter table public.members  enable row level security;

drop policy if exists "signed in full access" on public.projects;
create policy "signed in full access" on public.projects
  for all to authenticated using (true) with check (true);

drop policy if exists "signed in full access" on public.issues;
create policy "signed in full access" on public.issues
  for all to authenticated using (true) with check (true);

drop policy if exists "signed in full access" on public.members;
create policy "signed in full access" on public.members
  for all to authenticated using (true) with check (true);

-- ไม่มี policy ให้ role anon เลย = ผู้ที่ยังไม่ login อ่านอะไรไม่ได้สักแถว

-- ============================================================
-- เปิด realtime เพื่อให้ทุกคนเห็นการแก้ไขของกันทันที
-- ============================================================
alter publication supabase_realtime add table public.projects;
alter publication supabase_realtime add table public.issues;
alter publication supabase_realtime add table public.members;

-- ============================================================
-- หลังรันเสร็จ
-- 1. Authentication > Providers > Email : เปิด Email ไว้
--    และปิด "Confirm email" ถ้าอยากสร้างบัญชีให้ทีมได้เลยโดยไม่ต้องยืนยันอีเมล
-- 2. Authentication > Users > Add user : สร้างบัญชีให้ทีมทีละคน
--    (ตั้งใจไม่เปิดให้สมัครเอง เพราะเว็บเปิดสาธารณะ ใครสมัครได้ก็เข้าถึงข้อมูลได้)
-- 3. Project Settings > API : คัดลอก Project URL และ anon public key
--    ไปใส่ใน issue-tracker.html ที่ตัวแปร SUPA_URL และ SUPA_KEY
-- ============================================================
