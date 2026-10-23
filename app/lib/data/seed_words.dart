import 'models.dart';
import 'vocab_bank.dart';

/// The built-in catalogue: every picture card in the course vocabulary bank.
final List<Word> seedWords = bankWords.values.toList(growable: false);
