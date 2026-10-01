-- =====================================================
-- MIGRASI: tambah tipe soal TABEL KEBENARAN (gerbang logika)
-- Jalankan SETELAH migration_isian.sql (butuh kolom question_type dll).
-- Aman dijalankan ulang.
-- =====================================================

alter table questions drop constraint if exists questions_question_type_check;
alter table questions add constraint questions_question_type_check
  check (question_type in ('pilihan_ganda','isian','tabel_kebenaran'));

-- options untuk tipe ini menyimpan: {"variables": ["A","B"]}
-- Kunci jawaban: array 0/1 sepanjang 2^n, urutan hitungan biner standar (A=MSB)
alter table question_keys add column if not exists correct_table jsonb;

-- Jawaban murid: array 0/1 dengan panjang yang sama
alter table answers add column if not exists chosen_table jsonb;

-- save_answer: tambah parameter tabel kebenaran
create or replace function save_answer(
  p_attempt uuid, p_question uuid,
  p_choice int default null, p_text text default null, p_table jsonb default null
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
  insert into answers (attempt_id, question_id, chosen_index, chosen_text, chosen_table)
  values (p_attempt, p_question, p_choice, p_text, p_table)
  on conflict (attempt_id, question_id) do update
    set chosen_index = excluded.chosen_index, chosen_text = excluded.chosen_text, chosen_table = excluded.chosen_table;
end $$;

-- finish_attempt: tambah aturan tabel kebenaran (semua baris harus benar semua)
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
      ) / nullif((select count(*) from questions where quiz_id = a.quiz_id), 0), 1)
      from answers ans join question_keys k using (question_id)
      where ans.attempt_id = a.id), 0)
  where a.id = p_attempt and a.user_id = auth.uid() and a.finished_at is null
  returning score into s;
  return s;
end $$;

-- recalc_score (dipakai setelah koreksi manual isian): ikut hormati tabel kebenaran juga
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
        or (k.correct_table is not null and ans.chosen_table is not null and ans.chosen_table = k.correct_table)
      ) / nullif((select count(*) from questions where quiz_id = a.quiz_id), 0), 1)
      from answers ans join question_keys k using (question_id)
      where ans.attempt_id = a.id), 0)
  where a.id = p_attempt
  returning score into s;
  return s;
end $$;

-- admin_add_question: tambah parameter p_variables (untuk options) dan p_correct_table
create or replace function admin_add_question(
  p_quiz uuid, p_materi int, p_body text, p_type text,
  p_options jsonb default null, p_correct int default null,
  p_accepted jsonb default null, p_correct_table jsonb default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_pos int;
begin
  if not is_admin() then raise exception 'Khusus admin'; end if;
  select coalesce(max(position), 0) + 1 into v_pos from questions where quiz_id = p_quiz;
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (p_quiz, p_materi, p_body, p_type, p_options, v_pos) returning id into v_id;
  insert into question_keys (question_id, correct_index, accepted_answers, correct_table)
  values (v_id, p_correct, p_accepted, p_correct_table);
  return v_id;
end $$;
