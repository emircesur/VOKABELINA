import 'models.dart';
import 'vocab_bank.dart';

/// Course structure (A1 → B1) shared by all three target languages.
///
/// Design references: CEFR can-do descriptors; the Goethe-Institut "Start
/// Deutsch 1" theme inventory for A1 topics; DW "Nicos Weg" (story-driven
/// everyday situations); the CC BY open textbook "Deutsch im Blick" (themed
/// chapters); Busuu (short topic lessons: vocabulary → dialogue → grammar →
/// free writing/speaking) and Memrise (picture cards, mnemonics, spaced review).
/// All lesson content here is original.

class Phrase {
  const Phrase({required this.id, required this.speaker, required this.de, required this.en, required this.tr});
  final String id;

  /// 'A' or 'B' — the two people in the unit dialogue.
  final String speaker;
  final String de;
  final String en;
  final String tr;

  String inLang(String lang) => switch (lang) { 'de' => de, 'tr' => tr, _ => en };
}

class Unit {
  const Unit({
    required this.id,
    required this.number,
    required this.level,
    required this.emoji,
    required this.title,
    required this.canDo,
    required this.culture,
    required this.writing,
    required this.scenario,
  });

  final String id;
  final int number;
  final String level;
  final String emoji;

  /// UI-language keyed ('en', 'tr', 'de').
  final Map<String, String> title;

  /// CEFR-style "I can …" goal, UI-language keyed.
  final Map<String, String> canDo;

  /// Landeskunde (life in Germany), 'en' and 'tr'.
  final Map<String, String> culture;

  /// Free-writing task (Busuu-style), UI-language keyed. Corrected by the AI.
  final Map<String, String> writing;

  /// Role-play brief for the AI tutor (English, the server adapts it to the target language).
  final String scenario;

  List<String> get wordIds => unitWordIds[id] ?? const [];
  List<Word> get words => [for (final id in wordIds) bankWords[id]!];
  List<Phrase> get phrases => unitPhrases[id] ?? const [];
}

String pick(Map<String, String> m, String lang) => m[lang] ?? m['en'] ?? (m.values.isEmpty ? '' : m.values.first);

