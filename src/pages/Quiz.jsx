import { useEffect, useState, useRef, useCallback } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase } from '../supabase'
import { useTabGuard } from '../useTabGuard'
import { truthRows, JENIS_BUG } from '../truthTable'

const fmt = (ms) => {
  const s = Math.max(0, Math.floor(ms / 1000))
  return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`
}

export default function Quiz() {
  const { id } = useParams()
  const [quiz, setQuiz] = useState(null)
  const [att, setAtt] = useState(null)
  const [qs, setQs] = useState([])
  const [ans, setAns] = useState({})
  const [i, setI] = useState(0)
  const [left, setLeft] = useState(null)
  const [warn, setWarn] = useState('')
  const [result, setResult] = useState(null)
  const offset = useRef(0)
  const finishing = useRef(false)

  useEffect(() => {
    supabase.from('quizzes').select('*').eq('id', id).single().then(({ data }) => setQuiz(data))
  }, [id])

  const start = async () => {
    const { data, error } = await supabase.rpc('start_attempt', { p_quiz: id })
    if (error) return alert(error.message)
    if (data.finished_at) { setAtt(data); setResult(data.score); return }
    offset.current = new Date(data.server_now).getTime() - Date.now()
    try { await document.documentElement.requestFullscreen() } catch {}
    const { data: q } = await supabase.from('questions')
      .select('id,body,question_type,options,position').eq('quiz_id', id).order('position')
    const { data: a } = await supabase.from('answers')
      .select('question_id,chosen_index,chosen_text,chosen_table,chosen_langkah,chosen_jenis').eq('attempt_id', data.attempt_id)
    setQs(q || [])
    setAns(Object.fromEntries((a || []).map((x) => {
      if (x.chosen_langkah !== null && x.chosen_langkah !== undefined)
        return [x.question_id, { langkah: x.chosen_langkah, jenis: x.chosen_jenis, teks: x.chosen_text || '' }]
      if (x.chosen_table !== null && x.chosen_table !== undefined) return [x.question_id, x.chosen_table]
      if (x.chosen_text !== null && x.chosen_text !== undefined) return [x.question_id, x.chosen_text]
      return [x.question_id, x.chosen_index]
    })))
    setAtt(data)
  }

  const finish = useCallback(async () => {
    if (finishing.current || !att) return
    finishing.current = true
    const { data } = await supabase.rpc('finish_attempt', { p_attempt: att.attempt_id })
    if (document.fullscreenElement) document.exitFullscreen().catch(() => {})
    setResult(data ?? 0)
  }, [att])

  // Timer mengikuti jam server
  useEffect(() => {
    if (!att || !quiz || result !== null) return
    const end = new Date(att.started_at).getTime() + quiz.duration_minutes * 60000
    const tick = () => {
      const remain = end - (Date.now() + offset.current)
      setLeft(remain)
      if (remain <= 0) finish()
    }
    tick()
    const t = setInterval(tick, 1000)
    return () => clearInterval(t)
  }, [att, quiz, result, finish])

  useTabGuard(
    att && result === null ? att.attempt_id : null,
    quiz?.max_tab_switch,
    finish,
    (n, type) => setWarn(type === 'fullscreen_exit'
      ? 'Kamu keluar dari layar penuh. Kembali ke layar penuh ya.'
      : `Kamu meninggalkan halaman kuis (${n}x).${quiz?.max_tab_switch ? ` Batasnya ${quiz.max_tab_switch}x, setelah itu kuis otomatis dikumpulkan.` : ''}`)
  )

  const pick = async (qid, idx) => {
    setAns((a) => ({ ...a, [qid]: idx }))
    const { error } = await supabase.rpc('save_answer', { p_attempt: att.attempt_id, p_question: qid, p_choice: idx })
    if (error) alert(error.message)
  }

  const typeText = async (qid, text) => {
    setAns((a) => ({ ...a, [qid]: text }))
  }
  const saveText = async (qid) => {
    const { error } = await supabase.rpc('save_answer', { p_attempt: att.attempt_id, p_question: qid, p_text: ans[qid] ?? '' })
    if (error) alert(error.message)
  }

  // Baris tabel kebenaran yang sudah "diberi tahu" (pre-filled) ke murid, sisanya null (harus diisi)
  const baseTableFor = (q, rows) => {
    const given = q.options?.given
    if (Array.isArray(given) && given.length === rows.length) return given.map((v) => (v === null || v === undefined ? null : v))
    return Array(rows.length).fill(null)
  }

  const pickTable = async (q, rowIdx, val) => {
    const vars = q.options?.variables || ['A', 'B']
    const rows = truthRows(vars.length)
    const current = Array.isArray(ans[q.id]) ? [...ans[q.id]] : baseTableFor(q, rows)
    current[rowIdx] = val
    setAns((a) => ({ ...a, [q.id]: current }))
    if (current.every((v) => v === 0 || v === 1)) {
      const { error } = await supabase.rpc('save_answer', { p_attempt: att.attempt_id, p_question: q.id, p_table: current })
      if (error) alert(error.message)
    }
  }

  const saveCurrent = async (q) => {
    if (!q) return
    if (q.question_type === 'isian') await saveText(q.id)
    if (q.question_type === 'cari_bug') await saveBug(q.id)
  }

  const setBug = (qid, patch) => {
    setAns((a) => ({ ...a, [qid]: { langkah: '', jenis: '', teks: '', ...(a[qid] || {}), ...patch } }))
  }
  const saveBug = async (qid) => {
    const b = ans[qid] || {}
    const { error } = await supabase.rpc('save_answer', {
      p_attempt: att.attempt_id, p_question: qid,
      p_text: b.teks || '', p_langkah: b.langkah === '' ? null : +b.langkah, p_jenis: b.jenis || null,
    })
    if (error) alert(error.message)
  }

  if (!quiz) return <p className="center">Memuat…</p>

  if (result !== null) return (
    <div className="wrap center">
      <h1>Kuis selesai!</h1>
      <p className="timer">Nilai: {result}</p>
      <Link to="/"><button>Kembali ke beranda</button></Link>
    </div>
  )

  if (!att) return (
    <div className="wrap">
      <h1>{quiz.title}</h1>
      <div className="card stack">
        <p>Waktu: <strong>{quiz.duration_minutes} menit</strong>. Kuis hanya bisa dikerjakan sekali.</p>
        <ul>
          <li>Kuis dibuka dalam layar penuh.</li>
          <li>Jangan pindah tab atau aplikasi. Setiap kali pindah akan tercatat dan terlihat oleh pengajar.</li>
          {quiz.max_tab_switch && <li>Setelah pindah {quiz.max_tab_switch} kali, kuis otomatis dikumpulkan.</li>}
          <li>Jawaban tersimpan otomatis setiap kamu memilih.</li>
        </ul>
        <button onClick={start}>Mulai kuis</button>
      </div>
    </div>
  )

  const q = qs[i]
  return (
    <div className="wrap">
      <div className="row between">
        <h2>{quiz.title}</h2>
        <span className="timer">{left !== null && fmt(left)}</span>
      </div>
      {warn && <div className="banner" role="alert">{warn}</div>}
      {!document.fullscreenElement && (
        <button className="ghost" onClick={() => document.documentElement.requestFullscreen().catch(() => {})}>Masuk layar penuh</button>
      )}

      <div className="qnav">
        {qs.map((x, n) => {
          const v = ans[x.id]
          const done = x.question_type === 'isian' ? !!(v && v.trim())
            : x.question_type === 'tabel_kebenaran' ? (Array.isArray(v) && v.every((b) => b === 0 || b === 1))
            : x.question_type === 'cari_bug' ? !!(v && v.langkah !== '' && v.jenis && v.teks && v.teks.trim())
            : v !== undefined
          return <button key={x.id} className={n === i ? 'cur' : done ? 'done' : ''} onClick={() => setI(n)}>{n + 1}</button>
        })}
      </div>

      {q && (
        <div className="card">
          <p className="muted">Soal {i + 1} dari {qs.length}</p>
          <h3 style={{ marginBottom: '1rem' }}>{q.body}</h3>
          {q.question_type === 'isian' && (
            <div>
              <label htmlFor={`isian-${q.id}`}>Ketik jawaban kamu</label>
              <input
                id={`isian-${q.id}`}
                value={ans[q.id] ?? ''}
                onChange={(e) => typeText(q.id, e.target.value)}
                onBlur={() => saveText(q.id)}
                placeholder="Jawaban kamu..."
              />
              <p className="muted">Jawaban tersimpan otomatis saat kamu pindah dari kotak ini.</p>
            </div>
          )}
          {q.question_type === 'pilihan_ganda' && q.options.map((o, idx) => (
            <button key={idx} className={`option ${ans[q.id] === idx ? 'on' : ''}`} onClick={() => pick(q.id, idx)}>
              {String.fromCharCode(65 + idx)}. {o}
            </button>
          ))}
          {q.question_type === 'tabel_kebenaran' && (() => {
            const vars = q.options?.variables || ['A', 'B']
            const rows = truthRows(vars.length)
            const given = q.options?.given
            const myAns = Array.isArray(ans[q.id]) ? ans[q.id] : baseTableFor(q, rows)
            const adaGiven = Array.isArray(given) && given.some((v) => v !== null && v !== undefined)
            return (
              <div className="scroll">
                <table>
                  <thead>
                    <tr>{vars.map((v) => <th key={v}>{v}</th>)}<th>Output</th></tr>
                  </thead>
                  <tbody>
                    {rows.map((row, ri) => {
                      const locked = Array.isArray(given) && given[ri] !== null && given[ri] !== undefined
                      return (
                        <tr key={ri}>
                          {row.map((bit, ci) => <td key={ci}>{bit}</td>)}
                          <td>
                            {locked ? (
                              <strong>{given[ri]} <span className="muted">(contoh)</span></strong>
                            ) : (
                              <div className="row" style={{ gap: '.4rem' }}>
                                {[0, 1].map((v) => (
                                  <button key={v}
                                    className={myAns[ri] === v ? '' : 'ghost'}
                                    style={{ padding: '.3rem .8rem' }}
                                    onClick={() => pickTable(q, ri, v)}>
                                    {v}
                                  </button>
                                ))}
                              </div>
                            )}
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
                <p className="muted">
                  {adaGiven ? 'Sebagian baris sudah diisi sebagai contoh. Isi sisanya dengan 0 atau 1.' : 'Isi semua baris Output dengan 0 atau 1.'} Jawaban tersimpan otomatis setelah semua baris terisi.
                </p>
              </div>
            )
          })()}
          {q.question_type === 'cari_bug' && (() => {
            const b = ans[q.id] || { langkah: '', jenis: '', teks: '' }
            const jenisOptions = Array.isArray(q.options?.jenis_options) && q.options.jenis_options.length
              ? q.options.jenis_options : JENIS_BUG
            return (
              <div className="stack">
                <div>
                  <label htmlFor={`langkah-${q.id}`}>Bug ada di baris/langkah nomor berapa?</label>
                  <input id={`langkah-${q.id}`} type="number" min="1" style={{ maxWidth: 120 }}
                    value={b.langkah} onChange={(e) => setBug(q.id, { langkah: e.target.value })} onBlur={() => saveBug(q.id)} />
                </div>
                <div>
                  <label>Jenis bug apa?</label>
                  <div className="row">
                    {jenisOptions.map((j) => (
                      <label key={j.value} className="row" style={{ gap: '.3rem', fontWeight: 400 }}>
                        <input type="radio" name={`jenis-${q.id}`} checked={b.jenis === j.value}
                          onChange={() => { setBug(q.id, { jenis: j.value }); setTimeout(() => saveBug(q.id), 0) }} />
                        {j.label}
                      </label>
                    ))}
                  </div>
                </div>
                <div>
                  <label htmlFor={`perbaikan-${q.id}`}>Jelaskan cara memperbaikinya</label>
                  <textarea id={`perbaikan-${q.id}`} rows="3"
                    value={b.teks} onChange={(e) => setBug(q.id, { teks: e.target.value })} onBlur={() => saveBug(q.id)} />
                </div>
                <p className="muted">Semua jawaban tersimpan otomatis.</p>
              </div>
            )
          })()}
        </div>
      )}

      <div className="row between">
        <button className="ghost" disabled={i === 0} onClick={async () => { await saveCurrent(q); setI(i - 1) }}>Sebelumnya</button>
        {i < qs.length - 1
          ? <button onClick={async () => { await saveCurrent(q); setI(i + 1) }}>Berikutnya</button>
          : <button className="danger" onClick={async () => { await saveCurrent(q); if (confirm('Kumpulkan jawaban sekarang?')) finish() }}>Kumpulkan</button>}
      </div>
    </div>
  )
}
