import 'models.dart';

/// Trilingual picture-card vocabulary, grouped by course unit (`#unitId`).
///
/// Columns: emoji | German (nouns with article) | German plural ('-' = none) |
/// English | Turkish | CEFR level | optional German example.
///
/// Topic selection follows the CEFR / Goethe "Start Deutsch 1" theme inventory
/// (person, housing, environment, travel, food, shopping, services, learning,
/// work, leisure) and extends it to A2/B1 everyday life in Germany.
const _bank = r'''
#u01
👋|Hallo||hello|merhaba|A1|Hallo, ich bin Anna.
🌅|Guten Morgen||good morning|günaydın|A1|Guten Morgen, wie geht's?
☀️|Guten Tag||good day / hello|iyi günler|A1|Guten Tag, Frau Schmidt!
🌆|Guten Abend||good evening|iyi akşamlar|A1|Guten Abend zusammen!
🌙|Gute Nacht||good night|iyi geceler|A1|Gute Nacht, schlaf gut!
🙋|Tschüss||bye|hoşça kal|A1|Tschüss, bis morgen!
🤝|Auf Wiedersehen||goodbye|görüşmek üzere|A1|Auf Wiedersehen, Herr Meyer.
🙏|Danke||thank you|teşekkürler|A1|Danke für deine Hilfe.
💁|Bitte||please / you're welcome|lütfen / rica ederim|A1|Einen Kaffee, bitte.
😅|Entschuldigung||excuse me / sorry|affedersiniz / özür dilerim|A1|Entschuldigung, wo ist der Bahnhof?
✅|ja||yes|evet|A1|Ja, gern.
❌|nein||no|hayır|A1|Nein, danke.
🏷️|der Name|Namen|name|isim|A1|Mein Name ist Ali.
📛|heißen||to be called|adı … olmak|A1|Ich heiße Lena.
🟰|sein||to be|olmak|A1|Ich bin müde.
🙂|Wie geht's?||How are you?|Nasılsın?|A1|Hallo Tom, wie geht's?
👍|gut||good|iyi|A1|Das Essen ist gut.
🎉|willkommen||welcome|hoş geldin(iz)|A1|Willkommen in Berlin!
🧑|ich||I|ben|A1|Ich bin Student.
🫵|du||you (informal)|sen|A1|Du bist nett.
🎩|Sie||you (formal)|siz (resmî)|A1|Woher kommen Sie?
#u02
🇩🇪|Deutschland|-|Germany|Almanya|A1|Ich wohne in Deutschland.
🇹🇷|die Türkei|-|Turkey|Türkiye|A1|Ich komme aus der Türkei.
🇦🇹|Österreich|-|Austria|Avusturya|A1|Wien ist in Österreich.
🇨🇭|die Schweiz|-|Switzerland|İsviçre|A1|Die Schweiz hat vier Sprachen.
🇬🇧|England|-|England|İngiltere|A1|London ist in England.
🇺🇸|die USA|-|the USA|ABD|A1|Sie kommt aus den USA.
🇫🇷|Frankreich|-|France|Fransa|A1|Paris ist in Frankreich.
🇮🇹|Italien|-|Italy|İtalya|A1|Die Pizza kommt aus Italien.
🇪🇸|Spanien|-|Spain|İspanya|A1|Spanien ist im Sommer heiß.
🗺️|das Land|Länder|country|ülke|A1|Welches Land ist das?
🗣️|die Sprache|Sprachen|language|dil|A1|Ich spreche zwei Sprachen.
🇩🇪|Deutsch||German (language)|Almanca|A1|Ich lerne Deutsch.
🇬🇧|Englisch||English (language)|İngilizce|A1|Sprichst du Englisch?
🇹🇷|Türkisch||Turkish (language)|Türkçe|A1|Meine Mutter spricht Türkisch.
🛬|kommen||to come|gelmek|A1|Er kommt aus der Türkei.
🏠|wohnen||to live (reside)|oturmak (ikamet etmek)|A1|Ich wohne in Berlin.
💬|sprechen||to speak|konuşmak|A1|Sprichst du Deutsch?
📚|lernen||to learn|öğrenmek|A1|Ich lerne Deutsch.
🧭|woher||where from|nereden|A1|Woher kommst du?
📍|wo||where|nerede|A1|Wo wohnst du?
🌐|das Ausland|-|abroad|yurt dışı|A2|Sie lebt im Ausland.
🤔|verstehen||to understand|anlamak|A1|Ich verstehe nicht.
#u03
0️⃣|null||zero|sıfır|A1|
1️⃣|eins||one|bir|A1|Ich habe eins.
2️⃣|zwei||two|iki|A1|Zwei Bier, bitte.
3️⃣|drei||three|üç|A1|Es ist drei Uhr.
4️⃣|vier||four|dört|A1|
5️⃣|fünf||five|beş|A1|
6️⃣|sechs||six|altı|A1|
7️⃣|sieben||seven|yedi|A1|
8️⃣|acht||eight|sekiz|A1|
9️⃣|neun||nine|dokuz|A1|
🔟|zehn||ten|on|A1|Das kostet zehn Euro.
🕚|elf||eleven|on bir|A1|
🕛|zwölf||twelve|on iki|A1|Wir essen um zwölf.
🔢|zwanzig||twenty|yirmi|A1|Ich bin zwanzig Jahre alt.
🔢|dreißig||thirty|otuz|A1|
💯|hundert||hundred|yüz|A1|
🔢|tausend||thousand|bin|A1|
📅|das Jahr|Jahre|year|yıl|A1|Ich bin 25 Jahre alt.
☎️|die Telefonnummer|Telefonnummern|phone number|telefon numarası|A1|Wie ist deine Telefonnummer?
🧓|alt||old|yaşlı / eski|A1|Wie alt bist du?
🧒|jung||young|genç|A1|Er ist noch jung.
❓|wie viel||how much|ne kadar / kaç|A1|Wie viel kostet das?
#u04
👨‍👩‍👧|die Familie|Familien|family|aile|A1|Meine Familie ist groß.
👩|die Mutter|Mütter|mother|anne|A1|Meine Mutter kocht gern.
👨|der Vater|Väter|father|baba|A1|Mein Vater arbeitet.
👫|die Eltern|-|parents|ebeveynler / anne baba|A1|Meine Eltern wohnen in Izmir.
👦|der Bruder|Brüder|brother|erkek kardeş|A1|Mein Bruder heißt Tim.
👧|die Schwester|Schwestern|sister|kız kardeş|A1|Meine Schwester ist Ärztin.
🧑‍🤝‍🧑|die Geschwister|-|siblings|kardeşler|A1|Hast du Geschwister?
👶|der Sohn|Söhne|son|oğul|A1|Ihr Sohn ist fünf.
👧|die Tochter|Töchter|daughter|kız evlat|A1|Seine Tochter studiert.
🧒|das Kind|Kinder|child|çocuk|A1|Das Kind spielt.
🍼|das Baby|Babys|baby|bebek|A1|Das Baby schläft.
👴|der Großvater|Großväter|grandfather|büyükbaba / dede|A1|Mein Großvater ist 80.
👵|die Großmutter|Großmütter|grandmother|büyükanne / nine|A1|Meine Großmutter backt Kuchen.
🧔|der Onkel|Onkel|uncle|amca / dayı|A1|Mein Onkel wohnt in Köln.
👩‍🦰|die Tante|Tanten|aunt|teyze / hala|A1|Meine Tante ist lustig.
👨‍💼|der Mann|Männer|man / husband|adam / koca|A1|Der Mann liest.
👩‍💼|die Frau|Frauen|woman / wife / Mrs|kadın / eş / bayan|A1|Die Frau lacht.
💍|verheiratet||married|evli|A1|Ich bin verheiratet.
🧍|ledig||single|bekâr|A1|Er ist ledig.
🤜|der Freund|Freunde|friend (male) / boyfriend|arkadaş (erkek) / erkek arkadaş|A1|Er ist mein Freund.
👭|die Freundin|Freundinnen|friend (female) / girlfriend|arkadaş (kadın) / kız arkadaş|A1|Sie ist meine Freundin.
🤲|haben||to have|sahip olmak|A1|Ich habe einen Hund.
#u05
🍞|das Brot|Brote|bread|ekmek|A1|Das Brot ist frisch.
🥖|das Brötchen|Brötchen|bread roll|küçük ekmek (Brötchen)|A1|Zum Frühstück esse ich ein Brötchen.
🥨|die Brezel|Brezeln|pretzel|Brezel (tuzlu Alman çöreği)|A1|Ich esse eine Brezel.
🧈|die Butter|-|butter|tereyağı|A1|Die Butter ist im Kühlschrank.
🧀|der Käse|-|cheese|peynir|A1|Der Käse schmeckt gut.
🌭|die Wurst|Würste|sausage|sosis|A1|Die Wurst ist lecker.
🥚|das Ei|Eier|egg|yumurta|A1|Ich esse ein Ei.
🍎|der Apfel|Äpfel|apple|elma|A1|Der Apfel ist rot.
🍌|die Banane|Bananen|banana|muz|A1|Die Banane ist gelb.
🍊|die Orange|Orangen|orange|portakal|A1|Die Orange ist süß.
🍅|die Tomate|Tomaten|tomato|domates|A1|Ich kaufe Tomaten.
🥔|die Kartoffel|Kartoffeln|potato|patates|A1|Wir essen Kartoffeln.
🥗|der Salat|Salate|salad / lettuce|salata / marul|A1|Der Salat ist frisch.
🥩|das Fleisch|-|meat|et|A1|Ich esse kein Fleisch.
🐟|der Fisch|Fische|fish|balık|A1|Der Fisch schwimmt.
🍗|das Hähnchen|Hähnchen|chicken (food)|tavuk|A1|Das Hähnchen ist heiß.
🍲|die Suppe|Suppen|soup|çorba|A1|Die Suppe ist warm.
🍝|die Nudeln|-|pasta / noodles|makarna|A1|Die Kinder essen gern Nudeln.
🍚|der Reis|-|rice|pirinç / pilav|A1|Ich koche Reis.
🍰|der Kuchen|Kuchen|cake|kek / pasta|A1|Wir essen Kuchen.
🍫|die Schokolade|Schokoladen|chocolate|çikolata|A1|Ich liebe Schokolade.
🍦|das Eis|-|ice cream / ice|dondurma / buz|A1|Im Sommer essen wir Eis.
🍬|der Zucker|-|sugar|şeker|A1|Kaffee ohne Zucker, bitte.
🧂|das Salz|-|salt|tuz|A1|Die Suppe braucht Salz.
☕|der Kaffee|-|coffee|kahve|A1|Ich möchte einen Kaffee.
🍵|der Tee|Tees|tea|çay|A1|Ich trinke Tee.
💧|das Wasser|-|water|su|A1|Ich trinke Wasser.
🥛|die Milch|-|milk|süt|A1|Die Milch ist kalt.
🧃|der Saft|Säfte|juice|meyve suyu|A1|Einen Apfelsaft, bitte.
🍺|das Bier|Biere|beer|bira|A1|Ein Bier, bitte.
🍷|der Wein|Weine|wine|şarap|A1|Der Wein kommt aus Italien.
🍳|das Frühstück|-|breakfast|kahvaltı|A1|Das Frühstück ist fertig.
🍛|das Mittagessen|-|lunch|öğle yemeği|A1|Das Mittagessen ist um zwölf.
🍽️|das Abendessen|-|dinner|akşam yemeği|A1|Wir kochen das Abendessen.
😋|essen||to eat|yemek yemek|A1|Wir essen um zwölf.
🥤|trinken||to drink|içmek|A1|Ich trinke Tee.
🙋‍♀️|möchten||would like|istemek (rica)|A1|Ich möchte ein Wasser.
🤤|lecker||tasty|lezzetli|A1|Der Kuchen ist lecker.
🍴|die Gabel|Gabeln|fork|çatal|A1|Wo ist die Gabel?
🔪|das Messer|Messer|knife|bıçak|A1|Das Messer ist scharf.
🥄|der Löffel|Löffel|spoon|kaşık|A1|Ich brauche einen Löffel.
🍽|der Teller|Teller|plate|tabak|A1|Der Teller ist leer.
🫖|die Tasse|Tassen|cup|fincan|A1|Eine Tasse Tee, bitte.
🥃|das Glas|Gläser|glass|bardak / cam|A1|Ein Glas Wasser, bitte.
🧑‍🍳|das Restaurant|Restaurants|restaurant|restoran|A1|Das Restaurant ist voll.
📜|die Speisekarte|Speisekarten|menu|menü|A1|Die Speisekarte, bitte.
🧾|die Rechnung|Rechnungen|bill / invoice|fatura / hesap|A2|Die Rechnung, bitte.
😩|der Hunger|-|hunger|açlık|A1|Ich habe Hunger.
🏪|das Café|Cafés|café|kafe|A1|Wir treffen uns im Café.
#u06
🛒|kaufen||to buy|satın almak|A1|Ich kaufe Brot.
🏷️|kosten||to cost|(fiyatı) tutmak|A1|Was kostet das?
💶|der Euro|Euro|euro|avro|A1|Das kostet zwei Euro.
💰|das Geld|-|money|para|A2|Ich habe kein Geld dabei.
💸|teuer||expensive|pahalı|A1|Das Auto ist teuer.
🪙|billig||cheap|ucuz|A1|Der Pullover ist billig.
🏬|der Supermarkt|Supermärkte|supermarket|süpermarket|A1|Ich gehe zum Supermarkt.
🥐|die Bäckerei|Bäckereien|bakery|fırın|A1|Die Bäckerei öffnet um sechs.
⚕️|die Apotheke|Apotheken|pharmacy|eczane|A1|Die Apotheke ist am Markt.
🧺|der Markt|Märkte|market|pazar|A1|Am Samstag ist Markt.
🛍️|das Geschäft|Geschäfte|shop|dükkân|A1|Das Geschäft ist geschlossen.
💳|die Karte|Karten|card / map / ticket|kart / harita / bilet|A1|Kann ich mit Karte zahlen?
💵|bar||in cash|nakit|A1|Ich zahle bar.
🤑|bezahlen||to pay|ödemek|A1|Ich bezahle an der Kasse.
🧮|die Kasse|Kassen|checkout / till|kasa|A1|Die Kasse ist dort.
👖|die Hose|Hosen|trousers|pantolon|A1|Die Hose ist zu lang.
👔|das Hemd|Hemden|shirt|gömlek|A1|Das Hemd ist weiß.
👕|das T-Shirt|T-Shirts|T-shirt|tişört|A1|Das T-Shirt ist blau.
🧶|der Pullover|Pullover|sweater|kazak|A1|Der Pullover ist warm.
🧥|die Jacke|Jacken|jacket|ceket / mont|A1|Die Jacke kostet fünfzig Euro.
🥼|der Mantel|Mäntel|coat|palto|A1|Im Winter trage ich einen Mantel.
👗|das Kleid|Kleider|dress|elbise|A1|Das Kleid ist schön.
👚|der Rock|Röcke|skirt|etek|A1|Der Rock ist kurz.
👞|der Schuh|Schuhe|shoe|ayakkabı|A1|Die Schuhe sind neu.
🧦|die Socke|Socken|sock|çorap|A1|Wo sind meine Socken?
🎩|der Hut|Hüte|hat|şapka|A1|Der Hut ist schwarz.
🧢|die Mütze|Mützen|cap / beanie|bere|A1|Die Mütze ist warm.
👜|die Tasche|Taschen|bag|çanta|A1|Meine Tasche ist schwer.
👓|die Brille|Brillen|glasses|gözlük|A1|Ich brauche eine Brille.
🔴|rot||red|kırmızı|A1|Der Apfel ist rot.
🔵|blau||blue|mavi|A1|Der Himmel ist blau.
🟢|grün||green|yeşil|A1|Das Gras ist grün.
🟡|gelb||yellow|sarı|A1|Die Sonne ist gelb.
⚫|schwarz||black|siyah|A1|Die Katze ist schwarz.
⚪|weiß||white|beyaz|A1|Der Schnee ist weiß.
🩶|grau||grey|gri|A1|Der Himmel ist grau.
🟤|braun||brown|kahverengi|A1|Der Bär ist braun.
🟠|orange||orange (colour)|turuncu|A1|Die Jacke ist orange.
🩷|rosa||pink|pembe|A1|Das Kleid ist rosa.
🟣|lila||purple|mor|A1|Die Blume ist lila.
🎨|die Farbe|Farben|colour|renk|A1|Welche Farbe magst du?
#u07
🏠|das Haus|Häuser|house|ev|A1|Das Haus ist groß.
🏢|die Wohnung|Wohnungen|apartment|daire|A1|Die Wohnung ist klein.
🚪|das Zimmer|Zimmer|room|oda|A1|Mein Zimmer ist hell.
🍳|die Küche|Küchen|kitchen|mutfak|A1|Die Küche ist sauber.
🛁|das Bad|Bäder|bathroom|banyo|A1|Das Bad ist neu.
🛌|das Schlafzimmer|Schlafzimmer|bedroom|yatak odası|A1|Das Schlafzimmer ist ruhig.
🛋️|das Wohnzimmer|Wohnzimmer|living room|oturma odası|A1|Wir sitzen im Wohnzimmer.
🌇|der Balkon|Balkone|balcony|balkon|A1|Der Balkon hat Blumen.
🌷|der Garten|Gärten|garden|bahçe|A1|Der Garten ist groß.
🚪|die Tür|Türen|door|kapı|A1|Mach die Tür zu.
🪟|das Fenster|Fenster|window|pencere|A1|Das Fenster ist offen.
🪵|der Tisch|Tische|table|masa|A1|Der Tisch ist rund.
🪑|der Stuhl|Stühle|chair|sandalye|A1|Der Stuhl ist bequem.
🛏️|das Bett|Betten|bed|yatak|A1|Das Bett ist weich.
🛋|das Sofa|Sofas|sofa|kanepe|A1|Das Sofa ist grau.
🗄️|der Schrank|Schränke|cupboard / wardrobe|dolap|A1|Der Schrank ist voll.
💡|die Lampe|Lampen|lamp|lamba|A1|Die Lampe ist kaputt.
🧊|der Kühlschrank|Kühlschränke|fridge|buzdolabı|A1|Die Milch ist im Kühlschrank.
🔥|der Herd|Herde|stove|ocak|A2|Der Herd ist heiß.
🫧|die Waschmaschine|Waschmaschinen|washing machine|çamaşır makinesi|A2|Die Waschmaschine ist im Keller.
📺|der Fernseher|Fernseher|TV set|televizyon|A1|Der Fernseher ist alt.
🪜|die Treppe|Treppen|stairs|merdiven|A1|Die Treppe ist steil.
🔑|der Schlüssel|Schlüssel|key|anahtar|A1|Wo ist mein Schlüssel?
🏷|die Miete|Mieten|rent|kira|A2|Die Miete ist teuer.
✨|neu||new|yeni|A1|Die Wohnung ist neu.
🔆|hell||bright|aydınlık|A1|Das Zimmer ist hell.
🌑|dunkel||dark|karanlık|A1|Im Winter ist es früh dunkel.
🐘|groß||big / tall|büyük / uzun|A1|Berlin ist groß.
🐁|klein||small|küçük|A1|Das Auto ist klein.
🧹|sauber||clean|temiz|A1|Die Küche ist sauber.
😌|gemütlich||cosy|rahat, sıcak (gemütlich)|A2|Das Café ist gemütlich.
🛋️|bequem||comfortable|rahat|A1|Das Sofa ist bequem.
🙅|kein||no / not a|hiç / yok (olumsuz)|A1|Ich habe kein Auto.
🚫|nicht||not|değil / -me|A1|Das ist nicht teuer.
#u08
⏰|aufstehen||to get up|kalkmak|A1|Ich stehe um sieben Uhr auf.
🥐|frühstücken||to have breakfast|kahvaltı yapmak|A1|Wir frühstücken zusammen.
💼|arbeiten||to work|çalışmak|A1|Ich arbeite viel.
😴|schlafen||to sleep|uyumak|A1|Das Baby schläft.
🚿|duschen||to shower|duş almak|A1|Ich dusche am Morgen.
👨‍🍳|kochen||to cook|yemek pişirmek|A1|Mein Vater kocht gern.
🛒|einkaufen||to go shopping|alışveriş yapmak|A1|Am Samstag kaufe ich ein.
🚶|gehen||to go / walk|gitmek / yürümek|A1|Ich gehe nach Hause.
🔧|machen||to do / make|yapmak|A1|Was machst du?
🌄|der Morgen|Morgen|morning|sabah|A1|Am Morgen trinke ich Kaffee.
🕛|der Mittag|Mittage|noon|öğle|A1|Am Mittag esse ich Suppe.
🌇|der Nachmittag|Nachmittage|afternoon|öğleden sonra|A1|Am Nachmittag lerne ich.
🌆|der Abend|Abende|evening|akşam|A1|Am Abend sehe ich fern.
🌃|die Nacht|Nächte|night|gece|A1|Die Nacht ist kalt.
🕐|die Uhr|Uhren|clock / o'clock|saat|A1|Es ist acht Uhr.
⏳|die Stunde|Stunden|hour|saat (süre)|A1|Der Kurs dauert eine Stunde.
⏱️|die Minute|Minuten|minute|dakika|A1|Ich komme in fünf Minuten.
📅|heute||today|bugün|A1|Heute scheint die Sonne.
➡️|morgen||tomorrow|yarın|A1|Morgen habe ich frei.
⬅️|gestern||yesterday|dün|A1|Gestern war es kalt.
🐓|früh||early|erken|A1|Ich stehe früh auf.
🦉|spät||late|geç|A1|Es ist schon spät.
♾️|immer||always|her zaman|A1|Ich trinke immer Kaffee.
🔁|oft||often|sık sık|A1|Wir gehen oft spazieren.
🎲|manchmal||sometimes|bazen|A1|Manchmal koche ich.
🙅‍♂️|nie||never|asla / hiç|A1|Ich rauche nie.
🗓️|der Montag|Montage|Monday|pazartesi|A1|Am Montag arbeite ich.
🗓️|der Dienstag|Dienstage|Tuesday|salı|A1|Am Dienstag habe ich Deutschkurs.
🗓️|der Mittwoch|Mittwoche|Wednesday|çarşamba|A1|Am Mittwoch gehe ich schwimmen.
🗓️|der Donnerstag|Donnerstage|Thursday|perşembe|A1|Am Donnerstag kommt meine Mutter.
🗓️|der Freitag|Freitage|Friday|cuma|A1|Am Freitag gehe ich ins Kino.
🗓️|der Samstag|Samstage|Saturday|cumartesi|A1|Am Samstag kaufe ich ein.
🗓️|der Sonntag|Sonntage|Sunday|pazar|A1|Am Sonntag schlafe ich lange.
📆|die Woche|Wochen|week|hafta|A1|Nächste Woche reise ich.
🎉|das Wochenende|Wochenenden|weekend|hafta sonu|A1|Schönes Wochenende!
🍻|der Feierabend|-|end of the workday|iş çıkışı / paydos|A2|Endlich Feierabend!
⌚|pünktlich||punctual / on time|dakik|A2|Der Zug ist pünktlich.
🥱|müde||tired|yorgun|A1|Ich bin müde.
#u09
🎯|das Hobby|Hobbys|hobby|hobi|A1|Mein Hobby ist Lesen.
🧸|spielen||to play|oynamak|A1|Die Kinder spielen im Garten.
📖|lesen||to read|okumak|A1|Ich lese ein Buch.
🏊|schwimmen||to swim|yüzmek|A1|Kannst du schwimmen?
💃|tanzen||to dance|dans etmek|A1|Wir tanzen gern.
🎤|singen||to sing|şarkı söylemek|A1|Sie singt sehr schön.
🖌️|malen||to paint|resim yapmak|A1|Mein Sohn malt ein Bild.
🥾|wandern||to hike|doğa yürüyüşü yapmak|A1|Wir wandern in den Bergen.
📷|fotografieren||to take photos|fotoğraf çekmek|A1|Ich fotografiere gern.
⚽|der Fußball|-|football / soccer|futbol|A1|Er spielt Fußball.
🎾|das Tennis|-|tennis|tenis|A1|Spielst du Tennis?
🎵|die Musik|-|music|müzik|A1|Ich höre Musik.
📕|das Buch|Bücher|book|kitap|A1|Das Buch ist spannend.
🎬|der Film|Filme|film|film|A1|Der Film ist lustig.
🍿|das Kino|Kinos|cinema|sinema|A1|Gehen wir ins Kino?
🎶|das Konzert|Konzerte|concert|konser|A1|Das Konzert beginnt um acht.
🎸|die Gitarre|Gitarren|guitar|gitar|A1|Ich spiele Gitarre.
🎹|das Klavier|Klaviere|piano|piyano|A1|Sie spielt Klavier.
🚲|das Fahrrad|Fahrräder|bicycle|bisiklet|A1|Ich fahre mit dem Fahrrad.
❤️|gern||gladly / like to|severek|A1|Ich lese gern.
💪|können||can / to be able to|-ebilmek|A1|Kannst du schwimmen?
🤝|treffen||to meet|buluşmak|A1|Wir treffen uns im Park.
🏋️|der Sport|-|sport|spor|A1|Ich mache gern Sport.
🧘|die Freizeit|-|free time|boş zaman|A1|Was machst du in der Freizeit?
🎮|das Spiel|Spiele|game / match|oyun / maç|A1|Das Spiel ist spannend.
🍻|die Kneipe|Kneipen|pub|bar / meyhane (Kneipe)|A2|Wir gehen in die Kneipe.
🌳|der Biergarten|Biergärten|beer garden|bira bahçesi|A2|Wir sitzen im Biergarten.
🪑|der Stammtisch|Stammtische|regulars' table|düzenli buluşma masası|A2|Am Freitag ist Stammtisch.
#u10
🏙️|die Stadt|Städte|city|şehir|A1|Die Stadt ist alt.
🏘️|das Dorf|Dörfer|village|köy|A1|Meine Oma wohnt in einem Dorf.
🛣️|die Straße|Straßen|street|sokak / cadde|A1|Die Straße ist lang.
⛲|der Platz|Plätze|square / place|meydan / yer|A1|Der Platz ist voll.
🌳|der Park|Parks|park|park|A1|Wir gehen in den Park.
⛪|die Kirche|Kirchen|church|kilise|A1|Die Kirche ist sehr alt.
🕌|die Moschee|Moscheen|mosque|cami|A1|Die Moschee ist neben dem Park.
🏛️|das Museum|Museen|museum|müze|A1|Das Museum ist im Zentrum.
🏦|die Bank|Banken|bank|banka|A1|Die Bank ist neben der Post.
🏤|die Post|-|post office|postane|A1|Ich gehe zur Post.
🏥|das Krankenhaus|Krankenhäuser|hospital|hastane|A1|Das Krankenhaus ist groß.
🏫|die Schule|Schulen|school|okul|A1|Die Schule beginnt um acht.
🎓|die Universität|Universitäten|university|üniversite|A1|Die Universität ist alt.
🏨|das Hotel|Hotels|hotel|otel|A1|Das Hotel ist am Bahnhof.
🚉|der Bahnhof|Bahnhöfe|train station|tren istasyonu|A1|Der Bahnhof ist weit.
🚏|die Haltestelle|Haltestellen|stop (bus/tram)|durak|A1|Die Haltestelle ist hier.
⬅️|links||left|sol / solda|A1|Gehen Sie links.
➡️|rechts||right|sağ / sağda|A1|Das Hotel ist rechts.
⬆️|geradeaus||straight ahead|dümdüz|A1|Gehen Sie geradeaus.
🚦|die Ampel|Ampeln|traffic light|trafik lambası|A1|Die Ampel ist rot.
🌉|die Brücke|Brücken|bridge|köprü|A1|Die Brücke ist alt.
🏛|das Rathaus|Rathäuser|town hall|belediye binası|A2|Das Rathaus ist am Marktplatz.
👮|die Polizei|-|police|polis|A1|Rufen Sie die Polizei!
🔭|weit||far|uzak|A1|Ist das weit?
📍|nah||near|yakın|A1|Der Park ist ganz nah.
🗺️|der Stadtplan|Stadtpläne|city map|şehir haritası|A1|Hast du einen Stadtplan?
#u11
🚆|der Zug|Züge|train|tren|A1|Der Zug hat Verspätung.
🚌|der Bus|Busse|bus|otobüs|A1|Der Bus kommt gleich.
🚇|die U-Bahn|U-Bahnen|underground / subway|metro|A1|Ich fahre mit der U-Bahn.
🚊|die Straßenbahn|Straßenbahnen|tram|tramvay|A1|Die Straßenbahn ist voll.
🚗|das Auto|Autos|car|araba|A1|Das Auto ist neu.
🚕|das Taxi|Taxis|taxi|taksi|A1|Wir nehmen ein Taxi.
✈️|das Flugzeug|Flugzeuge|airplane|uçak|A1|Das Flugzeug landet.
🚢|das Schiff|Schiffe|ship|gemi|A1|Das Schiff fährt nach Norwegen.
🎫|die Fahrkarte|Fahrkarten|ticket|bilet|A1|Ich brauche eine Fahrkarte.
🛤️|das Gleis|Gleise|platform / track|peron / ray|A2|Der Zug fährt von Gleis drei.
🛫|die Abfahrt|Abfahrten|departure|kalkış|A1|Die Abfahrt ist um zehn Uhr.
🛬|die Ankunft|Ankünfte|arrival|varış|A1|Die Ankunft ist um elf Uhr.
⏰|die Verspätung|Verspätungen|delay|gecikme / rötar|A2|Die Bahn hat wieder Verspätung.
🧳|der Koffer|Koffer|suitcase|bavul|A1|Der Koffer ist schwer.
🛂|der Pass|Pässe|passport|pasaport|A1|Hier ist mein Pass.
🏖️|der Urlaub|Urlaube|holiday / vacation|tatil|A1|Ich mache Urlaub.
🧭|die Reise|Reisen|trip / journey|yolculuk / seyahat|A1|Gute Reise!
🌍|reisen||to travel|seyahat etmek|A1|Ich reise gern.
🚘|fahren||to drive / go (by vehicle)|(araçla) gitmek / sürmek|A1|Wir fahren nach Hamburg.
🛩️|fliegen||to fly|uçmak|A1|Wir fliegen nach Istanbul.
🏁|ankommen||to arrive|varmak|A1|Der Zug kommt um elf an.
🔀|umsteigen||to change (trains)|aktarma yapmak|A2|Sie müssen in Hannover umsteigen.
🛫|der Flughafen|Flughäfen|airport|havalimanı|A2|Der Flughafen ist groß.
🏃|verpassen||to miss (a train)|kaçırmak|B1|Ich habe den Zug verpasst.
🚥|der Verkehr|-|traffic|trafik|A2|Am Morgen ist viel Verkehr.
🎟️|das Ticket|Tickets|ticket|bilet|A1|Das Ticket ist im Handy.
#u12
🗣️|der Kopf|Köpfe|head|baş / kafa|A1|Mein Kopf tut weh.
👁️|das Auge|Augen|eye|göz|A1|Sie hat blaue Augen.
👂|das Ohr|Ohren|ear|kulak|A1|Mein Ohr tut weh.
👃|die Nase|Nasen|nose|burun|A1|Die Nase ist rot.
👄|der Mund|Münder|mouth|ağız|A1|Mach bitte den Mund auf.
🦷|der Zahn|Zähne|tooth|diş|A1|Ich putze die Zähne.
💇|das Haar|Haare|hair|saç|A1|Er hat kurze Haare.
🧣|der Hals|Hälse|neck / throat|boyun / boğaz|A1|Mein Hals tut weh.
💪|der Arm|Arme|arm|kol|A1|Mein Arm ist gebrochen.
✋|die Hand|Hände|hand|el|A1|Wasch dir die Hände.
☝️|der Finger|Finger|finger|parmak|A1|Ich habe zehn Finger.
🫃|der Bauch|Bäuche|belly|karın|A1|Ich habe Bauchschmerzen.
🔙|der Rücken|Rücken|back|sırt|A1|Mein Rücken tut weh.
🦵|das Bein|Beine|leg|bacak|A1|Mein Bein ist müde.
🦶|der Fuß|Füße|foot|ayak|A1|Mein Fuß tut weh.
🫀|das Herz|Herzen|heart|kalp|A1|Das Herz schlägt schnell.
🩺|der Arzt|Ärzte|doctor (male)|doktor (erkek)|A1|Ich gehe zum Arzt.
👩‍⚕️|die Ärztin|Ärztinnen|doctor (female)|doktor (kadın)|A1|Die Ärztin ist nett.
💊|das Medikament|Medikamente|medicine|ilaç|A1|Nehmen Sie das Medikament.
💊|die Tablette|Tabletten|pill|hap|A1|Nehmen Sie eine Tablette.
🤒|krank||ill|hasta|A1|Ich bin krank.
💚|gesund||healthy|sağlıklı|A1|Obst ist gesund.
🤕|der Schmerz|Schmerzen|pain|ağrı|A1|Ich habe Kopfschmerzen.
🌡️|das Fieber|-|fever|ateş|A1|Ich habe Fieber.
📅|der Termin|Termine|appointment|randevu|A2|Ich habe einen Termin beim Arzt.
#u13
🌦️|das Wetter|-|weather|hava durumu|A1|Das Wetter ist schön.
☀️|die Sonne|Sonnen|sun|güneş|A1|Die Sonne scheint.
🌧️|der Regen|-|rain|yağmur|A1|Ich mag keinen Regen.
❄️|der Schnee|-|snow|kar|A1|Der Schnee ist weiß.
💨|der Wind|Winde|wind|rüzgâr|A1|Der Wind ist stark.
☁️|die Wolke|Wolken|cloud|bulut|A1|Heute gibt es viele Wolken.
⛈️|das Gewitter|Gewitter|thunderstorm|gök gürültülü fırtına|A2|Am Abend kommt ein Gewitter.
🌤️|warm||warm|ılık / sıcak|A1|Heute ist es warm.
🥶|kalt||cold|soğuk|A1|Im Winter ist es kalt.
🥵|heiß||hot|çok sıcak|A1|Im Sommer ist es heiß.
😍|schön||beautiful / nice|güzel|A1|Der Park ist schön.
👎|schlecht||bad|kötü|A1|Das Wetter ist schlecht.
🌸|der Frühling|Frühlinge|spring|ilkbahar|A1|Im Frühling blühen die Blumen.
🏝️|der Sommer|Sommer|summer|yaz|A1|Im Sommer fahren wir ans Meer.
🍂|der Herbst|Herbste|autumn|sonbahar|A1|Im Herbst ist es windig.
⛄|der Winter|Winter|winter|kış|A1|Im Winter schneit es.
❄|der Januar|Januare|January|ocak|A1|Im Januar ist es kalt.
💘|der Februar|Februare|February|şubat|A1|Der Februar ist kurz.
🌱|der März|Märze|March|mart|A1|Im März kommt der Frühling.
🐰|der April|Aprile|April|nisan|A1|Im April regnet es oft.
🌼|der Mai|Maie|May|mayıs|A1|Mein Geburtstag ist im Mai.
🍓|der Juni|Junis|June|haziran|A1|Im Juni ist es warm.
🏖|der Juli|Julis|July|temmuz|A1|Im Juli habe ich Urlaub.
🌻|der August|Auguste|August|ağustos|A1|Im August ist es heiß.
🍎|der September|September|September|eylül|A1|Im September beginnt die Schule.
🎃|der Oktober|Oktober|October|ekim|A1|Im Oktober ist das Oktoberfest.
🍁|der November|November|November|kasım|A1|Der November ist grau.
🎄|der Dezember|Dezember|December|aralık|A1|Im Dezember ist Weihnachten.
🌳|der Baum|Bäume|tree|ağaç|A1|Der Baum ist hoch.
🌼|die Blume|Blumen|flower|çiçek|A1|Die Blume ist gelb.
⛰️|der Berg|Berge|mountain|dağ|A1|Der Berg ist hoch.
🏞️|der See|Seen|lake|göl|A1|Wir schwimmen im See.
🌊|das Meer|Meere|sea|deniz|A1|Das Meer ist blau.
🐕|der Hund|Hunde|dog|köpek|A1|Der Hund bellt.
🐈|die Katze|Katzen|cat|kedi|A1|Die Katze schläft.
🐦|der Vogel|Vögel|bird|kuş|A1|Der Vogel singt.
🐎|das Pferd|Pferde|horse|at|A1|Das Pferd ist schnell.
🐄|die Kuh|Kühe|cow|inek|A1|Die Kuh gibt Milch.
🐖|das Schwein|Schweine|pig|domuz|A1|Das Schwein ist rosa.
🐑|das Schaf|Schafe|sheep|koyun|A1|Das Schaf ist weiß.
🐭|die Maus|Mäuse|mouse|fare|A1|Die Maus ist klein.
🐻|der Bär|Bären|bear|ayı|A1|Der Bär mag Honig.
🦊|der Fuchs|Füchse|fox|tilki|A1|Der Fuchs ist schlau.
🐇|der Hase|Hasen|hare / rabbit|tavşan|A1|Der Hase ist schnell.
🐝|die Biene|Bienen|bee|arı|A1|Die Biene macht Honig.
🦁|der Löwe|Löwen|lion|aslan|A1|Der Löwe ist stark.
🐘|der Elefant|Elefanten|elephant|fil|A1|Der Elefant ist groß.
#u14
💼|die Arbeit|Arbeiten|work / job|iş|A2|Die Arbeit macht Spaß.
👷|der Beruf|Berufe|profession|meslek|A1|Was ist dein Beruf?
👨‍🏫|der Lehrer|Lehrer|teacher (male)|öğretmen (erkek)|A1|Der Lehrer ist nett.
👩‍🏫|die Lehrerin|Lehrerinnen|teacher (female)|öğretmen (kadın)|A1|Ich bin Lehrerin.
👨‍🍳|der Koch|Köche|cook / chef|aşçı|A1|Der Koch kocht Suppe.
👮‍♂️|der Polizist|Polizisten|police officer|polis memuru|A1|Der Polizist hilft.
🧑‍💼|der Verkäufer|Verkäufer|salesperson|satıcı|A1|Der Verkäufer ist freundlich.
👷‍♀️|der Ingenieur|Ingenieure|engineer|mühendis|A1|Mein Bruder ist Ingenieur.
🧑‍💻|der Programmierer|Programmierer|programmer|programcı|A1|Sie ist Programmiererin.
🧑‍⚕️|der Krankenpfleger|Krankenpfleger|nurse (male)|hemşire (erkek)|A1|Er arbeitet als Krankenpfleger.
👩‍⚕️|die Krankenpflegerin|Krankenpflegerinnen|nurse (female)|hemşire (kadın)|A1|Sie ist Krankenpflegerin.
🧑‍🎓|der Student|Studenten|student (male)|üniversite öğrencisi (erkek)|A1|Ich bin Student.
👩‍🎓|die Studentin|Studentinnen|student (female)|üniversite öğrencisi (kadın)|A1|Sie ist Studentin.
🤵|der Kellner|Kellner|waiter|garson|A1|Der Kellner bringt die Speisekarte.
🚚|der Fahrer|Fahrer|driver|şoför|A1|Der Fahrer wartet.
💈|der Friseur|Friseure|hairdresser|kuaför / berber|A1|Ich gehe zum Friseur.
🏢|das Büro|Büros|office|ofis|A1|Ich arbeite in einem Büro.
🏭|die Firma|Firmen|company|şirket|A1|Die Firma ist in München.
🧑‍✈️|der Chef|Chefs|boss|patron / şef|A1|Mein Chef ist sehr nett.
🤝|der Kollege|Kollegen|colleague|iş arkadaşı|A1|Mein Kollege kommt aus Polen.
🖥️|der Computer|Computer|computer|bilgisayar|A1|Der Computer ist langsam.
📱|das Handy|Handys|mobile phone|cep telefonu|A1|Mein Handy ist kaputt.
📧|die E-Mail|E-Mails|email|e-posta|A1|Ich schreibe eine E-Mail.
💵|verdienen||to earn|kazanmak (para)|A2|Er verdient gut.
💶|das Gehalt|Gehälter|salary|maaş|A2|Das Gehalt kommt am Monatsende.
🗣|die Besprechung|Besprechungen|meeting|toplantı|A2|Die Besprechung beginnt um neun.
🏖|frei||free / off|boş / serbest / izinli|A1|Morgen habe ich frei.
#u15
📖|erzählen||to tell (a story)|anlatmak|A2|Erzähl mal!
👋|besuchen||to visit|ziyaret etmek|A2|Ich habe meine Oma besucht.
😟|verlieren||to lose|kaybetmek|A2|Ich habe meinen Schlüssel verloren.
🔍|finden||to find / to think|bulmak / bulmak (fikir)|A2|Ich finde das gut.
🤯|vergessen||to forget|unutmak|A2|Ich habe den Termin vergessen.
📬|bekommen||to receive / get|almak (elde etmek)|A2|Ich habe ein Paket bekommen.
✍️|schreiben||to write|yazmak|A1|Ich schreibe einen Brief.
👀|sehen||to see|görmek|A1|Ich sehe den Bus.
🎧|hören||to hear / listen|duymak / dinlemek|A1|Ich höre Musik.
🎈|die Party|Partys|party|parti|A1|Die Party war toll.
🎂|der Geburtstag|Geburtstage|birthday|doğum günü|A1|Wann hast du Geburtstag?
🎁|das Geschenk|Geschenke|present / gift|hediye|A1|Danke für das Geschenk!
❗|passieren||to happen|olmak (meydana gelmek)|A2|Was ist passiert?
🧠|sich erinnern||to remember|hatırlamak|B1|Ich erinnere mich an den Urlaub.
📸|das Foto|Fotos|photo|fotoğraf|A1|Das Foto ist schön.
🔚|letzte||last|geçen / son|A2|Letzte Woche war ich in Wien.
1️⃣|zuerst||first (of all)|önce / ilk olarak|A2|Zuerst frühstücke ich.
➡|dann||then|sonra|A1|Dann gehe ich zur Arbeit.
⏭️|danach||afterwards|ondan sonra|A2|Danach treffe ich Freunde.
📘|die Geschichte|Geschichten|story / history|hikâye / tarih|A2|Erzähl mir eine Geschichte.
#u16
🎊|das Fest|Feste|festival / celebration|bayram / şenlik|A2|Das Fest beginnt um sechs.
🥳|feiern||to celebrate|kutlamak|A2|Wir feiern Silvester.
🎄|Weihnachten|-|Christmas|Noel|A2|Frohe Weihnachten!
🐣|Ostern|-|Easter|Paskalya|A2|An Ostern suchen Kinder Eier.
🎆|Silvester|-|New Year's Eve|yılbaşı gecesi|A2|An Silvester gibt es Feuerwerk.
🎭|der Karneval|-|carnival|karnaval|A2|In Köln feiert man Karneval.
🍺|das Oktoberfest|-|Oktoberfest|Oktoberfest (Münih bira festivali)|A2|Das Oktoberfest ist in München.
🕯️|die Kerze|Kerzen|candle|mum|A2|Die Kerze brennt.
🎄|der Weihnachtsbaum|Weihnachtsbäume|Christmas tree|Noel ağacı|A2|Der Weihnachtsbaum ist schön.
🎪|der Weihnachtsmarkt|Weihnachtsmärkte|Christmas market|Noel pazarı|A2|Wir trinken Glühwein auf dem Weihnachtsmarkt.
🎇|das Feuerwerk|Feuerwerke|fireworks|havai fişek|A2|Das Feuerwerk ist bunt.
👏|gratulieren||to congratulate|tebrik etmek|A2|Ich gratuliere dir!
💌|einladen||to invite|davet etmek|A2|Ich lade dich zu meiner Party ein.
✉️|die Einladung|Einladungen|invitation|davet|A2|Danke für die Einladung!
🧑‍🤝‍🧑|der Gast|Gäste|guest|misafir|A2|Die Gäste kommen um sieben.
🎂|die Torte|Torten|gateau / layer cake|pasta (yaş pasta)|A2|Die Torte ist süß.
🥂|Herzlichen Glückwunsch||congratulations / happy birthday|tebrikler / iyi ki doğdun|A2|Herzlichen Glückwunsch zum Geburtstag!
📆|der Adventskalender|Adventskalender|Advent calendar|Advent takvimi|A2|Der Adventskalender hat 24 Türen.
🌙|das Zuckerfest|-|Eid al-Fitr|Ramazan Bayramı (Şeker Bayramı)|A2|Wir feiern das Zuckerfest mit der Familie.
🎅|der Nikolaus|-|St Nicholas|Aziz Nikolaus|A2|Am 6. Dezember kommt der Nikolaus.
💐|schenken||to give (as a gift)|hediye etmek|A2|Ich schenke ihr Blumen.
#u17
🧑‍💼|der Vermieter|Vermieter|landlord|ev sahibi|A2|Der Vermieter repariert die Heizung.
🙋|der Mieter|Mieter|tenant|kiracı|A2|Die Mieter sind freundlich.
🧾|die Nebenkosten|-|utilities / extra costs|ek giderler (aidat, ısınma vb.)|A2|Die Nebenkosten sind hoch.
🔐|die Kaution|Kautionen|deposit (rent)|depozito (kira)|A2|Die Kaution ist drei Monatsmieten.
🗑️|der Müll|-|rubbish / trash|çöp|A2|Ich bringe den Müll raus.
♻️|die Mülltrennung|-|waste separation|çöp ayrıştırma|A2|Mülltrennung ist in Deutschland wichtig.
🍾|das Pfand|-|bottle deposit|depozito (şişe iadesi)|A2|Die Flasche hat 25 Cent Pfand.
🤫|die Ruhezeit|Ruhezeiten|quiet hours|sessizlik saatleri|B1|Sonntags ist Ruhezeit.
🏡|der Nachbar|Nachbarn|neighbour|komşu|A2|Mein Nachbar ist nett.
📋|die Hausordnung|Hausordnungen|house rules|bina kuralları|A2|Lies die Hausordnung!
📦|umziehen||to move house|taşınmak|A2|Wir ziehen nächsten Monat um.
🚚|der Umzug|Umzüge|move (house)|taşınma|A2|Der Umzug war anstrengend.
♨️|die Heizung|Heizungen|heating|kalorifer / ısıtma|A2|Die Heizung ist kaputt.
⚡|der Strom|-|electricity|elektrik|A2|Der Strom ist teuer.
📄|der Mietvertrag|Mietverträge|tenancy agreement|kira sözleşmesi|A2|Ich unterschreibe den Mietvertrag.
🟫|die Biotonne|Biotonnen|organic waste bin|organik çöp kutusu|A2|Die Bananenschale kommt in die Biotonne.
📰|das Altpapier|-|waste paper|atık kâğıt|A2|Zeitungen kommen ins Altpapier.
🍶|die Flasche|Flaschen|bottle|şişe|A1|Die Flasche ist leer.
🧽|putzen||to clean|temizlemek|A2|Am Samstag putze ich die Wohnung.
🔔|klingeln||to ring (doorbell)|zil çalmak|A2|Es klingelt an der Tür.
🗑|die Tonne|Tonnen|bin|çöp kutusu (büyük)|A2|Das Papier kommt in die blaue Tonne.
#u18
🏛️|das Amt|Ämter|(public) office|resmî daire|A2|Ich muss zum Amt.
🏢|das Bürgeramt|Bürgerämter|citizens' office|vatandaşlık dairesi (Bürgeramt)|A2|Die Anmeldung macht man im Bürgeramt.
📝|die Anmeldung|Anmeldungen|registration|kayıt / ikamet bildirimi|A2|Ich brauche einen Termin für die Anmeldung.
📄|das Formular|Formulare|form|form|A2|Bitte füllen Sie das Formular aus.
🪪|der Ausweis|Ausweise|ID card|kimlik kartı|A2|Zeigen Sie bitte Ihren Ausweis.
✍|die Unterschrift|Unterschriften|signature|imza|A2|Hier fehlt Ihre Unterschrift.
🖊️|unterschreiben||to sign|imzalamak|A2|Unterschreiben Sie bitte hier.
🗒️|ausfüllen||to fill in|doldurmak|A2|Ich fülle das Formular aus.
📑|der Antrag|Anträge|application|başvuru|A2|Der Antrag dauert vier Wochen.
🏛|die Behörde|Behörden|authority|resmî kurum|B1|Die Behörde schickt einen Brief.
🩺|die Krankenversicherung|Krankenversicherungen|health insurance|sağlık sigortası|A2|In Deutschland braucht man eine Krankenversicherung.
🏦|das Konto|Konten|bank account|banka hesabı|A2|Ich eröffne ein Konto.
💸|überweisen||to transfer (money)|havale etmek|A2|Ich überweise die Miete.
✉️|der Brief|Briefe|letter|mektup|A1|Ich schreibe einen Brief.
📦|das Paket|Pakete|parcel|paket|A1|Das Paket ist da.
📮|die Briefmarke|Briefmarken|stamp|pul|A1|Eine Briefmarke, bitte.
⏳|warten||to wait|beklemek|A1|Ich warte auf den Bus.
🎫|die Wartenummer|Wartenummern|queue number|sıra numarası|A2|Ich habe die Wartenummer 42.
📋|die Bürokratie|-|bureaucracy|bürokrasi|B1|Die Bürokratie braucht Geduld.
🏠|die Adresse|Adressen|address|adres|A1|Wie ist Ihre Adresse?
🎂|das Geburtsdatum|Geburtsdaten|date of birth|doğum tarihi|A1|Wie ist Ihr Geburtsdatum?
🧑‍💼|brauchen||to need|ihtiyaç duymak|A1|Ich brauche Hilfe.
#u19
🤧|die Erkältung|Erkältungen|cold|soğuk algınlığı|A2|Ich habe eine Erkältung.
😮‍💨|der Husten|-|cough|öksürük|A2|Ich habe Husten.
🤧|der Schnupfen|-|runny nose|nezle|A2|Ich habe Schnupfen.
🤒|die Grippe|-|flu|grip|A2|Er hat die Grippe.
📃|das Rezept|Rezepte|prescription / recipe|reçete / tarif|A2|Der Arzt gibt mir ein Rezept.
😕|sich fühlen||to feel|hissetmek|A2|Ich fühle mich nicht gut.
🤕|wehtun||to hurt|acımak / ağrımak|A2|Mein Hals tut weh.
🛌|sich ausruhen||to rest|dinlenmek|A2|Du musst dich ausruhen.
🏥|die Praxis|Praxen|(doctor's) practice|muayenehane|A2|Die Praxis öffnet um acht.
🚨|die Notaufnahme|Notaufnahmen|emergency room|acil servis|A2|Wir fahren in die Notaufnahme.
☎|der Notruf|Notrufe|emergency call|acil çağrı|A2|Der Notruf ist 112.
🚑|der Krankenwagen|Krankenwagen|ambulance|ambulans|A2|Der Krankenwagen kommt schnell.
💳|die Versichertenkarte|Versichertenkarten|health insurance card|sağlık sigortası kartı|A2|Bitte zeigen Sie Ihre Versichertenkarte.
🌾|die Allergie|Allergien|allergy|alerji|A2|Ich habe eine Allergie.
🩹|das Pflaster|Pflaster|plaster / band-aid|yara bandı|A2|Ich brauche ein Pflaster.
💐|Gute Besserung||get well soon|geçmiş olsun|A2|Gute Besserung!
🩸|das Blut|-|blood|kan|A2|Der Arzt nimmt Blut ab.
💉|die Impfung|Impfungen|vaccination|aşı|A2|Die Impfung ist wichtig.
🦠|die Krankheit|Krankheiten|illness|hastalık|A2|Die Krankheit ist nicht gefährlich.
☎️|anrufen||to call (phone)|telefonla aramak|A2|Ich rufe die Praxis an.
#u20
🌐|das Internet|-|internet|internet|A1|Ich surfe im Internet.
📩|die Nachricht|Nachrichten|message / news|mesaj / haber|A2|Ich schicke dir eine Nachricht.
🗞️|die Zeitung|Zeitungen|newspaper|gazete|A1|Mein Opa liest Zeitung.
📻|das Radio|Radios|radio|radyo|A1|Das Radio ist laut.
📲|die App|Apps|app|uygulama|A2|Die App ist kostenlos.
🔒|das Passwort|Passwörter|password|şifre|A2|Das Passwort ist geheim.
⬇️|herunterladen||to download|indirmek|A2|Ich lade die App herunter.
🎞️|das Video|Videos|video|video|A1|Das Video ist lustig.
🖥|der Bildschirm|Bildschirme|screen|ekran|A2|Der Bildschirm ist groß.
⌨️|die Tastatur|Tastaturen|keyboard|klavye|A2|Die Tastatur hat kein „ß“.
💻|der Laptop|Laptops|laptop|dizüstü bilgisayar|A2|Mein Laptop ist neu.
🟢|online||online|çevrimiçi|A2|Bist du online?
📤|posten||to post (online)|paylaşmak (gönderi)|A2|Sie postet jeden Tag Fotos.
🔗|teilen||to share|paylaşmak|A2|Teilst du den Link?
📢|die Werbung|-|advertising|reklam|A2|Zu viel Werbung!
📺|die Sendung|Sendungen|broadcast / programme|yayın / program|A2|Die Sendung beginnt um acht.
🔍|suchen||to search / look for|aramak|A1|Ich suche meine Brille.
📶|das WLAN|-|Wi-Fi|kablosuz internet (Wi-Fi)|A2|Gibt es hier WLAN?
📈|besser||better|daha iyi|A2|Diese App ist besser.
🏆|am besten||best|en iyi|A2|Das gefällt mir am besten.
🐇|schnell||fast|hızlı|A1|Das Internet ist schnell.
🐢|langsam||slow|yavaş|A1|Der Computer ist langsam.
#u21
🛏|die Unterkunft|Unterkünfte|accommodation|konaklama yeri|A2|Die Unterkunft ist günstig.
🎒|die Jugendherberge|Jugendherbergen|youth hostel|gençlik hosteli|A2|Wir schlafen in der Jugendherberge.
📅|buchen||to book|rezervasyon yapmak|A2|Ich buche ein Zimmer.
📝|die Reservierung|Reservierungen|reservation|rezervasyon|A2|Ich habe eine Reservierung.
🏖️|der Strand|Strände|beach|plaj|A2|Der Strand ist voll.
🏰|die Sehenswürdigkeit|Sehenswürdigkeiten|sight / attraction|görülecek yer|A2|Berlin hat viele Sehenswürdigkeiten.
🚌|der Ausflug|Ausflüge|trip / outing|gezi|A2|Wir machen einen Ausflug.
🗺|die Landkarte|Landkarten|map|harita|A2|Die Landkarte ist alt.
🎒|der Rucksack|Rucksäcke|backpack|sırt çantası|A2|Mein Rucksack ist schwer.
⛺|das Zelt|Zelte|tent|çadır|A2|Wir schlafen im Zelt.
🛃|die Grenze|Grenzen|border|sınır|A2|Wir sind an der Grenze.
🔭|besichtigen||to visit (a sight)|gezmek (görmek)|A2|Wir besichtigen das Schloss.
💌|die Postkarte|Postkarten|postcard|kartpostal|A2|Ich schreibe eine Postkarte.
🗿|das Souvenir|Souvenirs|souvenir|hatıra eşya|A2|Ich kaufe ein Souvenir.
📗|der Reiseführer|Reiseführer|travel guide|gezi rehberi|A2|Der Reiseführer erklärt alles.
✈️|das Fernweh|-|wanderlust|uzak yerlere özlem|B1|Ich habe Fernweh.
🌤️|die Vorfreude|-|anticipation|beklenti sevinci|B1|Ich habe Vorfreude auf den Urlaub.
🏔️|die Alpen|-|the Alps|Alpler|A2|Wir wandern in den Alpen.
🏯|das Schloss|Schlösser|castle / palace|şato / saray|A2|Das Schloss Neuschwanstein ist berühmt.
🌙|übernachten||to stay overnight|geceyi geçirmek / konaklamak|A2|Wir übernachten im Hotel.
⏰|die Zeit|Zeiten|time|zaman|A1|Ich habe keine Zeit.
#u22
🌭|die Bratwurst|Bratwürste|fried sausage|ızgara sosis (Bratwurst)|A2|Eine Bratwurst mit Senf, bitte.
🥩|das Schnitzel|Schnitzel|schnitzel|şinitzel|A2|Ich nehme das Schnitzel.
🥬|das Sauerkraut|-|sauerkraut|lahana turşusu|A2|Sauerkraut ist sauer.
🥙|der Döner|Döner|doner kebab|döner|A2|Der Döner ist in Deutschland sehr beliebt.
🍛|die Currywurst|Currywürste|currywurst|köri soslu sosis|A2|Die Currywurst kommt aus Berlin.
🍜|die Spätzle|-|spaetzle (egg noodles)|Spätzle (Alman eriştesi)|A2|Spätzle sind typisch für Schwaben.
🥟|der Knödel|Knödel|dumpling|Knödel (hamur köftesi)|A2|In Bayern isst man Knödel.
🍞|das Vollkornbrot|Vollkornbrote|wholemeal bread|tam buğday ekmeği|A2|Vollkornbrot ist gesund.
🌱|der Spargel|-|asparagus|kuşkonmaz|A2|Im Mai essen viele Deutsche Spargel.
🪙|das Trinkgeld|Trinkgelder|tip|bahşiş|A2|Das Trinkgeld ist für den Kellner.
🗒|bestellen||to order|sipariş vermek|A2|Was möchten Sie bestellen?
🥗|die Vorspeise|Vorspeisen|starter|başlangıç / meze|A2|Als Vorspeise nehme ich eine Suppe.
🍖|die Hauptspeise|Hauptspeisen|main course|ana yemek|A2|Die Hauptspeise ist Fisch.
🍮|der Nachtisch|Nachtische|dessert|tatlı|A2|Als Nachtisch gibt es Eis.
🌶️|scharf||spicy / sharp|acı / keskin|A2|Das Essen ist zu scharf.
🍯|süß||sweet|tatlı|A2|Der Kuchen ist sehr süß.
🍋|sauer||sour|ekşi|A2|Die Zitrone ist sauer.
🧂|salzig||salty|tuzlu|A2|Die Suppe ist zu salzig.
🥕|vegetarisch||vegetarian|vejetaryen|A2|Ich esse vegetarisch.
🌿|vegan||vegan|vegan|A2|Das Restaurant hat auch vegane Gerichte.
👅|schmecken||to taste|tadı olmak / lezzetli gelmek|A2|Das Essen hat gut geschmeckt.
🥧|der Apfelstrudel|Apfelstrudel|apple strudel|elmalı strudel|A2|Der Apfelstrudel ist warm.
#u23
💭|das Gefühl|Gefühle|feeling|duygu|A2|Ich habe ein gutes Gefühl.
😊|glücklich||happy|mutlu|A2|Ich bin glücklich.
😢|traurig||sad|üzgün|A2|Warum bist du traurig?
😠|wütend||angry|kızgın|A2|Er ist wütend.
😬|nervös||nervous|gergin|A2|Vor der Prüfung bin ich nervös.
😲|überrascht||surprised|şaşırmış|A2|Ich bin überrascht!
😨|die Angst|Ängste|fear|korku|A2|Ich habe Angst vor Hunden.
❤️‍🔥|die Liebe|-|love|aşk / sevgi|A2|Liebe ist schön.
💞|lieben||to love|sevmek|A2|Ich liebe dich.
🤗|die Freundschaft|Freundschaften|friendship|arkadaşlık|A2|Unsere Freundschaft ist wichtig.
😃|sich freuen||to be glad|sevinmek|B1|Ich freue mich auf das Wochenende.
😤|sich ärgern||to be annoyed|sinirlenmek|A2|Ich ärgere mich über den Zug.
🥺|vermissen||to miss (someone)|özlemek|A2|Ich vermisse meine Familie.
🦚|stolz||proud|gururlu|A2|Ich bin stolz auf dich.
😒|eifersüchtig||jealous|kıskanç|B1|Er ist eifersüchtig.
😔|einsam||lonely|yalnız|A2|Am Anfang war ich einsam.
😍|verliebt||in love|âşık|A2|Sie ist verliebt.
💢|der Streit|Streite|argument / fight|kavga / tartışma|A2|Wir hatten einen Streit.
🙇|sich entschuldigen||to apologise|özür dilemek|A2|Ich entschuldige mich.
😈|die Schadenfreude|-|joy at others' misfortune|başkasının talihsizliğine sevinme|B1|Das ist pure Schadenfreude.
😞|der Kummer|-|grief / worry|dert / keder|B1|Er hat viel Kummer.
🙂|zufrieden||satisfied|memnun|A2|Ich bin zufrieden.
#u24
📨|die Bewerbung|Bewerbungen|application (job)|iş başvurusu|B1|Ich schreibe eine Bewerbung.
✋|sich bewerben||to apply|başvurmak|B1|Ich bewerbe mich bei einer Firma.
📄|der Lebenslauf|Lebensläufe|CV / résumé|özgeçmiş|B1|Mein Lebenslauf ist aktuell.
🤝|das Vorstellungsgespräch|Vorstellungsgespräche|job interview|iş görüşmesi|B1|Morgen habe ich ein Vorstellungsgespräch.
🪑|die Stelle|Stellen|position / job|pozisyon / iş|B1|Die Stelle ist noch frei.
🧠|die Erfahrung|Erfahrungen|experience|deneyim|B1|Ich habe viel Erfahrung.
🛠️|die Ausbildung|Ausbildungen|vocational training|meslek eğitimi|B1|Sie macht eine Ausbildung als Köchin.
🧪|das Praktikum|Praktika|internship|staj|B1|Ich mache ein Praktikum.
🏢|der Arbeitgeber|Arbeitgeber|employer|işveren|B1|Mein Arbeitgeber ist fair.
👷|der Arbeitnehmer|Arbeitnehmer|employee|çalışan|B1|Arbeitnehmer haben Rechte.
📤|die Kündigung|Kündigungen|notice / dismissal|fesih / istifa bildirimi|B1|Ich habe die Kündigung bekommen.
🚪|kündigen||to quit / give notice|istifa etmek / feshetmek|B1|Er hat gekündigt.
⏰|die Überstunde|Überstunden|overtime hour|fazla mesai|B1|Ich mache keine Überstunden.
🕓|die Teilzeit|-|part-time|yarı zamanlı|B1|Sie arbeitet in Teilzeit.
🕘|die Vollzeit|-|full-time|tam zamanlı|B1|Ich arbeite Vollzeit.
👥|das Team|Teams|team|ekip|A2|Unser Team ist international.
⚖️|die Verantwortung|Verantwortungen|responsibility|sorumluluk|B1|Ich übernehme Verantwortung.
🧩|die Fähigkeit|Fähigkeiten|skill / ability|yetenek|B1|Welche Fähigkeiten haben Sie?
🧑‍💻|selbstständig||self-employed / independent|serbest çalışan / bağımsız|B1|Ich arbeite selbstständig.
🔒|zuverlässig||reliable|güvenilir|B1|Sie ist sehr zuverlässig.
#u25
🌍|die Umwelt|-|environment|çevre|B1|Wir müssen die Umwelt schützen.
🌡|das Klima|-|climate|iklim|B1|Das Klima ändert sich.
🔥|der Klimawandel|-|climate change|iklim değişikliği|B1|Der Klimawandel ist ein Problem.
⚡|die Energie|Energien|energy|enerji|B1|Wir sparen Energie.
☀️|die Solarenergie|-|solar energy|güneş enerjisi|B1|Solarenergie ist sauber.
🧴|der Plastikmüll|-|plastic waste|plastik atık|B1|Im Meer ist viel Plastikmüll.
♻|recyceln||to recycle|geri dönüştürmek|B1|Wir recyceln Glas.
🐷|sparen||to save|tasarruf etmek / biriktirmek|B1|Ich spare Wasser.
📉|der Verbrauch|-|consumption|tüketim|B1|Der Verbrauch ist zu hoch.
🌱|nachhaltig||sustainable|sürdürülebilir|B1|Nachhaltig leben ist wichtig.
🌬️|die Luft|-|air|hava (soluduğumuz)|B1|Die Luft ist sauber.
🌲|der Wald|Wälder|forest|orman|A2|Wir gehen im Wald spazieren.
🍃|die Natur|-|nature|doğa|A2|Ich liebe die Natur.
🛡️|schützen||to protect|korumak|B1|Wir schützen die Tiere.
🌿|der Umweltschutz|-|environmental protection|çevre koruma|B1|Umweltschutz geht alle an.
🏭|die Verschmutzung|Verschmutzungen|pollution|kirlilik|B1|Die Verschmutzung ist gefährlich.
🔌|das Elektroauto|Elektroautos|electric car|elektrikli araba|B1|Das Elektroauto ist leise.
🔄|erneuerbar||renewable|yenilenebilir|B1|Wind ist eine erneuerbare Energie.
🚲|umweltfreundlich||eco-friendly|çevre dostu|B1|Das Fahrrad ist umweltfreundlich.
➰|die Folge|Folgen|consequence|sonuç|B1|Das hat Folgen für alle.
#u26
🧱|die Mauer|Mauern|wall|duvar|B1|Die Mauer fiel 1989.
🤝|die Wiedervereinigung|-|reunification|yeniden birleşme|B1|Die Wiedervereinigung war 1990.
✂️|die Teilung|Teilungen|division|bölünme|B1|Die Teilung dauerte über 40 Jahre.
⚔️|der Krieg|Kriege|war|savaş|B1|Der Krieg war schrecklich.
🕊️|der Frieden|-|peace|barış|B1|Wir wollen Frieden.
🗳️|die Demokratie|Demokratien|democracy|demokrasi|B1|Deutschland ist eine Demokratie.
🏛️|die Regierung|Regierungen|government|hükümet|B1|Die Regierung plant neue Gesetze.
🗳|die Wahl|Wahlen|election / choice|seçim|B1|Die Wahl ist im September.
✅|wählen||to vote / choose|oy vermek / seçmek|B1|Ich darf wählen.
🏛|das Parlament|Parlamente|parliament|parlamento|B1|Das Parlament diskutiert.
🇩🇪|der Bundestag|-|German federal parliament|Federal Meclis (Bundestag)|B1|Der Bundestag ist in Berlin.
🗾|das Bundesland|Bundesländer|federal state|eyalet|B1|Bayern ist ein Bundesland.
🏙|die Hauptstadt|Hauptstädte|capital city|başkent|A2|Berlin ist die Hauptstadt.
🗽|die Freiheit|Freiheiten|freedom|özgürlük|B1|Freiheit ist wichtig.
👥|die Gesellschaft|Gesellschaften|society / company|toplum / şirket|B1|Die Gesellschaft verändert sich.
🧳|die Einwanderung|Einwanderungen|immigration|göç (ülkeye)|B1|Einwanderung prägt Deutschland.
🌈|die Vielfalt|-|diversity|çeşitlilik|B1|Vielfalt macht uns stark.
🗿|das Denkmal|Denkmäler|monument|anıt|B1|Das Denkmal steht im Zentrum.
📜|das Gesetz|Gesetze|law|yasa|B1|Das Gesetz gilt für alle.
👷‍♂️|der Gastarbeiter|Gastarbeiter|guest worker|misafir işçi (Gastarbeiter)|B1|Mein Großvater kam als Gastarbeiter.
#u27
🏫|die Grundschule|Grundschulen|primary school|ilkokul|B1|Die Grundschule dauert meist vier Jahre.
🎒|das Gymnasium|Gymnasien|academic secondary school|lise (Gymnasium)|B1|Sie geht aufs Gymnasium.
🎓|das Abitur|-|school-leaving exam (A-levels)|lise bitirme sınavı (Abitur)|B1|Nach dem Abitur studiere ich.
📝|die Prüfung|Prüfungen|exam|sınav|A2|Die Prüfung war schwer.
💯|die Note|Noten|grade|not|A2|Ich habe eine gute Note.
📃|das Zeugnis|Zeugnisse|report card / certificate|karne / belge|B1|Mein Zeugnis ist gut.
📚|das Fach|Fächer|subject|ders (branş)|A2|Mein Lieblingsfach ist Mathe.
🎓|das Studium|Studien|university studies|üniversite eğitimi|B1|Das Studium dauert drei Jahre.
🧑‍🎓|studieren||to study (at university)|üniversitede okumak|A2|Ich studiere Informatik.
🧑‍🏫|die Vorlesung|Vorlesungen|lecture|ders (üniversite)|B1|Die Vorlesung beginnt um zehn.
💶|das Stipendium|Stipendien|scholarship|burs|B1|Sie hat ein Stipendium bekommen.
📚|die Bibliothek|Bibliotheken|library|kütüphane|A2|Ich lerne in der Bibliothek.
🧾|der Kurs|Kurse|course|kurs|A1|Der Kurs beginnt am Montag.
✏️|die Hausaufgabe|Hausaufgaben|homework|ev ödevi|A2|Ich mache meine Hausaufgaben.
🏅|bestehen||to pass (an exam)|geçmek (sınavı)|B1|Ich habe die Prüfung bestanden.
📉|durchfallen||to fail (an exam)|kalmak (sınavda)|B1|Er ist durchgefallen.
🎖️|der Abschluss|Abschlüsse|degree / qualification|mezuniyet / diploma|B1|Ich habe einen Abschluss in Chemie.
🏭|die Berufsschule|Berufsschulen|vocational school|meslek okulu|B1|Azubis gehen in die Berufsschule.
🧠|das Wissen|-|knowledge|bilgi|B1|Wissen ist Macht.
🙋|die Frage|Fragen|question|soru|A1|Ich habe eine Frage.
#u28
💬|die Meinung|Meinungen|opinion|fikir / görüş|B1|Was ist deine Meinung?
🤔|meinen||to think / to mean|düşünmek / kastetmek|B1|Was meinst du?
🙏|glauben||to believe|inanmak / sanmak|A2|Ich glaube, das stimmt.
👍|zustimmen||to agree|katılmak (fikre)|B1|Ich stimme dir zu.
👎|widersprechen||to contradict / disagree|itiraz etmek|B1|Da muss ich widersprechen.
🧩|das Argument|Argumente|argument|argüman|B1|Das ist ein gutes Argument.
➕|der Vorteil|Vorteile|advantage|avantaj|B1|Das hat viele Vorteile.
➖|der Nachteil|Nachteile|disadvantage|dezavantaj|B1|Ein Nachteil ist der Preis.
◀️|einerseits||on the one hand|bir yandan|B1|Einerseits ist es teuer, …
▶️|andererseits||on the other hand|öte yandan|B1|… andererseits ist es gut.
🔀|obwohl||although|-e rağmen / -dığı halde|B1|Obwohl es regnet, gehe ich spazieren.
➡️|deshalb||therefore|bu yüzden|A2|Ich bin krank, deshalb bleibe ich zu Hause.
💪|trotzdem||nevertheless|yine de|B1|Es regnet, trotzdem gehe ich raus.
🗣️|die Diskussion|Diskussionen|discussion|tartışma|B1|Die Diskussion war lang.
🎯|überzeugen||to convince|ikna etmek|B1|Du hast mich überzeugt.
📣|behaupten||to claim|iddia etmek|B1|Er behauptet, dass er recht hat.
❔|der Grund|Gründe|reason|sebep|B1|Was ist der Grund?
💡|die Lösung|Lösungen|solution|çözüm|B1|Wir brauchen eine Lösung.
⚠️|das Problem|Probleme|problem|sorun|A2|Kein Problem!
✔️|richtig||right / correct|doğru|A1|Das ist richtig.
✖️|falsch||wrong|yanlış|A1|Das ist falsch.
🔁|weil||because|çünkü|A2|Ich lerne Deutsch, weil ich in Berlin wohne.
🔗|dass||that (conjunction)|-dığını / ki|A2|Ich glaube, dass es regnet.
🌦|wenn||if / when|eğer / -dığında|A2|Wenn es regnet, bleibe ich zu Hause.
#u29
🎭|die Kultur|Kulturen|culture|kültür|B1|Die Kultur ist vielfältig.
🖼️|die Kunst|Künste|art|sanat|B1|Ich interessiere mich für Kunst.
🎭|das Theater|Theater|theatre|tiyatro|A2|Wir gehen ins Theater.
🖼|die Ausstellung|Ausstellungen|exhibition|sergi|B1|Die Ausstellung ist im Museum.
📕|der Roman|Romane|novel|roman|B1|Der Roman ist spannend.
✒️|der Dichter|Dichter|poet|şair|B1|Goethe ist ein bekannter Dichter.
📜|das Gedicht|Gedichte|poem|şiir|B1|Ich lerne ein Gedicht.
🎼|der Komponist|Komponisten|composer|besteci|B1|Beethoven war ein Komponist.
🎻|das Orchester|Orchester|orchestra|orkestra|B1|Das Orchester spielt Mozart.
🎶|die Oper|Opern|opera|opera|B1|Die Oper beginnt um acht.
🎬|der Schauspieler|Schauspieler|actor|oyuncu|B1|Der Schauspieler ist berühmt.
📺|die Serie|Serien|series|dizi|A2|Ich schaue eine deutsche Serie.
🧑‍🎨|der Künstler|Künstler|artist|sanatçı|B1|Der Künstler malt.
⭐|berühmt||famous|ünlü|A2|Das Schloss ist berühmt.
📚|die Literatur|Literaturen|literature|edebiyat|B1|Ich mag deutsche Literatur.
🧚|das Märchen|Märchen|fairy tale|masal|B1|Die Brüder Grimm haben Märchen gesammelt.
🎪|die Bühne|Bühnen|stage|sahne|B1|Die Schauspieler stehen auf der Bühne.
👏|das Publikum|-|audience|seyirci|B1|Das Publikum klatscht.
🎥|der Regisseur|Regisseure|director (film)|yönetmen|B1|Der Regisseur ist bekannt.
🏛️|die Galerie|Galerien|gallery|galeri|B1|Die Galerie zeigt moderne Kunst.
''';

