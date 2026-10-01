-- =====================================================
-- 50 SOAL SIAP PAKAI: Debugging (Misi 7)
-- 20 pilihan ganda, 15 isian singkat, 15 cari & perbaiki bug
--
-- CARA PAKAI:
-- 1. Buat kuis dulu di halaman Admin (tab Kuis & Soal), catat judulnya.
-- 2. Ganti nilai di baris 'set_config' di bawah ini dengan JUDUL KUIS persis sama.
-- 3. Jalankan seluruh file ini di Supabase SQL Editor.
-- =====================================================

-- GANTI nilai di bawah ini dengan judul kuis yang sudah kamu buat di Admin:
select set_config('app.quiz_title', 'Kuis Debugging Misi 7', false);

do $$
declare v_quiz uuid;
begin
  select id into v_quiz from quizzes where title = current_setting('app.quiz_title') order by created_at desc limit 1;
  if v_quiz is null then
    raise exception 'Kuis dengan judul "%" tidak ditemukan. Buat dulu di Admin, lalu sesuaikan app.quiz_title di atas.', current_setting('app.quiz_title');
  end if;
  perform set_config('app.quiz_id', v_quiz::text, false);
end $$;

-- ================= PILIHAN GANDA (20) =================
with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Apa yang dimaksud dengan bug?', 'pilihan_ganda', '["Serangga yang masuk ke komputer", "Kesalahan kecil yang bikin hasil meleset dari harapan", "Hasil yang sudah benar", "Nama sebuah permainan"]'::jsonb, 1)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Debugging adalah proses...', 'pilihan_ganda', '["membuat langkah-langkah baru", "menghapus semua langkah", "mencari dan membenerin bug", "menebak hasil tanpa mencoba"]'::jsonb, 2)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 2 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Pernyataan berikut yang BENAR tentang bug adalah...', 'pilihan_ganda', '["Bug tandanya kita gagal total", "Programmer hebat pun sering menemukan bug", "Bug tidak mungkin diperbaiki", "Bug hanya terjadi pada pemula"]'::jsonb, 3)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Tabel jejak dipakai untuk...', 'pilihan_ganda', '["Mencatat nilai di tiap langkah biar ketahuan mulai meleset", "Menghapus bug secara otomatis", "Mengganti semua kode program", "Menghitung skor akhir kuis"]'::jsonb, 4)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, '"Loop muter terus tanpa henti" adalah contoh bug jenis...', 'pilihan_ganda', '["Bug Urutan", "Bug Kondisi", "Bug Perulangan", "Bukan bug"]'::jsonb, 5)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 2 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, '"Sepatu dipakai sebelum kaos kaki" adalah contoh bug jenis...', 'pilihan_ganda', '["Bug Urutan", "Bug Kondisi", "Bug Perulangan", "Bukan bug"]'::jsonb, 6)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, '"Kalau hujan, tidak bawa payung" adalah contoh bug jenis...', 'pilihan_ganda', '["Bug Urutan", "Bug Kondisi", "Bug Perulangan", "Bukan bug"]'::jsonb, 7)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Aturan robot: "Jika lampu MERAH -> jalan. Jika HIJAU -> berhenti." Ini bug jenis apa?', 'pilihan_ganda', '["Bug Urutan", "Bug Kondisi", "Bug Perulangan", "Tidak ada bug"]'::jsonb, 8)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Apa langkah PERTAMA yang dilakukan detektif bug?', 'pilihan_ganda', '["Langsung memperbaiki kodenya", "Menentukan hasil yang seharusnya benar", "Menghapus semua langkah", "Menebak jawabannya"]'::jsonb, 9)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 1 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Pada tabel jejak, dua kolom yang biasanya dicatat adalah...', 'pilihan_ganda', '["Langkah dan Nilai", "Nama dan Umur", "Warna dan Bentuk", "Tanggal dan Waktu"]'::jsonb, 10)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Loop yang tidak pernah terpenuhi syarat berhentinya disebut...', 'pilihan_ganda', '["Bug kondisi", "Bug urutan", "Bug perulangan (infinite loop)", "Bukan bug"]'::jsonb, 11)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 2 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Sistem ATM yang minta PIN berulang tanpa batas percobaan rawan terkena...', 'pilihan_ganda', '["Bug urutan", "Bug kondisi", "Bug perulangan", "Tidak ada bug"]'::jsonb, 12)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 2 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Toko mengecek diskon dari syarat terkecil dulu dan berhenti begitu cocok. Akibatnya pelanggan dengan belanja besar bisa mendapat...', 'pilihan_ganda', '["Diskon yang lebih kecil dari seharusnya", "Diskon yang lebih besar dari seharusnya", "Diskon yang sama persis", "Tidak dapat diskon sama sekali"]'::jsonb, 13)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Supaya aman naik wahana, aturan "tinggi >=120 cm" dan "umur >=10 tahun" seharusnya memakai operator...', 'pilihan_ganda', '["DAN (keduanya harus terpenuhi)", "ATAU (salah satu saja)", "TIDAK", "Tidak perlu operator"]'::jsonb, 14)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Jika memakai ATAU padahal seharusnya DAN pada aturan wahana, akibatnya...', 'pilihan_ganda', '["Anak yang semestinya tidak boleh naik malah diizinkan", "Semua anak otomatis ditolak", "Programnya error dan berhenti", "Tidak ada pengaruh sama sekali"]'::jsonb, 15)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Program mulai dari 0, tambah 2 tiap putaran, berhenti kalau nilainya SAMA DENGAN 9. Mengapa program ini tidak pernah berhenti?', 'pilihan_ganda', '["Karena nilainya meloncat dari 8 ke 10, tidak pernah tepat 9", "Karena penjumlahannya salah", "Karena mulai dari angka yang salah", "Karena +2 terlalu besar untuk komputer"]'::jsonb, 16)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Nilai 90 pada aturan "Jika nilai >=75 -> Remedial, jika tidak -> Lulus" menghasilkan Remedial, padahal seharusnya Lulus. Ini terjadi karena...', 'pilihan_ganda', '["Jalur Ya dan Tidak tertukar", "Nilainya salah ditulis", "Programnya error", "Tidak ada bug, hasil sudah benar"]'::jsonb, 17)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Fungsi utama dari 4 langkah detektif bug adalah...', 'pilihan_ganda', '["Menemukan dan membenerin bug secara sistematis", "Membuat program baru dari nol", "Menghapus semua kode lama", "Mengganti nama variabel"]'::jsonb, 18)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Bug yang terlihat seperti langkah benar padahal urutannya tertukar disebut bug yang...', 'pilihan_ganda', '["Menyamar", "Mencolok", "Hilang", "Tidak berbahaya"]'::jsonb, 19)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, options, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Kenapa penting menguji ulang program SETELAH memperbaiki satu bug?', 'pilihan_ganda', '["Supaya tahu tidak muncul bug baru akibat perbaikan tadi", "Supaya programnya jadi lebih panjang", "Supaya terlihat lebih rumit", "Tidak penting, bug lain pasti tidak akan muncul"]'::jsonb, 20)
  returning id
)
insert into question_keys (question_id, correct_index) select id, 0 from q;

