import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'

export default function Register(){
	const [name, setName] = useState('')
	const [email, setEmail] = useState('')
	const [password, setPassword] = useState('')
	const [confirmPassword, setConfirmPassword] = useState('')
	const [role, setRole] = useState('developer')
	const [error, setError] = useState(null)
	const [loading, setLoading] = useState(false)
	const [touched, setTouched] = useState({ name: false, email: false, password: false, confirmPassword: false })
	const [showPassword, setShowPassword] = useState(false)
	const [showConfirmPassword, setShowConfirmPassword] = useState(false)
	const [isLoginMode, setIsLoginMode] = useState(false)
	const nav = useNavigate()

	const validateName = (value) => {
		if (!value.trim()) return 'Name is required'
		if (value.trim().length < 2) return 'Name must be at least 2 characters'
		if (value.trim().length > 50) return 'Name must be less than 50 characters'
		return null
	}

	const validateEmail = (value) => {
		const trimmed = value.trim()
		if (!trimmed) return 'Email is required'
		const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
		if (!emailRegex.test(trimmed)) return 'Please enter a valid email address'
		return null
	}

	const getPasswordStrength = (pwd) => {
		if (!pwd) return null
		let strength = 0
		if (pwd.length >= 8) strength++
		if (pwd.length >= 12) strength++
		if (/[a-z]/.test(pwd) && /[A-Z]/.test(pwd)) strength++
		if (/[0-9]/.test(pwd)) strength++
		if (/[^a-zA-Z0-9]/.test(pwd)) strength++
		
		if (strength <= 2) return 'weak'
		if (strength <= 3) return 'medium'
		return 'strong'
	}

	const validatePassword = (value) => {
		if (!value) return 'Password is required'
		if (value.length < 8) return 'Password must be at least 8 characters'
		if (!/[a-z]/.test(value)) return 'Password must contain lowercase letter'
		if (!/[A-Z]/.test(value)) return 'Password must contain uppercase letter'
		if (!/[0-9]/.test(value)) return 'Password must contain a number'
		return null
	}

	const validateConfirmPassword = (value) => {
		if (!value) return 'Please confirm your password'
		if (value !== password) return 'Passwords do not match'
		return null
	}

	const nameError = touched.name ? validateName(name) : null
	const emailError = touched.email ? validateEmail(email) : null
	const passwordError = touched.password ? validatePassword(password) : null
	const confirmPasswordError = touched.confirmPassword ? validateConfirmPassword(confirmPassword) : null
	const passwordStrength = password ? getPasswordStrength(password) : null
	const isFormValid = !validateName(name) && !validateEmail(email) && !validatePassword(password) && !validateConfirmPassword(confirmPassword)

	const submit = async (e) => {
		e.preventDefault()
		
		// Mark all fields as touched
		setTouched({ name: true, email: true, password: true, confirmPassword: true })
		
		// Validate all fields
		if (!isFormValid) {
			setError('Please fix all validation errors before submitting')
			return
		}
		
		setLoading(true)
		setError(null)
		
		try {
			const res = await fetch('/api/user/register', { 
				method: 'POST', 
				headers: { 'Content-Type': 'application/json' }, 
				body: JSON.stringify({ name: name.trim(), email: email.trim(), password, role }) 
			})
			const text = await res.text()
			let data = null
			try { 
				data = text ? JSON.parse(text) : null 
			} catch(err) { 
				data = { message: text } 
			}
			if (!res.ok) throw new Error((data && data.message) || res.statusText || 'Failed to register')
			nav('/user/login')
		} catch(err) { 
			setError(err.message) 
		} finally { 
			setLoading(false) 
		}
	}

	const passwordRequirements = [
		{ label: 'At least 8 characters', met: password.length >= 8 },
		{ label: 'Contains uppercase letter', met: /[A-Z]/.test(password) },
		{ label: 'Contains lowercase letter', met: /[a-z]/.test(password) },
		{ label: 'Contains a number', met: /[0-9]/.test(password) }
	]

	return (
		<main className="page auth-page">
			<div className="auth-home-btn">
				<button onClick={() => nav('/')} type="button">← Home</button>
			</div>
			
			<div className="auth-container active">
				{/* Login placeholder */}
				<div className="auth-form-box login-box">
				</div>

				{/* Register Form (shown on right side) */}
				<div className="auth-form-box register-box">
					<h2>Create Account</h2>
					<p className="auth-form-subtitle">Join TASKIFY to manage your projects</p>
					
					{error && <div className="error" style={{marginBottom: '15px'}}>{error}</div>}
					
					<form className="auth-form" onSubmit={submit} autoComplete="off">
						<input type="text" name="_fakeusernameremembered" style={{display:'none'}} autoComplete="off" />
						<input type="password" name="_fakepasswordremembered" style={{display:'none'}} autoComplete="off" />
					
						<input 
							name="name" 
							autoComplete="off" 
							value={name} 
							onChange={e => setName(e.target.value)}
							onBlur={() => setTouched(prev => ({ ...prev, name: true }))}
							className={touched.name ? (nameError ? 'invalid' : 'valid') : ''}
							placeholder="Full Name"
						/>
						{nameError && <div className="validation-error">{nameError}</div>}


						<input 
							name="email" 
							autoComplete="off" 
							type="email" 
							value={email} 
							onChange={e => setEmail(e.target.value)}
							onBlur={() => setTouched(prev => ({ ...prev, email: true }))}
							className={touched.email ? (emailError ? 'invalid' : 'valid') : ''}
							placeholder="Email Address"
						/>
						{emailError && <div className="validation-error">{emailError}</div>}


						<div className="password-input-wrapper">
							<input 
								name="password" 
								autoComplete="new-password" 
								type={showPassword ? "text" : "password"}
								value={password} 
								onChange={e => setPassword(e.target.value)}
								onBlur={() => setTouched(prev => ({ ...prev, password: true }))}
								className={touched.password ? (passwordError ? 'invalid' : 'valid') : ''}
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
						
						{password && passwordStrength && (
							<div className={`password-strength ${passwordStrength}`} style={{fontSize: '12px', marginTop: '5px'}}>
								<span>Strength: {passwordStrength === 'weak' ? 'Weak' : passwordStrength === 'medium' ? 'Medium' : 'Strong'}</span>
								<div className="password-strength-bar">
									<div className={`password-strength-fill ${passwordStrength}`}></div>
								</div>
							</div>
						)}
						
						{password && (
							<div className="input-requirements" style={{fontSize: '11px'}}>
								<ul>
									{passwordRequirements.map((req, idx) => (
										<li key={idx} className={req.met ? 'met' : ''}>
											{req.label}
										</li>
									))}
								</ul>
							</div>
						)}


						<div className="password-input-wrapper">
							<input 
								type={showConfirmPassword ? "text" : "password"}
								value={confirmPassword} 
								onChange={e => setConfirmPassword(e.target.value)}
								onBlur={() => setTouched(prev => ({ ...prev, confirmPassword: true }))}
								className={touched.confirmPassword ? (confirmPasswordError ? 'invalid' : 'valid') : ''}
								placeholder="Confirm Password"
								autoComplete="new-password"
							/>
							<button 
								type="button"
								className="password-toggle"
								onClick={() => setShowConfirmPassword(!showConfirmPassword)}
								aria-label={showConfirmPassword ? "Hide password" : "Show password"}
							>
								{showConfirmPassword ? '👁️' : '👁️‍🗨️'}
							</button>
						</div>
						{confirmPasswordError && <div className="validation-error">{confirmPasswordError}</div>}
						{!confirmPasswordError && confirmPassword && touched.confirmPassword && (
							<div className="validation-success">Passwords match</div>
						)}

						<select value={role} onChange={e => setRole(e.target.value)} style={{marginTop: '8px'}}>
							<option value="developer">Developer</option>
							<option value="designer">Designer</option>
							<option value="tester">Tester</option>
							<option value="client">Client</option>
						</select>

						<button 
							className="auth-submit-btn" 
							type="submit"
							disabled={loading || !isFormValid}
						>
							{loading ? 'Creating Account...' : 'Register'}
						</button>
					</form>
				</div>

				{/* Overlay Panel */}
				<div className="auth-overlay">
					<h1>Welcome Back!</h1>
					<p>Already have an account?</p>
					<button 
						className="auth-overlay-btn" 
						onClick={(e) => {
							e.preventDefault()
							nav('/user/login')
						}}
						type="button"
					>
						Sign In
					</button>
				</div>
			</div>
		</main>
	)
}
