-- =====================================================
-- SKEMA LENGKAP KUIS BATCH LOGIKA (jalankan sekali di Supabase SQL Editor)
-- =====================================================

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text not null default '',
  class_name text,
  role text not null default 'siswa' check (role in ('siswa','admin'))
);

create table batches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  enroll_key text not null unique,
  is_open boolean not null default true,
  created_at timestamptz default now()
);

create table enrollments (
  batch_id uuid references batches on delete cascade,
  user_id uuid references profiles on delete cascade default auth.uid(),
  joined_at timestamptz default now(),
  primary key (batch_id, user_id)
);

create table quizzes (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references batches on delete cascade,
  title text not null,
  duration_minutes int not null default 30,
  max_tab_switch int default 3,          -- null = tidak ada batas, hanya dicatat
  is_active boolean not null default false,
  created_at timestamptz default now()
);

create table questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes on delete cascade,
  materi int,
  body text not null,
  question_type text not null default 'pilihan_ganda' check (question_type in ('pilihan_ganda','isian','tabel_kebenaran','cari_bug')),
  options jsonb,              -- wajib untuk pilihan_ganda, null untuk isian
  position int not null default 0
);

-- Kunci jawaban dipisah: murid tidak punya akses sama sekali
create table question_keys (
  question_id uuid primary key references questions on delete cascade,
  correct_index int,               -- untuk pilihan_ganda
  accepted_answers jsonb,          -- untuk isian: daftar jawaban yang diterima, mis. ["bug kondisi","kondisi"]
  correct_table jsonb,             -- untuk tabel_kebenaran: array 0/1 sepanjang 2^n, urutan biner standar
  correct_langkah int,             -- untuk cari_bug: nomor langkah yang benar
  correct_jenis text,  -- bebas teks: bisa 'urutan'/'kondisi'/'perulangan' ATAU 'syntax'/'logic'/dll, tergantung kurikulum
  perbaikan_keywords jsonb         -- untuk cari_bug: kata kunci yang diterima di penjelasan perbaikan
);

create table attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes on delete cascade,
  user_id uuid not null references profiles on delete cascade default auth.uid(),
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  score numeric,
  tab_switch_count int not null default 0,
  unique (quiz_id, user_id)
);

create table answers (
  attempt_id uuid references attempts on delete cascade,
  question_id uuid references questions on delete cascade,
  chosen_index int,                -- untuk pilihan_ganda
  chosen_text text,                -- untuk isian & penjelasan perbaikan (cari_bug)
  chosen_table jsonb,              -- untuk tabel_kebenaran: array 0/1 isian murid
  chosen_langkah int,              -- untuk cari_bug: nomor langkah pilihan murid
  chosen_jenis text,               -- untuk cari_bug: jenis bug pilihan murid
  manual_correct boolean,          -- override manual oleh admin (isian / cari_bug)
  primary key (attempt_id, question_id)
);

create table tab_events (
  id bigint generated always as identity primary key,
  attempt_id uuid references attempts on delete cascade,
  event_type text,
  duration_ms int,
  created_at timestamptz default now()
);

-- ---------- Helper ----------
create function is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

create function is_member(p_batch uuid) returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from enrollments where batch_id = p_batch and user_id = auth.uid());
$$;

-- ---------- Profil otomatis saat daftar (role selalu 'siswa') ----------
create function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name, class_name, role)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name', ''),
          new.raw_user_meta_data->>'class_name',
          'siswa');
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function handle_new_user();

-- ---------- RLS ----------
alter table profiles enable row level security;
alter table batches enable row level security;
alter table enrollments enable row level security;
alter table quizzes enable row level security;
alter table questions enable row level security;
alter table question_keys enable row level security;
alter table attempts enable row level security;
alter table answers enable row level security;
alter table tab_events enable row level security;

create policy "profil sendiri/admin" on profiles for select using (id = auth.uid() or is_admin());

create policy "batch anggota/admin" on batches for select using (is_member(id) or is_admin());
create policy "admin kelola batch" on batches for all using (is_admin());

create policy "enrol sendiri/admin" on enrollments for select using (user_id = auth.uid() or is_admin());
create policy "admin kelola enrol" on enrollments for all using (is_admin());

create policy "kuis di batch saya" on quizzes for select using (is_admin() or (is_active and is_member(batch_id)));
create policy "admin kelola kuis" on quizzes for all using (is_admin());

create policy "soal saat kuis berjalan" on questions for select using (
  is_admin() or exists (select 1 from attempts a
    where a.quiz_id = questions.quiz_id and a.user_id = auth.uid() and a.finished_at is null));
