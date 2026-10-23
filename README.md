# 🥨 Vokabelina

Learn **German, English or Turkish** — from Turkish, English or German — with a structured A1→B1 course, picture cards, AI mascot tutors, daily German-culture memes and news at your level.
Flutter app (Android first; iOS + web from the same code) + a Dart backend that owns every AI key.

```
app/       Flutter client  (Android · iOS · Web)
backend/   Dart (shelf) server: AI gateway, memory, feeds, admin panel   → deploy on Railway
docs/      CURRICULUM.md (course design + unit table) · AI.md (how the AI and memory work)
```

## What's in it

| Area | What it does |
|---|---|
| **Course** | 29 units (A1 14 · A2 9 · B1 6) built on the CEFR and the Goethe A1 theme inventory, structured like Busuu/Memrise: word lessons → dialogue → grammar → review → AI conversation → AI writing. Course map with winding lesson path, stars, unlocks and placement by level. See [docs/CURRICULUM.md](docs/CURRICULUM.md). |
| **Three languages** | Every word and dialogue line exists in German, English and Turkish; grammar cards for each target language (87). Separate decks and progress per language; UI in Turkish, English or German. |
| **Picture cards** | 743 emoji picture cards with gender colours for German nouns, plurals, audio (TTS) and flip animation; optional AI-generated pictures (cached and shared). |
| **13 exercise types** | Picture choice, meaning choice, listening, typing (umlaut/Turkish key helpers; tolerant of accents, typos, missing articles), der/die/das, match pairs, dialogue read-along, sentence building, sentence choice, listening comprehension, gap fill, grammar card, speaking (speech recognition). Mistakes are replayed; "🤖 I think I'm right" asks the AI judge. |
| **Mascot tutors** | Bruno 🐻, Frau Fuchs 🦊, Brezel 🥨 — procedurally drawn and animated (breathing, blinking, waving, cheering, hearts, thinking); each persona also changes the AI's personality. |
| **AI** | Tutor chat and unit role-plays, instant writing correction, word coach "mems", smart practice from weak words and recurring mistakes, graded-reader stories, grammar explanations, translator, news at your level, daily memes. See [docs/AI.md](docs/AI.md). |
| **Memory** | On device: SRS per language, Thompson-sampled weak words, decaying mistake patterns, facts, interests, goals. On the server: AI consolidation into a profile summary + conversation episodes, retrieval of relevant episodes into the tutor prompt, level estimate and next focus. Visible, editable, deletable. |
| **Animations** | Confetti, shake on mistakes, pop-in, pulse on the next lesson, 3D card flips, count-up XP, progress rings, page transitions; all respect "reduce motion". |
| **Admin panel** `/admin` | Keys for Anthropic / OpenAI-compatible / Gemini, provider+model+fallback per task (12 tasks), teaching-style variants with live win rates, AI pictures toggle, RSS sources, limits, learning insights, token usage, fine-tune and preference (KTO) exports. |

## Run it

### Backend
```bash
cd backend
ADMIN_TOKEN=choose-a-long-secret DATA_DIR=./data dart run bin/server.dart     # :8080
# open http://localhost:8080/admin → paste ADMIN_TOKEN → add a provider key → Save → "Test connection"
dart test
```
Env: `ADMIN_TOKEN` (admin disabled without it), `DATA_DIR` (keep on a persistent volume: config + keys + logs), `TOKEN_SECRET` (optional), `PORT`.

**Railway:** create a service from `backend/` (it has a `Dockerfile` + `railway.json`), attach a volume at `/data`, set `ADMIN_TOKEN`. Then open `https://<service>.up.railway.app/admin`.

### App
```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE=https://<service>.up.railway.app      # or set the URL in Me → Settings
flutter test
flutter build apk --release        # Android
flutter build web --release        # PC web
```
Without a server (or without an AI key on it) the app still works: the whole course, cards, reviews, offline practice tutor and bundled memes.

## Security & privacy notes
* API keys exist only in the server's `config.json` (mode 600) and are masked in the admin API. `DATA_DIR` (keys, memories, logs, caches, pictures) is created owner-only (700). Use a volume you trust; nothing is **encrypted at rest**.
* Devices register anonymously (HMAC token). Costs are capped by per-device, global-per-minute and daily limits (admin-editable) and a per-IP registration limit.
* Chats are logged for the fine-tune export and memory consolidation (device id hashed). Learners can turn off cloud memory and delete their server data in the app. **Before a public launch add an explicit opt-in / privacy notice** and a retention policy.
* News: only headline + teaser from the publisher's public RSS are sent to the AI; the original link is always shown.

## Roadmap / not done yet
* Accounts + cloud sync of progress (only the AI memory is on the server today).
* Rive/Lottie mascot art and sound effects; push reminders.
* B2 units; audio recorded by native speakers instead of TTS.
* Fine-tune job runner + evaluation set (the datasets are exported already); phoneme-level pronunciation scoring.
* iOS and web are generated and the web build is verified; iOS/Android release builds need the respective SDKs/signing (not verified in this environment).
* Rust: not needed so far; a good fit later for an on-device SRS/offline dictionary core via `flutter_rust_bridge`.
