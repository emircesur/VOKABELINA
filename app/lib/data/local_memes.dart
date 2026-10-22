import 'content.dart';
import 'models.dart';

/// Shown when the AI server is unavailable, so the Culture tab is never empty.
const _w = Word.new;

final List<Meme> localMemes = [
  Meme(
    id: 'local-1',
    top: 'Der Zug hat 5 Minuten Verspätung.',
    bottom: 'Die Deutsche Bahn: „Pünktlich ist relativ.“',
    theme: 'Bahn',
    emoji: '🚆',
    explanation: 'The joke: German trains are famously late, despite the stereotype of German punctuality.',
    explanationTr: 'Şaka: Alman klişesi dakikliktir ama Alman trenleri meşhur şekilde geç kalır.',
    vocab: [_w(id: 'die_verspaetung', de: 'die Verspätung', en: 'delay', tr: 'gecikme', custom: true), _w(id: 'puenktlich', de: 'pünktlich', en: 'punctual', tr: 'dakik', custom: true)],
  ),
  Meme(
    id: 'local-2',
    top: 'Sonntag, 14 Uhr. Du willst staubsaugen.',
    bottom: 'Die Nachbarn: „Ruhezeit!“',
    theme: 'Ruhezeit',
    emoji: '🤫',
    explanation: 'On Sundays and public holidays loud work is not allowed in Germany (Ruhezeit).',
    explanationTr: 'Almanya’da pazar ve resmî tatillerde gürültülü iş yapmak yasaktır (Ruhezeit).',
    vocab: [_w(id: 'die_ruhezeit', de: 'die Ruhezeit', en: 'quiet hours', tr: 'sessizlik saatleri', custom: true)],
  ),
  Meme(
    id: 'local-3',
    top: 'Ich: „Ich entsorge nur kurz die Flasche.“',
    bottom: 'Der Pfandautomat: „Ich bin nicht dein Freund.“',
    theme: 'Pfand',
    emoji: '🍾',
    explanation: 'Bottles carry a deposit (Pfand) you get back from a machine — which sometimes rejects them.',
    explanationTr: 'Şişelerde depozito (Pfand) vardır; makine bazen şişeyi kabul etmez.',
    vocab: [_w(id: 'das_pfand', de: 'das Pfand', en: 'bottle deposit', tr: 'depozito', custom: true)],
  ),
  Meme(
    id: 'local-4',
    top: 'Brot in Deutschland: Tausende Sorten.',
    bottom: 'Auslandsdeutsche: „Ich vermisse nur das Brot.“',
    theme: 'Brotkultur',
    emoji: '🍞',
    explanation: 'German bread culture is on the national intangible-heritage list kept by the German UNESCO Commission; expats often miss real bread most.',
    explanationTr: 'Alman ekmek kültürü, Alman UNESCO Komisyonu’nun ulusal somut olmayan kültürel miras listesindedir; yurtdışındakiler en çok ekmeği özler.',
    vocab: [_w(id: 'das_brot', de: 'das Brot', en: 'bread', tr: 'ekmek', custom: true)],
  ),
];
