# 📋 Taskify - Complete Task Management System

A full-stack task management application with role-based dashboards for Admin, HR, Manager, and Client users (Designer, Developer, Tester).

## 🚀 Quick Deploy (EASIEST METHOD)

**Deploy on Render (keeps ALL functionality):**

1. **Push to GitHub** (if not done)
2. **Go to [Render.com](https://render.com)** and sign up
3. **Click "New +" → "Blueprint"**
4. **Select your GitHub repo**
5. **Add environment variables** (MongoDB URI)
6. **Click "Apply"** - Done! ✅

📖 **Step-by-step guide:** [DEPLOY_CHECKLIST.md](DEPLOY_CHECKLIST.md)
📚 **More options:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 🏃 Local Development

```bash
# 1. Install dependencies
npm install
cd client && npm install && cd ..

# 2. Setup environment
cp .env.example .env
# Edit .env with your MongoDB URI and JWT_SECRET

# 3. Run dev mode (backend + frontend)
npm run dev:all
```

- **Frontend:** http://localhost:5173
- **Backend:** http://localhost:3000

---

## 👥 User Roles

- **Admin** - System administration, create managers/HR
- **HR** - HR management, final task approvals
- **Manager** - Team management, task assignments
- **Designer** - Design phase tasks
- **Developer** - Development phase tasks
- **Tester** - Testing phase tasks

---

## ✨ Key Features

✅ Role-based authentication & dashboards
✅ Complete task workflow (Design → Dev → Test → Review)
✅ Team & member management
✅ File uploads for tasks
✅ Real-time notifications
✅ Task progress tracking with animated visuals
✅ User profile management

---

## 🔧 Tech Stack

**Frontend:** React 18, React Router, Vite
**Backend:** Node.js, Express, MongoDB, JWT, Multer

---

## 📚 All Documentation

- **[DEPLOY_CHECKLIST.md](DEPLOY_CHECKLIST.md)** - Complete deployment checklist
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Multiple deployment methods
- **[VERCEL_DEPLOYMENT.md](VERCEL_DEPLOYMENT.md)** - Vercel-specific instructions

---

## 🆘 Troubleshooting

**Build fails?**
```bash
npm run build:client
```

**Blank page after deploy?**
- Make sure you deployed BOTH frontend and backend
- Check environment variables are set
- Use Render Blueprint for automatic setup

**MongoDB connection issues?**
- Verify connection string format
- Check database user permissions
- Whitelist all IPs (0.0.0.0/0) in MongoDB Atlas

---

Made with ❤️ for efficient project management