-- ================= ISIAN SINGKAT (15) =================
with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Proses mencari & membenerin kesalahan pada program disebut ______.', 'isian', 21)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["debugging"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Kesalahan kecil yang bikin hasil program meleset dari harapan disebut ______.', 'isian', 22)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["bug"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Tabel yang mencatat nilai di tiap langkah program disebut tabel ______.', 'isian', 23)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["jejak", "tabel jejak"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Bug yang terjadi karena langkah-langkahnya diletakkan di urutan yang salah disebut bug ______.', 'isian', 24)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["urutan", "bug urutan"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Bug yang terjadi karena syarat Ya/Tidak-nya salah sehingga jalurnya keliru disebut bug ______.', 'isian', 25)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["kondisi", "bug kondisi"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Bug yang terjadi karena perulangan tidak punya syarat berhenti yang tepat disebut bug ______.', 'isian', 26)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["perulangan", "bug perulangan"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Istilah bahasa Inggris untuk "kesalahan kecil pada program" adalah ______.', 'isian', 27)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["bug"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Sistem yang minta PIN tanpa batas percobaan rawan bug jenis ______ karena tidak ada penghitung percobaan.', 'isian', 28)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["perulangan", "bug perulangan"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Supaya diskon terbesar yang dipilih lebih dulu, urutan pengecekan syarat seharusnya dimulai dari nilai yang paling ______.', 'isian', 29)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["besar"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Sistem ATM akan lebih aman kalau dipasangi ______ supaya berhenti otomatis setelah 3 kali PIN salah.', 'isian', 30)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["penghitung", "counter", "penghitung percobaan"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Operator yang mengharuskan DUA syarat sekaligus terpenuhi disebut ______.', 'isian', 31)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["dan", "and", "operator dan"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Loop mulai dari 0, tambah 2 tiap putaran, dan berhenti kalau nilainya sama dengan 9, tidak akan pernah berhenti karena 9 adalah bilangan ______.', 'isian', 32)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["ganjil"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Supaya loop pada soal sebelumnya berhenti dengan benar, syarat berhentinya perlu diubah menjadi nilai ______ 9.', 'isian', 33)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["lebih dari sama dengan", "lebih dari atau sama dengan", ">="]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Tahap terakhir dari 4 langkah detektif bug adalah membenerin, lalu ______ ulang.', 'isian', 34)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["uji", "menguji"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Bug yang paling sulit ditemukan biasanya adalah bug yang ______ karena terlihat benar padahal salah.', 'isian', 35)
  returning id
)
insert into question_keys (question_id, accepted_answers) select id, '["menyamar", "nyamar"]'::jsonb from q;