class BankEntry {
  const BankEntry(this.unit, this.word);
  final String unit;
  final Word word;
}

List<BankEntry> parseBank([String raw = _bank]) {
  final out = <BankEntry>[];
  var unit = '';
  for (final line in raw.split('\n')) {
    final l = line.trim();
    if (l.isEmpty) continue;
    if (l.startsWith('#')) {
      unit = l.substring(1);
      continue;
    }
    final p = l.split('|');
    if (p.length < 6) continue;
    final de = p[1].trim();
    out.add(BankEntry(
      unit,
      Word(
        id: Word.idFor(de),
        emoji: p[0].trim(),
        de: de,
        plural: p[2].trim(),
        en: p[3].trim(),
        tr: p[4].trim(),
        level: p[5].trim(),
        example: p.length > 6 ? p[6].trim() : '',
        topic: unit,
      ),
    ));
  }
  return out;
}

/// Every bank entry (duplicates across units are a data error and caught by tests).
final List<BankEntry> bankEntries = parseBank();

/// Unique words by id; the first occurrence wins.
final Map<String, Word> bankWords = () {
  final m = <String, Word>{};
  for (final e in bankEntries) {
    m.putIfAbsent(e.word.id, () => e.word);
  }
  return m;
}();

/// Word ids per unit, in lesson order.
final Map<String, List<String>> unitWordIds = () {
  final m = <String, List<String>>{};
  for (final e in bankEntries) {
    (m[e.unit] ??= []).add(e.word.id);
  }
  return m;
}();
