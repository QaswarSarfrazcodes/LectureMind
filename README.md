# LectureMind — اپنا لیکچر، اپنی زبان

<p align="center">
  <img src="assets/app-logoandicon.svg" alt="LectureMind Logo" width="140" height="140" />
</p>

<p align="center">
  <strong>Voice-First Academic Knowledge Synthesis Engine for Higher Education (18+)</strong><br>
  <em>AssemblyAI Universal-3.5 Pro • Groq GPT-OSS-120B • Neumorphic Soft UI • Live STT • Structured Notes & PDF • Visual Mind Map & JPG • Socratic AI Quiz</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Riverpod-2.6.1-00599C?style=for-the-badge" alt="Riverpod" />
  <img src="https://img.shields.io/badge/AssemblyAI-Universal--3.5_Pro-FF5C35?style=for-the-badge" alt="AssemblyAI" />
  <img src="https://img.shields.io/badge/Groq-GPT--OSS--120B-F55036?style=for-the-badge" alt="Groq" />
  <img src="https://img.shields.io/badge/UI_Style-Neumorphic_Dark_Navy-0F172A?style=for-the-badge" alt="Neumorphic" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="License" />
</p>

---

## 📖 Executive Overview

**LectureMind** (*Apna Lecture, Apni Zubaan*) is an AI-powered voice intelligence and academic synthesis platform built on **AssemblyAI**'s streaming speech infrastructure and **Groq**'s ultra-low-latency Llama/GPT-OSS reasoning models. 

Engineered specifically for university scholars, graduate researchers, and adult lifelong learners (18+), LectureMind transforms spoken lectures, academic seminars, and document slides into deeply structured, exam-ready revision assets in seconds.

### 🛡️ The 18+ Cognitive Synthesis Charter
> *"LectureMind is engineered exclusively for university scholars and adult researchers. Early over-reliance on generative AI before developmental maturity impairs critical reasoning and deep self-thinking. Use LectureMind as an analytical amplifier to synthesize knowledge — never as a substitute for your own intellect."*

LectureMind acts as an intellectual amplifier that organizes, maps, and tests knowledge, ensuring students retain organic critical thinking while eliminating mechanical transcription friction.

---

## ⚡ The 5 Core Pillars

LectureMind is intentionally streamlined to deliver 5 focused, publication-grade academic workflows:

```
                                  ┌─────────────────────────────┐
                                  │    SPOKEN LECTURE AUDIO     │
                                  │   (Microphone / File Upload)│
                                  └──────────────┬──────────────┘
                                                 │
                                                 ▼
                                  ┌─────────────────────────────┐
                                  │   AssemblyAI Universal-3.5  │
                                  │   Real-Time STT WebSocket   │
                                  └──────────────┬──────────────┘
                                                 │ Raw Transcript
                                                 ▼
                                  ┌─────────────────────────────┐
                                  │  Neural STT Post-Processor  │
                                  │  (Groq GPT-OSS-120B Normal) │
                                  └──────────────┬──────────────┘
                                                 │ Polished Academic Prose
               ┌─────────────────────────────────┼─────────────────────────────────┐
               ▼                                 ▼                                 ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐   ┌─────────────────────────────┐
│    1. STRUCTURED NOTES      │   │     2. VISUAL MIND MAP      │   │    3. SOCRATIC AI QUIZ      │
│ • Executive Summary         │   │ • 4-Tier Concept Graph      │   │ • Bloom's Taxonomy Bloom Qs │
│ • Deep Bullets (Why & How)  │   │ • Interactive Zoom & Pan    │   │ • Neumorphic Gauge Dial     │
│ • 1-Click PDF Export        │   │ • Dedicated 1-Tap JPG Export│   │ • Spaced Misconception Drill│
└─────────────────────────────┘   └─────────────────────────────┘   └─────────────────────────────┘
               ▲                                                                   ▲
               │                     ┌─────────────────────────────┐               │
               └─────────────────────┤  4. PDF & SLIDE STUDIO      ├───────────────┘
                                     │ • Upload PDF / PPT Slides   │
                                     │ • Text Extraction & Parsing │
                                     └─────────────────────────────┘
```

### 1. High-Fidelity Speech-to-Text (Live Voice STT)
- **AssemblyAI Universal-3.5 Pro**: Low-latency acoustic processing with automatic punctuation, number formatting, and language detection.
- **Academic Vocabulary Boost**: Injected domain-specific vocabulary (`word_boost` with `boost_param: 'high'`) across STEM, medicine, law, and Pakistani English-Urdu code-switching.
- **Neural STT Normalizer (`openai/gpt-oss-120b`)**: Automatically strips speech disfluencies (*"um"*, *"uh"*, *"you know"*, *"matlab"*, *"yani"*), resolves misheard phonemes, and structures run-on spoken thoughts into clean academic prose.
- **✨ 1-Tap AI Polish & Fix Terms**: Interactive real-time transcript refinement button in the review studio.

### 2. Document Studio (PDF & Slide Reader)
- Upload lecture slides, research papers, or syllabus documents (`.pdf`, `.txt`, `.md`).
- Parses headings and sub-sections, generating cohesive lecture notes, visual concept maps, and Socratic quizzes directly from written documents.

### 3. Publication-Grade Structured Notes & PDF Export
- Deeply hierarchical notes: Executive Summary, Headings, Subheadings, Key Concept Breakdowns (explaining *Why*, *How*, and common misconceptions), and Technical Term Glossaries.
- **1-Click Styled PDF Generator**: Generates high-resolution academic study guides ready for printing or offline sharing.
- **Listen Notes**: Audio lecture recitation engine powered by text-to-speech.

