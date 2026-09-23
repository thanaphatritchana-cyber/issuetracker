-- ============================================================
-- Issue Tracker — ตั้งค่า Supabase
-- รันไฟล์นี้ทั้งไฟล์ใน Supabase > SQL Editor > New query > Run
--
-- ไฟล์นี้รันซ้ำได้เสมอ ของเดิมไม่หาย ไม่พัง
-- ถ้าเคยรันไปแล้วก่อนจะมีตาราง tasks ให้รันไฟล์นี้ใหม่อีกรอบได้เลย
-- ============================================================

-- ทุกตารางเก็บ record เป็น JSON ทั้งก้อนในคอลัมน์ data
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

-- tasks = งานในแผนโครงการ (Project Plan / Gantt) แยกจาก issues โดยตั้งใจ
-- เพราะแผนงานคือเฟส มีวันเริ่ม-วันจบ-%คืบหน้า ส่วน issue มีแค่กำหนดเสร็จ
create table if not exists public.tasks (
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

do $$
declare t text;
begin
  foreach t in array array['projects','issues','members','tasks'] loop
    execute format('drop trigger if exists touch_%1$s on public.%1$I', t);
    execute format(
      'create trigger touch_%1$s before update on public.%1$I
       for each row execute function public.touch_updated_at()', t);
  end loop;
end $$;

-- ============================================================
-- Row Level Security
-- สำคัญที่สุด: เว็บเปิดสาธารณะและ publishable key อยู่ในโค้ดที่ใครก็อ่านได้
-- ความปลอดภัยทั้งหมดอยู่ที่ตรงนี้ — อนุญาตเฉพาะผู้ที่ login แล้วเท่านั้น
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array['projects','issues','members','tasks'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "signed in full access" on public.%I', t);
    execute format(
      'create policy "signed in full access" on public.%I
       for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- ไม่มี policy ให้ role anon เลย = ผู้ที่ยังไม่ login อ่านหรือเขียนอะไรไม่ได้สักแถว

-- ============================================================
-- เปิด realtime เพื่อให้ทุกคนเห็นการแก้ไขของกันทันที
-- เช็คก่อนเพิ่ม เพราะการ add table ซ้ำจะ error
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array['projects','issues','members','tasks'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ============================================================
-- หลังรันเสร็จ
-- 1. Authentication > Providers > Email : เปิด Email ไว้
--    และปิด "Confirm email" ถ้าอยากสร้างบัญชีให้ทีมได้เลยโดยไม่ต้องยืนยันอีเมล
-- 2. Authentication > Users > Add user : สร้างบัญชีให้ทีมทีละคน
--    (ตั้งใจไม่เปิดให้สมัครเอง เพราะเว็บเปิดสาธารณะ ใครสมัครได้ก็เข้าถึงข้อมูลได้)
-- 3. Project Settings > API Keys : คัดลอก Project URL และ publishable key
--    ไปใส่ใน index.html ที่ตัวแปร SUPA_URL และ SUPA_KEY
-- ============================================================
