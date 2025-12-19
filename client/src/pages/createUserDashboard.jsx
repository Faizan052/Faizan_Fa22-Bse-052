import React, { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { apiFetch, clearSession, resolveAssetUrl, uploadWithProgress } from '../api'
import { useUserWorkspace } from '../hooks/useUserWorkspace'

const STATUS = {
	CLIENT_REQUESTED: 'Client Requested',
	AWAITING_MANAGER_ASSIGNMENT: 'Awaiting Manager Assignment',
	DESIGN_IN_PROGRESS: 'Design In Progress',
	DESIGN_SUBMITTED: 'Design Completed - Pending Manager Review',
	DEVELOPMENT_IN_PROGRESS: 'Development In Progress',
	DEVELOPMENT_SUBMITTED: 'Development Completed - Pending Manager Review',
	TESTING_IN_PROGRESS: 'Testing In Progress',
	TESTING_SUBMITTED: 'Testing Completed - Pending Manager Final Review',
	AWAITING_HR_REVIEW: 'Awaiting HR Review',
	AWAITING_CLIENT_REVIEW: 'Awaiting Client Review',
	CHANGES_REQUESTED: 'Changes Requested',
	COMPLETED: 'Completed'
}

const STAGE_KEY_BY_ROLE = {
	designer: 'designer',
	developer: 'developer',
	tester: 'tester'
}

const STAGE_LABEL_BY_KEY = {
	designer: 'Designer',
	developer: 'Developer',
	tester: 'Tester'
}

const ATTACHMENT_STAGE_LABEL = {
	'client-request': 'Client Request',
	design: 'Design',
	development: 'Development',
	testing: 'Testing',
	manager: 'Manager',
	hr: 'HR',
	'client-feedback': 'Client Feedback'
}

const NOTIFICATION_REFRESH_MS = 60000

const toId = (value) => {
	if (!value) return ''
	if (typeof value === 'string') return value
	if (typeof value === 'object' && value !== null) {
		return value._id || value.id || value.value || ''
	}
	return ''
}

const formatRole = (role) => (role ? role.charAt(0).toUpperCase() + role.slice(1) : '')

const formatPerson = (value) => {
	if (!value) return '—'
	if (typeof value === 'string') return 'Assigned'
	if (typeof value === 'object') {
		return value.name || value.username || value.email || '—'
	}
	return '—'
}

const formatSize = (size) => {
	if (typeof size !== 'number' || Number.isNaN(size)) return ''
	if (size < 1024) return `${size} B`
	if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`
	return `${(size / (1024 * 1024)).toFixed(1)} MB`
}

const formatSpeed = (bytesPerSecond) => {
	if (typeof bytesPerSecond !== 'number' || Number.isNaN(bytesPerSecond) || !Number.isFinite(bytesPerSecond)) {
		return ''
	}
	if (bytesPerSecond <= 0) return ''
	return `${formatSize(bytesPerSecond)}/s`
}

const stageStatusLabel = (value) => {
	switch (value) {
		case 'pending':
			return 'Pending'
		case 'in_progress':
			return 'In progress'
		case 'submitted':
			return 'Submitted'
		case 'approved':
			return 'Approved'
		case 'revisions':
			return 'Needs revisions'
		default:
			return value || 'Pending'
	}
}

export const createUserDashboard = ({ heading, role, allowTaskRequest = false }) => {
	return function UserDashboard() {
		const nav = useNavigate()
		const {
			profile,
			tasks,
			loading,
			error,
			setError,
			refresh,
			setTasks
		} = useUserWorkspace()

		const [message, setMessage] = useState('')
		const [uploadingTaskId, setUploadingTaskId] = useState('')
		const [actingTaskId, setActingTaskId] = useState('')
		const [uploadProgress, setUploadProgress] = useState({})
		const [notifications, setNotifications] = useState([])
		const [notificationsLoading, setNotificationsLoading] = useState(true)
		const [showNotifications, setShowNotifications] = useState(false)

		const taskList = useMemo(() => (Array.isArray(tasks) ? tasks : []), [tasks])
		const effectiveRole = role || (profile ? profile.role : '')
		const assignmentKey = STAGE_KEY_BY_ROLE[effectiveRole] || null
		const unreadCount = useMemo(() => notifications.filter((n) => !n.read).length, [notifications])
	const getTaskStatusStage = (status) => {
		const stages = {
			'Awaiting Manager Assignment': { stage: 'Pending Assignment', progress: 10, color: '#f59e0b' },
			'Design In Progress': { stage: 'Design Phase', progress: 25, color: '#3b82f6' },
			'Design Completed - Pending Manager Review': { stage: 'Design Review', progress: 35, color: '#8b5cf6' },
			'Development In Progress': { stage: 'Development Phase', progress: 50, color: '#10b981' },
			'Development Completed - Pending Manager Review': { stage: 'Dev Review', progress: 65, color: '#8b5cf6' },
			'Testing In Progress': { stage: 'Testing Phase', progress: 75, color: '#06b6d4' },
			'Testing Completed - Pending Manager Final Review': { stage: 'Final Review', progress: 85, color: '#8b5cf6' },
			'Awaiting HR Review': { stage: 'HR Review', progress: 90, color: '#f59e0b' },
			'Awaiting Client Review': { stage: 'Client Review', progress: 95, color: '#ec4899' },
			'Completed': { stage: 'Completed', progress: 100, color: '#22c55e' },
			'Changes Requested': { stage: 'Revisions Needed', progress: 40, color: '#ef4444' }
		}
		return stages[status] || { stage: status, progress: 0, color: '#6b7280' }
	}
		const formatDate = useCallback((value, withTime = false) => {
			if (!value) return '—'
			const date = new Date(value)
			if (Number.isNaN(date.getTime())) return '—'
			return withTime ? date.toLocaleString() : date.toLocaleDateString()
		}, [])

		const loadNotifications = useCallback(async () => {
			try {
				setNotificationsLoading(true)
				const data = await apiFetch('/api/user/notifications?limit=50')
				setNotifications(Array.isArray(data) ? data : [])
			} catch (err) {
				setError(err.message)
			} finally {
				setNotificationsLoading(false)
			}
		}, [setError])

		useEffect(() => {
			loadNotifications()
			const id = setInterval(() => {
				loadNotifications()
			}, NOTIFICATION_REFRESH_MS)
			return () => clearInterval(id)
		}, [loadNotifications])

		const logout = useCallback(() => {
			clearSession()
			nav('/user/login')
		}, [nav])

		const goProfile = useCallback(() => {
			nav('/profile')
		}, [nav])

		const goSubmitRequest = useCallback(() => {
			nav('/request/new')
		}, [nav])

		const assignmentBelongsToUser = useCallback((assignment) => {
			if (!profile) return false
			const assignedId = toId(assignment && assignment.user)
			return assignedId && assignedId === profile._id
		}, [profile])

		const getAssignment = useCallback((task) => {
			if (!assignmentKey) return null
			if (!task || !task.stageAssignments) return null
			return task.stageAssignments[assignmentKey] || null
		}, [assignmentKey])

		const updateTask = useCallback((updatedTask) => {
			setTasks((prev) => {
				const list = Array.isArray(prev) ? prev : []
				return list.map((task) => (task._id === updatedTask._id ? updatedTask : task))
			})
		}, [setTasks])

		const handleUpload = useCallback(async (taskId, file) => {
			if (!file) {
				setError('Choose a file before uploading')
				return
			}
			setMessage('')
			setError(null)
			setUploadingTaskId(taskId)
			const startedAt = Date.now()
			setUploadProgress(prev => ({
				...prev,
				[taskId]: {
					percent: 0,
					loaded: 0,
					total: file.size || 0,
					speed: 0
				}
			}))
			try {
				const formData = new FormData()
				formData.append('file', file)
				const data = await uploadWithProgress(`/api/user/tasks/${taskId}/attachments`, {
					body: formData,
					onProgress: (event) => {
						if (!event || !event.lengthComputable) return
						const elapsedSeconds = Math.max((Date.now() - startedAt) / 1000, 0.001)
						const percent = Math.min(100, Math.round((event.loaded / event.total) * 100))
						setUploadProgress(prev => ({
							...prev,
							[taskId]: {
								percent,
								loaded: event.loaded,
								total: event.total,
								speed: event.loaded / elapsedSeconds
							}
						}))
					}
				})
				if (data && data.task) {
					updateTask(data.task)
					setMessage('File uploaded successfully')
				} else {
					await refresh()
					setMessage('Upload finished')
				}
			} catch (err) {
				setError(err.message)
			} finally {
				setUploadProgress(prev => {
					const next = { ...prev }
					delete next[taskId]
					return next
				})
				setUploadingTaskId('')
			}
		}, [refresh, setError, updateTask])

		const handleClientAction = useCallback(async (taskId, action) => {
			const payload = { action }
			if (action === 'request-changes') {
				const comment = window.prompt('Describe the requested changes')
				if (!comment || !comment.trim()) return
				payload.comment = comment.trim()
			}
			setMessage('')
			setError(null)
			setActingTaskId(taskId)
			try {
				const updated = await apiFetch(`/api/user/tasks/${taskId}/status`, { method: 'PUT', body: payload })
				updateTask(updated)
				setMessage(action === 'approve' ? 'Task approved' : 'Change request sent')
			} catch (err) {
				setError(err.message)
			} finally {
				setActingTaskId('')
			}
		}, [setError, updateTask])

		const markNotificationRead = useCallback(async (id) => {
			try {
				await apiFetch(`/api/user/notifications/${id}/read`, { method: 'PUT' })
				setNotifications((prev) => prev.map((item) => (item._id === id ? { ...item, read: true } : item)))
			} catch (err) {
				setError(err.message)
			}
		}, [setError])

		const markAllNotificationsRead = useCallback(async () => {
			if (!notifications.length) return
			try {
				await apiFetch('/api/user/notifications/read', { method: 'PUT', body: { markAll: true } })
				setNotifications((prev) => prev.map((item) => ({ ...item, read: true })))
			} catch (err) {
				setError(err.message)
			}
		}, [notifications.length, setError])

		const queuedAssignments = useMemo(() => {
			if (!assignmentKey || !profile) return []
			return taskList.filter((task) => {
				const assignment = getAssignment(task)
				return assignmentBelongsToUser(assignment) && assignment.status === 'pending'
			})
		}, [assignmentBelongsToUser, assignmentKey, getAssignment, profile, taskList])

		const activeAssignments = useMemo(() => {
			if (!assignmentKey || !profile) return []
			return taskList.filter((task) => {
				const assignment = getAssignment(task)
				if (!assignmentBelongsToUser(assignment)) return false
				return ['in_progress', 'revisions'].includes(assignment.status)
			})
		}, [assignmentBelongsToUser, assignmentKey, getAssignment, profile, taskList])

		const awaitingManagerReview = useMemo(() => {
			if (!assignmentKey || !profile) return []
			return taskList.filter((task) => {
				const assignment = getAssignment(task)
				return assignmentBelongsToUser(assignment) && assignment.status === 'submitted'
			})
		}, [assignmentBelongsToUser, assignmentKey, getAssignment, profile, taskList])

		const completedAssignments = useMemo(() => {
			if (!assignmentKey || !profile) return []
			return taskList.filter((task) => {
				const assignment = getAssignment(task)
				return assignmentBelongsToUser(assignment) && assignment.status === 'approved'
			})
		}, [assignmentBelongsToUser, assignmentKey, getAssignment, profile, taskList])

		const clientQueued = useMemo(
			() => taskList.filter((task) => [
				STATUS.CLIENT_REQUESTED,
				STATUS.AWAITING_MANAGER_ASSIGNMENT,
				STATUS.CHANGES_REQUESTED
			].includes(task.status)),
			[taskList]
		)

		const clientInDelivery = useMemo(
			() => taskList.filter((task) => [
				STATUS.DESIGN_IN_PROGRESS,
				STATUS.DESIGN_SUBMITTED,
				STATUS.DEVELOPMENT_IN_PROGRESS,
				STATUS.DEVELOPMENT_SUBMITTED,
				STATUS.TESTING_IN_PROGRESS,
				STATUS.TESTING_SUBMITTED,
				STATUS.AWAITING_HR_REVIEW
			].includes(task.status)),
			[taskList]
		)

		const clientAwaitingReview = useMemo(
			() => taskList.filter((task) => task.status === STATUS.AWAITING_CLIENT_REVIEW),
			[taskList]
		)

		const clientCompleted = useMemo(
			() => taskList.filter((task) => task.status === STATUS.COMPLETED),
			[taskList]
		)

		const renderAttachmentList = useCallback((task) => {
			let files = Array.isArray(task.attachments) ? [...task.attachments] : []
			// For clients, only show files that are delivered as final results:
			// - files uploaded by HR (stage === 'hr')
			// - files uploaded during testing (stage === 'testing') but only when the task is awaiting client review or completed
			if (effectiveRole === 'client') {
				files = files.filter((file) => {
					if (!file || !file.stage) return false
					if (file.stage === 'hr') return true
					if (file.stage === 'testing') {
						return [STATUS.AWAITING_CLIENT_REVIEW, STATUS.COMPLETED].includes(task.status)
					}
					return false
				})
			}
			if (!files.length) return <div className="help">No files available for download</div>
			files.sort((a, b) => {
				const aTime = new Date(a.uploadedAt || a.createdAt || 0).getTime()
				const bTime = new Date(b.uploadedAt || b.createdAt || 0).getTime()
				return bTime - aTime
			})
			return (
				<ul style={{ marginTop: 6 }}>
					{files.map((file) => (
						<li key={file._id || file.filename}>
							<a href={resolveAssetUrl(`/uploads/${file.filename}`)} target="_blank" rel="noreferrer">{file.originalName}</a>
							{formatSize(file.size) ? <span style={{ marginLeft: 6, color: '#555' }}>{formatSize(file.size)}</span> : null}
							<span style={{ marginLeft: 6, color: '#555' }}>— {ATTACHMENT_STAGE_LABEL[file.stage] || file.stage}</span>
							<span style={{ marginLeft: 6, color: '#999', fontSize: 12 }}>{formatDate(file.uploadedAt || file.createdAt, true)}</span>
							{file.uploadedBy ? <span style={{ marginLeft: 6, color: '#777', fontSize: 12 }}>by {formatPerson(file.uploadedBy)}</span> : null}
						</li>
					))}
				</ul>
			)
		}, [formatDate, formatPerson])

		const renderChangeRequests = useCallback((task) => {
			const changes = Array.isArray(task.changeRequests) ? task.changeRequests : []
			if (!changes.length) return null
			return (
				<details style={{ marginTop: 10 }}>
					<summary>Change requests</summary>
					<ul>
						{changes.slice().reverse().map((item, idx) => (
							<li key={idx} style={{ fontSize: 13 }}>
								{item.comment}
								<span style={{ marginLeft: 6, color: '#777' }}>{formatDate(item.createdAt, true)}</span>
							</li>
						))}
					</ul>
				</details>
			)
		}, [formatDate])

			const renderStageSnapshot = useCallback((task) => {
			const stageAssignments = task && task.stageAssignments ? task.stageAssignments : {}
			const rows = Object.entries(STAGE_LABEL_BY_KEY)
				.map(([key, label]) => {
					const info = stageAssignments[key] || {}
					const hasData = info.user || info.status || info.submittedAt
					if (!hasData) return null
					return (
						<li key={key} style={{ fontSize: 13 }}>
							<strong>{label}</strong>: {formatPerson(info.user)} — {stageStatusLabel(info.status)}
							{info.submittedAt ? <span style={{ marginLeft: 6, color: '#777' }}>submitted {formatDate(info.submittedAt, true)}</span> : null}
						</li>
					)
				})
				.filter(Boolean)
			if (!rows.length) {
				return <div className="help">No stage updates yet.</div>
			}
			return <ul>{rows}</ul>
			}, [formatDate, formatPerson, stageStatusLabel])

		const renderAssignmentSection = useCallback((title, collection, { allowUpload: allowUploadInSection = false } = {}) => {
			if (!collection.length) return null
			return (
				<div className="dashboard-section">
					<h2 className="dashboard-section-title">{title}</h2>
					<div className="items-list">
						{collection.map((task) => {
							const assignment = getAssignment(task) || {}
							const isUploading = uploadingTaskId === task._id
							const progress = uploadProgress[task._id]
							return (
								<div key={task._id} className="item-card">
									<div className="item-title">{task.title}</div>
									<div className="item-meta">Project status: <span className="status-badge">{task.status}</span></div>
									<div className="item-meta">Stage status: <span className="status-badge">{stageStatusLabel(assignment.status)}</span></div>
									<div className="item-meta">Project due: {formatDate(task.deadline)}{assignment.deadline ? ` — Stage due: ${formatDate(assignment.deadline)}` : ''}</div>
									<div className="item-meta">Manager: {formatPerson(task.manager)} | Team: {task.assignedTeam ? task.assignedTeam.name : '—'}</div>
									{allowUploadInSection ? (
										<div style={{ marginTop: 12, display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
											<input
												type="file"
												onChange={(e) => {
													const file = e.target.files && e.target.files[0]
													if (file) {
														handleUpload(task._id, file)
													}
													e.target.value = ''
												}}
												disabled={isUploading}
											/>
											{assignment.submittedAt ? <span className="item-meta">Last submitted {formatDate(assignment.submittedAt, true)}</span> : null}
											{isUploading && !progress ? <span className="item-meta">Uploading...</span> : null}
										</div>
									) : null}
									{progress ? (
										<div style={{ width: '100%', marginTop: 12 }}>
											<div style={{ height: 8, background: '#f0f0f0', borderRadius: 4, overflow: 'hidden' }}>
												<div style={{ width: `${progress.percent}%`, height: '100%', background: 'var(--accent)', transition: 'width 0.2s ease', borderRadius: 4 }} />
											</div>
											<div className="item-meta" style={{ marginTop: 8 }}>
												Uploaded {formatSize(progress.loaded)} of {formatSize(progress.total)} ({progress.percent || 0}%)
												{progress.speed ? ` — ${formatSpeed(progress.speed)}` : ''}
											</div>
										</div>
									) : null}
									{renderChangeRequests(task)}
									<details style={{ marginTop: 12 }}>
										<summary>Attachments</summary>
										{renderAttachmentList(task)}
									</details>
									{Array.isArray(task.history) && task.history.length ? (
										<details style={{ marginTop: 12 }}>
											<summary>History</summary>
											<ul>
												{task.history.slice().reverse().map((entry, idx) => (
													<li key={idx} style={{ fontSize: 13 }}>
														<span style={{ fontWeight: 'bold' }}>{entry.status || ''}</span>
														{entry.note ? <span style={{ marginLeft: 6 }}>{entry.note}</span> : null}
														<span style={{ marginLeft: 6, color: '#777' }}>{formatDate(entry.createdAt, true)}</span>
													</li>
												))}
											</ul>
										</details>
									) : null}
								</div>
							)
						})}
					</div>
				</div>
			)
		}, [formatDate, formatPerson, formatSpeed, getAssignment, handleUpload, renderAttachmentList, renderChangeRequests, stageStatusLabel, uploadProgress, uploadingTaskId])

		const renderClientTasks = useCallback(() => (
			<>
				<div className="dashboard-section">
					<h2 className="dashboard-section-title">Submitted Requests</h2>
					{clientQueued.length ? (
						<div className="items-list">
							{clientQueued.map((task) => (
								<div key={task._id} className="item-card">
									<div className="item-title">{task.title}</div>
									<div className="item-meta">Status: <span className="status-badge">{task.status}</span> — Requested {formatDate(task.createdAt, true)}</div>
									<div className="item-meta">Manager: {formatPerson(task.manager)}</div>
									{renderChangeRequests(task)}
									<details style={{ marginTop: 12 }}>
										<summary>Attachments</summary>
										{renderAttachmentList(task)}
									</details>
								</div>
							))}
						</div>
					) : <div className="help">No pending requests.</div>}
				</div>

				<div className="dashboard-section">
					<h2 className="dashboard-section-title">In Delivery</h2>
					{clientInDelivery.length ? (
						<div className="items-list">
							{clientInDelivery.map((task) => (
								<div key={task._id} className="item-card">
									<div className="item-title">{task.title}</div>
									<div className="item-meta">Current status: <span className="status-badge">{task.status}</span> — Manager {formatPerson(task.manager)}</div>
									<details style={{ marginTop: 12 }}>
										<summary>Stage progress</summary>
										{renderStageSnapshot(task)}
									</details>
									<details style={{ marginTop: 12 }}>
										<summary>Attachments</summary>
										{renderAttachmentList(task)}
									</details>
								</div>
							))}
						</div>
					) : <div className="help">No active deliveries right now.</div>}
				</div>

				<div className="dashboard-section">
					<h2 className="dashboard-section-title">Awaiting Your Review</h2>
					{clientAwaitingReview.length ? (
						<div className="items-list">
							{clientAwaitingReview.map((task) => {
								const isActing = actingTaskId === task._id
								return (
									<div key={task._id} className="item-card">
										<div className="item-title">{task.title}</div>
										<div className="item-meta">Delivered {formatDate(task.updatedAt || task.deadline, true)} — Manager {formatPerson(task.manager)}</div>
										<div style={{ marginTop: 12, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
											<button className="btn small" onClick={() => handleClientAction(task._id, 'approve')} disabled={isActing}>{isActing ? 'Processing...' : 'Approve'}</button>
											<button className="btn btn-outline small" onClick={() => handleClientAction(task._id, 'request-changes')} disabled={isActing}>{isActing ? 'Processing...' : 'Request changes'}</button>
										</div>
										<details style={{ marginTop: 12 }}>
											<summary>Stage progress</summary>
											{renderStageSnapshot(task)}
										</details>
										<details style={{ marginTop: 12 }}>
											<summary>Deliverables</summary>
											{renderAttachmentList(task)}
										</details>
										{renderChangeRequests(task)}
									</div>
								)
							})}
						</div>
					) : <div className="help">No tasks need your approval.</div>}
				</div>

				<div className="dashboard-section">
					<h2 className="dashboard-section-title">Completed Projects</h2>
					{clientCompleted.length ? (
						<div className="table-container">
							<table className="data-table">
								<thead>
									<tr>
										<th>Title</th>
										<th>Completed</th>
										<th>Manager</th>
									</tr>
								</thead>
								<tbody>
									{clientCompleted.map((task) => (
										<tr key={task._id}>
											<td>{task.title}</td>
											<td>{formatDate(task.updatedAt || task.deadline, true)}</td>
											<td>{formatPerson(task.manager)}</td>
										</tr>
									))}
								</tbody>
							</table>
						</div>
					) : <div className="help">No completed projects yet.</div>}
				</div>
			</>
		), [actingTaskId, clientAwaitingReview, clientCompleted, clientInDelivery, clientQueued, formatDate, formatPerson, handleClientAction, renderAttachmentList, renderChangeRequests, renderStageSnapshot])

		const renderRoleAssignments = useCallback(() => (
			<>
				{renderAssignmentSection('Queued Assignments', queuedAssignments)}
				{renderAssignmentSection('Active Assignments', activeAssignments, { allowUpload: true })}
				{renderAssignmentSection('Waiting For Manager Review', awaitingManagerReview)}
				{renderAssignmentSection('Approved Deliveries', completedAssignments)}
			</>
		), [activeAssignments, awaitingManagerReview, completedAssignments, queuedAssignments, renderAssignmentSection])

		const displayName = profile ? profile.name || profile.email || 'User' : 'User'
		const roleLabel = formatRole(effectiveRole)

		const [activeView, setActiveView] = React.useState('tasks')

		return (
			<div className="user-dashboard-fullscreen">
				<div className="user-header-row">
					<div className="user-top-bar">
						<div className="user-brand">
							<div className="user-brand-logo">T</div>
							<div className="user-brand-text">
								<h2>{roleLabel || role} Dashboard</h2>
							</div>
						</div>
					</div>
					<div className="user-header">
						<div className="user-welcome-inline">
							<h1>Welcome, {displayName}! 👋</h1>
							<p style={{fontSize: '15px', color: '#64748b', marginTop: '8px', fontWeight: 500}}>
								Ready to make great things happen today! Let's turn your tasks into achievements.
							</p>
						</div>
						<div className="user-header-actions">
							<button className="btn" onClick={logout}>Sign out</button>
						</div>
					</div>
				</div>
				<div className="user-layout-wrapper">
					<div className="user-sidebar">
						<nav className="user-sidebar-nav">
							<button className={`user-sidebar-item ${activeView === 'overview' ? 'active' : ''}`} onClick={() => setActiveView('overview')}>
								<span className="user-sidebar-icon">🏠</span>
								<span>Overview</span>
							</button>
							<button className={`user-sidebar-item ${activeView === 'tasks' ? 'active' : ''}`} onClick={() => setActiveView('tasks')}>
								<span className="user-sidebar-icon">✓</span>
								<span>My Tasks</span>
							</button>
							{allowTaskRequest && (
								<button className={`user-sidebar-item ${activeView === 'submit' ? 'active' : ''}`} onClick={() => setActiveView('submit')}>
									<span className="user-sidebar-icon">➕</span>
									<span>Submit Request</span>
								</button>
							)}
							<button className={`user-sidebar-item ${activeView === 'progress' ? 'active' : ''}`} onClick={() => setActiveView('progress')}>
								<span className="user-sidebar-icon">📊</span>
								<span>Task Progress</span>
							</button>
							<button className={`user-sidebar-item ${activeView === 'notifications' ? 'active' : ''}`} onClick={() => setActiveView('notifications')}>
								<span className="user-sidebar-icon">🔔</span>
								<span>Notifications{unreadCount ? ` (${unreadCount})` : ''}</span>
							</button>
							<button className={`user-sidebar-item ${activeView === 'profile' ? 'active' : ''}`} onClick={() => setActiveView('profile')}>
								<span className="user-sidebar-icon">👤</span>
								<span>Profile</span>
							</button>
						</nav>
					</div>
					<div className="user-main">
						<div className="user-content">
							{/* OVERVIEW VIEW */}
							{activeView === 'overview' ? (
								<>
									<div className="stats-grid">
										<div className="stat-card">
											<div className="stat-card-label">Total Tasks</div>
											<div className="stat-card-value">{taskList.length}</div>
											<div className="stat-card-description">All assigned tasks</div>
										</div>
										<div className="stat-card">
											<div className="stat-card-label">Active</div>
											<div className="stat-card-value">
												{taskList.filter(t => t.status !== STATUS.COMPLETED && t.status !== STATUS.AWAITING_CLIENT_REVIEW).length}
											</div>
											<div className="stat-card-description">Currently in progress</div>
										</div>
										<div className="stat-card">
											<div className="stat-card-label">Awaiting Review</div>
											<div className="stat-card-value">
												{taskList.filter(t => {
													const assignment = getAssignment(t)
													return assignment && assignment.status === 'submitted'
												}).length}
											</div>
											<div className="stat-card-description">Submitted for review</div>
										</div>
										<div className="stat-card">
											<div className="stat-card-label">Completed</div>
											<div className="stat-card-value">
												{taskList.filter(t => t.status === STATUS.COMPLETED).length}
											</div>
											<div className="stat-card-description">Successfully finished</div>
										</div>
									</div>
								</>
							) : null}

							{/* TASK PROGRESS VIEW */}
							{activeView === 'progress' ? (
								<div className="dashboard-section">
									<div className="dashboard-section-header">
										<h3 className="dashboard-section-title">My Task Progress</h3>
										<span style={{fontSize: 14, color: '#64748b', fontWeight: 500}}>
									{taskList.length} Total Tasks
								</span>
							</div>
							{taskList.length > 0 ? (
								<div style={{display: 'grid', gap: 20}}>
									{taskList.map(task => {
										const stageInfo = getTaskStatusStage(task.status)
										return (
											<div 
												key={task._id} 
												className="item-card" 
												style={{
													position: 'relative',
													overflow: 'hidden',
													background: '#fff',
													border: '2px solid #e2e8f0'
												}}
											>
												<div 
													style={{
														position: 'absolute',
														top: 0,
														left: 0,
														bottom: 0,
														width: `${stageInfo.progress}%`,
														background: `linear-gradient(90deg, ${stageInfo.color}15, ${stageInfo.color}05)`,
														transition: 'width 1s ease-in-out'
													}}
												/>
												<div style={{position: 'relative', zIndex: 1}}>
													<div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16}}>
														<h4 className="item-title" style={{margin: 0, flex: 1}}>{task.title}</h4>
														<span 
															className="status-badge" 
															style={{
																background: `${stageInfo.color}20`,
																color: stageInfo.color,
																border: `2px solid ${stageInfo.color}`,
																fontWeight: 600,
																fontSize: 13
															}}
														>
															{stageInfo.stage}
														</span>
															</div>
															<div style={{
																padding: 12,
																background: '#f8fafc',
																borderRadius: 8,
																marginBottom: 12,
																border: '1px solid #e2e8f0'
															}}>
																<div style={{fontSize: 13, fontWeight: 600, color: '#1e293b', marginBottom: 6}}>
																	Current Status
																</div>
																<div style={{fontSize: 14, color: '#475569', fontWeight: 500}}>
																	{task.status}
																</div>
															</div>
															<div style={{marginBottom: 12}}>
																<div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6}}>
																	<span style={{fontSize: 13, fontWeight: 600, color: '#475569'}}>Progress</span>
																	<span style={{fontSize: 13, fontWeight: 700, color: stageInfo.color}}>{stageInfo.progress}%</span>
																</div>
																<div style={{
																	width: '100%',
																	height: 10,
																	background: '#e2e8f0',
																	borderRadius: 20,
																	overflow: 'hidden',
																	boxShadow: `0 0 0 2px ${stageInfo.color}20`
																}}>
																	<div style={{
																		width: `${stageInfo.progress}%`,
																		height: '100%',
																		background: `linear-gradient(90deg, ${stageInfo.color}, ${stageInfo.color}dd)`,
																		borderRadius: 20,
																		transition: 'width 1s ease-in-out',
																		boxShadow: `0 0 10px ${stageInfo.color}80`
																	}} />
																</div>
															</div>
															{task.deadline && (
																<div style={{
																	padding: 12,
																	background: '#f8fafc',
																	borderRadius: 8,
																	fontSize: 13,
																	color: '#64748b'
																}}>
																	<strong>Deadline:</strong> {formatDate(task.deadline)}
																</div>
															)}
														</div>
													</div>
												)
											})}
										</div>
									) : (
										<p style={{color: 'var(--muted)', padding: '24px', textAlign: 'center', background: '#f8fafc', borderRadius: '12px'}}>
											No tasks to track.
										</p>
									)}
								</div>
							) : null}

							{/* PROFILE VIEW */}
							{activeView === 'profile' ? (
								<div className="dashboard-section">
									<div className="dashboard-section-header">
										<h3 className="dashboard-section-title">My Profile</h3>
									</div>
									<div style={{maxWidth: 600, margin: '0 auto'}}>
										<div style={{
											textAlign: 'center',
											marginBottom: 32,
											padding: 24,
											background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
											borderRadius: 16
										}}>
											<div style={{
												width: 120,
												height: 120,
												margin: '0 auto 16px',
												borderRadius: '50%',
												background: 'white',
												display: 'flex',
												alignItems: 'center',
												justifyContent: 'center',
												fontSize: 48,
												fontWeight: 700,
												color: '#667eea',
												border: '4px solid white',
												boxShadow: '0 8px 24px rgba(0,0,0,0.15)'
											}}>
												{displayName?.charAt(0)?.toUpperCase() || 'U'}
											</div>
											<h2 style={{margin: '0 0 8px 0', color: 'white', fontSize: 28}}>{displayName}</h2>
											<p style={{margin: 0, color: 'rgba(255,255,255,0.9)', fontSize: 16}}>{roleLabel}</p>
										</div>

										<div style={{background: '#fff', padding: 32, borderRadius: 16, border: '2px solid #e2e8f0', boxShadow: '0 4px 16px rgba(0,0,0,0.08)'}}>
											<div style={{marginBottom: 24}}>
												<label style={{display: 'block', marginBottom: 8, fontSize: 14, fontWeight: 600, color: '#1e293b'}}>
													Name
												</label>
												<div style={{padding: '12px 16px', fontSize: 15, border: '2px solid #e2e8f0', borderRadius: 8, background: '#f8fafc'}}>
													{profile?.name || '—'}
												</div>
											</div>
											<div style={{marginBottom: 24}}>
												<label style={{display: 'block', marginBottom: 8, fontSize: 14, fontWeight: 600, color: '#1e293b'}}>
													Email
												</label>
												<div style={{padding: '12px 16px', fontSize: 15, border: '2px solid #e2e8f0', borderRadius: 8, background: '#f8fafc'}}>
													{profile?.email || '—'}
												</div>
											</div>
											<div style={{marginBottom: 24}}>
												<label style={{display: 'block', marginBottom: 8, fontSize: 14, fontWeight: 600, color: '#1e293b'}}>
													Role
												</label>
												<div style={{padding: '12px 16px', fontSize: 15, border: '2px solid #e2e8f0', borderRadius: 8, background: '#f8fafc'}}>
													{roleLabel}
												</div>
											</div>
											<div style={{
												padding: 16,
												background: '#fef3c7',
												border: '2px solid #fbbf24',
												borderRadius: 8,
												marginTop: 24,
												fontSize: 13,
												color: '#92400e'
											}}>
												<strong>🔒 Security Notice:</strong> To update your profile information or change your password, please contact your administrator.
											</div>
										</div>
									</div>
								</div>
							) : null}

							{activeView === 'submit' && allowTaskRequest ? (
								<div className="dashboard-section">
									<h2 className="dashboard-section-title">Submit New Project Request</h2>
									<button className="btn" onClick={goSubmitRequest}>Create Request</button>
								</div>
							) : null}

							{activeView === 'notifications' ? (
								<div className="dashboard-section">
									<div className="dashboard-section-header">
										<h2 className="dashboard-section-title">Notifications</h2>
										<button className="btn small" onClick={markAllNotificationsRead} disabled={notificationsLoading || !notifications.length}>Mark all read</button>
									</div>
									{notificationsLoading ? <div>Loading notifications...</div> : (
										notifications.length ? (
											<div className="items-list">
												{notifications.map((item) => (
													<div key={item._id} className="item-card" style={{ opacity: item.read ? 0.7 : 1 }}>
														<div className="item-title">{item.message}</div>
														<div className="item-meta">
															{item.task && item.task.title ? `Task: ${item.task.title}` : ''}
															{item.stage ? ` ${item.stage}` : ''}
															<span style={{ marginLeft: 6 }}>{formatDate(item.createdAt, true)}</span>
														</div>
														{!item.read ? (
															<button className="btn small" style={{ marginTop: 6 }} onClick={() => markNotificationRead(item._id)}>Mark read</button>
														) : null}
													</div>
												))}
											</div>
										) : <div className="help">No notifications</div>
									)}
								</div>
							) : null}

							{activeView === 'tasks' ? (
								<>
									{message ? <div className="success-message">{message}</div> : null}
									{error ? <div className="error">{error}</div> : null}
									{loading ? <div>Loading workspace...</div> : null}

									{!loading && profile ? (
										effectiveRole === 'client' ? renderClientTasks() : renderRoleAssignments()
									) : null}
								</>
							) : null}
						</div>
					</div>
				</div>
			</div>
		)
	}
}