### 4. Interactive Concept Mind Map & Instant JPG Download
- 4-Tier interactive concept tree: Root Subject $\rightarrow$ Pillars $\rightarrow$ Mechanisms $\rightarrow$ Concrete Details.
- **Dedicated 1-Tap "Download JPG"**: Exports the visual concept graph directly to standard `.jpg` format for mobile wallpapers, slide decks, and digital notebook imports.

### 5. Socratic AI Bloom's Taxonomy Quiz
- Generates 8–12 rigorous multiple-choice questions across Bloom's Taxonomy (Recall, Conceptual Understanding, Scenario Application, Comparative Analysis).
- Soft Neumorphic dial gauge scoring with comprehensive answer rationales.

---

## 🎨 Minimalist Neumorphic Design System

LectureMind employs an ultra-premium **Neumorphic (Soft UI)** design language:

| Design Token | Value | Visual Purpose |
|:---|:---:|:---|
| **Canvas Background** | `#0F172A` | Deep Navy substrate for soft extruded contrast |
| **Surface Card** | `#131D33` | Neumorphic extruded cards with dual-directional shadows |
| **Light Shadow** | `rgba(77, 126, 199, 0.18)` | Upper-left soft ambient highlight |
| **Dark Shadow** | `rgba(3, 6, 14, 0.60)` | Lower-right deep anchor shadow |
| **Accent Primary** | `#E8192C` | Vibrant Crimson Red for interactive buttons, recording pulses, and gauges |
| **Accent Glow** | `rgba(232, 25, 44, 0.35)` | Radiant crimson aura on active buttons |
| **Text Primary** | `#FFFFFF` | Crisp, high-legibility pure white typography |
| **Text Muted** | `#8FA0BC` | Subdued slate-blue for captions and secondary details |

---

## 🛠️ Technology Stack

- **Frontend & App Framework**: [Flutter 3.24+](https://flutter.dev) (Single codebase for Web, Android, iOS, and Desktop).
- **State Management**: [Flutter Riverpod 2.6+](https://riverpod.dev) with immutable reactive state notifiers.
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) declarative URL-driven routing.
- **Speech Intelligence**:
  - [AssemblyAI Universal-3.5 Pro Streaming WebSocket & Async REST API](https://www.assemblyai.com).
  - Native Web Audio `MediaRecorder` + Web Speech API fallback.
- **Reasoning LLM Backends**:
  - [Groq Cloud](https://groq.com) (`openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `qwen/qwen3.8-27b`).
  - Google Gemini 2.0 Flash (Multi-tier resilient fallback).
- **Document & Graphic Generation**:
  - `pdf` & `printing` for vector PDF rendering.
  - HTML5 Canvas rasterization for high-resolution JPG mind map export.
- **Security**: Local hardware-backed encrypted storage (`flutter_secure_storage`) with zero-retention cloud proxying.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.5.0 or higher)
- AssemblyAI API Key ([Get $100 free credits](https://www.assemblyai.com))
- Groq Cloud API Key ([console.groq.com](https://console.groq.com))

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/QaswarSarfrazcodes/LectureMind.git
cd LectureMind
flutter pub get
```

### 2. Configure API Keys
Configure your keys via compile-time defines or directly in the app:
```bash
flutter run -d chrome \
  --dart-define=ASSEMBLYAI_API_KEY="your_assemblyai_key" \
  --dart-define=GROQ_API_KEY="your_groq_key"
```

### 3. Build Web Release
```bash
flutter build web --release
# Serve locally
python tool/serve_web.py
```
Open [http://localhost:8080](http://localhost:8080) in Chrome.

### 4. Build Split-per-ABI Android APKs
```bash
flutter build apk --split-per-abi
```
Generated APKs will be located at `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (Modern 64-bit Android smartphones)
- `app-armeabi-v7a-release.apk` (Legacy 32-bit Android devices)
- `app-x86_64-release.apk` (Chromebooks & Emulators)

---

## 🏆 Lablab.ai AssemblyAI Hackathon Submission

This project was built for the **AssemblyAI - Voice Agent Hackathon** on **Lablab.ai**:
- **Slide Presentation Blueprint**: See [`PRESENTATION_10_SLIDES.md`](file:///c:/Users/hp/Downloads/Lecture%20Mind/PRESENTATION_10_SLIDES.md) for a complete 10-slide pitch ready for judges.
- **Official Submission Guide**: See [`LABLAB_SUBMISSION_GUIDE.md`](file:///c:/Users/hp/Downloads/Lecture%20Mind/LABLAB_SUBMISSION_GUIDE.md) for full project descriptions, video presentation script, tech tags, and judging criteria alignment.

---

## 👨‍💻 Project Creator & Team Leadership

- **Lead Developer & Solo Team Lead:** **Qaswar Sarfraz**
- **Academic Affiliation:** Final Year Software Engineering Student, **National University of Modern Languages (NUML)**, Islamabad, Pakistan
- **Specialization:** Mobile Application Engineering (Flutter), Cross-Platform Architecture, Real-Time Audio Streaming & Applied Speech AI
- **Role in Hackathon:** 100% solo developer and team leader for the Lablab.ai AssemblyAI Voice Agent Hackathon.

---

## 📜 License
MIT License. Built with pride for higher education scholars worldwide.

