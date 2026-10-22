# 🥨 Vokabelina

Learn **German** (from **Turkish** or **English**) with AI mascots, daily German-culture memes and news rewritten to your level.
Flutter app (Android first; iOS + web build from the same code) + a small Dart backend that owns every AI key.

```
app/       Flutter client  (Android · iOS · Web)
backend/   Dart (shelf) server: AI gateway, news/meme feeds, admin panel   → deploy on Railway
```

## What's in it

| Area | What it does |
|---|---|
| **Mascot tutors** | Bruno 🐻 (warm), Frau Fuchs 🦊 (strict, witty), Brezel 🥨 (memes & slang). Procedurally drawn + animated (breathing, blinking, moods: idle/happy/cheer/sad/thinking/talking). Each persona also changes the AI's personality. |
| **AI tutor chat** | German replies pitched at your CEFR level, native-language translation, corrections explained in Turkish/English, new words → one tap into your deck, suggested replies, 👍/👎. |
| **Cards (SM-2 SRS)** | 100-word trilingual starter deck (DE/EN/TR + example sentences), reverse cards, Turkish-aware UI, TTS pronunciation. |
| **AI memory hub** | What the tutor remembers: known words, weakest words, recurring mistakes, facts about you. Visible, editable, erasable (Me tab). |
| **Culture tab** | Daily AI-generated meme cards (with explanation + vocab) and real German news (Tagesschau, DW RSS) rewritten by AI at your level with translation + keywords. |
| **Translator** | DE ⇄ TR/EN with grammar notes and add-to-deck words. |
| **Admin panel** `/admin` | Add/rotate API keys for **Anthropic, OpenAI, Gemini or any OpenAI-compatible API** (OpenRouter, Groq, DeepSeek, Ollama, vLLM…), route each task (chat / translate / simplify / memes) to a model with a fallback, edit RSS sources, rate limits, a global prompt, view stats, download the fine-tune dataset. |

## How the "learning AI" actually works (honest version)

* **Adaptive prompting, not on-device training.** Every chat request carries your level, persona and a *memory payload* (known words, weak words, recurring mistakes, personal facts); the server turns it into the system prompt, so the tutor talks at your level and weaves your weak words in.
* **Reinforcement loop at the learner level.** After each reply the app updates the learner model: words you used correctly get a success, words you were corrected on get a failure, mistake patterns and facts go into memory. **Thompson sampling** over each word's success/failure counts decides which words the tutor practises next (explore/exploit). SM-2 schedules the cards.
* **Fine-tuning pipeline (data side).** Chats you 👍 are logged server-side (device id hashed) and exported from the admin panel as chat-format JSONL, ready to fine-tune a model with a provider that supports it. The fine-tune itself is not run by this repo.

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
Without a server (or without an AI key on it) the app still works: cards, offline practice tutor and bundled memes.

## Security & privacy notes
* API keys exist only in the server's `config.json` (mode 600) and are masked in the admin API. Use a volume you trust; they are **not encrypted at rest**.
* Devices register anonymously (HMAC token). Costs are capped by per-device, global-per-minute and daily limits (admin-editable) and a per-IP registration limit.
* Chats are logged for the fine-tune export. **Before a public launch add an explicit opt-in / privacy notice** and a retention policy.
* News: only headline + teaser from the publisher's public RSS are sent to the AI; the original link is always shown.

## Roadmap / not done yet
* Accounts + cloud sync (progress is device-local today).
* Replace the procedural mascots with Rive/Lottie art for richer animation; sound effects.
* Real fine-tune job runner and evaluation set; speech input (STT) + pronunciation scoring.
* iOS and web are generated and the web build is verified; iOS/Android release builds need the respective SDKs/signing (not verified in this environment).
* Rust: not needed so far; a good fit later for an on-device SRS/offline dictionary core via `flutter_rust_bridge`.