-- ================= CARI & PERBAIKI BUG (15) =================
with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Langkah mandi Beni:
1. Pakai baju bersih
2. Basahi badan
3. Sabunan
4. Bilas
5. Keringkan badan', 'cari_bug', 36)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'urutan', '["basahi dulu", "basahi badan dulu baru pakai baju", "pindahkan ke akhir", "urutan benar basahi sabun bilas keringkan baju"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Resep kue Rina:
1. Panggang 30 menit
2. Campur tepung, telur, dan gula
3. Tuang adonan ke loyang
4. Dinginkan kuenya
5. Panaskan oven', 'cari_bug', 37)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'urutan', '["panaskan oven dulu", "pindahkan ke langkah pertama", "urutan benar panaskan campur tuang panggang dinginkan", "5,2,3,1,4"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Aturan robot penyeberang jalan:
1. Jika lampu MERAH -> jalan
2. Jika lampu HIJAU -> berhenti', 'cari_bug', 38)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'kondisi', '["tukar aturannya", "merah berhenti", "hijau jalan", "jalur tertukar"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Aturan kelulusan sekolah:
1. Jika nilai > 70 -> Lulus
2. Selain itu -> Remedial', 'cari_bug', 39)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'kondisi', '["pakai >=70", "lebih dari sama dengan", "ubah jadi >=", "batas 70 lulus"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Aturan diskon toko (dicek berurutan, berhenti di kecocokan pertama):
1. Jika belanja >= Rp50.000 -> diskon 10%
2. Jika belanja >= Rp100.000 -> diskon 20%
3. Selain itu -> tanpa diskon', 'cari_bug', 40)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'kondisi', '["cek dari besar dulu", "urutan dibalik", "100000 dulu", "tukar urutan pengecekan"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Resep es teh Dodi:
1. Masukkan es batu ke gelas
2. Seduh teh celup dengan air panas
3. Jika teh sudah manis -> tambah gula, jika belum manis -> lanjut ke langkah 4
4. Aduk lalu sajikan', 'cari_bug', 41)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'urutan', '["es dimasukkan setelah teh diseduh", "pindahkan es ke belakang", "seduh dulu baru es"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Resep es teh Dodi (ada bug kedua di langkah lain):
1. Masukkan es batu ke gelas
2. Seduh teh celup dengan air panas
3. Jika teh sudah manis -> tambah gula, jika belum manis -> lanjut ke langkah 4
4. Aduk lalu sajikan', 'cari_bug', 42)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 3, 'kondisi', '["tukar syaratnya", "kalau belum manis tambah gula", "kalau sudah manis lanjut"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Aturan wahana:
1. Cek tinggi badan >=120 cm ATAU umur >=10 tahun
2. Jika salah satu terpenuhi -> boleh naik', 'cari_bug', 43)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'kondisi', '["ganti atau jadi dan", "harus dan bukan atau", "tinggi dan umur sekaligus"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Hitung mundur roket:
1. Mulai dari 5
2. Ucapkan "Meluncur!"
3. Sebutkan angkanya
4. Kurangi 1
5. Kalau belum 0, kembali ke langkah 2', 'cari_bug', 44)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 2, 'urutan', '["ucapkan meluncur di akhir", "setelah hitung mundur selesai", "pindahkan ke langkah terakhir"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Sistem ATM:
1. Ulangi: minta PIN
2. Jika PIN benar -> buka menu, lalu berhenti
3. Jika PIN salah -> minta PIN lagi', 'cari_bug', 45)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 3, 'perulangan', '["tambahkan penghitung", "hitung percobaan salah", "blokir setelah 3 kali", "counter percobaan"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Membuat mie instan:
1. Didihkan air
2. Masukkan mie dan bumbu
3. Tunggu 3 menit
4. Tuang ke piring
5. Nyalakan kompor', 'cari_bug', 46)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 5, 'urutan', '["nyalakan kompor dulu", "pindahkan ke langkah pertama", "urutan benar nyalakan kompor dulu baru didihkan air"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Aturan penyeberangan untuk pejalan kaki:
1. Jika lampu pejalan HIJAU -> berhenti
2. Jika lampu pejalan MERAH -> menyeberang', 'cari_bug', 47)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'kondisi', '["tukar aturannya", "hijau menyeberang", "merah berhenti"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Loop hitung mundur:
1. Mulai dari 10
2. Kurangi 3 tiap putaran
3. Berhenti kalau nilainya sama dengan 0', 'cari_bug', 48)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 3, 'perulangan', '["tidak pernah pas 0", "ganti jadi kurang dari sama dengan 0", "pakai <=0", "berhenti kalau <=0"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Aturan denda perpustakaan:
1. Jika buku dikembalikan TEPAT WAKTU -> kena denda
2. Jika TERLAMBAT -> gratis', 'cari_bug', 49)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'kondisi', '["tukar aturannya", "tepat waktu gratis", "terlambat kena denda"]'::jsonb from q;

with q as (
  insert into questions (quiz_id, materi, body, question_type, position)
  values (current_setting('app.quiz_id')::uuid, 7, 'Aturan lampu untuk mobil:
1. Jika lampu HIJAU -> berhenti
2. Jika lampu MERAH -> jalan
3. Jika lampu KUNING -> siap-siap', 'cari_bug', 50)
  returning id
)
insert into question_keys (question_id, correct_langkah, correct_jenis, perbaikan_keywords)
select id, 1, 'kondisi', '["tukar aturan hijau dan merah", "hijau jalan", "merah berhenti"]'::jsonb from q;

-- Selesai! Total 50 soal ditambahkan ke kuis.
select count(*) as total_soal_sekarang from questions where quiz_id = current_setting('app.quiz_id')::uuid;