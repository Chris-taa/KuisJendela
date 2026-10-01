-- =====================================================
-- 50 SOAL SIAP PAKAI: Logika & Problem Solving (Computational Thinking)
-- Materi 1 CT Dasar, 2 Flowchart, 3 Pseudocode, 4 Boolean, 5 Pola, 6 Debugging Mindset
-- 20 pilihan ganda, 15 isian singkat, 8 tabel kebenaran, 7 cari & perbaiki bug
--
-- CARA PAKAI:
-- 1. Buat kuis dulu di halaman Admin (tab Kuis & Soal), catat judulnya persis.
-- 2. Ganti nilai di baris set_config di bawah ini dengan JUDUL KUIS tersebut.
-- 3. Jalankan seluruh file ini di Supabase SQL Editor.
-- =====================================================

select set_config('app.quiz_title', 'Kuis Review Logika & Problem Solvings', false);

do $$
declare v_quiz uuid;
begin
  select id into v_quiz from quizzes where title = current_setting('app.quiz_title') order by created_at desc limit 1;
  if v_quiz is null then
    raise exception 'Kuis dengan judul "%" tidak ditemukan. Buat dulu di Admin, lalu sesuaikan app.quiz_title di atas.', current_setting('app.quiz_title');
  end if;
  perform set_config('app.quiz_id', v_quiz::text, false);
end $$;

-- ================= A. PILIHAN GANDA (20) =================
with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 1, '[Mudah] Proses memecah masalah besar menjadi bagian-bagian kecil yang lebih mudah diselesaikan disebut...', 'pilihan_ganda', '["Decomposition", "Pattern Recognition", "Abstraction", "Algorithm"]'::jsonb, 1)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 1, '[Mudah] Kemampuan mengenali kemiripan atau pengulangan dalam suatu masalah disebut...', 'pilihan_ganda', '["Algorithm", "Pattern Recognition", "Decomposition", "Abstraction"]'::jsonb, 2)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 1, '[Sedang] Saat merancang aplikasi kasir, kamu HANYA fokus memikirkan harga, jumlah barang, dan total bayar (tanpa memikirkan warna kemasan barang). Kamu sedang menerapkan pilar...', 'pilihan_ganda', '["Decomposition", "Pattern Recognition", "Abstraction", "Algorithm"]'::jsonb, 3)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 2 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 2, '[Mudah] Simbol oval pada flowchart digunakan untuk menandai...', 'pilihan_ganda', '["Proses", "Mulai/Selesai", "Keputusan", "Input/Output"]'::jsonb, 4)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 2, '[Mudah] Simbol diamond (belah ketupat) pada flowchart digunakan untuk...', 'pilihan_ganda', '["Memulai program", "Menampilkan output", "Mengambil keputusan", "Memasukkan data"]'::jsonb, 5)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 2 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 2, '[Sedang] Simbol jajar genjang pada flowchart biasanya digunakan untuk...', 'pilihan_ganda', '["Proses perhitungan", "Input atau Output data", "Mulai program", "Percabangan"]'::jsonb, 6)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Mudah] Kata kunci yang digunakan untuk menandai AWAL sebuah pseudocode adalah...', 'pilihan_ganda', '["INPUT", "START", "SET", "END"]'::jsonb, 7)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Sedang] Perhatikan pseudocode berikut:
START
INPUT umur
IF umur >= 17 THEN
  PRINT "Boleh buat SIM"
ELSE
  PRINT "Belum boleh"
END
Jika umur = 15, apa yang akan dicetak?', 'pilihan_ganda', '["Boleh buat SIM", "Belum boleh", "Tidak ada yang dicetak", "Program error"]'::jsonb, 8)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Sulit] Perhatikan pseudocode berikut:
START
SET total = 0
SET i = 1
WHILE i <= 3
  SET total = total + i
  SET i = i + 1
