# Issue Tracker

ระบบติดตาม Bug / Issue / Change Request รายโปรเจกต์ พร้อมหน้า Dashboard สรุปและกราฟ

ทั้งระบบอยู่ในไฟล์เดียว: [`index.html`](index.html) — ไม่มี build step ไม่มี dependency ที่ต้องติดตั้ง

**เว็บ:** https://thanaphatritchana-cyber.github.io/issuetracker/

## หน้าจอ

| เมนู | ทำอะไร |
|---|---|
| **Dashboard** | KPI 4 ช่อง (Total / Bug / Issue / CR), กราฟ Issue Trend รายปี, กราฟสัดส่วนประเภท, การ์ดสรุปราย Project, ตาราง Recent Issues |
| **All Issues** | ตารางเต็ม กรองตามปี / Project / ประเภท / สถานะ / Priority และค้นหาข้อความ |
| **Project Plan** | Gantt สำหรับ PM วางแผนโครงการ มีแท่งเวลา %คืบหน้า Milestone เส้นวันนี้ และสรุปสำหรับผู้บริหาร |
| **Create Issue** | ฟอร์มบันทึก Issue (เปิดจากเมนูหรือปุ่ม + เพิ่ม Issue) |
| **Projects** | จัดการ Project พร้อมยอด Bug / Issue / CR และจำนวนที่ยังไม่ปิด |
| **Users** | รายชื่อที่ใช้เลือกเป็น Assignee |
| **Settings** | ดูโหมดจัดเก็บข้อมูล, ส่งออก/นำเข้า JSON, โหลดข้อมูลตัวอย่าง, ล้างข้อมูล |

## โครงข้อมูล

Issue หนึ่งรายการมีประเภทเดียวใน 3 ประเภท — **Bug**, **Issue**, **CR** — และถือฟิลด์:

```
code       รหัสอัตโนมัติ เช่น BUG-2026-00012 (BUG / ISS / CR + ปี + running)
type       Bug | Issue | CR
projectId  ผูกกับ Project
title      ชื่อ Issue
priority   Critical | High | Medium | Low
status     Open | In Progress | Resolved | Closed
assigneeId ผูกกับ Users
env        DEV | UAT | PROD
due        กำหนดเสร็จ (เลยกำหนดแล้วยังไม่ Resolved/Closed จะขึ้นสีแดง)
created    วันที่สร้าง (ใช้เป็นแกนของกราฟ Issue Trend)
```

## Project Plan (Gantt)

เมนูสำหรับ PM วางแผนโครงการเพื่อนำเสนอผู้บริหาร เก็บข้อมูลแยกจาก Issue โดยตั้งใจ —
แผนงานคือ**เฟส**ที่มีวันเริ่ม/วันจบ/%คืบหน้า ส่วน Issue มีแค่กำหนดเสร็จ จึงวาดเป็นแท่งเวลาไม่ได้

งานหนึ่งรายการในแผนมีฟิลด์:

```
projectId   ผูกกับ Project
name        ชื่องาน เช่น วิเคราะห์ความต้องการ / UAT
milestone   true = หมุดสำคัญ แสดงเป็นเพชร ใช้วันเดียว
start / end วันเริ่ม-วันจบ (milestone ตั้ง end = start ให้อัตโนมัติ)
progress    0-100
assigneeId  ผูกกับ Users
```

- เลือก **ทุก Project** = หนึ่งแถวต่อหนึ่งโครงการ ย่อจากงานทั้งหมด คลิกเพื่อเจาะดูรายโครงการ
- สีแท่ง: น้ำเงิน = ตามแผน, แดง = เลยวันจบแต่ยังไม่ 100%, เขียว = เสร็จแล้ว
- ความคืบหน้ารวมถ่วงน้ำหนักด้วยจำนวนวันของแต่ละงาน ไม่นับ milestone ที่ไม่กินเวลา
- รายการที่วันที่ไม่ครบหรือวันจบมาก่อนวันเริ่มจะถูกซ่อนพร้อมแจ้งจำนวน ไม่ทำให้กราฟพัง

## การติดตั้ง Supabase (ให้ทีมเห็นข้อมูลชุดเดียวกัน)

ถ้ายังไม่ตั้งค่า ระบบจะเก็บข้อมูลใน `localStorage` ของเบราว์เซอร์แต่ละเครื่อง ใช้งานได้แต่ไม่แชร์กัน
ทำตาม 4 ขั้นนี้เพื่อเปิดโหมดแชร์:

