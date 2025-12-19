import React, { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { apiFetch, clearSession } from '../api'

const formatRoleLabel = (value) => (value ? value.charAt(0).toUpperCase() + value.slice(1) : '')

const routeForRole = (role) => {
	switch(role){
		case 'hr':
			return '/hr'
		case 'manager':
			return '/manager'
		case 'developer':
			return '/developer'
		case 'designer':
			return '/designer'
		case 'tester':
			return '/tester'
		case 'client':
			return '/client'
		default:
			return '/'
	}
}

export default function UserProfile(){
	const nav = useNavigate()
	const [profile, setProfile] = useState(null)
	const [form, setForm] = useState({ name: '', email: '', password: '' })
	const [loading, setLoading] = useState(true)
	const [saving, setSaving] = useState(false)
	const [message, setMessage] = useState('')
	const [error, setError] = useState(null)

	const roleLabel = useMemo(()=>formatRoleLabel(profile ? profile.role : ''), [profile])
	const displayName = profile && profile.name ? profile.name : (profile && profile.email ? profile.email : 'User')

	const loadProfile = async () => {
		setLoading(true); setError(null)
		try{
			const data = await apiFetch('/api/user/profile')
			setProfile(data)
			setForm({ name: data.name || '', email: data.email || '', password: '' })
		}catch(err){ setError(err.message) }
		finally{ setLoading(false) }
	}

	useEffect(()=>{ loadProfile() },[])

	const handleChange = (field, value) => {
		setForm(prev => ({ ...prev, [field]: value }))
	}

	const submit = async (e) => {
		e.preventDefault()
		setSaving(true); setMessage(''); setError(null)
		const payload = { name: form.name, email: form.email }
		if (form.password) payload.password = form.password
		try{
			const updated = await apiFetch('/api/user/profile', { method: 'PUT', body: payload })
			setMessage('Profile updated')
			setProfile(updated)
			setForm(prev => ({ ...prev, name: updated.name || '', email: updated.email || '', password: '' }))
		}catch(err){ setError(err.message) }
		finally{ setSaving(false) }
	}

	const goBack = () => {
		const role = profile ? profile.role : localStorage.getItem('tm_role')
		nav(routeForRole(role))
	}

	const logout = () => {
		clearSession()
		nav('/user/login')
	}

	return (
		<main className="page">
			<header style={{display:'flex', justifyContent:'space-between', alignItems:'center', flexWrap:'wrap', gap:8, marginBottom:12}}>
				<div>
					<h1 style={{margin:0}}>Profile</h1>
					<p style={{margin:'6px 0 0 0'}}>Welcome {displayName}{roleLabel ? ` (${roleLabel})` : ''}</p>
				</div>
				<div style={{display:'flex', gap:8, flexWrap:'wrap'}}>
					<button className="btn btn-outline" onClick={goBack}>Back to dashboard</button>
					<button className="btn" onClick={logout}>Sign out</button>
				</div>
			</header>

			{loading && <div>Loading profile...</div>}
			{!loading && (
				<React.Fragment>
					{message && <div style={{background:'#e6f7ef', color:'#106433', padding:'8px 10px', borderRadius:6, marginBottom:8}}>{message}</div>}
					{error && <div className="error" style={{marginBottom:8}}>{error}</div>}

					<section>
						<h2>Account details</h2>
						<p><strong>Role:</strong> {roleLabel || '—'}</p>
						<form className="form" onSubmit={submit}>
							<label>Name<input value={form.name} onChange={e=>handleChange('name', e.target.value)} required/></label>
							<label>Email<input type="email" value={form.email} onChange={e=>handleChange('email', e.target.value)} required/></label>
							<label>New password<input type="password" value={form.password} onChange={e=>handleChange('password', e.target.value)} placeholder="Leave blank to keep current password"/></label>
							<div className="form-row"><button className="btn" disabled={saving}>{saving ? 'Saving...' : 'Save changes'}</button></div>
						</form>
					</section>
				</React.Fragment>
			)}
		</main>
	)
}