const units = <Unit>[
  // ------------------------------------------------------------------ A1
  Unit(
    id: 'u01', number: 1, level: 'A1', emoji: '👋',
    title: {'en': 'Hello!', 'tr': 'Merhaba!', 'de': 'Hallo!'},
    canDo: {'en': 'I can greet people and introduce myself.', 'tr': 'İnsanları selamlayıp kendimi tanıtabilirim.', 'de': 'Ich kann Leute begrüßen und mich vorstellen.'},
    culture: {
      'en': 'Germans use "du" with friends and children, and "Sie" with strangers, officials and at work. When in doubt, start with "Sie".',
      'tr': 'Almanlar arkadaş ve çocuklarla "du", yabancılar, memurlar ve iş yerinde "Sie" kullanır. Emin değilsen "Sie" ile başla.',
    },
    writing: {'en': 'Introduce yourself: your name, how you are, and say goodbye.', 'tr': 'Kendini tanıt: adın, nasıl olduğun ve vedalaş.', 'de': 'Stell dich vor: Name, wie es dir geht, und verabschiede dich.'},
    scenario: 'You meet the learner for the first time at a language café. Greet them, ask their name and how they are.',
  ),
  Unit(
    id: 'u02', number: 2, level: 'A1', emoji: '🌍',
    title: {'en': 'Where are you from?', 'tr': 'Nerelisin?', 'de': 'Woher kommst du?'},
    canDo: {'en': 'I can say where I come from, where I live and which languages I speak.', 'tr': 'Nereli olduğumu, nerede yaşadığımı ve hangi dilleri konuştuğumu söyleyebilirim.', 'de': 'Ich kann sagen, woher ich komme, wo ich wohne und welche Sprachen ich spreche.'},
    culture: {
      'en': 'About 3 million people in Germany have Turkish roots — the largest such community outside Turkey. Many cities have Turkish markets and bakeries.',
      'tr': 'Almanya’da yaklaşık 3 milyon Türkiye kökenli insan yaşıyor — Türkiye dışındaki en büyük topluluk. Birçok şehirde Türk marketleri ve fırınları var.',
    },
    writing: {'en': 'Write about where you come from, where you live and which languages you speak.', 'tr': 'Nereli olduğunu, nerede yaşadığını ve hangi dilleri konuştuğunu yaz.', 'de': 'Schreib, woher du kommst, wo du wohnst und welche Sprachen du sprichst.'},
    scenario: 'You are a new classmate in a language course. Ask where the learner comes from, where they live and which languages they speak.',
  ),
  Unit(
    id: 'u03', number: 3, level: 'A1', emoji: '🔢',
    title: {'en': 'Numbers & age', 'tr': 'Sayılar ve yaş', 'de': 'Zahlen & Alter'},
    canDo: {'en': 'I can count, say my age and give a phone number.', 'tr': 'Sayabilir, yaşımı ve telefon numaramı söyleyebilirim.', 'de': 'Ich kann zählen, mein Alter sagen und eine Telefonnummer nennen.'},
    culture: {
      'en': 'German says numbers 21–99 "backwards": 21 = einundzwanzig ("one-and-twenty"). Phone numbers are usually read digit by digit or in pairs.',
      'tr': 'Almanca 21–99 arası sayıları "tersten" söyler: 21 = einundzwanzig ("bir ve yirmi"). Telefon numaraları genelde tek tek ya da ikişer okunur.',
    },
    writing: {'en': 'Write your age, the ages of two people you know and a (fake) phone number.', 'tr': 'Yaşını, tanıdığın iki kişinin yaşını ve (uydurma) bir telefon numarası yaz.', 'de': 'Schreib dein Alter, das Alter von zwei Bekannten und eine (erfundene) Telefonnummer.'},
    scenario: 'You are filling in a gym membership form with the learner. Ask their age and phone number; read numbers back to check.',
  ),
  Unit(
    id: 'u04', number: 4, level: 'A1', emoji: '👨‍👩‍👧',
    title: {'en': 'Family', 'tr': 'Aile', 'de': 'Familie'},
    canDo: {'en': 'I can talk about my family.', 'tr': 'Ailemden bahsedebilirim.', 'de': 'Ich kann über meine Familie sprechen.'},
    culture: {
      'en': 'Many German families are small; grandparents often live in another city. Sunday afternoon "Kaffee und Kuchen" with family is a classic tradition.',
      'tr': 'Alman aileleri çoğunlukla küçüktür; büyükanne ve büyükbabalar genelde başka bir şehirde yaşar. Pazar öğleden sonra ailece "Kaffee und Kuchen" klasik bir gelenektir.',
    },
    writing: {'en': 'Describe your family: who they are, names and ages.', 'tr': 'Aileni anlat: kimler, adları ve yaşları.', 'de': 'Beschreib deine Familie: wer, Namen und Alter.'},
    scenario: 'You are looking at family photos together. Ask who is in the photos and about the learner’s family.',
  ),
  Unit(
    id: 'u05', number: 5, level: 'A1', emoji: '🥨',
    title: {'en': 'Food & drink', 'tr': 'Yiyecek ve içecek', 'de': 'Essen & Trinken'},
    canDo: {'en': 'I can order food and drinks and say what I like.', 'tr': 'Yiyecek ve içecek sipariş edip neyi sevdiğimi söyleyebilirim.', 'de': 'Ich kann Essen und Getränke bestellen und sagen, was ich mag.'},
    culture: {
      'en': 'Germany has one of the richest bread cultures in the world. "Abendbrot" — a cold dinner of bread, cheese and cold cuts — is still common.',
      'tr': 'Almanya dünyanın en zengin ekmek kültürlerinden birine sahip. Ekmek, peynir ve şarküteriden oluşan soğuk akşam yemeği "Abendbrot" hâlâ yaygın.',
    },
    writing: {'en': 'Write what you eat and drink for breakfast and what you would like to order in a café.', 'tr': 'Kahvaltıda ne yiyip içtiğini ve bir kafede ne sipariş etmek istediğini yaz.', 'de': 'Schreib, was du zum Frühstück isst und trinkst und was du im Café bestellen möchtest.'},
    scenario: 'You are a friendly waiter in a German café. Take the learner’s order for drinks and cake.',
  ),
  Unit(
    id: 'u06', number: 6, level: 'A1', emoji: '🛍️',
    title: {'en': 'Shopping & clothes', 'tr': 'Alışveriş ve kıyafetler', 'de': 'Einkaufen & Kleidung'},
    canDo: {'en': 'I can ask for prices, colours and sizes and pay.', 'tr': 'Fiyat, renk ve beden sorup ödeme yapabilirim.', 'de': 'Ich kann nach Preis, Farbe und Größe fragen und bezahlen.'},
    culture: {
      'en': 'Cash is still popular in Germany — some small shops and bakeries accept only cash. Most shops are closed on Sundays.',
      'tr': 'Almanya’da nakit hâlâ çok kullanılıyor — bazı küçük dükkân ve fırınlar sadece nakit kabul ediyor. Dükkânların çoğu pazar günü kapalı.',
    },
    writing: {'en': 'You are shopping for clothes. Write what you want to buy, the colour and the price.', 'tr': 'Kıyafet alışverişindesin. Ne almak istediğini, rengini ve fiyatını yaz.', 'de': 'Du kaufst Kleidung. Schreib, was du kaufen möchtest, die Farbe und den Preis.'},
    scenario: 'You are a shop assistant in a clothes shop. Help the learner find a jacket in their colour and size and handle payment.',
  ),
  Unit(
    id: 'u07', number: 7, level: 'A1', emoji: '🏠',
    title: {'en': 'My home', 'tr': 'Evim', 'de': 'Meine Wohnung'},
    canDo: {'en': 'I can describe my flat and furniture.', 'tr': 'Evimi ve mobilyalarımı tarif edebilirim.', 'de': 'Ich kann meine Wohnung und Möbel beschreiben.'},
    culture: {
      'en': 'Most Germans rent rather than own. Flats are measured in "Zimmer" (rooms) without counting kitchen and bathroom; an empty flat may come without a kitchen!',
      'tr': 'Almanların çoğu ev sahibi değil, kiracıdır. Daireler mutfak ve banyo hariç "Zimmer" (oda) sayısıyla anlatılır; boş bir daire mutfaksız bile gelebilir!',
    },
    writing: {'en': 'Describe your home: rooms, furniture and what you like about it.', 'tr': 'Evini anlat: odalar, mobilyalar ve neyini sevdiğin.', 'de': 'Beschreib deine Wohnung: Zimmer, Möbel und was dir gefällt.'},
    scenario: 'You are visiting the learner’s new flat. Ask about the rooms, the furniture and the rent.',
  ),
  Unit(
    id: 'u08', number: 8, level: 'A1', emoji: '⏰',
    title: {'en': 'My day', 'tr': 'Günüm', 'de': 'Mein Tag'},
    canDo: {'en': 'I can describe my daily routine and tell the time.', 'tr': 'Günlük rutinimi anlatıp saati söyleyebilirim.', 'de': 'Ich kann meinen Tagesablauf beschreiben und die Uhrzeit sagen.'},
    culture: {
      'en': 'Germans say "halb acht" (half eight) for 7:30 — half *to* eight! Punctuality matters: arriving 5 minutes early is normal.',
      'tr': 'Almanlar 7:30 için "halb acht" (sekizin yarısı) der — yani sekize yarım var! Dakiklik önemlidir: 5 dakika erken gelmek normaldir.',
    },
    writing: {'en': 'Describe a normal weekday from morning to evening.', 'tr': 'Sabahtan akşama sıradan bir iş gününü anlat.', 'de': 'Beschreib einen normalen Wochentag von morgens bis abends.'},
    scenario: 'You are a curious flatmate. Ask the learner about their daily routine and plans for the weekend.',
  ),
  Unit(
    id: 'u09', number: 9, level: 'A1', emoji: '⚽',
    title: {'en': 'Free time', 'tr': 'Boş zaman', 'de': 'Freizeit'},
    canDo: {'en': 'I can talk about hobbies and make plans.', 'tr': 'Hobilerden bahsedip plan yapabilirim.', 'de': 'Ich kann über Hobbys sprechen und Pläne machen.'},
    culture: {
      'en': 'Germany has around 600,000 clubs ("Vereine") — for football, choir, hiking, even allotment gardens. Joining one is a great way to make friends.',
      'tr': 'Almanya’da yaklaşık 600.000 dernek ("Verein") var — futbol, koro, doğa yürüyüşü, hatta hobi bahçeleri için. Birine katılmak arkadaş edinmenin harika bir yolu.',
    },
    writing: {'en': 'Write about your hobbies and invite a friend to do something this weekend.', 'tr': 'Hobilerini yaz ve bir arkadaşını hafta sonu bir şey yapmaya davet et.', 'de': 'Schreib über deine Hobbys und lade einen Freund für das Wochenende ein.'},
    scenario: 'You are a new friend. Find out the learner’s hobbies and agree on an activity for Friday evening.',
  ),
  Unit(
    id: 'u10', number: 10, level: 'A1', emoji: '🏙️',
    title: {'en': 'In the city', 'tr': 'Şehirde', 'de': 'In der Stadt'},
    canDo: {'en': 'I can ask for and give simple directions.', 'tr': 'Basit yol tarifi isteyip verebilirim.', 'de': 'Ich kann nach dem Weg fragen und einfache Wegbeschreibungen geben.'},
    culture: {
      'en': 'Only cross at a red pedestrian light ("rote Ampel") if you want disapproving looks — many Germans wait even when the street is empty.',
      'tr': 'Kırmızı yaya ışığında ("rote Ampel") karşıya geçersen ters bakışlar alabilirsin — birçok Alman sokak boş olsa bile bekler.',
    },
    writing: {'en': 'Explain the way from your home to a café or shop nearby.', 'tr': 'Evinden yakındaki bir kafeye ya da dükkâna giden yolu tarif et.', 'de': 'Beschreib den Weg von deiner Wohnung zu einem Café in der Nähe.'},
    scenario: 'You are a passer-by in a German city centre. The learner asks you for directions; give simple directions and check they understood.',
  ),
  Unit(
    id: 'u11', number: 11, level: 'A1', emoji: '🚆',
    title: {'en': 'Getting around', 'tr': 'Ulaşım', 'de': 'Unterwegs'},
    canDo: {'en': 'I can buy a ticket and understand departures and delays.', 'tr': 'Bilet alabilir, kalkış ve gecikmeleri anlayabilirim.', 'de': 'Ich kann eine Fahrkarte kaufen und Abfahrten und Verspätungen verstehen.'},
    culture: {
      'en': 'The "Deutschlandticket" is a monthly pass for all local and regional buses and trains in Germany. Long-distance ICE trains are not included.',
      'tr': '"Deutschlandticket", Almanya’daki tüm yerel ve bölgesel otobüs ve trenler için aylık bir bilettir. Uzun mesafe ICE trenleri dahil değildir.',
    },
    writing: {'en': 'Write how you get to work or school and how long it takes.', 'tr': 'İşe ya da okula nasıl gittiğini ve ne kadar sürdüğünü yaz.', 'de': 'Schreib, wie du zur Arbeit oder Schule fährst und wie lange es dauert.'},
    scenario: 'You work at a train station ticket counter. Sell the learner a ticket, tell them the platform and that the train is delayed.',
  ),
  Unit(
    id: 'u12', number: 12, level: 'A1', emoji: '🩺',
    title: {'en': 'Body & doctor', 'tr': 'Vücut ve doktor', 'de': 'Körper & Arzt'},
    canDo: {'en': 'I can say what hurts and understand simple instructions at the doctor’s.', 'tr': 'Neremin ağrıdığını söyleyip doktordaki basit talimatları anlayabilirim.', 'de': 'Ich kann sagen, was mir wehtut, und einfache Anweisungen beim Arzt verstehen.'},
    culture: {
      'en': 'In Germany you usually see a "Hausarzt" (family doctor) first. If you are sick, work usually needs a doctor’s note ("Krankmeldung") from the 4th day — some employers ask for it from day 1.',
      'tr': 'Almanya’da genelde önce bir "Hausarzt"a (aile hekimi) gidilir. Hastaysan iş yeri genelde 4. günden itibaren doktor raporu ("Krankmeldung") ister — bazı işverenler ilk günden ister.',
    },
    writing: {'en': 'Write a message to your teacher or boss: you are ill and cannot come today.', 'tr': 'Öğretmenine ya da patronuna mesaj yaz: hastasın ve bugün gelemiyorsun.', 'de': 'Schreib eine Nachricht an deinen Lehrer oder Chef: Du bist krank und kannst heute nicht kommen.'},
    scenario: 'You are a doctor (Hausarzt). Ask the learner what is wrong, about fever and pain, and give simple instructions.',
  ),
  Unit(
    id: 'u13', number: 13, level: 'A1', emoji: '🌦️',
    title: {'en': 'Weather & nature', 'tr': 'Hava ve doğa', 'de': 'Wetter & Natur'},
    canDo: {'en': 'I can talk about the weather, seasons and animals.', 'tr': 'Hava durumu, mevsimler ve hayvanlar hakkında konuşabilirim.', 'de': 'Ich kann über Wetter, Jahreszeiten und Tiere sprechen.'},
    culture: {
      'en': 'Talking about the weather is the safest small talk in Germany. And a saying: "Es gibt kein schlechtes Wetter, nur falsche Kleidung."',
      'tr': 'Hava durumu, Almanya’daki en güvenli sohbet konusudur. Bir de deyim: "Kötü hava yoktur, sadece yanlış kıyafet vardır."',
    },
    writing: {'en': 'Describe the weather today and your favourite season.', 'tr': 'Bugünkü havayı ve en sevdiğin mevsimi anlat.', 'de': 'Beschreib das Wetter heute und deine Lieblingsjahreszeit.'},
    scenario: 'You are chatting with the learner at a bus stop. Make small talk about the weather and seasons.',
  ),
  Unit(
    id: 'u14', number: 14, level: 'A1', emoji: '💼',
    title: {'en': 'Work & jobs', 'tr': 'İş ve meslekler', 'de': 'Arbeit & Beruf'},
    canDo: {'en': 'I can talk about my job and say what I did yesterday.', 'tr': 'Mesleğimden bahsedip dün ne yaptığımı söyleyebilirim.', 'de': 'Ich kann über meinen Beruf sprechen und sagen, was ich gestern gemacht habe.'},
    culture: {
      'en': 'Germans separate work and free time strictly: "Feierabend" is sacred, and writing to colleagues in the evening is often avoided.',
      'tr': 'Almanlar iş ve boş zamanı kesin şekilde ayırır: "Feierabend" kutsaldır ve akşam iş arkadaşlarına yazmaktan genelde kaçınılır.',
    },
    writing: {'en': 'Write about your job (or dream job) and what you did at work yesterday.', 'tr': 'Mesleğini (ya da hayalindeki mesleği) ve dün işte ne yaptığını yaz.', 'de': 'Schreib über deinen Beruf (oder Traumberuf) und was du gestern bei der Arbeit gemacht hast.'},
    scenario: 'You meet the learner at a networking event. Ask about their job, workplace and what they did yesterday.',
  ),
  // ------------------------------------------------------------------ A2
  Unit(
    id: 'u15', number: 15, level: 'A2', emoji: '📸',
    title: {'en': 'Memories', 'tr': 'Anılar', 'de': 'Erinnerungen'},
    canDo: {'en': 'I can tell what happened at the weekend.', 'tr': 'Hafta sonu neler olduğunu anlatabilirim.', 'de': 'Ich kann erzählen, was am Wochenende passiert ist.'},
    culture: {
      'en': 'In spoken German, the past is mostly told with the Perfekt ("Ich habe … gemacht"), while written stories use the Präteritum.',
      'tr': 'Konuşma dilinde Almanca geçmiş zaman çoğunlukla Perfekt ile ("Ich habe … gemacht") anlatılır; yazılı hikâyelerde ise Präteritum kullanılır.',
    },
    writing: {'en': 'Tell what you did last weekend (at least 5 sentences).', 'tr': 'Geçen hafta sonu ne yaptığını anlat (en az 5 cümle).', 'de': 'Erzähl, was du letztes Wochenende gemacht hast (mindestens 5 Sätze).'},
    scenario: 'It is Monday morning and you are a colleague. Ask the learner what they did at the weekend and react with interest.',
  ),
  Unit(
    id: 'u16', number: 16, level: 'A2', emoji: '🎄',
    title: {'en': 'Festivals', 'tr': 'Bayramlar ve kutlamalar', 'de': 'Feste & Feiern'},
    canDo: {'en': 'I can congratulate, invite and talk about festivals.', 'tr': 'Tebrik edebilir, davet edebilir ve bayramlardan bahsedebilirim.', 'de': 'Ich kann gratulieren, einladen und über Feste sprechen.'},
    culture: {
      'en': 'Germans open Christmas presents on Christmas Eve (24 Dec). Never wish someone "Happy birthday" before the day — it is considered bad luck!',
      'tr': 'Almanlar Noel hediyelerini 24 Aralık akşamı açar. Birine doğum gününden önce "iyi ki doğdun" deme — uğursuzluk sayılır!',
    },
    writing: {'en': 'Write an invitation to your birthday party: when, where, what to bring.', 'tr': 'Doğum günü partine bir davet yaz: ne zaman, nerede, ne getirilmeli.', 'de': 'Schreib eine Einladung zu deiner Geburtstagsparty: wann, wo, was mitbringen.'},
    scenario: 'You are a neighbour who invites the learner to a celebration. Talk about festivals you each celebrate and gifts.',
  ),
  Unit(
    id: 'u17', number: 17, level: 'A2', emoji: '♻️',
    title: {'en': 'Living in Germany', 'tr': 'Almanya’da yaşam', 'de': 'Wohnen in Deutschland'},
    canDo: {'en': 'I can understand house rules, recycling and give reasons with "weil".', 'tr': 'Bina kurallarını, geri dönüşümü anlayabilir ve "weil" ile sebep belirtebilirim.', 'de': 'Ich kann Hausordnung und Mülltrennung verstehen und mit „weil“ begründen.'},
    culture: {
      'en': 'Typical bins: yellow (packaging), blue (paper), brown (organic), black/grey (residual). Bottles with a deposit go back to the shop machine.',
      'tr': 'Tipik çöp kutuları: sarı (ambalaj), mavi (kâğıt), kahverengi (organik), siyah/gri (diğer). Depozitolu şişeler marketteki makineye geri verilir.',
    },
    writing: {'en': 'Explain to a new neighbour how waste separation works in your building and why.', 'tr': 'Yeni bir komşuya binanda çöp ayrıştırmanın nasıl ve neden yapıldığını açıkla.', 'de': 'Erklär einem neuen Nachbarn, wie die Mülltrennung im Haus funktioniert und warum.'},
    scenario: 'You are the learner’s new German neighbour. Kindly explain recycling and quiet hours; ask why they moved here.',
  ),
  Unit(
    id: 'u18', number: 18, level: 'A2', emoji: '🏛️',
    title: {'en': 'Offices & paperwork', 'tr': 'Resmî daireler ve evrak', 'de': 'Ämter & Formulare'},
    canDo: {'en': 'I can register my address, fill in forms and make appointments.', 'tr': 'İkametimi kaydettirebilir, form doldurabilir ve randevu alabilirim.', 'de': 'Ich kann mich anmelden, Formulare ausfüllen und Termine machen.'},
    culture: {
      'en': 'After moving, you must register your address ("Anmeldung") at the Bürgeramt within two weeks. You need the landlord’s confirmation ("Wohnungsgeberbestätigung").',
      'tr': 'Taşındıktan sonra iki hafta içinde Bürgeramt’ta adres kaydı ("Anmeldung") yaptırmalısın. Ev sahibinin onay belgesi ("Wohnungsgeberbestätigung") gerekir.',
    },
    writing: {'en': 'Write a short email asking for an appointment to register your address.', 'tr': 'Adres kaydı için randevu isteyen kısa bir e-posta yaz.', 'de': 'Schreib eine kurze E-Mail und bitte um einen Termin für die Anmeldung.'},
    scenario: 'You are a polite but busy clerk at the Bürgeramt. Help the learner register their address and ask for the documents.',
  ),
  Unit(
    id: 'u19', number: 19, level: 'A2', emoji: '🤧',
    title: {'en': 'Health', 'tr': 'Sağlık', 'de': 'Gesundheit'},
    canDo: {'en': 'I can describe symptoms, make a doctor’s appointment and understand advice.', 'tr': 'Belirtileri anlatabilir, doktordan randevu alabilir ve tavsiyeleri anlayabilirim.', 'de': 'Ich kann Symptome beschreiben, einen Arzttermin machen und Ratschläge verstehen.'},
    culture: {
      'en': 'Emergency numbers: 112 (ambulance/fire), 110 (police). For non-urgent help outside office hours, call 116 117 (medical on-call service).',
      'tr': 'Acil numaralar: 112 (ambulans/itfaiye), 110 (polis). Mesai dışı acil olmayan durumlar için 116 117’yi (nöbetçi doktor hizmeti) ara.',
    },
    writing: {'en': 'Write to a friend who is ill: ask how they feel and give advice.', 'tr': 'Hasta olan bir arkadaşına yaz: nasıl hissettiğini sor ve tavsiye ver.', 'de': 'Schreib einem kranken Freund: Frag, wie er sich fühlt, und gib Ratschläge.'},
    scenario: 'You are a receptionist at a doctor’s practice on the phone. Ask about symptoms and find an appointment for the learner.',
  ),
  Unit(
    id: 'u20', number: 20, level: 'A2', emoji: '📱',
    title: {'en': 'Media & internet', 'tr': 'Medya ve internet', 'de': 'Medien & Internet'},
    canDo: {'en': 'I can compare apps and media and say what I like best.', 'tr': 'Uygulama ve medyaları karşılaştırıp en çok neyi sevdiğimi söyleyebilirim.', 'de': 'Ich kann Apps und Medien vergleichen und sagen, was mir am besten gefällt.'},
    culture: {
      'en': 'Public broadcasters ARD and ZDF are funded by a household fee ("Rundfunkbeitrag"). The "Tagesschau" at 8 pm is Germany’s most-watched news show.',
      'tr': 'Kamu yayıncıları ARD ve ZDF, hane başına ödenen bir ücretle ("Rundfunkbeitrag") finanse edilir. Saat 20:00’deki "Tagesschau" Almanya’nın en çok izlenen haber programıdır.',
    },
    writing: {'en': 'Compare two apps or websites you use. Which is better and why?', 'tr': 'Kullandığın iki uygulamayı ya da siteyi karşılaştır. Hangisi daha iyi ve neden?', 'de': 'Vergleich zwei Apps oder Webseiten. Welche ist besser und warum?'},
    scenario: 'You are a friend who is not good with technology. Ask the learner which apps they use and to compare them.',
  ),
  Unit(
    id: 'u21', number: 21, level: 'A2', emoji: '🏰',
    title: {'en': 'Travel', 'tr': 'Seyahat', 'de': 'Reisen'},
    canDo: {'en': 'I can book accommodation and talk about past trips.', 'tr': 'Konaklama ayarlayıp geçmiş seyahatlerimi anlatabilirim.', 'de': 'Ich kann eine Unterkunft buchen und über vergangene Reisen sprechen.'},
    culture: {
      'en': 'Popular German destinations: the Baltic and North Sea coasts, the Alps, Neuschwanstein castle and the Rhine valley with its castles and vineyards.',
      'tr': 'Almanya’da popüler yerler: Baltık ve Kuzey Denizi kıyıları, Alpler, Neuschwanstein şatosu ve kaleleri ile bağlarıyla Ren vadisi.',
    },
    writing: {'en': 'Write a postcard from your last (or dream) holiday.', 'tr': 'Son (ya da hayalindeki) tatilinden bir kartpostal yaz.', 'de': 'Schreib eine Postkarte aus deinem letzten (oder Traum-)Urlaub.'},
    scenario: 'You work at a youth hostel reception. Book a room for the learner and recommend a sight; ask about their last trip.',
  ),
  Unit(
    id: 'u22', number: 22, level: 'A2', emoji: '🍽️',
    title: {'en': 'Eating out in Germany', 'tr': 'Almanya’da dışarıda yemek', 'de': 'Essen gehen'},
    canDo: {'en': 'I can order in a restaurant, pay and talk about regional food.', 'tr': 'Restoranda sipariş verip ödeme yapabilir ve yöresel yemeklerden bahsedebilirim.', 'de': 'Ich kann im Restaurant bestellen, bezahlen und über regionale Gerichte sprechen.'},
    culture: {
      'en': 'Tip about 5–10% by saying the total you want to pay ("25, stimmt so"). In many restaurants you ask to pay together ("zusammen") or separately ("getrennt").',
      'tr': 'Bahşiş için ödemek istediğin toplamı söyleyerek yaklaşık %5–10 bırakılır ("25, stimmt so"). Birçok restoranda birlikte ("zusammen") ya da ayrı ("getrennt") ödemek istediğin sorulur.',
    },
    writing: {'en': 'Write a short restaurant review: what you ate, how it tasted, the service.', 'tr': 'Kısa bir restoran yorumu yaz: ne yedin, tadı nasıldı, servis nasıldı.', 'de': 'Schreib eine kurze Restaurantbewertung: was du gegessen hast, wie es geschmeckt hat, der Service.'},
    scenario: 'You are a waiter in a Bavarian restaurant. Take the learner’s order (starter, main, dessert) and handle the bill and tip.',
  ),
  Unit(
    id: 'u23', number: 23, level: 'A2', emoji: '💞',
    title: {'en': 'Feelings & friends', 'tr': 'Duygular ve arkadaşlar', 'de': 'Gefühle & Freunde'},
    canDo: {'en': 'I can express feelings and say what I do in which situation.', 'tr': 'Duygularımı ifade edip hangi durumda ne yaptığımı söyleyebilirim.', 'de': 'Ich kann Gefühle ausdrücken und sagen, was ich in welcher Situation mache.'},
    culture: {
      'en': 'Germans can seem reserved at first, but friendships are often deep and long-lasting. Directness is seen as honesty, not rudeness.',
      'tr': 'Almanlar başta mesafeli görünebilir ama arkadaşlıklar genelde derin ve uzun sürelidir. Dolaysız konuşmak kabalık değil, dürüstlük sayılır.',
    },
    writing: {'en': 'Write about a moment when you were very happy or nervous.', 'tr': 'Çok mutlu ya da gergin olduğun bir anı yaz.', 'de': 'Schreib über einen Moment, in dem du sehr glücklich oder nervös warst.'},
    scenario: 'You are a close friend. Ask the learner how they feel today and what they do when they are sad or stressed.',
  ),
  // ------------------------------------------------------------------ B1
  Unit(
    id: 'u24', number: 24, level: 'B1', emoji: '📨',
    title: {'en': 'The world of work', 'tr': 'İş dünyası', 'de': 'Arbeitswelt'},
    canDo: {'en': 'I can apply for a job and present myself politely in an interview.', 'tr': 'Bir işe başvurabilir ve görüşmede kendimi kibarca tanıtabilirim.', 'de': 'Ich kann mich bewerben und mich im Vorstellungsgespräch höflich präsentieren.'},
    culture: {
      'en': 'German applications traditionally include a cover letter, a tabular CV ("Lebenslauf") and certificates ("Zeugnisse"). Vocational training ("Ausbildung") is highly respected.',
      'tr': 'Alman iş başvuruları geleneksel olarak ön yazı, tablo şeklinde özgeçmiş ("Lebenslauf") ve belgelerden ("Zeugnisse") oluşur. Meslek eğitimi ("Ausbildung") çok saygın kabul edilir.',
    },
    writing: {'en': 'Write a short cover letter for a job you would like.', 'tr': 'İstediğin bir iş için kısa bir ön yazı yaz.', 'de': 'Schreib ein kurzes Anschreiben für eine Stelle, die dich interessiert.'},
    scenario: 'You are an HR manager conducting a polite job interview. Ask about experience, strengths and availability; use polite forms.',
  ),
  Unit(
    id: 'u25', number: 25, level: 'B1', emoji: '🌱',
    title: {'en': 'Environment', 'tr': 'Çevre', 'de': 'Umwelt'},
    canDo: {'en': 'I can discuss environmental issues and describe processes.', 'tr': 'Çevre sorunlarını tartışabilir ve süreçleri anlatabilirim.', 'de': 'Ich kann über Umweltprobleme diskutieren und Vorgänge beschreiben.'},
    culture: {
      'en': 'Germany’s "Energiewende" aims to replace fossil and nuclear energy with renewables; the last nuclear power plants were shut down in 2023.',
      'tr': 'Almanya’nın "Energiewende"si fosil ve nükleer enerjiyi yenilenebilir enerjiyle değiştirmeyi hedefliyor; son nükleer santraller 2023’te kapatıldı.',
    },
    writing: {'en': 'Write what you do (or could do) for the environment in daily life.', 'tr': 'Günlük hayatta çevre için ne yaptığını (ya da yapabileceğini) yaz.', 'de': 'Schreib, was du im Alltag für die Umwelt tust (oder tun könntest).'},
    scenario: 'You are a journalist interviewing the learner about the environment and recycling in their city.',
  ),
  Unit(
    id: 'u26', number: 26, level: 'B1', emoji: '🧱',
    title: {'en': 'History & society', 'tr': 'Tarih ve toplum', 'de': 'Geschichte & Gesellschaft'},
    canDo: {'en': 'I can talk about important events in German history and society.', 'tr': 'Alman tarihi ve toplumundaki önemli olaylardan bahsedebilirim.', 'de': 'Ich kann über wichtige Ereignisse der deutschen Geschichte und Gesellschaft sprechen.'},
    culture: {
      'en': 'The Berlin Wall fell on 9 November 1989; Germany reunified on 3 October 1990 — today a public holiday. From 1961, a recruitment agreement brought many workers from Turkey.',
      'tr': 'Berlin Duvarı 9 Kasım 1989’da yıkıldı; Almanya 3 Ekim 1990’da yeniden birleşti — bugün resmî tatil. 1961’deki işgücü anlaşmasıyla Türkiye’den birçok işçi geldi.',
    },
    writing: {'en': 'Write about a historical event that is important for your family or country.', 'tr': 'Ailen ya da ülken için önemli olan tarihî bir olayı yaz.', 'de': 'Schreib über ein historisches Ereignis, das für deine Familie oder dein Land wichtig ist.'},
    scenario: 'You are a city guide at the Berlin Wall memorial. Tell the learner a little history and ask about history in their country.',
  ),
  Unit(
    id: 'u27', number: 27, level: 'B1', emoji: '🎓',
    title: {'en': 'Education', 'tr': 'Eğitim', 'de': 'Bildung'},
    canDo: {'en': 'I can describe school systems and my education with relative clauses.', 'tr': 'Okul sistemlerini ve eğitimimi ilgi cümleleriyle anlatabilirim.', 'de': 'Ich kann Schulsysteme und meine Bildung mit Relativsätzen beschreiben.'},
    culture: {
      'en': 'After primary school, German children are split into different school types (Gymnasium, Realschule, …). Public universities charge no tuition fees in most states.',
      'tr': 'Alman çocukları ilkokuldan sonra farklı okul türlerine (Gymnasium, Realschule, …) ayrılır. Çoğu eyalette devlet üniversiteleri öğrenim ücreti almaz.',
    },
    writing: {'en': 'Describe your school or university and a teacher who was important for you.', 'tr': 'Okulunu ya da üniversiteni ve senin için önemli olan bir öğretmeni anlat.', 'de': 'Beschreib deine Schule oder Uni und eine Lehrkraft, die für dich wichtig war.'},
    scenario: 'You are a student advisor. Ask the learner about their education and plans, and explain options in Germany.',
  ),
  Unit(
    id: 'u28', number: 28, level: 'B1', emoji: '💬',
    title: {'en': 'Giving opinions', 'tr': 'Fikir bildirmek', 'de': 'Meinungen'},
    canDo: {'en': 'I can give my opinion, weigh pros and cons and disagree politely.', 'tr': 'Fikrimi söyleyebilir, artı ve eksileri tartabilir ve kibarca itiraz edebilirim.', 'de': 'Ich kann meine Meinung sagen, Vor- und Nachteile abwägen und höflich widersprechen.'},
    culture: {
      'en': 'Germans enjoy factual debate ("Diskussion") and separate the topic from the person — disagreeing openly is normal and not personal.',
      'tr': 'Almanlar olgulara dayalı tartışmayı ("Diskussion") sever ve konuyu kişiden ayırır — açıkça karşı çıkmak normaldir, kişisel algılanmaz.',
    },
    writing: {'en': 'Home office: yes or no? Write your opinion with pros and cons.', 'tr': 'Evden çalışma: evet mi hayır mı? Artı ve eksileriyle fikrini yaz.', 'de': 'Homeoffice: ja oder nein? Schreib deine Meinung mit Vor- und Nachteilen.'},
    scenario: 'You are a debate partner with the opposite opinion on working from home. Argue politely and ask for the learner’s reasons.',
  ),
  Unit(
    id: 'u29', number: 29, level: 'B1', emoji: '🎭',
    title: {'en': 'Culture & arts', 'tr': 'Kültür ve sanat', 'de': 'Kultur & Kunst'},
    canDo: {'en': 'I can talk about books, films and art and recommend something.', 'tr': 'Kitaplar, filmler ve sanat hakkında konuşup bir şey önerebilirim.', 'de': 'Ich kann über Bücher, Filme und Kunst sprechen und etwas empfehlen.'},
    culture: {
      'en': 'The Brothers Grimm collected fairy tales like "Hänsel und Gretel" and "Rotkäppchen". Germany has over 6,000 museums and a famous theatre and orchestra culture.',
      'tr': 'Grimm Kardeşler "Hansel ile Gretel" ve "Kırmızı Başlıklı Kız" gibi masalları derledi. Almanya’da 6.000’den fazla müze ve ünlü bir tiyatro ve orkestra kültürü var.',
    },
    writing: {'en': 'Recommend a book, film or series to a friend and explain why.', 'tr': 'Bir arkadaşına bir kitap, film ya da dizi öner ve nedenini açıkla.', 'de': 'Empfiehl einem Freund ein Buch, einen Film oder eine Serie und erkläre warum.'},
    scenario: 'You are a culture-loving friend. Talk about books, films and museums and ask the learner for a recommendation.',
  ),
];

