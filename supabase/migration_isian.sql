-- =====================================================
-- MIGRASI: tambah tipe soal ISIAN (jawaban singkat)
-- Jalankan ini SEKALI di project Supabase yang SUDAH pakai schema.sql lama.
-- Aman dijalankan ulang (pakai "if not exists" / "or replace").
-- =====================================================

-- 1. Tandai tipe tiap soal
alter table questions add column if not exists question_type text not null default 'pilihan_ganda'
  check (question_type in ('pilihan_ganda','isian'));
alter table questions alter column options drop not null;   -- isian tidak butuh pilihan

-- 2. Kunci jawaban isian: daftar jawaban yang diterima (boleh lebih dari satu variasi)
alter table question_keys add column if not exists accepted_answers jsonb;
alter table question_keys alter column correct_index drop not null; -- isian tidak pakai correct_index

-- 3. Jawaban murid untuk isian disimpan sebagai teks
alter table answers add column if not exists chosen_text text;

-- 4. Kolom untuk koreksi manual oleh admin (override hasil auto-check)
alter table answers add column if not exists manual_correct boolean;

-- 5. Helper: rapikan teks sebelum dibandingkan
create or replace function normalize_text(t text) returns text
language sql immutable as $$
  select trim(regexp_replace(lower(coalesce(t,'')), '\s+', ' ', 'g'));
$$;

-- 6. save_answer: sekarang menerima pilihan ganda ATAU teks isian
create or replace function save_answer(p_attempt uuid, p_question uuid, p_choice int default null, p_text text default null) returns void
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
  insert into answers (attempt_id, question_id, chosen_index, chosen_text)
  values (p_attempt, p_question, p_choice, p_text)
  on conflict (attempt_id, question_id) do update
    set chosen_index = excluded.chosen_index, chosen_text = excluded.chosen_text;
end $$;

-- 7. finish_attempt: nilai pilihan ganda (exact) + isian (cocok ke accepted_answers, dinormalisasi)
create or replace function finish_attempt(p_attempt uuid) returns numeric
language plpgsql security definer set search_path = public as $$
declare s numeric;
begin
  update attempts a set finished_at = now(),
    score = coalesce((
      select round(100.0 * count(*) filter (where
        (k.correct_index is not null and k.correct_index = ans.chosen_index)
        or
        (k.accepted_answers is not null and normalize_text(ans.chosen_text) in
          (select normalize_text(x) from jsonb_array_elements_text(k.accepted_answers) x))
      ) / nullif((select count(*) from questions where quiz_id = a.quiz_id), 0), 1)
      from answers ans join question_keys k using (question_id)
      where ans.attempt_id = a.id), 0)
  where a.id = p_attempt and a.user_id = auth.uid() and a.finished_at is null
  returning score into s;
  return s;
end $$;

-- 8. admin_add_question: sekarang bisa tambah soal pilihan ganda ATAU isian
create or replace function admin_add_question(
  p_quiz uuid, p_materi int, p_body text, p_type text,
  p_options jsonb default null, p_correct int default null,
  p_accepted jsonb default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_pos int;
begin
  if not is_admin() then raise exception 'Khusus admin'; end if;
  select coalesce(max(position), 0) + 1 into v_pos from questions where quiz_id = p_quiz;
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (p_quiz, p_materi, p_body, p_type, p_options, v_pos) returning id into v_id;
  insert into question_keys (question_id, correct_index, accepted_answers)
  values (v_id, p_correct, p_accepted);
  return v_id;
end $$;

-- 9. View untuk admin memeriksa & mengoreksi jawaban isian yang tidak otomatis cocok
create or replace view isian_untuk_dicek with (security_invoker = true) as
select ans.attempt_id, p.full_name as nama, b.name as batch, q.title as kuis,
       qq.body as pertanyaan, ans.chosen_text as jawaban_murid,
       k.accepted_answers, ans.manual_correct
from answers ans
join questions qq on qq.id = ans.question_id
join question_keys k on k.question_id = qq.id
join attempts a on a.id = ans.attempt_id
join profiles p on p.id = a.user_id
join quizzes q on q.id = a.quiz_id
join batches b on b.id = q.batch_id
where qq.question_type = 'isian'
  and (k.accepted_answers is null or not (normalize_text(ans.chosen_text) in
       (select normalize_text(x) from jsonb_array_elements_text(k.accepted_answers) x)));

-- 10. Admin: tandai jawaban isian benar/salah secara manual, lalu nilai dihitung ulang
create or replace function admin_grade_isian(p_attempt uuid, p_question uuid, p_correct boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Khusus admin'; end if;
  update answers set manual_correct = p_correct
  where attempt_id = p_attempt and question_id = p_question;
end $$;

-- 11. finish_attempt v2: sekarang juga menghormati koreksi manual admin
create or replace function recalc_score(p_attempt uuid) returns numeric
language plpgsql security definer set search_path = public as $$
declare s numeric;
begin
  if not is_admin() then raise exception 'Khusus admin'; end if;
  update attempts a set score = coalesce((
      select round(100.0 * count(*) filter (where
        (k.correct_index is not null and k.correct_index = ans.chosen_index)
        or (ans.manual_correct is true)
        or (ans.manual_correct is distinct from false and k.accepted_answers is not null
            and normalize_text(ans.chosen_text) in
              (select normalize_text(x) from jsonb_array_elements_text(k.accepted_answers) x))
      ) / nullif((select count(*) from questions where quiz_id = a.quiz_id), 0), 1)
      from answers ans join question_keys k using (question_id)
      where ans.attempt_id = a.id), 0)
  where a.id = p_attempt
  returning score into s;
  return s;
end $$;
