# Vokabelina course (A1 → B1)

29 units · 743 picture cards (German / English / Turkish) · 232 dialogue lines in three languages · 87 grammar cards (one per unit and target language).

The same course structure serves three target languages: **German** (explained in Turkish or English), **English** (explained in Turkish or German) and **Turkish** (explained in English or German). Every word and every dialogue line exists in all three languages, so exercises are generated for whichever language the learner picks.

## How the course was designed

| Source | What we took from it |
|---|---|
| CEFR descriptors (Council of Europe) | Levels A1/A2/B1 and the "I can …" goal of each unit. |
| Goethe-Institut *Start Deutsch 1 — Wortliste* (theme inventory, ~650 words) | The A1 topic list: person, housing, environment, travel & traffic, food & drink, shopping, services, learning, work, leisure; plus the word groups (numbers, weekdays, months, colours). [PDF](https://www.goethe.de/pro/relaunch/prf/ca/A1_SD1_Wortliste_02.pdf) |
| DW *Nicos Weg* (A1–B1 video course) | Story-driven everyday situations (arriving, ordering, directions, appointments) — reflected in the unit dialogues and AI role-play scenarios. |
| *Deutsch im Blick* (open textbook, CC BY, UT Austin COERLL) | Themed chapters that combine vocabulary, a situation and one grammar focus. |
| Busuu methodology | Short topic lessons; controlled practice (gap fills, multiple choice, dictation, sentence order) followed by free practice (writing / speaking) that is corrected — here instantly by the AI. |
| Memrise | Picture cards, mnemonic "mems" (our AI word coach) and spaced review. |

All lesson content in this repository is original; no third-party course text is copied.

## Unit anatomy

Each unit has these lessons (generated from the data in `app/lib/data/`):

1. **Words 1…n** — 6–9 picture cards each: intro card (picture, audio, gender colour for German nouns) → picture/meaning check → match pairs → recall (typing with umlaut/Turkish keyboard helpers, listening, der/die/das, reverse meaning). Mistakes are replayed at the end.
2. **Dialogue** — an 8-line A/B conversation to read and listen to, then sentence choice, listening comprehension, sentence building and gap fills, plus one speaking exercise (speech recognition).
3. **Grammar** — a grammar card for the target language, "explain more" by the AI in the learner's language, then gap fills on the examples and sentence building.
4. **Unit review** — everything mixed.
5. **AI conversation** — role-play with the tutor in the unit's situation (e.g. café, ticket counter, Bürgeramt). Bonus; needs the server.
6. **AI writing** — Busuu-style writing task corrected instantly (score, corrected text, tagged mistakes, tip). Bonus; needs the server.

Units unlock in order; lessons inside a unit unlock one after another (AI lessons open after the dialogue). A learner placed at A2 or B1 can open every unit below their level. Every practised word enters the SM-2 spaced-repetition deck of that target language.

## Units


### A1

| # | Unit | Can-do | Words | Grammar 🇩🇪 | Grammar 🇬🇧 | Grammar 🇹🇷 |
|---|---|---|---|---|---|---|
| 1 | 👋 Hello! · *Merhaba!* | I can greet people and introduce myself. | 21 | "sein" and "heißen" | "to be": am / is / are | Personal endings: "Ben öğrenciyim" |
| 2 | 🌍 Where are you from? · *Nerelisin?* | I can say where I come from, where I live and which languages I speak. | 22 | Present tense of regular verbs | Geniş zaman (Present simple) | Vowel harmony: -de/-da, -den/-dan |
| 3 | 🔢 Numbers & age · *Sayılar ve yaş* | I can count, say my age and give a phone number. | 22 | Questions: verb in position 2 or 1 | "do/does" ile sorular ve yaş | Question particle mi/mı/mu/mü |
| 4 | 👨‍👩‍👧 Family · *Aile* | I can talk about my family. | 22 | Articles, gender and "mein" | İyelik ve a/an/the | Possessive endings and "var/yok" |
| 5 | 🥨 Food & drink · *Yiyecek ve içecek* | I can order food and drinks and say what I like. | 49 | Accusative: einen / eine / ein | "would like" ve sayılabilen/sayılamayan | Accusative -(y)I and "istiyorum" |
| 6 | 🛍️ Shopping & clothes · *Alışveriş ve kıyafetler* | I can ask for prices, colours and sizes and pay. | 41 | Plural forms and prices | Çoğullar ve How much / How many | Plural -ler/-lar and numbers |
| 7 | 🏠 My home · *Evim* | I can describe my flat and furniture. | 34 | Negation: "kein" vs "nicht" | there is / there are ve olumsuzluk | "değil" and "var/yok" |
| 8 | ⏰ My day · *Günüm* | I can describe my daily routine and tell the time. | 38 | Separable verbs and time | Sıklık zarfları ve saat | Present continuous -(I)yor |
| 9 | ⚽ Free time · *Boş zaman* | I can talk about hobbies and make plans. | 28 | "können" and "gern" | can ve like + -ing | Ability -(y)Abil and "-mAyı severim" |
| 10 | 🏙️ In the city · *Şehirde* | I can ask for and give simple directions. | 26 | Where? — in/an/neben + dative | Yer edatları ve yol tarifi | Dative -(y)A and directions |
| 11 | 🚆 Getting around · *Ulaşım* | I can buy a ticket and understand departures and delays. | 26 | "müssen" and "mit" + dative | have to ve ulaşım | Instrumental -(y)lA and necessity |
| 12 | 🩺 Body & doctor · *Vücut ve doktor* | I can say what hurts and understand simple instructions at the doctor’s. | 25 | Imperative and "sollen" | Emir kipi ve "should" | Imperative and "… ağrıyor" |
| 13 | 🌦️ Weather & nature · *Hava ve doğa* | I can talk about the weather, seasons and animals. | 47 | "es" for weather; im/am | Hava için "it" ve şimdiki zaman | Weather and time expressions |
| 14 | 💼 Work & jobs · *İş ve meslekler* | I can talk about my job and say what I did yesterday. | 27 | Perfekt with "haben" | Meslekler: "a/an" ve geniş zaman | Past tense -DI |

### A2

| # | Unit | Can-do | Words | Grammar 🇩🇪 | Grammar 🇬🇧 | Grammar 🇹🇷 |
|---|---|---|---|---|---|---|
| 15 | 📸 Memories · *Anılar* | I can tell what happened at the weekend. | 20 | Perfekt with "sein" | Geçmiş zaman (Past simple) | -DI vs. -mIş |
| 16 | 🎄 Festivals · *Bayramlar ve kutlamalar* | I can congratulate, invite and talk about festivals. | 21 | Dative objects: mir, dir, ihm, ihr | Nesne zamirleri ve tarihler | Dative for recipients |
| 17 | ♻️ Living in Germany · *Almanya’da yaşam* | I can understand house rules, recycling and give reasons with "weil". | 21 | "weil" — verb at the end | because ve so | Reasons: "çünkü" and "-DIğI için" |
| 18 | 🏛️ Offices & paperwork · *Resmî daireler ve evrak* | I can register my address, fill in forms and make appointments. | 22 | "dass" clauses | Resmî ricalar ve "that" | Polite requests: "-(y)Abilir misiniz?" |
| 19 | 🤧 Health · *Sağlık* | I can describe symptoms, make a doctor’s appointment and understand advice. | 20 | Reflexive verbs | feel + sıfat ve tavsiye | "Kendimi … hissediyorum" and -mAlI |
| 20 | 📱 Media & internet · *Medya ve internet* | I can compare apps and media and say what I like best. | 22 | Comparative and superlative | Karşılaştırma ve üstünlük | Comparison: "daha" and "en" |
| 21 | 🏰 Travel · *Seyahat* | I can book accommodation and talk about past trips. | 21 | Präteritum of "sein" and "haben" | was/were ve "did" soruları | Future -(y)AcAk |
| 22 | 🍽️ Eating out in Germany · *Almanya’da dışarıda yemek* | I can order in a restaurant, pay and talk about regional food. | 22 | Two-way prepositions | Restoranda sipariş: "I'll have …" | Ordering: "-(y)AyIm" |
| 23 | 💞 Feelings & friends · *Duygular ve arkadaşlar* | I can express feelings and say what I do in which situation. | 22 | "wenn" clauses | Koşul cümleleri (0 ve 1. tip) | Conditional -(y)sA |

### B1

| # | Unit | Can-do | Words | Grammar 🇩🇪 | Grammar 🇬🇧 | Grammar 🇹🇷 |
|---|---|---|---|---|---|---|
| 24 | 📨 The world of work · *İş dünyası* | I can apply for a job and present myself politely in an interview. | 20 | Konjunktiv II: polite and unreal | 2. tip koşul ve kibar "would" | Unreal conditions: "-sAydI … -Irdi" |
| 25 | 🌱 Environment · *Çevre* | I can discuss environmental issues and describe processes. | 20 | Passive voice (present) | Edilgen yapı (Passive) | Passive -Il / -In |
| 26 | 🧱 History & society · *Tarih ve toplum* | I can talk about important events in German history and society. | 20 | Präteritum for narration | Anlatıda geçmiş ve "used to" | Past perfect -mIştI |
| 27 | 🎓 Education · *Eğitim* | I can describe school systems and my education with relative clauses. | 20 | Relative clauses | İlgi cümleleri: who / which / that | Participles instead of relative clauses |
| 28 | 💬 Giving opinions · *Fikir bildirmek* | I can give my opinion, weigh pros and cons and disagree politely. | 24 | Arguing: zu + infinitive, obwohl, trotzdem | Bağlaçlar: although, however, therefore | "-mAsInA rağmen" and connectors |
| 29 | 🎭 Culture & arts · *Kültür ve sanat* | I can talk about books, films and art and recommend something. | 20 | Genitive | İyelik 's ve "because of / despite" | Genitive-possessive: "Kafka'nın romanı" |


## Extending the course

* Words: add lines to `app/lib/data/vocab_bank.dart` under a unit header (`emoji|German|plural|English|Turkish|level|example`). Tests reject duplicates and missing translations.
* Dialogues: `_phrases` in `app/lib/data/curriculum.dart` (8 lines per unit, speaker A/B, three languages).
* Grammar: `app/lib/data/grammar.dart` (one card per unit and target language).
* `flutter test test/curriculum_test.dart test/lessons_test.dart` checks the data and builds every lesson in all three languages.