PRINT total
END
Berapa nilai total yang akan dicetak?', 'pilihan_ganda', '["3", "6", "9", "1"]'::jsonb, 9)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Sedang] Penulisan pseudocode yang rapi biasanya menggunakan huruf besar (kapital) untuk...', 'pilihan_ganda', '["Nama variabel", "Kata kunci seperti IF, WHILE, PRINT", "Semua kalimat", "Angka saja"]'::jsonb, 10)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Mudah] Hasil dari operasi TRUE AND FALSE adalah...', 'pilihan_ganda', '["TRUE", "FALSE", "Tidak bisa ditentukan", "Error"]'::jsonb, 11)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Mudah] Hasil dari operasi TRUE OR FALSE adalah...', 'pilihan_ganda', '["TRUE", "FALSE", "Tidak bisa ditentukan", "Error"]'::jsonb, 12)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Sedang] Hasil dari NOT TRUE adalah...', 'pilihan_ganda', '["TRUE", "FALSE", "TRUE dan FALSE", "Tidak ada hasil"]'::jsonb, 13)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Sulit] Jika A = TRUE dan B = FALSE, hasil dari (A AND B) OR (NOT B) adalah...', 'pilihan_ganda', '["TRUE", "FALSE", "Tidak valid", "Sama dengan A"]'::jsonb, 14)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 5, '[Mudah] Angka selanjutnya dari pola 2, 4, 6, 8, ... adalah...', 'pilihan_ganda', '["9", "10", "12", "16"]'::jsonb, 15)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 5, '[Sulit] Angka selanjutnya dari pola 3, 6, 12, 24, ... adalah...', 'pilihan_ganda', '["36", "48", "30", "27"]'::jsonb, 16)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 5, '[Sulit] Perhatikan pola huruf berikut: A, C, F, J, O, ... (selisihnya terus membesar: +2, +3, +4, +5, ...). Huruf selanjutnya adalah...', 'pilihan_ganda', '["T", "U", "V", "W"]'::jsonb, 17)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 6, '[Mudah] Kesalahan penulisan kode yang membuat program tidak bisa dijalankan sama sekali (misalnya lupa tanda kurung atau salah ketik kata kunci) disebut...', 'pilihan_ganda', '["Syntax Error", "Logic Error", "Runtime Error", "Tidak ada istilahnya"]'::jsonb, 18)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 6, '[Sedang] Program bisa berjalan tanpa pesan error, tetapi hasilnya tidak sesuai yang diharapkan (misalnya salah rumus). Ini disebut...', 'pilihan_ganda', '["Syntax Error", "Logic Error", "Runtime Error", "Bukan bug"]'::jsonb, 19)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 6, '[Sedang] Kesalahan yang baru muncul SAAT program sedang dijalankan, misalnya program mencoba membagi dengan angka 0, disebut...', 'pilihan_ganda', '["Syntax Error", "Logic Error", "Runtime Error", "Compile Error"]'::jsonb, 20)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 2 from q;

-- ================= B. ISIAN SINGKAT (15) =================
with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 1, '[Mudah] Langkah-langkah yang disusun untuk menyelesaikan suatu masalah disebut ______.', 'isian', 21)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["algoritma", "algorithm"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 2, '[Mudah] Simbol kotak (persegi panjang) pada flowchart digunakan untuk menandai langkah ______.', 'isian', 22)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["proses"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Mudah] Kata kunci pseudocode yang digunakan untuk menampilkan hasil ke layar adalah ______.', 'isian', 23)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["print", "output"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Mudah] Kata kunci pseudocode untuk meminta data dari pengguna adalah ______.', 'isian', 24)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["input"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 1, '[Sedang] Pilar computational thinking yang fokus mengenali kemiripan atau pengulangan dalam masalah disebut ______.', 'isian', 25)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["pattern recognition", "mengenali pola"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 1, '[Sedang] Pilar computational thinking yang membuang detail tidak penting dan fokus ke hal utama disebut ______.', 'isian', 26)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["abstraction", "abstraksi"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 5, '[Mudah] Lanjutkan pola berikut: 5, 10, 15, 20, ______.', 'isian', 27)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["25"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 5, '[Sedang] Lanjutkan pola berikut: 1, 2, 4, 8, 16, ______.', 'isian', 28)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["32"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 5, '[Sulit] Lanjutkan pola huruf berikut: A, B, D, G, K, ______.', 'isian', 29)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["p"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Mudah] Hasil dari TRUE AND TRUE adalah ______.', 'isian', 30)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["true"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Mudah] Hasil dari FALSE OR FALSE adalah ______.', 'isian', 31)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["false"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Mudah] Hasil dari NOT FALSE adalah ______.', 'isian', 32)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["true"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 6, '[Mudah] Kesalahan penulisan kode yang membuat program gagal dijalankan sama sekali disebut ______ error.', 'isian', 33)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["syntax"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 6, '[Sedang] Kesalahan logika dalam program dimana program tetap berjalan tapi hasilnya salah disebut ______ error.', 'isian', 34)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["logic"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 6, '[Sulit] Langkah pertama dalam debugging sistematis adalah ______ masalahnya terlebih dahulu sebelum mencari penyebabnya.', 'isian', 35)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["mengulangi", "ulangi"]'::jsonb from q;