final Map<String, Unit> unitsById = {for (final u in units) u.id: u};

// ----------------------------------------------------------------- dialogues

/// Speaker | German | English | Turkish
const _phrases = r'''
#u01
A|Hallo! Wie heißt du?|Hi! What's your name?|Merhaba! Adın ne?
B|Ich heiße Lena. Und du?|My name is Lena. And you?|Benim adım Lena. Ya sen?
A|Ich bin Emir.|I am Emir.|Ben Emir.
B|Freut mich, Emir!|Nice to meet you, Emir!|Memnun oldum, Emir!
A|Wie geht es dir?|How are you?|Nasılsın?
B|Gut, danke. Und dir?|Fine, thanks. And you?|İyiyim, teşekkürler. Ya sen?
A|Auch gut. Tschüss!|Also fine. Bye!|Ben de iyiyim. Hoşça kal!
B|Bis morgen!|See you tomorrow!|Yarın görüşürüz!
#u02
A|Woher kommst du?|Where are you from?|Nerelisin?
B|Ich komme aus der Türkei.|I come from Turkey.|Türkiye'den geliyorum.
A|Wo wohnst du jetzt?|Where do you live now?|Şimdi nerede yaşıyorsun?
B|Ich wohne in Berlin.|I live in Berlin.|Berlin'de yaşıyorum.
A|Welche Sprachen sprichst du?|Which languages do you speak?|Hangi dilleri konuşuyorsun?
B|Ich spreche Türkisch und Englisch.|I speak Turkish and English.|Türkçe ve İngilizce konuşuyorum.
A|Und Deutsch?|And German?|Ya Almanca?
B|Ich lerne Deutsch.|I am learning German.|Almanca öğreniyorum.
#u03
A|Wie alt bist du?|How old are you?|Kaç yaşındasın?
B|Ich bin zwanzig Jahre alt.|I am twenty years old.|Yirmi yaşındayım.
A|Wie ist deine Telefonnummer?|What is your phone number?|Telefon numaran ne?
B|Null, eins, sieben, drei, fünf.|Zero, one, seven, three, five.|Sıfır, bir, yedi, üç, beş.
A|Wie viel kostet das?|How much does that cost?|Bu ne kadar?
B|Das kostet zehn Euro.|That costs ten euros.|Bu on avro.
A|Wie viele Kinder sind hier?|How many children are here?|Burada kaç çocuk var?
B|Hier sind drei Kinder.|There are three children here.|Burada üç çocuk var.
#u04
A|Ist das deine Familie?|Is that your family?|Bu senin ailen mi?
B|Ja, das ist meine Mutter.|Yes, that is my mother.|Evet, bu benim annem.
A|Und wer ist das?|And who is that?|Peki bu kim?
B|Das ist mein Vater.|That is my father.|Bu benim babam.
A|Hast du Geschwister?|Do you have siblings?|Kardeşin var mı?
B|Ja, ich habe einen Bruder und eine Schwester.|Yes, I have a brother and a sister.|Evet, bir erkek ve bir kız kardeşim var.
A|Bist du verheiratet?|Are you married?|Evli misin?
B|Nein, ich bin ledig.|No, I am single.|Hayır, bekârım.
#u05
A|Was möchtest du trinken?|What would you like to drink?|Ne içmek istersin?
B|Ich möchte einen Kaffee, bitte.|I would like a coffee, please.|Bir kahve istiyorum, lütfen.
A|Möchtest du auch etwas essen?|Would you also like something to eat?|Bir şey de yemek ister misin?
B|Ja, ein Stück Kuchen.|Yes, a piece of cake.|Evet, bir dilim pasta.
A|Ich habe Hunger.|I am hungry.|Acıktım.
B|Das Brot ist sehr lecker.|The bread is very tasty.|Ekmek çok lezzetli.
A|Ich esse kein Fleisch.|I don't eat meat.|Et yemiyorum.
B|Guten Appetit!|Enjoy your meal!|Afiyet olsun!
#u06
A|Was kostet die Jacke?|How much is the jacket?|Ceket ne kadar?
B|Die Jacke kostet fünfzig Euro.|The jacket costs fifty euros.|Ceket elli avro.
A|Das ist zu teuer.|That is too expensive.|Bu çok pahalı.
B|Der Pullover ist billig.|The sweater is cheap.|Kazak ucuz.
A|Haben Sie die Hose auch in Blau?|Do you also have the trousers in blue?|Bu pantolonun mavisi de var mı?
B|Ja, natürlich.|Yes, of course.|Evet, tabii ki.
A|Kann ich mit Karte bezahlen?|Can I pay by card?|Kartla ödeyebilir miyim?
B|Nein, leider nur bar.|No, unfortunately only cash.|Hayır, maalesef sadece nakit.
#u07
A|Wie ist deine Wohnung?|What is your flat like?|Evin nasıl?
B|Sie ist klein, aber hell.|It is small but bright.|Küçük ama aydınlık.
A|Wie viele Zimmer hat die Wohnung?|How many rooms does the flat have?|Dairenin kaç odası var?
B|Sie hat zwei Zimmer, eine Küche und ein Bad.|It has two rooms, a kitchen and a bathroom.|İki oda, bir mutfak ve bir banyosu var.
A|Hast du einen Balkon?|Do you have a balcony?|Balkonun var mı?
B|Nein, ich habe keinen Balkon.|No, I don't have a balcony.|Hayır, balkonum yok.
A|Ist die Miete teuer?|Is the rent expensive?|Kira pahalı mı?
B|Nein, die Miete ist nicht teuer.|No, the rent is not expensive.|Hayır, kira pahalı değil.
#u08
A|Wann stehst du auf?|When do you get up?|Ne zaman kalkıyorsun?
B|Ich stehe um sieben Uhr auf.|I get up at seven o'clock.|Saat yedide kalkıyorum.
A|Was machst du am Morgen?|What do you do in the morning?|Sabah ne yapıyorsun?
B|Ich dusche und frühstücke.|I shower and have breakfast.|Duş alıyorum ve kahvaltı yapıyorum.
A|Wie lange arbeitest du?|How long do you work?|Ne kadar çalışıyorsun?
B|Ich arbeite bis fünf Uhr.|I work until five o'clock.|Saat beşe kadar çalışıyorum.
A|Was machst du am Wochenende?|What do you do at the weekend?|Hafta sonu ne yapıyorsun?
B|Am Samstag kaufe ich ein.|On Saturday I go shopping.|Cumartesi alışveriş yapıyorum.
#u09
A|Was machst du gern?|What do you like to do?|Ne yapmayı seversin?
B|Ich lese gern und spiele Fußball.|I like reading and playing football.|Okumayı ve futbol oynamayı severim.
A|Kannst du schwimmen?|Can you swim?|Yüzebilir misin?
B|Ja, ich kann gut schwimmen.|Yes, I can swim well.|Evet, iyi yüzebilirim.
A|Gehen wir am Freitag ins Kino?|Shall we go to the cinema on Friday?|Cuma sinemaya gidelim mi?
B|Gute Idee! Welcher Film?|Good idea! Which film?|İyi fikir! Hangi film?
A|Spielst du ein Instrument?|Do you play an instrument?|Bir enstrüman çalıyor musun?
B|Ich spiele Gitarre.|I play the guitar.|Gitar çalıyorum.
#u10
A|Entschuldigung, wo ist der Bahnhof?|Excuse me, where is the train station?|Affedersiniz, tren istasyonu nerede?
B|Gehen Sie geradeaus und dann links.|Go straight ahead and then left.|Dümdüz gidin, sonra sola dönün.
A|Ist das weit?|Is it far?|Uzak mı?
B|Nein, nur fünf Minuten.|No, only five minutes.|Hayır, sadece beş dakika.
A|Gibt es hier eine Bank?|Is there a bank here?|Burada banka var mı?
B|Ja, die Bank ist neben der Post.|Yes, the bank is next to the post office.|Evet, banka postanenin yanında.
A|Wo ist das Museum?|Where is the museum?|Müze nerede?
B|Das Museum ist im Zentrum.|The museum is in the centre.|Müze merkezde.
#u11
A|Wann fährt der Zug nach München?|When does the train to Munich leave?|Münih treni ne zaman kalkıyor?
B|Um zehn Uhr von Gleis drei.|At ten o'clock from platform three.|Saat onda, üçüncü perondan.
A|Ich möchte eine Fahrkarte nach Hamburg.|I would like a ticket to Hamburg.|Hamburg'a bir bilet istiyorum.
B|Einfach oder hin und zurück?|One way or return?|Tek yön mü, gidiş-dönüş mü?
A|Muss ich umsteigen?|Do I have to change trains?|Aktarma yapmam gerekiyor mu?
B|Ja, in Hannover.|Yes, in Hanover.|Evet, Hannover'de.
A|Ich fahre mit dem Bus zur Arbeit.|I take the bus to work.|İşe otobüsle gidiyorum.
B|Der Zug hat leider Verspätung.|Unfortunately the train is delayed.|Tren maalesef rötarlı.
#u12
A|Was fehlt Ihnen?|What's wrong with you?|Şikâyetiniz nedir?
B|Ich habe Kopfschmerzen.|I have a headache.|Başım ağrıyor.
A|Haben Sie Fieber?|Do you have a fever?|Ateşiniz var mı?
B|Ja, ich bin krank.|Yes, I am ill.|Evet, hastayım.
A|Nehmen Sie diese Tabletten.|Take these pills.|Bu hapları alın.
B|Wie oft muss ich sie nehmen?|How often do I have to take them?|Ne sıklıkla almam gerekiyor?
A|Dreimal am Tag.|Three times a day.|Günde üç kez.
B|Danke, Frau Doktor.|Thank you, doctor.|Teşekkürler, doktor hanım.
#u13
A|Wie ist das Wetter heute?|What's the weather like today?|Bugün hava nasıl?
B|Es regnet und es ist kalt.|It's raining and it's cold.|Yağmur yağıyor ve hava soğuk.
A|Im Sommer ist es oft heiß.|In summer it is often hot.|Yazın hava genelde sıcak.
B|Im Winter schneit es.|In winter it snows.|Kışın kar yağar.
A|Welche Jahreszeit magst du?|Which season do you like?|Hangi mevsimi seversin?
B|Ich mag den Frühling.|I like spring.|İlkbaharı severim.
A|Mein Geburtstag ist im Mai.|My birthday is in May.|Doğum günüm mayısta.
B|Die Sonne scheint!|The sun is shining!|Güneş parlıyor!
#u14
A|Was bist du von Beruf?|What do you do for a living?|Mesleğin ne?
B|Ich bin Lehrerin.|I am a teacher.|Öğretmenim.
A|Wo arbeitest du?|Where do you work?|Nerede çalışıyorsun?
B|Ich arbeite in einem Büro.|I work in an office.|Bir ofiste çalışıyorum.
A|Gestern habe ich lange gearbeitet.|Yesterday I worked late.|Dün uzun süre çalıştım.
B|Hast du heute frei?|Are you off today?|Bugün izinli misin?
A|Mein Chef ist sehr nett.|My boss is very nice.|Patronum çok iyi.
B|Ich habe eine E-Mail geschrieben.|I wrote an email.|Bir e-posta yazdım.
#u15
A|Was hast du am Wochenende gemacht?|What did you do at the weekend?|Hafta sonu ne yaptın?
B|Ich habe meine Oma besucht.|I visited my grandma.|Büyükannemi ziyaret ettim.
A|Wohin bist du gefahren?|Where did you go?|Nereye gittin?
B|Ich bin nach Hamburg gefahren.|I went to Hamburg.|Hamburg'a gittim.
A|Was ist passiert?|What happened?|Ne oldu?
B|Ich habe meinen Schlüssel verloren.|I lost my key.|Anahtarımı kaybettim.
A|Hast du ihn gefunden?|Did you find it?|Buldun mu?
B|Ja, zum Glück!|Yes, luckily!|Evet, neyse ki!
#u16
A|Wann hast du Geburtstag?|When is your birthday?|Doğum günün ne zaman?
B|Am zwölften März.|On the twelfth of March.|On iki Mart'ta.
A|Herzlichen Glückwunsch zum Geburtstag!|Happy birthday!|Doğum günün kutlu olsun!
B|Danke! Ich lade dich zu meiner Party ein.|Thanks! I'm inviting you to my party.|Teşekkürler! Seni partime davet ediyorum.
A|Was schenkst du deiner Mutter?|What are you giving your mother?|Annene ne hediye ediyorsun?
B|Ich schenke ihr Blumen.|I'm giving her flowers.|Ona çiçek hediye ediyorum.
A|Frohe Weihnachten!|Merry Christmas!|Mutlu Noeller!
B|Wir feiern Silvester mit Freunden.|We celebrate New Year's Eve with friends.|Yılbaşı gecesini arkadaşlarla kutluyoruz.
#u17
A|Warum trennst du den Müll?|Why do you separate the rubbish?|Neden çöpü ayrıştırıyorsun?
B|Weil das in Deutschland wichtig ist.|Because it is important in Germany.|Çünkü bu Almanya'da önemli.
A|Wohin kommt das Papier?|Where does the paper go?|Kâğıt nereye atılır?
B|Das Papier kommt in die blaue Tonne.|The paper goes in the blue bin.|Kâğıt mavi çöp kutusuna atılır.
A|Ich bringe die Flaschen zurück, weil es Pfand gibt.|I'm taking the bottles back because there's a deposit.|Şişeleri geri götürüyorum, çünkü depozito var.
B|Am Sonntag ist Ruhezeit.|On Sunday there are quiet hours.|Pazar günü sessizlik saatleri var.
A|Wir ziehen nächsten Monat um.|We are moving next month.|Gelecek ay taşınıyoruz.
B|Die Nebenkosten sind sehr hoch.|The extra costs are very high.|Ek giderler çok yüksek.
#u18
A|Ich möchte mich anmelden.|I would like to register my address.|İkametimi kaydettirmek istiyorum.
B|Haben Sie einen Termin?|Do you have an appointment?|Randevunuz var mı?
A|Ja, um neun Uhr.|Yes, at nine o'clock.|Evet, saat dokuzda.
B|Bitte füllen Sie dieses Formular aus.|Please fill in this form.|Lütfen bu formu doldurun.
A|Brauchen Sie meinen Pass?|Do you need my passport?|Pasaportuma ihtiyacınız var mı?
B|Ja, und den Mietvertrag.|Yes, and the tenancy agreement.|Evet, bir de kira sözleşmesine.
A|Ich glaube, dass alles fertig ist.|I think that everything is ready.|Sanırım her şey hazır.
B|Unterschreiben Sie bitte hier.|Please sign here.|Lütfen buraya imza atın.
#u19
A|Wie fühlst du dich?|How are you feeling?|Kendini nasıl hissediyorsun?
B|Ich fühle mich nicht gut.|I don't feel well.|Kendimi iyi hissetmiyorum.
A|Was tut dir weh?|What hurts?|Neren ağrıyor?
B|Mein Hals tut weh und ich habe Husten.|My throat hurts and I have a cough.|Boğazım ağrıyor ve öksürüğüm var.
A|Du musst dich ausruhen.|You have to rest.|Dinlenmen lazım.
B|Ich rufe die Praxis an.|I'll call the doctor's office.|Muayenehaneyi arayacağım.
A|Im Notfall rufst du die 112 an.|In an emergency you call 112.|Acil durumda 112'yi ararsın.
B|Gute Besserung!|Get well soon!|Geçmiş olsun!
#u20
A|Wie oft bist du online?|How often are you online?|Ne sıklıkla çevrimiçisin?
B|Ich bin jeden Tag online.|I am online every day.|Her gün çevrimiçiyim.
A|Welche App findest du am besten?|Which app do you like best?|En iyi hangi uygulamayı buluyorsun?
B|Diese App ist besser als die alte.|This app is better than the old one.|Bu uygulama eskisinden daha iyi.
A|Liest du Zeitung?|Do you read the newspaper?|Gazete okur musun?
B|Nein, ich lese die Nachrichten im Internet.|No, I read the news on the internet.|Hayır, haberleri internetten okurum.
A|Wie ist das WLAN-Passwort?|What is the Wi-Fi password?|Wi-Fi şifresi ne?
B|Das Internet ist heute langsamer.|The internet is slower today.|İnternet bugün daha yavaş.
#u21
A|Wohin fährst du in den Urlaub?|Where are you going on holiday?|Tatile nereye gidiyorsun?
B|Ich fahre an die Ostsee.|I'm going to the Baltic Sea.|Baltık Denizi'ne gidiyorum.
A|Hast du schon ein Hotel gebucht?|Have you already booked a hotel?|Otel ayırttın mı?
B|Nein, ich übernachte in einer Jugendherberge.|No, I'm staying in a youth hostel.|Hayır, bir gençlik hostelinde kalacağım.
A|Wie war deine Reise?|How was your trip?|Yolculuğun nasıldı?
B|Sie war toll, aber ich hatte wenig Zeit.|It was great, but I had little time.|Harikaydı ama az zamanım vardı.
A|Wir haben das Schloss besichtigt.|We visited the castle.|Şatoyu gezdik.
B|Ich habe Fernweh!|I have wanderlust!|Uzaklara gitmeyi özledim!
#u22
A|Was möchten Sie bestellen?|What would you like to order?|Ne sipariş etmek istersiniz?
B|Ich nehme das Schnitzel mit Salat.|I'll have the schnitzel with salad.|Salatalı şinitzel alayım.
A|Und als Nachtisch?|And for dessert?|Tatlı olarak?
B|Einen Apfelstrudel, bitte.|An apple strudel, please.|Bir elmalı strudel, lütfen.
A|Hat es Ihnen geschmeckt?|Did you enjoy your meal?|Yemeği beğendiniz mi?
B|Ja, sehr gut. Zahlen, bitte!|Yes, very good. The bill, please!|Evet, çok güzeldi. Hesap, lütfen!
A|Das macht dreiundzwanzig Euro.|That's twenty-three euros.|Yirmi üç avro tutuyor.
B|Fünfundzwanzig, stimmt so.|Twenty-five, keep the change.|Yirmi beş, üstü kalsın.
#u23
A|Wie geht es dir heute?|How are you today?|Bugün nasılsın?
B|Ich bin glücklich, weil die Sonne scheint.|I am happy because the sun is shining.|Mutluyum, çünkü güneş parlıyor.
A|Wenn ich müde bin, bin ich schnell wütend.|When I'm tired, I get angry quickly.|Yorgun olduğumda çabuk sinirlenirim.
B|Ich vermisse meine Familie.|I miss my family.|Ailemi özlüyorum.
A|Wenn du traurig bist, ruf mich an.|If you are sad, call me.|Üzgün olursan beni ara.
B|Danke, du bist ein echter Freund.|Thanks, you are a real friend.|Teşekkürler, gerçek bir arkadaşsın.
A|Ich freue mich auf das Wochenende.|I'm looking forward to the weekend.|Hafta sonunu dört gözle bekliyorum.
B|Es tut mir leid.|I'm sorry.|Üzgünüm.
#u24
A|Warum möchten Sie bei uns arbeiten?|Why would you like to work for us?|Neden bizimle çalışmak istiyorsunuz?
B|Ich würde gern in einem internationalen Team arbeiten.|I would like to work in an international team.|Uluslararası bir ekipte çalışmak isterim.
A|Welche Erfahrungen haben Sie?|What experience do you have?|Ne gibi deneyimleriniz var?
B|Ich habe ein Praktikum in Köln gemacht.|I did an internship in Cologne.|Köln'de staj yaptım.
A|Könnten Sie auch in Teilzeit arbeiten?|Could you also work part-time?|Yarı zamanlı da çalışabilir misiniz?
B|Ja, das wäre kein Problem.|Yes, that wouldn't be a problem.|Evet, bu sorun olmaz.
A|Wenn ich mehr Zeit hätte, würde ich eine Ausbildung machen.|If I had more time, I would do vocational training.|Daha çok zamanım olsaydı bir meslek eğitimi alırdım.
B|Ich bin zuverlässig und arbeite gern selbstständig.|I am reliable and like working independently.|Güvenilirim ve bağımsız çalışmayı severim.
#u25
A|Was kann man für die Umwelt tun?|What can one do for the environment?|Çevre için ne yapılabilir?
B|Man kann weniger Plastik benutzen.|You can use less plastic.|Daha az plastik kullanılabilir.
A|In Deutschland wird viel recycelt.|A lot is recycled in Germany.|Almanya'da çok geri dönüşüm yapılıyor.
B|Der Müll wird jeden Montag abgeholt.|The rubbish is collected every Monday.|Çöpler her pazartesi toplanıyor.
A|Wir sollten mehr Energie sparen.|We should save more energy.|Daha çok enerji tasarrufu yapmalıyız.
B|Ich fahre Fahrrad, weil es umweltfreundlich ist.|I cycle because it's eco-friendly.|Bisiklete biniyorum, çünkü çevre dostu.
A|Der Klimawandel ist ein großes Problem.|Climate change is a big problem.|İklim değişikliği büyük bir sorun.
B|Solarenergie ist erneuerbar.|Solar energy is renewable.|Güneş enerjisi yenilenebilir.
#u26
A|Wann fiel die Berliner Mauer?|When did the Berlin Wall fall?|Berlin Duvarı ne zaman yıkıldı?
B|Die Mauer fiel im Jahr 1989.|The wall fell in 1989.|Duvar 1989'da yıkıldı.
A|Deutschland war viele Jahre geteilt.|Germany was divided for many years.|Almanya uzun yıllar bölünmüştü.
B|1990 kam die Wiedervereinigung.|Reunification came in 1990.|1990'da yeniden birleşme geldi.
A|Deutschland hat sechzehn Bundesländer.|Germany has sixteen federal states.|Almanya'nın on altı eyaleti var.
B|Die Hauptstadt ist Berlin.|The capital is Berlin.|Başkent Berlin'dir.
A|In den Sechzigerjahren kamen viele Gastarbeiter aus der Türkei.|In the sixties many guest workers came from Turkey.|Altmışlı yıllarda Türkiye'den birçok misafir işçi geldi.
B|Die Gesellschaft ist heute sehr vielfältig.|Society today is very diverse.|Toplum bugün çok çeşitli.
#u27
A|Was studierst du?|What are you studying?|Üniversitede ne okuyorsun?
B|Ich studiere Informatik.|I study computer science.|Bilgisayar bilimi okuyorum.
A|Das ist der Kurs, den ich sehr mag.|That is the course that I really like.|Bu çok sevdiğim kurs.
B|Die Lehrerin, die uns hilft, ist super.|The teacher who helps us is great.|Bize yardım eden öğretmen harika.
A|Hast du die Prüfung bestanden?|Did you pass the exam?|Sınavı geçtin mi?
B|Ja, mit einer guten Note!|Yes, with a good grade!|Evet, iyi bir notla!
A|In Deutschland machen viele eine Ausbildung.|In Germany many people do vocational training.|Almanya'da birçok kişi meslek eğitimi alıyor.
B|Nach dem Abitur möchte ich studieren.|After the Abitur I want to go to university.|Abitur'dan sonra üniversitede okumak istiyorum.
#u28
A|Was ist deine Meinung dazu?|What's your opinion on that?|Bu konuda fikrin ne?
B|Ich finde, dass Homeoffice viele Vorteile hat.|I think working from home has many advantages.|Bence evden çalışmanın birçok avantajı var.
A|Einerseits spart man Zeit, andererseits ist man oft allein.|On the one hand you save time, on the other hand you are often alone.|Bir yandan zaman kazanılıyor, öte yandan insan çoğu zaman yalnız kalıyor.
B|Obwohl es praktisch ist, fehlt mir das Team.|Although it's practical, I miss the team.|Pratik olmasına rağmen ekibimi özlüyorum.
A|Ich stimme dir zu.|I agree with you.|Sana katılıyorum.
B|Da muss ich widersprechen.|I have to disagree there.|Burada itiraz etmeliyim.
A|Es ist wichtig, die eigene Meinung zu sagen.|It is important to say your own opinion.|Kendi fikrini söylemek önemli.
B|Trotzdem sollten wir einen Kompromiss finden.|Nevertheless we should find a compromise.|Yine de bir uzlaşma bulmalıyız.
#u29
A|Gehst du gern ins Theater?|Do you like going to the theatre?|Tiyatroya gitmeyi sever misin?
B|Ja, besonders wegen der guten Schauspieler.|Yes, especially because of the good actors.|Evet, özellikle iyi oyuncular sayesinde.
A|Kennst du die Märchen der Brüder Grimm?|Do you know the fairy tales of the Brothers Grimm?|Grimm Kardeşlerin masallarını biliyor musun?
B|Ja, „Hänsel und Gretel“ ist mein Lieblingsmärchen.|Yes, "Hansel and Gretel" is my favourite fairy tale.|Evet, "Hansel ile Gretel" en sevdiğim masal.
A|Trotz des Regens gingen wir zur Ausstellung.|Despite the rain we went to the exhibition.|Yağmura rağmen sergiye gittik.
B|Goethe ist einer der berühmtesten Dichter Deutschlands.|Goethe is one of Germany's most famous poets.|Goethe, Almanya'nın en ünlü şairlerinden biridir.
A|Der Film des Regisseurs war sehr spannend.|The director's film was very exciting.|Yönetmenin filmi çok heyecanlıydı.
B|Ich lese gerade einen Roman von Kafka.|I am reading a novel by Kafka right now.|Şu an Kafka'nın bir romanını okuyorum.
''';

Map<String, List<Phrase>> _parsePhrases() {
  final m = <String, List<Phrase>>{};
  var unit = '';
  for (final line in _phrases.split('\n')) {
    final l = line.trim();
    if (l.isEmpty) continue;
    if (l.startsWith('#')) {
      unit = l.substring(1);
      continue;
    }
    final p = l.split('|');
    if (p.length < 4) continue;
    final list = m[unit] ??= [];
    list.add(Phrase(id: '${unit}_p${list.length}', speaker: p[0], de: p[1], en: p[2], tr: p[3]));
  }
  return m;
}

final Map<String, List<Phrase>> unitPhrases = _parsePhrases();

final Map<String, Phrase> phrasesById = {for (final l in unitPhrases.values) for (final p in l) p.id: p};
