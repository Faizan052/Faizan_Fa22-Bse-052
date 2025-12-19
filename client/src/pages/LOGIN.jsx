import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { apiFetch } from '../api'

export default function LOGIN(){
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [touched, setTouched] = useState({ email: false, password: false })
  const [showPassword, setShowPassword] = useState(false)
  const [isRegisterMode, setIsRegisterMode] = useState(false)
  const nav = useNavigate()

  const validateEmail = (value) => {
    const trimmed = value.trim()
    if (!trimmed) return 'Email or username is required'
    return null
  }

  const validatePassword = (value) => {
    if (!value) return 'Password is required'
    return null
  }

  const emailError = touched.email ? validateEmail(email) : null
  const passwordError = touched.password ? validatePassword(password) : null
  const isFormValid = !validateEmail(email) && !validatePassword(password)

  const completeLogin = (data, fallbackRole) => {
    const role = data?.role || fallbackRole || 'client'
    localStorage.setItem('tm_token', data.token)
    localStorage.setItem('tm_isAdmin', role === 'admin' ? 'true' : 'false')
    if (role) localStorage.setItem('tm_role', role); else localStorage.removeItem('tm_role')

    if (role === 'admin') return nav('/admin')
    if (role === 'hr') return nav('/hr')
    if (role === 'manager') return nav('/manager')
    if (role === 'developer') return nav('/developer')
    if (role === 'designer') return nav('/designer')
    if (role === 'tester') return nav('/tester')
    if (role === 'client') return nav('/client')
    return nav('/')
  }

  const submit = async (e) => {
    e.preventDefault()
    
    // Mark all fields as touched
    setTouched({ email: true, password: true })
    
    // Validate all fields
    if (!isFormValid) {
      setError('Please fix the validation errors before submitting')
      return
    }
    
    setLoading(true)
    setError(null)
    const trimmedEmail = email.trim()
    try {
      // Attempt normal user login first
      const userData = await apiFetch('/api/user/login', {
        method: 'POST',
        body: { email: trimmedEmail, password }
      })
      setLoading(false)
      return completeLogin(userData, userData.role)
    } catch (userErr) {
      const message = userErr?.message || ''
      const retryAdmin = message.includes('Invalid email or password') || message.includes('User not found')
      const networkIssue = message === 'Failed to fetch'

      if (!retryAdmin && !networkIssue) {
        setError(message || 'Unable to sign in. Please try again.')
        setLoading(false)
        return
      }

      if (networkIssue) {
        setError('Unable to reach the server. Please ensure the backend is running and try again.')
        setLoading(false)
        return
      }

      try {
        const adminData = await apiFetch('/api/admin/login', {
          method: 'POST',
          body: { username: trimmedEmail, password }
        })
        setLoading(false)
        return completeLogin(adminData, 'admin')
      } catch (adminErr) {
        const adminMessage = adminErr?.message || 'Unable to sign in.'
        setError(adminMessage)
      } finally {
        setLoading(false)
      }
    }
  }

  return (
    <main className="page auth-page">
      <div className="auth-home-btn">
        <button onClick={() => nav('/')} type="button">← Home</button>
      </div>
      
      <div className={`auth-container ${isRegisterMode ? 'active' : ''}`}>
        {/* Login Form */}
        <div className="auth-form-box login-box">
          <h2>Welcome Back</h2>
          <p className="auth-form-subtitle">Sign in to access your workspace</p>
          
          {error && !isRegisterMode && <div className="error" style={{marginBottom: '15px'}}>{error}</div>}

          <form className="auth-form" onSubmit={submit} autoComplete="off">
            <input type="text" name="_fakeusernameremembered" style={{display:'none'}} autoComplete="off" />
            <input type="password" name="_fakepasswordremembered" style={{display:'none'}} autoComplete="off" />

            <input 
              type="text" 
              value={email} 
              onChange={e => setEmail(e.target.value)}
              onBlur={() => setTouched(prev => ({ ...prev, email: true }))}
              className={touched.email ? (emailError ? 'invalid' : 'valid') : ''}
              autoComplete="off"
              placeholder="Email or Username"
            />
            {emailError && <div className="validation-error">{emailError}</div>}

            <div className="password-input-wrapper">
              <input 
                type={showPassword ? "text" : "password"}
                value={password} 
                onChange={e => setPassword(e.target.value)}
                onBlur={() => setTouched(prev => ({ ...prev, password: true }))}
                className={touched.password ? (passwordError ? 'invalid' : 'valid') : ''}
                autoComplete="new-password"
                placeholder="Password"
              />
              <button 
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? '👁️' : '👁️‍🗨️'}
              </button>
            </div>
            {passwordError && <div className="validation-error">{passwordError}</div>}

            <button 
              className="auth-submit-btn" 
              type="submit"
              disabled={loading || !isFormValid}
            >
              {loading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
        </div>

        {/* Register placeholder */}
        <div className="auth-form-box register-box">
        </div>

        {/* Overlay Panel */}
        <div className="auth-overlay">
          <h1>Hello, Welcome!</h1>
          <p>Don't have an account?</p>
          <button 
            className="auth-overlay-btn" 
            onClick={(e) => {
              e.preventDefault()
              setIsRegisterMode(true)
              setTimeout(() => {
                nav('/register')
              }, 600)
            }}
            type="button"
          >
            Register
          </button>
        </div>
      </div>
    </main>
  )
}
      