import 'package:flutter/material.dart';

import '../data/models.dart';

/// Classic colour coding for German genders.
Color? articleColor(String? article) => switch (article) {
      'der' => const Color(0xFF2B6CB0),
      'die' => const Color(0xFFD64545),
      'das' => const Color(0xFF2E9E5B),
      _ => null,
    };

/// Square emoji picture with a soft gradient; border shows the German gender.
class PictureTile extends StatelessWidget {
  const PictureTile({super.key, required this.word, this.size = 72, this.showGender = false, this.selected = false});
  final Word word;
  final double size;
  final bool showGender;
  final bool selected;

  static const _bgs = [
    [Color(0xFFFFF1DE), Color(0xFFFFE1BD)],
    [Color(0xFFE3F4F4), Color(0xFFCBEAEA)],
    [Color(0xFFFDE6E6), Color(0xFFF8CFCF)],
    [Color(0xFFE6F4EA), Color(0xFFCDEBD6)],
    [Color(0xFFEDE7F8), Color(0xFFDCD0F2)],
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = _bgs[word.id.hashCode.abs() % _bgs.length];
    final gender = showGender ? articleColor(word.article) : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark ? [bg[0].withValues(alpha: 0.18), bg[1].withValues(alpha: 0.28)] : bg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: selected ? Theme.of(context).colorScheme.primary : (gender ?? Colors.transparent),
          width: selected ? 3 : (gender == null ? 0 : 2.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(word.emoji.isEmpty ? '📝' : word.emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Word in the target language; German nouns show the article in its gender colour.
class TargetWordText extends StatelessWidget {
  const TargetWordText({super.key, required this.word, required this.lang, this.style});
  final Word word;
  final String lang;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle(fontSize: 22, fontWeight: FontWeight.w900);
    final art = lang == 'de' ? word.article : null;
    if (art == null) return Text(word.inLang(lang), style: base, textAlign: TextAlign.center);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$art ', style: base.copyWith(color: articleColor(art))),
        TextSpan(text: word.de.substring(art.length + 1)),
      ]),
      style: base,
      textAlign: TextAlign.center,
    );
  }
}
