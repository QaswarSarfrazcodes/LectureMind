# 🚀 LectureMind — Deployment Guide

> **Backend:** LectureMind is a **fully client-side Flutter app**.
> There is **no separate backend server** to deploy or maintain.
> All AI inference is handled by external APIs (AssemblyAI, Groq, Gemini) called directly from the client over HTTPS/WSS.

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        LectureMind Client                       │
│               Flutter Web / Android APK / iOS IPA               │
│                                                                  │
│  ┌──────────────────┐  ┌─────────────────┐  ┌───────────────┐  │
│  │  AssemblyAI STT  │  │  Groq LLM API   │  │  Gemini API   │  │
│  │  (Realtime WSS)  │  │ (Ultra-fast LLM)│  │ (Deep Reason) │  │
│  └──────────────────┘  └─────────────────┘  └───────────────┘  │
│           ↑ Direct HTTPS / WSS from browser or device           │
└─────────────────────────────────────────────────────────────────┘
```

**API Keys** are injected at build time via `--dart-define` flags.
On mobile they are additionally encrypted in the OS keychain via `FlutterSecureStorage`.
On web, values are compiled into the JS bundle (ephemeral session — no persistent storage).

---

## 🔑 Environment Variables (Required for Every Build)

| Variable | Service | Where to Get |
|---|---|---|
| `ASSEMBLYAI_API_KEY` | AssemblyAI Real-time STT | [assemblyai.com](https://www.assemblyai.com/) → Dashboard |
| `GROQ_API_KEY` | Groq LLM (Llama / GPT-OSS) | [console.groq.com](https://console.groq.com/) → API Keys |
| `GEMINI_API_KEY` | Google Gemini (optional fallback) | [aistudio.google.com](https://aistudio.google.com/) → Get API Key |

> **Note:** Default keys are already embedded in `app_secrets.dart` for hackathon demo purposes.
> For production, always override them using `--dart-define` so your own API quota is used.

---

## 🌐 Option 1 — Firebase Hosting (Recommended for Web)

Firebase Hosting gives you a free `*.web.app` URL with CDN, HTTPS, and custom domain support.

### Step 1 — Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### Step 2 — Initialize Firebase in the project
```bash
# Run once inside the project root
firebase init hosting
# Choose "build/web" as the public directory
# Select "Yes" for single-page app rewrite (index.html)
```

### Step 3 — Build Flutter Web
```bash
flutter build web --release \
  --dart-define=ASSEMBLYAI_API_KEY=your_assemblyai_key \
  --dart-define=GROQ_API_KEY=your_groq_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key \
  --web-renderer canvaskit \
  --pwa-strategy offline-first
```

### Step 4 — Deploy
```bash
firebase deploy --only hosting
```

Your live URL will be:
```
https://lecturemind-YOURPROJECT.web.app
```

---

## ▲ Option 2 — Vercel (Zero-Config, Fastest)

### Step 1 — Install Vercel CLI
```bash
npm install -g vercel
```

### Step 2 — Build Flutter Web
```bash
flutter build web --release \
  --dart-define=ASSEMBLYAI_API_KEY=your_assemblyai_key \
  --dart-define=GROQ_API_KEY=your_groq_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

### Step 3 — Deploy from build/web
```bash
cd build/web
vercel --prod
```

### `vercel.json` (place in project root — SPA routing fix)
```json
{
  "outputDirectory": "build/web",
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

---

## 📄 Option 3 — GitHub Pages (Free, No CLI Required)

### Step 1 — Build
```bash
flutter build web --release \
  --dart-define=ASSEMBLYAI_API_KEY=your_assemblyai_key \
  --dart-define=GROQ_API_KEY=your_groq_key \
  --base-href /LectureMind/
```

### Step 2 — Push build/web to gh-pages branch
```bash
cd build/web
git init
git add .
git commit -m "Deploy LectureMind Web"
git branch -M gh-pages
git remote add origin https://github.com/QaswarSarfrazcodes/LectureMind.git
git push -f origin gh-pages
```

### Step 3 — Enable GitHub Pages
- Go to **GitHub → Repository → Settings → Pages**
- Source: **Deploy from branch → `gh-pages` → `/ (root)`**
- URL: `https://qaswarSarfrazcodes.github.io/LectureMind/`

---

## 🤖 Option 4 — Android APK (Direct Install / Sideload)

### Prerequisites
```bash
flutter doctor  # Ensure Android SDK and JDK 17+ are installed
```

