import { useEffect, useState } from 'react'
import { supabase } from '../supabase'
import { truthRows, JENIS_BUG } from '../truthTable'

const ALPHA = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
const randKey = () => 'LOGIKA-' + Array.from(crypto.getRandomValues(new Uint8Array(6)), (n) => ALPHA[n % ALPHA.length]).join('')

export default function Admin({ profile }) {
  const [tab, setTab] = useState('nilai')
  return (
    <div className="wrap wide">
      <div className="row between">
        <h1>Admin: {profile.full_name}</h1>
        <button className="ghost" onClick={() => supabase.auth.signOut()}>Keluar</button>
      </div>
      <div className="tabs">
        {[['nilai', 'Nilai'], ['batch', 'Batch'], ['kuis', 'Kuis & Soal'], ['isian', 'Cek Jawaban']].map(([k, l]) => (
          <button key={k} className={tab === k ? 'on' : ''} onClick={() => setTab(k)}>{l}</button>
        ))}
      </div>
      {tab === 'nilai' && <Nilai />}
      {tab === 'batch' && <Batch />}
      {tab === 'kuis' && <Kuis />}
      {tab === 'isian' && <CekIsian />}
    </div>
  )
}

function Nilai() {
  const [rows, setRows] = useState([])
  const [fb, setFb] = useState('')
  const [fk, setFk] = useState('')
  useEffect(() => {
    supabase.from('hasil_kuis').select('*').order('started_at', { ascending: false }).then(({ data }) => setRows(data || []))
  }, [])
  const uniq = (k) => [...new Set(rows.map((r) => r[k]).filter(Boolean))].sort()
  const shown = rows.filter((r) => (!fb || r.batch === fb) && (!fk || r.kelas === fk))

  const exportCsv = () => {
    const head = ['batch', 'nama', 'kelas', 'kuis', 'nilai', 'pindah_tab', 'selesai']
    const esc = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`
    const csv = [head.join(','), ...shown.map((r) => [r.batch, r.nama, r.kelas, r.kuis, r.nilai, r.pindah_tab, r.finished_at].map(esc).join(','))].join('\n')
    const a = document.createElement('a')
    a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }))
    a.download = 'nilai-kuis.csv'
    a.click()
  }

  return (
    <div>
      <div className="row" style={{ marginBottom: '1rem' }}>
        <select style={{ width: 200 }} value={fb} onChange={(e) => setFb(e.target.value)}>
          <option value="">Semua batch</option>{uniq('batch').map((b) => <option key={b}>{b}</option>)}
        </select>
        <select style={{ width: 160 }} value={fk} onChange={(e) => setFk(e.target.value)}>
          <option value="">Semua kelas</option>{uniq('kelas').map((b) => <option key={b}>{b}</option>)}
        </select>
        <button className="ghost" onClick={exportCsv}>Ekspor CSV</button>
      </div>
      <div className="scroll">
        <table>
          <thead><tr><th>Batch</th><th>Nama</th><th>Kelas</th><th>Kuis</th><th>Nilai</th><th>Pindah tab</th><th>Status</th></tr></thead>
          <tbody>
            {shown.map((r, n) => (
              <tr key={n}>
                <td>{r.batch}</td><td>{r.nama}</td><td>{r.kelas}</td><td>{r.kuis}</td>
                <td>{r.finished_at ? r.nilai : '-'}</td>
                <td style={{ color: r.pindah_tab > 0 ? 'var(--warn)' : undefined, fontWeight: r.pindah_tab > 0 ? 700 : 400 }}>{r.pindah_tab}x</td>
                <td>{r.finished_at ? 'Selesai' : 'Belum dikumpulkan'}</td>
              </tr>
            ))}
            {shown.length === 0 && <tr><td colSpan="7" className="muted">Belum ada data.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function Batch() {
  const [list, setList] = useState([])
  const [name, setName] = useState('')
  const load = () => supabase.from('batches').select('*').order('created_at', { ascending: false }).then(({ data }) => setList(data || []))
  useEffect(() => { load() }, [])

  const add = async (e) => {
    e.preventDefault()
    const { error } = await supabase.from('batches').insert({ name, enroll_key: randKey() })
    if (error) return alert(error.message)
    setName(''); load()
  }
  const toggle = async (b) => { await supabase.from('batches').update({ is_open: !b.is_open }).eq('id', b.id); load() }

  return (
    <div>
      <form className="card row" onSubmit={add}>
        <div style={{ flex: 1, minWidth: 200 }}><label>Nama batch baru</label><input value={name} onChange={(e) => setName(e.target.value)} required /></div>
        <button style={{ alignSelf: 'flex-end' }}>Buat batch</button>
      </form>
      {list.map((b) => (
        <div className="card row between" key={b.id}>
          <div><h3>{b.name}</h3>Kunci enrol: <strong style={{ fontFamily: 'monospace', fontSize: '1.1rem' }}>{b.enroll_key}</strong></div>
          <div className="row">
            <span className="badge">{b.is_open ? 'Pendaftaran dibuka' : 'Ditutup'}</span>
            <button className="ghost" onClick={() => toggle(b)}>{b.is_open ? 'Tutup' : 'Buka'}</button>
          </div>
        </div>
      ))}
    </div>
  )
}

function Kuis() {
  const [batches, setBatches] = useState([])
  const [quizzes, setQuizzes] = useState([])
  const [sel, setSel] = useState('')
  const [qs, setQs] = useState([])
  const [nq, setNq] = useState({ batch_id: '', title: '', duration_minutes: 30, max_tab_switch: 3 })
  const [f, setF] = useState({
    materi: '', body: '', type: 'pilihan_ganda', o: ['', '', '', ''], correct: 0, accepted: '',
    vars: 'A,B', table: [], shown: [], bugLangkah: '', bugJenis: 'urutan', bugKeywords: '', bugJenisCustom: '',
  })

  // Parse "value:Label, value2:Label2" jadi [{value,label}]. Kosong -> pakai default (Urutan/Kondisi/Perulangan).
  const parseJenisCustom = (s) => s.split(',').map((x) => x.trim()).filter(Boolean).map((pair) => {
    const [value, label] = pair.includes(':') ? pair.split(':').map((x) => x.trim()) : [pair, pair]
    return { value, label }
  })
  const jenisBugList = f.bugJenisCustom.trim() ? parseJenisCustom(f.bugJenisCustom) : JENIS_BUG

  const loadQuizzes = () => supabase.from('quizzes').select('*, batches(name)').order('created_at', { ascending: false }).then(({ data }) => setQuizzes(data || []))
  const loadQs = (id) => supabase.from('questions').select('id,materi,body,question_type,position').eq('quiz_id', id).order('position').then(({ data }) => setQs(data || []))
  useEffect(() => { supabase.from('batches').select('id,name').then(({ data }) => setBatches(data || [])); loadQuizzes() }, [])
  useEffect(() => { if (sel) loadQs(sel) }, [sel])

  const addQuiz = async (e) => {
    e.preventDefault()
    const { error } = await supabase.from('quizzes').insert({
      batch_id: nq.batch_id, title: nq.title,
      duration_minutes: +nq.duration_minutes,
      max_tab_switch: nq.max_tab_switch === '' ? null : +nq.max_tab_switch,
    })
    if (error) return alert(error.message)
    setNq({ ...nq, title: '' }); loadQuizzes()
  }
  const toggleActive = async (q) => { await supabase.from('quizzes').update({ is_active: !q.is_active }).eq('id', q.id); loadQuizzes() }

  const addQ = async (e) => {
    e.preventDefault()
    const isPG = f.type === 'pilihan_ganda'
    const isIsian = f.type === 'isian'
    const isTable = f.type === 'tabel_kebenaran'
    const isBug = f.type === 'cari_bug'
    let accepted = null, options = null, correct = null, correctTable = null
    let correctLangkah = null, correctJenis = null, bugKeywords = null

    if (isPG) { options = f.o; correct = f.correct }
    if (isIsian) {
      accepted = f.accepted.split(',').map((s) => s.trim()).filter(Boolean)
      if (accepted.length === 0) return alert('Isi minimal satu jawaban yang diterima, pisahkan dengan koma.')
    }
    if (isTable) {
      const vars = f.vars.split(',').map((s) => s.trim()).filter(Boolean)
      if (vars.length < 1 || vars.length > 4) return alert('Isi 1-4 nama variabel, pisahkan koma (mis. A,B).')
      const rows = truthRows(vars.length)
      if (f.table.length !== rows.length || f.table.some((v) => v !== 0 && v !== 1)) return alert('Isi Output (0/1) untuk semua baris tabel kebenaran.')
      const given = rows.map((_, i) => (f.shown[i] ? f.table[i] : null))
      options = { variables: vars, given }
      correctTable = f.table
    }
    if (isBug) {
      if (f.bugLangkah === '') return alert('Isi nomor langkah/baris yang benar.')
      if (!f.bugJenis) return alert('Pilih jenis bug yang benar.')
      correctLangkah = +f.bugLangkah
      correctJenis = f.bugJenis
      bugKeywords = f.bugKeywords.split(',').map((s) => s.trim()).filter(Boolean)
      if (bugKeywords.length === 0) return alert('Isi minimal satu kata kunci untuk penjelasan perbaikan, pisahkan dengan koma.')
      if (f.bugJenisCustom.trim()) options = { jenis_options: jenisBugList }
    }

    const { error } = await supabase.rpc('admin_add_question', {
      p_quiz: sel, p_materi: f.materi === '' ? null : +f.materi, p_body: f.body, p_type: f.type,
      p_options: options, p_correct: correct, p_accepted: accepted, p_correct_table: correctTable,
      p_correct_langkah: correctLangkah, p_correct_jenis: correctJenis, p_perbaikan_keywords: bugKeywords,
    })
    if (error) return alert(error.message)
    setF({ ...f, body: '', o: ['', '', '', ''], accepted: '', table: [], shown: [], bugLangkah: '', bugKeywords: '', bugJenisCustom: '' }); loadQs(sel)
  }
  const delQ = async (id) => { if (confirm('Hapus soal ini?')) { await supabase.from('questions').delete().eq('id', id); loadQs(sel) } }

  const tableVars = f.vars.split(',').map((s) => s.trim()).filter(Boolean)
  const tableRows = tableVars.length >= 1 && tableVars.length <= 4 ? truthRows(tableVars.length) : []
  const setTableCell = (ri, val) => {
    const next = tableRows.map((_, i) => (f.table[i] === 0 || f.table[i] === 1 ? f.table[i] : null))
    next[ri] = val
    setF({ ...f, table: next })
  }
  const toggleShown = (ri) => {
    const next = tableRows.map((_, i) => !!f.shown[i])
    next[ri] = !next[ri]
    setF({ ...f, shown: next })
  }

  return (
    <div>
      <form className="card stack" onSubmit={addQuiz}>
        <h3>Buat kuis baru</h3>
        <div className="row">
          <div style={{ flex: 1, minWidth: 180 }}><label>Batch</label>
            <select value={nq.batch_id} onChange={(e) => setNq({ ...nq, batch_id: e.target.value })} required>
              <option value="">Pilih batch</option>{batches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select></div>
          <div style={{ flex: 2, minWidth: 200 }}><label>Judul</label><input value={nq.title} onChange={(e) => setNq({ ...nq, title: e.target.value })} required /></div>
          <div style={{ width: 110 }}><label>Menit</label><input type="number" min="1" value={nq.duration_minutes} onChange={(e) => setNq({ ...nq, duration_minutes: e.target.value })} /></div>
          <div style={{ width: 150 }}><label>Maks pindah tab</label><input type="number" min="1" placeholder="kosong = catat saja" value={nq.max_tab_switch} onChange={(e) => setNq({ ...nq, max_tab_switch: e.target.value })} /></div>
        </div>
        <button>Buat kuis</button>
      </form>

      <h3>Daftar kuis</h3>
      {quizzes.map((q) => (
        <div className="card row between" key={q.id}>
          <div><strong>{q.title}</strong> <span className="badge">{q.batches?.name}</span><div className="muted">{q.duration_minutes} menit</div></div>
          <div className="row">
            <button className="ghost" onClick={() => setSel(q.id)}>Kelola soal</button>
            <button className={q.is_active ? 'danger' : ''} onClick={() => toggleActive(q)}>{q.is_active ? 'Nonaktifkan' : 'Aktifkan'}</button>
          </div>
        </div>
      ))}

      {sel && (
        <div className="card stack">
          <h3>Soal ({qs.length})</h3>
          {qs.map((q, n) => (
            <div className="row between" key={q.id}>
              <span>{n + 1}. {(q.body || '').slice(0, 80)}{(q.body || '').length > 80 ? '…' : ''} {q.materi && <span className="badge">Materi {q.materi}</span>} <span className="badge">
                {q.question_type === 'isian' ? 'Isian'
                  : q.question_type === 'tabel_kebenaran' ? 'Tabel kebenaran'
                  : q.question_type === 'cari_bug' ? 'Cari & perbaiki bug'
                  : 'Pilihan ganda'}
              </span></span>
              <button className="ghost" onClick={() => delQ(q.id)}>Hapus</button>
            </div>
          ))}
          <form className="stack" onSubmit={addQ} style={{ borderTop: '1px solid var(--line)', paddingTop: '1rem' }}>
            <h3>Tambah soal</h3>
            <div className="row">
              <div style={{ width: 100 }}><label>Materi (1-8)</label><input type="number" min="1" max="8" value={f.materi} onChange={(e) => setF({ ...f, materi: e.target.value })} /></div>
              <div style={{ flex: 1, minWidth: 180 }}><label>Tipe soal</label>
                <select value={f.type} onChange={(e) => setF({ ...f, type: e.target.value, table: [] })}>
                  <option value="pilihan_ganda">Pilihan ganda</option>
                  <option value="isian">Isian singkat</option>
                  <option value="tabel_kebenaran">Tabel kebenaran (gerbang logika)</option>
                  <option value="cari_bug">Cari & perbaiki bug</option>
                </select>
              </div>
            </div>
            <div>
              <label>{f.type === 'cari_bug' ? 'Skenario / langkah-langkah (tulis bernomor di sini)' : 'Pertanyaan'}</label>
              <textarea rows={f.type === 'cari_bug' ? 5 : 2} value={f.body} onChange={(e) => setF({ ...f, body: e.target.value })}
                placeholder={f.type === 'cari_bug' ? 'Contoh:\n1. Basahi badan\n2. Pakai baju bersih\n3. Sabunan\n4. Bilas\n5. Keringkan badan' : ''}
                required />
            </div>

            {f.type === 'pilihan_ganda' ? (<>
              {f.o.map((o, idx) => (
                <div className="row" key={idx}>
                  <input type="radio" name="correct" checked={f.correct === idx} onChange={() => setF({ ...f, correct: idx })} aria-label={`Jawaban benar ${String.fromCharCode(65 + idx)}`} />
                  <span style={{ width: 20 }}>{String.fromCharCode(65 + idx)}</span>
                  <input style={{ flex: 1 }} value={o} onChange={(e) => setF({ ...f, o: f.o.map((x, j) => (j === idx ? e.target.value : x)) })} required />
                </div>
              ))}
              <p className="muted">Pilih bulatan di samping jawaban yang benar.</p>
            </>) : f.type === 'isian' ? (
              <div>
                <label>Jawaban yang diterima (pisahkan dengan koma)</label>
                <input value={f.accepted} onChange={(e) => setF({ ...f, accepted: e.target.value })} placeholder="mis. bug kondisi, kondisi, bug urutan" required />
                <p className="muted">Tulis beberapa variasi supaya jawaban murid yang mirip tetap dianggap benar. Huruf besar/kecil dan spasi tidak masalah.</p>
              </div>
            ) : f.type === 'tabel_kebenaran' ? (
              <div>
                <label>Nama variabel input (pisahkan dengan koma, 1-4 variabel)</label>
                <input value={f.vars} onChange={(e) => setF({ ...f, vars: e.target.value, table: [], shown: [] })} placeholder="mis. A,B" />
                <p className="muted">Isi kolom Output untuk tiap baris sebagai kunci jawaban benar.</p>
                {tableVars.length >= 1 && tableVars.length <= 4 && (
                  <div className="scroll">
                    <table>
                      <thead><tr>{tableVars.map((v) => <th key={v}>{v}</th>)}<th>Output (kunci)</th><th>Tampilkan ke murid?</th></tr></thead>
                      <tbody>
                        {tableRows.map((row, ri) => (
                          <tr key={ri}>
                            {row.map((bit, ci) => <td key={ci}>{bit}</td>)}
                            <td>
                              <div className="row" style={{ gap: '.4rem' }}>
                                {[0, 1].map((v) => (
                                  <button type="button" key={v}
                                    className={f.table[ri] === v ? '' : 'ghost'}
                                    style={{ padding: '.3rem .8rem' }}
                                    onClick={() => setTableCell(ri, v)}>
                                    {v}
                                  </button>
                                ))}
                              </div>
                            </td>
                            <td>
                              <input type="checkbox" checked={!!f.shown[ri]} onChange={() => toggleShown(ri)}
                                aria-label={`Tampilkan baris ${ri + 1} ke murid`} />
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
                {tableVars.length > 4 && <p className="err">Maksimal 4 variabel (16 baris).</p>}
                <p className="muted">Centang "Tampilkan ke murid?" kalau baris itu mau ditunjukkan sudah terisi sebagai contoh. Biarkan tidak dicentang untuk baris yang harus diisi murid.</p>
              </div>
            ) : f.type === 'cari_bug' ? (
              <div className="stack">
                <div><label>Nomor langkah yang benar (kunci)</label>
                  <input type="number" min="1" style={{ maxWidth: 120 }} value={f.bugLangkah} onChange={(e) => setF({ ...f, bugLangkah: e.target.value })} required />
                </div>
                <div>
                  <label>Kategori jenis bug (opsional)</label>
                  <input value={f.bugJenisCustom} onChange={(e) => setF({ ...f, bugJenisCustom: e.target.value, bugJenis: '' })}
                    placeholder="syntax:Syntax Error, logic:Logic Error, urutan:Kesalahan Urutan Langkah" />
                  <p className="muted">Kosongkan untuk pakai kategori default (Bug Urutan/Kondisi/Perulangan). Isi dengan format <code>nilai:Label</code> dipisah koma untuk kategori sendiri.</p>
                </div>
                <div><label>Jenis bug yang benar (kunci)</label>
                  <div className="row">
                    {jenisBugList.map((j) => (
                      <label key={j.value} className="row" style={{ gap: '.3rem', fontWeight: 400 }}>
                        <input type="radio" name="bugJenis" checked={f.bugJenis === j.value} onChange={() => setF({ ...f, bugJenis: j.value })} />
                        {j.label}
                      </label>
                    ))}
                  </div>
                </div>
                <div>
                  <label>Kata kunci penjelasan perbaikan yang diterima (pisahkan koma)</label>
                  <input value={f.bugKeywords} onChange={(e) => setF({ ...f, bugKeywords: e.target.value })}
                    placeholder="mis. basahi dulu, basahi badan dulu, pakai baju terakhir" required />
                  <p className="muted">Kalau penjelasan murid mengandung salah satu kata kunci ini, otomatis benar. Kalau tidak cocok, akan masuk ke tab "Cek Jawaban" untuk kamu periksa manual.</p>
                </div>
              </div>
            ) : null}
            <button>Simpan soal</button>
          </form>
        </div>
      )}
    </div>
  )
}

function CekIsian() {
  const [rows, setRows] = useState([])
  const load = () => supabase.from('jawaban_untuk_dicek').select('*').then(({ data }) => setRows(data || []))
  useEffect(() => { load() }, [])

  const grade = async (r, correct) => {
    await supabase.rpc('admin_grade_isian', { p_attempt: r.attempt_id, p_question: r.question_id, p_correct: correct })
    await supabase.rpc('recalc_score', { p_attempt: r.attempt_id })
    load()
  }

  const jenisLabel = (v) => ({
    urutan: 'Bug Urutan', kondisi: 'Bug Kondisi', perulangan: 'Bug Perulangan',
    syntax: 'Syntax Error', logic: 'Logic Error', runtime: 'Runtime Error',
  }[v] || v)

  return (
    <div>
      <p className="muted">Ini daftar jawaban (isian & cari-bug) yang tidak otomatis cocok dengan kunci. Periksa dan tandai benar/salah secara manual — nilai murid akan otomatis diperbarui.</p>
      {rows.length === 0 && <p className="muted">Tidak ada jawaban yang perlu dicek saat ini.</p>}
      {rows.map((r, n) => (
        <div className="card stack" key={n}>
          <div><span className="badge">{r.batch}</span> <span className="badge">{r.kuis}</span>{' '}
            <span className="badge">{r.tipe === 'cari_bug' ? 'Cari & perbaiki bug' : 'Isian'}</span> — <strong>{r.nama}</strong></div>
          <p className="muted" style={{ whiteSpace: 'pre-line' }}>{r.pertanyaan}</p>

          {r.tipe === 'cari_bug' ? (<>
            <p>Jawaban murid — Langkah: <strong>{r.chosen_langkah ?? '-'}</strong>{' '}
              (kunci: {r.correct_langkah}), Jenis: <strong>{jenisLabel(r.chosen_jenis) || '-'}</strong>{' '}
              (kunci: {jenisLabel(r.correct_jenis)})</p>
            <p>Penjelasan perbaikan murid: <strong>{r.jawaban_teks || <em>(kosong)</em>}</strong></p>
            <p className="muted">Kata kunci yang diterima: {(r.perbaikan_keywords || []).join(', ')}</p>
          </>) : (<>
            <p>Jawaban murid: <strong>{r.jawaban_teks || <em>(kosong)</em>}</strong></p>
            <p className="muted">Kunci yang diterima: {(r.accepted_answers || []).join(', ')}</p>
          </>)}

          <div className="row">
            {r.manual_correct === true && <span className="badge" style={{ background: '#dcfce7', color: '#15803d' }}>Ditandai benar</span>}
            {r.manual_correct === false && <span className="badge" style={{ background: '#fee2e2', color: '#b91c1c' }}>Ditandai salah</span>}
            <button onClick={() => grade(r, true)}>Tandai benar</button>
            <button className="ghost" onClick={() => grade(r, false)}>Tandai salah</button>
          </div>
        </div>
      ))}
    </div>
  )
}
