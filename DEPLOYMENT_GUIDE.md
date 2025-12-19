# 🚀 Deploy Taskify - Complete Guide

## ✅ EASIEST METHOD: Deploy on Render (Recommended)

Render supports full-stack Node.js apps - your entire project will work perfectly!

### Step-by-Step:

1. **Push to GitHub** (if not already done)
   ```bash
   git init
   git add .
   git commit -m "Ready for deployment"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/taskify.git
   git push -u origin main
   ```

2. **Sign up at Render.com**
   - Go to https://render.com
   - Sign up with GitHub

3. **Create New Blueprint**
   - Click "New" → "Blueprint"
   - Connect your GitHub repository
   - Render will automatically detect `render.yaml`
   - Click "Apply"

4. **Set Environment Variables**
   - Go to your backend service (taskify-api)
   - Click "Environment"
   - Add:
     - `MONGO_URI`: Your MongoDB connection string
     - `JWT_SECRET`: (auto-generated or set your own)

5. **Done! 🎉**
   - Backend will be at: `https://taskify-api.onrender.com`
   - Frontend will be at: `https://taskify-frontend.onrender.com`
   - All features work automatically!

---

## 📋 Alternative: Manual Setup on Render

If you don't want to use the Blueprint:

### Backend Service:
1. New Web Service
2. Build Command: `npm install`
3. Start Command: `node server.js`
4. Add environment variables

### Frontend Service:
1. New Static Site
2. Build Command: `cd client && npm install && npm run build`
3. Publish Directory: `client/dist`
4. Add `VITE_API_BASE_URL` = your backend URL

---

## 🔧 Environment Variables You Need

### Backend (on Render):
- `MONGO_URI` - Your MongoDB connection string
- `JWT_SECRET` - Any random secure string
- `PORT` - 3000 (already set)

### Frontend (on Render):
- `VITE_API_BASE_URL` - Your backend URL (e.g., `https://taskify-api.onrender.com`)

---

## 🌐 Deploy on Vercel (Frontend Only)

If you already deployed backend elsewhere:

1. **Deploy Frontend:**
   ```bash
   vercel
   ```

2. **Add Environment Variable:**
   - In Vercel dashboard → Settings → Environment Variables
   - Add: `VITE_API_BASE_URL` = your backend URL

3. **Redeploy**

---

## ⚡ Quick MongoDB Setup (if needed)

1. Go to https://www.mongodb.com/cloud/atlas
2. Create free cluster
3. Create database user
4. Get connection string
5. Replace `<password>` with your password
6. Use this as `MONGO_URI`

---

## 🎯 What Happens After Deployment

✅ All your dashboards work (Admin, HR, Manager, Designer, Developer, Tester)
✅ User authentication works
✅ File uploads work
✅ All CRUD operations work
✅ Task management flows work
✅ Notifications work

**No functionality is lost!**
