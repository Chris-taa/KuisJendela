-- =====================================================
-- MIGRASI: jenis bug jadi bebas (tidak dikunci ke urutan/kondisi/perulangan saja)
-- Supaya bisa dipakai untuk kurikulum lain, mis. Syntax Error / Logic Error / Kesalahan Urutan.
-- Jalankan SETELAH migration_cari_bug.sql. Aman dijalankan ulang.
-- =====================================================
do $$
declare r record;
begin
  for r in
    select conname from pg_constraint
    where conrelid = 'question_keys'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%correct_jenis%'
  loop
    execute format('alter table question_keys drop constraint %I', r.conname);
  end loop;
end $$;
