-- =====================================================
-- MIGRASI: tambah tipe soal CARI & PERBAIKI BUG
-- Jalankan SETELAH migration_isian.sql dan migration_tabel_kebenaran.sql.
-- Aman dijalankan ulang.
-- =====================================================

alter table questions drop constraint if exists questions_question_type_check;
alter table questions add constraint questions_question_type_check
  check (question_type in ('pilihan_ganda','isian','tabel_kebenaran','cari_bug'));

-- Kunci jawaban untuk cari_bug
alter table question_keys add column if not exists correct_langkah int;
alter table question_keys add column if not exists correct_jenis text
  check (correct_jenis in ('urutan','kondisi','perulangan'));
alter table question_keys add column if not exists perbaikan_keywords jsonb; -- kata kunci yang diterima di penjelasan perbaikan

-- Jawaban murid untuk cari_bug
alter table answers add column if not exists chosen_langkah int;
alter table answers add column if not exists chosen_jenis text;
-- penjelasan perbaikan murid disimpan di kolom chosen_text yang sudah ada (dipakai bareng dgn tipe isian)

-- save_answer: tambah parameter langkah & jenis
create or replace function save_answer(
  p_attempt uuid, p_question uuid,
  p_choice int default null, p_text text default null, p_table jsonb default null,
  p_langkah int default null, p_jenis text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare a attempts; q quizzes;
begin
  select * into a from attempts where id = p_attempt and user_id = auth.uid();
  if a.id is null then raise exception 'Attempt tidak ditemukan'; end if;
  select * into q from quizzes where id = a.quiz_id;
  if a.finished_at is not null
     or now() > a.started_at + make_interval(mins => q.duration_minutes) + interval '10 seconds'
  then raise exception 'Kuis sudah berakhir'; end if;
  if not exists (select 1 from questions where id = p_question and quiz_id = a.quiz_id)
  then raise exception 'Soal tidak valid'; end if;
  insert into answers (attempt_id, question_id, chosen_index, chosen_text, chosen_table, chosen_langkah, chosen_jenis)
  values (p_attempt, p_question, p_choice, p_text, p_table, p_langkah, p_jenis)
  on conflict (attempt_id, question_id) do update
    set chosen_index = excluded.chosen_index, chosen_text = excluded.chosen_text,
        chosen_table = excluded.chosen_table, chosen_langkah = excluded.chosen_langkah,
        chosen_jenis = excluded.chosen_jenis;
end $$;

-- Helper: cek apakah penjelasan perbaikan murid mengandung salah satu kata kunci
create or replace function perbaikan_cocok(chosen text, keywords jsonb) returns boolean
language sql immutable as $$
  select keywords is not null and exists (
    select 1 from jsonb_array_elements_text(keywords) k
    where position(normalize_text(k) in normalize_text(chosen)) > 0
  );
$$;

-- finish_attempt: tambah aturan cari_bug (langkah + jenis + perbaikan harus benar semua)
create or replace function finish_attempt(p_attempt uuid) returns numeric
language plpgsql security definer set search_path = public as $$
declare s numeric;
begin
  update attempts a set finished_at = now(),
    score = coalesce((
      select round(100.0 * count(*) filter (where
        (k.correct_index is not null and k.correct_index = ans.chosen_index)
        or (k.accepted_answers is not null and normalize_text(ans.chosen_text) in
            (select normalize_text(x) from jsonb_array_elements_text(k.accepted_answers) x))
        or (k.correct_table is not null and ans.chosen_table is not null and ans.chosen_table = k.correct_table)
        or (k.correct_langkah is not null and k.correct_jenis is not null
            and ans.chosen_langkah = k.correct_langkah and ans.chosen_jenis = k.correct_jenis
            and (ans.manual_correct is true
                 or (ans.manual_correct is distinct from false and perbaikan_cocok(ans.chosen_text, k.perbaikan_keywords))))
      ) / nullif((select count(*) from questions where quiz_id = a.quiz_id), 0), 1)
      from answers ans join question_keys k using (question_id)
      where ans.attempt_id = a.id), 0)
  where a.id = p_attempt and a.user_id = auth.uid() and a.finished_at is null
  returning score into s;
  return s;
end $$;

-- recalc_score: sama, dipakai setelah admin koreksi manual
create or replace function recalc_score(p_attempt uuid) returns numeric
language plpgsql security definer set search_path = public as $$
declare s numeric;
begin
  if not is_admin() then raise exception 'Khusus admin'; end if;
  update attempts a set score = coalesce((
      select round(100.0 * count(*) filter (where
        (k.correct_index is not null and k.correct_index = ans.chosen_index)
        or (ans.manual_correct is true and q2.question_type = 'isian')
        or (ans.manual_correct is distinct from false and q2.question_type = 'isian' and k.accepted_answers is not null
            and normalize_text(ans.chosen_text) in
              (select normalize_text(x) from jsonb_array_elements_text(k.accepted_answers) x))
        or (k.correct_table is not null and ans.chosen_table is not null and ans.chosen_table = k.correct_table)
        or (k.correct_langkah is not null and k.correct_jenis is not null
            and ans.chosen_langkah = k.correct_langkah and ans.chosen_jenis = k.correct_jenis
            and (ans.manual_correct is true
                 or (ans.manual_correct is distinct from false and perbaikan_cocok(ans.chosen_text, k.perbaikan_keywords))))
      ) / nullif((select count(*) from questions where quiz_id = a.quiz_id), 0), 1)
      from answers ans
      join question_keys k using (question_id)
      join questions q2 on q2.id = ans.question_id
      where ans.attempt_id = a.id), 0)
  where a.id = p_attempt
  returning score into s;
  return s;
end $$;

-- admin_add_question: tambah parameter cari_bug
create or replace function admin_add_question(
  p_quiz uuid, p_materi int, p_body text, p_type text,
  p_options jsonb default null, p_correct int default null,
  p_accepted jsonb default null, p_correct_table jsonb default null,
  p_correct_langkah int default null, p_correct_jenis text default null,
  p_perbaikan_keywords jsonb default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_pos int;
begin
  if not is_admin() then raise exception 'Khusus admin'; end if;
  select coalesce(max(position), 0) + 1 into v_pos from questions where quiz_id = p_quiz;
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (p_quiz, p_materi, p_body, p_type, p_options, v_pos) returning id into v_id;
  insert into question_keys (question_id, correct_index, accepted_answers, correct_table, correct_langkah, correct_jenis, perbaikan_keywords)
  values (v_id, p_correct, p_accepted, p_correct_table, p_correct_langkah, p_correct_jenis, p_perbaikan_keywords);
  return v_id;
end $$;

-- Ganti halaman "Cek Jawaban Isian" jadi mencakup isian DAN cari_bug yang perlu direview manual
drop view if exists isian_untuk_dicek;
create view jawaban_untuk_dicek with (security_invoker = true) as
select ans.attempt_id, ans.question_id, p.full_name as nama, b.name as batch, q.title as kuis,
       qq.question_type as tipe, qq.body as pertanyaan,
       ans.chosen_text as jawaban_teks, ans.chosen_langkah, ans.chosen_jenis,
       k.accepted_answers, k.perbaikan_keywords, k.correct_langkah, k.correct_jenis,
       ans.manual_correct
from answers ans
join questions qq on qq.id = ans.question_id
join question_keys k on k.question_id = qq.id
join attempts a on a.id = ans.attempt_id
join profiles p on p.id = a.user_id
join quizzes q on q.id = a.quiz_id
join batches b on b.id = q.batch_id
where
  (qq.question_type = 'isian' and (k.accepted_answers is null or not (normalize_text(ans.chosen_text) in
       (select normalize_text(x) from jsonb_array_elements_text(k.accepted_answers) x))))
  or
  (qq.question_type = 'cari_bug' and ans.manual_correct is null and not perbaikan_cocok(ans.chosen_text, k.perbaikan_keywords));
