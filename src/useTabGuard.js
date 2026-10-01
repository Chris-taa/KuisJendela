import { useEffect, useRef } from 'react'
import { supabase } from './supabase'

// Mencatat setiap kali murid meninggalkan halaman kuis.
// attemptId = null -> hook tidak aktif.
export function useTabGuard(attemptId, maxSwitch, onLimit, onWarn) {
  const away = useRef(null)
  const cb = useRef({})
  cb.current = { maxSwitch, onLimit, onWarn }

  useEffect(() => {
    if (!attemptId) return

    const report = async (type, ms) => {
      const { data: count } = await supabase.rpc('log_tab_event', {
        p_attempt: attemptId, p_type: type, p_ms: ms,
      })
      const { maxSwitch, onLimit, onWarn } = cb.current
      onWarn?.(count ?? 0, type)
      if (type !== 'fullscreen_exit' && maxSwitch && count >= maxSwitch) onLimit?.()
    }
    // visibilitychange dan blur sering menyala bersamaan -> hanya hitung sekali
    const leave = () => { if (!away.current) away.current = Date.now() }
    const back = () => {
      if (!away.current) return
      const ms = Date.now() - away.current
      away.current = null
      report('hidden', ms)
    }
    const onVisibility = () => (document.hidden ? leave() : back())
    const onFs = () => { if (!document.fullscreenElement) report('fullscreen_exit', 0) }

    document.addEventListener('visibilitychange', onVisibility)
    window.addEventListener('blur', leave)
    window.addEventListener('focus', back)
    document.addEventListener('fullscreenchange', onFs)
    return () => {
      document.removeEventListener('visibilitychange', onVisibility)
      window.removeEventListener('blur', leave)
      window.removeEventListener('focus', back)
      document.removeEventListener('fullscreenchange', onFs)
    }
  }, [attemptId])
}