-- ================= C. TABEL KEBENARAN (8) =================
with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Mudah] Lengkapi tabel kebenaran untuk ekspresi A AND B (isi SEMUA baris).', 'tabel_kebenaran', '{"variables": ["A", "B"], "given": [null, null, null, null]}'::jsonb, 36)
  returning id
)
insert into question_keys (question_id, correct_table) select id, '[0, 0, 0, 1]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Mudah] Lengkapi tabel kebenaran untuk ekspresi A OR B (isi SEMUA baris).', 'tabel_kebenaran', '{"variables": ["A", "B"], "given": [null, null, null, null]}'::jsonb, 37)
  returning id
)
insert into question_keys (question_id, correct_table) select id, '[0, 1, 1, 1]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Mudah] Lengkapi tabel kebenaran untuk ekspresi NOT A (isi SEMUA baris).', 'tabel_kebenaran', '{"variables": ["A"], "given": [null, null]}'::jsonb, 38)
  returning id
)
insert into question_keys (question_id, correct_table) select id, '[1, 0]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Sedang] Tabel kebenaran untuk A AND B sudah terisi sebagian sebagai contoh. Lengkapi HANYA baris yang masih kosong.', 'tabel_kebenaran', '{"variables": ["A", "B"], "given": [0, 0, 0, null]}'::jsonb, 39)
  returning id
)
insert into question_keys (question_id, correct_table) select id, '[0, 0, 0, 1]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Sedang] Tabel kebenaran untuk A OR B sudah terisi sebagian sebagai contoh. Lengkapi HANYA baris yang masih kosong.', 'tabel_kebenaran', '{"variables": ["A", "B"], "given": [0, null, 1, 1]}'::jsonb, 40)
  returning id
)
insert into question_keys (question_id, correct_table) select id, '[0, 1, 1, 1]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Sedang] Tabel kebenaran untuk NOT A sudah terisi sebagian sebagai contoh. Lengkapi HANYA baris yang masih kosong.', 'tabel_kebenaran', '{"variables": ["A"], "given": [1, null]}'::jsonb, 41)
  returning id
)
insert into question_keys (question_id, correct_table) select id, '[1, 0]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Sulit] Lengkapi tabel kebenaran untuk ekspresi A AND NOT B (isi SEMUA baris).', 'tabel_kebenaran', '{"variables": ["A", "B"], "given": [null, null, null, null]}'::jsonb, 42)
  returning id
)
insert into question_keys (question_id, correct_table) select id, '[0, 0, 1, 0]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 4, '[Sulit] Tabel kebenaran untuk ekspresi (A OR B) AND (NOT A OR NOT B) sudah terisi sebagian sebagai contoh. Lengkapi HANYA baris yang masih kosong.', 'tabel_kebenaran', '{"variables": ["A", "B"], "given": [0, null, null, 0]}'::jsonb, 43)
  returning id
)
insert into question_keys (question_id, correct_table) select id, '[0, 1, 1, 0]'::jsonb from q;

