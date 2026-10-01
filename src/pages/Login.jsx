import { useState } from 'react'
import { supabase } from '../supabase'

const toEmail = (u) => `${u.trim().toLowerCase()}@kuis.local`

export default function Login() {
  const [mode, setMode] = useState('masuk')
  const [f, setF] = useState({ username: '', password: '', nama: '', kelas: '' })
  const [err, setErr] = useState('')
  const [busy, setBusy] = useState(false)
  const set = (k) => (e) => setF({ ...f, [k]: e.target.value })

  const submit = async (e) => {
    e.preventDefault()
    setErr('')
    if (!/^[a-z0-9._-]{3,}$/i.test(f.username.trim())) return setErr('Username minimal 3 karakter: huruf, angka, titik, strip, atau garis bawah.')
    if (f.password.length < 6) return setErr('Password minimal 6 karakter.')
    setBusy(true)
    const email = toEmail(f.username)
    const { error } = mode === 'masuk'
      ? await supabase.auth.signInWithPassword({ email, password: f.password })
      : await supabase.auth.signUp({ email, password: f.password,
          options: { data: { full_name: f.nama.trim(), class_name: f.kelas.trim() } } })
    setBusy(false)
    if (error) setErr(mode === 'masuk' ? 'Username atau password salah.' : error.message)
  }

  return (
    <div className="wrap" style={{ maxWidth: 420, paddingTop: '3rem' }}>
      <h1>Kuis Detektif Logika</h1>
      <p className="muted">Masuk untuk mengerjakan kuis batch kamu.</p>
      <form className="card stack" onSubmit={submit}>
        {mode === 'daftar' && (<>
          <div><label>Nama lengkap</label><input value={f.nama} onChange={set('nama')} required /></div>
          <div><label>Kelas</label><input value={f.kelas} onChange={set('kelas')} placeholder="mis. 4A" required /></div>
        </>)}
        <div><label>Username</label><input value={f.username} onChange={set('username')} autoCapitalize="none" required /></div>
        <div><label>Password</label><input type="password" value={f.password} onChange={set('password')} required /></div>
        {err && <div className="err">{err}</div>}
        <button disabled={busy}>{mode === 'masuk' ? 'Masuk' : 'Daftar'}</button>
        <button type="button" className="ghost" onClick={() => { setMode(mode === 'masuk' ? 'daftar' : 'masuk'); setErr('') }}>
          {mode === 'masuk' ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk'}
        </button>
      </form>
    </div>
  )
}
