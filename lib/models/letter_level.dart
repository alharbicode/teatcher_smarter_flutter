// lib/models/letter_level.dart
import 'arabic_letter.dart';

class LetterLevel {
  final int levelNumber; // رقم المستوى
  final List<ArabicLetter> letters; // قائمة الحروف في المستوى

  LetterLevel({
    required this.levelNumber,
    required this.letters,
  });
}
