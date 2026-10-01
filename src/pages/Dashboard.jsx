import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '../supabase'

export default function Dashboard({ profile }) {
  const [quizzes, setQuizzes] = useState([])
  const [attempts, setAttempts] = useState({})
  const [key, setKey] = useState('')
  const [msg, setMsg] = useState('')

  const load = async () => {
    const { data: q } = await supabase.from('quizzes')
      .select('id,title,duration_minutes,batches(name)').eq('is_active', true)
    const { data: a } = await supabase.from('attempts').select('quiz_id,score,finished_at')
    setQuizzes(q || [])
    setAttempts(Object.fromEntries((a || []).map((x) => [x.quiz_id, x])))
  }
  useEffect(() => { load() }, [])

  const join = async (e) => {
    e.preventDefault()
    setMsg('')
    const { error } = await supabase.rpc('join_batch', { p_key: key })
    if (error) return setMsg('Kunci salah atau batch sudah ditutup.')
    setKey(''); setMsg('Berhasil masuk batch!'); load()
  }

  return (
    <div className="wrap">
      <div className="row between">
        <div><h1>Halo, {profile.full_name}</h1><span className="muted">Kelas {profile.class_name}</span></div>
        <button className="ghost" onClick={() => supabase.auth.signOut()}>Keluar</button>
      </div>

      <form className="card row" onSubmit={join} style={{ marginTop: '1rem' }}>
        <div style={{ flex: 1, minWidth: 200 }}>
          <label>Kunci enrol batch</label>
          <input value={key} onChange={(e) => setKey(e.target.value)} placeholder="Dari kakak pengajar" required />
        </div>
        <button style={{ alignSelf: 'flex-end' }}>Masuk batch</button>
      </form>
      {msg && <p className={msg.startsWith('Berhasil') ? '' : 'err'}>{msg}</p>}

      <h2>Kuis kamu</h2>
      {quizzes.length === 0 && <p className="muted">Belum ada kuis. Masukkan kunci enrol dulu, atau tunggu kuis dibuka.</p>}
      {quizzes.map((q) => {
        const a = attempts[q.id]
        return (
          <div className="card row between" key={q.id}>
            <div>
              <h3>{q.title}</h3>
              <span className="badge">{q.batches?.name}</span>{' '}
              <span className="muted">{q.duration_minutes} menit</span>
            </div>
            {a?.finished_at
              ? <strong>Nilai: {a.score}</strong>
              : <Link to={`/kuis/${q.id}`}><button>{a ? 'Lanjutkan' : 'Mulai'}</button></Link>}
          </div>
        )
      })}
    </div>
  )
}