-- ================= D. CARI & PERBAIKI BUG (7) =================
with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Mudah] START
1. INPUT panjang
2. INPUT lebar
3. SET luas = panjang + lebar
4. PRINT luas
END', 'cari_bug', '{"jenis_options": [{"value": "syntax", "label": "Syntax Error"}, {"value": "logic", "label": "Logic Error"}, {"value": "urutan", "label": "Kesalahan Urutan Langkah"}]}'::jsonb, 44)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 3, 'logic', '["panjang * lebar", "perkalian bukan penjumlahan", "ganti + jadi *", "luas = panjang * lebar"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Mudah] START
1. INPUT nilai
2. IF nilai >= 75
3.   PRINT "Lulus"
4. ELSE
5.   PRINT "Tidak lulus"
END', 'cari_bug', '{"jenis_options": [{"value": "syntax", "label": "Syntax Error"}, {"value": "logic", "label": "Logic Error"}, {"value": "urutan", "label": "Kesalahan Urutan Langkah"}]}'::jsonb, 45)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 2, 'syntax', '["tambahkan then", "kurang then", "if nilai >= 75 then", "lupa then"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Sedang] START
1. PRINT "Hasil: " + total
2. INPUT angka1
3. INPUT angka2
4. SET total = angka1 + angka2
END', 'cari_bug', '{"jenis_options": [{"value": "syntax", "label": "Syntax Error"}, {"value": "logic", "label": "Logic Error"}, {"value": "urutan", "label": "Kesalahan Urutan Langkah"}]}'::jsonb, 46)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'urutan', '["pindahkan print ke akhir", "print total di baris terakhir", "urutan dibalik", "hasil dicetak sebelum dihitung"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Sulit] START
1. SET i = 1
2. SET jumlah = 0
3. WHILE i < 5
4.   SET jumlah = jumlah + i
5.   SET i = i + 1
6. PRINT jumlah
END', 'cari_bug', '{"jenis_options": [{"value": "syntax", "label": "Syntax Error"}, {"value": "logic", "label": "Logic Error"}, {"value": "urutan", "label": "Kesalahan Urutan Langkah"}]}'::jsonb, 47)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 3, 'logic', '["ubah jadi i <= 5", "kurang dari sama dengan", "angka 5 tidak ikut dijumlahkan", "while i <= 5"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Sedang] START
1. INPUT suhu
2. IF suhu > 30 THEN
3.   PRINT Panas
4. ELSE
5.   PRINT "Sejuk"
END', 'cari_bug', '{"jenis_options": [{"value": "syntax", "label": "Syntax Error"}, {"value": "logic", "label": "Logic Error"}, {"value": "urutan", "label": "Kesalahan Urutan Langkah"}]}'::jsonb, 48)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 3, 'syntax', '["kurang tanda kutip", "tambahkan tanda kutip", "print \"panas\"", "panas harus pakai kutip"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Sulit] START
1. INPUT nilai
2. IF nilai >= 90 THEN
3.   PRINT "A"
4. ELSE IF nilai >= 80 THEN
5.   PRINT "A"
END', 'cari_bug', '{"jenis_options": [{"value": "syntax", "label": "Syntax Error"}, {"value": "logic", "label": "Logic Error"}, {"value": "urutan", "label": "Kesalahan Urutan Langkah"}]}'::jsonb, 49)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 5, 'logic', '["ganti jadi b", "harusnya print b", "nilai 80-89 harus dapat b bukan a"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 3, '[Sulit] START
1. SET total = 0
2. REPEAT 3 KALI
3.   PRINT total
4.   INPUT skor
5.   SET total = total + skor
END', 'cari_bug', '{"jenis_options": [{"value": "syntax", "label": "Syntax Error"}, {"value": "logic", "label": "Logic Error"}, {"value": "urutan", "label": "Kesalahan Urutan Langkah"}]}'::jsonb, 50)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 3, 'urutan', '["pindahkan print ke akhir perulangan", "print setelah total dihitung", "urutan print salah", "print total di baris terakhir perulangan"]'::jsonb from q;

-- Selesai! Total 50 soal ditambahkan ke kuis.
select count(*) as total_soal_sekarang from questions where quiz_id = current_setting('app.quiz_id')::uuid;