### Build Split APKs (one per ABI — smaller download sizes)
```bash
flutter build apk --release --split-per-abi \
  --dart-define=ASSEMBLYAI_API_KEY=your_assemblyai_key \
  --dart-define=GROQ_API_KEY=your_groq_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

Output files in `build/app/outputs/apk/release/`:

| APK File | Target Devices |
|---|---|
| `app-arm64-v8a-release.apk` | All modern 64-bit Android phones (2018+) |
| `app-armeabi-v7a-release.apk` | Older 32-bit Android phones |
| `app-x86_64-release.apk` | Android emulators / Chrome OS |

### Build Universal APK (single file, works everywhere)
```bash
flutter build apk --release \
  --dart-define=ASSEMBLYAI_API_KEY=your_assemblyai_key \
  --dart-define=GROQ_API_KEY=your_groq_key
```

### Build AAB (for Google Play Store upload)
```bash
flutter build appbundle --release \
  --dart-define=ASSEMBLYAI_API_KEY=your_assemblyai_key \
  --dart-define=GROQ_API_KEY=your_groq_key
```
Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 🔄 GitHub Actions CI/CD (Automated Builds)

Create `.github/workflows/deploy.yml`:

```yaml
name: Build & Deploy LectureMind

on:
  push:
    branches: [main]

jobs:
  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      - run: flutter pub get
      - name: Build Flutter Web
        run: |
          flutter build web --release \
            --dart-define=ASSEMBLYAI_API_KEY=${{ secrets.ASSEMBLYAI_API_KEY }} \
            --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }} \
            --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}
      - name: Deploy to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-firebase-project-id

  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: flutter pub get
      - name: Build Split APKs
        run: |
          flutter build apk --release --split-per-abi \
            --dart-define=ASSEMBLYAI_API_KEY=${{ secrets.ASSEMBLYAI_API_KEY }} \
            --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }}
      - uses: actions/upload-artifact@v4
        with:
          name: android-apks
          path: build/app/outputs/apk/release/*.apk
```

Add API keys as **GitHub Secrets**: `Settings → Secrets and variables → Actions → New repository secret`

---

## 🌍 AssemblyAI WebSocket & CORS (Web-Specific Notes)

LectureMind connects directly to `wss://streaming.assemblyai.com` from the browser.
AssemblyAI supports browser-to-API WebSocket connections natively — **no proxy required**.

For the `/api/token` token endpoint on web (short-lived token fetching), the app makes a relative call.
On a static hosting deployment without a backend, the app gracefully falls back to direct API-key WebSocket auth.

If you want a proper token proxy for production (recommended):
- Deploy a minimal Cloud Function / Vercel Serverless Function that calls `https://streaming.assemblyai.com/v3/token`
- Returns the temporary token to the browser so the raw API key is never in JS

---

## 📱 Platform Support Matrix

| Platform | Status | Notes |
|---|---|---|
| Android arm64 | ✅ Production Ready | Best performance — modern phones |
| Android arm32 | ✅ Production Ready | Legacy device support |
| Flutter Web (Chrome) | ✅ Production Ready | Full microphone + WebSocket support |
| Flutter Web (Firefox) | ✅ Works | MediaRecorder API supported |
| Flutter Web (Safari) | ⚠️ Partial | Mic permissions require HTTPS |
| iOS | 🔧 Needs Apple Dev Account | `flutter build ipa` |
| Windows Desktop | 🔧 Experimental | `flutter build windows` |

---

## 🧪 Local Development

```bash
# 1. Clone repository
git clone https://github.com/QaswarSarfrazcodes/LectureMind.git
cd LectureMind

# 2. Install dependencies
flutter pub get

# 3a. Run on Chrome (Web)
flutter run -d chrome \
  --dart-define=ASSEMBLYAI_API_KEY=your_key \
  --dart-define=GROQ_API_KEY=your_key

# 3b. Run on connected Android device
flutter run \
  --dart-define=ASSEMBLYAI_API_KEY=your_key \
  --dart-define=GROQ_API_KEY=your_key

# 4. Run all unit tests
flutter test
```

---

## 🔐 Security Checklist Before Public Release

- [x] API keys never hardcoded in version control (`.env` is gitignored)
- [x] Mobile keys encrypted in OS keychain (`FlutterSecureStorage`)
- [x] Keys masked in all UI display (`AppSecrets.masked()`)
- [x] `.gitignore` excludes `*.apk`, `*.aab`, `release_apks/`, `.env*`
- [ ] **TODO for production:** Rotate default embedded keys in `app_secrets.dart`
- [ ] **TODO for production:** Use a server-side token proxy for AssemblyAI WebSocket
- [ ] **TODO for production:** Enable Firebase App Check for additional API security

---

## 📞 Contact & Support

- **GitHub:** https://github.com/QaswarSarfrazcodes/LectureMind
- **Developer:** Qaswar Sarfraz — Final Year SE, NUML Islamabad
