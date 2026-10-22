import 'models.dart';

/// Starter vocabulary: de | en | tr | example | level | topic
const _raw = '''
Hallo|hello|merhaba|Hallo, ich bin Anna.|A1|greetings
Guten Morgen|good morning|günaydın|Guten Morgen, wie geht's?|A1|greetings
Tschüss|bye|hoşça kal|Tschüss, bis morgen!|A1|greetings
Danke|thank you|teşekkürler|Danke für deine Hilfe.|A1|greetings
Bitte|please / you're welcome|lütfen / rica ederim|Einen Kaffee, bitte.|A1|greetings
Entschuldigung|excuse me / sorry|affedersiniz / özür dilerim|Entschuldigung, wo ist der Bahnhof?|A1|greetings
ja|yes|evet|Ja, gern.|A1|greetings
nein|no|hayır|Nein, danke.|A1|greetings
das Wasser|water|su|Ich trinke Wasser.|A1|food
das Brot|bread|ekmek|Das Brot ist frisch.|A1|food
die Brezel|pretzel|Brezel (tuzlu Alman çöreği)|Ich esse eine Brezel.|A1|food
der Kaffee|coffee|kahve|Ich möchte einen Kaffee.|A1|food
der Käse|cheese|peynir|Der Käse schmeckt gut.|A1|food
der Apfel|apple|elma|Der Apfel ist rot.|A1|food
die Milch|milk|süt|Die Milch ist kalt.|A1|food
das Bier|beer|bira|Ein Bier, bitte.|A1|food
die Wurst|sausage|sosis|Die Wurst ist lecker.|A1|food
der Kuchen|cake|kek / pasta|Wir essen Kuchen.|A1|food
essen|to eat|yemek yemek|Wir essen um zwölf.|A1|verbs
trinken|to drink|içmek|Ich trinke Tee.|A1|verbs
gehen|to go|gitmek|Ich gehe nach Hause.|A1|verbs
kommen|to come|gelmek|Er kommt aus der Türkei.|A1|verbs
machen|to do / make|yapmak|Was machst du?|A1|verbs
haben|to have|sahip olmak|Ich habe einen Hund.|A1|verbs
sein|to be|olmak|Ich bin müde.|A1|verbs
wohnen|to live (reside)|oturmak (ikamet etmek)|Ich wohne in Berlin.|A1|verbs
sprechen|to speak|konuşmak|Sprichst du Deutsch?|A1|verbs
lernen|to learn|öğrenmek|Ich lerne Deutsch.|A1|verbs
arbeiten|to work|çalışmak|Ich arbeite viel.|A1|verbs
kaufen|to buy|satın almak|Ich kaufe Brot.|A1|verbs
verstehen|to understand|anlamak|Ich verstehe nicht.|A1|verbs
die Familie|family|aile|Meine Familie ist groß.|A1|people
die Mutter|mother|anne|Meine Mutter kocht gern.|A1|people
der Vater|father|baba|Mein Vater arbeitet.|A1|people
der Bruder|brother|erkek kardeş|Mein Bruder heißt Tim.|A1|people
die Schwester|sister|kız kardeş|Meine Schwester ist Ärztin.|A1|people
der Freund|friend (male)|arkadaş (erkek)|Er ist mein Freund.|A1|people
die Freundin|friend (female)|arkadaş (kadın)|Sie ist meine Freundin.|A1|people
das Kind|child|çocuk|Das Kind spielt.|A1|people
der Mann|man|adam|Der Mann liest.|A1|people
die Frau|woman|kadın|Die Frau lacht.|A1|people
das Haus|house|ev|Das Haus ist groß.|A1|home
die Wohnung|apartment|daire|Die Wohnung ist klein.|A1|home
der Tisch|table|masa|Der Tisch ist rund.|A1|home
der Stuhl|chair|sandalye|Der Stuhl ist bequem.|A1|home
das Fenster|window|pencere|Das Fenster ist offen.|A1|home
die Tür|door|kapı|Mach die Tür zu.|A1|home
das Zimmer|room|oda|Mein Zimmer ist hell.|A1|home
die Küche|kitchen|mutfak|Die Küche ist sauber.|A1|home
der Hund|dog|köpek|Der Hund bellt.|A1|animals
die Katze|cat|kedi|Die Katze schläft.|A1|animals
der Bär|bear|ayı|Der Bär mag Honig.|A1|animals
der Fuchs|fox|tilki|Der Fuchs ist schlau.|A1|animals
groß|big / tall|büyük / uzun|Berlin ist groß.|A1|adjectives
klein|small|küçük|Das Auto ist klein.|A1|adjectives
gut|good|iyi|Das Essen ist gut.|A1|adjectives
schlecht|bad|kötü|Das Wetter ist schlecht.|A1|adjectives
schön|beautiful / nice|güzel|Der Park ist schön.|A1|adjectives
müde|tired|yorgun|Ich bin müde.|A1|adjectives
heute|today|bugün|Heute scheint die Sonne.|A1|time
morgen|tomorrow|yarın|Morgen habe ich frei.|A1|time
gestern|yesterday|dün|Gestern war es kalt.|A1|time
die Woche|week|hafta|Nächste Woche reise ich.|A1|time
das Wetter|weather|hava durumu|Das Wetter ist schön.|A1|time
eins|one|bir|Ich habe eins.|A1|numbers
zwei|two|iki|Zwei Bier, bitte.|A1|numbers
drei|three|üç|Es sind drei Uhr.|A1|numbers
die Stadt|city|şehir|Die Stadt ist alt.|A1|places
der Bahnhof|train station|tren istasyonu|Der Bahnhof ist weit.|A1|places
die Straße|street|sokak / cadde|Die Straße ist lang.|A1|places
der Supermarkt|supermarket|süpermarket|Ich gehe zum Supermarkt.|A1|places
die Schule|school|okul|Die Schule beginnt um acht.|A1|places
das Auto|car|araba|Das Auto ist neu.|A1|places
der Zug|train|tren|Der Zug hat Verspätung.|A2|travel
die Verspätung|delay|gecikme|Die Bahn hat wieder Verspätung.|A2|travel
die Fahrkarte|ticket|bilet|Ich brauche eine Fahrkarte.|A2|travel
das Gleis|platform / track|peron / ray|Der Zug fährt von Gleis drei.|A2|travel
der Flughafen|airport|havalimanı|Der Flughafen ist groß.|A2|travel
der Termin|appointment|randevu|Ich habe einen Termin beim Arzt.|A2|life
die Rechnung|bill / invoice|fatura / hesap|Die Rechnung, bitte.|A2|life
die Miete|rent|kira|Die Miete ist teuer.|A2|life
der Arzt|doctor|doktor|Ich gehe zum Arzt.|A2|life
das Geld|money|para|Ich habe kein Geld dabei.|A2|life
die Arbeit|work / job|iş|Die Arbeit macht Spaß.|A2|life
der Feierabend|end of the workday|iş çıkışı / paydos|Endlich Feierabend!|A2|culture
das Pfand|bottle deposit|depozito (şişe iadesi)|Die Flasche hat 25 Cent Pfand.|A2|culture
die Mülltrennung|waste separation|çöp ayrıştırma|Mülltrennung ist in Deutschland wichtig.|A2|culture
pünktlich|punctual / on time|dakik|Der Zug ist pünktlich.|A2|culture
gemütlich|cosy / comfortable|rahat, sıcak (gemütlich)|Das Café ist gemütlich.|A2|culture
der Biergarten|beer garden|bira bahçesi|Wir sitzen im Biergarten.|A2|culture
der Stammtisch|regulars' table|düzenli buluşma masası|Am Freitag ist Stammtisch.|A2|culture
die Bürokratie|bureaucracy|bürokrasi|Die Bürokratie braucht Geduld.|B1|culture
das Fernweh|wanderlust (longing for far places)|uzak yerlere özlem|Ich habe Fernweh.|B1|culture
die Ruhezeit|quiet hours|sessizlik saatleri|Sonntags ist Ruhezeit.|B1|culture
die Schadenfreude|joy at others' misfortune|başkasının talihsizliğine sevinme|Das ist pure Schadenfreude.|B1|culture
die Vorfreude|anticipation|beklenti sevinci|Ich habe Vorfreude auf den Urlaub.|B1|culture
der Kummer|grief / worry|dert / keder|Er hat viel Kummer.|B1|feelings
sich freuen|to be glad|sevinmek|Ich freue mich auf das Wochenende.|B1|feelings
sich erinnern|to remember|hatırlamak|Ich erinnere mich an den Urlaub.|B1|feelings
verpassen|to miss (a train)|kaçırmak|Ich habe den Zug verpasst.|B1|travel
''';

List<Word> buildSeedWords() {
  final out = <Word>[];
  for (final line in _raw.trim().split('\n')) {
    final p = line.split('|');
    if (p.length < 6) continue;
    out.add(Word(id: Word.idFor(p[0]), de: p[0], en: p[1], tr: p[2], example: p[3], level: p[4], topic: p[5]));
  }
  return out;
}

final List<Word> seedWords = buildSeedWords();
