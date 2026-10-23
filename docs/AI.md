# How the AI works in Vokabelina

All model calls go through the backend (`backend/`), which owns the API keys. The app never sees a key. Each AI feature is a **task** with its own provider + model + fallback, chosen in the admin panel (`/admin`). Anthropic, OpenAI-compatible APIs (OpenAI, OpenRouter, Groq, DeepSeek, Ollama, vLLM …) and Gemini are supported.

## What the learner sees

| Feature | Task | Where in the app |
|---|---|---|
| Tutor chat in the target language, with corrections (tagged by grammar category), new words, reply suggestions, 👍/👎 | `chat` | Tutor tab |
| Role-play in each unit's situation (café, ticket office, Bürgeramt …) | `chat` + scenario | Unit → AI conversation |
| Instant writing correction: score, corrected text, tagged mistakes, praise, tip, CEFR estimate | `check` | Unit → AI writing, Learn → Free writing |
| Word coach: memory trick ("mem"), example sentences, grammar notes, related words, optional AI picture | `word`, `image` | Any picture card |
| "I think I'm right": a second opinion on a typed answer the offline checker rejected | `judge` | Lesson feedback panel |
| Smart practice: gap-fills written around the learner's weakest words, recurring mistakes and interests | `practice` | Learn → Smart practice |
| Graded-reader stories from the learner's own words, with glossary and comprehension questions | `story` | Learn → AI story |
| Grammar explanations in the learner's language, with follow-up questions | `grammar` | Grammar lessons |
| Translator, news at the learner's level, daily culture memes | `translate`, `simplify`, `memes` | Tutor / Culture |

Everything degrades gracefully: without a server the course, cards, offline checker, offline practice tutor and bundled memes still work.

## What only the backend does

* **Long-term memory consolidation** (task `memory`). Every 8 chat turns — or when the app syncs — the server reads the learner's recent turns from its log and asks the model to update a memory document: a profile summary, categorised facts, interests, goals, mistake tags, an *episode* summary of the conversation, an estimated CEFR level and the next focus. Stored per anonymous device hash in `DATA_DIR/memory/`.
* **Memory retrieval.** Each chat prompt gets the profile summary plus the two past episodes most relevant to the current message (word overlap + recency) and the suggested focus, so the tutor can say "How was the football match in Hamburg?".
* **Teaching-style bandit.** Admin-defined prompt variants ("balanced", "curious", "storyteller" …) are chosen per reply by Thompson sampling over 👍/👎 — an online reinforcement-learning loop that shifts traffic to the styles learners prefer. Win rates are in the admin panel.
* **JSON repair.** If a model breaks the response schema, the server asks it once more to fix its own output at low temperature.
* **Shared caches.** Word-coach entries, grammar explanations and AI pictures are generated once and reused for every learner.
* **Cost control.** Token usage per day / provider / model / task, per-device, global and daily request limits, and a per-IP registration limit.
* **Learning analytics** (aggregated, no personal content): most common mistake tags, learners per level and target language, average writing score.
* **Training data.** 👍 chats export as chat-format JSONL for fine-tuning; every rated reply exports as a KTO-style preference dataset (`label: true/false`).

## The learner model on the device

* **Spaced repetition** (SM-2) per target language; every lesson outcome schedules the practised words.
* **Thompson sampling over each word's success/failure counts** decides which words count as "weak" — used by the tutor, smart practice and stories.
* **Memory v2**: facts with categories and timestamps, mistake patterns with examples whose weight halves every 14 days (fixed mistakes fade), interests, goals, and the server's summary / episodes / level estimate / focus. Everything is visible and editable in *Me → memory*; "Forget everything" clears it on the device, "Delete my data on the server" removes the server memory and every log line of the device.

## Honest limits

* The models are not trained on the device. "Learning" happens through the learner model, memory, retrieval and the prompt bandit. Fine-tuning itself is done outside this repo with the exported datasets.
* The memory consolidation and the level estimate are model judgements; the app only *suggests* a level change.
* Speech recognition depends on the platform recogniser; pronunciation scoring is a text similarity of what was recognised.
