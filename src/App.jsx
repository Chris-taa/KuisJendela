import { useEffect, useState } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { supabase } from './supabase'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Quiz from './pages/Quiz'
import Admin from './pages/Admin'

export default function App() {
  const [session, setSession] = useState(undefined)
  const [profile, setProfile] = useState(null)

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session))
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => setSession(s))
    return () => sub.subscription.unsubscribe()
  }, [])

  useEffect(() => {
    if (!session) { setProfile(null); return }
    supabase.from('profiles').select('*').eq('id', session.user.id).single()
      .then(({ data }) => setProfile(data))
  }, [session])

  if (session === undefined || (session && !profile)) return <p className="center">Memuat…</p>
  if (!session) return <Login />

  const admin = profile.role === 'admin'
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={admin ? <Navigate to="/admin" /> : <Dashboard profile={profile} />} />
        <Route path="/kuis/:id" element={<Quiz />} />
        <Route path="/admin" element={admin ? <Admin profile={profile} /> : <Navigate to="/" />} />
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  )
}
