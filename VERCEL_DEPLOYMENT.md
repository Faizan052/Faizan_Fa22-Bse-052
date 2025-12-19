# Taskify - Vercel Deployment Guide

## Important: Deploy Frontend Only on Vercel

Since this is a full-stack application with a Node.js backend, you need to:

### 1. Deploy the Backend Separately
- Deploy `server.js` on a platform like **Render**, **Railway**, **Heroku**, or **DigitalOcean**
- Get your backend URL (e.g., `https://your-backend.onrender.com`)

### 2. Configure Vercel for Frontend

In your Vercel project settings:

**Build & Development Settings:**
- Build Command: `npm run vercel-build`
- Output Directory: `client/dist`
- Install Command: `npm install`

**Environment Variables:**
Add this environment variable in Vercel dashboard:
- `VITE_API_BASE_URL` = `https://your-backend-url.com` (your backend URL)

### 3. Deploy Steps

1. Push your code to GitHub
2. Import the project in Vercel
3. Set the environment variable `VITE_API_BASE_URL`
4. Deploy

### 4. Backend Deployment (Example with Render)

1. Create a new Web Service on Render
2. Connect your GitHub repo
3. Set:
   - Build Command: `npm install`
   - Start Command: `node server.js`
4. Add your MongoDB connection string and JWT secret as environment variables
5. Deploy

### Alternative: Deploy Both on Same Platform

Consider deploying both frontend and backend on **Render** or **Railway** which better support full-stack Node.js applications.