1. สร้าง project ที่ [supabase.com](https://supabase.com) (แพลนฟรีพอ)
2. เปิด **SQL Editor → New query** วางทั้งไฟล์ [`supabase-setup.sql`](supabase-setup.sql) แล้วกด Run
   สคริปต์จะสร้างตาราง เปิด Row Level Security และเปิด realtime ให้
3. **Authentication → Users → Add user** สร้างบัญชีให้ทีมทีละคน
   (ตั้งใจไม่เปิดให้สมัครเอง เพราะเว็บเปิดสาธารณะ)
4. **Project Settings → API** คัดลอก Project URL กับ anon public key
   มาใส่ที่บรรทัดบนสุดของ `index.html`

```js
const SUPA_URL='https://xxxxxxxx.supabase.co';
const SUPA_KEY='eyJhbGciOi...';
```

### ทำไม anon key อยู่ในโค้ดแล้วยังปลอดภัย

`anon key` ออกแบบมาให้เปิดเผยได้ ความปลอดภัยทั้งหมดอยู่ที่ **Row Level Security**
`supabase-setup.sql` ตั้ง policy ให้เฉพาะ role `authenticated` เท่านั้นที่อ่านและเขียนได้
และไม่มี policy ให้ role `anon` เลย คนที่ยังไม่ login จึงอ่านไม่ได้สักแถว

> **อย่าเอา `service_role` key มาใส่เด็ดขาด** — key ตัวนั้นข้าม RLS ทั้งหมด
> ใช้ `anon public` เท่านั้น

## โหมดจัดเก็บข้อมูล

ตอนเปิดหน้า ระบบเลือกโหมดให้เองตามลำดับ:

| ลำดับ | เงื่อนไข | ผล |
|---|---|---|
| 1 | เปิดเป็น Claude artifact | ใช้ฐานข้อมูลของ artifact ไม่ต้อง login แยก |
| 2 | ตั้งค่า `SUPA_URL` / `SUPA_KEY` ไว้ | ใช้ Supabase ต้อง login ก่อน |
| 3 | นอกนั้น | `localStorage` ของเครื่องนั้น |

จุดสถานะมุมล่างซ้ายของเมนูบอกว่ากำลังใช้โหมดไหน ย้ายข้อมูลระหว่างโหมดได้ที่
**Settings → ส่งออก / นำเข้า JSON**

## โครงสร้างภายใน

| ส่วน | ที่อยู่ในไฟล์ | หมายเหตุ |
|---|---|---|
| โทเคนสี (ธีมน้ำเงิน-ขาว) | `:root` ในบล็อก `<style>` | แก้สีทั้งระบบได้จากจุดเดียว มีชุด dark mode แยก |
| routing | `route()` / `render()` / `ROUTES` | SPA ด้วย hash routing (`#/dashboard`, `#/issues`, ...) |
| ตัวกรอง | `UI` / `filtered()` / `filterBar()` | ตัวกรองชุดเดียวใช้ร่วมกันทั้ง Dashboard และ All Issues |
| กราฟ | `chartSlot()` / `mountCharts()` | Chart.js จาก CDN สีอ่านจาก CSS variable ตอน mount จึงตามธีมสว่าง/มืดเอง |
| การเก็บข้อมูล | `put()` / `del()` / `sbLoad()` | สลับระหว่าง 3 โหมดข้างบนให้เอง |
| Gantt | `vPlan()` / `planRange()` / `barHTML()` | คำนวณตำแหน่งเป็น % ของช่วงเวลาทั้งหมด ไม่ต้องใช้ไลบรารีเสริม |
| login | `#authScreen` / `setSignedIn()` | แสดงทับทั้งหน้าจนกว่าจะ login สำเร็จ (เฉพาะโหมด Supabase) |

## ข้อควรรู้

- ต้องต่ออินเทอร์เน็ตเพื่อโหลดฟอนต์ Prompt, Chart.js และ supabase-js จาก CDN
  ถ้าออฟไลน์ ระบบยังใช้งานได้ในโหมด localStorage เพียงแต่ฟอนต์เปลี่ยนและกราฟไม่ขึ้น
- กราฟ Issue Trend **ไม่สนตัวกรองปี** โดยตั้งใจ เพราะจุดประสงค์คือเทียบข้ามปี ตัวกรองอื่นยังมีผล
- ทุกคนที่ login ได้จะแก้และลบข้อมูลได้เท่ากันหมด ไม่มีสิทธิ์รายคนและไม่มีประวัติว่าใครแก้
  ถ้าต้องการแยกสิทธิ์ ต้องเพิ่ม policy ใน Supabase
- GitHub Pages เปิดให้คนทั้งอินเทอร์เน็ตเข้าถึงหน้าเว็บได้เสมอ สิ่งที่กันข้อมูลคือหน้า login กับ RLS
  ไม่ใช่ความลับของ URL
