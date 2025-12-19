# 🚀 DEPLOYMENT CHECKLIST

## ✅ Pre-Deployment
- [ ] All code committed to Git
- [ ] `.env` file is in `.gitignore` (✓ already done)
- [ ] MongoDB database is ready
- [ ] Test build locally: `npm run build:client`

## ✅ Render Deployment (RECOMMENDED - EASIEST)

### Step 1: Push to GitHub
```bash
git add .
git commit -m "Ready for deployment"
git push
```

### Step 2: Deploy on Render
1. Go to https://render.com/login
2. Sign up/login with GitHub
3. Click "New +" → "Blueprint"
4. Select your repository
5. Render detects `render.yaml` automatically
6. Click "Apply"

### Step 3: Add Environment Variables
Go to taskify-api service:
- `MONGO_URI`: mongodb+srv://username:password@cluster.mongodb.net/taskify
- `JWT_SECRET`: (auto-generated or set your own)

### Step 4: Wait for Deploy
- Both services will build and deploy
- Takes 5-10 minutes
- You'll get URLs for both frontend and backend

## ✅ Post-Deployment Testing
- [ ] Visit frontend URL
- [ ] Try to register a new admin
- [ ] Login with admin credentials
- [ ] Create a manager
- [ ] Create an HR
- [ ] Create teams
- [ ] Assign tasks
- [ ] Test file uploads
- [ ] Test all dashboards

## 🎉 That's It!
Your app is live with ALL functionality working!

## 📝 Your Live URLs (after deployment)
- Frontend: https://taskify-frontend.onrender.com
- Backend: https://taskify-api.onrender.com

## 💡 Important Notes
- Free tier spins down after 15min of inactivity
- First load after inactivity takes ~30 seconds
- All features work 100%
- No code changes needed!

## 🆘 Having Issues?
Check:
1. MongoDB connection string is correct
2. Environment variables are set in Render dashboard
3. Both services show "Live" status
4. Check service logs in Render dashboard
