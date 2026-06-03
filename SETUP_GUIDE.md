# 🚀 TWINE — Complete Setup & Deployment Guide

## What You Have Built
- **Backend**: NestJS API with 15 modules (Auth, Chat, Games, AI, Couples, Gamification, Subscriptions, Notifications, Location, Admin...)
- **Realtime**: Socket.IO gateway for live chat, games, presence, location
- **Frontend**: Flutter app (iOS + Android + Web) with full UI
- **Database**: PostgreSQL + Redis
- **Deploy target**: Railway.app (free tier available)

---

## STEP 1 — Install Tools on Your Computer

### On Windows:
1. Install **Node.js 20**: https://nodejs.org
2. Install **Flutter**: https://docs.flutter.dev/get-started/install/windows
3. Install **Git**: https://git-scm.com
4. Install **Android Studio**: https://developer.android.com/studio (for Android phone)

### On Mac:
```bash
brew install node git
# Flutter: https://docs.flutter.dev/get-started/install/macos
```

---

## STEP 2 — Set Up Railway (Free Database + Hosting)

1. Go to **https://railway.app** → Sign up (free, use GitHub login)
2. Click **"New Project"**
3. Click **"Add Service"** → choose **PostgreSQL**
   - Click the PostgreSQL service → **"Connect"** tab
   - Copy the **"DATABASE_URL"** (looks like `postgresql://postgres:xxxxx@xxx.railway.app:5432/railway`)
4. Click **"Add Service"** again → choose **Redis**
   - Click the Redis service → **"Connect"** tab
   - Copy the **"REDIS_URL"** (looks like `redis://default:xxxxx@xxx.railway.app:6379`)
5. Click **"Add Service"** again → choose **"Deploy from GitHub repo"**
   - Connect your GitHub account
   - Select the repo containing this code
   - Set **Root Directory** to `backend`
   - Railway will auto-detect NestJS

---

## STEP 3 — Configure Environment Variables on Railway

In your Railway backend service → **"Variables"** tab, add:

```
PORT=3000
NODE_ENV=production
DATABASE_URL=<paste from Step 2>
REDIS_URL=<paste from Step 2>
JWT_SECRET=<generate: open terminal, run: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))">
JWT_REFRESH_SECRET=<generate another one the same way>
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
OPENAI_API_KEY=sk-... (get from https://platform.openai.com/api-keys — optional, AI works with fallbacks)
STRIPE_SECRET_KEY=sk_test_... (get from https://dashboard.stripe.com — optional for now)
ALLOWED_ORIGINS=*
```

---

## STEP 4 — Deploy the Backend

### Option A — Via Railway GitHub (recommended):
1. Push this code to a GitHub repo
2. Railway auto-deploys on every push
3. After deploy, click your service → **"Settings"** → **"Domains"** → Generate domain
4. You get a URL like: `https://twine-api-production.up.railway.app`

### Option B — Deploy manually right now (no GitHub needed):

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Go to backend folder
cd /path/to/twine/backend

# Copy env file
cp .env.example .env
# Edit .env with your Railway PostgreSQL and Redis URLs

# Link to your Railway project
railway link

# Deploy
railway up
```

---

## STEP 5 — Verify Backend is Running

Open your Railway domain in browser:
- **Health**: `https://your-domain.railway.app/api/v1/auth/me` → should return 401 (good, means it's running)
- **Swagger docs**: `https://your-domain.railway.app/api/docs` → full interactive API docs

---

## STEP 6 — Connect Flutter App to Your Backend

Edit the file: `frontend/lib/core/providers/api_client.dart`

Change this line:
```dart
static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api/v1');
```
To:
```dart
static const String baseUrl = 'https://YOUR-RAILWAY-DOMAIN.railway.app/api/v1';
```

Also in `frontend/lib/core/providers/socket_service.dart`:
```dart
static const String wsUrl = 'https://YOUR-RAILWAY-DOMAIN.railway.app';
```

---

## STEP 7 — Run on Your Android Phone

```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Check your phone is connected (enable Developer Mode + USB Debugging on phone)
flutter devices

# Run on your phone
flutter run

# Build APK to install directly
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
# Transfer this APK to your phone and install it
```

### Enable Developer Mode on Android:
1. Settings → About Phone → tap **"Build Number"** 7 times
2. Settings → Developer Options → Enable **"USB Debugging"**
3. Connect phone to computer via USB → allow debugging

---

## STEP 8 — Build for iOS (Mac only)

```bash
cd frontend
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode and deploy
```

---

## STEP 9 — Test the Full Flow

1. Register two accounts (on two phones or two browser tabs on web)
2. Account 1: go to Couple tab → "Generate Invite" → copy code
3. Account 2: go to Couple tab → "Enter Code" → paste → connect
4. Now chat, play games, and see AI insights!

---

## Local Development (Run Everything Locally)

### Start databases with Docker:
```bash
# Install Docker Desktop: https://docker.com
cd /path/to/twine
docker-compose up -d  # starts PostgreSQL + Redis locally
```

### Start backend:
```bash
cd backend
cp .env.example .env
# Edit .env: set DATABASE_URL=postgresql://twine_user:twine_password@localhost:5432/twine_db
#            set REDIS_URL=redis://localhost:6379
npm run start:dev
# API runs at http://localhost:3000
```

### Start Flutter:
```bash
cd frontend
flutter pub get
flutter run
```

---

## Credentials Needed (Summary)

| Credential | Where to Get | Required? |
|---|---|---|
| Railway account | railway.app (free) | YES |
| PostgreSQL URL | Auto from Railway | YES |
| Redis URL | Auto from Railway | YES |
| JWT_SECRET | `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"` | YES |
| JWT_REFRESH_SECRET | Same command again | YES |
| OpenAI API Key | platform.openai.com | Optional (AI works with fallbacks) |
| Stripe Key | dashboard.stripe.com | Optional (subscriptions) |
| Google Maps Key | console.cloud.google.com | Optional (location features) |

---

## Troubleshooting

**"Cannot connect to server"** → Check ALLOWED_ORIGINS in Railway env vars, set to `*` for now

**"Database error"** → Make sure DATABASE_URL is correct in Railway variables

**Flutter build fails** → Run `flutter doctor` to check your setup

**App won't install on phone** → Enable "Install from unknown sources" in phone settings

---

## What's Already Built & Production-Ready

✅ JWT Auth with refresh token rotation  
✅ Argon2id password hashing  
✅ Couple pairing with invite codes  
✅ Realtime chat (Socket.IO)  
✅ 5 multiplayer games (Tic Tac Toe, Chess, Quiz, Truth/Dare, Ludo)  
✅ AI insights + daily questions (OpenAI GPT-4o-mini)  
✅ Bond meter + streaks + XP system  
✅ Subscription management (Stripe-ready)  
✅ Push notification architecture (FCM-ready)  
✅ Admin panel endpoints  
✅ GDPR account deletion  
✅ Full Swagger API docs at /api/docs  
✅ Docker + docker-compose for local dev  
✅ Railway deployment-ready  
