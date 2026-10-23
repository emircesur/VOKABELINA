/// One grammar card per unit and target language. Explanations are written in
/// the learner's likely native languages: German target → EN/TR, English
/// target → TR/DE, Turkish target → EN/DE. The AI can explain further in any language.
class GrammarPoint {
  const GrammarPoint({required this.target, required this.unitId, required this.title, required this.body, required this.examples});
  final String target;
  final String unitId;
  final Map<String, String> title;
  final Map<String, String> body;

  /// Sentences in the target language.
  final List<String> examples;

  String titleIn(String lang) => title[lang] ?? title['en'] ?? title.values.first;
  String bodyIn(String lang) => body[lang] ?? body['en'] ?? body.values.first;
}

const _grammar = r'''
== de u01
T en|"sein" and "heißen"
T tr|"sein" (olmak) ve "heißen" (adı olmak)
B en|The verb "sein" (to be) is irregular: ich bin, du bist, er/sie/es ist, wir sind, ihr seid, sie/Sie sind. To say your name use "Ich heiße …" or "Ich bin …". "Sie" (capital S) is the polite "you".
B tr|"sein" (olmak) düzensiz bir fiildir: ich bin, du bist, er/sie/es ist, wir sind, ihr seid, sie/Sie sind. Adını söylemek için "Ich heiße …" ya da "Ich bin …" denir. Büyük harfle "Sie" kibar "siz" demektir.
E|Ich bin Emir.
E|Du bist nett.
E|Wie heißen Sie?
== de u02
T en|Present tense of regular verbs
T tr|Düzenli fiillerin şimdiki zamanı
B en|Take the stem (kommen → komm-) and add: ich -e, du -st, er/sie/es -t, wir -en, ihr -t, sie/Sie -en. Some verbs change their vowel with du and er/sie: sprechen → du sprichst, er spricht.
B tr|Fiil kökünü al (kommen → komm-) ve ekle: ich -e, du -st, er/sie/es -t, wir -en, ihr -t, sie/Sie -en. Bazı fiillerde du ve er/sie ile ünlü değişir: sprechen → du sprichst, er spricht.
E|Ich komme aus der Türkei.
E|Wo wohnst du?
E|Sie spricht Englisch.
== de u03
T en|Questions: verb in position 2 or 1
T tr|Soru cümleleri: fiil 2. veya 1. sırada
B en|In W-questions (wie, wo, woher, wie viel) the verb comes second: "Wie alt bist du?". In yes/no questions the verb comes first: "Hast du Zeit?".
B tr|W-sorularında (wie, wo, woher, wie viel) fiil ikinci sıradadır: "Wie alt bist du?". Evet/hayır sorularında fiil başa gelir: "Hast du Zeit?".
E|Wie alt bist du?
E|Wie ist deine Telefonnummer?
E|Hast du Geschwister?
== de u04
T en|Articles, gender and "mein"
T tr|Artikeller, cinsiyet ve "mein"
B en|Every noun has a gender: der (masculine), die (feminine), das (neuter), and nouns are capitalised. Learn each noun with its article. Possessives follow the gender: mein Vater, meine Mutter, mein Kind; plural: meine Eltern.
B tr|Her ismin bir cinsiyeti vardır: der (eril), die (dişil), das (nötr) ve isimler büyük harfle yazılır. Her ismi artikeliyle öğren. İyelik cinsiyete uyar: mein Vater, meine Mutter, mein Kind; çoğul: meine Eltern.
E|Das ist mein Vater.
E|Das ist meine Schwester.
E|Wie heißt dein Kind?
== de u05
T en|Accusative: einen / eine / ein
T tr|Akkusativ (belirtme hâli): einen / eine / ein
B en|The direct object is in the accusative. Only the masculine changes: ein → einen, der → den. "Ich möchte einen Kaffee", but "eine Suppe", "ein Wasser". "möchten" = would like: ich möchte, du möchtest, er möchte.
B tr|Nesne Akkusativ’tedir. Yalnızca eril değişir: ein → einen, der → den. "Ich möchte einen Kaffee" ama "eine Suppe", "ein Wasser". "möchten" = istemek (kibar): ich möchte, du möchtest, er möchte.
E|Ich möchte einen Kaffee.
E|Ich nehme eine Suppe.
E|Er isst den Kuchen.
== de u06
T en|Plural forms and prices
T tr|Çoğul biçimleri ve fiyatlar
B en|German plurals vary: -e (Schuhe), -er (Kleider), -n/-en (Jacken), -s (T-Shirts), often with umlaut (Mäntel). The plural article is always "die". Ask prices with "Was kostet …?" (singular) / "Was kosten …?" (plural).
B tr|Almanca çoğullar değişkendir: -e (Schuhe), -er (Kleider), -n/-en (Jacken), -s (T-Shirts), çoğu zaman umlautla (Mäntel). Çoğul artikeli her zaman "die"dir. Fiyat sorarken "Was kostet …?" (tekil) / "Was kosten …?" (çoğul) denir.
E|Was kostet die Jacke?
E|Was kosten die Schuhe?
E|Die Mäntel sind teuer.
== de u07
T en|Negation: "kein" vs "nicht"
T tr|Olumsuzluk: "kein" ve "nicht"
B en|Use "kein" to negate a noun with ein/no article: Ich habe keinen Balkon (masc. accusative: keinen). Use "nicht" for everything else — verbs, adjectives, definite nouns: Die Miete ist nicht teuer.
B tr|"ein"li ya da artikelsiz bir ismi olumsuz yapmak için "kein" kullan: Ich habe keinen Balkon (eril Akkusativ: keinen). Diğer her şey için "nicht" kullan — fiiller, sıfatlar, belirli isimler: Die Miete ist nicht teuer.
E|Ich habe kein Auto.
E|Wir haben keinen Garten.
E|Das Zimmer ist nicht groß.
== de u08
T en|Separable verbs and time
T tr|Ayrılabilen fiiller ve zaman
B en|Verbs like aufstehen, einkaufen, ankommen split in main clauses: the prefix goes to the end — "Ich stehe um sieben Uhr auf." Time: um + clock time, am + day/part of day (am Montag, am Abend).
B tr|aufstehen, einkaufen, ankommen gibi fiiller ana cümlede ayrılır: ön ek sona gider — "Ich stehe um sieben Uhr auf." Zaman: um + saat, am + gün/gün bölümü (am Montag, am Abend).
E|Ich stehe um sieben Uhr auf.
E|Am Samstag kaufe ich ein.
E|Der Zug kommt um elf an.
== de u09
T en|"können" and "gern"
T tr|"können" (-ebilmek) ve "gern" (severek)
B en|Modal verbs push the infinitive to the end: "Ich kann gut schwimmen." können: ich kann, du kannst, er kann, wir können. Say what you like with gern: "Ich lese gern." — more: lieber, most: am liebsten.
B tr|Modal fiiller mastarı sona iter: "Ich kann gut schwimmen." können: ich kann, du kannst, er kann, wir können. Sevdiğin şeyi gern ile söyle: "Ich lese gern." — daha çok: lieber, en çok: am liebsten.
E|Kannst du schwimmen?
E|Ich spiele gern Gitarre.
E|Am liebsten lese ich.
== de u10
T en|Where? — in/an/neben + dative
T tr|Nerede? — in/an/neben + Dativ
B en|For location (wo?) these prepositions take the dative: der/das → dem, die → der. in + dem = im. "Das Museum ist im Zentrum. Die Bank ist neben der Post." Directions use the polite imperative: "Gehen Sie geradeaus!"
B tr|Yer bildirirken (wo?) bu edatlar Dativ alır: der/das → dem, die → der. in + dem = im. "Das Museum ist im Zentrum. Die Bank ist neben der Post." Yol tarifinde kibar emir kipi kullanılır: "Gehen Sie geradeaus!"
E|Das Museum ist im Zentrum.
E|Die Bank ist neben der Post.
E|Gehen Sie links!
== de u11
T en|"müssen" and "mit" + dative
T tr|"müssen" (zorunda olmak) ve "mit" + Dativ
B en|müssen = have to: ich muss, du musst, er muss — the infinitive goes to the end. Transport uses "mit" + dative: mit dem Bus, mit der U-Bahn, mit dem Auto. Destinations: nach + city/country, zu + place (zur Arbeit).
B tr|müssen = zorunda olmak: ich muss, du musst, er muss — mastar sona gider. Ulaşımda "mit" + Dativ: mit dem Bus, mit der U-Bahn, mit dem Auto. Varış yeri: nach + şehir/ülke, zu + yer (zur Arbeit).
E|Ich muss in Hannover umsteigen.
E|Ich fahre mit dem Bus zur Arbeit.
E|Wir fliegen nach Istanbul.
== de u12
T en|Imperative and "sollen"
T tr|Emir kipi ve "sollen"
B en|Polite imperative: verb + Sie (Nehmen Sie …!). Informal: verb stem without -st (du nimmst → Nimm …!). "sollen" passes on advice or instructions: "Ich soll viel trinken." Pain: "Mein Kopf tut weh" or "Ich habe Kopfschmerzen".
B tr|Kibar emir: fiil + Sie (Nehmen Sie …!). Samimi: -st eki olmadan fiil (du nimmst → Nimm …!). "sollen" tavsiye ya da talimat aktarır: "Ich soll viel trinken." Ağrı: "Mein Kopf tut weh" ya da "Ich habe Kopfschmerzen".
E|Nehmen Sie diese Tabletten.
E|Trink viel Tee!
E|Ich soll im Bett bleiben.
== de u13
T en|"es" for weather; im/am
T tr|Hava için "es"; im/am
B en|Weather verbs use the impersonal "es": es regnet, es schneit, es ist kalt. Months and seasons take "im" (im Mai, im Winter), days take "am" (am Sonntag).
B tr|Hava fiilleri öznesiz "es" ile kurulur: es regnet, es schneit, es ist kalt. Aylar ve mevsimler "im" alır (im Mai, im Winter), günler "am" (am Sonntag).
E|Es regnet und es ist kalt.
E|Im Winter schneit es.
E|Mein Geburtstag ist im Mai.
== de u14
T en|Perfekt with "haben"
T tr|"haben" ile Perfekt (geçmiş zaman)
B en|Spoken past = haben (position 2) + participle (end). Regular: ge- + stem + -t (arbeiten → gearbeitet). Irregular: ge- + changed stem + -en (schreiben → geschrieben). Jobs need no article: "Ich bin Lehrerin."
B tr|Konuşmada geçmiş = haben (2. sırada) + ortaç (sonda). Düzenli: ge- + kök + -t (arbeiten → gearbeitet). Düzensiz: ge- + değişen kök + -en (schreiben → geschrieben). Meslekte artikel kullanılmaz: "Ich bin Lehrerin."
E|Gestern habe ich lange gearbeitet.
E|Ich habe eine E-Mail geschrieben.
E|Er ist Ingenieur.
== de u15
T en|Perfekt with "sein"
T tr|"sein" ile Perfekt
B en|Verbs of movement from A to B or change of state use "sein": fahren → ist gefahren, gehen → ist gegangen, passieren → ist passiert. Everything else uses "haben". Separable: einkaufen → eingekauft.
B tr|A’dan B’ye hareket ya da durum değişimi bildiren fiiller "sein" alır: fahren → ist gefahren, gehen → ist gegangen, passieren → ist passiert. Diğerleri "haben" alır. Ayrılabilen fiil: einkaufen → eingekauft.
E|Ich bin nach Hamburg gefahren.
E|Was ist passiert?
E|Ich habe meinen Schlüssel verloren.
== de u16
T en|Dative objects: mir, dir, ihm, ihr
T tr|Dativ nesneler: mir, dir, ihm, ihr
B en|Verbs like schenken, geben, helfen, gratulieren take a dative person: "Ich schenke ihr Blumen." Pronouns: mir, dir, ihm, ihr, uns, euch, ihnen/Ihnen. Articles: dem (m/n), der (f), den + -n (pl).
B tr|schenken, geben, helfen, gratulieren gibi fiiller Dativ kişi alır: "Ich schenke ihr Blumen." Zamirler: mir, dir, ihm, ihr, uns, euch, ihnen/Ihnen. Artikeller: dem (eril/nötr), der (dişil), den + -n (çoğul).
E|Ich schenke ihr Blumen.
E|Was schenkst du deiner Mutter?
E|Ich gratuliere dir!
== de u17
T en|"weil" — verb at the end
T tr|"weil" (çünkü) — fiil sonda
B en|"weil" starts a subordinate clause, and the conjugated verb goes to the very end: "…, weil das in Deutschland wichtig ist." With separable verbs the prefix stays attached: "weil ich morgen umziehe".
B tr|"weil" bir yan cümle başlatır ve çekimli fiil en sona gider: "…, weil das in Deutschland wichtig ist." Ayrılabilen fiillerde ön ek ayrılmaz: "weil ich morgen umziehe".
E|Ich trenne den Müll, weil das wichtig ist.
E|Ich bin müde, weil ich spät geschlafen habe.
E|Wir ziehen um, weil die Miete zu hoch ist.
== de u18
T en|"dass" clauses
T tr|"dass" (ki/-dığı) yan cümleleri
B en|After verbs like glauben, denken, wissen, finden you can use "dass" + verb at the end: "Ich glaube, dass alles fertig ist." Formal requests use the Sie-imperative: "Füllen Sie bitte das Formular aus."
B tr|glauben, denken, wissen, finden gibi fiillerden sonra "dass" + sonda fiil kullanılır: "Ich glaube, dass alles fertig ist." Resmî ricalar Sie-emir kipiyle yapılır: "Füllen Sie bitte das Formular aus."
E|Ich glaube, dass alles fertig ist.
E|Ich weiß, dass der Termin um neun ist.
E|Füllen Sie bitte das Formular aus.
== de u19
T en|Reflexive verbs
T tr|Dönüşlü fiiller
B en|Some verbs need a reflexive pronoun: sich fühlen, sich ausruhen, sich freuen. ich → mich, du → dich, er/sie/es → sich, wir → uns, ihr → euch, sie/Sie → sich. "Ich fühle mich nicht gut."
B tr|Bazı fiiller dönüşlü zamir ister: sich fühlen, sich ausruhen, sich freuen. ich → mich, du → dich, er/sie/es → sich, wir → uns, ihr → euch, sie/Sie → sich. "Ich fühle mich nicht gut."
E|Ich fühle mich nicht gut.
E|Du musst dich ausruhen.
E|Wie fühlen Sie sich?
== de u20
T en|Comparative and superlative
T tr|Karşılaştırma ve üstünlük
B en|Comparative: adjective + -er (schnell → schneller), compare with "als". Superlative: am + -sten (am schnellsten). Irregular: gut – besser – am besten; viel – mehr – am meisten; gern – lieber – am liebsten.
B tr|Karşılaştırma: sıfat + -er (schnell → schneller), "als" ile kıyaslanır. Üstünlük: am + -sten (am schnellsten). Düzensiz: gut – besser – am besten; viel – mehr – am meisten; gern – lieber – am liebsten.
E|Diese App ist besser als die alte.
E|Das Internet ist heute langsamer.
E|Welche App findest du am besten?
== de u21
T en|Präteritum of "sein" and "haben"
T tr|"sein" ve "haben"in Präteritum’u
B en|Even in speech Germans use the simple past of sein and haben: ich war, du warst, er war, wir waren; ich hatte, du hattest, er hatte, wir hatten. "Wie war deine Reise?"
B tr|Almanlar konuşmada bile sein ve haben için basit geçmiş zamanı kullanır: ich war, du warst, er war, wir waren; ich hatte, du hattest, er hatte, wir hatten. "Wie war deine Reise?"
E|Wie war deine Reise?
E|Sie war toll, aber ich hatte wenig Zeit.
E|Wir waren in den Alpen.
== de u22
T en|Two-way prepositions
T tr|İki yönlü edatlar (Wechselpräpositionen)
B en|in, an, auf, unter, über, vor, hinter, neben, zwischen take the accusative for movement (wohin? → auf den Tisch) and the dative for location (wo? → auf dem Tisch). Verbs come in pairs: stellen/stehen, legen/liegen.
B tr|in, an, auf, unter, über, vor, hinter, neben, zwischen hareket bildirirken Akkusativ (wohin? → auf den Tisch), yer bildirirken Dativ (wo? → auf dem Tisch) alır. Fiiller çift hâlinde gelir: stellen/stehen, legen/liegen.
E|Ich stelle das Glas auf den Tisch.
E|Das Glas steht auf dem Tisch.
E|Wir gehen in das Restaurant.
== de u23
T en|"wenn" clauses
T tr|"wenn" (-ınca / eğer) yan cümleleri
B en|"wenn" means "when/whenever" or "if" and sends the verb to the end. If the wenn-clause comes first, the main clause starts with the verb: "Wenn ich müde bin, bin ich schnell wütend."
B tr|"wenn" "-dığında / her … -dığında" ya da "eğer" demektir ve fiili sona gönderir. Wenn-cümlesi başta gelirse ana cümle fiille başlar: "Wenn ich müde bin, bin ich schnell wütend."
E|Wenn ich müde bin, bin ich schnell wütend.
E|Wenn du traurig bist, ruf mich an.
E|Ich bin glücklich, wenn die Sonne scheint.
== de u24
T en|Konjunktiv II: polite and unreal
T tr|Konjunktiv II: kibarlık ve gerçek dışı durumlar
B en|Use würde + infinitive, or the forms hätte, wäre, könnte, for politeness ("Könnten Sie …?") and unreal wishes: "Wenn ich mehr Zeit hätte, würde ich eine Ausbildung machen."
B tr|Kibarlık ("Könnten Sie …?") ve gerçek dışı dilekler için würde + mastar ya da hätte, wäre, könnte biçimleri kullanılır: "Wenn ich mehr Zeit hätte, würde ich eine Ausbildung machen."
E|Ich würde gern im Team arbeiten.
E|Könnten Sie auch in Teilzeit arbeiten?
E|Das wäre kein Problem.
== de u25
T en|Passive voice (present)
T tr|Edilgen çatı (şimdiki zaman)
B en|Passive = werden + participle at the end: "Der Müll wird abgeholt." The doer is often left out; "man" is a common active alternative: "Man recycelt viel."
B tr|Edilgen = werden + sonda ortaç: "Der Müll wird abgeholt." Eylemi yapan genelde söylenmez; "man" yaygın bir etken alternatiftir: "Man recycelt viel."
E|In Deutschland wird viel recycelt.
E|Der Müll wird jeden Montag abgeholt.
E|Man kann weniger Plastik benutzen.
== de u26
T en|Präteritum for narration
T tr|Anlatımda Präteritum
B en|Written stories and history use the Präteritum. Regular verbs add -te (sagen → sagte); irregular verbs change the stem (fallen → fiel, kommen → kam, gehen → ging).
B tr|Yazılı hikâyeler ve tarih anlatımı Präteritum kullanır. Düzenli fiiller -te alır (sagen → sagte); düzensiz fiillerde kök değişir (fallen → fiel, kommen → kam, gehen → ging).
E|Die Mauer fiel im Jahr 1989.
E|1990 kam die Wiedervereinigung.
E|Deutschland war viele Jahre geteilt.
== de u27
T en|Relative clauses
T tr|İlgi cümleleri (Relativsätze)
B en|Relative pronouns mostly look like articles (der, die, das, den, dem, denen, dessen) and take the gender of the noun and the case of their role in the clause. The verb goes to the end: "die Lehrerin, die uns hilft"; "der Kurs, den ich mag".
B tr|İlgi zamirleri çoğunlukla artikellere benzer (der, die, das, den, dem, denen, dessen); ismin cinsiyetini ve yan cümledeki görevine göre hâlini alır. Fiil sona gider: "die Lehrerin, die uns hilft"; "der Kurs, den ich mag".
E|Die Lehrerin, die uns hilft, ist super.
E|Das ist der Kurs, den ich sehr mag.
E|Das ist das Buch, das ich lese.
== de u28
T en|Arguing: zu + infinitive, obwohl, trotzdem
T tr|Tartışma: zu + mastar, obwohl, trotzdem
B en|"Es ist wichtig, … zu sagen" — zu + infinitive at the end. "obwohl" (although) sends the verb to the end; "trotzdem" and "deshalb" are adverbs: the verb follows right after them.
B tr|"Es ist wichtig, … zu sagen" — zu + mastar sonda. "obwohl" (-e rağmen) fiili sona gönderir; "trotzdem" (yine de) ve "deshalb" (bu yüzden) zarftır: fiil hemen arkalarından gelir.
E|Es ist wichtig, die eigene Meinung zu sagen.
E|Obwohl es praktisch ist, fehlt mir das Team.
E|Trotzdem sollten wir einen Kompromiss finden.
== de u29
T en|Genitive
T tr|Genitiv (tamlayan hâli)
B en|The genitive shows possession: des (m/n, noun + -s/-es), der (f/pl): "der Film des Regisseurs", "die Märchen der Brüder Grimm". In writing, wegen and trotz take the genitive: "trotz des Regens".
B tr|Genitiv iyelik bildirir: des (eril/nötr, isim + -s/-es), der (dişil/çoğul): "der Film des Regisseurs", "die Märchen der Brüder Grimm". Yazı dilinde wegen ve trotz Genitiv alır: "trotz des Regens".
E|Der Film des Regisseurs war spannend.
E|Trotz des Regens gingen wir zur Ausstellung.
E|Kennst du die Märchen der Brüder Grimm?
== en u01
T tr|"to be": am / is / are
T de|"to be": am / is / are
B tr|"to be" (olmak) öznelere göre değişir: I am, you are, he/she/it is, we/they are. Kısaltmalar çok yaygındır: I'm, you're, she's. Adını söylemek için "My name is …" ya da "I'm …" denir.
B de|"to be" (sein) richtet sich nach dem Subjekt: I am, you are, he/she/it is, we/they are. Kurzformen sind üblich: I'm, you're, she's. Den Namen sagt man mit "My name is …" oder "I'm …".
E|I'm Emir.
E|What's your name?
E|How are you?
== en u02
T tr|Geniş zaman (Present simple)
T de|Present simple
B tr|Alışkanlık ve genel gerçekler için fiilin yalın hâli kullanılır: I live, you speak. he/she/it ile fiil -s alır: she lives, he speaks. Soru: "Where do you live?"
B de|Für Gewohnheiten und Fakten nimmt man die Grundform: I live, you speak. Bei he/she/it kommt -s dazu: she lives, he speaks. Frage: "Where do you live?"
E|I come from Turkey.
E|She lives in Berlin.
E|Which languages do you speak?
== en u03
T tr|"do/does" ile sorular ve yaş
T de|Fragen mit "do/does" und Alter
B tr|Geniş zamanda soru "do/does" ile kurulur: "Do you have siblings?" Yaş ise "to be" ile söylenir: "I am twenty (years old)." — "I have twenty years" yanlıştır!
B de|Fragen im Present simple bildet man mit "do/does": "Do you have siblings?" Das Alter sagt man mit "to be": "I am twenty (years old)." — nicht "I have twenty years"!
E|How old are you?
E|I'm twenty years old.
E|What's your phone number?
== en u04
T tr|İyelik ve a/an/the
T de|Possessivbegleiter und a/an/the
B tr|İyelik sözcükleri değişmez: my, your, his, her, its, our, their. "a" ünsüzle, "an" ünlü sesle başlayan kelimelerden önce gelir (a brother, an aunt); "the" belirli bir şeyi gösterir. İngilizcede isimlerin cinsiyeti yoktur.
B de|Possessivbegleiter ändern sich nicht: my, your, his, her, its, our, their. "a" steht vor Konsonantenlaut, "an" vor Vokallaut (a brother, an aunt); "the" ist der bestimmte Artikel. Nomen haben kein grammatisches Geschlecht.
E|This is my mother.
E|Is that your family?
E|I have a brother and a sister.
== en u05
T tr|"would like" ve sayılabilen/sayılamayan
T de|"would like" und zählbar/unzählbar
B tr|Kibar istek: "I'd like a coffee." Sayılabilen isimler a/an ve çoğul alır (an apple, two apples); sayılamayanlar almaz (bread, water, some milk). "a piece of cake" gibi ölçülerle sayılır.
B de|Höfliche Bitte: "I'd like a coffee." Zählbare Nomen haben a/an und Plural (an apple, two apples); unzählbare nicht (bread, water, some milk). Man zählt mit Mengen: "a piece of cake".
E|I'd like a coffee, please.
E|Would you like something to eat?
E|I don't eat meat.
== en u06
T tr|Çoğullar ve How much / How many
T de|Plural und How much / How many
B tr|Çoğul genelde -s/-es ile yapılır (shoes, dresses); düzensizler: child → children, man → men, woman → women. Fiyat ve sayılamayanlar için "How much…?", sayılabilenler için "How many…?" kullanılır.
B de|Der Plural endet meist auf -s/-es (shoes, dresses); unregelmäßig: child → children, man → men, woman → women. "How much…?" für Preise und Unzählbares, "How many…?" für Zählbares.
E|How much is the jacket?
E|The shoes are cheap.
E|How many children are here?
== en u07
T tr|there is / there are ve olumsuzluk
T de|there is / there are und Verneinung
B tr|Var/yok için "there is" (tekil) ve "there are" (çoğul) kullanılır. Olumsuz: isn't / aren't; fiillerde don't / doesn't: "I don't have a balcony."
B de|"Es gibt" heißt "there is" (Singular) bzw. "there are" (Plural). Verneinung: isn't / aren't; bei Verben don't / doesn't: "I don't have a balcony."
E|There are two rooms.
E|There isn't a garden.
E|I don't have a balcony.
== en u08
T tr|Sıklık zarfları ve saat
T de|Häufigkeitsadverbien und Uhrzeit
B tr|always, often, sometimes, never ana fiilden önce, "to be"den sonra gelir: "I often cook." / "She is always late." Saat: "at seven o'clock", günler: "on Saturday", "in the morning".
B de|always, often, sometimes, never stehen vor dem Vollverb, aber nach "to be": "I often cook." / "She is always late." Uhrzeit: "at seven o'clock", Tage: "on Saturday", "in the morning".
E|I get up at seven o'clock.
E|I often cook in the evening.
E|On Saturday I go shopping.
== en u09
T tr|can ve like + -ing
T de|can und like + -ing
B tr|"can" tüm öznelerde aynıdır ve ardından yalın fiil gelir: "She can swim." Olumsuz: can't. Sevdiğin aktiviteler için "like + -ing": "I like reading."
B de|"can" ist für alle Personen gleich, danach folgt die Grundform: "She can swim." Verneint: can't. Vorlieben: "like + -ing": "I like reading."
E|Can you swim?
E|I like reading and playing football.
E|I play the guitar.
== en u10
T tr|Yer edatları ve yol tarifi
T de|Ortspräpositionen und Wegbeschreibung
B tr|next to, in, on, at, opposite, between yer bildirir: "The bank is next to the post office." Yol tarifinde emir kipi kullanılır: "Go straight ahead and turn left."
B de|next to, in, on, at, opposite, between geben den Ort an: "The bank is next to the post office." Wegbeschreibungen nutzen den Imperativ: "Go straight ahead and turn left."
E|Excuse me, where is the train station?
E|Go straight ahead and then left.
E|The museum is in the centre.
== en u11
T tr|have to ve ulaşım
T de|have to und Verkehrsmittel
B tr|Zorunluluk için "have to / has to": "I have to change trains." Ulaşım aracı "by" ile söylenir: by bus, by train (ama "on foot"). "take the bus" da çok yaygındır.
B de|Notwendigkeit: "have to / has to": "I have to change trains." Verkehrsmittel mit "by": by bus, by train (aber "on foot"). Üblich ist auch "take the bus".
E|Do I have to change trains?
E|I take the bus to work.
E|The train is delayed.
== en u12
T tr|Emir kipi ve "should"
T de|Imperativ und "should"
B tr|Emir kipi fiilin yalın hâlidir: "Take these pills." Tavsiye için "should": "You should rest." Ağrı: "I have a headache / My back hurts."
B de|Der Imperativ ist die Grundform: "Take these pills." Ratschläge mit "should": "You should rest." Schmerzen: "I have a headache / My back hurts."
E|Take these pills.
E|You should drink a lot of water.
E|I have a headache.
== en u13
T tr|Hava için "it" ve şimdiki zaman
T de|"it" beim Wetter und Present continuous
B tr|Hava durumu "it" ile anlatılır: "It's cold." Şu anda olan şeyler için "am/is/are + -ing": "It's raining." Aylar ve mevsimler "in" alır: in May, in winter.
B de|Wetter beschreibt man mit "it": "It's cold." Was gerade passiert: "am/is/are + -ing": "It's raining." Monate und Jahreszeiten mit "in": in May, in winter.
E|It's raining and it's cold.
E|In winter it snows.
E|The sun is shining!
== en u14
T tr|Meslekler: "a/an" ve geniş zaman
T de|Berufe: "a/an" und Present simple
B tr|Meslekler İngilizcede "a/an" ile söylenir: "I'm a teacher." (Almancanın aksine!). Meslek sorusu: "What do you do?" Geçmiş için -ed: "I worked late."
B de|Berufe stehen im Englischen mit "a/an": "I'm a teacher." (anders als im Deutschen!). Frage: "What do you do?" Vergangenheit mit -ed: "I worked late."
E|I'm a teacher.
E|Where do you work?
E|Yesterday I worked late.
== en u15
T tr|Geçmiş zaman (Past simple)
T de|Past simple
B tr|Düzenli fiiller -ed alır (visit → visited); düzensizler ezberlenir (go → went, lose → lost, find → found). Soru ve olumsuzda "did" + yalın fiil: "Did you find it?"
B de|Regelmäßige Verben bekommen -ed (visit → visited); unregelmäßige muss man lernen (go → went, lose → lost, find → found). Fragen und Verneinung mit "did" + Grundform: "Did you find it?"
E|I visited my grandma.
E|I lost my key.
E|Did you find it?
== en u16
T tr|Nesne zamirleri ve tarihler
T de|Objektpronomen und Daten
B tr|Nesne zamirleri: me, you, him, her, it, us, them. "give/send someone something": "I'm giving her flowers." Tarih: "on the twelfth of March" / "on March 12th".
B de|Objektpronomen: me, you, him, her, it, us, them. "give/send someone something": "I'm giving her flowers." Datum: "on the twelfth of March" / "on March 12th".
E|I'm giving her flowers.
E|When is your birthday?
E|I'm inviting you to my party.
== en u17
T tr|because ve so
T de|because und so
B tr|"because" sebep, "so" sonuç bildirir; İngilizcede kelime sırası değişmez: "I separate the rubbish because it's important." / "It's important, so I separate it."
B de|"because" nennt den Grund, "so" die Folge; die Wortstellung ändert sich nicht (anders als bei "weil"): "I separate the rubbish because it's important."
E|Because it is important in Germany.
E|I take the bottles back because there's a deposit.
E|We are moving next month.
== en u18
T tr|Resmî ricalar ve "that"
T de|Höfliche Bitten und "that"
B tr|Kibar rica: "Could you …?", "I'd like to …". "I think (that) …" — İngilizcede "that" çoğu zaman düşer ve fiil yer değiştirmez: "I think everything is ready."
B de|Höfliche Bitten: "Could you …?", "I'd like to …". "I think (that) …" — "that" fällt oft weg, und das Verb bleibt an seinem Platz: "I think everything is ready."
E|I would like to register my address.
E|Could you fill in this form, please?
E|I think that everything is ready.
== en u19
T tr|feel + sıfat ve tavsiye
T de|feel + Adjektiv und Ratschläge
B tr|"feel" sıfat alır (zarf değil): "I feel sick / I don't feel well." Tavsiye: "You should rest", güçlü zorunluluk: "You must call 112."
B de|"feel" steht mit Adjektiv: "I feel sick / I don't feel well." Ratschläge: "You should rest", starke Pflicht: "You must call 112."
E|How are you feeling?
E|I don't feel well.
E|You have to rest.
== en u20
T tr|Karşılaştırma ve üstünlük
T de|Komparativ und Superlativ
B tr|Kısa sıfatlar -er/-est alır (fast → faster → the fastest); uzunlar more/most (more expensive). Düzensiz: good → better → the best. Kıyaslamada "than": "better than the old one".
B de|Kurze Adjektive: -er/-est (fast → faster → the fastest); lange mit more/most (more expensive). Unregelmäßig: good → better → the best. Vergleich mit "than".
E|This app is better than the old one.
E|The internet is slower today.
E|Which app do you like best?
== en u21
T tr|was/were ve "did" soruları
T de|was/were und Fragen mit "did"
B tr|"to be"nin geçmişi: I/he/she/it was, you/we/they were. Diğer fiillerde soru "did" ile: "Did you book a hotel?" Planlar için "be going to": "I'm going to visit the castle."
B de|Vergangenheit von "to be": I/he/she/it was, you/we/they were. Andere Verben fragen mit "did": "Did you book a hotel?" Pläne: "be going to": "I'm going to visit the castle."
E|How was your trip?
E|It was great, but I had little time.
E|Have you already booked a hotel?
== en u22
T tr|Restoranda sipariş: "I'll have …"
T de|Im Restaurant: "I'll have …"
B tr|Sipariş verirken "I'll have …" ya da "Could I have …?" denir. Hesap: "Could we have the bill, please?" (ABD'de "check"). Bahşiş: "Keep the change."
B de|Bestellen: "I'll have …" oder "Could I have …?". Rechnung: "Could we have the bill, please?" (US: "check"). Trinkgeld: "Keep the change."
E|I'll have the schnitzel with salad.
E|And for dessert?
E|Twenty-five, keep the change.
== en u23
T tr|Koşul cümleleri (0 ve 1. tip)
T de|Bedingungssätze (Typ 0 und 1)
B tr|Genel doğrular: if/when + geniş zaman, geniş zaman ("When I'm tired, I get angry."). Olası durum: if + geniş zaman, will/emir ("If you're sad, call me.").
B de|Allgemeine Wahrheiten: if/when + Present, Present ("When I'm tired, I get angry."). Mögliche Situation: if + Present, will/Imperativ ("If you're sad, call me.").
E|When I'm tired, I get angry quickly.
E|If you are sad, call me.
E|I'm looking forward to the weekend.
== en u24
T tr|2. tip koşul ve kibar "would"
T de|Bedingungssatz Typ 2 und höfliches "would"
B tr|Gerçek dışı durum: if + geçmiş zaman, would + fiil: "If I had more time, I would do a course." Kibarlık için "would/could": "I would like to…", "Could you…?"
B de|Irreale Situation: if + Past, would + Verb: "If I had more time, I would do a course." Höflichkeit mit "would/could": "I would like to…", "Could you…?"
E|I would like to work in an international team.
E|Could you also work part-time?
E|If I had more time, I would do vocational training.
== en u25
T tr|Edilgen yapı (Passive)
T de|Passiv
B tr|Edilgen = am/is/are + 3. hâl (past participle): "Plastic is recycled." Eylemi yapan önemliyse "by" ile eklenir. Genel öznede "you/people" da kullanılır.
B de|Passiv = am/is/are + Partizip (past participle): "Plastic is recycled." Der Handelnde kommt mit "by". Für "man" sagt man oft "you/people".
E|A lot is recycled in Germany.
E|The rubbish is collected every Monday.
E|We should save more energy.
== en u26
T tr|Anlatıda geçmiş ve "used to"
T de|Erzählen in der Vergangenheit und "used to"
B tr|Tarih anlatırken past simple kullanılır: "The wall fell in 1989." Geçmişteki alışkanlıklar ve artık geçerli olmayan durumlar için "used to": "Germany used to be divided."
B de|Geschichte erzählt man im Past simple: "The wall fell in 1989." Für frühere Gewohnheiten und Zustände: "used to": "Germany used to be divided."
E|The wall fell in 1989.
E|Germany was divided for many years.
E|Many guest workers came from Turkey.
== en u27
T tr|İlgi cümleleri: who / which / that
T de|Relativsätze: who / which / that
B tr|İnsanlar için "who", şeyler için "which", ikisi için de "that": "the teacher who helps us", "the course that I like". Nesne olduğunda zamir düşebilir: "the course I like".
B de|"who" für Personen, "which" für Dinge, "that" für beides: "the teacher who helps us", "the course that I like". Als Objekt kann es wegfallen: "the course I like".
E|The teacher who helps us is great.
E|That is the course that I really like.
E|Did you pass the exam?
== en u28
T tr|Bağlaçlar: although, however, therefore
T de|Konnektoren: although, however, therefore
B tr|"although" (-e rağmen) iki cümleyi bağlar; "however" (ancak) ve "therefore" (bu yüzden) genelde yeni cümlenin başında virgülle gelir. "It's important to + fiil" yapısı da çok yaygındır.
B de|"although" (obwohl) verbindet zwei Sätze; "however" (jedoch) und "therefore" (deshalb) stehen meist am Satzanfang mit Komma. Häufig auch: "It's important to + Verb".
E|Although it's practical, I miss the team.
E|I agree with you.
E|It is important to say your own opinion.
== en u29
T tr|İyelik 's ve "because of / despite"
T de|Besitz mit 's und "because of / despite"
B tr|Kişilerde iyelik 's ile: "Kafka's novel", "the director's film". "because of" ve "despite" isim alır: "despite the rain".
B de|Besitz bei Personen mit 's: "Kafka's novel", "the director's film". "because of" und "despite" stehen mit Nomen: "despite the rain".
E|The director's film was very exciting.
E|Despite the rain we went to the exhibition.
E|I am reading a novel by Kafka right now.
== tr u01
T en|Personal endings: "Ben öğrenciyim"
T de|Personalendungen: "Ben öğrenciyim"
B en|Turkish has no verb "to be" in the present — it adds personal endings: -(y)Im (I), -sIn (you), – (he/she), -(y)Iz (we). The vowel follows vowel harmony: öğrenciyim, yorgunum. Name: "Benim adım …" / "Adım …".
B de|Im Präsens gibt es kein "sein" – man hängt Personalendungen an: -(y)Im (ich), -sIn (du), – (er/sie), -(y)Iz (wir). Der Vokal folgt der Vokalharmonie: öğrenciyim, yorgunum. Name: "Benim adım …" / "Adım …".
E|Ben Emir.
E|Benim adım Lena.
E|İyiyim, teşekkürler.
== tr u02
T en|Vowel harmony: -de/-da, -den/-dan
T de|Vokalharmonie: -de/-da, -den/-dan
B en|Endings change their vowel to match the last vowel of the word. Two-way (e/a): after e, i, ö, ü → e; after a, ı, o, u → a. Locative "in/at": Berlin'de, Ankara'da. Ablative "from": Türkiye'den, Almanya'dan. After p, ç, t, k, f, h, s, ş the d becomes t: İstanbul'da but Paris'te.
B de|Endungen passen ihren Vokal an den letzten Vokal des Wortes an. Zweifach (e/a): nach e, i, ö, ü → e; nach a, ı, o, u → a. Lokativ "in": Berlin'de, Ankara'da. Ablativ "aus/von": Türkiye'den, Almanya'dan. Nach p, ç, t, k, f, h, s, ş wird d zu t: İstanbul'da, aber Paris'te.
E|Türkiye'den geliyorum.
E|Berlin'de yaşıyorum.
E|Hangi dilleri konuşuyorsun?
== tr u03
T en|Question particle mi/mı/mu/mü
T de|Fragepartikel mi/mı/mu/mü
B en|Yes/no questions use the separate particle mi with four-way vowel harmony (i, ı, u, ü) after the word in question: "Pahalı mı?", "Evli misin?". Age: "Kaç yaşındasın?" — "Yirmi yaşındayım."
B de|Ja/Nein-Fragen bildet die getrennte Partikel mi mit vierfacher Harmonie (i, ı, u, ü) nach dem erfragten Wort: "Pahalı mı?", "Evli misin?". Alter: "Kaç yaşındasın?" – "Yirmi yaşındayım."
E|Kaç yaşındasın?
E|Telefon numaran ne?
E|Bu ne kadar?
== tr u04
T en|Possessive endings and "var/yok"
T de|Possessivendungen und "var/yok"
B en|Possession is a suffix: annem (my mother), annen (your), annesi (his/her), annemiz (our). "Have" is expressed with var (there is) / yok (there isn't): "Kardeşim var" = I have a sibling.
B de|Besitz wird angehängt: annem (meine Mutter), annen (deine), annesi (seine/ihre), annemiz (unsere). "Haben" drückt man mit var (es gibt) / yok (es gibt nicht) aus: "Kardeşim var" = Ich habe Geschwister.
E|Bu benim annem.
E|Kardeşin var mı?
E|Evet, bir erkek ve bir kız kardeşim var.
== tr u05
T en|Accusative -(y)I and "istiyorum"
T de|Akkusativ -(y)I und "istiyorum"
B en|A definite direct object takes -(y)ı/i/u/ü: "Kahveyi içiyorum" (the coffee). An indefinite one has no ending: "Bir kahve istiyorum" (a coffee). "istemek" = to want: istiyorum, istiyor musun?
B de|Ein bestimmtes direktes Objekt bekommt -(y)ı/i/u/ü: "Kahveyi içiyorum" (den Kaffee). Unbestimmt bleibt es endungslos: "Bir kahve istiyorum". "istemek" = wollen: istiyorum, istiyor musun?
E|Bir kahve istiyorum, lütfen.
E|Bir şey de yemek ister misin?
E|Et yemiyorum.
== tr u06
T en|Plural -ler/-lar and numbers
T de|Plural -ler/-lar und Zahlen
B en|Plural: -ler after e, i, ö, ü; -lar after a, ı, o, u (ayakkabılar, elbiseler). After a number the noun stays singular: "iki kitap" (two books), not "iki kitaplar". Price: "Ne kadar?"
B de|Plural: -ler nach e, i, ö, ü; -lar nach a, ı, o, u (ayakkabılar, elbiseler). Nach Zahlen bleibt das Nomen im Singular: "iki kitap" (zwei Bücher). Preis: "Ne kadar?"
E|Ceket ne kadar?
E|Ceket elli avro.
E|Kartla ödeyebilir miyim?
== tr u07
T en|"değil" and "var/yok"
T de|"değil" und "var/yok"
B en|Negate nouns/adjectives with değil (+ personal ending): "pahalı değil", "öğrenci değilim". Existence: "Balkon var / yok". With possession: "Balkonum yok" (I don't have a balcony).
B de|Nomen/Adjektive verneint man mit değil (+ Personalendung): "pahalı değil", "öğrenci değilim". Existenz: "Balkon var / yok". Mit Besitz: "Balkonum yok" (Ich habe keinen Balkon).
E|Küçük ama aydınlık.
E|Hayır, balkonum yok.
E|Kira pahalı değil.
== tr u08
T en|Present continuous -(I)yor
T de|Präsens auf -(I)yor
B en|-(ı/i/u/ü)yor + personal ending expresses what you are doing now and routines: kalkıyorum (I get up / am getting up), çalışıyorsun, yapıyor. Clock time: "saat yedide" (at seven).
B de|-(ı/i/u/ü)yor + Personalendung drückt Gegenwart und Gewohnheiten aus: kalkıyorum (ich stehe auf), çalışıyorsun, yapıyor. Uhrzeit: "saat yedide" (um sieben).
E|Saat yedide kalkıyorum.
E|Duş alıyorum ve kahvaltı yapıyorum.
E|Hafta sonu ne yapıyorsun?
== tr u09
T en|Ability -(y)Abil and "-mAyı severim"
T de|Können -(y)Abil und "-mAyı severim"
B en|"Can" is the suffix -(y)abil/-(y)ebil before the tense: yüzebilirim (I can swim), yüzebilir misin? Likes: verb + -mayı/-meyi severim: "Okumayı severim."
B de|"Können" ist die Endung -(y)abil/-(y)ebil vor der Zeitform: yüzebilirim (ich kann schwimmen), yüzebilir misin? Vorlieben: Verb + -mayı/-meyi severim: "Okumayı severim."
E|Yüzebilir misin?
E|Evet, iyi yüzebilirim.
E|Okumayı ve futbol oynamayı severim.
== tr u10
T en|Dative -(y)A and directions
T de|Dativ -(y)A und Wegbeschreibung
B en|Direction "to" is the dative -(y)a/-(y)e: sola (to the left), istasyona (to the station). Polite imperative adds -(y)In: "gidin", "dönün". "Where is …?" = "… nerede?"
B de|Richtung "nach/zu" ist der Dativ -(y)a/-(y)e: sola (nach links), istasyona (zum Bahnhof). Höflicher Imperativ mit -(y)In: "gidin", "dönün". "Wo ist …?" = "… nerede?"
E|Affedersiniz, tren istasyonu nerede?
E|Dümdüz gidin, sonra sola dönün.
E|Banka postanenin yanında.
== tr u11
T en|Instrumental -(y)lA and necessity
T de|Instrumental -(y)lA und Notwendigkeit
B en|"by/with" is -(y)la/-(y)le: otobüsle (by bus), trenle. "Must/have to": -malı/-meli or "… gerekiyor": "Aktarma yapmam gerekiyor mu?" (Do I have to change?).
B de|"mit" ist -(y)la/-(y)le: otobüsle (mit dem Bus), trenle. "Müssen": -malı/-meli oder "… gerekiyor": "Aktarma yapmam gerekiyor mu?" (Muss ich umsteigen?).
E|İşe otobüsle gidiyorum.
E|Hamburg'a bir bilet istiyorum.
E|Aktarma yapmam gerekiyor mu?
== tr u12
T en|Imperative and "… ağrıyor"
T de|Imperativ und "… ağrıyor"
B en|The informal imperative is the bare stem (al! = take!), formal adds -(y)In (alın!). Pain: body part + possessive + ağrıyor: "Başım ağrıyor" (my head hurts).
B de|Der informelle Imperativ ist der Stamm (al! = nimm!), formell mit -(y)In (alın!). Schmerzen: Körperteil + Possessiv + ağrıyor: "Başım ağrıyor" (mein Kopf tut weh).
E|Bu hapları alın.
E|Başım ağrıyor.
E|Günde üç kez.
== tr u13
T en|Weather and time expressions
T de|Wetter und Zeitangaben
B en|Weather uses a noun + verb: "yağmur yağıyor" (it's raining, lit. rain is raining), "kar yağıyor", "güneş parlıyor". Seasons: yazın (in summer), kışın (in winter); months take -da/-de: mayısta.
B de|Wetter mit Nomen + Verb: "yağmur yağıyor" (es regnet, wörtl. Regen regnet), "kar yağıyor", "güneş parlıyor". Jahreszeiten: yazın (im Sommer), kışın (im Winter); Monate mit -da/-de: mayısta.
E|Yağmur yağıyor ve hava soğuk.
E|Kışın kar yağar.
E|Doğum günüm mayısta.
== tr u14
T en|Past tense -DI
T de|Vergangenheit auf -DI
B en|The definite past: stem + -dı/-di/-du/-dü (t after hard consonants) + short endings -m, -n, –, -k: çalıştım (I worked), yazdın, gitti. Jobs: "Öğretmenim" (I'm a teacher).
B de|Bestimmte Vergangenheit: Stamm + -dı/-di/-du/-dü (t nach harten Konsonanten) + kurze Endungen -m, -n, –, -k: çalıştım (ich arbeitete), yazdın, gitti. Beruf: "Öğretmenim".
E|Dün uzun süre çalıştım.
E|Bir e-posta yazdım.
E|Mesleğin ne?
== tr u15
T en|-DI vs. -mIş
T de|-DI und -mIş
B en|-dı/-di is used for things you witnessed yourself: "Anahtarımı kaybettim." -mış/-miş reports things you heard or just discovered: "Ali Hamburg'a gitmiş" (apparently Ali went to Hamburg).
B de|-dı/-di für selbst Erlebtes: "Anahtarımı kaybettim." -mış/-miş für Gehörtes oder überraschend Festgestelltes: "Ali Hamburg'a gitmiş" (Ali ist wohl nach Hamburg gefahren).
E|Büyükannemi ziyaret ettim.
E|Ne oldu?
E|Anahtarımı kaybettim.
== tr u16
T en|Dative for recipients
T de|Dativ für Empfänger
B en|The person who receives something takes the dative -(y)A: "Annene ne hediye ediyorsun?" "Ona çiçek hediye ediyorum." Dates: "on iki Mart'ta" (on 12 March).
B de|Wer etwas bekommt, steht im Dativ -(y)A: "Annene ne hediye ediyorsun?" "Ona çiçek hediye ediyorum." Datum: "on iki Mart'ta" (am 12. März).
E|Annene ne hediye ediyorsun?
E|Ona çiçek hediye ediyorum.
E|Seni partime davet ediyorum.
== tr u17
T en|Reasons: "çünkü" and "-DIğI için"
T de|Gründe: "çünkü" und "-DIğI için"
B en|Simple: "…, çünkü …" (because). More native: verb + -dığı/-diği + possessive + için: "Önemli olduğu için" (because it is important).
B de|Einfach: "…, çünkü …" (weil). Typischer: Verb + -dığı/-diği + Possessiv + için: "Önemli olduğu için" (weil es wichtig ist).
E|Çünkü bu Almanya'da önemli.
E|Şişeleri geri götürüyorum, çünkü depozito var.
E|Gelecek ay taşınıyoruz.
== tr u18
T en|Polite requests: "-(y)Abilir misiniz?"
T de|Höfliche Bitten: "-(y)Abilir misiniz?"
B en|Polite request = ability + question: "Yardım edebilir misiniz?" (Could you help?). Wish: verb + -mak/-mek istiyorum: "Kaydettirmek istiyorum." "Lütfen" softens orders: "Lütfen formu doldurun."
B de|Höfliche Bitte = Können + Frage: "Yardım edebilir misiniz?" (Könnten Sie helfen?). Wunsch: Verb + -mak/-mek istiyorum: "Kaydettirmek istiyorum." "Lütfen" macht Aufforderungen höflich.
E|İkametimi kaydettirmek istiyorum.
E|Lütfen bu formu doldurun.
E|Lütfen buraya imza atın.
== tr u19
T en|"Kendimi … hissediyorum" and -mAlI
T de|"Kendimi … hissediyorum" und -mAlI
B en|To feel = kendimi (myself) … hissediyorum: "Kendimi iyi hissetmiyorum." Advice "should" = -malı/-meli: "Dinlenmelisin." Set phrase for the sick: "Geçmiş olsun!"
B de|Sich fühlen = kendimi (mich) … hissediyorum: "Kendimi iyi hissetmiyorum." Rat "sollte" = -malı/-meli: "Dinlenmelisin." Feste Wendung für Kranke: "Geçmiş olsun!"
E|Kendini nasıl hissediyorsun?
E|Kendimi iyi hissetmiyorum.
E|Geçmiş olsun!
== tr u20
T en|Comparison: "daha" and "en"
T de|Vergleich: "daha" und "en"
B en|Comparative = daha + adjective; "than" = noun + -dAn: "Bu uygulama eskisinden daha iyi." Superlative = en + adjective: "en iyi" (the best).
B de|Komparativ = daha + Adjektiv; "als" = Nomen + -dAn: "Bu uygulama eskisinden daha iyi." Superlativ = en + Adjektiv: "en iyi" (am besten).
E|Bu uygulama eskisinden daha iyi.
E|İnternet bugün daha yavaş.
E|En iyi hangi uygulamayı buluyorsun?
== tr u21
T en|Future -(y)AcAk
T de|Futur -(y)AcAk
B en|Future = stem + -(y)acak/-(y)ecek + ending: gideceğim, kalacağım (k → ğ before a vowel). "Was/were" with nouns: -(y)dI: "harikaydı" (it was great).
B de|Futur = Stamm + -(y)acak/-(y)ecek + Endung: gideceğim, kalacağım (k → ğ vor Vokal). "War" bei Nomen/Adjektiven: -(y)dI: "harikaydı" (es war toll).
E|Bir gençlik hostelinde kalacağım.
E|Harikaydı ama az zamanım vardı.
E|Şatoyu gezdik.
== tr u22
T en|Ordering: "-(y)AyIm"
T de|Bestellen: "-(y)AyIm"
B en|The optative "let me …" is very common when ordering: "Şinitzel alayım" (I'll have the schnitzel). Paying: "Hesap, lütfen!" Tip: "Üstü kalsın" (keep the change).
B de|Der Optativ "ich nehme mal …" ist beim Bestellen üblich: "Şinitzel alayım" (Ich nehme das Schnitzel). Bezahlen: "Hesap, lütfen!" Trinkgeld: "Üstü kalsın" (Stimmt so).
E|Salatalı şinitzel alayım.
E|Hesap, lütfen!
E|Yirmi beş, üstü kalsın.
== tr u23
T en|Conditional -(y)sA
T de|Konditional -(y)sA
B en|"If" is a suffix: -sa/-se (+ ending): "Üzgün olursan beni ara" (If you are sad, call me), "yorgunsam" (if I'm tired). "When" = -dığında: "Yorgun olduğumda".
B de|"Wenn" ist eine Endung: -sa/-se (+ Endung): "Üzgün olursan beni ara" (Wenn du traurig bist, ruf mich an), "yorgunsam". "Immer wenn" = -dığında: "Yorgun olduğumda".
E|Üzgün olursan beni ara.
E|Yorgun olduğumda çabuk sinirlenirim.
E|Ailemi özlüyorum.
== tr u24
T en|Unreal conditions: "-sAydI … -Irdi"
T de|Irreale Bedingungen: "-sAydI … -Irdi"
B en|Unreal past/present: -saydı/-seydi in the if-part, aorist + -dı in the result: "Daha çok zamanım olsaydı bir meslek eğitimi alırdım." Polite "would like": "… isterim".
B de|Irreal: -saydı/-seydi im Bedingungsteil, Aorist + -dı im Folgeteil: "Daha çok zamanım olsaydı bir meslek eğitimi alırdım." Höflich "möchte gern": "… isterim".
E|Uluslararası bir ekipte çalışmak isterim.
E|Daha çok zamanım olsaydı bir meslek eğitimi alırdım.
E|Evet, bu sorun olmaz.
== tr u25
T en|Passive -Il / -In
T de|Passiv -Il / -In
B en|Passive inserts -ıl/-il (or -n after vowels, -ın after l) into the verb: toplamak → toplanıyor (is collected), yapmak → yapılıyor (is done), kullanmak → kullanılabilir (can be used).
B de|Das Passiv fügt -ıl/-il (nach Vokalen -n, nach l -ın) ins Verb ein: toplamak → toplanıyor (wird abgeholt), yapmak → yapılıyor (wird gemacht), kullanmak → kullanılabilir (kann benutzt werden).
E|Çöpler her pazartesi toplanıyor.
E|Almanya'da çok geri dönüşüm yapılıyor.
E|Daha az plastik kullanılabilir.
== tr u26
T en|Past perfect -mIştI
T de|Plusquamperfekt -mIştI
B en|-mıştı/-mişti describes a state or event further back in the past: "Almanya uzun yıllar bölünmüştü" (had been divided). The simple -dı tells the main events: "Duvar 1989'da yıkıldı."
B de|-mıştı/-mişti beschreibt Vorvergangenes: "Almanya uzun yıllar bölünmüştü" (war geteilt gewesen). Das einfache -dı erzählt die Hauptereignisse: "Duvar 1989'da yıkıldı."
E|Duvar 1989'da yıkıldı.
E|Almanya uzun yıllar bölünmüştü.
E|Altmışlı yıllarda Türkiye'den birçok misafir işçi geldi.
== tr u27
T en|Participles instead of relative clauses
T de|Partizipien statt Relativsätzen
B en|Turkish has no "who/which" — it puts a participle before the noun. Subject: -(y)an/-(y)en: "bize yardım eden öğretmen" (the teacher who helps us). Object: -dığı + possessive: "sevdiğim kurs" (the course I like).
B de|Türkisch hat kein "der/die/das" als Relativpronomen – ein Partizip steht vor dem Nomen. Subjekt: -(y)an/-(y)en: "bize yardım eden öğretmen" (die Lehrerin, die uns hilft). Objekt: -dığı + Possessiv: "sevdiğim kurs" (der Kurs, den ich mag).
E|Bize yardım eden öğretmen harika.
E|Bu çok sevdiğim kurs.
E|Sınavı geçtin mi?
== tr u28
T en|"-mAsInA rağmen" and connectors
T de|"-mAsInA rağmen" und Konnektoren
B en|"Although" = -masına/-mesine rağmen: "Pratik olmasına rağmen" (although it's practical). Opinion: "Bence …" (in my opinion), "Sana katılıyorum" (I agree with you), "bu yüzden" (therefore), "yine de" (nevertheless).
B de|"Obwohl" = -masına/-mesine rağmen: "Pratik olmasına rağmen". Meinung: "Bence …" (meiner Meinung nach), "Sana katılıyorum" (ich stimme dir zu), "bu yüzden" (deshalb), "yine de" (trotzdem).
E|Pratik olmasına rağmen ekibimi özlüyorum.
E|Sana katılıyorum.
E|Yine de bir uzlaşma bulmalıyız.
== tr u29
T en|Genitive-possessive: "Kafka'nın romanı"
T de|Genitiv-Possessiv: "Kafka'nın romanı"
B en|"X's Y" = X + -(n)In, Y + -(s)I: "Kafka'nın romanı" (Kafka's novel), "yönetmenin filmi" (the director's film). "Despite" = noun + -(y)A rağmen: "yağmura rağmen".
B de|"Ys von X" = X + -(n)In, Y + -(s)I: "Kafka'nın romanı" (Kafkas Roman), "yönetmenin filmi" (der Film des Regisseurs). "Trotz" = Nomen + -(y)A rağmen: "yağmura rağmen".
E|Yönetmenin filmi çok heyecanlıydı.
E|Yağmura rağmen sergiye gittik.
E|Şu an Kafka'nın bir romanını okuyorum.
''';

