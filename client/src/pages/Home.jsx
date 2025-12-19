import React from 'react'
import { Link } from 'react-router-dom'

export default function Home(){
	return (
		<main className="home-page">
			<div className="home-card">
				<div className="home-logo">T</div>
				<h1 className="home-title">TASKIFY</h1>
				<p className="home-subtitle">Transform the way your team works together</p>
				<p className="home-description">
					Streamline project management, enhance collaboration,
					and track every task from start to finish.
				</p>
				
				<div className="home-actions">
					<Link className="btn btn-primary" to="/user/login">
						<span>Sign In</span>
						<span className="btn-icon">→</span>
					</Link>
					<Link className="btn btn-secondary" to="/register">
						<span>Create Account</span>
					</Link>
				</div>
			</div>
		</main>
	)
}