create policy "admin kelola soal" on questions for all using (is_admin());

create policy "admin kunci" on question_keys for all using (is_admin());

create policy "attempt sendiri/admin" on attempts for select using (user_id = auth.uid() or is_admin());
create policy "jawaban sendiri/admin" on answers for select using (
  is_admin() or exists (select 1 from attempts a where a.id = attempt_id and a.user_id = auth.uid()));
create policy "admin lihat event" on tab_events for select using (is_admin());

-- ---------- Fungsi (semua logika penting di server) ----------
create function join_batch(p_key text) returns uuid
language plpgsql security definer set search_path = public as $$
declare b batches;
begin
  select * into b from batches where lower(enroll_key) = lower(trim(p_key)) and is_open;
  if not found then raise exception 'Kunci tidak valid'; end if;
  insert into enrollments (batch_id, user_id) values (b.id, auth.uid()) on conflict do nothing;
  return b.id;
end $$;

create function start_attempt(p_quiz uuid) returns json
language plpgsql security definer set search_path = public as $$
declare v_batch uuid; a attempts;
begin
  select batch_id into v_batch from quizzes where id = p_quiz and is_active;
  if v_batch is null or not is_member(v_batch) then
    raise exception 'Tidak punya akses ke kuis ini';
  end if;
  insert into attempts (quiz_id, user_id) values (p_quiz, auth.uid())
  on conflict (quiz_id, user_id) do nothing;
  select * into a from attempts where quiz_id = p_quiz and user_id = auth.uid();
  return json_build_object('attempt_id', a.id, 'started_at', a.started_at,
    'finished_at', a.finished_at, 'score', a.score, 'server_now', now());
end $$;

create function normalize_text(t text) returns text
language sql immutable as $$
  select trim(regexp_replace(lower(coalesce(t,'')), '\s+', ' ', 'g'));
$$;

create function save_answer(
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

create function perbaikan_cocok(chosen text, keywords jsonb) returns boolean
language sql immutable as $$
  select keywords is not null and exists (
    select 1 from jsonb_array_elements_text(keywords) k
    where position(normalize_text(k) in normalize_text(chosen)) > 0
  );
$$;

create function log_tab_event(p_attempt uuid, p_type text, p_ms int) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not exists (select 1 from attempts where id = p_attempt and user_id = auth.uid() and finished_at is null)
  then return 0; end if;
  insert into tab_events (attempt_id, event_type, duration_ms) values (p_attempt, p_type, p_ms);
  if p_type <> 'fullscreen_exit' then
    update attempts set tab_switch_count = tab_switch_count + 1 where id = p_attempt;
  end if;
  select tab_switch_count into n from attempts where id = p_attempt;
  return n;
end $$;

create function finish_attempt(p_attempt uuid) returns numeric
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

-- Admin melihat & mengoreksi jawaban isian / cari_bug yang tidak otomatis cocok
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

create function admin_grade_isian(p_attempt uuid, p_question uuid, p_correct boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Khusus admin'; end if;
  update answers set manual_correct = p_correct
  where attempt_id = p_attempt and question_id = p_question;
end $$;

create function recalc_score(p_attempt uuid) returns numeric
language plpgsql security definer set search_path = public as $$
declare s numeric;
begin
  if not is_admin() then raise exception 'Khusus admin'; end if;
  update attempts a set score = coalesce((
      select round(100.0 * count(*) filter (where
        (k.correct_index is not null and k.correct_index = ans.chosen_index)
        or (ans.manual_correct is true and qq.question_type = 'isian')
        or (ans.manual_correct is distinct from false and qq.question_type = 'isian' and k.accepted_answers is not null
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
      join questions qq on qq.id = ans.question_id
      where ans.attempt_id = a.id), 0)
  where a.id = p_attempt
  returning score into s;
  return s;
end $$;

-- Admin: tambah soal + kunci sekaligus (pilihan_ganda / isian / tabel_kebenaran / cari_bug)
create function admin_add_question(
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

-- Rekap nilai untuk admin
create view hasil_kuis with (security_invoker = true) as
select b.name as batch, p.full_name as nama, p.class_name as kelas,
       q.title as kuis, a.score as nilai, a.tab_switch_count as pindah_tab,
       a.started_at, a.finished_at
from attempts a
join profiles p on p.id = a.user_id
join quizzes q on q.id = a.quiz_id
join batches b on b.id = q.batch_id;
