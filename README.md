# Kuis Detektif Logika

React (Vite) + Supabase, deploy ke Vercel.

## 1. Supabase
1. Buat project di supabase.com.
2. Authentication → Providers → Email → matikan "Confirm email".
3. SQL Editor → tempel seluruh isi `supabase/schema.sql` → Run.
4. Settings → API → salin Project URL dan anon public key.

## 2. Jalankan lokal
```
npm install
cp .env.example .env    # isi URL dan key
npm run dev
```

## 3. Jadikan dirimu admin
1. Buka web, klik Daftar, buat akun kamu sendiri.
2. Di Supabase SQL Editor jalankan:
```
update profiles set role = 'admin' where id = (select id from auth.users where email = 'usernamekamu@kuis.local');
```
3. Refresh web -> otomatis masuk halaman Admin.

## 4. Deploy Vercel
Push ke GitHub -> vercel.com -> Import -> isi Environment Variables
VITE_SUPABASE_URL dan VITE_SUPABASE_ANON_KEY -> Deploy.

## Cara pakai
Admin: tab Batch (buat batch, dapat kunci) -> tab Kuis & Soal (buat kuis untuk batch, tambah soal, Aktifkan) -> tab Nilai.
Murid: Daftar -> masukkan kunci enrol -> kerjakan kuis.
