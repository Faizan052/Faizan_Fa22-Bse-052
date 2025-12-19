import React, { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { apiFetch, clearSession } from '../api'

const AUTO_REFRESH_INTERVAL = 30000

const formatDate = (value) => value ? new Date(value).toLocaleDateString() : '—'

export default function AdminDashboard(){
	const nav = useNavigate()
	const [profile, setProfile] = useState(null)
	const [tasks, setTasks] = useState([])
	const [teams, setTeams] = useState([])
	const [clients, setClients] = useState([])
	const [hrs, setHrs] = useState([])
	const [loading, setLoading] = useState(true)
	const [error, setError] = useState(null)
	const [activeView, setActiveView] = useState('overview')
	const [message, setMessage] = useState('')
	const [profileForm, setProfileForm] = useState({ name: '', email: '', username: '', bio: '', password: '' })
	const [profilePhoto, setProfilePhoto] = useState(null)
	const [photoPreview, setPhotoPreview] = useState(null)
	const adminDetails = useMemo(() => profile && profile.admin ? profile.admin : null, [profile])
	const displayName = adminDetails && adminDetails.username ? adminDetails.username : 'Admin'

	const loadDashboard = useCallback(async (withSpinner = false) => {
		if (withSpinner) setLoading(true)
		setError(null)
		try{
			const [profileData, taskData, teamData, userData, hrData] = await Promise.all([
				apiFetch('/api/admin/profile'),
				apiFetch('/api/admin/tasks'),
				apiFetch('/api/admin/teams'),
				apiFetch('/api/admin/users'),
				apiFetch('/api/admin/hr').catch(() => [])
			])
			setProfile(profileData)
			setTasks(taskData)
			setTeams(teamData)
			setClients(userData.filter(user => user.role === 'client'))
			setHrs(hrData)
			if (profileData && profileData.admin) {
				setProfileForm({
					name: profileData.admin.name || profileData.admin.username || '',
					email: profileData.admin.email || '',
					username: profileData.admin.username || '',
					bio: profileData.admin.bio || '',
					password: ''
				})
			}
		}catch(err){ setError(err.message) }
		finally{ if (withSpinner) setLoading(false) }
	},[])

	useEffect(()=>{ loadDashboard(true) },[loadDashboard])

	useEffect(()=>{
		const id = setInterval(()=>{ loadDashboard() }, AUTO_REFRESH_INTERVAL)
		return () => clearInterval(id)
	},[loadDashboard])

	const logout = () => {
		clearSession()
		nav('/admin/login')
	}

	const deleteHr = async (hrId) => {
		if (!window.confirm('Are you sure you want to delete this HR?')) return
		try {
			await apiFetch(`/api/admin/hr/${hrId}`, { method: 'DELETE' })
			setMessage('HR deleted successfully')
			loadDashboard()
			setTimeout(() => setMessage(''), 3000)
		} catch (err) {
			setError(err.message)
		}
	}

	const handlePhotoChange = (e) => {
		const file = e.target.files[0]
		if (file) {
			setProfilePhoto(file)
			const reader = new FileReader()
			reader.onloadend = () => {
				setPhotoPreview(reader.result)
			}
			reader.readAsDataURL(file)
		}
	}

	const saveProfile = async () => {
		try {
			const updates = {}
			if (profileForm.name !== (adminDetails?.name || adminDetails?.username)) updates.name = profileForm.name
			if (profileForm.email !== (adminDetails?.email || '')) updates.email = profileForm.email
			if (profileForm.username !== (adminDetails?.username || '')) updates.username = profileForm.username
			if (profileForm.bio) updates.bio = profileForm.bio
			if (profileForm.password) updates.password = profileForm.password

			const result = await apiFetch('/api/admin/profile', {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify(updates)
			})

			setMessage('Profile updated successfully!')
			setProfileForm({ ...profileForm, password: '' })
			loadDashboard()
			setTimeout(() => setMessage(''), 3000)
		} catch (err) {
			setError(err.message)
			setTimeout(() => setError(null), 3000)
		}
	}

	const renderContent = () => {
		if (loading) return <div className="admin-loading">Loading data...</div>
		if (error) return <div className="error">{error}</div>

		switch(activeView) {
			case 'hrs':
				return (
					<div className="admin-view">
						<div className="admin-view-header">
							<h2>HR Management</h2>
							<button className="btn" onClick={() => nav('/admin/manage-hrs')}>Add New HR</button>
						</div>
						{message && <div className="success-message">{message}</div>}
						<div className="admin-grid">
							{hrs && hrs.length ? hrs.map(hr => (
								<div key={hr._id} className="admin-card">
									<div className="admin-card-header">
										<h3>{hr.name || hr.username}</h3>
										<span className="status-badge status-active">HR</span>
									</div>
									<div className="admin-card-body">
										<p><strong>Email:</strong> {hr.email}</p>
										<p><strong>Username:</strong> {hr.username}</p>
									</div>
									<div className="admin-card-footer">
										<button className="btn-small btn-danger" onClick={() => deleteHr(hr._id)}>Delete</button>
										<button className="btn-small" onClick={() => nav('/admin/manage-hrs')}>Edit</button>
									</div>
								</div>
							)) : <p className="empty-state">No HRs found</p>}
						</div>
					</div>
				)

			case 'managers':
				return (
					<div className="admin-view">
						<div className="admin-view-header">
							<h2>Managers Overview</h2>
						</div>
						<div className="admin-grid">
							{profile.managers && profile.managers.length ? profile.managers.map(manager => (
								<div key={manager._id} className="admin-card">
									<div className="admin-card-header">
										<h3>{manager.name}</h3>
										<span className="status-badge status-active">Active</span>
									</div>
									<div className="admin-card-body">
										<p><strong>Email:</strong> {manager.email}</p>
										<p><strong>Role:</strong> Manager</p>
										<div className="progress-info">
											<div className="progress-label">Success Rate</div>
											<div className="progress-bar">
												<div className="progress-fill" style={{width: '85%'}}></div>
											</div>
											<span className="progress-value">85%</span>
										</div>
									</div>
								</div>
							)) : <p className="empty-state">No managers found</p>}
						</div>
					</div>
				)

			case 'teams':
				return (
					<div className="admin-view">
						<div className="admin-view-header">
							<h2>Teams Overview</h2>
						</div>
						<div className="admin-grid">
							{teams && teams.length ? teams.map(team => (
								<div key={team._id} className="admin-card">
									<div className="admin-card-header">
										<h3>{team.name}</h3>
										<span className="status-badge status-info">{team.members?.length || 0} Members</span>
									</div>
									<div className="admin-card-body">
										<p><strong>Manager:</strong> {team.manager ? team.manager.name : 'Not assigned'}</p>
										<p><strong>Members:</strong> {team.members && team.members.length ? team.members.map(m => m.name || m.email).join(', ') : 'None'}</p>
										<div className="progress-info">
											<div className="progress-label">Team Progress</div>
											<div className="progress-bar">
												<div className="progress-fill" style={{width: '70%'}}></div>
											</div>
											<span className="progress-value">70%</span>
										</div>
									</div>
								</div>
							)) : <p className="empty-state">No teams found</p>}
						</div>
					</div>
				)

			case 'clients':
				return (
					<div className="admin-view">
						<div className="admin-view-header">
							<h2>Clients Overview</h2>
						</div>
						<div className="admin-grid">
							{clients && clients.length ? clients.map(client => (
								<div key={client._id} className="admin-card">
									<div className="admin-card-header">
										<h3>{client.name || client.email}</h3>
										<span className="status-badge status-active">Client</span>
									</div>
									<div className="admin-card-body">
										<p><strong>Email:</strong> {client.email}</p>
										<p><strong>Joined:</strong> {formatDate(client.createdAt)}</p>
									</div>
								</div>
							)) : <p className="empty-state">No clients found</p>}
						</div>
					</div>
				)

			case 'tasks':
				return (
					<div className="admin-view">
						<div className="admin-view-header">
							<h2>All Tasks</h2>
						</div>
						<div className="admin-table-container">
							{tasks && tasks.length ? (
								<table className="admin-table">
									<thead>
										<tr>
											<th>Title</th>
											<th>Assigned To</th>
											<th>Team</th>
											<th>Status</th>
											<th>Deadline</th>
										</tr>
									</thead>
									<tbody>
										{tasks.map(task => {
											const statusClass = task.status === 'completed' ? 'status-completed' : task.status === 'in-progress' ? 'status-in-progress' : 'status-pending';
											return (
												<tr key={task._id}>
													<td>{task.title}</td>
													<td>{task.assignedTo ? `${task.assignedTo.name} (${task.assignedTo.role})` : '—'}</td>
													<td>{task.assignedTeam ? task.assignedTeam.name : '—'}</td>
													<td><span className={`status-badge ${statusClass}`}>{task.status}</span></td>
													<td>{formatDate(task.deadline)}</td>
												</tr>
											);
										})}
									</tbody>
								</table>
							) : <p className="empty-state">No tasks found</p>}
						</div>
					</div>
				)

			case 'profile':
				return (
					<div className="admin-view">
						<div className="admin-view-header">
							<h2>Admin Profile</h2>
						</div>
						{message && <div className="admin-message">{message}</div>}
						{error && <div className="error-message">{error}</div>}
						<div className="admin-profile">
							<div className="profile-avatar">
								{photoPreview ? (
									<img src={photoPreview} alt="Profile" className="avatar-circle" style={{objectFit: 'cover'}} />
								) : (
									<div className="avatar-circle">{displayName.charAt(0).toUpperCase()}</div>
								)}
								<div className="avatar-upload">
									<input 
										type="file" 
										id="photoUpload" 
										accept="image/*" 
										onChange={handlePhotoChange}
									/>
									<label htmlFor="photoUpload">Change Photo</label>
								</div>
							</div>
							<div className="profile-form">
								<div className="form-row">
									<div className="form-group">
										<label>Name</label>
										<input 
											type="text" 
											value={profileForm.name} 
											onChange={(e) => setProfileForm({...profileForm, name: e.target.value})}
										/>
									</div>
									<div className="form-group">
										<label>Email</label>
										<input 
											type="email" 
											value={profileForm.email} 
											onChange={(e) => setProfileForm({...profileForm, email: e.target.value})}
										/>
									</div>
								</div>
								<div className="form-group">
									<label>Username</label>
									<input 
										type="text" 
										value={profileForm.username} 
										onChange={(e) => setProfileForm({...profileForm, username: e.target.value})}
									/>
								</div>
								<div className="form-group">
									<label>Bio</label>
									<textarea 
										rows="4" 
										value={profileForm.bio} 
										placeholder="Tell us about yourself..."
										onChange={(e) => setProfileForm({...profileForm, bio: e.target.value})}
									></textarea>
								</div>
								<div className="form-group">
									<label>New Password</label>
									<input 
										type="password" 
										value={profileForm.password} 
										placeholder="Leave blank to keep current password"
										onChange={(e) => setProfileForm({...profileForm, password: e.target.value})}
									/>
								</div>
								<div className="profile-form-actions">
									<button className="btn btn-primary" onClick={saveProfile}>Save Changes</button>
								</div>
							</div>
						</div>
					</div>
				)

			default:
				return (
					<div className="admin-view">
						<div className="admin-stats">
							<div className="stat-card" onClick={() => setActiveView('hrs')}>
								<div className="stat-icon">👥</div>
								<div className="stat-info">
									<div className="stat-card-value">{hrs?.length || 0}</div>
									<div className="stat-card-label">HR's</div>
								</div>
							</div>
							<div className="stat-card" onClick={() => setActiveView('managers')}>
								<div className="stat-icon">👔</div>
								<div className="stat-info">
									<div className="stat-card-value">{profile.managers?.length || 0}</div>
									<div className="stat-card-label">Managers</div>
								</div>
							</div>
							<div className="stat-card" onClick={() => setActiveView('teams')}>
								<div className="stat-icon">🤝</div>
								<div className="stat-info">
									<div className="stat-card-value">{teams?.length || 0}</div>
									<div className="stat-card-label">Teams</div>
								</div>
							</div>
							<div className="stat-card" onClick={() => setActiveView('clients')}>
								<div className="stat-icon">💼</div>
								<div className="stat-info">
									<div className="stat-card-value">{clients?.length || 0}</div>
									<div className="stat-card-label">Clients</div>
								</div>
							</div>
							<div className="stat-card" onClick={() => setActiveView('tasks')}>
								<div className="stat-icon">📋</div>
								<div className="stat-info">
									<div className="stat-card-value">{tasks?.length || 0}</div>
									<div className="stat-card-label">Tasks</div>
								</div>
							</div>
							<div className="stat-card" onClick={() => setActiveView('profile')}>
								<div className="stat-icon">⚙️</div>
								<div className="stat-info">
									<div className="stat-card-value">•</div>
									<div className="stat-card-label">Profile</div>
								</div>
							</div>
						</div>
					</div>
				)
		}
	}

	return (
		<div className="admin-dashboard-fullscreen">
			<div className="admin-header-row">
				<div className="admin-top-bar">
					<div className="admin-brand">
						<div className="brand-logo">T</div>
						<div className="brand-text">
							<h2>Admin Dashboard</h2>
						</div>
					</div>
				</div>
				<div className="admin-header">
					<div className="admin-welcome-inline">
						<h1>Welcome back, {displayName}! 👋</h1>
						<p>Here's what's happening with your platform today</p>
					</div>
					<button className="admin-logout-btn" onClick={logout}>Logout</button>
				</div>
			</div>
			<div className="admin-layout-wrapper">
				<div className="admin-sidebar">
					<nav className="sidebar-nav">
						<button className={`sidebar-item ${activeView === 'overview' ? 'active' : ''}`} onClick={() => setActiveView('overview')}>
							<span className="sidebar-icon">🏠</span>
							<span>Overview</span>
						</button>
						<button className={`sidebar-item ${activeView === 'hrs' ? 'active' : ''}`} onClick={() => setActiveView('hrs')}>
							<span className="sidebar-icon">👥</span>
							<span>HR's</span>
						</button>
						<button className={`sidebar-item ${activeView === 'managers' ? 'active' : ''}`} onClick={() => setActiveView('managers')}>
							<span className="sidebar-icon">👔</span>
							<span>Managers</span>
						</button>
						<button className={`sidebar-item ${activeView === 'teams' ? 'active' : ''}`} onClick={() => setActiveView('teams')}>
							<span className="sidebar-icon">🤝</span>
							<span>Teams</span>
						</button>
						<button className={`sidebar-item ${activeView === 'clients' ? 'active' : ''}`} onClick={() => setActiveView('clients')}>
							<span className="sidebar-icon">💼</span>
							<span>Clients</span>
						</button>
						<button className={`sidebar-item ${activeView === 'tasks' ? 'active' : ''}`} onClick={() => setActiveView('tasks')}>
							<span className="sidebar-icon">✓</span>
							<span>Tasks</span>
						</button>
						<button className={`sidebar-item ${activeView === 'profile' ? 'active' : ''}`} onClick={() => setActiveView('profile')}>
							<span className="sidebar-icon">⚙️</span>
							<span>Profile</span>
						</button>
					</nav>
				</div>
				<div className="admin-main">
					<div className="admin-content">
						{profile ? renderContent() : null}
					</div>
				</div>
			</div>
		</div>
	)
}
