import React from 'react'
import { Routes, Route, Link, Navigate } from 'react-router-dom'
import AdminLogin from './pages/AdminLogin'
import UserLogin from './pages/UserLogin'
import Register from './pages/Register'
import Home from './pages/Home'
import AdminDashboard from './pages/AdminDashboard'
import AdminProfile from './pages/AdminProfile'
import ManageHrs from './pages/ManageHrs'
import HRDashboard from './pages/HRDashboard'
import ManagerDashboard from './pages/ManagerDashboard'
import DeveloperDashboard from './pages/DeveloperDashboard'
import DesignerDashboard from './pages/DesignerDashboard'
import TesterDashboard from './pages/TesterDashboard'
import ClientDashboard from './pages/ClientDashboard'
import UserProfile from './pages/UserProfile'
import SubmitRequest from './pages/SubmitRequest'

function PrivateRoute({ children, adminOnly, disallowAdmin }){
  const token = localStorage.getItem('tm_token')
  const isAdmin = localStorage.getItem('tm_isAdmin') === 'true'
  if (!token) return <Navigate to={adminOnly ? '/admin/login' : '/user/login'} />
  if (adminOnly && !isAdmin) return <Navigate to='/' />
  if (disallowAdmin && isAdmin) return <Navigate to='/admin' />
  // allow admins to visit admin routes only
  return children
}

export default function App(){
  const isAuthenticated = !!localStorage.getItem('tm_token')
  return (
    <div>
      <Routes>
        <Route path="/admin/login" element={<AdminLogin/>} />
        <Route path="/user/login" element={<UserLogin/>} />
        <Route path="/register" element={<Register/>} />
        <Route path="/admin" element={<PrivateRoute adminOnly>{<AdminDashboard/>}</PrivateRoute>} />
        <Route path="/admin/profile" element={<PrivateRoute adminOnly>{<AdminProfile/>}</PrivateRoute>} />
        <Route path="/admin/manage-hrs" element={<PrivateRoute adminOnly>{<ManageHrs/>}</PrivateRoute>} />
        <Route path="/hr" element={<PrivateRoute>{<HRDashboard/>}</PrivateRoute>} />
        <Route path="/manager" element={<PrivateRoute>{<ManagerDashboard/>}</PrivateRoute>} />
    <Route path="/developer" element={<PrivateRoute>{<DeveloperDashboard/>}</PrivateRoute>} />
    <Route path="/designer" element={<PrivateRoute>{<DesignerDashboard/>}</PrivateRoute>} />
    <Route path="/tester" element={<PrivateRoute>{<TesterDashboard/>}</PrivateRoute>} />
  <Route path="/client" element={<PrivateRoute>{<ClientDashboard/>}</PrivateRoute>} />
  <Route path="/request/new" element={<PrivateRoute>{<SubmitRequest/>}</PrivateRoute>} />
        <Route path="/profile" element={<PrivateRoute disallowAdmin>{<UserProfile/>}</PrivateRoute>} />
        <Route path="/" element={<Home/>} />
      </Routes>
    </div>
  )
}
 