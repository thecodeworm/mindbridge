import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { supabase } from '../lib/supabaseClient'

interface AuthContextValue {
  session: Session | null
  user: User | null
  loading: boolean
  isRecoverySession: boolean
  signUp: (
    email: string,
    password: string,
    displayName: string,
    consent: Record<string, unknown>,
  ) => Promise<{ error: string | null }>
  signIn: (email: string, password: string) => Promise<{ error: string | null }>
  signInWithGoogle: () => Promise<{ error: string | null }>
  resetPassword: (email: string) => Promise<{ error: string | null }>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

// A reset-password link establishes a full, persisted Supabase session. This
// flag keeps ProtectedRoute from treating that as a normal login. Persisted
// to sessionStorage so a reload mid-recovery doesn't silently promote it.
const RECOVERY_STORAGE_KEY = 'mindbridge-recovery-session'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)
  const [isRecoverySession, setIsRecoverySession] = useState(
    () => sessionStorage.getItem(RECOVERY_STORAGE_KEY) === 'true',
  )

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session)
      setLoading(false)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, newSession) => {
      setSession(newSession)

      if (event === 'PASSWORD_RECOVERY') {
        setIsRecoverySession(true)
        sessionStorage.setItem(RECOVERY_STORAGE_KEY, 'true')
      } else if (event === 'SIGNED_OUT') {
        setIsRecoverySession(false)
        sessionStorage.removeItem(RECOVERY_STORAGE_KEY)
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  async function signUp(
    email: string,
    password: string,
    displayName: string,
    consent: Record<string, unknown>,
  ) {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { display_name: displayName.trim().slice(0, 60), ...consent } },
    })
    return { error: error?.message ?? null }
  }

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    return { error: error?.message ?? null }
  }

  async function signInWithGoogle() {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin },
    })
    return { error: error?.message ?? null }
  }

  async function resetPassword(email: string) {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    })
    return { error: error?.message ?? null }
  }

  async function signOut() {
    await supabase.auth.signOut()
  }

  const value: AuthContextValue = {
    session,
    user: session?.user ?? null,
    loading,
    isRecoverySession,
    signUp,
    signIn,
    signInWithGoogle,
    resetPassword,
    signOut,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider')
  return ctx
}