List<GrammarPoint> _parse() {
  final out = <GrammarPoint>[];
  String? target, unit;
  var title = <String, String>{}, body = <String, String>{};
  var ex = <String>[];
  void flush() {
    if (target != null && unit != null) {
      out.add(GrammarPoint(target: target, unitId: unit, title: title, body: body, examples: ex));
    }
  }

  for (final raw in _grammar.split('\n')) {
    final l = raw.trim();
    if (l.isEmpty) continue;
    if (l.startsWith('== ')) {
      flush();
      final p = l.substring(3).split(' ');
      target = p[0];
      unit = p[1];
      title = {};
      body = {};
      ex = [];
    } else if (l.startsWith('T ')) {
      final i = l.indexOf('|');
      title[l.substring(2, i)] = l.substring(i + 1);
    } else if (l.startsWith('B ')) {
      final i = l.indexOf('|');
      body[l.substring(2, i)] = l.substring(i + 1);
    } else if (l.startsWith('E|')) {
      ex.add(l.substring(2));
    }
  }
  flush();
  return out;
}

final List<GrammarPoint> grammarPoints = _parse();

GrammarPoint? grammarFor(String target, String unitId) {
  for (final g in grammarPoints) {
    if (g.target == target && g.unitId == unitId) return g;
  }
  return null;
}
